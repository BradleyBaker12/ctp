import 'package:flutter/material.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/providers/vehicles_provider.dart';

class WishCard extends StatelessWidget {
  final String vehicleMakeModel;
  final String vehicleImageUrl;
  final Size size;
  final TextStyle Function(double, FontWeight, Color) customFont;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool hasOffer; // Add hasOffer parameter
  final String vehicleId;

  const WishCard({
    super.key,
    required this.vehicleMakeModel,
    required this.vehicleImageUrl,
    required this.size,
    required this.customFont,
    required this.onTap,
    required this.onDelete,
    required this.hasOffer, // Include hasOffer in the constructor
    required this.vehicleId,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(vehicleMakeModel),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        onDelete();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 32,
        ),
      ),
      child: GestureDetector(
        onTap: () => navigateToVehicleDetails(context), // Navigate on tap
        child: Card(
          elevation: 5,
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: LayoutBuilder(
              builder: (context, constraints) {
                double imageWidth = constraints.maxWidth * 0.25;
                double cardHeight = 120.0;

                return Row(
                  children: [
                    Container(
                      width: constraints.maxWidth * 0.06,
                      height: cardHeight,
                      color: Colors.blue,
                    ),
                    Container(
                      width: imageWidth,
                      height: cardHeight,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: vehicleImageUrl.isNotEmpty &&
                                  Uri.tryParse(vehicleImageUrl)
                                          ?.hasAbsolutePath ==
                                      true
                              ? NetworkImage(vehicleImageUrl)
                              : const AssetImage(
                                      'lib/assets/default_vehicle_image.png')
                                  as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Colors.blue,
                        padding: const EdgeInsets.all(10.0),
                        height: cardHeight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              vehicleMakeModel.toUpperCase(),
                              style: customFont(
                                15,
                                FontWeight.w800,
                                Colors.white,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _buildOfferStatus(), // Build the offer status widget
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: constraints.maxWidth * 0.24,
                      height: cardHeight,
                      color: hasOffer ? const Color(0xFFFF4E00) : Colors.green,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              hasOffer ? 'Offer Made' : 'Make Offer',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Navigate to VehicleDetailsPage with vehicle information
  void navigateToVehicleDetails(BuildContext context) async {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    Vehicle? vehicle;

    try {
      vehicle = vehicleProvider.vehicles.firstWhere(
        (v) => v.id == vehicleId,
        orElse: () => throw Exception('Vehicle not found in provider'),
      );
    } catch (e) {
      try {
        DocumentSnapshot vehicleSnapshot = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(vehicleId)
            .get();

        if (vehicleSnapshot.exists) {
          vehicle = Vehicle.fromDocument(vehicleSnapshot);
          vehicleProvider.addVehicle(vehicle); // Add to provider
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle details not found.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching vehicle details: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailsPage(vehicle: vehicle!),
      ),
    );
  }

  // Build the offer status widget based on the offer details
  Widget _buildOfferStatus() {
    return Text(
      hasOffer ? 'Offer Status: Offer Made' : '',
      style: customFont(14, FontWeight.bold, Colors.white),
    );
  }
}

// A FutureBuilder implementation that fetches the offer status
FutureBuilder buildWishCard(
    String vehicleId,
    BuildContext context,
    Size size,
    TextStyle Function(double, FontWeight, Color) customFont,
    VoidCallback onDelete) {
  return FutureBuilder<Vehicle?>(
    future: getVehicleFromProvider(
        context, vehicleId), // Fetch vehicle details from provider
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        if (snapshot.hasData && snapshot.data != null) {
          Vehicle vehicle = snapshot.data!;

          return WishCard(
            vehicleMakeModel: vehicle.makeModel, // Use makeModel from vehicle
            vehicleImageUrl:
                vehicle.mainImageUrl ?? '', // Use mainImageUrl from vehicle
            size: size,
            customFont: customFont,
            onTap: () {
              // Define onTap here
            },
            onDelete: onDelete,
            hasOffer: false, // You can modify this to check for offer status
            vehicleId: vehicleId,
          );
        } else {
          return const Center(child: Text('Vehicle not found.'));
        }
      } else {
        return const Center(
            child: CircularProgressIndicator()); // Loading indicator
      }
    },
  );
}

Future<Vehicle?> getVehicleFromProvider(
    BuildContext context, String vehicleId) async {
  final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
  try {
    // Check if vehicle is already in the provider
    Vehicle? vehicle = vehicleProvider.vehicles.firstWhere(
      (v) => v.id == vehicleId,
      orElse: () => throw Exception('Vehicle not found in provider'),
    );
    return vehicle;
  } catch (e) {
    // If not found, try fetching the vehicle from Firebase
    try {
      DocumentSnapshot vehicleSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      if (vehicleSnapshot.exists) {
        Vehicle vehicle = Vehicle.fromDocument(vehicleSnapshot);
        vehicleProvider.addVehicle(vehicle); // Add to provider
        return vehicle;
      }
    } catch (e) {
      print('Error fetching vehicle: $e');
      return null;
    }
  }
  return null;
}

// Example function to fetch offer status
Future<bool> getOfferStatus(String vehicleId) async {
  QuerySnapshot offerSnapshot = await FirebaseFirestore.instance
      .collection('offers')
      .where('vehicleId', isEqualTo: vehicleId)
      .limit(1)
      .get();

  return offerSnapshot.docs.isNotEmpty;
}
