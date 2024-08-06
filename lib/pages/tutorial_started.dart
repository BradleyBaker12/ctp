import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/loading_screen.dart';

class TutorialStartedPage extends StatefulWidget {
  const TutorialStartedPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TutorialStartedPageState createState() => _TutorialStartedPageState();
}

class _TutorialStartedPageState extends State<TutorialStartedPage> {
  int _selectedIndex = 0;
  final bool _isLoading = false;
  int _currentIndex = 0;

  final List<String> _titles = ["HOME", "TRUCKS", "WISHLIST", "PROFILE"];
  final List<String> _descriptions = [
    "Brief description of homepage and what it has/does. E.g. can view xyz features, summary, dashboard.",
    "Brief description of trucks page and what it has/does. E.g. can view truck features, list, details.",
    "Brief description of wishlist page and what it has/does. E.g. can view liked trucks, manage wishlist.",
    "Brief description of profile page and what it has/does. E.g. can view and edit profile details."
  ];
  final List<IconData> _icons = [
    Icons.home,
    Icons.local_shipping,
    Icons.favorite,
    Icons.person
  ];

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

  void _nextMessage() {
    setState(() {
      if (_currentIndex < _titles.length - 1) {
        _currentIndex++;
        _selectedIndex =
            _currentIndex; // Update selectedIndex when currentIndex changes
      } else {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.fetchUserData().then((_) {
          Navigator.pushNamed(context, "/home");
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var orange = const Color(0xFFFF4E00);
    final userProvider = Provider.of<UserProvider>(context);

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
                      Positioned(
                        top: 50,
                        left: 0,
                        right: 0,
                        child: Image.asset(
                          'lib/assets/CTPLogo.png', // Replace with your logo image path
                          height: screenSize.height * 0.12,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        top: screenSize.height * 0.2,
                        left: 0,
                        right: 0,
                        child: SizedBox(
                          width: screenSize.width,
                          height: screenSize.height * 0.6,
                          child: Image.asset(
                            'lib/assets/tutorialImage.png', // Replace with your tutorial image path
                            fit: BoxFit.fitHeight,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.0),
                                Colors.black.withOpacity(0.8)
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: screenSize.height * 0.35,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          color: orange,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                _icons[_currentIndex],
                                color: Colors.white,
                                size: 50.0,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _titles[_currentIndex],
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _descriptions[_currentIndex],
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 230,
                        right: 16,
                        child: GestureDetector(
                          onTap: _nextMessage,
                          child: Text(
                            _currentIndex == _titles.length - 1
                                ? "FINISH"
                                : "NEXT",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
