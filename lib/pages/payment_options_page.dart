import 'package:ctp/pages/payment_approved.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'offer_summary_page.dart';
import 'payment_pending_page.dart';

class PaymentOptionsPage extends StatelessWidget {
  final String offerId;

  const PaymentOptionsPage({Key? key, required this.offerId}) : super(key: key);

  Future<void> _navigateBasedOnStatus(BuildContext context) async {
    try {
      DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .doc(offerId)
          .get();
      if (offerSnapshot.exists) {
        String paymentStatus = offerSnapshot['paymentStatus'];
        if (paymentStatus == 'approved') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentApprovedPage(offerId: offerId),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentPendingPage(offerId: offerId),
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

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore.instance
        .collection('offers')
        .doc(offerId)
        .update({'offerStatus': '2/4'});
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
              Column(
                children: [
                  CustomButton(
                    text: 'GENERATE INVOICE',
                    borderColor: Colors.orange,
                    onPressed: () {
                      // Handle generate invoice action
                    },
                  ),
                  CustomButton(
                    text: 'PAY ONLINE NOW',
                    borderColor: Colors.orange,
                    onPressed: () {
                      // Handle pay online now action
                    },
                  ),
                  CustomButton(
                    text: 'SEND OFFER SUMMARY',
                    borderColor: Colors.orange,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              OfferSummaryPage(offerId: offerId),
                        ),
                      );
                    },
                  ),
                  CustomButton(
                    text: 'CONTINUE',
                    borderColor: Colors.orange,
                    onPressed: () {
                      _navigateBasedOnStatus(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
