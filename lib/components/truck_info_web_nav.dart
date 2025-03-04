import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/foundation.dart'; // Added for kIsWeb

class TruckInfoWebNavBar extends StatelessWidget {
  final VoidCallback onHomePressed;
  final VoidCallback onBasicInfoPressed;
  final VoidCallback onTruckConditionsPressed;
  final VoidCallback onMaintenanceWarrantyPressed;
  final String selectedTab;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback onExternalCabPressed;
  final VoidCallback onInternalCabPressed;
  final VoidCallback onChassisPressed;
  final VoidCallback onDriveTrainPressed;
  final VoidCallback onTyresPressed;
  final String vehicleId; // Changed from String? to String

  const TruckInfoWebNavBar({
    super.key,
    required this.onHomePressed,
    required this.onBasicInfoPressed,
    required this.onTruckConditionsPressed,
    required this.onMaintenanceWarrantyPressed,
    required this.scaffoldKey,
    required this.onExternalCabPressed,
    required this.onInternalCabPressed,
    required this.onChassisPressed,
    required this.onDriveTrainPressed,
    required this.onTyresPressed,
    required this.vehicleId, // Made required
    this.selectedTab = "Home",
  });

  bool _isCompactNavigation(BuildContext context) {
    // Base width needed for logo, profile, and spacing
    const baseWidth = 300.0;

    // Width per navigation item (includes padding and text)
    const itemWidth = 180.0;

    // Calculate the total width needed based on which navigation items are shown
    double requiredWidth = baseWidth;

    if (["External Cab", "Internal Cab", "Chassis", "Drive Train", "Tyres"]
        .contains(selectedTab)) {
      // Truck condition pages show 5 conditions plus Home
      requiredWidth += itemWidth * 6; // 5 conditions + Home
    } else {
      // Basic navigation items: Basic Info, Truck Conditions, Maintenance + Home
      requiredWidth += itemWidth * 4;
    }

    // Show hamburger menu as soon as available width is less than needed.
    return MediaQuery.of(context).size.width < requiredWidth;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.getUserRole;
    final isCompact = _isCompactNavigation(context);

    // Get the screen width and determine logo width.
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTabletOrLarger = screenWidth >= 600;
    // For tablet or larger, use a fixed width of 150; otherwise 10% of the screen width.
    final logoWidth = isTabletOrLarger ? 200.0 : screenWidth * 0.3;

    // Check if we're on a truck condition page
    final bool isOnTruckConditionPage = [
      "External Cab",
      "Internal Cab",
      "Chassis",
      "Drive Train",
      "Tyres"
    ].contains(selectedTab);

    return Container(
      height: 70,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.black, Color(0xFF2F7FFD)],
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
            // Left section with hamburger menu and back button (only in compact mode)
            Row(
              children: [
                if (isCompact) ...[
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                    onPressed: () => _showNavigationDrawer(context),
                    tooltip: 'Open menu',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Go back',
                  ),
                ],
              ],
            ),

            // Logo section
            Expanded(
              child: Row(
                mainAxisAlignment: isCompact
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      userRole == 'admin' ? '/admin-home' : '/home',
                    ),
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
                  // Navigation items only shown in full mode
                  if (!isCompact) ...[
                    const SizedBox(width: 60),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Home is always shown
                          _buildNavItem(context, "Home", selectedTab == "Home",
                              () {
                            if (userRole == 'admin') {
                              Navigator.pushNamed(context, '/admin-home');
                            } else {
                              onHomePressed();
                            }
                          }),
                          // Show either truck condition pages OR main navigation
                          if (isOnTruckConditionPage) ...[
                            _buildNavItem(
                              context,
                              "External Cab",
                              selectedTab == "External Cab",
                              () => Navigator.pushReplacementNamed(
                                  context, '/external_cab',
                                  arguments: vehicleId),
                            ),
                            _buildNavItem(
                              context,
                              "Internal Cab",
                              selectedTab == "Internal Cab",
                              () => Navigator.pushReplacementNamed(
                                  context, '/internal_cab',
                                  arguments: vehicleId),
                            ),
                            _buildNavItem(
                              context,
                              "Chassis",
                              selectedTab == "Chassis",
                              () => Navigator.pushReplacementNamed(
                                  context, '/chassis',
                                  arguments: vehicleId),
                            ),
                            _buildNavItem(
                              context,
                              "Drive Train",
                              selectedTab == "Drive Train",
                              () => Navigator.pushReplacementNamed(
                                  context, '/drive_train',
                                  arguments: vehicleId),
                            ),
                            _buildNavItem(
                              context,
                              "Tyres",
                              selectedTab == "Tyres",
                              () => Navigator.pushReplacementNamed(
                                  context, '/tyres',
                                  arguments: vehicleId),
                            ),
                          ] else ...[
                            _buildNavItem(
                              context,
                              "Basic Information",
                              selectedTab == "Basic Information",
                              () => Navigator.pushReplacementNamed(
                                context,
                                '/basic_information',
                                arguments: vehicleId,
                              ),
                            ),
                            _buildNavItem(
                              context,
                              "Truck Conditions",
                              selectedTab == "Truck Conditions",
                              () => Navigator.pushReplacementNamed(
                                context,
                                '/external_cab',
                                arguments: vehicleId,
                              ),
                            ),
                            _buildNavItem(
                              context,
                              "Maintenance and Warranty",
                              selectedTab == "Maintenance and Warranty",
                              () => Navigator.pushReplacementNamed(
                                context,
                                '/maintenance_warranty',
                                arguments: vehicleId,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Right section - Profile icon
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

  void _showNavigationDrawer(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTabletOrLarger = screenWidth >= 600;
    final logoWidth = isTabletOrLarger ? screenWidth * 0.15 : screenWidth * 0.1;

    // Check if we're on a truck condition page
    final bool isOnTruckConditionPage = [
      "External Cab",
      "Internal Cab",
      "Chassis",
      "Drive Train",
      "Tyres"
    ].contains(selectedTab);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Stack(
          children: [
            // Semi-transparent background
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black54),
            ),
            // Sliding drawer
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: ModalRoute.of(context)!.animation!,
                curve: Curves.easeOut,
              )),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.black, Color(0xFF2F7FFD)],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header with logo and close button
                      Container(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 20,
                          bottom: 20,
                          left: 16,
                          right: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: logoWidth,
                              child: Image.network(
                                'https://firebasestorage.googleapis.com/v0/b/ctp-central-database.appspot.com/o/CTPLOGOWeb.png?alt=media&token=d85ec0b5-f2ba-4772-aa08-e9ac6d4c2253',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: logoWidth,
                                    height: logoWidth,
                                    color: Colors.grey[900],
                                    child: const Icon(Icons.local_shipping,
                                        color: Colors.white),
                                  );
                                },
                              ),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white24),
                      // Navigation items
                      ListTile(
                        selected: selectedTab == "Home",
                        selectedTileColor: Colors.black12,
                        title: Text(
                          "Home",
                          style: TextStyle(
                            color: selectedTab == "Home"
                                ? const Color(0xFFFF4E00)
                                : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          onHomePressed();
                        },
                      ),
                      if (isOnTruckConditionPage) ...[
                        _buildDrawerItem(context, "External Cab", () {
                          Navigator.pushReplacementNamed(
                              context, '/external_cab',
                              arguments: vehicleId);
                        }),
                        _buildDrawerItem(context, "Internal Cab", () {
                          Navigator.pushReplacementNamed(
                              context, '/internal_cab',
                              arguments: vehicleId);
                        }),
                        _buildDrawerItem(context, "Chassis", () {
                          Navigator.pushReplacementNamed(context, '/chassis',
                              arguments: vehicleId);
                        }),
                        _buildDrawerItem(context, "Drive Train", () {
                          Navigator.pushReplacementNamed(
                              context, '/drive_train',
                              arguments: vehicleId);
                        }),
                        _buildDrawerItem(context, "Tyres", () {
                          Navigator.pushReplacementNamed(context, '/tyres',
                              arguments: vehicleId);
                        }),
                      ] else ...[
                        _buildDrawerItem(
                            context, "Basic Information", onBasicInfoPressed),
                        _buildDrawerItem(context, "Truck Conditions",
                            onTruckConditionsPressed),
                        _buildDrawerItem(context, "Maintenance and Warranty",
                            onMaintenanceWarrantyPressed),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, String title, VoidCallback onPressed) {
    return ListTile(
      selected: selectedTab == title,
      selectedTileColor: Colors.black12,
      title: Text(
        title,
        style: TextStyle(
          color: selectedTab == title ? const Color(0xFFFF4E00) : Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        switch (title) {
          case "Basic Information":
            Navigator.pushReplacementNamed(context, '/basic_information',
                arguments: vehicleId);
            break;
          case "Truck Conditions":
            Navigator.pushReplacementNamed(context, '/external_cab',
                arguments: vehicleId);
            break;
          case "Maintenance and Warranty":
            Navigator.pushReplacementNamed(context, '/maintenance_warranty',
                arguments: vehicleId);
            break;
          default:
            onPressed();
        }
      },
    );
  }

  Widget _buildNavItem(BuildContext context, String title, bool isActive,
      VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onPressed,
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
      ),
    );
  }
}
