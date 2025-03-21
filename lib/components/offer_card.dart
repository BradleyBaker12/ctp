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
import 'package:flutter/foundation.dart';

class OfferCard extends StatefulWidget {
  final Offer offer;
  final Function? onPop;

  const OfferCard({
    super.key,
    required this.offer,
    this.onPop,
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
      debugPrint('Fetching vehicle details for ID: ${widget.offer.vehicleId}');
      final vehicleDoc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.offer.vehicleId)
          .get();

      if (vehicleDoc.exists && mounted) {
        final data = vehicleDoc.data();
        // debugPrint('Firestore data: $data');

        setState(() {
          transmissionType = data?['transmissionType'];
          vehicleConfig = data?['config'];
          mileage = data?['mileage'];
          vehicleYear = data?['year']?.toString();

          final vehicleType = data?['vehicleType']?.toString().toLowerCase();

          if (vehicleType == 'trailer') {
            // For trailer offers, show make (from makeModel) and year.
            widget.offer.vehicleBrand = data?['makeModel']?.toString();
            widget.offer.variant = '';
          } else {
            // Existing logic for trucks
            if (data?['brands'] != null) {
              if (data?['brands'] is List) {
                widget.offer.vehicleBrand =
                    (data?['brands'] as List).first.toString();
              } else {
                widget.offer.vehicleBrand = data?['brands'].toString();
              }
            }
            widget.offer.variant = data?['variant']?.toString();
          }

          debugPrint('Updated brand: ${widget.offer.vehicleBrand}');
          debugPrint('Updated variant: ${widget.offer.variant}');
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
    final normalizedStatus = (status ?? '').toLowerCase().trim();
    debugPrint('Getting status color for normalized status: $normalizedStatus');

    switch (normalizedStatus) {
      case 'sold':
        return Colors.red;
      // Success states - Green
      case 'accepted':
      case 'done':
      case 'paid':
      case 'successful':
      case 'completed':
      case 'inspection done':
      case 'payment approved':
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
    final normalizedStatus = (status ?? '').toLowerCase().trim();
    debugPrint('Getting status icon for normalized status: $normalizedStatus');

    switch (normalizedStatus) {
      case 'sold':
        return Icons.sell;
      // Completed/Success states
      case 'accepted':
      case 'done':
      case 'paid':
      case 'successful':
      case 'completed':
      case 'payment approved':
      case 'awaiting collection':
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
        return Icons.sync;
      default:
        return Icons.sync;
    }
  }

  void navigateBasedOnStatus(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = userProvider.getUserRole ?? '';

    // Check for sold status
    if (widget.offer.offerStatus.toLowerCase() == 'sold') {
      debugPrint('Offer status is sold, not navigating.');
      return;
    }

    // Handle Payment Approved status
    if (widget.offer.offerStatus.toLowerCase() == 'payment approved') {
      String newStatus = 'awaiting collection';
      FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offer.offerId)
          .update({'offerStatus': newStatus}).then((_) {
        setState(() {
          widget.offer.offerStatus = newStatus;
        });
      });
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
                brand: widget.offer.vehicleBrand ?? '',
                variant: widget.offer.variant ?? '',
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
                    ? LatLng(widget.offer.latLng!.latitude,
                        widget.offer.latLng!.longitude)
                    : null,
              ),
            ),
          );
          return;
        default:
          _getVehicle().then((vehicle) async {
            if (vehicle != null) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransporterOfferDetailsPage(
                    offer: widget.offer,
                    vehicle: vehicle,
                  ),
                ),
              );
              if (widget.onPop != null) {
                widget.onPop!();
              }
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

    // Dealer Navigation
    switch (widget.offer.offerStatus) {
      case 'set location and time':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InspectionDetailsPage(
              offerId: widget.offer.offerId,
              offerAmount: formatOfferAmount(widget.offer.offerAmount),
              vehicleId: widget.offer.vehicleId,
              brand: widget.offer.vehicleBrand ?? 'Unknown',
              variant: widget.offer.variant ?? 'Unknown',
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
              brand: widget.offer.vehicleBrand ?? 'Unknown',
              offerAmount: formatOfferAmount(widget.offer.offerAmount),
              vehicleId: widget.offer.vehicleId,
              variant: widget.offer.variant ?? "",
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
                  ? LatLng(widget.offer.latLng!.latitude,
                      widget.offer.latLng!.longitude)
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
              offerAmount: formatOfferAmount(widget.offer.offerAmount),
              vehicleId: widget.offer.vehicleId,
              brand: widget.offer.vehicleBrand ?? 'Unknown',
              variant: widget.offer.variant ?? 'Unknown',
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
        orElse: () => throw Exception('Vehicle not found'),
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
              offerAmount: formatOfferAmount(widget.offer.offerAmount),
              vehicleId: widget.offer.vehicleId,
              brand: widget.offer.vehicleBrand ?? '',
              variant: widget.offer.variant ?? '',
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
            "Dealer - unhandled status in _navigateToRespectivePage: ${widget.offer.offerStatus}");
        break;
    }
  }

  /// Helper that builds a spec box if the value is valid.
  Widget _buildSpecBox(String value) {
    if (value.trim().isEmpty || value.toUpperCase() == 'N/A') {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
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

  /// Main Offer Card layout with debugging prints and borders.
  Widget _buildWebCard(Color statusColor, BoxConstraints constraints) {
    debugPrint('Offer status in web card: ${widget.offer.offerStatus}');

    const bool isWeb = kIsWeb;
    final double cardWidth = isWeb ? 400 : constraints.maxWidth;
    // Increase cardHeight to allow for a larger gap without overflow.
    final double cardHeight = isWeb ? 600 : cardWidth * 1.4;
    debugPrint('Card dimensions - Width: $cardWidth, Height: $cardHeight');

    final String brandModel = [
      widget.offer.vehicleBrand,
      widget.offer.variant,
    ].where((element) => element != null && element.isNotEmpty).join(' ');
    final String year = vehicleYear ?? 'N/A';

    String brandVariant = '';
    debugPrint('Building card with brand: ${widget.offer.vehicleBrand}');
    debugPrint('Building card with variant: ${widget.offer.variant}');
    if (widget.offer.vehicleBrand?.isNotEmpty == true ||
        widget.offer.variant?.isNotEmpty == true) {
      List<String> parts = [
        widget.offer.vehicleBrand ?? '',
        widget.offer.variant ?? '',
      ].where((element) => element.isNotEmpty).toList();
      brandVariant = parts.join(' ');
      debugPrint('Final brandVariant: $brandVariant');
    }

    return Center(
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: EdgeInsets.all(isWeb ? 8 : 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2F7FFF).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2F7FFF), width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, cardConstraints) {
            double cardW = cardConstraints.maxWidth;
            double cardH = cardConstraints.maxHeight;
            // debugPrint(
            //     'Inner card constraints - Width: $cardW, Height: $cardH');

            double titleFontSize = isWeb ? cardW * 0.045 : cardW * 0.04;
            double subtitleFontSize = isWeb ? cardW * 0.04 : cardW * 0.035;
            double paddingVal = isWeb ? cardW * 0.04 : cardW * 0.03;
            double specFontSize = isWeb ? cardW * 0.03 : cardW * 0.025;
            // debugPrint(
            //     'Calculated font sizes & padding - title: $titleFontSize, subtitle: $subtitleFontSize, padding: $paddingVal, specFontSize: $specFontSize');

            return Column(
              children: [
                // Image section with a debug border.
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
                // Details section with debug border to show its boundaries.
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(paddingVal),
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vehicle details sub-section.
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                Text(
                                  year,
                                  style: GoogleFonts.montserrat(
                                    fontSize: subtitleFontSize,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white70,
                                  ),
                                ),
                                SizedBox(height: paddingVal * 0.5),
                                Text(
                                  'Offer of ${formatOfferAmount(widget.offer.offerAmount)}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
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
                          // Fixed gap of 50 units (debug adjustable)
                          // const SizedBox(height: 25),
                          // View Details Button with a debug border.
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Helper method to build spec boxes.
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
    final normalizedStatus = status.toLowerCase().trim();
    // debugPrint(
    //     'Building status badge for normalized status: $normalizedStatus');

    final String displayText =
        status.isEmpty ? 'UNKNOWN' : status.toUpperCase();
    final icon = getStatusIcon(normalizedStatus);
    final bgColor = getStatusColor(normalizedStatus);

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
            child: InkWell(
                onTap: () => navigateBasedOnStatus(context),
                child: _buildWebCard(statusColor, constraints)));
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
        orElse: () => throw Exception('Vehicle not found'),
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
