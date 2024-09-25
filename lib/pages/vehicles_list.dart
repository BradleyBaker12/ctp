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

      print('initState - Current User ID: $currentUserId');

      if (currentUserId != null) {
        vehicleProvider.fetchVehicles(userProvider,
            userId: currentUserId, filterLikedDisliked: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = Provider.of<VehicleProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    // Fetch the current user's ID from the UserProvider
    final currentUserId = userProvider.userId;

    print('build - Current User ID: $currentUserId');

    // Check if currentUserId is null
    if (currentUserId == null) {
      return Scaffold(
        appBar: CustomAppBar(), // Use the custom app bar here
        body: const Center(
          child: Text('User is not signed in.'),
        ),
      );
    }

    // Get the filtered vehicles by current userId
    final userVehicles = vehicleProvider.getVehiclesByUserId(currentUserId);

    print(
        'Total vehicles to be displayed for user $currentUserId: ${userVehicles.length}');

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(), // Use the custom app bar here
        body: Column(
          children: [
            const SizedBox(height: 40),
            // Styled heading
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
              child: vehicleProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : userVehicles.isEmpty
                      ? const Center(
                          child: Text(
                            'No vehicles available.',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : ListView.builder(
                          itemCount: userVehicles.length,
                          itemBuilder: (context, index) {
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
