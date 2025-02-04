import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/collectionPages/collection_confirmationPage.dart';
import 'package:ctp/pages/collectionPages/collection_details_page.dart';
import 'package:ctp/pages/payment_approved.dart';
import 'package:flutter/material.dart';
import 'package:ctp/pages/transport_offer_details_page.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ctp/pages/inspectionPages/final_inspection_approval_page.dart';
import 'package:ctp/pages/inspectionPages/inspection_details_page.dart';
import 'package:ctp/pages/payment_options_page.dart';
import 'package:ctp/pages/payment_pending_page.dart';
import 'package:ctp/pages/inspectionPages/location_confirmation_page.dart';
import 'package:ctp/pages/inspectionPages/confirmation_page.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/providers/complaints_provider.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

class OfferCard extends StatefulWidget {
  final Offer offer;

  const OfferCard({
    super.key,
    required this.offer,
  });

  @override
  _OfferCardState createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  final TextEditingController _editController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variables for transmission, config, mileage, and vehicleYear.
  String? transmissionType;
  String? vehicleConfig;
  String? mileage;
  String? vehicleYear; // New state variable for the year

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForResolvedComplaints();
      _fetchVehicleDetails();
    });
  }

  Future<void> _checkForResolvedComplaints() async {
    final complaintsProvider =
        Provider.of<ComplaintsProvider>(context, listen: false);
    await complaintsProvider.fetchComplaints(widget.offer.offerId);
    final resolvedComplaint =
        complaintsProvider.getResolvedComplaint(widget.offer.offerId);

    if (resolvedComplaint != null &&
        widget.offer.offerStatus == 'Issue reported') {
      if (mounted) {
        setState(() {
          widget.offer.offerStatus = resolvedComplaint.previousStep;
        });
      }
    }
  }

  /// Fetch basic vehicle details from Firestore (including the year).
  Future<void> _fetchVehicleDetails() async {
    try {
      final vehicleDoc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.offer.vehicleId)
          .get();

      if (vehicleDoc.exists && mounted) {
        setState(() {
          transmissionType = vehicleDoc.data()?['transmissionType'];
          vehicleConfig = vehicleDoc.data()?['config'];
          mileage = vehicleDoc.data()?['mileage'];
          // Retrieve the year from the vehicle document.
          vehicleYear = vehicleDoc.data()?['year']?.toString();
        });
      }
    } catch (e) {
      debugPrint('Error fetching vehicle details: $e');
    }
  }

  TextStyle customFont(double size, FontWeight weight, Color color) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  Color getStatusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      // Success states - Green
      case 'accepted':
      case 'done':
      case 'paid':
      case 'successful':
      case 'completed':
      case 'inspection done':
        return Colors.green;

      // Failed states - Red
      case 'rejected':
        return Colors.red;

      // Warning states - Orange
      case 'issue reported':
        return Colors.orange;

      // Payment states - Purple
      case 'payment pending':
      case 'payment options':
        return Colors.purple;

      // Location states - Blue
      case 'set location and time':
      case 'confirm location':
      case 'collection location confirmation':
      case 'collection details':
      case 'confirm collection':
        return Colors.blue;

      // In-progress state - Gray
      case 'in-progress':
        return Colors.grey;

      // Default state - Light Blue
      case 'inspection pending':
      default:
        return const Color(0xFF2F7FFF);
    }
  }

  String formatOfferAmount(double? amount) {
    if (amount == null) return 'Unknown';
    final formattedAmount = NumberFormat.currency(
      locale: 'en_ZA',
      symbol: 'R',
      decimalDigits: 0,
    ).format(amount);
    return formattedAmount.replaceAll(',', ' ');
  }

  IconData getStatusIcon(String? status) {
    switch ((status ?? '').toLowerCase()) {
      // Completed/Success states
      case 'accepted':
      case 'done':
      case 'paid':
      case 'successful':
      case 'completed':
        return Icons.check_circle;

      // Rejected/Failed states
      case 'rejected':
        return Icons.cancel;

      // Warning/Issue states
      case 'issue reported':
        return Icons.report_problem;

      // Payment states
      case 'payment pending':
      case 'payment options':
        return Icons.payments;

      // Inspection states
      case 'inspection pending':
      case 'inspection done':
        return Icons.check_box;

      // Location/Collection states
      case 'set location and time':
      case 'confirm location':
      case 'collection location confirmation':
      case 'collection details':
      case 'confirm collection':
        return Icons.location_on;

      // In-progress/Default state
      case 'in-progress':
        return Icons.sync; // Changed from Icons.refresh to Icons.sync
      default:
        return Icons.sync; // Changed default icon as well
    }
  }

  void navigateBasedOnStatus(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = userProvider.getUserRole ?? '';

    // Handle Payment Approved status for both roles
    if (widget.offer.offerStatus?.toLowerCase() == 'payment approved') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentApprovedPage(
            offerId: widget.offer.offerId,
          ),
        ),
      );
      return;
    }

    if (userRole == 'transporter') {
      switch (widget.offer.offerStatus) {
        case 'inspection pending':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmationPage(
                offerId: widget.offer.offerId,
                location:
                    widget.offer.dealerSelectedInspectionLocation ?? 'Unknown',
                address:
                    widget.offer.dealerSelectedInspectionLocation ?? 'Unknown',
                date: widget.offer.dealerSelectedInspectionDate!,
                time: widget.offer.dealerSelectedInspectionTime ?? 'Unknown',
                latLng: LatLng(
                  widget.offer.latLng?.latitude ?? 0,
                  widget.offer.latLng?.longitude ?? 0,
                ),
                makeModel: widget.offer.vehicleMakeModel ?? 'Unknown',
                offerAmount: formatOfferAmount(widget.offer.offerAmount),
                vehicleId: widget.offer.vehicleId,
              ),
            ),
          );
          return;
        case 'Inspection Done':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FinalInspectionApprovalPage(
                offerId: widget.offer.offerId,
                oldOffer: formatOfferAmount(widget.offer.offerAmount),
                vehicleName: widget.offer.vehicleMakeModel ?? 'Unknown',
              ),
            ),
          );
          return;
        case 'payment pending':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentPendingPage(
                offerId: widget.offer.offerId,
              ),
            ),
          );
          return;
        case 'Collection Location Confirmation':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CollectionConfirmationPage(
                offerId: widget.offer.offerId,
                location:
                    widget.offer.dealerSelectedInspectionLocation ?? 'Unknown',
                address: widget.offer.transporterDeliveryAddress ?? 'Unknown',
                date: widget.offer.dealerSelectedInspectionDate!,
                time: widget.offer.dealerSelectedInspectionTime ?? 'Unknown',
                latLng: widget.offer.latLng != null
                    ? LatLng(
                        widget.offer.latLng!.latitude,
                        widget.offer.latLng!.longitude,
                      )
                    : null,
              ),
            ),
          );
          return;
        default:
          _getVehicle().then((vehicle) {
            if (vehicle != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransporterOfferDetailsPage(
                    offer: widget.offer,
                    vehicle: vehicle,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vehicle details could not be loaded.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
          return;
      }
    }

    // Dealer Navigation.
    switch (widget.offer.offerStatus) {
      case 'set location and time':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InspectionDetailsPage(
              offerId: widget.offer.offerId,
              makeModel: widget.offer.vehicleMakeModel ?? 'Unknown',
              offerAmount: formatOfferAmount(widget.offer.offerAmount),
              vehicleId: widget.offer.vehicleId,
            ),
          ),
        );
        break;
      case 'confirm location':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LocationConfirmationPage(
              offerId: widget.offer.offerId,
              location:
                  widget.offer.dealerSelectedInspectionLocation ?? 'Unknown',
              address:
                  widget.offer.dealerSelectedInspectionLocation ?? 'Unknown',
              date: widget.offer.dealerSelectedInspectionDate!,
              time: widget.offer.dealerSelectedInspectionTime ?? 'Unknown',
              makeModel: widget.offer.vehicleMakeModel ?? 'Unknown',
              offerAmount: formatOfferAmount(widget.offer.offerAmount),
              vehicleId: widget.offer.vehicleId,
            ),
          ),
        );
        break;
      case 'Confirm Collection':
      case 'Collection Location Confirmation':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CollectionConfirmationPage(
              offerId: widget.offer.offerId,
              location:
                  widget.offer.dealerSelectedInspectionLocation ?? 'Unknown',
              address: widget.offer.transporterDeliveryAddress ?? 'Unknown',
              date: widget.offer.dealerSelectedInspectionDate!,
              time: widget.offer.dealerSelectedInspectionTime ?? 'Unknown',
              latLng: widget.offer.latLng != null
                  ? LatLng(
                      widget.offer.latLng!.latitude,
                      widget.offer.latLng!.longitude,
                    )
                  : null,
            ),
          ),
        );
        break;
      case 'payment options':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentOptionsPage(
              offerId: widget.offer.offerId,
            ),
          ),
        );
        break;
      case 'accepted':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InspectionDetailsPage(
              offerId: widget.offer.offerId,
              makeModel: widget.offer.vehicleMakeModel ?? 'Unknown',
              offerAmount: formatOfferAmount(widget.offer.offerAmount),
              vehicleId: widget.offer.vehicleId,
            ),
          ),
        );
        break;
      case 'inspection pending':
      case 'Inspection Done':
      case 'payment pending':
        _navigateToRespectivePage(userRole);
        break;
      case 'paid':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentApprovedPage(
              offerId: widget.offer.offerId,
            ),
          ),
        );
        break;
      case 'collection details':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CollectionDetailsPage(
              offerId: widget.offer.offerId,
            ),
          ),
        );
        break;
      default:
        debugPrint("Dealer - unhandled status: ${widget.offer.offerStatus}");
        break;
    }
  }

  /// Fallback to loading the vehicle if not found in the provider.
  Future<Vehicle?> _getVehicle() async {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    Vehicle? vehicle;

    try {
      vehicle = vehicleProvider.vehicles.firstWhere(
        (v) => v.id == widget.offer.vehicleId,
        orElse: () => throw Exception('Vehicle not found in provider'),
      );
    } catch (e) {
      try {
        DocumentSnapshot vehicleSnapshot = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.offer.vehicleId)
            .get();

        if (vehicleSnapshot.exists) {
          vehicle = Vehicle.fromDocument(vehicleSnapshot);
          vehicleProvider.addVehicle(vehicle);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle details not found.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching vehicle details: $err'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    return vehicle;
  }

  void _navigateToRespectivePage(String userRole) {
    switch (widget.offer.offerStatus) {
      case 'inspection pending':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmationPage(
              offerId: widget.offer.offerId,
              location:
                  widget.offer.dealerSelectedInspectionLocation ?? 'Unknown',
              address:
                  widget.offer.dealerSelectedInspectionLocation ?? 'Unknown',
              date: widget.offer.dealerSelectedInspectionDate!,
              time: widget.offer.dealerSelectedInspectionTime ?? 'Unknown',
              latLng: LatLng(
                widget.offer.latLng?.latitude ?? 0,
                widget.offer.latLng?.longitude ?? 0,
              ),
              makeModel: widget.offer.vehicleMakeModel ?? 'Unknown',
              offerAmount: formatOfferAmount(widget.offer.offerAmount),
              vehicleId: widget.offer.vehicleId,
            ),
          ),
        );
        break;
      case 'Inspection Done':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FinalInspectionApprovalPage(
              offerId: widget.offer.offerId,
              oldOffer: formatOfferAmount(widget.offer.offerAmount),
              vehicleName:
                  (widget.offer.vehicleMakeModel ?? 'Unknown').toUpperCase(),
            ),
          ),
        );
        break;
      case 'payment pending':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentPendingPage(
              offerId: widget.offer.offerId,
            ),
          ),
        );
        break;
      default:
        debugPrint(
          "Dealer - unhandled status in _navigateToRespectivePage: ${widget.offer.offerStatus}",
        );
        break;
    }
  }

  /// Updated helper that only builds a spec box when data is available.
  Widget _buildSpecBox(String value) {
    // If the value is empty (or equals "N/A"), return an empty widget.
    if (value.trim().isEmpty || value.toUpperCase() == 'N/A') {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// The main Offer Card layout with fixed dimensions like TruckCard
  Widget _buildWebCard(Color statusColor, BoxConstraints constraints) {
    // Determine if we're on web
    const bool isWeb = kIsWeb;

    // Use different dimensions for web vs mobile
    final double cardWidth = isWeb ? 400 : constraints.maxWidth;
    final double cardHeight =
        isWeb ? 500 : cardWidth * 1.2; // Keep aspect ratio on mobile

    // Get brand/model and year
    final String brandModel = [
      widget.offer.vehicleBrand,
      widget.offer.vehicleMakeModel,
    ].where((element) => element != null && element.isNotEmpty).join(' ');
    final String year = vehicleYear ?? 'N/A';

    return Center(
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: EdgeInsets.all(isWeb ? 8 : 4), // Smaller margin on mobile
        decoration: BoxDecoration(
          color: const Color(0xFF2F7FFF).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2F7FFF),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, cardConstraints) {
            // Calculate relative sizes based on container width
            double cardW = cardConstraints.maxWidth;
            double cardH = cardConstraints.maxHeight;

            // Adjust font sizes for mobile
            double titleFontSize = isWeb ? cardW * 0.045 : cardW * 0.04;
            double subtitleFontSize = isWeb ? cardW * 0.04 : cardW * 0.035;
            double paddingVal = isWeb ? cardW * 0.04 : cardW * 0.03;
            double specFontSize = isWeb ? cardW * 0.03 : cardW * 0.025;

            // ...rest of your existing layout code...
            return Column(
              children: [
                // Image section with status badge
                SizedBox(
                  height: cardH * 0.55,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10)),
                        child: Image.network(
                          widget.offer.vehicleMainImage ?? '',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                            'lib/assets/default_vehicle_image.png',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: paddingVal * 0.75,
                        right: paddingVal * 0.75,
                        child:
                            _buildStatusBadge(widget.offer.offerStatus ?? ''),
                      ),
                    ],
                  ),
                ),

                // Details section
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(paddingVal),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vehicle details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Brand/model
                              Text(
                                brandModel.isEmpty
                                    ? 'LOADING...'
                                    : brandModel.toUpperCase(),
                                style: GoogleFonts.montserrat(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: paddingVal * 0.25),

                              // Year
                              Text(
                                year,
                                style: GoogleFonts.montserrat(
                                  fontSize: subtitleFontSize,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white70,
                                ),
                              ),
                              SizedBox(height: paddingVal * 0.5),

                              // Offer amount
                              Text(
                                'Offer of ${formatOfferAmount(widget.offer.offerAmount)}',
                                style: GoogleFonts.montserrat(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),

                              // Specs row
                              if (_buildSpecBoxes(cardW).isNotEmpty) ...[
                                SizedBox(height: paddingVal * 0.5),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: _buildSpecBoxes(cardW),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // View Details Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => navigateBasedOnStatus(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2F7FFF),
                              padding: EdgeInsets.symmetric(
                                  vertical: paddingVal * 0.75),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(paddingVal * 0.5),
                              ),
                            ),
                            child: Text(
                              'VIEW MORE DETAILS',
                              style: GoogleFonts.montserrat(
                                fontSize: specFontSize + 2,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Helper method to build spec boxes
  List<Widget> _buildSpecBoxes(double cardWidth) {
    List<Widget> specBoxes = [];
    double spacing = cardWidth * 0.015;

    if (mileage != null &&
        mileage!.trim().isNotEmpty &&
        mileage!.toUpperCase() != 'N/A') {
      specBoxes.add(Expanded(child: _buildSpecBox('${mileage!} km')));
    }
    if (transmissionType != null &&
        transmissionType!.trim().isNotEmpty &&
        transmissionType!.toUpperCase() != 'N/A') {
      if (specBoxes.isNotEmpty) specBoxes.add(SizedBox(width: spacing));
      specBoxes.add(Expanded(child: _buildSpecBox(transmissionType!)));
    }
    if (vehicleConfig != null &&
        vehicleConfig!.trim().isNotEmpty &&
        vehicleConfig!.toUpperCase() != 'N/A') {
      if (specBoxes.isNotEmpty) specBoxes.add(SizedBox(width: spacing));
      specBoxes.add(Expanded(child: _buildSpecBox(vehicleConfig!)));
    }

    return specBoxes;
  }

  Widget _buildStatusBadge(String status) {
    final icon = getStatusIcon(status);
    final bgColor = getStatusColor(status);
    final displayText = status.isEmpty ? 'UNKNOWN' : status.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            displayText,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(widget.offer.offerStatus);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: _buildWebCard(
            statusColor,
            constraints,
          ),
        );
      },
    );
  }

  void navigateToVehicleDetails() async {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    Vehicle? vehicle;

    try {
      vehicle = vehicleProvider.vehicles.firstWhere(
        (v) => v.id == widget.offer.vehicleId,
        orElse: () => throw Exception('Vehicle not found in provider'),
      );
    } catch (e) {
      try {
        DocumentSnapshot vehicleSnapshot = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.offer.vehicleId)
            .get();

        if (vehicleSnapshot.exists) {
          vehicle = Vehicle.fromDocument(vehicleSnapshot);
          vehicleProvider.addVehicle(vehicle);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle details not found.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading vehicle details: $err'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    if (mounted && vehicle != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VehicleDetailsPage(vehicle: vehicle!),
        ),
      );
    }
  }
}
