import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/build_sign_in_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  static const String DEFAULT_PROFILE_IMAGE =
      'https://firebasestorage.googleapis.com/v0/b/your-bucket/default-profile.png';

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      // Initialize Firebase provider installer if needed
      if (!kIsWeb) {
        await Firebase.initializeApp();
      }
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      if (!mounted) return;
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          if (!mounted) return;
          Navigator.pop(context); // Remove loading indicator
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final bool shouldProceed = await _showSignInConfirmation();
        if (!shouldProceed) {
          Navigator.pop(context); // Remove loading indicator
          return;
        }

        await _auth.signInWithCredential(credential);
      }

      final User? user = _auth.currentUser;
      if (!mounted) return;

      // Check if user is new by looking up their doc in Firestore
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user!.uid);
      final docSnapshot = await userDocRef.get();

      Navigator.pop(context); // Remove loading indicator

      if (!docSnapshot.exists) {
        // New user scenario
        // Save initial user data (optional)
        await saveUserData(user.uid, {
          'email': user.email,
          // Add additional fields if needed
        });
        // Navigate to the first name page
        Navigator.pushReplacementNamed(context, '/firstNamePage');
      } else {
        // Existing user scenario
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Remove loading indicator
      _showErrorDialog('Failed to sign in with Google: ${e.toString()}');
    }
  }

  Future<bool> _showSignInConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
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
          ),
        ) ??
        false;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> saveUserData(String uid, Map<String, dynamic> userData) async {
    try {
      userData['profileImageUrl'] = DEFAULT_PROFILE_IMAGE;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData);
      print('User data saved successfully');
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Comment out this line
    // return kIsWeb ? _buildWebLoginPage() : _buildMobileLoginPage();

    // Replace with just
    return _buildMobileLoginPage();
  }

  Widget _buildWebLoginPage() {
    final size = MediaQuery.of(context).size;
    const orange = Color(0xFFFF4E00);

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: GradientBackground(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'lib/assets/CTPLogo.png',
                      height: 100,
                      width: 100,
                    ),
                    const SizedBox(height: 30),
                    _buildHeaderText(),
                    const SizedBox(height: 40),
                    _buildSignInButtons(),
                    const SizedBox(height: 30),
                    _buildBottomRow(),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: size.height,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('lib/assets/LoginImageWeb.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLoginPage() {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _buildMobileHeader(constraints),
                        _buildMobileContent(constraints),
                      ],
                    ),
                    Positioned(
                      child: BlurryAppBar(),
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

  Widget _buildHeaderText() {
    return Column(
      children: const [
        Text(
          'COMMERCIAL TRADER PORTAL',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Text(
          'Navigate with Confidence, Drive with Ease.\nYour trusted partner on the road.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButtons() {
    const orange = Color(0xFFFF4E00);
    return Column(
      children: [
        _buildAuthButton('Sign In with Apple', Colors.grey[850]!, () {}),
        const SizedBox(height: 10),
        _buildAuthButton('Sign In with Facebook', Colors.grey[850]!, () {}),
        const SizedBox(height: 10),
        _buildAuthButton(
            'Sign In with Google', const Color(0xFF2F7FFF), _signInWithGoogle),
        const SizedBox(height: 10),
        _buildAuthButton('Sign In with Email', orange, () {
          Navigator.pushNamed(context, '/signin');
        }),
      ],
    );
  }

  Widget _buildAuthButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 50),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildBottomRow() {
    const orange = Color(0xFFFF4E00);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Trouble Signing In?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/signup'),
          child: const Text(
            'Sign Up',
            style: TextStyle(
              color: orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader(BoxConstraints constraints) {
    return Container(
      width: double.infinity,
      height: constraints.maxHeight * 0.5,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/HeroImageLoginPage.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildMobileContent(BoxConstraints constraints) {
    const orange = Color(0xFFFF4E00);
    return Expanded(
      child: GradientBackground(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth * 0.05,
            vertical: constraints.maxHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: constraints.maxHeight * 0.01),
              _buildMobileHeaderText(constraints),
              SizedBox(height: constraints.maxHeight * 0.025),
              _buildMobileSignInButtons(),
              SizedBox(height: constraints.maxHeight * 0.02),
              _buildMobileBottomRow(orange),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHeaderText(BoxConstraints constraints) {
    return Column(
      children: [
        Text(
          'COMMERCIAL TRADER PORTAL',
          style: GoogleFonts.montserrat(
            fontSize: constraints.maxHeight * 0.024,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: constraints.maxHeight * 0.01),
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
      ],
    );
  }

  Widget _buildMobileSignInButtons() {
    const orange = Color(0xFFFF4E00);
    return Column(
      children: [
        SignInButton(
          text: 'Sign In with Apple',
          onPressed: () {},
          borderColor: Colors.white,
        ),
        SignInButton(
          text: 'Sign In with Facebook',
          onPressed: () {},
          borderColor: Colors.white,
        ),
        SignInButton(
          text: 'Sign In with Google',
          onPressed: _signInWithGoogle,
          borderColor: const Color(0xFF2F7FFF),
        ),
        SignInButton(
          text: 'Sign In with Email',
          onPressed: () => Navigator.pushNamed(context, '/signin'),
          borderColor: orange,
        ),
      ],
    );
  }

  Widget _buildMobileBottomRow(Color orange) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Trouble Signing In?',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/signup'),
          child: Text(
            'Sign Up',
            style: GoogleFonts.montserrat(
              color: orange,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
