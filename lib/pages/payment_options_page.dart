// lib/adminScreens/payment_options_page.dart

// ignore_for_file: unused_local_variable

import 'package:ctp/pages/payment_approved.dart';
import 'package:ctp/pages/payment_pending_page.dart';
import 'package:ctp/pages/offer_summary_page.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentOptionsPage extends StatefulWidget {
  final String offerId;

  const PaymentOptionsPage({super.key, required this.offerId});

  @override
  _PaymentOptionsPageState createState() => _PaymentOptionsPageState();
}

class _PaymentOptionsPageState extends State<PaymentOptionsPage> {
  int _selectedIndex = 0; // For bottom navigation

  @override
  void initState() {
    super.initState();
    _updateOfferStatus(); // Update the offer status when the page loads
  }

  /// Update the offer status to 'payment options' upon page load
  Future<void> _updateOfferStatus() async {
    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({'offerStatus': 'payment options'});

      print('Offer status updated to "payment options"');
    } catch (e) {
      print('Failed to update offer status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update offer status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Navigate based on payment status
  Future<void> _navigateBasedOnStatus(
      BuildContext context, String? paymentStatus) async {
    if (paymentStatus == 'approved') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentApprovedPage(offerId: widget.offerId),
        ),
      );
    } else if (paymentStatus == 'pending') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPendingPage(offerId: widget.offerId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unknown payment status: $paymentStatus'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Handle "Generate Invoice" button press
  Future<void> _handleGenerateInvoice(DocumentSnapshot offerSnapshot) async {
    final offerData = offerSnapshot.data() as Map<String, dynamic>;
    final String? externalInvoice = offerData['externalInvoice'];

    if (externalInvoice != null && externalInvoice.isNotEmpty) {
      // **Step 1:** Invoice exists, allow user to view it
      if (await canLaunch(externalInvoice)) {
        await launch(externalInvoice);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch invoice URL'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // **Step 2:** Invoice not uploaded, send a message by setting 'needsInvoice' flag
      try {
        await FirebaseFirestore.instance
            .collection('offers')
            .doc(widget.offerId)
            .update({'needsInvoice': true});

        // **Step 3:** Notify the user that the admin has been notified
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice not uploaded. Admin notified.'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        print('Failed to send invoice request: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('offers')
              .doc(widget.offerId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error fetching offer details',
                  style: GoogleFonts.montserrat(color: Colors.red),
                ),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Text(
                  'Offer not found',
                  style: GoogleFonts.montserrat(color: Colors.red),
                ),
              );
            }

            final offerData = snapshot.data!.data() as Map<String, dynamic>;

            final String offerStatus = offerData['offerStatus'] ?? '';
            final String? externalInvoice = offerData['externalInvoice'];
            final String? paymentStatus = offerData['paymentStatus'];

            // **Determine if "Continue" button should be enabled based on Firestore data**
            bool isContinueEnabled =
                externalInvoice != null && externalInvoice.isNotEmpty;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                    const SizedBox(height: 64),
                    Text(
                      'PAYMENT OPTIONS',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "You're almost there!",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(
                      width: 350,
                      child: Text(
                        'Full payment needs to reflect before arranging collection. If payment is not made within 3 days, the transaction will be cancelled and other dealers will be able to offer again.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32), // Spacing before buttons

                    /// **Step 1 & Step 2 Buttons**
                    CustomButton(
                      text:
                          externalInvoice != null && externalInvoice.isNotEmpty
                              ? 'VIEW INVOICE'
                              : 'GENERATE INVOICE',
                      borderColor: const Color(0xFFFF4E00),
                      onPressed: () => _handleGenerateInvoice(snapshot.data!),
                    ),
                    const SizedBox(height: 16),

                    CustomButton(
                      text: 'PAY ONLINE NOW',
                      borderColor: const Color(0xFFFF4E00),
                      onPressed: () {
                        // Implement online payment functionality here
                        // For example, navigate to a payment gateway page
                      },
                    ),
                    const SizedBox(height: 16),

                    CustomButton(
                      text: 'SEND OFFER SUMMARY',
                      borderColor: const Color(0xFFFF4E00),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OfferSummaryPage(offerId: widget.offerId),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    /// **"Continue" Button**
                    CustomButton(
                      text: 'CONTINUE',
                      borderColor: const Color(0xFFFF4E00),
                      onPressed: isContinueEnabled
                          ? () {
                              _navigateBasedOnStatus(context, paymentStatus);
                            }
                          : null, // Disable if invoice not uploaded
                      // Optionally, adjust appearance when disabled
                      disabledColor: Colors.grey,
                    ),
                    const SizedBox(height: 16), // Bottom padding
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
