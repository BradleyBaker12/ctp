import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:google_fonts/google_fonts.dart';

class WaitingForApprovalPage extends StatelessWidget {
  const WaitingForApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    var orange = const Color(0xFFFF4E00);
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
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenSize.width * 0.05,
                        vertical: screenSize.height * 0.02,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: screenSize.height * 0.02),
                          Image.asset(
                            'lib/assets/CTPLogo.png',
                            height: screenSize.height * 0.2,
                          ),
                          SizedBox(height: screenSize.height * 0.02),
                          Text(
                            'WAITING FOR ADMIN',
                            style: GoogleFonts.montserrat(
                              fontSize: screenSize.height * 0.04,
                              fontWeight: FontWeight.bold,
                              color: orange,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: screenSize.height * 0.02),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenSize.width * 0.05),
                            child: Text(
                              'Your account is awaiting on an admin. You will be notified once your account is active. Thank you for your patience!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontSize: screenSize.height * 0.02,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: screenSize.height * 0.04),
                          CustomButton(
                            text: 'LOG OUT',
                            borderColor: blue,
                            onPressed: () {
                              // Add logic to log out the user
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                          ),
                          SizedBox(height: screenSize.height * 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
