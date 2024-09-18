import 'package:ctp/pages/collectionPages/collection_confirmationPage.dart';
import 'package:ctp/pages/collectionPages/collection_details_page.dart';
import 'package:ctp/pages/transport_offer_details_page.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:ctp/pages/inspectionPages/final_inspection_approval_page.dart';
import 'package:ctp/pages/inspectionPages/inspection_details_page.dart';
import 'package:ctp/pages/payment_options_page.dart';
import 'package:ctp/pages/payment_pending_page.dart';
import 'package:ctp/pages/payment_approved.dart';
import 'package:ctp/pages/inspectionPages/location_confirmation_page.dart';
import 'package:ctp/pages/inspectionPages/confirmation_page.dart';
import 'package:ctp/pages/rating_pages/rate_transporter_page.dart'; // Import RateTransporterPage
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/providers/complaints_provider.dart'; // Import ComplaintsProvider

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
        return Colors.green; // Green color for 'Done'
      case 'Issue reported':
        return Colors.orange; // Orange color for 'Issue reported'
      case 'resolved':
        return Colors.blue; // Blue color for 'resolved'
      default:
        return Colors.grey;
    }
  }

  String formatOfferAmount(double? amount) {
    if (amount == null) return 'Unknown';

    // Use NumberFormat to format with commas
    final formattedAmount = NumberFormat.currency(
      locale: 'en_ZA',
      symbol: 'R',
      decimalDigits: 0,
    ).format(amount);

    // Replace commas with spaces
    return formattedAmount.replaceAll(',', ' ');
  }

  IconData getIcon() {
    switch (widget.offer.offerStatus) {
      case 'in-progress':
      case 'inspection pending':
      case 'set location and time':
        return Icons.access_time; // Clock icon for "In Progress"
      case '1/4':
      case '2/4':
      case '3/4':
        return Icons.access_time; // Clock icon
      case 'paid':
        return Icons.check_circle; // Paid icon
      case 'Done':
      case 'accepted':
        return Icons.check; // Tick icon for 'Done'
      case 'resolved':
        return Icons.thumb_up; // Thumbs up icon for 'resolved'
      default:
        return Icons.info; // Default icon
    }
  }

  String getDisplayStatus(String? offerStatus) {
    switch (offerStatus) {
      case 'in-progress':
        return 'In Progress';
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
      case 'Issue reported':
        return 'Issue Reported'; // Display text for 'Issue reported'
      case 'resolved':
        return 'Resolved'; // Display text for 'Resolved'
      case 'done':
      case 'Done':
        return 'Done';
      // Add more cases as needed
      default:
        return offerStatus ?? 'Unknown';
    }
  }

  Future<void> _updateOfferAmount(double newAmount) async {
    try {
      await widget.offer.updateOfferAmount(newAmount);
      _editController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Offer amount updated to ${formatOfferAmount(newAmount)}',
            style: customFont(16, FontWeight.bold, Colors.green),
          ),
          backgroundColor: Colors.black,
        ),
      );

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.userId ?? ''; // Add a fallback value
      final userRole = userProvider.getUserRole ?? ''; // Add a fallback value
      await Provider.of<OfferProvider>(context, listen: false).refreshOffers(
        userId,
        userRole,
      );

      setState(() {
        widget.offer.offerAmount = newAmount;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update offer amount: $e',
              style: customFont(16, FontWeight.normal, Colors.red)),
        ),
      );
    }
  }

  void _editOfferAmountDialog() {
    _editController.text = widget.offer.offerAmount?.toStringAsFixed(0) ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Offer Amount',
              style: customFont(18, FontWeight.bold, Colors.black)),
          content: TextField(
            controller: _editController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter new offer amount',
              hintStyle: customFont(16, FontWeight.normal, Colors.grey),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel',
                  style: customFont(16, FontWeight.bold, Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save',
                  style: customFont(16, FontWeight.bold, Colors.green)),
              onPressed: () {
                double? newAmount = double.tryParse(_editController.text);
                if (newAmount != null) {
                  _updateOfferAmount(newAmount);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Invalid offer amount',
                          style: customFont(16, FontWeight.normal, Colors.red)),
                    ),
                  );
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateOfferStatus(String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offer.offerId)
          .update({'offerStatus': status});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offer status updated to $status',
              style: customFont(16, FontWeight.normal, Colors.green)),
        ),
      );

      setState(() {
        // Optionally update the UI or trigger a refresh if needed
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e',
              style: customFont(16, FontWeight.normal, Colors.red)),
        ),
      );
    }
  }

  void navigateBasedOnStatus(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);
    final complaintsProvider =
        Provider.of<ComplaintsProvider>(context, listen: false);
    final userRole = userProvider.getUserRole ?? ''; // Add a fallback value

    // Fetch complaints related to this offer
    await complaintsProvider.fetchComplaints(widget.offer.offerId);

    // Check if there's a resolved complaint
    final resolvedComplaint =
        complaintsProvider.getResolvedComplaint(widget.offer.offerId);

    // Check user role and navigate accordingly
    if (userRole == 'transporter') {
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
            vehicleProvider.addVehicle(vehicle); // Add to provider
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vehicle details not found.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error fetching vehicle details: $e'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransporterOfferDetailsPage(
            offer: widget.offer,
            vehicle: vehicle!,
          ),
        ),
      );
      return;
    }

    if (resolvedComplaint['complaintStatus'] == 'resolved') {
      // Handle resolved complaints
      // ... (existing logic for handling resolved complaints)
    } else {
      print("Offer status: ${widget.offer.offerStatus}");
      // Continue with the original logic based on offer status
      switch (widget.offer.offerStatus) {
        case 'accepted':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InspectionDetailsPage(
                offerId: widget.offer.offerId,
                makeModel: widget.offer.vehicleMakeModel ?? 'Unknown',
                offerAmount: formatOfferAmount(widget.offer.offerAmount),
                vehicleId: widget.offer.vehicleId, // Add this line
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
        case '3/4':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentPendingPage(
                offerId: widget.offer.offerId,
              ),
            ),
          );
          break;
        case 'set location and time':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InspectionDetailsPage(
                offerId: widget.offer.offerId,
                makeModel: widget.offer.vehicleMakeModel ?? 'Unknown',
                offerAmount: formatOfferAmount(widget.offer.offerAmount),
                vehicleId: widget.offer.vehicleId, // Add this line
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
                vehicleId: widget.offer.vehicleId, // Add this line
              ),
            ),
          );
          break;

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
                vehicleId: widget.offer.vehicleId, // Add this line
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
                vehicleName: widget.offer.vehicleMakeModel ?? 'Unknown',
              ),
            ),
          );
          break;
        case 'rating transporter':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RateTransporterPage(
                offerId: widget.offer.offerId,
                fromCollectionPage: false,
              ),
            ),
          );
          break;
        case 'Confirm Collection':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CollectionDetailsPage(
                offerId: widget.offer.offerId,
              ),
            ),
          );
          break;
        case 'Collection Location Confirmation':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CollectionConfirmationPage(
                offerId: widget.offer.offerId,
                location:
                    widget.offer.dealerSelectedCollectionLocation ?? 'Unknown',
                address:
                    widget.offer.dealerSelectedCollectionAddress ?? 'Unknown',
                date:
                    widget.offer.dealerSelectedCollectionDate ?? DateTime.now(),
                time: widget.offer.dealerSelectedCollectionTime ?? 'Unknown',
                latLng: widget.offer.latLng != null
                    ? LatLng(widget.offer.latLng!.latitude,
                        widget.offer.latLng!.longitude)
                    : null,
              ),
            ),
          );
          break;
        case 'paid': // Handle the 'paid' status
        case 'Payment Approved': // Handle the 'paid' status
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PaymentApprovedPage(offerId: widget.offer.offerId),
            ),
          );
          break;
        default:
          print("Offer status not handled: ${widget.offer.offerStatus}");
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.getUserRole ?? ''; // Add a fallback value
    Color statusColor = getStatusColor(widget.offer.offerStatus);

    return LayoutBuilder(
      builder: (context, constraints) {
        double imageWidth = constraints.maxWidth * 0.25;
        double statusWidth = constraints.maxWidth * 0.2;
        double cardHeight = constraints.maxHeight < 150 ? 100 : 120;

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
    double cardHeight =
        screenSize.height * 0.13; // Set a fixed height for consistency
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
              // Ensure Expanded is within a Row or Column
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
                        (widget.offer.vehicleMakeModel ?? 'Unknown')
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
                          style: customFont(screenSize.height * 0.016,
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
      vehicle = vehicleProvider.vehicles.firstWhere(
        (v) => v.id == widget.offer.vehicleId,
        orElse: () => throw Exception('Vehicle not found in provider'),
      );
    } catch (e) {
      // If the vehicle is not found in the provider, fetch it from the database
      try {
        DocumentSnapshot vehicleSnapshot = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.offer.vehicleId)
            .get();

        if (vehicleSnapshot.exists) {
          vehicle = Vehicle.fromDocument(vehicleSnapshot);
          vehicleProvider.addVehicle(vehicle); // Add to provider
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle details not found.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching vehicle details: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailsPage(vehicle: vehicle!),
      ),
    );
  }

  Widget _buildTransporterCard(Color statusColor, BoxConstraints constraints) {
    var screenSize = MediaQuery.of(context).size;
    double cardHeight = screenSize.height * 0.13; // Same as dealer card height

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => navigateBasedOnStatus(context),
              child: Container(
                width: constraints.maxWidth * 0.06, // Same side indicator width
                height: cardHeight, // Fixed height
                color: Colors.green,
              ),
            ),
            GestureDetector(
              onTap: () => navigateToVehicleDetails(),
              child: Container(
                width:
                    constraints.maxWidth * 0.22, // Same image container width
                height: cardHeight, // Fixed height
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
                  padding: const EdgeInsets.all(10.0), // Same padding as dealer
                  height: cardHeight, // Fixed height
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        (widget.offer.vehicleMakeModel ?? 'Unknown')
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
                width: constraints.maxWidth *
                    0.23, // Same as dealer status section
                height: cardHeight, // Fixed height
                color: Colors.green, // Always green
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.remove_red_eye, // Always the eye icon
                          color: Colors.white,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'View', // Always "View"
                          style: customFont(screenSize.height * 0.016,
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
}
