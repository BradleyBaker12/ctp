import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdjustOfferPage extends StatefulWidget {
  final String oldOffer;
  final String vehicleName;

  const AdjustOfferPage({
    super.key,
    required this.oldOffer,
    required this.vehicleName,
  });

  @override
  _AdjustOfferPageState createState() => _AdjustOfferPageState();
}

class _AdjustOfferPageState extends State<AdjustOfferPage> {
  int _selectedIndex = 1;
  final TextEditingController _newOfferController = TextEditingController();
  double discount = 0.0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _updateDiscount() {
    double oldOfferValue = double.tryParse(
            widget.oldOffer.replaceAll('R', '').replaceAll(' ', '')) ??
        0.0;
    double newOffer =
        double.tryParse(_newOfferController.text.replaceAll(' ', '')) ?? 0.0;

    setState(() {
      discount = oldOfferValue - newOffer;
    });
  }

  String formatWithSpacing(String number) {
    number = number.replaceAll(RegExp(r'\s+'), ''); // Remove existing spaces
    List<String> parts =
        number.split('.'); // Split the number by the decimal point
    String integerPart = parts[0]; // Get the integer part of the number
    String decimalPart = parts.length > 1
        ? '.${parts[1]}'
        : ''; // Get the decimal part if it exists

    String formatted = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formatted += ' '; // Add a space every 3 digits
      }
      formatted += integerPart[i];
    }

    return formatted +
        decimalPart; // Concatenate the formatted integer part with the decimal part
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Image.asset('lib/assets/CTPLogo.png'),
                  const SizedBox(height: 16),
                  Text(
                    'ADJUST OFFER',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Not happy with your offer after inspection?',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please adjust your offer here. Note that the new offer will be sent to the transporter first for approval.',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.vehicleName,
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _buildOfferLabel('OLD OFFER'),
                  _buildOfferRow(
                      'R ${formatWithSpacing(widget.oldOffer.replaceAll('R', '').replaceAll(',', ''))}',
                      const Color(0xFF2F7FFF)),
                  const SizedBox(height: 16),
                  _buildOfferLabel('NEW OFFER'),
                  _buildNewOfferInput(),
                  const SizedBox(height: 16),
                  _buildOfferLabel('DISCOUNT'),
                  _buildOfferRow(
                      'R ${formatWithSpacing(discount.toStringAsFixed(2))}',
                      const Color(0xFFFF4E00)),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Submit',
                    borderColor: const Color(0xFFFF4E00),
                    onPressed: () async {
                      // Check if the new offer is a valid number
                      double newOfferValue = double.tryParse(
                              _newOfferController.text.replaceAll(' ', '')) ??
                          0.0;
                      if (newOfferValue <= 0) {
                        // Show some error message or feedback to the user
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Please enter a valid new offer amount.'),
                          ),
                        );
                        return;
                      }

                      // Calculate the discount
                      double oldOfferValue = double.tryParse(widget.oldOffer
                              .replaceAll('R', '')
                              .replaceAll(' ', '')) ??
                          0.0;
                      double discountValue = oldOfferValue - newOfferValue;

                      try {
                        // Reference to the specific offer document in Firebase
                        DocumentReference offerRef = FirebaseFirestore.instance
                            .collection('offers')
                            .doc(
                                'f9AYrUNp7gDxIkomZbzp'); // Replace with widget.offerId if dynamic

                        // Update the offer document
                        await offerRef.update({
                          'offerAmount': newOfferValue,
                          'discount': discountValue,
                          'oldOffer':
                              oldOfferValue, // Optional: if you want to store the old offer
                          'offerStatus':
                              'in-progress', // Set offerStatus back to in-progress
                        });

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Offer updated successfully.'),
                          ),
                        );

                        // Navigate back or to another page
                        Navigator.of(context).pop();
                      } catch (e) {
                        // Handle errors, e.g., show an error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Failed to update the offer. Please try again.'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildOfferLabel(String label) {
    return Align(
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 14,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildOfferRow(String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      height: 60.0, // Set a fixed height for consistency
      decoration: BoxDecoration(
        color: color
            .withOpacity(0.2), // Add background color with some transparency
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        // Center the text vertically and horizontally
        child: Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Set text color to white
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildNewOfferInput() {
    return Container(
      height: 60.0, // Set a fixed height for consistency
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey
            .withOpacity(0.2), // Add background color with some transparency
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey, width: 2),
      ),
      child: TextField(
        controller: _newOfferController,
        keyboardType: TextInputType.number,
        style: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white, // Set text color to white
        ),
        textAlign: TextAlign.center,
        textAlignVertical:
            TextAlignVertical.center, // Ensure hint text is centered vertically
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Enter new offer',
          hintStyle: TextStyle(color: Colors.grey),
        ),
        onChanged: (value) {
          _updateDiscount(); // Update discount when new offer changes
        },
      ),
    );
  }
}
