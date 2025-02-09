import 'package:ctp/models/vehicle.dart';
import 'package:ctp/utils/cached_image.dart';
import 'package:flutter/material.dart';
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
  final bool hasOffer;
  final String vehicleId;
  final Vehicle vehicle; // Add Vehicle model

  const WishCard({
    super.key,
    required this.vehicleMakeModel,
    required this.vehicleImageUrl,
    required this.size,
    required this.customFont,
    required this.onTap,
    required this.onDelete,
    required this.hasOffer,
    required this.vehicleId,
    required this.vehicle, // Add to constructor
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(vehicleId),
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
        onTap: onTap,
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
                    SizedBox(
                      width: imageWidth,
                      height: cardHeight,
                      child: vehicle.mainImageUrl != null &&
                              vehicle.mainImageUrl!.isNotEmpty
                          ? cachedImage(vehicle.mainImageUrl!)
                          : Image.asset('lib/assets/default_vehicle_image.png'),
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
                              '${vehicle.brands.join("")} ${vehicle.makeModel} ${vehicle.year}',
                              style:
                                  customFont(15, FontWeight.w800, Colors.white),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
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
            vehicleId: vehicleId, vehicle: vehicle,
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
    Vehicle vehicle = vehicleProvider.vehicles.firstWhere(
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

      if (vehicleSnapshot.exists && vehicleSnapshot.data() != null) {
        Vehicle vehicle = Vehicle.fromFirestore(
          vehicleSnapshot.id,
          vehicleSnapshot.data() as Map<String, dynamic>,
        );
        vehicleProvider.addVehicle(vehicle); // Add to provider
        return vehicle;
      } else {
        print('Vehicle data is null for ID $vehicleId');
        return null;
      }
    } catch (e) {
      print('Error fetching vehicle: $e');
      return null;
    }
  }
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
