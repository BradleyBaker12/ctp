// lib/components/offer_card.dart

// ignore_for_file: unused_field, unused_local_variable

import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/collectionPages/collection_confirmationPage.dart';
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

  @override
  void initState() {
    super.initState();
    // Schedule the complaint check after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForResolvedComplaints();
    });
  }

  Future<void> _checkForResolvedComplaints() async {
    final complaintsProvider =
        Provider.of<ComplaintsProvider>(context, listen: false);
    await complaintsProvider.fetchComplaints(widget.offer.offerId);
    final resolvedComplaint =
        complaintsProvider.getResolvedComplaint(widget.offer.offerId);

    // Check if there is a resolved complaint and update the status accordingly
    if (resolvedComplaint != null &&
        widget.offer.offerStatus == 'Issue reported') {
      if (mounted) {
        setState(() {
          widget.offer.offerStatus = resolvedComplaint.previousStep;
        });
      }
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
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'in-progress':
        return Colors.deepOrange;
      case 'rejected':
        return Colors.red;
      case 'Done':
        return Colors.green;
      case 'Issue reported':
        return Colors.orange;
      case 'resolved':
        return Colors.blue;
      default:
        return Colors.grey;
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

  IconData getIcon() {
    switch (widget.offer.offerStatus) {
      case 'in-progress':
      case 'inspection pending':
      case 'set location and time':
        return Icons.access_time;
      case '1/4':
      case '2/4':
      case '3/4':
        return Icons.access_time;
      case 'paid':
        return Icons.check_circle;
      case 'Done':
      case 'accepted':
        return Icons.check;
      case 'resolved':
        return Icons.thumb_up;
      default:
        return Icons.info;
    }
  }

  void navigateBasedOnStatus(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = userProvider.getUserRole;

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
        case 'Collection Location Confirmation': // Ensure this status matches
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CollectionConfirmationPage(
                offerId: widget.offer.offerId,
                location: widget.offer.dealerSelectedInspectionLocation ??
                    'Unknown', // Replace with the correct location key
                address: widget.offer.transporterDeliveryAddress ??
                    'Unknown', // Replace with the correct address key
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

    // Dealer-specific navigation logic
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
              location: widget.offer.dealerSelectedInspectionLocation ??
                  'Unknown', // Replace with the correct location key
              address: widget.offer.transporterDeliveryAddress ??
                  'Unknown', // Replace with the correct address key
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
      default:
        print(
            "Offer status not handled for dealer: ${widget.offer.offerStatus}");
        break;
    }
  }

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
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching vehicle details: $e'),
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
        print(
            "Offer status not handled in _navigateToRespectivePage: ${widget.offer.offerStatus}");
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.getUserRole;
    final userId = userProvider.userId;

    print('''
=== OFFER CARD DEBUG ===
Rendering Offer:
  OfferID: ${widget.offer.offerId}
  Current UserID: $userId
  Current UserRole: $userRole
  Offer DealerId: ${widget.offer.dealerId}
  Offer TransporterId: ${widget.offer.transporterId}
''');

    Color statusColor = getStatusColor(widget.offer.offerStatus);

    return LayoutBuilder(
      builder: (context, constraints) {
        var screenSize = MediaQuery.of(context).size;
        double cardHeight = screenSize.height * 0.13;

        return GestureDetector(
          onTap: () => navigateBasedOnStatus(context),
          child: Card(
            elevation: 5,
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: userRole == 'transporter'
                  ? _buildTransporterCard(statusColor, constraints)
                  : _buildDealerCard(statusColor, constraints),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDealerCard(Color statusColor, BoxConstraints constraints) {
    var screenSize = MediaQuery.of(context).size;
    double cardHeight = screenSize.height * 0.14;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => navigateBasedOnStatus(context),
              child: Container(
                width: constraints.maxWidth * 0.06,
                height: cardHeight,
                color: statusColor,
              ),
            ),
            GestureDetector(
              onTap: () => navigateToVehicleDetails(),
              child: Container(
                width: constraints.maxWidth * 0.22,
                height: cardHeight,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: widget.offer.vehicleMainImage != null
                        ? NetworkImage(widget.offer.vehicleMainImage!)
                        : const AssetImage(
                                'lib/assets/default_vehicle_image.png')
                            as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => navigateToVehicleDetails(),
                child: Container(
                  color: Colors.blue,
                  padding: const EdgeInsets.all(10.0),
                  height: cardHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${widget.offer.vehicleBrand ?? 'Unknown'} ${widget.offer.vehicleMakeModel ?? 'Unknown'} ${widget.offer.vehicleYear ?? 'Unknown'}"
                            .toUpperCase(),
                        style: customFont(
                          screenSize.width * 0.03,
                          FontWeight.w800,
                          Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Offer of ${formatOfferAmount(widget.offer.offerAmount)}'
                            .toUpperCase(),
                        style: customFont(
                          screenSize.width * 0.028,
                          FontWeight.w800,
                          Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => navigateBasedOnStatus(context),
              child: Container(
                width: constraints.maxWidth * 0.23,
                height: cardHeight,
                color: statusColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          getIcon(),
                          color: Colors.white,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          getDisplayStatus(widget.offer.offerStatus),
                          style: customFont(screenSize.height * 0.012,
                              FontWeight.bold, Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransporterCard(Color statusColor, BoxConstraints constraints) {
    //   print('''
    // === OFFER CARD DEBUG ===
    // Brand: ${widget.offer.vehicleBrand}
    // MakeModel: ${widget.offer.vehicleMakeModel}
    // MainImage: ${widget.offer.vehicleMainImage}
    //   ''');

    var screenSize = MediaQuery.of(context).size;
    double cardHeight = screenSize.height * 0.14;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => navigateBasedOnStatus(context),
              child: Container(
                width: constraints.maxWidth * 0.06,
                height: cardHeight,
                color: Colors.green,
              ),
            ),
            GestureDetector(
              onTap: () => navigateToVehicleDetails(),
              child: Container(
                width: constraints.maxWidth * 0.22,
                height: cardHeight,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: widget.offer.vehicleMainImage != null
                        ? NetworkImage(widget.offer.vehicleMainImage!)
                        : const AssetImage(
                                'lib/assets/default_vehicle_image.png')
                            as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => navigateToVehicleDetails(),
                child: Container(
                  color: Colors.blue,
                  padding: const EdgeInsets.all(10.0),
                  height: cardHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${widget.offer.vehicleBrand ?? 'Unknown'} ${widget.offer.vehicleMakeModel ?? 'Unknown'} ${widget.offer.vehicleYear ?? 'Unknown'}"
                            .toUpperCase(),
                        style: customFont(screenSize.height * 0.016,
                            FontWeight.w800, Colors.white),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Offer of ${formatOfferAmount(widget.offer.offerAmount)}'
                            .toUpperCase(),
                        style: customFont(screenSize.height * 0.015,
                            FontWeight.w800, Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () => navigateBasedOnStatus(context),
              child: Container(
                width: constraints.maxWidth * 0.23,
                height: cardHeight,
                color: statusColor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          getIcon(),
                          color: Colors.white,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          getDisplayStatus(widget.offer.offerStatus),
                          style: customFont(screenSize.height * 0.012,
                              FontWeight.bold, Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void navigateToVehicleDetails() async {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    Vehicle? vehicle;

    try {
      // First attempt to get from provider
      vehicle = vehicleProvider.vehicles.firstWhere(
        (v) => v.id == widget.offer.vehicleId,
        orElse: () => throw Exception('Vehicle not found in provider'),
      );
    } catch (e) {
      try {
        // If not in provider, fetch from Firestore
        DocumentSnapshot vehicleSnapshot = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.offer.vehicleId)
            .get();

        if (vehicleSnapshot.exists) {
          vehicle = Vehicle.fromDocument(vehicleSnapshot);
          vehicleProvider.addVehicle(vehicle); // Add to provider for future use

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VehicleDetailsPage(vehicle: vehicle!),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading vehicle details: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    // If vehicle was found in provider, navigate
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VehicleDetailsPage(vehicle: vehicle!),
        ),
      );
    }
  }

  String getDisplayStatus(String? offerStatus) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = userProvider.getUserRole;

    if (userRole == 'transporter' &&
        (offerStatus == 'payment pending' || offerStatus == 'paid')) {
      return 'Payment Processing';
    }

    switch (offerStatus) {
      case 'in-progress':
        return 'Offer Made';
      case 'select location and time':
        return 'Set Location and Time';
      case 'accepted':
        return 'Accepted';
      case 'set location and time':
        return 'Setup Inspection';
      case 'confirm location':
        return 'Confirm Location';
      case 'inspection pending':
        return 'Inspection Pending';
      case '3/4':
        return 'Step 3 of 4';
      case 'paid':
        return 'Paid';
      case 'payment pending':
        return 'Payment Pending';
      case 'Issue reported':
        return 'Issue Reported';
      case 'resolved':
        return 'Resolved';
      case 'done':
      case 'Done':
        return 'Done';
      default:
        return offerStatus ?? 'Unknown';
    }
  }
}
