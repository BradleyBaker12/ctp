import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/custom_text_field.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/loading_screen.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  bool _isEmailValid(String email) {
    final RegExp emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegExp.hasMatch(email);
  }

  bool _isPasswordValid(String password) {
    final RegExp passwordRegExp = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*?&\-])[A-Za-z\d@$!%*?&\-]{8,}$',
    );

    return passwordRegExp.hasMatch(password);
  }

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();

    if (!_isEmailValid(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    if (!_isPasswordValid(_passwordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Password must be at least 8 characters long, include a number, and a special character.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      User? user = userCredential.user;

      if (user != null) {
        print("DEBUG: User created with ID: ${user.uid}");

        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'userRole': 'pending',
          'accountStatus': 'active'
        });
        print("DEBUG: Firestore document created");

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setUser(user);
        print("DEBUG: User set in provider");

        print("DEBUG: Navigating to phone number page");
        Navigator.pushReplacementNamed(context, '/phoneNumber');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'email-already-in-use') {
        errorMessage =
            'The email address is already in use by another account.';
      } else {
        errorMessage = 'An error occurred. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      print("SignUp Error: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          var orange = const Color(0xFFFF4E00);
          return Stack(
            children: [
              GradientBackground(
                child: Column(
                  children: [
                    const BlurryAppBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: constraints.maxWidth * 0.05,
                            vertical: constraints.maxHeight * 0.02,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  SizedBox(
                                      height: constraints.maxHeight * 0.03),
                                  Text(
                                    'Welcome to',
                                    style: GoogleFonts.montserrat(
                                      fontSize: constraints.maxHeight * 0.025,
                                      fontWeight: FontWeight.w900,
                                      color: orange,
                                    ),
                                  ),
                                  SizedBox(
                                      height: constraints.maxHeight * 0.06),
                                  Image.asset('lib/assets/CTPLogo.png',
                                      height: constraints.maxHeight * 0.2),
                                  SizedBox(
                                      height: constraints.maxHeight * 0.06),
                                  Text(
                                    'Sign Up',
                                    style: GoogleFonts.montserrat(
                                      fontSize: constraints.maxHeight * 0.028,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(
                                      height: constraints.maxHeight * 0.07),
                                  CustomTextField(
                                    hintText: 'Username or Email',
                                    controller: _emailController,
                                  ),
                                  SizedBox(
                                      height: constraints.maxHeight * 0.03),
                                  CustomTextField(
                                    hintText: 'Password',
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
                                  SizedBox(
                                      height: constraints.maxHeight * 0.03),
                                  CustomTextField(
                                    hintText: 'Confirm Password',
                                    obscureText: !_confirmPasswordVisible,
                                    controller: _confirmPasswordController,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _confirmPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _confirmPasswordVisible =
                                              !_confirmPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: constraints.maxHeight * 0.07),
                              CustomButton(
                                text: 'Sign Up',
                                borderColor: const Color(0xFF2F7FFF),
                                onPressed: _signUp,
                              ),
                              SizedBox(height: constraints.maxHeight * 0.02),
                              CustomButton(
                                text: 'Cancel',
                                borderColor: const Color(0xFFFF4E00),
                                onPressed: _signUp,
                              ),
                              SizedBox(height: constraints.maxHeight * 0.02),
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
          );
        },
      ),
    );
  }
}
