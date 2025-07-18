import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/loading_screen.dart';
import 'package:ctp/components/progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:auto_route/auto_route.dart';
@RoutePage()class FirstNamePage extends StatefulWidget {
  const FirstNamePage({super.key});

  @override
  _FirstNamePageState createState() => _FirstNamePageState();
}

class _FirstNamePageState extends State<FirstNamePage> {
  final TextEditingController _firstNameController = TextEditingController();
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _saveFirstName(String userId, String firstName) async {
    if (userId.isNotEmpty) {
      final userDoc = _firestore.collection('users').doc(userId);

      try {
        DocumentSnapshot docSnapshot = await userDoc.get();
        if (!docSnapshot.exists) {
          print('FirstNamePage: Document does not exist for userId: $userId');
          throw Exception('Document does not exist');
        }

        await userDoc.update({'firstName': firstName});
        print('FirstNamePage: First name saved for UID: $userId');
      } catch (e) {
        print('FirstNamePage: Error updating first name: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save first name. Please try again.')),
        );
      }
    } else {
      print('FirstNamePage: User ID is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID is not available.')),
      );
    }
  }

  void _continue() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String? userId = userProvider.userId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID is not available.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    String firstName = _firstNameController.text.trim();

    if (firstName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your first name')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    await _saveFirstName(userId, firstName);
    setState(() {
      _isLoading = false;
    });

    Navigator.pushNamed(context, '/tradingCategory');
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var blue = const Color(0xFF2F7FFF);
    var orange = const Color(0xFFFF4E00);

    return PopScope(
      onPopInvokedWithResult: (route, result) async => false,
      child: Scaffold(
        body: Stack(
          children: [
            GradientBackground(
              child: Column(
                children: [
                  const BlurryAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenSize.width * 0.05,
                          vertical: screenSize.height * 0.02,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: screenSize.height * 0.02),
                            Image.asset(
                              'lib/assets/CTPLogo.png',
                              height: screenSize.height * 0.2,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(height: screenSize.height * 0.1),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenSize.width * 0.15),
                              child: const ProgressBar(progress: 0.20),
                            ),
                            SizedBox(height: screenSize.height * 0.07),
                            Text(
                              'MY FIRST NAME IS',
                              style: GoogleFonts.montserrat(
                                fontSize: screenSize.width * 0.045,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenSize.width * 0.15),
                              child: TextField(
                                controller: _firstNameController,
                                textAlign: TextAlign.center,
                                cursorColor: orange,
                                decoration: InputDecoration(
                                  hintText: '',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: blue),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: blue),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: screenSize.height * 0.02,
                                    horizontal: screenSize.width * 0.04,
                                  ),
                                ),
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: screenSize.width * 0.04,
                                ),
                              ),
                            ),
                            SizedBox(height: screenSize.height * 0.05),
                            Text(
                              'This is the name that will appear to other users in the app',
                              style: GoogleFonts.montserrat(
                                fontSize: screenSize.width * 0.025,
                                color: Colors.white.withOpacity(0.7),
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenSize.height * 0.03),
                            TextButton(
                              onPressed: () {
                                // Handle name changes approval info
                              },
                              child: Text(
                                'Name changes will have to be approved',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: screenSize.width * 0.03,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: screenSize.height * 0.07),
                            CustomButton(
                              text: 'CONTINUE',
                              borderColor: blue,
                              onPressed: _continue,
                            ),
                            SizedBox(height: screenSize.height * 0.04),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading) const LoadingScreen()
          ],
        ),
      ),
    );
  }
}
