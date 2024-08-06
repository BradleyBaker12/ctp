import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/loading_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';

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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            Image.asset('lib/assets/CTPLogo.png',
                                height: 150), // Adjust the height as needed
                            const SizedBox(height: 30),
                            const Text(
                              'PREFERRED BRANDS',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 5.0,
                                mainAxisSpacing: 1.0,
                                childAspectRatio: 1 / 1,
                              ),
                              itemCount: semiTruckBrands.length,
                              itemBuilder: (BuildContext context, int index) {
                                final brand = semiTruckBrands[index];
                                final isSelected =
                                    selectedBrands.contains(brand);
                                return GestureDetector(
                                  onTap: () => _toggleSelection(brand),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 5.0),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? blue
                                          : Colors.transparent,
                                      border: Border.all(color: blue),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Center(
                                      child: Text(
                                        brand,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            CustomButton(
                              text: 'CONTINUE',
                              borderColor: blue,
                              onPressed: () => _savePreferredBrands(context),
                            ),
                            const SizedBox(height: 20),
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
