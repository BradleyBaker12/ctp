import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ctp/components/loading_screen.dart';
import 'package:google_fonts/google_fonts.dart'; // Import the Google Fonts package

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
                    child: Column(
                      children: [
                        Image.asset(
                          'lib/assets/truckSelectImage.png',
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'COMMERCIAL TRADER PORTAL',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'What are you interested in?',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        CustomButton(
                          text: 'TRUCKS',
                          borderColor: blue,
                          onPressed: () =>
                              _updateTradingInterest(context, 'trucks'),
                        ),
                        const SizedBox(height: 10),
                        CustomButton(
                          text: 'TRAILERS',
                          borderColor: blue,
                          onPressed: () =>
                              _updateTradingInterest(context, 'trailers'),
                        ),
                        const SizedBox(height: 10),
                        CustomButton(
                          text: 'BOTH',
                          borderColor: orange,
                          onPressed: () =>
                              _updateTradingInterest(context, 'both'),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 120,
            left: 16,
            child: CustomBackButton(),
          ),
          if (_isLoading) const LoadingScreen()
        ],
      ),
    );
  }
}
