import 'package:flutter/foundation.dart'; // For kIsWeb
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

      if (googleUser != null && googleAuth != null) {
        // Create credential but do not sign in immediately
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Show a confirmation dialog before signing in
        bool confirmSignIn = await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirm Sign In'),
              content: const Text('Do you want to sign in with this account?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );

        // If the user confirms, proceed with signing in
        if (confirmSignIn) {
          await FirebaseAuth.instance.signInWithCredential(credential);
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      print(e);
      // Handle error, show appropriate message to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebLoginPage();
    } else {
      return _buildMobileLoginPage();
    }
  }

  // Web version of the login page with gradient background
  Widget _buildWebLoginPage() {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Row(
        children: [
          // Left section with login form
          Expanded(
            flex: 1,
            child: GradientBackground(
              child: Container(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'lib/assets/CTPLogo.png', // Use your logo path here
                      height: 100,
                      width: 100,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'COMMERCIAL TRADER PORTAL',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // All text is white
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Navigate with Confidence, Drive with Ease.\nYour trusted partner on the road.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white, // Changed to white
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        // Handle Apple sign-in
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[850],
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Sign In with Apple',
                        style: TextStyle(color: Colors.white), // Text is white
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // Handle Facebook sign-in
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[850],
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Sign In with Facebook',
                        style: TextStyle(color: Colors.white), // Text is white
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F7FFF),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Sign In with Google',
                        style: TextStyle(color: Colors.white), // Text is white
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signin');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4E00),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Sign In with Email',
                        style: TextStyle(color: Colors.white), // Text is white
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Trouble Signing In?',
                          style: TextStyle(
                            color: Colors.white, // Changed to white
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Color(0xFFFF4E00), // Changed to white
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right section with background image
          Expanded(
            flex: 1,
            child: Container(
              height: screenHeight,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                      'lib/assets/LoginImageWeb.png'), // Use your image path here
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mobile version of the login page
  Widget _buildMobileLoginPage() {
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
                          width: double.infinity,
                          height: constraints.maxHeight * 0.5,
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
                                horizontal: constraints.maxWidth * 0.05,
                                vertical: constraints.maxHeight * 0.02,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: constraints.maxHeight * 0.01,
                                  ),
                                  Text(
                                    'COMMERCIAL TRADER PORTAL',
                                    style: GoogleFonts.montserrat(
                                      fontSize: constraints.maxHeight * 0.024,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(
                                      height: constraints.maxHeight * 0.01),
                                  Text(
                                    'Navigate with Confidence, Drive with Ease.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                      fontSize: constraints.maxHeight * 0.015,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Your trusted partner on the road.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                      fontSize: constraints.maxHeight * 0.018,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(
                                      height: constraints.maxHeight * 0.025),
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
                                  SizedBox(
                                      height: constraints.maxHeight * 0.02),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Trouble Signing In?',
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
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
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      child: BlurryAppBar(
                        height: constraints.maxHeight * 0.001,
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
