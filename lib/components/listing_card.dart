import 'package:flutter/material.dart';

class ListingCard extends StatelessWidget {
  final String vehicleMakeModel;
  final String vehicleImageUrl;
  final String vehicleYear;
  final String vehicleMileage;
  final String vehicleTransmission;
  final VoidCallback onTap;

  const ListingCard({
    super.key,
    required this.vehicleMakeModel,
    required this.vehicleImageUrl,
    required this.vehicleYear,
    required this.vehicleMileage,
    required this.vehicleTransmission,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 120, // Fixed height to avoid layout issues
                color: Colors.blue, // Indicator color
              ),
              Container(
                width: 90,
                height: 120, // Fixed height to avoid layout issues
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
                  padding: const EdgeInsets.all(10.0),
                  height: 120, // Fixed height to avoid layout issues
                  color: Colors.black87, // Background color
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        vehicleMakeModel,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Year: $vehicleYear',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Mileage: $vehicleMileage',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Transmission: $vehicleTransmission',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 90,
                height: 120, // Fixed height to avoid layout issues
                color: Colors.green, // Action color
                child: const Center(
                  child: Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
