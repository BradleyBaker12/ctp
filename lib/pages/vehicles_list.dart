import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/listing_card.dart';
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

    List<Widget> buildVehicleList(List vehicles) {
      return vehicles.isEmpty
          ? [const Center(child: Text('No vehicles found.'))]
          : vehicles.map((vehicle) {
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
            }).toList();
    }

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
              labelColor: Color(0xFFFF4E00),
              unselectedLabelColor: Colors.white,
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
                            return buildVehicleList(drafts)[index];
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
                            return buildVehicleList(pending)[index];
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
                            return buildVehicleList(live)[index];
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavigation(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }
}
