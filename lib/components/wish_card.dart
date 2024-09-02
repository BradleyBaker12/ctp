import 'package:flutter/material.dart';

class WishCard extends StatelessWidget {
  final String vehicleMakeModel;
  final String vehicleImageUrl;
  final Size size;
  final TextStyle Function(double, FontWeight, Color) customFont;
  final VoidCallback onTap;
  final bool hasOffer;

  const WishCard({
    super.key,
    required this.vehicleMakeModel,
    required this.vehicleImageUrl,
    required this.size,
    required this.customFont,
    required this.onTap,
    required this.hasOffer,
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
    );
  }
}
