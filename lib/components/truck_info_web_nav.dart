import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';

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
    Key? key,
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
  }) : super(key: key);

  bool _isCompactNavigation(BuildContext context) {
    return MediaQuery.of(context).size.width <= 1100;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.getUserRole;
    final isCompact = _isCompactNavigation(context);

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
            // Hamburger menu for compact mode
            if (isCompact)
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                onPressed: () => _showNavigationDrawer(context),
                tooltip: 'Open menu',
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
                      child: Image.network(
                        'https://firebasestorage.googleapis.com/v0/b/ctp-central-database.appspot.com/o/CTPLOGOWeb.png?alt=media&token=d85ec0b5-f2ba-4772-aa08-e9ac6d4c2253',
                        height: 40,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 40,
                            width: 40,
                            color: Colors.grey[900],
                            child: const Icon(Icons.local_shipping,
                                color: Colors.white),
                          );
                        },
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
                            // Show truck condition navigation buttons
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
                            // Show main navigation buttons
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

            // Profile icon
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
                            Image.network(
                              'https://firebasestorage.googleapis.com/v0/b/ctp-central-database.appspot.com/o/CTPLOGOWeb.png?alt=media&token=d85ec0b5-f2ba-4772-aa08-e9ac6d4c2253',
                              height: 40,
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
                      // Add more navigation items
                      _buildDrawerItem(
                          context, "Basic Information", onBasicInfoPressed),
                      _buildDrawerItem(context, "Truck Conditions",
                          onTruckConditionsPressed),
                      _buildDrawerItem(context, "Maintenance and Warranty",
                          onMaintenanceWarrantyPressed),
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
