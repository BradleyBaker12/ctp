// lib/pages/sign_in_page.dart
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
import 'package:cloud_firestore/cloud_firestore.dart';

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
  bool _passwordVisible = false;

  // List of admin emails
  final List<String> adminEmails = [
    'admin1@example.com',
    'admin2@example.com',
    // Add more admin emails here
  ];

  Future<void> _signIn() async {
    // First check for empty fields
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check for valid email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      User? user = userCredential.user;
      print('Signed in user UID: ${user?.uid}');

      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        print('User document exists: ${userDoc.exists}');

        if (!userDoc.exists) {
          // Determine the user role based on email
          String role = 'guest';
          if (user.email != null && adminEmails.contains(user.email)) {
            role = 'admin';
          } else {
            // Assign default role or determine based on other criteria
            role = 'dealer'; // Change as per your application logic
          }
          print('Assigned role: $role');

          // Create a new user document
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'userRole': role,
            'email': user.email,
            // Add other default fields as needed
          });
          print('User document created with role: $role');
        } else {
          print('User document already exists');
        }

        // Fetch user data via UserProvider
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.fetchUserData();

        // Get user role
        String userRole = userProvider.userRole;
        print('Fetched user role: $userRole');

        // Navigate based on user role
        if (userRole == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin-home');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      Color backgroundColor = Colors.red;

      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'user-not-found':
          errorMessage =
              'No account exists with this email. Please check your email or sign up.';
          break;
        case 'invalid-email':
          errorMessage =
              'Invalid email format. Please enter a valid email address.';
          break;
        case 'invalid-credential':
        case 'invalid-login-credentials':
          errorMessage =
              'Invalid email or password. Please check your credentials.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          backgroundColor = Colors.orange;
          break;
        case 'user-disabled':
          errorMessage =
              'This account has been disabled. Please contact support.';
          break;
        default:
          errorMessage = 'An error occurred during sign in. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your Email address')),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim());
      print('Password reset email sent to ${_emailController.text.trim()}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent!')),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'invalid-email':
          errorMessage =
              'The email address is not valid. Please check it and try again.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with that email address.';
          break;
        default:
          errorMessage = e.message ?? 'An unknown error occurred.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var orange = const Color(0xFFFF4E00);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Gradient background should be the first widget in the Stack
          GradientBackground(
            child: Container(),
          ),
          Scaffold(
            appBar: const BlurryAppBar(),
            backgroundColor: Colors.transparent, // Make scaffold transparent
            body: Column(
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
                              SizedBox(height: screenSize.height * 0.08),
                              CustomTextField(
                                hintText: 'EMAIL',
                                controller: _emailController,
                              ),
                              SizedBox(height: screenSize.height * 0.02),
                              CustomTextField(
                                hintText: 'PASSWORD',
                                obscureText: !_passwordVisible,
                                controller: _passwordController,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _passwordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _passwordVisible = !_passwordVisible;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenSize.height * 0.03),
                          TextButton(
                            onPressed: _resetPassword,
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: screenSize.height * 0.016,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(height: screenSize.height * 0.03),
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
              backgroundColor: Colors.black54,
              indicatorColor: Color(0xFFFF4E00),
            ),
        ],
      ),
    );
  }
}
