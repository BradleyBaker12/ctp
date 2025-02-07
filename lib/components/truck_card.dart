import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';

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
  Widget _buildSpecBox(BuildContext context, String value, double fontSize) {
    if (value.trim().isEmpty || value.toUpperCase() == 'N/A') {
      return const SizedBox.shrink();
    }

    // Get screen dimensions for dynamic font sizing
    final screenWidth = MediaQuery.of(context).size.width;

    // Adjust font size based on screen size with a reasonable minimum.
    final dynamicFontSize = screenWidth < 600
        ? max(fontSize * 0.9, 12.0)
        : screenWidth < 1200
            ? max(fontSize * 0.7, 10.0)
            : max(fontSize * 0.6, 10.0);

    // Return a Container that wraps the text with padding and decoration.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: AutoSizeText(
        value.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: dynamicFontSize,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        maxLines: 1,
        minFontSize: 10,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
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
      // Basic Vehicle Details
      vehicle.makeModel,
      vehicle.brands,
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
      vehicle.vehicleType,
      vehicle.vehicleAvailableImmediately,
      vehicle.availableDate,
      vehicle.referenceNumber,
      vehicle.requireToSettleType,
      vehicle.country,
      vehicle.province,
      vehicle.variant,
      vehicle.assignedSalesRepId,

      // Descriptions and Features
      vehicle.damageDescription,
      vehicle.damagesDescription,
      vehicle.hydraluicType,
      vehicle.suspensionType,
      vehicle.additionalFeatures,
      vehicle.damagesCondition,
      vehicle.featuresCondition,

      // Images and Documents
      vehicle.mainImageUrl,
      vehicle.photos,
      vehicle.damagePhotos,
      vehicle.dashboardPhoto,
      vehicle.mileageImage,
      vehicle.faultCodesPhoto,
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
      vehicle.additionalImages,

      // Arrays of Data
      vehicle.damages,
      vehicle.features,
      vehicle.application,

      // Admin Data Fields
      vehicle.adminData.settlementAmount,
      vehicle.adminData.natisRc1Url,
      vehicle.adminData.licenseDiskUrl,
      vehicle.adminData.settlementLetterUrl,

      // Maintenance Fields
      vehicle.maintenance.oemInspectionType,
      vehicle.maintenance.oemReason,
      vehicle.maintenance.maintenanceDocUrl,
      vehicle.maintenance.warrantyDocUrl,
      vehicle.maintenance.maintenanceSelection,
      vehicle.maintenance.warrantySelection,

      // Truck Conditions - External Cab
      vehicle.truckConditions.externalCab.condition,
      vehicle.truckConditions.externalCab.damagesCondition,
      vehicle.truckConditions.externalCab.additionalFeaturesCondition,
      vehicle.truckConditions.externalCab.damages,
      vehicle.truckConditions.externalCab.additionalFeatures,
      vehicle.truckConditions.externalCab.images,

      // Truck Conditions - Internal Cab
      vehicle.truckConditions.internalCab.condition,
      vehicle.truckConditions.internalCab.damagesCondition,
      vehicle.truckConditions.internalCab.additionalFeaturesCondition,
      vehicle.truckConditions.internalCab.faultCodesCondition,
      vehicle.truckConditions.internalCab.damages,
      vehicle.truckConditions.internalCab.additionalFeatures,
      vehicle.truckConditions.internalCab.faultCodes,
      vehicle.truckConditions.internalCab.viewImages,

      // Truck Conditions - Chassis
      vehicle.truckConditions.chassis.condition,
      vehicle.truckConditions.chassis.damagesCondition,
      vehicle.truckConditions.chassis.additionalFeaturesCondition,
      vehicle.truckConditions.chassis.damages,
      vehicle.truckConditions.chassis.additionalFeatures,
      vehicle.truckConditions.chassis.images,

      // Truck Conditions - Drive Train
      vehicle.truckConditions.driveTrain.condition,
      vehicle.truckConditions.driveTrain.oilLeakConditionEngine,
      vehicle.truckConditions.driveTrain.waterLeakConditionEngine,
      vehicle.truckConditions.driveTrain.blowbyCondition,
      vehicle.truckConditions.driveTrain.oilLeakConditionGearbox,
      vehicle.truckConditions.driveTrain.retarderCondition,
      vehicle.truckConditions.driveTrain.damages,
      vehicle.truckConditions.driveTrain.additionalFeatures,
      vehicle.truckConditions.driveTrain.faultCodes,
      vehicle.truckConditions.driveTrain.images,

      // Truck Conditions - Tyres (check if positions map is not empty)
      vehicle.truckConditions.tyres['tyres']?.positions.isNotEmpty,
    ];

    final filledFields = fieldsToCheck.where(_isFieldFilled).length;
    final totalFields = fieldsToCheck.length;

    return (filledFields, totalFields);
  }

  @override
  Widget build(BuildContext context) {
    // Fixed height for the card
    const double cardHeight = 600.0;

    // Width based on screen size with a maximum limit
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = min(screenWidth * 0.95, 500.0);

    // Calculate fields ratio for the progress bar
    final (filledFields, totalFields) = _calculateFieldsRatio(vehicle);
    final progressRatio = totalFields > 0 ? filledFields / totalFields : 0.0;

    // BRAND + MODEL + YEAR text.
    final brandModel = [
      vehicle.brands.join(" "),
      vehicle.makeModel,
    ].where((e) => e.isNotEmpty).join(" ");
    final year = vehicle.year.toString();

    // Wrap the entire card in an InkWell so that tapping anywhere (except on interactive widgets)
    // navigates to the vehicle details page.
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleDetailsPage(vehicle: vehicle),
          ),
        );
      },
      child: Center(
        child: Container(
          width: cardWidth,
          height: cardHeight,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2F7FFF).withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: borderColor ?? const Color(0xFF2F7FFF),
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

              // Define sections of the card based on its height.
              final imageSectionHeight = cardH * 0.6;
              final contentSectionHeight = cardH * 0.4;

              // Adjust font sizes and padding based on card width.
              final titleFontSize = max(cardW * 0.045, 14.0);
              final subtitleFontSize = max(cardW * 0.042, 12.0);
              final paddingVal = max(cardW * 0.04, 8.0);
              final specFontSize = max(cardW * 0.032, 14.0);
              final progressText = max(cardW * 0.024, 8.0);

              // Button height ~8% of card height.
              final double buttonHeight = cardH * 0.08;

              // Vertical spacing between sections.
              final verticalSpacing = cardH * 0.02;

              // Spacing between spec boxes.
              final responsiveSpacing =
                  screenWidth < 400 ? 4.0 : paddingVal * 0.2;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top section: Image with a like button.
                  SizedBox(
                    height: imageSectionHeight,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
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

                  // Bottom section: Details, specs, progress bar.
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: 10, right: 10, top: 5, bottom: 5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: verticalSpacing),
                          // Brand, Model, and Year text.
                          Text(
                            brandModel.isEmpty
                                ? 'LOADING...'
                                : brandModel.toUpperCase(),
                            style: GoogleFonts.montserrat(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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

                          // Specs row: Each spec box now sizes itself based on its content.
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _buildSpecBox(
                                  context,
                                  '${vehicle.mileage ?? "N/A"} km',
                                  specFontSize),
                              SizedBox(width: responsiveSpacing),
                              _buildSpecBox(
                                  context,
                                  vehicle.transmissionType ?? 'N/A',
                                  specFontSize),
                              SizedBox(width: responsiveSpacing),
                              _buildSpecBox(context, vehicle.config ?? 'N/A',
                                  specFontSize),
                            ],
                          ),
                          SizedBox(height: 18),

                          // Progress bar.
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
                                  contentSectionHeight * 0.02),
                              child: Stack(
                                children: [
                                  // Background
                                  Container(
                                    color: const Color(0xFF2F7FFF)
                                        .withOpacity(0.2),
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
                                        color: const Color(0xFF0d1d4a),
                                        borderRadius:
                                            BorderRadius.circular(100),
                                      ),
                                    ),
                                  ),
                                  // Green fill representing progress
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
                          SizedBox(height: 18),

                          // Optionally, you can keep the "VIEW MORE DETAILS" button if desired.
                          // If you want the entire card to be clickable, this button could be removed.
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
                                minimumSize:
                                    Size(double.infinity, buttonHeight),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(paddingVal * 0.5),
                                ),
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
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
