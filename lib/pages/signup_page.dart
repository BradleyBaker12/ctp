import 'package:flutter/material.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/custom_text_field.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    FocusScope.of(context).unfocus();

    // Your sign-up logic here

    setState(() {
      _isLoading = true;
    });

    // Simulate loading and completion of the sign-up process
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    // Proceed with navigation or error handling based on success/failure
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;
    var orange = const Color(0xFFFF4E00);

    return Scaffold(
      body: Row(
        children: [
          // Left side: Form content
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(40.0),
              color: const Color(0xFF1A1A2E), // Dark background
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'WELCOME TO',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Image.asset(
                            'lib/assets/CTPLogo.png', // Your logo path
                            height: 100,
                            width: 100,
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'SIGN-UP',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 40),
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
                          const SizedBox(height: 20),
                          CustomButton(
                            text: 'CANCEL',
                            borderColor: const Color(0xFFFF4E00),
                            onPressed: () {
                              // Handle cancel action
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right side: Background image
          Expanded(
            flex: 1,
            child: Container(
              height: screenHeight,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                      'lib/assets/HeroImageLoginPage.png'), // Path to the image
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
