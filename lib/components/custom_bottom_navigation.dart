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
      BuildContext context, Widget iconWidget, bool isActive, int index) {
    return GestureDetector(
      onTap: () {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userRole = userProvider.getUserRole;

        // Navigation logic based on userRole and index
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
              MaterialPageRoute(
                  builder: (context) => const TruckPage(vehicleType: 'truck')),
            );
          }
        } else if (index == 2 && userRole == 'transporter') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OffersPage()),
          );
        } else if (index == 3 && userRole != 'transporter') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WishlistOffersPage()),
          );
        } else if (index == 4 && userRole == 'dealer') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OffersPage()),
          );
        } else if (index == 5 && userRole != 'dealer') {
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
          iconWidget,
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
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final userRole = userProvider.getUserRole;

        return Container(
          height: 80,
          color: const Color(0xFF2F7FFF),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home Icon - Available for all roles
              _buildNavBarItem(
                context,
                Icon(
                  Icons.home,
                  size: iconSize,
                  color: selectedIndex == 0
                      ? Colors.black
                      : Colors.black.withOpacity(0.6),
                ),
                selectedIndex == 0,
                0,
              ),
              // Vehicles or Truck Icon
              _buildNavBarItem(
                context,
                Icon(
                  Icons.local_shipping,
                  size: iconSize,
                  color: selectedIndex == 1
                      ? Colors.black
                      : Colors.black.withOpacity(0.6),
                ),
                selectedIndex == 1,
                1,
              ),
              // Transporter Offers Icon - Only for transporters
              if (userRole == 'transporter')
                _buildNavBarItem(
                  context,
                  ImageIcon(
                    const AssetImage('lib/assets/transporter_handshake.png'),
                    size: iconSize,
                    color: selectedIndex == 2
                        ? Colors.black
                        : Colors.black.withOpacity(0.6),
                  ),
                  selectedIndex == 2,
                  2,
                ),
              // Wishlist Icon - Only for non-transporters
              if (userRole != 'transporter')
                _buildNavBarItem(
                  context,
                  Icon(
                    Icons.favorite,
                    size: iconSize,
                    color: selectedIndex == 3
                        ? Colors.black
                        : Colors.black.withOpacity(0.6),
                  ),
                  selectedIndex == 3,
                  3,
                ),
              // Dealer Offers Icon - Only for dealers
              if (userRole == 'dealer')
                _buildNavBarItem(
                  context,
                  ImageIcon(
                    const AssetImage('lib/assets/dealer_handshake.png'),
                    size: iconSize,
                    color: selectedIndex == 4
                        ? Colors.black
                        : Colors.black.withOpacity(0.6),
                  ),
                  selectedIndex == 4,
                  4,
                ),
              // Profile Icon - Only for non-dealers
              if (userRole != 'dealer')
                _buildNavBarItem(
                  context,
                  Icon(
                    Icons.person,
                    size: iconSize,
                    color: selectedIndex == 5
                        ? Colors.black
                        : Colors.black.withOpacity(0.6),
                  ),
                  selectedIndex == 5,
                  5,
                ),
            ],
          ),
        );
      },
    );
  }
}
