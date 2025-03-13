import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/pages/adjust_offer.dart';
import 'package:ctp/pages/rating_pages/rate_dealer_page_two.dart';
import 'package:ctp/pages/rating_pages/rate_transporter_page.dart';
// Import RateDealerPage
import 'package:ctp/pages/report_issue.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  Future<void> _approveInspection(String userRole) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String fieldToUpdate =
          userRole == 'dealer' ? 'dealerApproved' : 'transporterApproved';

      // Update Firestore to mark the approval status for the respective role
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({fieldToUpdate: true});

      // Check if both the dealer and transporter have approved
      DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .get();

      Map<String, dynamic> data = offerSnapshot.data() as Map<String, dynamic>;
      bool dealerApproved = data['dealerApproved'] ?? false;
      bool transporterApproved = data['transporterApproved'] ?? false;

      // Navigate to the appropriate rating page only if both parties have approved
      if (dealerApproved && transporterApproved) {
        await FirebaseFirestore.instance
            .collection('offers')
            .doc(widget.offerId)
            .update({'offerStatus': 'Inspection Done'});

        if (userRole == 'dealer') {
          // Dealer rates the transporter
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RateTransporterPage(
                offerId: widget.offerId,
                fromCollectionPage: false,
              ),
            ),
          );
        } else if (userRole == 'transporter') {
          // Transporter rates the dealer
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RateDealerPageTwo(
                offerId: widget.offerId,
              ),
            ),
          );
        }
      } else {
        // Display message indicating the other party still needs to approve
        String waitingForMessage = userRole == 'dealer'
            ? 'Waiting for the transporter to approve the inspection.'
            : 'Waiting for the dealer to approve the inspection.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(waitingForMessage),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Failed to approve inspection: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while approving the inspection.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = screenSize.width * 0.05;
    final spacing = screenSize.height * 0.02;

    // Fetch the user role to determine whether to show the adjust offer button
    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.getUserRole;

    return Scaffold(
      body: Stack(
        children: [
          GradientBackground(
            child: SizedBox.expand(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: spacing),
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
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
                      CustomButton(
                        text: 'APPROVE',
                        borderColor: Colors.blue,
                        onPressed: () {
                          _approveInspection(userRole);
                        },
                      ),
                      // Only show the "Adjust Offer" button for dealers
                      if (userRole == 'dealer')
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
