import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    _updateOfferStatus();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _updateOfferStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({'offerStatus': 'Inspection Done'});
    } catch (e) {
      print('Failed to update offer status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

    // Update offer status to "Done" before navigating
    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({'offerStatus': 'Done'});
      print('Offer status updated to Done');
    } catch (e) {
      print('Failed to update offer status to Done: $e');
    }

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
    final screenSize = MediaQuery.of(context).size;
    final padding = screenSize.width * 0.05;
    final buttonWidth = screenSize.width * 0.85;
    final logoHeight = screenSize.height * 0.15;
    final spacing = screenSize.height * 0.02;

    return Scaffold(
      body: Stack(
        children: [
          GradientBackground(
            child: SizedBox.expand(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: spacing),
                          Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          SizedBox(height: spacing),
                          SizedBox(
                            width: 250,
                            height: 250,
                            child: Image.asset(
                              'lib/assets/CTPLogo.png',
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'FINAL INSPECTION APPROVAL',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: spacing),
                          const Text(
                            "You're almost there!",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: spacing),
                          const Text(
                            'By approving the transaction, you confirm that all conditions have been met to your satisfaction. If there are any issues, please select "Report an Issue" to provide details. Our team is here to assist you in resolving any concerns.',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: spacing),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: spacing),
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
                                    offerId: widget.offerId,
                                  ),
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
                                  builder: (context) => ReportIssuePage(
                                    offerId: widget.offerId,
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: spacing),
                        ],
                      ),
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
