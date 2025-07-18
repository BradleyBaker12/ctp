import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/offer_provider.dart';

import 'package:auto_route/auto_route.dart';

@RoutePage()
class AdjustOfferPage extends StatefulWidget {
  final String offerId;

  const AdjustOfferPage({
    super.key,
    required this.offerId,
  });

  @override
  _AdjustOfferPageState createState() => _AdjustOfferPageState();
}

class _AdjustOfferPageState extends State<AdjustOfferPage> {
  int _selectedIndex = 1;
  final TextEditingController _newOfferController = TextEditingController();
  double discount = 0.0;

  @override
  void initState() {
    super.initState();
    // Fetch the offer details when the page initializes
    Provider.of<OfferProvider>(context, listen: false)
        .fetchOfferById(widget.offerId);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _updateDiscount(double oldOfferValue) {
    int newOffer =
        int.tryParse(_newOfferController.text.replaceAll(' ', '')) ?? 0;

    // Ensure the new offer is not greater than the old offer
    if (newOffer > oldOfferValue) {
      // Show a message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New offer cannot be higher than the old offer.'),
        ),
      );

      // Set the discount to zero to prevent negative values
      setState(() {
        discount = 0.0;
      });

      // Optionally, clear the input field or reset it to the old offer value
      _newOfferController
          .clear(); // or _newOfferController.text = oldOfferValue.toString();
    } else {
      setState(() {
        discount = oldOfferValue - newOffer;
      });
    }
  }

  String formatWithSpacing(String number) {
    number = number.replaceAll(RegExp(r'\s+'), ''); // Remove existing spaces
    String formatted = '';
    for (int i = 0; i < number.length; i++) {
      if (i > 0 && (number.length - i) % 3 == 0) {
        formatted += ' '; // Add a space every 3 digits
      }
      formatted += number[i];
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    // Access the OfferProvider
    OfferProvider offerProvider = Provider.of<OfferProvider>(context, listen: false);
    Offer? offer = offerProvider.getOfferById(widget.offerId);

    if (offer == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                  const SizedBox(height: 30),
                  Image.asset('lib/assets/CTPLogo.png'),
                  const SizedBox(height: 30),
                  Text(
                    'ADJUST OFFER',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Not happy with your offer after inspection?',
                    style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 32),
                  Text(
                    offer.vehicleMakeModel ?? 'Unknown Vehicle',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 26),
                  _buildOfferLabel('OLD OFFER'),
                  _buildOfferRow(
                      'R ${formatWithSpacing(offer.offerAmount?.toInt().toString() ?? '0')}',
                      const Color(0xFF2F7FFF)),
                  const SizedBox(height: 25),
                  _buildOfferLabel('NEW OFFER'),
                  _buildNewOfferInput(offer.offerAmount ?? 0.0),
                  const SizedBox(height: 25),
                  _buildOfferLabel('DISCOUNT'),
                  _buildOfferRow(
                      'R ${formatWithSpacing(discount.toStringAsFixed(0))}',
                      const Color(0xFFFF4E00)),
                  const SizedBox(height: 25),
                  CustomButton(
                    text: 'Submit',
                    borderColor: const Color(0xFFFF4E00),
                    onPressed: () async {
                      // Check if the new offer is a valid number
                      int newOfferValue = int.tryParse(
                              _newOfferController.text.replaceAll(' ', '')) ??
                          0;
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

                      try {
                        // Save the old offer amount and update the offer with the new amount and status
                        await FirebaseFirestore.instance
                            .collection('offers')
                            .doc(widget.offerId)
                            .update({
                          'oldOfferAmount': offer.offerAmount
                              ?.toInt(), // Save the old offer amount
                          'offerAmount':
                              newOfferValue, // Update to the new offer amount
                          'offerStatus':
                              'in-progress', // Update status to in-progress
                        });

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Offer updated successfully.'),
                          ),
                        );

                        // Navigate back to the home page
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/home', (route) => false);
                      } catch (e) {
                        print(
                            "Adjust offer error: $e"); // Handle errors, e.g., show an error message
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

  Widget _buildNewOfferInput(double oldOfferValue) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 16.0),
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
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly, // Allow only digits
          // Add a custom TextInputFormatter to add spaces
          TextInputFormatter.withFunction((oldValue, newValue) {
            // Remove spaces
            String newText = newValue.text.replaceAll(' ', '');

            // Add spaces every 3 digits
            String formattedText = '';
            for (int i = 0; i < newText.length; i++) {
              if (i > 0 && (newText.length - i) % 3 == 0) {
                formattedText += ' ';
              }
              formattedText += newText[i];
            }

            // Return the formatted value
            return TextEditingValue(
              text: formattedText,
              selection: TextSelection.collapsed(offset: formattedText.length),
            );
          }),
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Enter new offer',
          hintStyle: TextStyle(color: Colors.grey),
        ),
        onChanged: (value) {
          _updateDiscount(
              oldOfferValue); // Update discount when new offer changes
        },
      ),
    );
  }
}
