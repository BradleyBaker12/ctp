// lib/components/truck_card.dart

import 'dart:math'; // <-- Needed for min(...)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/vehicle.dart';
import '../pages/vehicle_details_page.dart';
import '../providers/user_provider.dart';

class TruckCard extends StatelessWidget {
  final Vehicle vehicle;

  /// Callback when the heart (like) button is pressed.
  final Function(Vehicle) onInterested;

  /// Optional parameter for customizing border color.
  final Color? borderColor;

  const TruckCard({
    super.key,
    required this.vehicle,
    required this.onInterested,
    this.borderColor,
  });

  /// Builds one of the small spec boxes (e.g., mileage, transmission, config).
  Widget _buildSpecBox(String value, double fontSize) {
    if (value.trim().isEmpty || value.toUpperCase() == 'N/A') {
      return const SizedBox.shrink();
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.8,
        vertical: fontSize * 0.5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(fontSize * 0.4),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        value.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: fontSize,
          fontWeight: FontWeight.w300,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Helper to determine if a single field is considered "filled".
  bool _isFieldFilled(dynamic value) {
    if (value == null) return false;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isNotEmpty && trimmed.toUpperCase() != 'N/A';
    }
    if (value is List) {
      return value.isNotEmpty;
    }
    return true;
  }

  /// Calculates how many fields are filled vs total, based on Vehicle fields.
  (int filled, int total) _calculateFieldsRatio(Vehicle vehicle) {
    final fieldsToCheck = [
      // Basic details
      vehicle.makeModel,
      vehicle.brands, // List<String>
      vehicle.year,
      vehicle.mileage,
      vehicle.transmissionType,
      vehicle.config,
      vehicle.engineNumber,
      vehicle.registrationNumber,
      vehicle.vinNumber,
      vehicle.warrentyType,
      vehicle.warrantyDetails,
      vehicle.expectedSellingPrice,

      // Descriptions
      vehicle.damageDescription,
      vehicle.damagesDescription,
      vehicle.hydraluicType,
      vehicle.suspensionType,

      // Images/Docs
      vehicle.mainImageUrl,
      vehicle.natisDocumentUrl,
      vehicle.serviceHistoryUrl,
      vehicle.frontImageUrl,
      vehicle.sideImageUrl,
      vehicle.tyresImageUrl,
      vehicle.chassisImageUrl,
      vehicle.deckImageUrl,
      vehicle.makersPlateImageUrl,
      vehicle.licenceDiskUrl,
      vehicle.rc1NatisFile,
      vehicle.additionalImages, // List<String>?

      // Maintenance
      vehicle.maintenance.maintenanceDocUrl,
      vehicle.maintenance.warrantyDocUrl,
      vehicle.maintenance.maintenanceSelection,
      vehicle.maintenance.warrantySelection,

      // Admin data
      vehicle.adminData.natisRc1Url,
      vehicle.adminData.licenseDiskUrl,

      // Location
      vehicle.country,
      vehicle.province,

      // Additional features/conditions
      vehicle.additionalFeatures,
      vehicle.damagesCondition,
      vehicle.featuresCondition,
      vehicle.damages, // List<Map<String, dynamic>>?
      vehicle.features, // List<Map<String, dynamic>>?
    ];

    final filledFields = fieldsToCheck.where(_isFieldFilled).length;
    final totalFields = fieldsToCheck.length;

    return (filledFields, totalFields);
  }

  @override
  Widget build(BuildContext context) {
    // --- 1) Enforce your chosen ratio: (5 : 13) ---
    const double ratioWidth = 5;
    const double ratioHeight = 13;

    // Hard limits
    const double maxWidth = 500;
    const double maxHeight = 1300;

    // Percentage of screen usage
    const double screenFractionWidth = 0.95;
    const double screenFractionHeight = 0.90;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // We'll find the largest scale 's' so:
    //   5*s <= 500, 13*s <= 1300
    //   5*s <= screenWidth * 0.95
    //   13*s <= screenHeight * 0.90
    final sForMaxWidth = maxWidth / ratioWidth;
    final sForMaxHeight = maxHeight / ratioHeight;
    final sForScreenWidth = (screenWidth * screenFractionWidth) / ratioWidth;
    final sForScreenHeight =
        (screenHeight * screenFractionHeight) / ratioHeight;

    final scale = min(
      sForMaxWidth,
      min(sForMaxHeight, min(sForScreenWidth, sForScreenHeight)),
    );

    final cardWidth = ratioWidth * scale;
    final cardHeight = ratioHeight * scale;

    // --- 2) Data completeness (progress bar) ---
    final (filledFields, totalFields) = _calculateFieldsRatio(vehicle);
    final progressRatio =
        (totalFields == 0) ? 0 : filledFields / totalFields.toDouble();

    // --- 3) Decide final border color ---
    final Color effectiveBorderColor = borderColor ?? const Color(0xFF2F7FFF);

    // --- 4) Build the UI, ensuring order: Specs -> ProgressBar -> Button at bottom
    return Center(
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2F7FFF).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: effectiveBorderColor,
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
            final cardW = constraints.maxWidth;
            final cardH = constraints.maxHeight;

            // Let's make the top ~60% for the image, bottom ~40% for specs & button
            final imageSectionHeight = cardH * 0.6;
            final contentSectionHeight = cardH - imageSectionHeight;

            // Font sizes based on card width
            final titleFontSize = cardW * 0.045;
            final subtitleFontSize = cardW * 0.042;
            final paddingVal = cardW * 0.04;
            final specFontSize = cardW * 0.032;
            final progressText = cardW * 0.024;

            // For button thickness, ~8% of card height
            final double buttonHeight = cardH * 0.08;

            // Brand + Model + Year
            final brandModel = [
              vehicle.brands.join(" "),
              vehicle.makeModel,
            ].where((e) => e.isNotEmpty).join(" ");
            final year = vehicle.year.toString();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ========== TOP SECTION: IMAGE ==========
                SizedBox(
                  height: imageSectionHeight,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                        child: Image.network(
                          vehicle.mainImageUrl ?? '',
                          width: cardW,
                          height: imageSectionHeight,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                            'lib/assets/default_vehicle_image.png',
                            width: cardW,
                            height: imageSectionHeight,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Heart (like) button in top-right
                      Positioned(
                        top: paddingVal * 0.75,
                        right: paddingVal * 0.75,
                        child: Consumer<UserProvider>(
                          builder: (context, userProvider, child) {
                            bool isLiked = userProvider.getLikedVehicles
                                .contains(vehicle.id);
                            return IconButton(
                              icon: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.white,
                                size: titleFontSize + 10,
                              ),
                              onPressed: () => onInterested(vehicle),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // ========== BOTTOM SECTION: SPECS + PROGRESS + BUTTON ==========
                SizedBox(
                  height: contentSectionHeight,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: paddingVal * 0.8,
                      vertical: paddingVal * 0.8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // BRAND MODEL / YEAR
                        SizedBox(height: 18),
                        Text(
                          brandModel.isEmpty
                              ? 'LOADING...'
                              : brandModel.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          year,
                          style: GoogleFonts.montserrat(
                            fontSize: subtitleFontSize,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 18),

                        // SPECS ROW
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: _buildSpecBox(
                                '${vehicle.mileage ?? "N/A"} km',
                                specFontSize,
                              ),
                            ),
                            SizedBox(width: paddingVal * 0.5),
                            Flexible(
                              child: _buildSpecBox(
                                vehicle.transmissionType ?? 'N/A',
                                specFontSize,
                              ),
                            ),
                            SizedBox(width: paddingVal * 0.5),
                            Flexible(
                              child: _buildSpecBox(
                                vehicle.config ?? 'N/A',
                                specFontSize,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 18),

                        // PROGRESS BAR
                        Container(
                          height: contentSectionHeight * 0.07,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: const Color(0xFF2F7FFF),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                                contentSectionHeight * 0.03),
                            child: Stack(
                              children: [
                                // Background
                                Container(
                                  color:
                                      const Color(0xFF2F7FFF).withOpacity(0.2),
                                ),
                                // Gray bar
                                Positioned(
                                  left: paddingVal * 0.7,
                                  right: paddingVal * 2.8,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                      vertical: contentSectionHeight * 0.01,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                  ),
                                ),
                                // Green fill
                                Positioned(
                                  left: paddingVal * 0.7,
                                  right: paddingVal * 2.8,
                                  top: 0,
                                  bottom: 0,
                                  child: FractionallySizedBox(
                                    widthFactor: progressRatio.toDouble(),
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      margin: EdgeInsets.symmetric(
                                        vertical: contentSectionHeight * 0.01,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4CAF50),
                                        borderRadius:
                                            BorderRadius.circular(100),
                                      ),
                                    ),
                                  ),
                                ),
                                // Progress text
                                Positioned(
                                  right: 5,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: Text(
                                      '$filledFields/$totalFields',
                                      style: GoogleFonts.montserrat(
                                        fontSize: progressText,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // This spacer pushes the button to the bottom of the card
                        SizedBox(height: 18),

                        // VIEW MORE DETAILS BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      VehicleDetailsPage(vehicle: vehicle),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2F7FFF),
                              minimumSize: Size(double.infinity, buttonHeight),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  paddingVal * 0.5,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                'VIEW MORE DETAILS',
                                style: GoogleFonts.montserrat(
                                  fontSize: specFontSize + 3,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
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
    );
  }
}
