import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ctp/components/loading_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class TradingInterestsPage extends StatefulWidget {
  const TradingInterestsPage({super.key});

  @override
  _TradingInterestsPageState createState() => _TradingInterestsPageState();
}

class _TradingInterestsPageState extends State<TradingInterestsPage> {
  bool _isLoading = false;

  Future<void> _updateTradingInterest(
      BuildContext context, String interest) async {
    setState(() {
      _isLoading = true;
    });

    final String userId =
        Provider.of<UserProvider>(context, listen: false).userId ?? '';
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      await firestore.collection('users').doc(userId).update({
        'tradingInterest': interest,
      });

      setState(() {
        _isLoading = false;
      });

      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating trading interest: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var screenSize = MediaQuery.of(context).size;
        var blue = const Color(0xFF2F7FFF);
        var orange = const Color(0xFFFF4E00);

        return Scaffold(
          body: Stack(
            children: [
              Container(
                color: Colors
                    .black, // Set the background color of the body to black
              ),
              Column(
                children: [
                  const BlurryAppBar(),
                  SizedBox(
                    height: screenSize.height * 0.35, // Constrain the height
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0, // Slightly move the image up
                          left: 0,
                          right: 0,
                          child: Image.asset(
                            'lib/assets/truckSelectImage.png',
                            fit: BoxFit.cover,
                            height: screenSize.height * 0.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GradientBackground(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenSize.width *
                                0.05, // Horizontal padding for responsiveness
                          ),
                          child: Column(
                            children: [
                              SizedBox(
                                  height: screenSize.height *
                                      0.05), // Adjust the space so the content starts below the image
                              Text(
                                'COMMERCIAL TRADER PORTAL',
                                style: GoogleFonts.montserrat(
                                  fontSize: screenSize.height * 0.022,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: screenSize.height * 0.02),
                              Text(
                                'What are you interested in?',
                                style: GoogleFonts.montserrat(
                                  fontSize: screenSize.height * 0.017,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: screenSize.height * 0.03),
                              CustomButton(
                                text: 'TRUCKS',
                                borderColor: Colors.white,
                                onPressed: () =>
                                    _updateTradingInterest(context, 'trucks'),
                              ),
                              SizedBox(height: screenSize.height * 0.01),
                              CustomButton(
                                text: 'TRAILERS',
                                borderColor: Colors.white,
                                onPressed: () =>
                                    _updateTradingInterest(context, 'trailers'),
                              ),
                              SizedBox(height: screenSize.height * 0.01),
                              CustomButton(
                                text: 'BOTH',
                                borderColor: orange,
                                onPressed: () =>
                                    _updateTradingInterest(context, 'both'),
                              ),
                              SizedBox(height: screenSize.height * 0.03),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: screenSize.height * 0.15,
                left: screenSize.width * 0.05,
                child: const CustomBackButton(),
              ),
              if (_isLoading) const LoadingScreen(),
            ],
          ),
        );
      },
    );
  }
}
