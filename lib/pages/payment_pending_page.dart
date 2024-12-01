// File: payment_pending_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/pages/report_issue.dart';
import 'package:ctp/pages/upload_pop.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/pages/payment_approved.dart';
import 'package:ctp/components/custom_bottom_navigation.dart'; // Ensure this import is correct
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';

class PaymentPendingPage extends StatefulWidget {
  final String offerId;

  const PaymentPendingPage({super.key, required this.offerId});

  @override
  _PaymentPendingPageState createState() => _PaymentPendingPageState();
}

class _PaymentPendingPageState extends State<PaymentPendingPage> {
  int _selectedIndex =
      0; // Variable to keep track of the selected bottom nav item
  bool _hasNavigated = false; // Flag to prevent multiple navigations

  @override
  void initState() {
    super.initState();
    _updateOfferStatus(); // Update the offer status to "payment pending"
    // No need for manual payment status checking as StreamBuilder handles real-time updates
  }

  Future<void> _updateOfferStatus() async {
    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({
        'offerStatus': 'payment pending'
      }); // Update status to "payment pending"
    } catch (e) {
      print('Error updating offer status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating offer status: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = userProvider.getUserRole ?? '';

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('offers')
            .doc(widget.offerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return GradientBackground(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return GradientBackground(
              child: Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return GradientBackground(
              child: Center(
                child: Text(
                  'Offer not found.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            );
          }

          var offerData = snapshot.data!;
          String paymentStatus = offerData['paymentStatus'] ?? '';
          String? proofOfPaymentUrl = offerData['proofOfPaymentUrl'];

          // Navigate to PaymentApprovedPage if paymentStatus is 'accepted'
          if (paymentStatus == 'accepted' && !_hasNavigated) {
            _hasNavigated =
                true; // Set the flag to prevent multiple navigations
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PaymentApprovedPage(offerId: widget.offerId),
                ),
              );
            });
          }

          bool proofOfPaymentUploaded =
              proofOfPaymentUrl != null && proofOfPaymentUrl.isNotEmpty;

          return GradientBackground(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Content
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Image.asset('lib/assets/CTPLogo.png'),
                          const SizedBox(height: 100),
                          const Text(
                            'PAYMENT PENDING',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
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
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
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
                        ],
                      ),
                      // Bottom Buttons
                      Column(
                        children: [
                          // Conditionally display the "UPLOAD PROOF OF PAYMENT" button
                          if (userRole != 'transporter' &&
                              !proofOfPaymentUploaded)
                            CustomButton(
                              text: 'UPLOAD PROOF OF PAYMENT',
                              borderColor: Colors.blue,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        UploadProofOfPaymentPage(
                                      offerId: widget.offerId,
                                    ),
                                  ),
                                );
                              },
                            ),
                          // Display confirmation message if proof is uploaded
                          if (proofOfPaymentUploaded)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.green, size: 60),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Proof of payment has been uploaded.',
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          CustomButton(
                            text: 'REPORT AN ISSUE',
                            borderColor: const Color(0xFFFF4E00),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReportIssuePage(
                                    offerId: widget.offerId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
