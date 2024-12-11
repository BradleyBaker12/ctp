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

// Import nested models
import 'package:ctp/models/admin_data.dart';
import 'package:ctp/models/maintenance.dart';
import 'package:ctp/models/truck_conditions.dart';
import 'package:ctp/models/external_cab.dart';
import 'package:ctp/models/internal_cab.dart';
import 'package:ctp/models/chassis.dart';
import 'package:ctp/models/drive_train.dart';
import 'package:ctp/models/tyres.dart';

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
        await vehicleProvider.fetchVehicles(userProvider,
            userId: currentUserId, filterLikedDisliked: false);
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose(); // Dispose of the TabController
    super.dispose();
  }

  // Helper methods to create default nested instances
  AdminData _getDefaultAdminData() {
    return AdminData(
      settlementAmount: '0',
      natisRc1Url: '',
      licenseDiskUrl: '',
      settlementLetterUrl: '',
    );
  }

  Maintenance _getDefaultMaintenance(String vehicleId) {
    return Maintenance(
      vehicleId: vehicleId,
      oemInspectionType: '',
      maintenanceDocUrl: '',
      warrantyDocUrl: '',
      maintenanceSelection: '',
      warrantySelection: '',
      lastUpdated: DateTime.now(),
    );
  }

  TruckConditions _getDefaultTruckConditions() {
    return TruckConditions(
      externalCab: ExternalCab(
        damages: [],
        additionalFeatures: [],
        condition: '',
        damagesCondition: '',
        additionalFeaturesCondition: '',
        images: {},
      ),
      internalCab: InternalCab(
          condition: '',
          damagesCondition: '',
          additionalFeaturesCondition: '',
          faultCodesCondition: '',
          viewImages: {},
          damages: [],
          additionalFeatures: [],
          faultCodes: []),
      chassis: Chassis(
          condition: '',
          damagesCondition: '',
          additionalFeaturesCondition: '',
          images: {},
          damages: [],
          additionalFeatures: []),
      driveTrain: DriveTrain(
        condition: '',
        oilLeakConditionEngine: '',
        waterLeakConditionEngine: '',
        blowbyCondition: '',
        oilLeakConditionGearbox: '',
        retarderCondition: '',
        lastUpdated: DateTime.now(),
        images: {
          'Right Brake': '',
          'Left Brake': '',
          'Front Axel': '',
          'Suspension': '',
          'Fuel Tank': '',
          'Battery': '',
          'Cat Walk': '',
          'Electrical Cable Black': '',
          'Air Cable Yellow': '',
          'Air Cable Red': '',
          'Tail Board': '',
          '5th Wheel': '',
          'Left Brake Rear Axel': '',
          'Right Brake Rear Axel': '',
        },
        damages: [],
        additionalFeatures: [],
        faultCodes: [],
      ),
      tyres: {
        'default': Tyres(
          lastUpdated: DateTime.now(),
          positions: {},
        ),
      },
    );
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
    print('User Id: $currentUserId');
    print('Fetched vehicles count: ${userVehicles.length}');

    // Add print statements to verify the filtering logic
    print('Total vehicles: ${userVehicles.length}');
    final drafts = userVehicles
        .where((vehicle) => vehicle.vehicleStatus == 'Draft')
        .toList();
    print('Drafts filtered: ${drafts.length}');

    final pending = userVehicles
        .where((vehicle) => vehicle.vehicleStatus == 'Pending')
        .toList();

    final live = userVehicles
        .where((vehicle) => vehicle.vehicleStatus == 'Live')
        .toList();

    print('Pending: ${pending.length}');
    print('Live: ${live.length}');
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(),
        body: Column(
          children: [
            if (isLoading) const Center(child: CircularProgressIndicator()),
            if (userVehicles.isEmpty)
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
                              vehicleMakeModel: vehicle.makeModel.toString(),
                              vehicleImageUrl: vehicle.mainImageUrl,
                              vehicleYear: vehicle.year.toString(),
                              vehicleMileage: vehicle.mileage,
                              vehicleTransmission: vehicle.transmissionType,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VehicleDetailsPage(
                                      vehicle: vehicle,
                                    ),
                                  ),
                                );
                              },
                              vehicleId: vehicle.id,
                              referenceNumber: vehicle.referenceNumber,
                              brands: vehicle.brands,
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
                              brands: vehicle.brands,
                              vehicleMakeModel: vehicle.makeModel.toString(),
                              vehicleImageUrl: vehicle.mainImageUrl,
                              vehicleYear: vehicle.year.toString(),
                              vehicleMileage: vehicle.mileage,
                              vehicleTransmission: vehicle.transmissionType,
                              referenceNumber: vehicle.referenceNumber,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VehicleDetailsPage(
                                      vehicle: vehicle,
                                    ),
                                  ),
                                );
                              },
                              vehicleId: vehicle.id,
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
                              brands: vehicle.brands,
                              vehicleMakeModel: vehicle.makeModel.toString(),
                              vehicleImageUrl: vehicle.mainImageUrl,
                              vehicleYear: vehicle.year.toString(),
                              vehicleMileage: vehicle.mileage,
                              vehicleTransmission: vehicle.transmissionType,
                              referenceNumber: vehicle.referenceNumber,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VehicleDetailsPage(
                                      vehicle: vehicle,
                                    ),
                                  ),
                                );
                              },
                              vehicleId: vehicle.id,
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
