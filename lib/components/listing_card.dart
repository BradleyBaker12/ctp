import 'package:flutter/material.dart';

class ListingCard extends StatelessWidget {
  final String vehicleMakeModel;
  final String? vehicleImageUrl; // Now nullable
  final String vehicleYear;
  final String vehicleMileage;
  final String vehicleTransmission;
  final VoidCallback onTap;

  const ListingCard({
    Key? key,
    required this.vehicleMakeModel,
    required this.vehicleImageUrl,
    required this.vehicleYear,
    required this.vehicleMileage,
    required this.vehicleTransmission,
    required this.onTap,
  }) : super(key: key);

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              double imageWidth = constraints.maxWidth * 0.25;
              double cardHeight = 130.0;

              return Row(
                children: [
                  Container(
                    width: constraints.maxWidth * 0.06,
                    height: cardHeight,
                    color: Colors.blue, // Indicator color
                  ),
                  Container(
                    width: imageWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: (vehicleImageUrl != null &&
                                vehicleImageUrl!.isNotEmpty &&
                                Uri.tryParse(vehicleImageUrl!)
                                        ?.hasAbsolutePath ==
                                    true)
                            ? NetworkImage(vehicleImageUrl!)
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
                      height: cardHeight,
                      color: Colors.blue,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            vehicleMakeModel.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
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
                    width: constraints.maxWidth * 0.24,
                    height: cardHeight,
                    color: Colors.green,
                    child: const Center(
                      child: Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
