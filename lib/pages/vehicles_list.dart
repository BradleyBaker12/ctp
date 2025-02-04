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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUserId = userProvider.userId;

      if (currentUserId != null) {
        // Fetch vehicles for the logged-in user
        await vehicleProvider.fetchVehicles(
          userProvider,
          userId: currentUserId,
          filterLikedDisliked: false,
        );
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

    // Get all vehicles uploaded by the current user
    final userVehicles = vehicleProvider.getVehiclesByUserId(currentUserId);

    // Separate them by status
    final drafts =
        userVehicles.where((v) => v.vehicleStatus == 'Draft').toList();
    final pending =
        userVehicles.where((v) => v.vehicleStatus == 'pending').toList();
    final live = userVehicles.where((v) => v.vehicleStatus == 'Live').toList();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(),
        body: Column(
          children: [
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!isLoading && userVehicles.isEmpty)
              Center(
                child: Text(
                  'No Vehicles Found',
                  style: GoogleFonts.montserrat(color: Colors.white),
                ),
              ),
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

            // Tab bar for Draft / Pending / Live
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFF4E00),
              unselectedLabelColor: Colors.white,
              indicatorColor: const Color(0xFFFF4E00),
              tabs: [
                Tab(text: 'Drafts (${drafts.length})'),
                Tab(text: 'Pending (${pending.length})'),
                Tab(text: 'Live (${live.length})'),
              ],
            ),
            const SizedBox(height: 16),

            // Tab views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Draft tab
                  drafts.isEmpty
                      ? Center(
                          child: Text(
                            'No Draft vehicles.',
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                        )
                      : _buildVehiclesList(drafts),

                  // Pending tab
                  pending.isEmpty
                      ? Center(
                          child: Text(
                            'No Pending vehicles.',
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                        )
                      : _buildVehiclesList(pending),

                  // Live tab
                  live.isEmpty
                      ? Center(
                          child: Text(
                            'No Live vehicles.',
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                        )
                      : _buildVehiclesList(live),
                ],
              ),
            ),
          ],
        ),

        // Bottom nav
        bottomNavigationBar: CustomBottomNavigation(
          selectedIndex: _selectedIndex,
          onItemTapped: (index) {
            _onItemTapped(index);
            final userRole = userProvider.getUserRole.toLowerCase().trim();

            // Example for dealers
            if (userRole == 'dealer') {
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
                    builder: (context) => const VehiclesListPage(),
                  ),
                );
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const OffersPage()),
                );
              }
            }
            // Example for transporters
            else if (userRole == 'transporter') {
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
                    builder: (context) => const VehiclesListPage(),
                  ),
                );
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const OffersPage()),
                );
              } else if (index == 3) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              }
            } else {
              // Handle other roles if needed
            }
          },
        ),
      ),
    );
  }

  /// Build a list of vehicles using ListingCard
  Widget _buildVehiclesList(List vehicles) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        return ListingCard(
          vehicleId: vehicle.id,
          vehicleType: vehicle.vehicleType, // e.g. "truck" or "trailer"
          onTap: () {
            // Go to details page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VehicleDetailsPage(vehicle: vehicle),
              ),
            );
          },
          // Common fields
          vehicleImageUrl: vehicle.mainImageUrl,
          referenceNumber: vehicle.referenceNumber,
          vehicleTransmission: vehicle.transmissionType,
          vehicleMileage: vehicle.mileage,
          // Trailer fields
          trailerType: vehicle.trailerType,
          trailerMake: vehicle.brands.isNotEmpty ? vehicle.brands.first : '',
          trailerYear: vehicle.year,
          // Truck fields
          truckBrand: vehicle.brands.isNotEmpty ? vehicle.brands.first : '',
          truckModel: vehicle.makeModel,
        );
      },
    );
  }
}
