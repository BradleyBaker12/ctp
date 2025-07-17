import 'package:flutter/material.dart';
import 'package:ctp/components/progress_bar.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/loading_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

import 'package:auto_route/auto_route.dart';
@RoutePage()class PreferredBrandsPage extends StatefulWidget {
  const PreferredBrandsPage({super.key});

  @override
  _PreferredBrandsPageState createState() => _PreferredBrandsPageState();
}

class _PreferredBrandsPageState extends State<PreferredBrandsPage> {
  final List<Map<String, dynamic>> semiTruckBrands = [
    {'name': 'ASHOK LEYLAND', 'path': 'lib/assets/Logo/ASHOK LEYLAND.png'},
    {'name': 'CNHTC', 'path': 'lib/assets/Logo/CNHTC.png'},
    {'name': 'DAF', 'path': 'lib/assets/Logo/DAF.png'},
    {'name': 'DAYUN', 'path': 'lib/assets/Logo/DAYUN.png'},
    {'name': 'EICHER', 'path': 'lib/assets/Logo/EICHER.png'},
    {'name': 'FAW', 'path': 'lib/assets/Logo/FAW.png'},
    {'name': 'FIAT', 'path': 'lib/assets/Logo/FIAT.png'},
    {'name': 'FORD', 'path': 'lib/assets/Logo/FORD.png'},
    {'name': 'FOTON', 'path': 'lib/assets/Logo/FOTON.png'},
    {
      'name': 'FREIGHTLINER',
      'path': 'lib/assets/Freightliner-logo-6000x2000.png'
    },
    {'name': 'FUSO', 'path': 'lib/assets/Logo/FUSO.png'},
    {'name': 'HINO', 'path': 'lib/assets/Logo/HINO.png'},
    {'name': 'HYUNDAI', 'path': 'lib/assets/Logo/HYUNDAI.png'},
    {'name': 'ISUZU', 'path': 'lib/assets/Logo/ISUZU.png'},
    {
      'name': 'IVECO',
      'path': 'lib/assets/Logo/iveco.png'
    }, // Logo not available, will use an Icon
    {'name': 'JAC', 'path': 'lib/assets/Logo/JAC.png'},
    {'name': 'JOYLONG', 'path': 'lib/assets/Logo/JOYLONG.png'},
    {'name': 'MAN', 'path': 'lib/assets/Logo/MAN.png'},
    {'name': 'MERCEDES-BENZ', 'path': 'lib/assets/Logo/MERCEDES BENZ.png'},
    {'name': 'PEUGEOT', 'path': 'lib/assets/Logo/PEUGEOT.png'},
    {'name': 'POWERSTAR', 'path': 'lib/assets/Logo/POWERSTAR.png'},
    {'name': 'RENAULT', 'path': 'lib/assets/Logo/RENAULT.png'},
    {'name': 'SCANIA', 'path': 'lib/assets/Logo/SCANIA.png'},
    {'name': 'TATA', 'path': 'lib/assets/Logo/TATA.png'},
    {'name': 'TOYOTA', 'path': 'lib/assets/Logo/TOYOTA.png'},
    {'name': 'UD TRUCKS', 'path': 'lib/assets/Logo/UD TRUCKS.png'},
    {'name': 'VOLVO', 'path': 'lib/assets/Logo/VOLVO.png'},
    {'name': 'VW', 'path': 'lib/assets/Logo/VW.png'},
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
                              SizedBox(height: screenSize.height * 0.02),
                              Image.asset(
                                'lib/assets/CTPLogo.png',
                                height: screenSize.height * 0.2,
                                width: screenSize.height * 0.2,
                                fit: BoxFit.cover,
                              ),
                              SizedBox(height: screenSize.height * 0.03),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 64.0),
                                child: const ProgressBar(progress: 0.80),
                              ),
                              SizedBox(height: screenSize.height * 0.06),
                              Text(
                                'PREFERRED BRANDS',
                                style: GoogleFonts.montserrat(
                                  fontSize: screenSize.height * 0.022,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: screenSize.height * 0.04),
                              Expanded(
                                child: GridView.builder(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: screenSize.width * 0.01),
                                  shrinkWrap: true,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: isPortrait ? 3 : 5,
                                    crossAxisSpacing: screenSize.width * 0.02,
                                    mainAxisSpacing: screenSize.height * 0.01,
                                    childAspectRatio: isPortrait
                                        ? 1
                                        : 1, // Square aspect ratio
                                  ),
                                  itemCount: semiTruckBrands.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final brand =
                                        semiTruckBrands[index]['name']!;
                                    final path =
                                        semiTruckBrands[index]['path']!;
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
                                              : blue.withOpacity(0.3),
                                          border: Border.all(color: blue),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Image.asset(
                                                path,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                            SizedBox(
                                                height:
                                                    screenSize.height * 0.01),
                                            Text(
                                              brand,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.montserrat(
                                                fontSize:
                                                    screenSize.height * 0.012,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              CustomButton(
                                text: 'CONTINUE',
                                borderColor: blue,
                                onPressed: () => _savePreferredBrands(context),
                              ),
                              SizedBox(height: screenSize.height * 0.02),
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
      ),
    );
  }
}
