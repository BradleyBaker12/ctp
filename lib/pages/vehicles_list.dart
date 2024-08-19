import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/listing_card.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_bottom_navigation.dart'; // Import the custom bottom navigation
import 'package:ctp/pages/vehicle_details_page.dart'; // Import the VehicleDetailsPage

class VehiclesListPage extends StatefulWidget {
  const VehiclesListPage({super.key});

  @override
  _VehiclesListPageState createState() => _VehiclesListPageState();
}

class _VehiclesListPageState extends State<VehiclesListPage> {
  int _selectedIndex =
      1; // Set the default selected index for the bottom navigation

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = Provider.of<VehicleProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    // Fetch the current user's ID from the UserProvider
    final currentUserId = userProvider.userId;

    // Filter vehicles by userId
    final userVehicles = vehicleProvider.vehicles.where((vehicle) {
      return vehicle.userId == currentUserId;
    }).toList();

    return Scaffold(
      appBar: const BlurryAppBar(),
      body: GradientBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Image(
                  image: AssetImage(
                      'lib/assets/CTPLogo.png'), // Add your logo path here
                  height: 100, // Adjust the height of the logo as needed
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  'Vehicle Listing',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Expanded(
              child: userVehicles.isEmpty
                  ? const Center(child: Text('No vehicles available.'))
                  : ListView.builder(
                      itemCount: userVehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = userVehicles[index];
                        return ListingCard(
                          vehicleMakeModel: vehicle.makeModel,
                          vehicleImageUrl: vehicle.mainImageUrl ?? '',
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
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
