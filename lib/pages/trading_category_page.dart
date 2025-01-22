import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

class TradingCategoryPage extends StatelessWidget {
  const TradingCategoryPage({super.key});

  Future<void> _updateUserRole(BuildContext context, String role) async {
    // ignore: unused_local_variable
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final String? userId = userProvider.userId;
      
      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'userRole': role,
        'isFirstLogin': false
      });

      // Update local UserProvider state
      userProvider.updateUserRole(role);

      // Navigate based on role
      if (role == 'dealer') {
        Navigator.pushReplacementNamed(context, '/preferedBrands');
      } else if (role == 'transporter') {
        Navigator.pushReplacementNamed(context, '/addProfilePhotoTransporter');
      }
    } catch (e) {
      print('Error updating user role: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update user role. Please try again.')),
      );
    }
  }

  

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var blue = const Color(0xFF2F7FFF);
    var orange = const Color(0xFFFF4E00);

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            const BlurryAppBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Stack(
                  children: [
                    Container(
                      width: screenSize.width,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        children: [
                          SizedBox(height: screenSize.height * 0.02),
                          Image.asset(
                            'lib/assets/CTPLogo.png',
                            height: screenSize.height * 0.2,
                            width: screenSize.height * 0.2,
                            fit: BoxFit.cover,
                          ), // Adjust the height as needed
                          SizedBox(height: screenSize.height * 0.15),
                          Text(
                            'Welcome to CTP Where Trading Trucks and Trailers is Made Easy!',
                            style: GoogleFonts.montserrat(
                              fontSize: screenSize.height * 0.02,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Please Select Your Trading Category:',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                              height: 20), // Adjust the spacing as needed
                          Text(
                            'Transporters are users who sell trucks.\nDealers are users who buy trucks.',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                              height: 50), // Adjust the spacing as needed
                          CustomButton(
                            text: 'Transporter',
                            borderColor: blue,
                            onPressed: () =>
                                _updateUserRole(context, 'transporter'),
                          ),
                          CustomButton(
                            text: 'Dealer',
                            borderColor: orange,
                            onPressed: () => _updateUserRole(context, 'dealer'),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                    // const Positioned(
                    //   top: 40,
                    //   left: 16,
                    //   child: CustomBackButton(),
                    // ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
