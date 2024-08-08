import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/build_sign_in_button.dart';
import 'package:ctp/components/gradient_background.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var orange = const Color(0xFFFF4E00);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: screenSize.width,
            height: screenSize.height * 0.5,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/HeroImageLoginPage.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              const BlurryAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: screenSize.width,
                        height: screenSize.height * 0.4,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image:
                                AssetImage('lib/assets/HeroImageLoginPage.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      GradientBackground(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenSize.width * 0.05,
                            vertical: screenSize.height * 0.02,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: screenSize.height * 0.02),
                              const Text(
                                'COMMERCIAL TRADER PORTAL',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: screenSize.height * 0.01),
                              const Text(
                                'Navigate with Confidence, Drive with Ease.\nYour trusted partner on the road.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: screenSize.height * 0.02),
                              SignInButton(
                                text: 'Sign In with Apple',
                                onPressed: () {
                                  // Handle sign-in with Apple
                                },
                                borderColor: Colors.white,
                              ),
                              SignInButton(
                                text: 'Sign In with Facebook',
                                onPressed: () {
                                  // Handle sign-in with Facebook
                                },
                                borderColor: Colors.white,
                              ),
                              SignInButton(
                                text: 'Sig n In with Google',
                                onPressed: () {
                                  // Handle sign-in with Google
                                },
                                borderColor: const Color(0xFF2F7FFF),
                              ),
                              SignInButton(
                                text: 'Sign In with Email',
                                onPressed: () {
                                  Navigator.pushNamed(context, '/signin');
                                },
                                borderColor: orange,
                              ),
                              SizedBox(height: screenSize.height * 0.02),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  const Text(
                                    'Trouble Signing In?',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(width: 5),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(context, '/signup');
                                    },
                                    child: Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenSize.height * 0.08),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
