import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/listing_card.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/components/custom_bottom_navigation.dart'; // Import the custom bottom navigation
import 'package:ctp/pages/vehicle_details_page.dart'; // Import the VehicleDetailsPage
import 'package:ctp/components/custom_app_bar.dart'; // Import the custom app bar

class VehiclesListPage extends StatefulWidget {
  const VehiclesListPage({Key? key}) : super(key: key);

  @override
  _VehiclesListPageState createState() => _VehiclesListPageState();
}

class _VehiclesListPageState extends State<VehiclesListPage> {
  int _selectedIndex = 1;
  final ScrollController _scrollController = ScrollController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Handle navigation to different pages if needed
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUserId = userProvider.userId;

      if (currentUserId != null) {
        vehicleProvider.fetchVehicles(userProvider,
            userId: currentUserId, filterLikedDisliked: false);
      }

      // Add listener to the scroll controller for pagination
      _scrollController.addListener(() {
        if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent) {
          // Trigger fetching more vehicles when reaching the end
          vehicleProvider.fetchMoreVehicles();
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
            Expanded(
              child: vehicleProvider.isLoading && userVehicles.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController, // Attach scroll controller
                      itemCount: userVehicles.length +
                          1, // Add an extra item for the loading indicator
                      itemBuilder: (context, index) {
                        if (index == userVehicles.length) {
                          // Show loading indicator at the bottom
                          return vehicleProvider.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : const SizedBox(); // Empty widget when not loading
                        }

                        final vehicle = userVehicles[index];
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
                                builder: (context) => VehicleDetailsPage(
                                  vehicle: vehicle,
                                ),
                              ),
                            );
                          },
                        );
                      },
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
