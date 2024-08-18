import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/pages/report_issue.dart';
import 'package:ctp/pages/upload_pop.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/pages/payment_approved.dart';
import 'package:ctp/components/custom_bottom_navigation.dart'; // Ensure this import is correct

class PaymentPendingPage extends StatefulWidget {
  final String offerId;

  const PaymentPendingPage({super.key, required this.offerId});

  @override
  _PaymentPendingPageState createState() => _PaymentPendingPageState();
}

class _PaymentPendingPageState extends State<PaymentPendingPage> {
  int _selectedIndex =
      0; // Variable to keep track of the selected bottom nav item

  @override
  void initState() {
    super.initState();
    _updateOfferStatus(); // Update the offer status to "payment pending"
    _checkPaymentStatus();
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
    }
  }

  Future<void> _checkPaymentStatus() async {
    try {
      DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .get();

      if (offerSnapshot.exists) {
        String paymentStatus = offerSnapshot['paymentStatus'];

        if (paymentStatus == 'accepted') {
          // Update the offer status to "Payment Approved"
          await FirebaseFirestore.instance
              .collection('offers')
              .doc(widget.offerId)
              .update({'offerStatus': 'paid'});

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PaymentApprovedPage(offerId: widget.offerId),
            ),
          );
        } else {
          // Keep checking the payment status if not yet accepted
          Future.delayed(const Duration(seconds: 5), _checkPaymentStatus);
        }
      }
    } catch (e) {
      print('Error checking payment status: $e');
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
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
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
                  const Text(
                    'PAYMENT PENDING',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "You're almost there!",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Full payment needs to reflect before arranging collection. If payment is not made within 3 days, the transaction will be cancelled and other dealers will be able to offer again.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              Column(
                children: [
                  CustomButton(
                    text: 'UPLOAD PROOF OF PAYMENT',
                    borderColor: Colors.blue,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UploadProofOfPaymentPage(offerId: widget.offerId),
                        ),
                      );
                    },
                  ),
                  CustomButton(
                    text: 'REPORT AN ISSUE',
                    borderColor: const Color(0xFFFF4E00),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportIssuePage(),
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
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
