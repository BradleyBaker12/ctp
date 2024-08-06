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
      body: Stack(
        children: [
          GradientBackground(
            child: Column(
              children: [
                const BlurryAppBar(),
                Expanded(
                  child: Container(
                    width: screenSize.width,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        Text(
                          'WELCOME TO',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: orange,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Image.asset('lib/assets/CTPLogo.png',
                            height: 100), // Adjust the height as needed
                        const Spacer(),
                        const Text(
                          'SIGN-UP',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
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
                        const Spacer(),
                        CustomButton(
                          text: 'SIGN-UP',
                          borderColor: const Color(0xFF2F7FFF),
                          onPressed: _signUp,
                        ),
                        const SizedBox(height: 50),
                      ],
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
