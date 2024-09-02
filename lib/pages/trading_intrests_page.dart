import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
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
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          var screenSize = MediaQuery.of(context).size;

          return Stack(
            children: [
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: constraints.maxHeight * 0.5, // Adjust to your needs
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('lib/assets/truckSelectImage.png'),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                              'What are you interested in?',
                              style: GoogleFonts.montserrat(
                                  fontSize: constraints.maxHeight * 0.017,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: constraints.maxHeight * 0.05),
                            CustomButton(
                              text: 'TRUCKS',
                              borderColor: Colors.white,
                              onPressed: () =>
                                  _updateTradingInterest(context, 'trucks'),
                            ),
                            SizedBox(height: constraints.maxHeight * 0.01),
                            CustomButton(
                              text: 'TRAILERS',
                              borderColor: Colors.white,
                              onPressed: () =>
                                  _updateTradingInterest(context, 'trailers'),
                            ),
                            SizedBox(height: constraints.maxHeight * 0.01),
                            CustomButton(
                              text: 'BOTH',
                              borderColor: const Color(0xFFFF4E00),
                              onPressed: () =>
                                  _updateTradingInterest(context, 'both'),
                            ),
                            SizedBox(height: constraints.maxHeight * 0.03),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: BlurryAppBar(// Adjust as needed
                    ),
              ),
              if (_isLoading) const LoadingScreen(),
            ],
          );
        },
      ),
    );
  }
}
