import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/loading_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class HouseRulesPage extends StatefulWidget {
  const HouseRulesPage({super.key});

  @override
  _HouseRulesPageState createState() => _HouseRulesPageState();
}

class _HouseRulesPageState extends State<HouseRulesPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus(); // Hide the keyboard when the page loads
    });
  }

  Future<void> _handleAgree(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    final String userId =
        Provider.of<UserProvider>(context, listen: false).userId!;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    await firestore.collection('users').doc(userId).update({
      'agreedToHouseRules': true,
    });

    setState(() {
      _isLoading = false;
    });

    Navigator.pushReplacementNamed(context, '/tradingInterests');
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var blue = const Color(0xFF2F7FFF);
    var orange = const Color(0xFFFF4E00);

    return Scaffold(
      body: Stack(
        children: [
          GradientBackground(
            child: Column(
              children: [
                const BlurryAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Stack(
                      children: [
                        Container(
                          width: screenSize.width,
                          padding: EdgeInsets.symmetric(
                              horizontal:
                                  screenSize.width * 0.04, // 4% of screen width
                              vertical: screenSize.height *
                                  0.01), // 1% of screen height
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                  height: screenSize.height *
                                      0.03), // 3% of screen height
                              Text(
                                'WELCOME TO',
                                style: GoogleFonts.montserrat(
                                  fontSize: screenSize.width *
                                      0.05, // 6% of screen width
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                  height: screenSize.height *
                                      0.06), // 1.5% of screen height
                              Image.asset('lib/assets/CTPLogo.png',
                                  height: screenSize.height *
                                      0.15), // 25% of screen height
                              SizedBox(
                                  height: screenSize.height *
                                      0.06), // 6% of screen height
                              Text(
                                'Please follow these House Rules',
                                style: GoogleFonts.montserrat(
                                  fontSize: screenSize.width *
                                      0.04, // 5% of screen width
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                  height: screenSize.height *
                                      0.03), // 3% of screen height
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Be Yourself,',
                                      style: GoogleFonts.montserrat(
                                        fontSize: screenSize.width *
                                            0.04, // 4.5% of screen width
                                        fontWeight: FontWeight.bold,
                                        color: orange,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          '\nMake sure your details are accurate to ensure the approval of your trading application.\n\n',
                                      style: GoogleFonts.montserrat(
                                        fontSize: screenSize.width *
                                            0.035, // 4% of screen width
                                        color: Colors.white,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Stay Safe,',
                                      style: GoogleFonts.montserrat(
                                        fontSize: screenSize.width *
                                            0.04, // 4.5% of screen width
                                        fontWeight: FontWeight.bold,
                                        color: orange,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          '\nUse strong passwords and avoid sharing personal information.\n\n',
                                      style: GoogleFonts.montserrat(
                                        fontSize: screenSize.width *
                                            0.035, // 4% of screen width
                                        color: Colors.white,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Play it cool.',
                                      style: GoogleFonts.montserrat(
                                        fontSize: screenSize.width *
                                            0.04, // 4.5% of screen width
                                        fontWeight: FontWeight.bold,
                                        color: orange,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          '\nRespect others and treat them how you want to be treated.',
                                      style: GoogleFonts.montserrat(
                                        fontSize: screenSize.width *
                                            0.035, // 4% of screen width
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                  height: screenSize.height *
                                      0.06), // 6% of screen height
                              CustomButton(
                                text: 'I AGREE',
                                borderColor: blue,
                                onPressed: () => _handleAgree(context),
                              ),
                              SizedBox(
                                  height: screenSize.height *
                                      0.04), // 4% of screen height
                            ],
                          ),
                        ),
                        const Positioned(
                          top: 40,
                          left: 16,
                          child: CustomBackButton(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) const LoadingScreen()
        ],
      ),
    );
  }
}
