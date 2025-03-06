import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';

class NavigationItem {
  final String title;
  final String route;

  NavigationItem({
    required this.title,
    required this.route,
  });
}

class WebNavigationBar extends StatelessWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool isCompactNavigation;
  final String currentRoute;
  final VoidCallback? onMenuPressed;

  const WebNavigationBar({
    super.key,
    this.scaffoldKey,
    required this.isCompactNavigation,
    required this.currentRoute,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.getUserRole;
    final screenWidth = MediaQuery.of(context).size.width;
    // If screenWidth is 600 or more, use a fixed width of 150, otherwise 10% of the width.
    final bool isTabletOrLarger = screenWidth >= 600;
    final logoWidth = isTabletOrLarger ? 200.0 : screenWidth * 0.3;

    List<NavigationItem> navigationItems = userRole == 'dealer'
        ? [
            NavigationItem(title: 'Home', route: '/home'),
            NavigationItem(title: 'Search Trucks', route: '/truckPage'),
            NavigationItem(title: 'Wishlist', route: '/wishlist'),
            NavigationItem(title: 'Pending Offers', route: '/offers'),
          ]
        : [
            NavigationItem(title: 'Home', route: '/home'),
            NavigationItem(title: 'Your Trucks', route: '/transporterList'),
            NavigationItem(title: 'Your Offers', route: '/offers'),
            NavigationItem(title: 'In-Progress', route: '/in-progress'),
          ];

    return Container(
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [Colors.black, Color(0xFF2F7FFD)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left section - Hamburger menu (only shown in compact mode)
            if (isCompactNavigation)
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                onPressed: onMenuPressed,
                tooltip: 'Open menu',
              ),

            // Center section - Logo and Navigation Links
            Expanded(
              child: Row(
                mainAxisAlignment: isCompactNavigation
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (userRole == 'admin') {
                        Navigator.pushNamed(context, '/adminHome');
                      } else {
                        Navigator.pushNamed(context, '/home');
                      }
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: SizedBox(
                        width: logoWidth,
                        child: Image.network(
                          'https://firebasestorage.googleapis.com/v0/b/ctp-central-database.appspot.com/o/CTPLOGOWeb.png?alt=media&token=d85ec0b5-f2ba-4772-aa08-e9ac6d4c2253',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: logoWidth,
                              height: logoWidth,
                              color: Colors.grey[900],
                              child: const Icon(
                                Icons.local_shipping,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  // Navigation links (only shown in full mode)
                  if (!isCompactNavigation) ...[
                    const SizedBox(width: 60),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: navigationItems.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child:
                                _buildNavItem(context, item.title, item.route),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Right section - Profile icon
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: CircleAvatar(
                radius: 18,
                backgroundImage: userProvider.getProfileImageUrl != null
                    ? NetworkImage(userProvider.getProfileImageUrl)
                    : const AssetImage('lib/assets/default_profile.png')
                        as ImageProvider,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String title, String route) {
    bool isActive = currentRoute == route;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () {
          if (!isActive) {
            Navigator.pushNamed(context, route);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: isActive
              ? BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFFF4E00),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isActive ? const Color(0xFFFF4E00) : Colors.white,
              fontFamily: 'Montserrat',
            ),
          ),
        ),
      ),
    );
  }
}
