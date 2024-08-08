import 'package:flutter/material.dart';
import 'package:ctp/pages/home_page.dart';
import 'package:ctp/pages/profile_page.dart';
import 'package:ctp/pages/truck_page.dart'; // Import the truck page
import 'package:ctp/pages/wishlist_offers_page.dart'; // Import the wishlist offers page

class CustomBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final double iconSize;

  const CustomBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.iconSize = 30.0, // Adjusted icon size
  });

  Widget _buildNavBarItem(
      BuildContext context, IconData icon, bool isActive, int index) {
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const TruckPage()),
          );
        } else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WishlistOffersPage()),
          );
        } else if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        }
        onItemTapped(index);
      },
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
            ), // Pointer icon with adjusted size
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
