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
  final bool hasOffer;
  final String vehicleId; // Add vehicleId to the constructor

  const WishCard({
    super.key,
    required this.vehicleMakeModel,
    required this.vehicleImageUrl,
    required this.size,
    required this.customFont,
    required this.onTap,
    required this.onDelete,
    required this.hasOffer,
    required this.vehicleId, // Add vehicleId to the constructor
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
                          image: vehicleImageUrl.isNotEmpty
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
                            if (!hasOffer)
                              const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 38,
                              ),
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
      // If the vehicle is not found in the provider, fetch it from Firestore
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
}
