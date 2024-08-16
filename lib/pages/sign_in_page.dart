import 'package:ctp/pages/error_page.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/custom_text_field.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/loading_screen.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      User? user = userCredential.user;

      if (user != null) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.fetchUserData();

        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException Code: ${e.code}");

      // Provide specific feedback based on the error code
      String errorMessage;
      switch (e.code) {
        case 'invalid-credential':
        case 'INVALID_LOGIN_CREDENTIALS':
        case 'user-not-found':
          errorMessage = 'No user found with that email address.';
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ErrorPage()),
          );
          break;
        case 'wrong-password':
          errorMessage = 'The password is incorrect. Please try again.';
          break;
        case 'invalid-email':
          errorMessage =
              'The email address is not valid. Please check it and try again.';
          break;
        case 'user-disabled':
          errorMessage =
              'This user has been disabled. Please contact support for help.';
          break;
        case 'too-many-requests':
          errorMessage =
              'Too many unsuccessful login attempts. Please try again later.';
          break;
        default:
          errorMessage = 'An unknown error occurred. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      print("Error: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var orange = const Color(0xFFFF4E00);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const BlurryAppBar(),
      body: Stack(
        children: [
          GradientBackground(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      width: screenSize.width,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenSize.width * 0.05,
                        vertical: screenSize.height * 0.02,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              SizedBox(height: screenSize.height * 0.05),
                              Text(
                                'WELCOME BACK TO',
                                style: GoogleFonts.montserrat(
                                  fontSize: screenSize.height * 0.03,
                                  fontWeight: FontWeight.w900,
                                  color: orange,
                                ),
                              ),
                              SizedBox(height: screenSize.height * 0.08),
                              Image.asset('lib/assets/CTPLogo.png',
                                  height: screenSize.height * 0.15),
                              SizedBox(height: screenSize.height * 0.08),
                              Text(
                                'SIGN IN',
                                style: GoogleFonts.montserrat(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: screenSize.height * 0.1),
                              CustomTextField(
                                hintText: 'EMAIL',
                                controller: _emailController,
                              ),
                              SizedBox(height: screenSize.height * 0.02),
                              CustomTextField(
                                hintText: 'PASSWORD',
                                obscureText: true,
                                controller: _passwordController,
                              ),
                            ],
                          ),
                          SizedBox(height: screenSize.height * 0.05),
                          CustomButton(
                            text: 'SIGN IN',
                            borderColor: const Color(0xFF2F7FFF),
                            onPressed: _signIn,
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
          if (_isLoading)
            const LoadingScreen(
              backgroundColor: Colors.black,
              indicatorColor: Color(0xFFFF4E00),
            ),
        ],
      ),
    );
  }
}
