import 'package:ctp/pages/home_page.dart';
import 'package:ctp/pages/tutorial_pages/tutorial_truck_swipe.dart';
import 'package:flutter/material.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/loading_screen.dart';

class TutorialStartedPage extends StatefulWidget {
  const TutorialStartedPage({super.key});

  @override
  _TutorialStartedPageState createState() => _TutorialStartedPageState();
}

class _TutorialStartedPageState extends State<TutorialStartedPage> {
  int _selectedIndex = 0;
  final bool _isLoading = false;
  int _currentIndex = 0;
  bool _showTutorialSection = true; // State variable to manage visibility

  final List<String> _titles = [
    "HOME",
    "TRUCKS",
    "INFORMATION",
    "LIKING",
    "DISLIKING",
    "UNDO",
    "WISHLIST",
    "PROFILE"
  ];

  final List<String> _descriptions = [
    "The Home screen is where you can get a quick overview of all your activity on the app from pending offers to new trucks.",
    "This is the Trucks page! Here you will add trucks to your wishlist or swipe past them. Follow the following steps to learn the features.",
    "Below is a summary of the truck's information. You can expand the information tab by pressing the arrow next to the truck's name.",
    "Swiping right on a truck will add it to your wishlist where you can then make an offer to buy the truck. Additionally, you can also press the highlighted heart button to add it to your wishlist.",
    "Swiping left on a truck will simply just remove it from your truck options. Additionally, you can also press the highlighted X button.",
    "If you mistakenly swipe left on a truck you want, you can press the undo button to bring that truck back to your screen.",
    "Brief description of wishlist page and what it has/does. E.g. can view liked trucks, manage wishlist.",
    "Brief description of profile page and what it has/does. E.g. can view and edit profile details."
  ];

  final List<IconData> _icons = [
    Icons.home,
    Icons.local_shipping,
    Icons.info_outline,
    Icons.favorite,
    Icons.cancel,
    Icons.undo,
    Icons.favorite,
    Icons.person
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      if (index == 1) {
        // If Trucks is selected
        _currentIndex = 1;
        _showTutorialSection = true; // Show the truck tutorial section
      } else if (_currentIndex == 0 && index == 0) {
        // Go to the home tutorial section
        _showTutorialSection = true;
      } else if (_currentIndex == _titles.length - 1 && index == 0) {
        // On the last tutorial step, go to the actual home page
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.fetchUserData().then((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        });
      } else {
        // Keep navigating through the tutorial sections
        if (index == _currentIndex) {
          if (_currentIndex < _titles.length - 1) {
            _currentIndex++;
          }
        }
      }
    });
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
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: _showTutorialSection
                            ? _buildTutorialSection(screenSize, orange)
                            : _buildHomeTutorial(screenSize, orange),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) const LoadingScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        iconSize: 30.0,
      ),
    );
  }

  Widget _buildTutorialSection(Size screenSize, Color orange) {
    String title = _titles[_currentIndex];
    String description = _descriptions[_currentIndex];
    IconData icon = _icons[_currentIndex];

    return Stack(
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
              'lib/assets/tutorialImage.png', // Replace with your truck tutorial image path
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
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: orange.withOpacity(
                  0.95), // Slightly adjust opacity to match the design
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: screenSize.width * 0.12,
                ),
                SizedBox(height: screenSize.height * 0.01),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: screenSize.width * 0.06,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenSize.height * 0.01),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: screenSize.width * 0.04,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: screenSize.height * 0.55,
          right: 16,
          child: TextButton(
            onPressed: () {
              if (_currentIndex == 1) {
                // Navigate to the TutorialTruckSwipePage
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TutorialTruckSwipePage()),
                );
              } else {
                setState(() {
                  if (_currentIndex < _titles.length - 1) {
                    _currentIndex++;
                  }
                });
              }
            },
            child: Text(
              "NEXT",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: screenSize.width * 0.045,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeTutorial(Size screenSize, Color orange) {
    final userProvider = Provider.of<UserProvider>(context);
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  Image.asset(
                    'lib/assets/HomePageHero.png',
                    width: screenSize.width,
                    height: screenSize.height * 0.4,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: screenSize.height * 0.3,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            'Welcome ${userProvider.getUserName}',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFF4E00),
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Positioned(
                            child: Text(
                              "Ready to steer your trading journey to success?",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    _buildTutorialCard(screenSize, orange),
                    const SizedBox(height: 20),
                    // Additional sections (brands, arrivals, offers, etc.) can be added here
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildBlackOverlay(screenSize),
        _buildOverlayBox(screenSize, orange),
      ],
    );
  }

  Widget _buildTutorialCard(Size screenSize, Color orange) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            "I'm looking for".toUpperCase(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Trigger next tutorial step or explanation
                  },
                  child: Container(
                    height: screenSize.height * 0.2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.blue,
                        width: 3,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'lib/assets/truck_image.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            color: Colors.black54,
                            width: double.infinity,
                            padding: const EdgeInsets.all(8.0),
                            child: const Text(
                              "TRUCKS",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Trigger next tutorial step or explanation
                  },
                  child: Container(
                    height: screenSize.height * 0.2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: orange,
                        width: 3,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'lib/assets/trailer_image.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            color: Colors.black54,
                            width: double.infinity,
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "TRAILERS",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: orange,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlackOverlay(Size screenSize) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
      ),
    );
  }

  Widget _buildOverlayBox(Size screenSize, Color orange) {
    return Positioned(
      top: screenSize.height * 0.1, // Adjusted to move up
      left: screenSize.width * 0.1,
      right: screenSize.width * 0.1,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: orange.withOpacity(0.95),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.home,
                  color: Colors.white,
                  size: screenSize.width * 0.1,
                ),
                const SizedBox(height: 10),
                Text(
                  "HOME",
                  style: TextStyle(
                    fontSize: screenSize.width * 0.06,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "This is the home page!\nHere you can: Select trucks or trailers, edit your preferred brands, see the latest trucks and pending offers.",
                  style: TextStyle(
                    fontSize: screenSize.width * 0.035,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Please click the highlighted Trucks button to proceed",
            style: TextStyle(
              fontSize: screenSize.width * 0.035,
              color: Colors.white,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class CustomBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final double iconSize;

  const CustomBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.iconSize = 30.0,
  });

  Widget _buildNavBarItem(
      BuildContext context, IconData icon, bool isActive, int index) {
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: isActive ? Colors.black : Colors.black.withOpacity(0.6),
          ),
          if (isActive)
            const Icon(
              Icons.arrow_drop_up,
              size: 30,
              color: Colors.white,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: const Color(0xFF2F7FFF),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavBarItem(context, Icons.home, selectedIndex == 0, 0),
          _buildNavBarItem(
              context, Icons.local_shipping, selectedIndex == 1, 1),
          _buildNavBarItem(context, Icons.favorite, selectedIndex == 2, 2),
          _buildNavBarItem(context, Icons.person, selectedIndex == 3, 3),
        ],
      ),
    );
  }
}
