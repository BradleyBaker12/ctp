import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/pages/setup_collection.dart';
import 'package:ctp/pages/setup_inspection.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/offer_provider.dart';
import '../providers/user_provider.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';

class OfferDetailPage extends StatefulWidget {
  final Offer offer;

  const OfferDetailPage({Key? key, required this.offer}) : super(key: key);

  @override
  _OfferDetailPageState createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage> {
  late TextEditingController _offerAmountController;
  late TextEditingController _vehicleMakeModelController;
  late TextEditingController _vehicleYearController;
  late TextEditingController _vehicleMileageController;
  late TextEditingController _vehicleTransmissionController;

  @override
  void initState() {
    super.initState();
    _offerAmountController =
        TextEditingController(text: widget.offer.offerAmount?.toString() ?? '');
    _vehicleMakeModelController =
        TextEditingController(text: widget.offer.vehicleMakeModel);
    _vehicleYearController =
        TextEditingController(text: widget.offer.vehicleYear);
    _vehicleMileageController =
        TextEditingController(text: widget.offer.vehicleMileage);
    _vehicleTransmissionController =
        TextEditingController(text: widget.offer.vehicleTransmission);
  }

  @override
  void dispose() {
    _offerAmountController.dispose();
    _vehicleMakeModelController.dispose();
    _vehicleYearController.dispose();
    _vehicleMileageController.dispose();
    _vehicleTransmissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return GradientBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Offer Details',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Vehicle main image
                if (widget.offer.vehicleMainImage != null)
                  SizedBox(
                    width: double.infinity,
                    child: Image.network(
                      widget.offer.vehicleMainImage!,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 20),

                /// Editable fields
                _buildEditableDetailRow(
                  'Vehicle:',
                  _vehicleMakeModelController,
                ),
                _buildEditableDetailRow(
                  'Offer Amount:',
                  _offerAmountController,
                ),

                /// Non-editable fields
                _buildDetailRow('Status:', widget.offer.offerStatus),
                _buildDealerEmailRow(userProvider, widget.offer.dealerId),
                const SizedBox(height: 20),

                /// If offer is in-progress, show Approve/Reject
                if (widget.offer.offerStatus == 'in-progress')
                  // Wrap Row in a Container with a finite width
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CustomButton(
                            text: 'Approve',
                            borderColor: Colors.blue,
                            onPressed: () async {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('offers')
                                    .doc(widget.offer.offerId)
                                    .update({'offerStatus': 'accepted'});

                                if (mounted) {
                                  setState(() {});
                                  Navigator.pop(context);
                                }
                              } catch (e, stackTrace) {
                                debugPrint('Exception in approve: $e');
                                debugPrint('Stack trace: $stackTrace');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Failed to approve the offer. Please try again.\nError: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          CustomButton(
                            text: 'Reject',
                            borderColor: const Color(0xFFFF4E00),
                            onPressed: () async {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('offers')
                                    .doc(widget.offer.offerId)
                                    .update({'offerStatus': 'rejected'});

                                if (mounted) {
                                  setState(() {});
                                  Navigator.pop(context);
                                }
                              } catch (e, stackTrace) {
                                debugPrint('Exception in reject: $e');
                                debugPrint('Stack trace: $stackTrace');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Failed to reject the offer. Please try again.\nError: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                /// Payment pending
                if (widget.offer.offerStatus == 'payment pending')
                  Column(
                    children: [
                      if (widget.offer.proofOfPayment != null)
                        Container(
                          height: 200,
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.offer.proofOfPayment!,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                    child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                    child: Text('Error loading image'));
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),

                      /// Wrap Row in a Container with a finite width
                      Container(
                        width: MediaQuery.of(context).size.width,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            CustomButton(
                              text: 'Verify Payment',
                              borderColor: Colors.green,
                              onPressed: () {
                                offerProvider.updateOfferStatus(
                                  widget.offer.offerId,
                                  'paid',
                                );
                                Navigator.pop(context);
                              },
                            ),
                            const SizedBox(width: 16),
                            CustomButton(
                              text: 'Reject Payment',
                              borderColor: Colors.red,
                              onPressed: () {
                                offerProvider.updateOfferStatus(
                                  widget.offer.offerId,
                                  'payment_rejected',
                                );
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                /// If accepted, show inspection/collection setup
                if (widget.offer.offerStatus == 'accepted')
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('vehicles')
                        .doc(widget.offer.vehicleId)
                        .snapshots(),
                    builder: (context, vehicleSnapshot) {
                      if (!vehicleSnapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      Map<String, dynamic> vehicleData =
                          vehicleSnapshot.data!.data() as Map<String, dynamic>;

                      List<Map<String, dynamic>> inspectionLocations =
                          _parseLocations(
                        vehicleData['inspectionDetails']?['inspectionLocations']
                            ?['locations'] as List<dynamic>?,
                      );

                      List<Map<String, dynamic>> collectionLocations =
                          _parseLocations(
                        vehicleData['collectionDetails']?['collectionLocations']
                            ?['locations'] as List<dynamic>?,
                      );

                      bool isInspectionComplete =
                          inspectionLocations.isNotEmpty;
                      bool isCollectionComplete =
                          collectionLocations.isNotEmpty;

                      return Column(
                        children: [
                          const SizedBox(height: 20),
                          isInspectionComplete
                              ? Text(
                                  'Inspection Setup Complete',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : CustomButton(
                                  text: 'Setup Inspection',
                                  borderColor: Colors.blue,
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SetupInspectionPage(
                                        vehicleId: widget.offer.vehicleId,
                                      ),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 16),
                          isCollectionComplete
                              ? Text(
                                  'Collection Setup Complete',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : CustomButton(
                                  text: 'Setup Collection',
                                  borderColor: Colors.blue,
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SetupCollectionPage(
                                        vehicleId: widget.offer.vehicleId,
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      );
                    },
                  ),

                const SizedBox(height: 20),

                /// Another Approve/Reject row for 'in-progress' if you still need it
                if (widget.offer.offerStatus == 'in-progress')
                  // Also wrap in a Container with a finite width
                  Container(
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomButton(
                          text: 'Approve',
                          borderColor: Colors.blue,
                          onPressed: () async {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('offers')
                                  .doc(widget.offer.offerId)
                                  .update({'offerStatus': 'accepted'});

                              if (mounted) {
                                setState(() {});
                                Navigator.pop(context);
                              }
                            } catch (e, stackTrace) {
                              debugPrint('Exception in approve: $e');
                              debugPrint('Stack trace: $stackTrace');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Failed to approve the offer. Please try again.\nError: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        if (widget.offer.offerStatus != 'rejected')
                          CustomButton(
                            text: 'Reject',
                            borderColor: Colors.red,
                            onPressed: () {
                              offerProvider.updateOfferStatus(
                                  widget.offer.offerId, 'rejected');
                              Navigator.pop(context);
                            },
                          ),
                      ],
                    ),
                  )
                else
                  Center(
                    child: Text(
                      widget.offer.offerStatus == 'rejected'
                          ? 'This offer has been rejected'
                          : 'Offer Status: ${widget.offer.offerStatus}',
                      style: GoogleFonts.montserrat(
                        color: widget.offer.offerStatus == 'rejected'
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                /// Save changes
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: CustomButton(
                      text: 'Save Changes',
                      borderColor: Colors.deepOrange,
                      onPressed: () {
                        offerProvider.updateOfferAmount(
                          widget.offer.offerId,
                          double.tryParse(_offerAmountController.text) ?? 0.0,
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper to parse location arrays safely
  List<Map<String, dynamic>> _parseLocations(List<dynamic>? rawList) {
    if (rawList == null || rawList.isEmpty) {
      return [];
    }
    try {
      return rawList
          .where((e) => e != null)
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error parsing locations: $e');
      return [];
    }
  }

  /// Displays a non-editable row with a label and value
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                color: Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Displays an editable row with a label and a TextField
  Widget _buildEditableDetailRow(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              style: GoogleFonts.montserrat(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Asynchronously fetches the Dealer's email and displays it
  Widget _buildDealerEmailRow(UserProvider userProvider, String dealerId) {
    return FutureBuilder<String?>(
      future: userProvider.getUserEmailById(dealerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDetailRow('Dealer Email:', 'Loading...');
        } else if (snapshot.hasError) {
          return _buildDetailRow('Dealer Email:', 'Error loading email');
        } else {
          return _buildDetailRow('Dealer Email:', snapshot.data ?? 'Unknown');
        }
      },
    );
  }
}
