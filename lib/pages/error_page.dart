import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signup_page.dart'; // Import the SignUp page

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var orange = const Color(0xFFFF4E00);
    var blue = const Color(0xFF2F7FFF);

    return Scaffold(
      appBar: const BlurryAppBar(),
      body: GradientBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Image.asset(
                    'lib/assets/CTPLogo.png',
                    height: screenSize.height * 0.2,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ERROR!',
                    style: GoogleFonts.montserrat(
                      fontSize: screenSize.height * 0.045,
                      fontWeight: FontWeight.bold,
                      color: orange,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'We could not find an account associated with that Account.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: screenSize.height * 0.02,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        CustomButton(
                          text: 'CREATE NEW ACCOUNT',
                          borderColor: blue,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignUpPage()),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'CHOOSE ANOTHER SIGN IN METHOD',
                          borderColor: orange,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Positioned(
                top: 40,
                left: 16,
                child: CustomBackButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
