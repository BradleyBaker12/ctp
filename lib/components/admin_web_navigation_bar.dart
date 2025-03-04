import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';

class NavigationItem {
  final String title;
  final String route; // kept for consistency

  NavigationItem({
    required this.title,
    required this.route,
  });
}

class AdminWebNavigationBar extends StatelessWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool isCompactNavigation;
  final String currentRoute;
  final VoidCallback? onMenuPressed;
  final void Function(int)? onTabSelected; // new callback

  const AdminWebNavigationBar({
    super.key,
    this.scaffoldKey,
    required this.isCompactNavigation,
    required this.currentRoute,
    this.onMenuPressed,
    this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    // Determine logo width based on screen size:
    // On tablets or larger (>=600px), use a fixed width of 150.0; otherwise, use 10% of the screen width.
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTabletOrLarger = screenWidth >= 600;
    final logoWidth = isTabletOrLarger ? 200.0 : screenWidth * 0.3;

    // Define compact mode for the layout; here using a breakpoint of 900px.
    final bool isCompact = MediaQuery.of(context).size.width < 900;
    final userProvider = Provider.of<UserProvider>(context);

    List<NavigationItem> navigationItems = [
      NavigationItem(title: 'Users', route: '/adminUsers'),
      NavigationItem(title: 'Offers', route: '/adminOffers'),
      NavigationItem(title: 'Complaints', route: '/adminComplaints'),
      NavigationItem(title: 'Vehicles', route: '/adminVehicles'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (isCompact) {
          return Container(
            height: double.infinity,
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
                  // Hamburger menu in compact mode.
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                    onPressed: () {
                      if (onMenuPressed != null) {
                        onMenuPressed!();
                      } else {
                        Scaffold.of(context).openDrawer();
                      }
                    },
                    tooltip: 'Open menu',
                  ),
                  // Logo.
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/adminHome'),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
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
                  // Profile icon.
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/profile'),
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
        } else {
          // Full navigation bar for larger screens.
          return Container(
            height: double.infinity,
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
                  // No hamburger in full mode.
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/adminHome'),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
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
                        const SizedBox(width: 60),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: navigationItems.map((item) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: _buildNavItem(context, item.title),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/profile'),
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
      },
    );
  }

  Widget _buildNavItem(BuildContext context, String title) {
    bool isActive = currentRoute == title;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () {
          // Use the callback if provided.
          if (onTabSelected != null) {
            if (title == 'Users') {
              onTabSelected!(0);
            } else if (title == 'Offers') {
              onTabSelected!(1);
            } else if (title == 'Complaints') {
              onTabSelected!(2);
            } else if (title == 'Vehicles') {
              onTabSelected!(3);
            }
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
