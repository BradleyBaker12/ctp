import 'package:ctp/pages/adjust_offer.dart';
import 'package:ctp/pages/rating_pages/rate_transporter_page.dart';
import 'package:ctp/pages/report_issue.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/offer_provider.dart';

class FinalInspectionApprovalPage extends StatefulWidget {
  final String offerId;
  final String oldOffer;
  final String vehicleName;

  const FinalInspectionApprovalPage({
    super.key,
    required this.offerId,
    required this.oldOffer,
    required this.vehicleName,
  });

  @override
  _FinalInspectionApprovalPageState createState() =>
      _FinalInspectionApprovalPageState();
}

class _FinalInspectionApprovalPageState
    extends State<FinalInspectionApprovalPage> {
  int _selectedIndex = 1;
  bool _isLoading = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _navigateToRateTransporterPage(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    OfferProvider offerProvider =
        Provider.of<OfferProvider>(context, listen: false);
    await offerProvider.fetchOffers('JdTI3IY7WcRQne7QnyDp1O7p7Xg2', 'dealer');

    setState(() {
      _isLoading = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RateTransporterPage(
          offerId: widget.offerId,
          fromCollectionPage: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GradientBackground(
            child: SizedBox.expand(
              child: Stack(
                children: [
                  SingleChildScrollView(
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
                        const SizedBox(height: 60),
                        Image.asset('lib/assets/CTPLogo.png'),
                        const SizedBox(height: 40),
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
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomButton(
                          text: 'APPROVE',
                          borderColor: Colors.blue,
                          onPressed: () {
                            _navigateToRateTransporterPage(context);
                          },
                        ),
                        CustomButton(
                          text: 'ADJUST OFFER',
                          borderColor: Colors.blue,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdjustOfferPage(
                                  oldOffer: widget.oldOffer,
                                  vehicleName: widget.vehicleName,
                                ),
                              ),
                            );
                          },
                        ),
                        CustomButton(
                          text: 'REPORT AN ISSUE',
                          borderColor: Color(0xFFFF4E00),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportIssuePage(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
