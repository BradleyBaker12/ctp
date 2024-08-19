import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';

class TutorialTruckSwipePage extends StatefulWidget {
  const TutorialTruckSwipePage({super.key});

  @override
  _TutorialTruckSwipePageState createState() => _TutorialTruckSwipePageState();
}

class _TutorialTruckSwipePageState extends State<TutorialTruckSwipePage> {
  int _selectedIndex = 1; // Set initial selected index to the trucks tab
  int _currentStep = 0; // Track the current step of the tutorial

  // Sample vehicle data
  final Map<String, dynamic> sampleVehicle = {
    'makeModel': 'Toyota Dyna 7-145',
    'year': '2024',
    'mileage': '25 000 km',
    'transmission': 'Auto',
    'config': '6X4',
    'photos': const AssetImage("lib/assets/default_vehicle_image.png"),
    'honestyPercentage': 85,
  };

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onNextTap() {
    setState(() {
      if (_currentStep < 3) {
        _currentStep++; // Move to the next step of the tutorial
        print('Next button tapped. Current step: $_currentStep');
      }
    });
  }

  void _onSwipeRight() {
    setState(() {
      if (_currentStep == 1) {
        _currentStep++; // Move from "LIKING" to "DISLIKING"
        print('Swiped right. Current step: $_currentStep');
      }
    });
  }

  void _onSwipeLeft() {
    setState(() {
      if (_currentStep == 2) {
        _currentStep++; // Move from "DISLIKING" to "UNDO"
        print('Swiped left. Current step: $_currentStep');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    print('Building UI. Current step: $_currentStep');

    return Scaffold(
      appBar: const BlurryAppBar(),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            // Swiped right
            _onSwipeRight();
          } else if (details.primaryVelocity! < 0) {
            // Swiped left
            _onSwipeLeft();
          }
        },
        child: Stack(
          children: [
            _buildTruckCard(context, size),
            if (_currentStep == 1) _buildDimmingLayer(), // Add a dimming layer
            if (_currentStep == 0)
              _buildOverlayWithNextButton(
                context,
                size,
                icon: Icons.local_shipping,
                title: "INFORMATION",
                description:
                    "Below is a summary of the truck's information. You can expand the information tab by pressing the arrow next to the truck's name.",
                extraDescription:
                    "To the right is the honesty bar. The honesty bar represents how much information is complete about the truck. The number below it, out of 100, is how much information was given about the truck.",
              )
            else if (_currentStep == 1)
              _buildOverlayWithNextButton(
                context,
                size,
                icon: Icons.favorite,
                title: "LIKING",
                description:
                    "Swiping right on a truck will add it to your wishlist where you can then make an offer to buy the truck.",
                extraDescription:
                    "Additionally, you can also press the highlighted heart button to add it to your wishlist.",
                buttonText:
                    "Swipe right to proceed", // Changing the button text
              )
            else if (_currentStep == 2)
              _buildOverlayWithNextButton(
                context,
                size,
                icon: Icons.close,
                title: "DISLIKING",
                description:
                    "Swiping left on a truck will simply remove it from your truck options.",
                extraDescription:
                    "Additionally, you can also press the highlighted X button.",
                buttonText: "Swipe left to proceed", // Changing the button text
              )
            else if (_currentStep == 3)
              _buildOverlayWithNextButton(
                context,
                size,
                icon: Icons.undo,
                title: "UNDO",
                description:
                    "If you mistakenly swipe left on a truck you want, you can press the undo button to bring that truck back to your screen.",
                buttonText:
                    "Please click on the Wishlist icon to proceed", // Updated button text
              ),
            _buildHonestyInfo(context, size),
            if (_currentStep == 1)
              _buildHeartButtonOnTop(), // Highlight the heart button on top
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildTruckCard(BuildContext context, Size size) {
    int honestyPercentage = (sampleVehicle['honestyPercentage'] as int);

    return GestureDetector(
      onDoubleTap: () {
        print('Navigating to vehicle details page...');
      },
      child: Container(
        width: double.infinity,
        height: size.height * 0.847,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image(
                  image: sampleVehicle['photos'],
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Positioned(
              bottom: 70,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        sampleVehicle['makeModel'] as String,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Image.asset(
                        'lib/assets/verified_Icon.png',
                        width: 20,
                        height: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBlurryContainer(
                          'YEAR', sampleVehicle['year'] as String),
                      const SizedBox(width: 1),
                      _buildBlurryContainer(
                          'MILEAGE', sampleVehicle['mileage'] as String),
                      const SizedBox(width: 1),
                      _buildBlurryContainer('TRANSMISSION',
                          sampleVehicle['transmission'] as String),
                      const SizedBox(width: 1),
                      _buildBlurryContainer(
                          'CONFIG', sampleVehicle['config'] as String),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIconButton(Icons.close, const Color(0xFF2F7FFF)),
                  _buildCenterButton(),
                  _buildIconButton(Icons.favorite, const Color(0xFFFF4E00)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHonestyInfo(BuildContext context, Size size) {
    int honestyPercentage = (sampleVehicle['honestyPercentage'] as int);

    return Positioned(
      top: 10,
      right: 10,
      child: Column(
        children: [
          _buildHonestyBar(honestyPercentage.toDouble()),
          const SizedBox(height: 8),
          Text(
            "$honestyPercentage/100",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHonestyBar(double percentage) {
    return Container(
      width: 25,
      height: 580,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: (580 * percentage) / 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4E00),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurryContainer(String title, String value) {
    return Flexible(
      child: Container(
        height: 85,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value.isNotEmpty ? value : "Unknown",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          print("Button pressed: $icon");
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          print("Undo action");
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.undo, color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayWithNextButton(
    BuildContext context,
    Size size, {
    required IconData icon,
    required String title,
    required String description,
    String extraDescription = '', // Made optional with a default value
    String buttonText = "NEXT", // Default text for the button
  }) {
    String swipeIconPath =
        'lib/assets/Layer_1.png'; // Default to swipe right icon

    if (buttonText.contains("Swipe left")) {
      swipeIconPath =
          'lib/assets/Layer_2.png'; // Change to the swipe left icon path
    }

    return Positioned(
      top: size.height * 0.15,
      left: size.width * 0.05,
      right: size.width * 0.1,
      child: Column(
        children: [
          _buildAdjustableOrangeBox(
            icon: icon,
            title: title,
            description: description,
            extraDescription: extraDescription,
          ),
          const SizedBox(
              height: 10), // Space between orange box and "NEXT" button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _onNextTap,
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          if (buttonText.contains("Swipe")) ...[
            const SizedBox(height: 10), // Add space between text and icon
            Center(
              child: Image.asset(
                swipeIconPath, // Load the appropriate icon based on the swipe direction
                width: 200, // Adjust width based on your icon size
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdjustableOrangeBox({
    required IconData icon,
    required String title,
    required String description,
    String extraDescription = '', // Optional extra description
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4E00).withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (extraDescription.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              extraDescription,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDimmingLayer() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.6),
      ),
    );
  }

  Widget _buildHeartButtonOnTop() {
    return Positioned(
      bottom: 10,
      right: 10,
      child: _buildIconButton(Icons.favorite, const Color(0xFFFF4E00)),
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
