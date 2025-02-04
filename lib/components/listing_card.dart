import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/vehicle.dart';

class ListingCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;

  const ListingCard({
    super.key,
    required this.vehicle,
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

  /// Calculates the ratio of filled fields vs total fields
  (int filled, int total) _calculateFieldsRatio() {
    // Use the same fields as in TruckCard
    final fieldsToCheck = [
      vehicle.makeModel,
      vehicle.brands.isNotEmpty ? vehicle.brands.join() : null,
      vehicle.year,
      vehicle.mileage,
      vehicle.transmissionType,
      vehicle.config,
      vehicle.engineNumber,
      vehicle.registrationNumber,
      vehicle.vinNumber,
      vehicle.warrentyType,
      vehicle.warrantyDetails,
      vehicle.damageDescription,
      vehicle.hydraluicType,
      vehicle.suspensionType,
      vehicle.expectedSellingPrice,
      vehicle.mainImageUrl,
      vehicle.natisDocumentUrl,
      vehicle.serviceHistoryUrl,
      vehicle.frontImageUrl,
      vehicle.sideImageUrl,
      vehicle.tyresImageUrl,
      vehicle.chassisImageUrl,
      vehicle.licenceDiskUrl,
      vehicle.rc1NatisFile,
      // Maintenance related fields
      vehicle.maintenance.maintenanceDocUrl,
      vehicle.maintenance.warrantyDocUrl,
      vehicle.maintenance.maintenanceSelection,
      vehicle.maintenance.warrantySelection,
      // Admin related fields
      vehicle.adminData.natisRc1Url,
      vehicle.adminData.licenseDiskUrl,
      // Location related
      vehicle.country,
      vehicle.province,
      // Additional fields
      vehicle.damagesDescription,
      vehicle.additionalFeatures,
    ];

    int filledFields = fieldsToCheck
        .where((field) =>
            field != null &&
            field.toString().isNotEmpty &&
            field.toString().toUpperCase() != 'N/A')
        .length;

    return (filledFields, fieldsToCheck.length);
  }

  @override
  Widget build(BuildContext context) {
    const double fixedWidth = 400;
    const double fixedHeight = 520; // Increased from 500 to 520

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
                  // Reduce image height slightly
                  SizedBox(
                    height: cardH * 0.5, // Reduced from 0.55 to 0.5
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(10)),
                      child: Image(
                        image: (vehicle.mainImageUrl != null &&
                                vehicle.mainImageUrl!.isNotEmpty)
                            ? NetworkImage(vehicle.mainImageUrl!)
                            : const AssetImage(
                                    "lib/assets/default_vehicle_image.png")
                                as ImageProvider,
                        width: cardW,
                        height: cardH * 0.55,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Reduce padding for details section
                  Padding(
                    padding: EdgeInsets.all(
                        paddingVal * 0.8), // Reduced from 1.0 to 0.8
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
                                vehicle.vehicleType.toLowerCase() == 'trailer'
                                    ? '${vehicle.trailerType}'.toUpperCase()
                                    : '${vehicle.brands.join(" ")} ${vehicle.makeModel}'
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
                                vehicle.vehicleType.toLowerCase() == 'trailer'
                                    ? vehicle.year
                                    : vehicle.referenceNumber,
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
                                    vehicle.mileage != null
                                        ? '${vehicle.mileage} km'
                                        : 'N/A',
                                    specFontSize)),
                            SizedBox(width: paddingVal * 0.3),
                            Expanded(
                                child: _buildSpecBox(
                                    vehicle.transmissionType ?? 'N/A',
                                    specFontSize)),
                            SizedBox(width: paddingVal * 0.3),
                            Expanded(
                                child: _buildSpecBox(
                                    vehicle.vehicleType.toLowerCase() ==
                                            'trailer'
                                        ? vehicle.trailerType ?? 'N/A'
                                        : 'N/A',
                                    specFontSize)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Progress bar with optimized padding
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: paddingVal,
                      vertical: paddingVal * 0.3, // Reduced vertical padding
                    ),
                    child: Stack(
                      children: [
                        Container(
                          height: cardH * 0.045,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(cardH * 0.025),
                            border: Border.all(
                              color: const Color(0xFF2F7FFF),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(cardH * 0.025),
                            child: Stack(
                              children: [
                                Container(
                                  color: const Color(0xFF2F7FFF),
                                ),
                                Positioned(
                                  left: 0,
                                  right: paddingVal * 2.5,
                                  top: 0,
                                  bottom: 0,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: cardH * 0.01),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius:
                                            BorderRadius.circular(100),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: cardH * 0.01),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: FractionallySizedBox(
                                      widthFactor: _calculateFieldsRatio().$1 /
                                          _calculateFieldsRatio().$2,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF4CAF50),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          right: 5,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Text(
                              '${_calculateFieldsRatio().$1}/${_calculateFieldsRatio().$2}',
                              style: GoogleFonts.montserrat(
                                fontSize: specFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Button with adjusted padding
                  Padding(
                    padding: EdgeInsets.only(
                        bottom: paddingVal * 0.8, // Reduced bottom padding
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
