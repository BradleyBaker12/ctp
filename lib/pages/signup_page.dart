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

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
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
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('SignUp: User created with UID: ${user.uid}'); // Debugging

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setUser(user); // Set the user in UserProvider
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

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var orange = const Color(0xFFFF4E00);

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: screenSize.height * 0.05),
                          Text(
                            'WELCOME TO',
                            style: TextStyle(
                              fontSize: screenSize.height * 0.03,
                              fontWeight: FontWeight.w900,
                              color: orange,
                            ),
                          ),
                          SizedBox(height: screenSize.height * 0.02),
                          Image.asset('lib/assets/CTPLogo.png',
                              height: screenSize.height * 0.15),
                          SizedBox(height: screenSize.height * 0.05),
                          const Text(
                            'SIGN-UP',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: screenSize.height * 0.02),
                          CustomTextField(
                            hintText: 'USERNAME OR EMAIL',
                            controller: _emailController,
                          ),
                          SizedBox(height: screenSize.height * 0.02),
                          CustomTextField(
                            hintText: 'PASSWORD',
                            obscureText: true,
                            controller: _passwordController,
                          ),
                          SizedBox(height: screenSize.height * 0.02),
                          CustomTextField(
                            hintText: 'CONFIRM PASSWORD',
                            obscureText: true,
                            controller: _confirmPasswordController,
                          ),
                          SizedBox(height: screenSize.height * 0.05),
                          CustomButton(
                            text: 'SIGN-UP',
                            borderColor: const Color(0xFF2F7FFF),
                            onPressed: _signUp,
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
