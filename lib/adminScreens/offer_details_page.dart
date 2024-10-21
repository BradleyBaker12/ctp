import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/offer_provider.dart';
import '../providers/user_provider.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';

class OfferDetailPage extends StatefulWidget {
  final Offer offer;

  const OfferDetailPage({super.key, required this.offer});

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
    final offerProvider = Provider.of<OfferProvider>(context);
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
          iconTheme: IconThemeData(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Image
                  if (widget.offer.vehicleMainImage != null)
                    SizedBox(
                      width: double.infinity,
                      child: Image.network(
                        widget.offer.vehicleMainImage!,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  SizedBox(height: 20),
                  // Editable Offer Information
                  _buildEditableDetailRow(
                      'Vehicle:', _vehicleMakeModelController),
                  _buildEditableDetailRow(
                      'Offer Amount:', _offerAmountController),
                  _buildDetailRow('Status:', widget.offer.offerStatus),
                  _buildDealerEmailRow(userProvider, widget.offer.dealerId),
                  SizedBox(height: 20),
                  // Additional Information
                  Text(
                    'Additional Information',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  _buildEditableDetailRow('Year:', _vehicleYearController),
                  _buildEditableDetailRow(
                      'Mileage:', _vehicleMileageController),
                  _buildEditableDetailRow(
                      'Transmission:', _vehicleTransmissionController),
                  SizedBox(height: 20),
                  // Actions
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Approve',
                            borderColor: Colors.green,
                            onPressed: () {
                              // Approve offer logic
                              offerProvider.updateOfferStatus(
                                  widget.offer.offerId, 'approved');
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: CustomButton(
                            text: 'Reject',
                            borderColor: Colors.red,
                            onPressed: () {
                              // Reject offer logic
                              offerProvider.updateOfferStatus(
                                  widget.offer.offerId, 'rejected');
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: CustomButton(
                      text: 'Save Changes',
                      borderColor: Colors.deepOrange,
                      onPressed: () {
                        // Save changes logic
                        offerProvider.updateOfferAmount(
                            widget.offer.offerId,
                            double.tryParse(_offerAmountController.text) ??
                                0.0);
                        // Update other details in Firestore
                        FirebaseFirestore.instance
                            .collection('offers')
                            .doc(widget.offer.offerId)
                            .update({
                          'vehicleMakeModel': _vehicleMakeModelController.text,
                          'vehicleYear': _vehicleYearController.text,
                          'vehicleMileage': _vehicleMileageController.text,
                          'vehicleTransmission':
                              _vehicleTransmissionController.text,
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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

  Widget _buildEditableDetailRow(
      String label, TextEditingController controller) {
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
