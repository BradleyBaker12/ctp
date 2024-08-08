import 'package:ctp/pages/rating_pages/rate_transporter_page.dart';
import 'package:ctp/pages/report_issue.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';

import 'package:ctp/components/custom_bottom_navigation.dart'; // Ensure this import is correct

class FinalInspectionApprovalPage extends StatefulWidget {
  final String offerId; // Add offerId parameter

  const FinalInspectionApprovalPage({super.key, required this.offerId});

  @override
  _FinalInspectionApprovalPageState createState() =>
      _FinalInspectionApprovalPageState();
}

class _FinalInspectionApprovalPageState
    extends State<FinalInspectionApprovalPage> {
  int _selectedIndex =
      1; // Variable to keep track of the selected bottom nav item

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
                            offerId: widget.offerId,
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
