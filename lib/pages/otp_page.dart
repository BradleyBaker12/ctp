import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/loading_screen.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  _OTPScreenState createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  void _verifyOTP(String verificationId, String userId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: _otpController.text,
      );

      await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);

      print(
          'OTPScreen: User verified and linked with UID: $userId'); // Debugging
      Navigator.pushReplacementNamed(context, '/firstNamePage');
    } catch (e) {
      // Display a friendly message for OTP verification failure.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Invalid verification code. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendCode(String phoneNumber) async {
    setState(() {
      _isLoading = true;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        // Handle instant verification
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _isLoading = false;
        });
        // Use a friendlier error message when resend fails.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Unable to resend code. Please try again later.')),
        );
      },
      codeSent: (String verificationId, int? forceResendingToken) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code resent')),
        );

        // Extract arguments from the current route
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

        // Pass all necessary arguments when navigating back to OTPScreen
        Navigator.popAndPushNamed(context, '/otp', arguments: {
          'verificationId': verificationId,
          'phoneNumber': phoneNumber,
          'userId': args['userId'], // Ensure userId is passed
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var blue = const Color(0xFF2F7FFF);
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    assert(
        args != null &&
            args.containsKey('verificationId') &&
            args.containsKey('phoneNumber') &&
            args.containsKey('userId'),
        'Verification ID, Phone Number and User ID are required');
    final String verificationId = args!['verificationId'];
    final String phoneNumber = args['phoneNumber'];
    final String userId = args['userId'];

    print('OTPScreen: Received verificationId: $verificationId'); // Debugging
    print('OTPScreen: Received phoneNumber: $phoneNumber'); // Debugging
    print('OTPScreen: Received userId: $userId'); // Debugging

    return Scaffold(
      body: Stack(
        children: [
          GradientBackground(
            child: Column(
              children: [
                const BlurryAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      width: screenSize.width,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenSize.width * 0.05,
                        vertical: screenSize.height * 0.02,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: screenSize.height * 0.03),
                          Image.asset(
                            'lib/assets/CTPLogo.png',
                            height: screenSize.height * 0.23,
                          ),
                          SizedBox(height: screenSize.height * 0.1),
                          Text(
                            'MY CODE IS',
                            style: GoogleFonts.montserrat(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'We will send you a six digit code',
                            style: GoogleFonts.montserrat(
                              fontSize: screenSize.height * 0.02,
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: screenSize.height * 0.01),
                          Pinput(
                            length: 6,
                            controller: _otpController,
                            defaultPinTheme: PinTheme(
                              width: screenSize.width * 0.1,
                              height: screenSize.height * 0.07,
                              textStyle: GoogleFonts.montserrat(
                                fontSize: screenSize.height * 0.025,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: blue,
                                    width: 2.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: screenSize.height * 0.03),
                          TextButton(
                            onPressed: () {
                              _resendCode(phoneNumber);
                            },
                            child: Text(
                              'Resend code',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 16,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: screenSize.height * 0.15),
                          CustomButton(
                            text: 'CONTINUE',
                            borderColor: blue,
                            onPressed: () => _verifyOTP(verificationId, userId),
                          ),
                          SizedBox(height: screenSize.height * 0.03),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 40,
            left: 16,
            child: CustomBackButton(),
          ),
          if (_isLoading) const LoadingScreen()
        ],
      ),
    );
  }
}
