import 'package:ctp/components/loading_screen.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:pinput/pinput.dart';
import 'package:ctp/components/custom_back_button.dart';
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
      Navigator.pushReplacementNamed(context, '/firstName');
    } catch (e) {
      print("OTPScreen Error: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
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
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
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
                    child: Stack(
                      children: [
                        Container(
                          width: screenSize.width,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              Image.asset('lib/assets/CTPLogo.png',
                                  height: 200), // Adjust the height as needed
                              const SizedBox(height: 50),
                              const Text(
                                'MY CODE IS',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'We will send you a six digit code',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Pinput(
                                length: 6,
                                controller: _otpController,
                                defaultPinTheme: PinTheme(
                                  width: 56,
                                  height: 56,
                                  textStyle: const TextStyle(
                                    fontSize: 20,
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
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () {
                                  _resendCode(phoneNumber);
                                },
                                child: const Text(
                                  'Resend code',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 150),
                              CustomButton(
                                text: 'CONTINUE',
                                borderColor: blue,
                                onPressed: () =>
                                    _verifyOTP(verificationId, userId),
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
          if (_isLoading) const LoadingScreen()
        ],
      ),
    );
  }
}
