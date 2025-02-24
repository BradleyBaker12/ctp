import 'dart:convert';

import 'package:ctp/adminScreens/viewer_page.dart';
import 'package:ctp/pages/bought_vehicles_list.dart';
import 'package:ctp/pages/edit_profile_page.dart';
import 'package:ctp/pages/sold_vehicles_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_back_button.dart'; // Import the Custom Back Button
import 'package:ctp/components/web_navigation_bar.dart';
import 'package:ctp/components/web_footer.dart'; // Add this import
import 'package:ctp/utils/navigation.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  // Add scaffold key for drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Add this getter for consistent breakpoint
  bool _isCompactNavigation(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1100;

  Widget _buildProfileAction(String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Icon(icon, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String userRole = userProvider.getUserRole;
    // Define the roles
    final bool isAdmin = userRole.toLowerCase() == 'admin';
    final bool isSalesRep = userRole.toLowerCase() == 'sales representative';
    final bool isDealer = userRole.toLowerCase() == 'dealer';
    final bool isTransporter = userRole.toLowerCase() == 'transporter';

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

    var screenSize = MediaQuery.of(context).size;
    const Color borderColor = Color(0xFFFF4E00);
    final Color backgroundColor = borderColor.withOpacity(0.6);

    // Determine the top offset for the back button.
    // For sales reps, set it lower to avoid overlapping the profile photo.
    final double backButtonTopPosition =
        isSalesRep ? screenSize.height * 0.12 : 30;

    String capitalizeFirstLetter(String? value) {
      if (value == null || value.isEmpty) return '';
      return value[0].toUpperCase() + value.substring(1).toLowerCase();
    }

    print(
        "userProvider.getBankConfirmationUrl : ${userProvider.getBankConfirmationUrl}");

    return Scaffold(
      key: _scaffoldKey,
      appBar: kIsWeb && !isAdmin
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: WebNavigationBar(
                isCompactNavigation: _isCompactNavigation(context),
                currentRoute: '/profile',
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            )
          : null,
      drawer: _isCompactNavigation(context)
          ? Drawer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: const [Colors.black, Color(0xFF2F7FFD)],
                  ),
                ),
                child: Column(
                  children: [
                    DrawerHeader(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white24,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Image.network(
                          'https://firebasestorage.googleapis.com/v0/b/ctp-central-database.appspot.com/o/CTPLOGOWeb.png?alt=media&token=d85ec0b5-f2ba-4772-aa08-e9ac6d4c2253',
                          height: 50,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 50,
                              width: 50,
                              color: Colors.grey[900],
                              child: const Icon(Icons.local_shipping,
                                  color: Colors.white),
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: navigationItems.map((item) {
                          bool isActive = '/profile' == item.route;
                          return ListTile(
                            title: Text(
                              item.title,
                              style: TextStyle(
                                color: isActive
                                    ? const Color(0xFFFF4E00)
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            selected: isActive,
                            selectedTileColor: Colors.black12,
                            onTap: () {
                              Navigator.pop(context); // Close drawer
                              if (!isActive) {
                                Navigator.pushNamed(context, item.route);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: GradientBackground(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 600, // Profile content container
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Adjusted SizedBox to reduce top space on web
                          SizedBox(
                              height: kIsWeb ? 20 : screenSize.height * 0.1),
                          if (!kIsWeb)
                            Image.asset(
                              'lib/assets/CTPLogo.png',
                              height: screenSize.height * 0.1,
                              width: screenSize.height * 0.1,
                              fit: BoxFit.cover,
                            )
                          else
                            SizedBox(height: screenSize.height * 0.1),
                          SizedBox(height: screenSize.height * 0.03),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage: kIsWeb
                                      ? (userProvider
                                              .getProfileImageUrl.isNotEmpty
                                          ? NetworkImage(
                                              userProvider.getProfileImageUrl)
                                          : const AssetImage(
                                                  'lib/assets/default-profile-photo.jpg')
                                              as ImageProvider)
                                      : (userProvider
                                              .getProfileImageUrl.isNotEmpty
                                          ? NetworkImage(
                                              userProvider.getProfileImageUrl)
                                          : const AssetImage(
                                                  'lib/assets/default-profile-photo.jpg')
                                              as ImageProvider),
                                  onBackgroundImageError:
                                      (exception, stackTrace) {
                                    const AssetImage(
                                        'lib/assets/default-profile-photo.jpg');
                                  },
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              userProvider.getUserName
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () async {
                                              await MyNavigator.push(
                                                  context, EditProfilePage());
                                              print("Back from page");
                                            },
                                            child: Text(
                                              'Edit Profile'.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationColor: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildProfileDetail(
                            'FULL NAME',
                            '${userProvider.getFirstName ?? ''} ${userProvider.getMiddleName ?? ''} ${userProvider.getLastName ?? ''}',
                          ),
                          _buildProfileDetail(
                              'EMAIL', userProvider.getUserEmail),
                          _buildProfileDetail('PHONE NUMBER',
                              userProvider.getPhoneNumber ?? ''),
                          _buildProfileDetail('ROLE',
                              capitalizeFirstLetter(userProvider.getUserRole)),
                          _buildProfileDetail('COMPANY NAME',
                              userProvider.getCompanyName ?? ''),
                          _buildProfileDetail('TRADING NAME',
                              userProvider.getTradingName ?? ''),
                          _buildProfileDetail('REG NO.',
                              userProvider.getRegistrationNumber ?? ''),
                          _buildProfileDetail(
                              'VAT NO.', userProvider.getVatNumber ?? ''),
                          _buildProfileDetail(
                            'ADDRESS',
                            '${userProvider.getAddressLine1 ?? ''}\n'
                                '${userProvider.getAddressLine2 ?? ''}\n'
                                '${userProvider.getCity ?? ''}\n'
                                '${userProvider.getState ?? ''}\n'
                                '${userProvider.getPostalCode ?? ''}',
                          ),
                          const SizedBox(height: 20),
                          if (isTransporter) ...[
                            const Padding(
                              padding: EdgeInsets.only(left: 16.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'VEHICLE HISTORY',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const Divider(color: Colors.white),
                            _buildProfileAction(
                              'VIEW SOLD VEHICLES',
                              Icons.history,
                              () async {
                                await MyNavigator.push(
                                    context, const SoldVehiclesListPage());
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                          // Add the new section for dealers
                          if (isDealer) ...[
                            const Padding(
                              padding: EdgeInsets.only(left: 16.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'VEHICLE HISTORY',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const Divider(color: Colors.white),
                            _buildProfileAction(
                              'VIEW BOUGHT VEHICLES',
                              Icons.history,
                              () async {
                                await MyNavigator.push(
                                    context, const BoughtVehiclesListPage());
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                          // Only show the Documents section if the user is neither an admin nor a sales rep.
                          if (!isAdmin && !isSalesRep) ...[
                            const Padding(
                              padding: EdgeInsets.only(left: 16.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'DOCUMENTS',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const Divider(color: Colors.white),
                            const SizedBox(height: 10),
                            _buildDocumentItem(
                              'BANK CONFIRMATION',
                              userProvider.getBankConfirmationUrl,
                              Icons.visibility,
                              context,
                            ),
                            if (isDealer)
                              _buildDocumentItem(
                                'CIPC CERTIFICATE',
                                userProvider.getCipcCertificateUrl,
                                Icons.visibility,
                                context,
                              ),
                            _buildDocumentItem(
                              'PROXY',
                              userProvider.getProxyUrl,
                              Icons.visibility,
                              context,
                            ),
                            _buildDocumentItem(
                              'BRNC',
                              userProvider.getBrncUrl,
                              Icons.visibility,
                              context,
                            ),
                            _buildDocumentItem(
                              'TERMS AND CONDITIONS',
                              'https://firebasestorage.googleapis.com/v0/b/ctp-central-database.appspot.com/o/Product%20Terms%20.pdf?alt=media&token=8f27f138-afe2-4b82-83a6-9b49564b4d48',
                              Icons.visibility,
                              context,
                            ),
                            const SizedBox(height: 20),
                          ],
                          ElevatedButton(
                            onPressed: () async {
                              await userProvider.signOut();
                              Navigator.of(context)
                                  .pushReplacementNamed('/login');
                            },
                            style: ElevatedButton.styleFrom(
                              side: const BorderSide(
                                  color: borderColor, width: 2),
                              backgroundColor: backgroundColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Sign Out',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 20),
                          FutureBuilder<String>(
                            future: DefaultAssetBundle.of(context)
                                .loadString('lib/assets/version.json')
                                .then((jsonStr) {
                              final Map<String, dynamic> versionData =
                                  json.decode(jsonStr);
                              return "${versionData['type']} Version ${versionData['version']}";
                            }),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data ?? 'Loading...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          // Removed WebFooter from here
                        ],
                      ),
                    ),
                  ),
                  // Add WebFooter full-width on web
                  if (kIsWeb)
                    Container(
                      width: MediaQuery.of(context).size.width,
                      child: const WebFooter(),
                    )
                ],
              ),
            ),
            // Show the CustomBackButton only for Admins and Sales Reps, with a conditional top offset.
            if (isAdmin || isSalesRep)
              Positioned(
                top:
                    backButtonTopPosition, // Different positioning for sales rep to avoid overlap
                left: 20,
                child: SafeArea(
                  child: CustomBackButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
      // Only show the bottom navigation bar if the user is NOT an admin or a sales rep.
      bottomNavigationBar: (isAdmin || isSalesRep || kIsWeb)
          ? null
          : CustomBottomNavigation(
              selectedIndex: 5, // Index for the profile tab
              onItemTapped: (index) {
                // Handle navigation
              },
            ),
    );
  }

  Widget _buildProfileDetail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Flexible(
            child: Text(
              value.toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(
      String title, String? url, IconData icon, BuildContext context) {
    print("URL :: $url");
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: url != null
                    ? () async {
                        await MyNavigator.push(context, ViewerPage(url: url));
                      }
                    : null,
                child: Text(
                  url != null ? 'VIEW' : 'NOT UPLOADED',
                  style: TextStyle(
                    fontSize: 14,
                    color: url != null ? Colors.white : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                icon,
                color: url != null ? Colors.white : Colors.white,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
