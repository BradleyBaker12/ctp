import 'package:ctp/pages/offersPage.dart';
import 'package:flutter/material.dart';
import 'package:ctp/pages/home_page.dart';
import 'package:ctp/pages/profile_page.dart';
import 'package:ctp/pages/truck_page.dart';
import 'package:ctp/pages/wishlist_offers_page.dart';
import 'package:ctp/pages/vehicles_list.dart'; // Import the vehicles list page
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart'; // Import the UserProvider

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
      onTap: () {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userRole = userProvider.getUserRole;

        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else if (index == 1) {
          if (userRole == 'transporter') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const VehiclesListPage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TruckPage()),
            );
          }
        } else if (index == 2) {
          if (userRole == 'transporter') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OffersPage()),
            );
          }
        } else if (index == 3 && userRole != 'transporter') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WishlistOffersPage()),
          );
        } else if (index == 4) {
          if (userRole == 'dealer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OffersPage()),
            );
          }
        } else if (index == 5 && userRole != 'dealer') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        }

        if (!(userRole == 'dealer' && index == 3)) {
          onItemTapped(index);
        }
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
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = userProvider.getUserRole;

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
          if (userRole == 'transporter')
            _buildNavBarItem(context, Icons.handshake, selectedIndex == 2, 2),
          if (userRole != 'transporter')
            _buildNavBarItem(context, Icons.favorite, selectedIndex == 3, 3),
          if (userRole == 'dealer')
            _buildNavBarItem(context, Icons.handshake, selectedIndex == 4, 4),
          if (userRole != 'dealer')
            _buildNavBarItem(context, Icons.person, selectedIndex == 5, 5),
        ],
      ),
    );
  }
}
