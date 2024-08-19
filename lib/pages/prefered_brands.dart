import 'package:ctp/components/progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/loading_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

class PreferredBrandsPage extends StatefulWidget {
  const PreferredBrandsPage({super.key});

  @override
  _PreferredBrandsPageState createState() => _PreferredBrandsPageState();
}

class _PreferredBrandsPageState extends State<PreferredBrandsPage> {
  final List<String> semiTruckBrands = [
    'Volvo',
    'Freightliner',
    'Kenworth',
    'Peterbilt',
    'Mack',
    'Western Star',
    'International',
    'Scania',
    'Mercedes-Benz',
    'MAN',
    'DAF',
    'Iveco'
  ];

  final Set<String> selectedBrands = {};
  bool _isLoading = false;

  void _toggleSelection(String brand) {
    setState(() {
      if (selectedBrands.contains(brand)) {
        selectedBrands.remove(brand);
      } else {
        selectedBrands.add(brand);
      }
    });
  }

  Future<void> _savePreferredBrands(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    final String userId =
        Provider.of<UserProvider>(context, listen: false).userId!;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    await firestore.collection('users').doc(userId).update({
      'preferredBrands': selectedBrands.toList(),
    });

    setState(() {
      _isLoading = false;
    });

    Navigator.pushReplacementNamed(context, '/addProfilePhoto');
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var blue = const Color(0xFF2F7FFF);
    var isPortrait = screenSize.height > screenSize.width;

    double logoHeight =
        isPortrait ? screenSize.height * 0.15 : screenSize.height * 0.25;
    double spacing =
        isPortrait ? screenSize.height * 0.03 : screenSize.height * 0.02;
    double headerFontSize =
        isPortrait ? screenSize.width * 0.06 : screenSize.width * 0.05;
    double brandFontSize =
        isPortrait ? screenSize.width * 0.04 : screenSize.width * 0.035;
    double buttonFontSize =
        isPortrait ? screenSize.width * 0.045 : screenSize.width * 0.04;

    return Scaffold(
      body: Stack(
        children: [
          GradientBackground(
            child: Column(
              children: [
                const BlurryAppBar(),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        width: screenSize.width,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenSize.width * 0.04,
                          vertical: screenSize.height * 0.02,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(height: spacing),
                            Image.asset(
                              'lib/assets/CTPLogo.png',
                              height:
                                  logoHeight, // Adjust the height responsively
                            ),
                            SizedBox(height: spacing),
                            const ProgressBar(progress: 0.80),
                            SizedBox(height: spacing),
                            Text(
                              'PREFERRED BRANDS',
                              style: GoogleFonts.montserrat(
                                fontSize: headerFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: spacing),
                            Expanded(
                              child: GridView.builder(
                                padding: EdgeInsets.symmetric(
                                    horizontal: screenSize.width * 0.05),
                                shrinkWrap: true,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isPortrait ? 3 : 5,
                                  crossAxisSpacing: screenSize.width * 0.02,
                                  mainAxisSpacing: screenSize.height * 0.02,
                                  childAspectRatio: isPortrait ? 2 / 1 : 3 / 1,
                                ),
                                itemCount: semiTruckBrands.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final brand = semiTruckBrands[index];
                                  final isSelected =
                                      selectedBrands.contains(brand);
                                  return GestureDetector(
                                    onTap: () => _toggleSelection(brand),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: screenSize.height * 0.01),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? blue.withOpacity(0.8)
                                            : Colors.transparent,
                                        border: Border.all(color: blue),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      child: Center(
                                        child: Text(
                                          brand,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.montserrat(
                                            fontSize: brandFontSize,
                                            color: Colors.white,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: spacing),
                            CustomButton(
                              text: 'CONTINUE',
                              borderColor: blue,
                              onPressed: () => _savePreferredBrands(context),
                            ),
                            SizedBox(height: spacing),
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
              ],
            ),
          ),
          if (_isLoading) const LoadingScreen()
        ],
      ),
    );
  }
}
