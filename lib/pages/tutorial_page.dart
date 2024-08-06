import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/loading_screen.dart';

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  _TutorialPageState createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  final int _selectedIndex = 0;
  final bool _isLoading = false;

  void _onItemTapped(int index) {
    // Handle navigation based on selected index
    // switch (index) {
    //   case 0:
    //     Navigator.pushReplacementNamed(context, '/home');
    //     break;
    //   case 1:
    //     Navigator.pushReplacementNamed(context, '/trucks');
    //     break;
    //   case 2:
    //     Navigator.pushReplacementNamed(context, '/favorites');
    //     break;
    //   case 3:
    //     Navigator.pushReplacementNamed(context, '/profile');
    //     break;
    // }
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var orange = const Color(0xFFFF4E00);

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
                      SizedBox(
                        width: screenSize.width,
                        height: screenSize.height * 0.8,
                        child: Image.asset(
                          'lib/assets/tutorialImage.png', // Replace with your tutorial image path
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        width: screenSize.width,
                        height: screenSize.height * 0.8,
                        color: Colors.black.withOpacity(0.45),
                      ),
                      Positioned(
                        top: screenSize.height *
                            0.3, // Adjust position as needed
                        left: 0,
                        right: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "LET'S GET YOU READY!",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Here is everything you need to know:',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: FractionallySizedBox(
                                widthFactor: 1, // 100% of the available width
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(
                                          context, '/tutorialStarted');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: orange, // Button color
                                      padding: const EdgeInsets.symmetric(
                                          vertical:
                                              15.0), // Padding inside button
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            8.0), // Rounded corners
                                        side: const BorderSide(
                                            color:
                                                Colors.white), // Border color
                                      ),
                                    ),
                                    child: Text(
                                      "start tutorial".toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white, // Text color
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: FractionallySizedBox(
                                widthFactor: 1, // 100% of the available width
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(
                                          context, '/home');
                                    },
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor:
                                          Colors.black, // Button color
                                      padding: const EdgeInsets.symmetric(
                                          vertical:
                                              15.0), // Padding inside button
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            8.0), // Rounded corners
                                        side: const BorderSide(
                                            color:
                                                Colors.white), // Border color
                                      ),
                                    ),
                                    child: Text(
                                      "skip".toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white, // Text color
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
          if (_isLoading) const LoadingScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
