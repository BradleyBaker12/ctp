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
  bool _isPasswordFocused = false;

  bool _has8Chars = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  bool _hasCapitalLetter = false; // Add this new state variable

  bool _isEmailValid(String email) {
    final RegExp emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegExp.hasMatch(email);
  }

  bool _isPasswordValid(String password) {
    final RegExp passwordRegExp = RegExp(
      r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$%\^&\*\(\)\-_\+=\[\]{}\|;:,.<>?\/]).[A-Za-z0-9!@#\$%\^&\*\(\)\-_\+=\[\]{}\|;:,.<>?\/]{7,}$',
    );
    return passwordRegExp.hasMatch(password);
  }

  void _checkPasswordStrength(String password) {
    setState(() {
      _has8Chars = password.length >= 8;
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password
          .contains(RegExp(r'[!@#\$%\^&\*\(\)\-_\+=\[\]{}\|;:,.<>?\/]'));
      _hasCapitalLetter = password.contains(RegExp(r'[A-Z]')); // Add this check
    });
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
            'Password must be at least 8 characters long, include a number, and a special character.',
          ),
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

        // Create initial user data with all fields
        Map<String, dynamic> userData = {
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
          'userRole': 'pending',
          'accountStatus': 'pending',
          'isVerified': false,

          // Initialize all additional fields as null/empty
          'preferredBrands': [],
          'profileImageUrl': null,
          'companyName': null,
          'tradingName': null,
          'registrationNumber': null,
          'vatNumber': null,
          'addressLine1': null,
          'addressLine2': null,
          'city': null,
          'state': null,
          'postalCode': null,
          'firstName': null,
          'middleName': null,
          'lastName': null,
          'phoneNumber': null,
          'agreedToHouseRules': false,
          'bankConfirmationUrl': null,
          'brncUrl': null,
          'cipcCertificateUrl': null,
          'proxyUrl': null,
          'adminApproval': false,
        };

        await _firestore.collection('users').doc(user.uid).set(userData);
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

  Widget _buildPasswordRequirementItem(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.circle_outlined,
          color: isMet ? Colors.green : Colors.white.withOpacity(0.8),
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.montserrat(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Use an `AnimatedCrossFade` so that if `_isPasswordFocused` is `false`,
  /// the requirements widget becomes a `SizedBox.shrink()` (0 size),
  /// removing all extra space.
  Widget _buildPasswordRequirements() {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 200),
      crossFadeState: _isPasswordFocused
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      firstChild: const SizedBox.shrink(), // no space when not focused
      secondChild: Container(
        margin: const EdgeInsets.only(top: 4),
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Password Requirements:',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            _buildPasswordRequirementItem(
              'At least 8 characters',
              _has8Chars,
            ),
            const SizedBox(height: 4),
            _buildPasswordRequirementItem(
              'Include at least one number',
              _hasNumber,
            ),
            const SizedBox(height: 4),
            _buildPasswordRequirementItem(
              'At least one Capital Letter',
              _hasCapitalLetter, // Use the new state variable instead of _hasSpecialChar
            ),
            const SizedBox(height: 4),
            _buildPasswordRequirementItem(
              'Include at least one special character.',
              _hasSpecialChar,
            ),
          ],
        ),
      ),
    );
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
                                  // Password + Requirements
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CustomTextField(
                                        hintText: 'Password',
                                        obscureText: !_passwordVisible,
                                        controller: _passwordController,
                                        onFocusChange: (hasFocus) {
                                          setState(() {
                                            _isPasswordFocused = hasFocus;
                                          });
                                        },
                                        onChanged: (value) {
                                          _checkPasswordStrength(value);
                                        },
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _passwordVisible
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _passwordVisible =
                                                  !_passwordVisible;
                                            });
                                          },
                                        ),
                                      ),
                                      // Show/hide requirements with no extra space
                                      _buildPasswordRequirements(),
                                      SizedBox(
                                          height: constraints.maxHeight * 0.03),
                                      // Extra gap only if user is focusing on the password field
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        height: _isPasswordFocused ? 24.0 : 0.0,
                                      ),
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
