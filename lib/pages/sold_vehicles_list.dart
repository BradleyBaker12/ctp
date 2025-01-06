// lib/pages/sold_vehicles_list.dart

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

class SoldVehiclesListPage extends StatefulWidget {
  const SoldVehiclesListPage({super.key});

  @override
  _SoldVehiclesListPageState createState() => _SoldVehiclesListPageState();
}

class _SoldVehiclesListPageState extends State<SoldVehiclesListPage> {
  final int _selectedIndex = 1;
  final ScrollController _scrollController = ScrollController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
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
    final soldVehicles = userVehicles
        .where((vehicle) => vehicle.vehicleStatus == 'Sold')
        .toList();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(),
        body: Column(
          children: [
            if (isLoading) const Center(child: CircularProgressIndicator()),
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
                  'SOLD VEHICLES',
                  style: TextStyle(
                    color: Color(0xFFFF4E00),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: soldVehicles.isEmpty
                  ? Center(
                      child: Text(
                        'No Sold Vehicles Found',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: soldVehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = soldVehicles[index];

                        return ListingCard(
                          vehicleId: vehicle.id,
                          vehicleType:
                              vehicle.vehicleType, // "truck" or "trailer"
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
                          vehicleImageUrl: vehicle.mainImageUrl,
                          referenceNumber: vehicle.referenceNumber,
                          vehicleTransmission: vehicle.transmissionType,
                          vehicleMileage: vehicle.mileage,

                          // If trailer => pass trailer fields
                          trailerType: vehicle.trailerType,
                          trailerMake: vehicle.brands.isNotEmpty
                              ? vehicle.brands[0]
                              : '', // <--- was "vehicle.make"
                          trailerYear: vehicle.year,

                          // If truck => pass truck fields
                          truckBrand: vehicle.brands.isNotEmpty
                              ? vehicle.brands[0]
                              : '',
                          truckModel: vehicle.makeModel,
                        );
                      },
                    ),
            ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavigation(
          selectedIndex: _selectedIndex,
          onItemTapped: (index) {
            // same nav logic
          },
        ),
      ),
    );
  }
}
