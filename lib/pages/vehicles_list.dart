// lib/pages/vehicles_list_page.dart

import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/listing_card.dart';
import 'package:ctp/pages/home_page.dart';
import 'package:ctp/pages/offersPage.dart';
import 'package:ctp/pages/profile_page.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:ctp/components/custom_app_bar.dart';

class VehiclesListPage extends StatefulWidget {
  const VehiclesListPage({super.key});

  @override
  _VehiclesListPageState createState() => _VehiclesListPageState();
}

class _VehiclesListPageState extends State<VehiclesListPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this); // Create the TabController
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUserId = userProvider.userId;

      if (currentUserId != null) {
        vehicleProvider.fetchVehicles(userProvider,
            userId: currentUserId, filterLikedDisliked: false);
      }

      _scrollController.addListener(() {
        if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent) {
          vehicleProvider.fetchMoreVehicles();
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose(); // Dispose of the TabController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = Provider.of<VehicleProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final currentUserId = userProvider.userId;

    if (currentUserId == null) {
      return Scaffold(
        appBar: CustomAppBar(),
        body: const Center(
          child: Text('User is not signed in.'),
        ),
      );
    }

    final userVehicles = vehicleProvider.getVehiclesByUserId(currentUserId);

    // Filter vehicles by status
    final drafts = userVehicles
        .where((vehicle) => vehicle.vehicleStatus == 'Draft')
        .toList();
    final pending = userVehicles
        .where((vehicle) => vehicle.vehicleStatus == 'Pending')
        .toList();
    final live = userVehicles
        .where((vehicle) => vehicle.vehicleStatus == 'Live')
        .toList();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(),
        body: Column(
          children: [
            const SizedBox(height: 40),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_shipping,
                  color: Color(0xFFFF4E00),
                  size: 30,
                ),
                SizedBox(width: 8),
                Text(
                  'MY VEHICLES',
                  style: TextStyle(
                    color: Color(0xFFFF4E00),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(
              width: 350,
              child: Text(
                'Here are your uploaded vehicles.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            // Add TabBar
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFF4E00),
              unselectedLabelColor: Colors.white,
              indicatorColor: const Color(0xFFFF4E00),
              tabs: const [
                Tab(text: 'Drafts'),
                Tab(text: 'Pending'),
                Tab(text: 'Live'),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Drafts Tab
                  drafts.isEmpty
                      ? Center(
                          child: Text(
                          'No Draft vehicles.',
                          style: GoogleFonts.montserrat(color: Colors.white),
                        ))
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: drafts.length,
                          itemBuilder: (context, index) {
                            final vehicle = drafts[index];
                            return ListingCard(
                              vehicleMakeModel: vehicle.makeModel,
                              vehicleImageUrl: vehicle.mainImageUrl,
                              vehicleYear: vehicle.year,
                              vehicleMileage: vehicle.mileage,
                              vehicleTransmission: vehicle.transmission,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        VehicleDetailsPage(vehicle: vehicle),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                  // Pending Tab
                  pending.isEmpty
                      ? Center(
                          child: Text('No Pending vehicles.',
                              style:
                                  GoogleFonts.montserrat(color: Colors.white)))
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: pending.length,
                          itemBuilder: (context, index) {
                            final vehicle = pending[index];
                            return ListingCard(
                              vehicleMakeModel: vehicle.makeModel,
                              vehicleImageUrl: vehicle.mainImageUrl,
                              vehicleYear: vehicle.year,
                              vehicleMileage: vehicle.mileage,
                              vehicleTransmission: vehicle.transmission,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        VehicleDetailsPage(vehicle: vehicle),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                  // Live Tab
                  live.isEmpty
                      ? Center(
                          child: Text('No Live vehicles.',
                              style:
                                  GoogleFonts.montserrat(color: Colors.white)))
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: live.length,
                          itemBuilder: (context, index) {
                            final vehicle = live[index];
                            return ListingCard(
                              vehicleMakeModel: vehicle.makeModel,
                              vehicleImageUrl: vehicle.mainImageUrl,
                              vehicleYear: vehicle.year,
                              vehicleMileage: vehicle.mileage,
                              vehicleTransmission: vehicle.transmission,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        VehicleDetailsPage(vehicle: vehicle),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavigation(
          selectedIndex: _selectedIndex,
          onItemTapped: (index) {
            _onItemTapped(index);
            // Handle navigation based on the selected index and user role
            // Ensure that navigation is not triggered during the build phase
            final userRole = userProvider.getUserRole.toLowerCase().trim();

            if (userRole == 'dealer') {
              // Navigation items for dealers:
              // 0: Home, 1: Vehicles, 2: Offers
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              } else if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const VehiclesListPage()),
                );
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const OffersPage()),
                );
              }
            } else if (userRole == 'transporter') {
              // Navigation items for transporters:
              // 0: Home, 1: Vehicles, 2: Offers, 3: Profile
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              } else if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const VehiclesListPage()),
                );
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const OffersPage()),
                );
              } else if (index == 3) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              }
            } else {
              // Handle other roles or undefined roles if necessary
            }
          },
        ),
      ),
    );
  }

  TextStyle _customFont(double fontSize, FontWeight fontWeight, Color color) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFamily: 'Montserrat',
    );
  }
}
