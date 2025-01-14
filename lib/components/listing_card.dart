import 'package:flutter/material.dart';

class ListingCard extends StatelessWidget {
  final String vehicleId;
  final String vehicleType; // "truck" or "trailer"

  // For trailers: trailerType, make, year
  final String? trailerType;
  final String? trailerMake;
  final String? trailerYear;

  // For trucks: brand, model
  final String? truckBrand;
  final String? truckModel;

  // Common fields (only if you still need them)
  final String? referenceNumber;
  final String? vehicleMileage;
  final String? vehicleTransmission;
  final String? vehicleImageUrl;
  final VoidCallback onTap;

  const ListingCard({
    super.key,
    required this.vehicleId,
    required this.vehicleType,
    this.trailerType,
    this.trailerMake,
    this.trailerYear,
    this.truckBrand,
    this.truckModel,
    this.referenceNumber,
    this.vehicleMileage,
    this.vehicleTransmission,
    this.vehicleImageUrl,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              double imageWidth = constraints.maxWidth * 0.25;
              double cardHeight = 130.0;

              return Row(
                children: [
                  // Left color strip
                  Container(
                    width: constraints.maxWidth * 0.06,
                    height: cardHeight,
                    color: Colors.blue,
                  ),

                  // Vehicle image
                  Container(
                    width: imageWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: (vehicleImageUrl != null &&
                                vehicleImageUrl!.isNotEmpty)
                            ? NetworkImage(vehicleImageUrl!)
                            : const AssetImage(
                                    "lib/assets/default_vehicle_image.png")
                                as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Middle info section
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10.0),
                      height: cardHeight,
                      color: Colors.blue,
                      child: _buildInfo(context),
                    ),
                  ),

                  // Right color strip / arrow
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

  Widget _buildInfo(BuildContext context) {
    // If trailer => show trailer type, make, year
    // If truck => show brand + model
    if (vehicleType.toLowerCase() == 'trailer') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // e.g. "SIDE TIPPER" or "FLAT DECK" (whatever trailerType is)
          Text(
            (trailerType ?? '').toUpperCase(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 5),

          // Trailer Make (e.g. "AFRIT")
          if (trailerMake != null && trailerMake!.isNotEmpty)
            Text(
              'Make: $trailerMake',
              style: const TextStyle(color: Colors.white70),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          // Year
          if (trailerYear != null && trailerYear!.isNotEmpty)
            Text(
              'Year: $trailerYear',
              style: const TextStyle(color: Colors.white70),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
        ],
      );
    } else {
      // truck => brand + model
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // e.g. "SCANIA G460"
          Text(
            '${(truckBrand ?? '').toUpperCase()} '
                    '${(truckModel ?? '').toUpperCase()}'
                .trim(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 5),

          // If you still want to show more fields for truck:
          if (referenceNumber != null && referenceNumber!.isNotEmpty)
            Text(
              'Ref#: $referenceNumber',
              style: const TextStyle(color: Colors.white70),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          if (vehicleMileage != null && vehicleMileage!.isNotEmpty)
            Text(
              'Mileage: $vehicleMileage',
              style: const TextStyle(color: Colors.white70),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          if (vehicleTransmission != null && vehicleTransmission!.isNotEmpty)
            Text(
              'Transmission: $vehicleTransmission',
              style: const TextStyle(color: Colors.white70),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
        ],
      );
    }
  }
}
