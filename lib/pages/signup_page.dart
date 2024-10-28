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
        const SnackBar(content: Text('Passwords do not match')),
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
        WriteBatch batch = _firestore.batch();

        DocumentReference userRef =
            _firestore.collection('users').doc(user.uid);
        batch.set(userRef, {
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await batch.commit();

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setUser(user);
        await userProvider.fetchUserData();

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
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Mobile Layout Builder
  Widget _buildMobileLayout(BoxConstraints constraints, Color orange) {
    return Column(
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
                      SizedBox(height: constraints.maxHeight * 0.03),
                      Text(
                        'WELCOME TO',
                        style: GoogleFonts.montserrat(
                          fontSize: constraints.maxHeight * 0.025,
                          fontWeight: FontWeight.w900,
                          color: orange,
                        ),
                      ),
                      SizedBox(height: constraints.maxHeight * 0.06),
                      Image.asset('lib/assets/CTPLogo.png',
                          height: constraints.maxHeight * 0.2),
                      SizedBox(height: constraints.maxHeight * 0.06),
                      Text(
                        'SIGN-UP',
                        style: GoogleFonts.montserrat(
                          fontSize: constraints.maxHeight * 0.028,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: constraints.maxHeight * 0.07),
                      CustomTextField(
                        hintText: 'USERNAME OR EMAIL',
                        controller: _emailController,
                      ),
                      SizedBox(height: constraints.maxHeight * 0.02),
                      CustomTextField(
                        hintText: 'PASSWORD',
                        obscureText: true,
                        controller: _passwordController,
                      ),
                      SizedBox(height: constraints.maxHeight * 0.02),
                      CustomTextField(
                        hintText: 'CONFIRM PASSWORD',
                        obscureText: true,
                        controller: _confirmPasswordController,
                      ),
                    ],
                  ),
                  SizedBox(height: constraints.maxHeight * 0.07),
                  CustomButton(
                    text: 'SIGN-UP',
                    borderColor: const Color(0xFF2F7FFF),
                    onPressed: _signUp,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.02),
                  CustomButton(
                    text: 'CANCEL',
                    borderColor: const Color(0xFFFF4E00),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  SizedBox(height: constraints.maxHeight * 0.02),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebLayout(BoxConstraints constraints, Color orange) {
    return Row(
      children: [
        // Left side with form and gradient background
        Expanded(
          flex: 2,
          child: GradientBackground(
            begin: FractionalOffset(0.5, 0),
            end: FractionalOffset(
                0.5, 1.0), // Adjust for desired gradient effect
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'WELCOME TO',
                    style: GoogleFonts.montserrat(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF4E00),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Image.asset('lib/assets/CTPLogo.png', height: 100),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'SIGN-UP',
                    style: GoogleFonts.montserrat(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  CustomTextField(
                    hintText: 'USERNAME OR EMAIL',
                    controller: _emailController,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    hintText: 'PASSWORD',
                    obscureText: true,
                    controller: _passwordController,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    hintText: 'CONFIRM PASSWORD',
                    obscureText: true,
                    controller: _confirmPasswordController,
                  ),
                  const SizedBox(height: 40),
                  CustomButton(
                    text: 'SIGN-UP',
                    borderColor: const Color(0xFF2F7FFF),
                    onPressed: _signUp,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Right side with image
        Expanded(
          flex: 3,
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/LoginImageWeb.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          const Color orange = Color(0xFFFF4E00);
          // Define a breakpoint for responsiveness (e.g., 600px)
          if (constraints.maxWidth < 600) {
            // Mobile Layout
            return Stack(
              children: [
                GradientBackground(
                  child: _buildMobileLayout(constraints, orange),
                ),
                if (_isLoading)
                  const LoadingScreen(
                    backgroundColor: Colors.black54,
                    indicatorColor: Color(0xFFFF4E00),
                  ),
              ],
            );
          } else {
            // Web Layout
            return Stack(
              children: [
                GradientBackground(
                  child: _buildWebLayout(constraints, orange),
                ),
                if (_isLoading)
                  const LoadingScreen(
                    backgroundColor: Colors.black54,
                    indicatorColor: Color(0xFFFF4E00),
                  ),
              ],
            );
          }
        },
      ),
    );
  }
}
