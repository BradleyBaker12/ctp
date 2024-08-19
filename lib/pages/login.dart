import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/build_sign_in_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var orange = const Color(0xFFFF4E00);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: screenSize.width,
                          height: screenSize.height * 0.4,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                  'lib/assets/HeroImageLoginPage.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Expanded(
                          child: GradientBackground(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenSize.width * 0.05,
                                vertical: screenSize.height * 0.02,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: screenSize.height * 0.02),
                                  Text(
                                    'COMMERCIAL TRADER PORTAL',
                                    style: GoogleFonts.montserrat(
                                      fontSize: screenSize.height * 0.024,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: screenSize.height * 0.01),
                                  Text(
                                    'Navigate with Confidence, Drive with Ease.\nYour trusted partner on the road.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
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
                                    text: 'Sign In with Google',
                                    onPressed: _signInWithGoogle,
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
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Trouble Signing In?',
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(
                                              context, '/signup');
                                        },
                                        child: Text(
                                          'Sign Up',
                                          style: GoogleFonts.montserrat(
                                            color: orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: screenSize.height * 0.07),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      child: BlurryAppBar(
                        height: screenSize.height * 0.001,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
