import 'package:ctp/pages/payment_approved.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'offer_summary_page.dart';
import 'payment_pending_page.dart';
import 'package:ctp/components/custom_bottom_navigation.dart'; // Ensure this import is correct

class PaymentOptionsPage extends StatefulWidget {
  final String offerId;

  const PaymentOptionsPage({super.key, required this.offerId});

  @override
  _PaymentOptionsPageState createState() => _PaymentOptionsPageState();
}

class _PaymentOptionsPageState extends State<PaymentOptionsPage> {
  int _selectedIndex =
      0; // Variable to keep track of the selected bottom nav item

  @override
  void initState() {
    super.initState();
    _updateOfferStatus(); // Update the offer status when the page loads
  }

  Future<void> _updateOfferStatus() async {
    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({'offerStatus': 'payment options'});

      print('Offer status updated to "payment options"');
    } catch (e) {
      print('Failed to update offer status: $e');
      // Handle error
    }
  }

  Future<void> _navigateBasedOnStatus(BuildContext context) async {
    try {
      DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .get();
      if (offerSnapshot.exists) {
        String paymentStatus = offerSnapshot['paymentStatus'];
        if (paymentStatus == 'approved') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PaymentApprovedPage(offerId: widget.offerId),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentPendingPage(offerId: widget.offerId),
            ),
          );
        }
      } else {
        print('Offer not found');
        // Handle offer not found case
      }
    } catch (e) {
      print('Error fetching offer: $e');
      // Handle error
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
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
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
                        const SizedBox(height: 16),
                        Image.asset('lib/assets/CTPLogo.png'),
                        const SizedBox(height: 16),
                        const Text(
                          'PAYMENT OPTIONS',
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
                  ),
                ),
              ),
              Column(
                children: [
                  CustomButton(
                    text: 'GENERATE INVOICE',
                    borderColor: const Color(0xFFFF4E00),
                    onPressed: () {
                      // Handle generate invoice action
                    },
                  ),
                  CustomButton(
                    text: 'PAY ONLINE NOW',
                    borderColor: const Color(0xFFFF4E00),
                    onPressed: () {
                      // Handle pay online now action
                    },
                  ),
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
                  CustomButton(
                    text: 'CONTINUE',
                    borderColor: const Color(0xFFFF4E00),
                    onPressed: () {
                      _navigateBasedOnStatus(context);
                    },
                  ),
                  const SizedBox(
                      height: 16), // Added spacing for bottom padding
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
