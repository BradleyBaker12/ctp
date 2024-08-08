import 'package:ctp/pages/rating_pages/rate_transporter_page.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';

class FinalInspectionApprovalPage extends StatelessWidget {
  final String offerId; // Add offerId parameter

  const FinalInspectionApprovalPage({Key? key, required this.offerId})
      : super(key: key);

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
                    'FINAL INSPECTION APPROVAL',
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
                    'By approving the transaction, you confirm that all conditions have been met to your satisfaction. If there are any issues, please select "Report an Issue" to provide details. Our team is here to assist you in resolving any concerns.',
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
                    text: 'APPROVE',
                    borderColor: Colors.blue,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RateTransporterPage(
                            offerId: offerId,
                            fromCollectionPage: false,
                          ), // Pass the offerId
                        ),
                      );
                    },
                  ),
                  CustomButton(
                    text: 'ADJUST OFFER',
                    borderColor: Colors.blue,
                    onPressed: () {
                      // Handle adjust offer action
                    },
                  ),
                  CustomButton(
                    text: 'REPORT AN ISSUE',
                    borderColor: Colors.orange,
                    onPressed: () {
                      // Handle report an issue action
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
