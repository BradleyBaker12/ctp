import 'package:ctp/components/expandable_container.dart';
import 'package:ctp/pages/collectionPages/collection_confirmationPage.dart';
import 'package:ctp/pages/collectionPages/collection_details_page.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ctp/pages/inspectionPages/final_inspection_approval_page.dart';
import 'package:ctp/pages/inspectionPages/inspection_details_page.dart';
import 'package:ctp/pages/offer_details_page.dart';
import 'package:ctp/pages/payment_options_page.dart';
import 'package:ctp/pages/payment_pending_page.dart';
import 'package:ctp/pages/payment_approved.dart';
import 'package:ctp/pages/inspectionPages/location_confirmation_page.dart';
import 'package:ctp/pages/inspectionPages/confirmation_page.dart';
import 'package:ctp/pages/rating_pages/rate_transporter_page.dart'; // Import RateTransporterPage
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/user_provider.dart';

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
  bool _isExpanded = false;
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
      default:
        return Colors.grey;
    }
  }

  String formatOfferAmount(double? amount) {
    if (amount == null) return 'Unknown';
    return 'R${amount.toStringAsFixed(0)}'; // Removes decimal places
  }

  IconData getIcon() {
    switch (widget.offer.offerStatus) {
      case '1/4':
      case '2/4':
      case '3/4':
        return Icons.access_time; // Clock icon
      case 'paid':
        return Icons.check_circle; // Paid icon
      case 'Done':
        return Icons.check; // Tick icon for 'Done'
      default:
        return Icons.info; // Default icon
    }
  }

  Future<void> _updateOfferAmount(double newAmount) async {
    try {
      await widget.offer.updateOfferAmount(newAmount);
      _editController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Offer amount updated to R${newAmount.toStringAsFixed(0)}',
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

  void navigateBasedOnStatus(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = userProvider.getUserRole ?? ''; // Add a fallback value

    if (userRole == 'transporter') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OfferDetailsPage(
            offerId: widget.offer.offerId,
            vehicleName: widget.offer.vehicleMakeModel ?? 'Unknown',
            offerAmount: formatOfferAmount(widget.offer.offerAmount),
            images: widget.offer.vehicleImages,
            additionalInfo: widget.offer.additionalInfo,
            year: widget.offer.vehicleYear,
            mileage: widget.offer.vehicleMileage,
            transmission: widget.offer.vehicleTransmission,
            onAccept: () async {
              await _updateOfferStatus('accepted');
              Navigator.of(context).pop();
            },
            onReject: () async {
              await _updateOfferStatus('rejected');
              Navigator.of(context).pop();
            },
            offerStatus: widget.offer.offerStatus ?? 'Unknown',
          ),
        ),
      );
    } else {
      switch (widget.offer.offerStatus) {
        case '1/4':
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
        case '2/4':
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
        case 'Payment Pending':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentPendingPage(
                offerId: widget.offer.offerId,
              ),
            ),
          );
          break;
        case 'paid':
        case 'Payment Approved':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentApprovedPage(
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
              ),
            ),
          );
          break;
        case 'Inspection Pending':
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
        case 'Rating Transporter':
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
        case 'Confirm Collection Details':
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
                    : null, // Passing the latLng here
              ),
            ),
          );
          break;

        default:
          // Handle any other statuses or default behavior
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // Ensure full width
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 120, // Set a fixed height to avoid infinite height issue
              color: statusColor,
            ),
            Container(
              width: constraints.maxWidth * 0.2,
              height: 120, // Set a fixed height to avoid infinite height issue
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: widget.offer.vehicleMainImage != null
                      ? NetworkImage(widget.offer.vehicleMainImage!)
                      : const AssetImage('lib/assets/default_vehicle_image.png')
                          as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.blue,
                padding: const EdgeInsets.all(10.0),
                height:
                    120, // Set a fixed height to avoid infinite height issue
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.offer.vehicleMakeModel ?? 'Unknown',
                      style: customFont(18, FontWeight.bold, Colors.white),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Offer of ${formatOfferAmount(widget.offer.offerAmount)}',
                      style: customFont(16, FontWeight.normal, Colors.white),
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Text(
                        _isExpanded ? 'View less' : 'View more details',
                        style: customFont(14, FontWeight.normal, Colors.white)
                            .copyWith(decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: constraints.maxWidth * 0.2,
              height: 120, // Set a fixed height to avoid infinite height issue
              color: statusColor,
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
                      widget.offer.offerStatus ?? 'Unknown',
                      style: customFont(16, FontWeight.bold, Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ExpandableContainer(
          isExpanded: _isExpanded,
          borderColor: statusColor,
          backgroundColor: statusColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STATUS: ${widget.offer.offerStatus}',
                style: customFont(16, FontWeight.bold, Colors.white),
              ),
              const SizedBox(height: 5),
              if (widget.offer.offerStatus == 'in-progress')
                ElevatedButton(
                  onPressed: _editOfferAmountDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: Text('Edit Offer Amount',
                      style: customFont(16, FontWeight.bold, Colors.white)),
                ),
              if (widget.offer.offerStatus == 'accepted')
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InspectionDetailsPage(
                          offerId: widget.offer.offerId,
                          makeModel: widget.offer.vehicleMakeModel ?? 'Unknown',
                          offerAmount:
                              formatOfferAmount(widget.offer.offerAmount),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Proceed with next steps',
                    style: customFont(16, FontWeight.normal, Colors.white)
                        .copyWith(decoration: TextDecoration.underline),
                  ),
                ),
              if (widget.offer.offerStatus == 'rejected' &&
                  widget.offer.reason != null &&
                  widget.offer.reason!.isNotEmpty)
                const SizedBox(height: 5),
              if (widget.offer.offerStatus == 'rejected' &&
                  widget.offer.reason != null &&
                  widget.offer.reason!.isNotEmpty)
                Text(
                  'REASON: ${widget.offer.reason}',
                  style: customFont(16, FontWeight.normal, Colors.white),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransporterCard(Color statusColor, BoxConstraints constraints) {
    return Row(
      children: [
        Container(
          width: constraints.maxWidth * 0.02,
          color: Colors.green,
        ),
        Expanded(
          child: Container(
            color: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offer of ${formatOfferAmount(widget.offer.offerAmount)}',
                  style: customFont(18, FontWeight.bold, Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'DEALERS RATING:',
                  style: customFont(14, FontWeight.normal, Colors.white),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      '50/50', // You can replace this with dynamic data if available
                      style: customFont(14, FontWeight.normal, Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(
          width: constraints.maxWidth * 0.2,
          height: 120,
          color: Colors.green,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.remove_red_eye, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  'View',
                  style: customFont(16, FontWeight.bold, Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
