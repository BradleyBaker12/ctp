import 'package:ctp/pages/offersPage.dart';
import 'package:ctp/pages/wish_list_page.dart';
import 'package:flutter/material.dart';
import 'package:ctp/pages/home_page.dart';
import 'package:ctp/pages/profile_page.dart';
import 'package:ctp/pages/truck_page.dart';
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
                builder: (context) => const TruckPage(),
              ),
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
            MaterialPageRoute(builder: (context) => const WishlistPage()),
          );
        } else if (index == 4 && userRole == 'dealer') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OffersPage()),
          );
        } else if (index == 5 && userRole != 'dealer') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfilePage()),
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

        List<Widget> navBarItems = [];

        // Home Icon - Available for all roles
        navBarItems.add(Expanded(
          child: _buildNavBarItem(
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
        ));

        navBarItems.add(_buildVerticalDivider());

        // Vehicles or Truck Icon
        navBarItems.add(Expanded(
          child: _buildNavBarItem(
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
        ));

        if (userRole == 'transporter') {
          navBarItems.add(_buildVerticalDivider());
          // Transporter Offers Icon - Only for transporters
          navBarItems.add(Expanded(
            child: _buildNavBarItem(
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
          ));
        }

        if (userRole != 'transporter') {
          navBarItems.add(_buildVerticalDivider());
          // Wishlist Icon - Only for non-transporters
          navBarItems.add(Expanded(
            child: _buildNavBarItem(
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
          ));
        }

        if (userRole == 'dealer') {
          navBarItems.add(_buildVerticalDivider());
          // Dealer Offers Icon - Only for dealers
          navBarItems.add(Expanded(
            child: _buildNavBarItem(
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
          ));
        }

        if (userRole != 'dealer') {
          navBarItems.add(_buildVerticalDivider());
          // Profile Icon - Only for non-dealers
          navBarItems.add(Expanded(
            child: _buildNavBarItem(
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
          ));
        }

        return Container(
          height: 80,
          color: const Color(0xFF2F7FFF),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navBarItems,
          ),
        );
      },
    );
  }

  // Add this helper method for the vertical divider
  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 80,
      color: Colors.white.withOpacity(0.5),
    );
  }
}
