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
  bool _proofOfPaymentUploaded = false; // Track proof of payment status

  @override
  void initState() {
    super.initState();
    _updateOfferStatus(); // Update the offer status to "payment pending"
    _checkPaymentStatus();
    _checkProofOfPayment(); // Check if proof of payment is already uploaded
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

  Future<void> _checkProofOfPayment() async {
    try {
      DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .get();

      if (offerSnapshot.exists) {
        String? proofOfPaymentUrl = offerSnapshot['proofOfPaymentUrl'];
        setState(() {
          _proofOfPaymentUploaded =
              proofOfPaymentUrl != null && proofOfPaymentUrl.isNotEmpty;
        });
      }
    } catch (e) {
      print('Error checking proof of payment: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Optional: Refresh the proof of payment status when the page is resumed
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkProofOfPayment();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = userProvider.getUserRole ?? '';

    return Scaffold(
      body: GradientBackground(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
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
                  Column(
                    children: [
                      // Conditionally display the "UPLOAD PROOF OF PAYMENT" button
                      if (userRole != 'transporter' && !_proofOfPaymentUploaded)
                        CustomButton(
                          text: 'UPLOAD PROOF OF PAYMENT',
                          borderColor: Colors.blue,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UploadProofOfPaymentPage(
                                    offerId: widget.offerId),
                              ),
                            ).then((_) {
                              // Refresh the proof of payment status when returning
                              _checkProofOfPayment();
                            });
                          },
                        ),
                      // Optionally, display a message or another widget indicating that the proof has been uploaded
                      if (_proofOfPaymentUploaded && userRole != 'transporter')
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Proof of payment has been uploaded.',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
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
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
