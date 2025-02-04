import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  Widget _buildSpecBox(String value, double fontSize) {
    if (value.trim().isEmpty || value.toUpperCase() == 'N/A') {
      return const SizedBox.shrink();
    }
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: fontSize * 0.5, vertical: fontSize * 0.5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(fontSize * 0.4),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double fixedWidth = 400;
    const double fixedHeight = 500;

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: fixedWidth,
          height: fixedHeight,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2F7FFF).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF2F7FFF),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              double cardW = constraints.maxWidth;
              double cardH = constraints.maxHeight;
              double titleFontSize = cardW * 0.045;
              double subtitleFontSize = cardW * 0.04;
              double paddingVal = cardW * 0.04;
              double specFontSize = cardW * 0.03;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: cardH * 0.55,
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(10)),
                      child: Image(
                        image: (vehicleImageUrl != null &&
                                vehicleImageUrl!.isNotEmpty)
                            ? NetworkImage(vehicleImageUrl!)
                            : const AssetImage(
                                    "lib/assets/default_vehicle_image.png")
                                as ImageProvider,
                        width: cardW,
                        height: cardH * 0.55,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(paddingVal),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                vehicleType.toLowerCase() == 'trailer'
                                    ? '${trailerType ?? ''}'.toUpperCase()
                                    : '${truckBrand ?? ''} ${truckModel ?? ''}'
                                        .toUpperCase(),
                                style: GoogleFonts.montserrat(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                              ),
                            ),
                            SizedBox(height: paddingVal * 0.25),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                vehicleType.toLowerCase() == 'trailer'
                                    ? trailerYear ?? ''
                                    : referenceNumber ?? '',
                                style: GoogleFonts.montserrat(
                                  fontSize: subtitleFontSize,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: paddingVal),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                                child: _buildSpecBox(
                                    vehicleMileage != null
                                        ? '$vehicleMileage km'
                                        : 'N/A',
                                    specFontSize)),
                            SizedBox(width: paddingVal * 0.3),
                            Expanded(
                                child: _buildSpecBox(
                                    vehicleTransmission ?? 'N/A',
                                    specFontSize)),
                            SizedBox(width: paddingVal * 0.3),
                            Expanded(
                                child: _buildSpecBox(
                                    vehicleType.toLowerCase() == 'trailer'
                                        ? trailerMake ?? 'N/A'
                                        : 'N/A',
                                    specFontSize)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: paddingVal,
                        left: paddingVal,
                        right: paddingVal),
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F7FFF),
                        padding:
                            EdgeInsets.symmetric(vertical: paddingVal * 0.75),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(paddingVal * 0.5),
                        ),
                      ),
                      child: Text(
                        'VIEW MORE DETAILS',
                        style: GoogleFonts.montserrat(
                          fontSize: specFontSize + 2,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
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
