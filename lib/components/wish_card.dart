import 'package:flutter/material.dart';

class WishCard extends StatelessWidget {
  final String vehicleMakeModel;
  final String vehicleImageUrl;
  final Size size;
  final TextStyle Function(double, FontWeight, Color) customFont;
  final VoidCallback onTap; // Add this line

  const WishCard({
    super.key,
    required this.vehicleMakeModel,
    required this.vehicleImageUrl,
    required this.size,
    required this.customFont,
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
                height: 120, // Set a fixed height to avoid infinite height issue
                color: Colors.blue, // Set a color to indicate the wishlist item
              ),
              Container(
                width: 90,
                height: 120, // Set a fixed height to avoid infinite height issue
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: vehicleImageUrl.isNotEmpty
                        ? NetworkImage(vehicleImageUrl)
                        : const AssetImage('lib/assets/default_vehicle_image.png')
                            as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  height:
                      120, // Set a fixed height to avoid infinite height issue
                  color: Colors.blue, // Set background color to blue
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        vehicleMakeModel,
                        style: customFont(
                            18, FontWeight.bold, Colors.white), // White text
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
              ),
              Container(
                width: 90,
                height: 120, // Set a fixed height to avoid infinite height issue
                color: Colors.green,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Make Offer',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
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
