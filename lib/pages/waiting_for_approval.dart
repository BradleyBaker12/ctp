// lib/screens/account_status_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:auto_route/auto_route.dart';

@RoutePage()
class AccountStatusPage extends StatefulWidget {
  const AccountStatusPage({super.key});

  @override
  _AccountStatusPageState createState() => _AccountStatusPageState();
}

class _AccountStatusPageState extends State<AccountStatusPage> {
  String? accountStatus; // raw accountStatus from Firestore
  bool? isVerified; // verification flag
  String?
      _displayStatus; // derived status used for UI (e.g., awaiting_verification)
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAccountStatus();
  }

  Future<void> _fetchAccountStatus() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        // Handle unauthenticated state
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        setState(() {
          accountStatus = 'unknown';
          isVerified = false;
          _displayStatus = 'unknown';
          isLoading = false;
        });
        return;
      }

      Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;

      final rawStatus =
          data?['accountStatus']?.toString().toLowerCase() ?? 'unknown';
      final verifiedFlag = data?['isVerified'] == true;

      // Derive composite display status:
      // active + verified => active
      // active + !verified => awaiting_verification
      // pending (regardless of verification flag) => pending
      // others pass through
      String derived;
      if (rawStatus == 'active' && verifiedFlag) {
        derived = 'active';
      } else if (rawStatus == 'active' && !verifiedFlag) {
        derived = 'awaiting_verification';
      } else if (rawStatus == 'pending') {
        derived = 'pending';
      } else if (rawStatus == 'suspended') {
        derived = 'suspended';
      } else if (rawStatus == 'deactivated') {
        derived = 'deactivated';
      } else {
        derived = 'unknown';
      }

      setState(() {
        accountStatus = rawStatus;
        isVerified = verifiedFlag;
        _displayStatus = derived;
        isLoading = false;
      });
    } catch (e) {
      // Handle errors appropriately
      setState(() {
        accountStatus = 'error';
        _displayStatus = 'error';
        isLoading = false;
      });
    }
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'active':
        return 'Account Active';
      case 'awaiting_verification':
        return 'Verifying Your Account';
      case 'pending':
        return 'Account Pending Approval';
      case 'suspended':
        return 'Account Suspended';
      case 'deactivated':
        return 'Account Deactivated';
      case 'error':
        return 'Status Processing';
      default: // includes 'unknown'
        return 'Account Under Review';
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'active':
        return 'Your account is fully approved and verified. You can now access all features.';
      case 'awaiting_verification':
        return 'Your account has been approved and we\'re finalizing verification. You\'ll gain full access shortly.';
      case 'pending':
        return 'Your application is under review. An admin is attending to your account. You\'ll receive a notification once approval and verification are complete.';
      case 'suspended':
        return 'Your account has been suspended. Please contact support for more information.';
      case 'deactivated':
        return 'Your account has been deactivated. Please contact support to reactivate it.';
      case 'error':
        return 'We\'re processing your status. Please re-open the app in a moment.';
      default: // includes 'unknown'
        return 'An admin is attending to your account. You will gain access once it is fully approved and verified.';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'awaiting_verification':
      case 'pending':
        return Colors.orange;
      case 'suspended':
        return Colors.red;
      case 'deactivated':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _contactSupport() async {
    final Uri params = Uri(
      scheme: 'mailto',
      path: 'support@yourapp.com',
      query: 'subject=Account Issue&body=Describe your issue here',
    );

    var url = params.toString();
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not launch email client.',
            style: GoogleFonts.montserrat(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var blue = const Color(0xFF2F7FFF);
    var screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: const BlurryAppBar(),
      body: SizedBox.expand(
        child: Stack(
          children: [
            // GradientBackground now spans the entire screen
            const GradientBackground(child: SizedBox.expand()),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenSize.width * 0.05,
                    vertical: screenSize.height * 0.02,
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: screenSize.height * 0.02),
                            Image.asset(
                              'lib/assets/CTPLogo.png',
                              height: screenSize.height * 0.2,
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            Text(
                              _getStatusTitle(_displayStatus ?? 'unknown'),
                              style: GoogleFonts.montserrat(
                                fontSize: screenSize.height * 0.04,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(
                                    _displayStatus ?? 'unknown'),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenSize.width * 0.05),
                              child: Text(
                                _getStatusMessage(_displayStatus ?? 'unknown'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: screenSize.height * 0.02,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: screenSize.height * 0.04),
                            // Display LOG OUT button for all statuses
                            CustomButton(
                              text: 'LOG OUT',
                              borderColor: blue,
                              onPressed: () async {
                                // Add logic to log out the user
                                FirebaseAuth.instance.signOut();
                                Navigator.pushReplacementNamed(
                                    context, '/login');
                              },
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            // Optionally, provide additional actions based on status
                            if (_displayStatus == 'suspended' ||
                                _displayStatus == 'deactivated')
                              CustomButton(
                                text: 'CONTACT SUPPORT',
                                borderColor: Colors.white,
                                // backgroundColor: Colors.transparent,
                                // textColor: Colors.white,
                                onPressed: _contactSupport,
                              ),
                            SizedBox(height: screenSize.height * 0.02),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
