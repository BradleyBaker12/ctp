import 'package:ctp/pages/inspectionPages/final_inspection_approval_page.dart';
import 'package:ctp/pages/inspectionPages/inspection_details_page.dart';
import 'package:ctp/pages/payment_options_page.dart';
import 'package:ctp/pages/payment_pending_page.dart';
import 'package:ctp/pages/payment_approved.dart';
import 'package:flutter/material.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'expandable_container.dart'; // Make sure to import the new widget

class OfferCard extends StatefulWidget {
  final Offer offer;
  final Size size;
  final TextStyle Function(double, FontWeight, Color) customFont;

  const OfferCard({
    super.key,
    required this.offer,
    required this.size,
    required this.customFont,
  });

  @override
  _OfferCardState createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  bool _isExpanded = false;

  Color getStatusColor(String? status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'in-progress':
        return Colors.deepOrange;
      case 'rejected':
        return Colors.red;
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
      default:
        return Icons.info; // Default icon
    }
  }

  void navigateBasedOnStatus(BuildContext context) {
    switch (widget.offer.offerStatus) {
      case '1/4':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FinalInspectionApprovalPage(
              offerId: widget.offer.offerId,
            ),
          ),
        );
        break;
      case '2/4':
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
        // Handle any other statuses or default behavior
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = getStatusColor(widget.offer.offerStatus);
    Color semiTransparentStatusColor = statusColor.withOpacity(0.8);

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Ensure full width
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height:
                        120, // Set a fixed height to avoid infinite height issue
                    color: statusColor,
                  ),
                  Container(
                    width: widget.size.width * 0.2,
                    height:
                        120, // Set a fixed height to avoid infinite height issue
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
                            style: widget.customFont(
                                18, FontWeight.bold, Colors.white),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Offer of ${formatOfferAmount(widget.offer.offerAmount)}',
                            style: widget.customFont(
                                16, FontWeight.normal, Colors.white),
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
                              style: widget
                                  .customFont(
                                      14, FontWeight.normal, Colors.white)
                                  .copyWith(
                                      decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: widget.size.width * 0.2,
                    height:
                        120, // Set a fixed height to avoid infinite height issue
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
                            style: widget.customFont(
                                16, FontWeight.bold, Colors.white),
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
                      style:
                          widget.customFont(16, FontWeight.bold, Colors.white),
                    ),
                    const SizedBox(height: 5),
                    if (widget.offer.offerStatus == 'accepted')
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InspectionDetailsPage(
                                offerId: widget.offer.offerId,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          'Proceed with next steps',
                          style: widget
                              .customFont(16, FontWeight.normal, Colors.white)
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
                        style: widget.customFont(
                            16, FontWeight.normal, Colors.white),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
