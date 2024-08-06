import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/custom_text_field.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/loading_screen.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

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
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided for that user.';
      } else {
        errorMessage = 'An error occurred. Please try again.';
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
                          'WELCOME BACK TO',
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
                          'SIGN IN',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        CustomTextField(
                          hintText: 'EMAIL',
                          controller: _emailController,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          hintText: 'PASSWORD',
                          obscureText: true,
                          controller: _passwordController,
                        ),
                        const Spacer(),
                        CustomButton(
                          text: 'SIGN IN',
                          borderColor: const Color(0xFF2F7FFF),
                          onPressed: _signIn,
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
