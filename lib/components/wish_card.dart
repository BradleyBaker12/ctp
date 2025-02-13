// lib/components/wish_card.dart

import 'dart:math';
import 'package:ctp/models/vehicle.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class WishCard extends StatelessWidget {
  final String vehicleMakeModel;
  final String vehicleImageUrl;
  final Size size; // preserved for future use
  final TextStyle Function(double, FontWeight, Color)
      customFont; // preserved for future use
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool hasOffer; // preserved for future use
  final String vehicleId;
  final Vehicle vehicle; // the vehicle model

  const WishCard({
    super.key,
    required this.vehicleMakeModel,
    required this.vehicleImageUrl,
    required this.size,
    required this.customFont,
    required this.onTap,
    required this.onDelete,
    required this.hasOffer,
    required this.vehicleId,
    required this.vehicle,
  });

  /// Builds a spec box (for mileage, transmission, config) matching TruckCard styling.
  Widget _buildSpecBox(BuildContext context, String value, double fontSize) {
    if (value.trim().isEmpty || value.toUpperCase() == 'N/A') {
      return const SizedBox.shrink();
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final dynamicFontSize = screenWidth < 600
        ? max(fontSize * 0.9, 12.0)
        : screenWidth < 1200
            ? max(fontSize * 0.7, 10.0)
            : max(fontSize * 0.6, 10.0);

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

  /// Helper to check if a field is considered “filled.”
  bool _isFieldFilled(dynamic value) {
    if (value == null) return false;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isNotEmpty && trimmed.toUpperCase() != 'N/A';
    }
    if (value is List) return value.isNotEmpty;
    return true;
  }

  /// Calculates the progress based on a list of 41 fields (from the original WishCard code).
  (int filled, int total) _calculateFieldsRatio(Vehicle vehicle) {
    final List<dynamic> fields = [
      vehicle.mileage, // 1.
      vehicle.transmissionType, // 2.
      vehicle.config, // 3.
      vehicle.damageDescription, // 4.
      vehicle.damagePhotos, // 5.
      vehicle.dashboardPhoto, // 6.
      vehicle.engineNumber, // 7.
      vehicle.expectedSellingPrice, // 8.
      vehicle.faultCodesPhoto, // 9.
      vehicle.hydraluicType, // 10.
      vehicle.licenceDiskUrl, // 11.
      vehicle.mileageImage, // 12.
      vehicle.mainImageUrl, // 13.
      vehicle.photos, // 14.
      vehicle.rc1NatisFile, // 15.
      vehicle.registrationNumber, // 16.
      vehicle.suspensionType, // 17.
      vehicle.vehicleType, // 18.
      vehicle.vinNumber, // 19.
      vehicle.warrentyType, // 20.
      vehicle.warrantyDetails, // 21.
      vehicle.availableDate, // 22.
      vehicle.trailerType, // 23.
      vehicle.axles, // 24.
      vehicle.trailerLength, // 25.
      vehicle.natisRc1Url, // 26.
      vehicle.referenceNumber, // 27.
      vehicle.length, // 28.
      vehicle.vinTrailer, // 29.
      vehicle.damagesDescription, // 30.
      vehicle.additionalFeatures, // 31.
      vehicle.requireToSettleType, // 32.
      vehicle.country, // 33.
      vehicle.province, // 34.
      vehicle.variant, // 35.
      vehicle.natisDocumentUrl, // 36.
      vehicle.serviceHistoryUrl, // 37.
      vehicle.frontImageUrl, // 38.
      vehicle.sideImageUrl, // 39.
      vehicle.tyresImageUrl, // 40.
      vehicle.chassisImageUrl, // 41.
    ];

    final filledFields = fields.where(_isFieldFilled).length;
    final totalFields = fields.length;
    return (filledFields, totalFields);
  }

  @override
  Widget build(BuildContext context) {
    // Use dynamic sizing like TruckCard: width based on MediaQuery and fixed height.
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = min(screenWidth * 0.95, 500.0);
    const double cardHeight = 600.0;

    // Calculate progress based on 41 fields.
    final (filledFields, totalFields) = _calculateFieldsRatio(vehicle);
    final progressRatio = totalFields > 0 ? filledFields / totalFields : 0.0;

    // Determine display title: show brand, variant and year
    final String displayTitle = [
      vehicle.brands.isNotEmpty ? vehicle.brands.join(" ") : 'NO BRAND',
      vehicle.variant ?? '',
    ].where((e) => e.isNotEmpty).join(" ").toUpperCase();

    // Year string.
    final String year = vehicle.year.toString();

    // Determine image URL: use provided vehicleImageUrl if available, else fallback.
    final String imageUrl = vehicleImageUrl.isNotEmpty
        ? vehicleImageUrl
        : (vehicle.mainImageUrl ?? '');

    return Dismissible(
      key: Key(vehicleId),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: Stack(
            children: [
              Container(
                width: cardWidth,
                height: cardHeight,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F7FFF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
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
                    final cardW = constraints.maxWidth;
                    final cardH = constraints.maxHeight;
                    // Define sections: image (60%) and details (40%).
                    final imageSectionHeight = cardH * 0.6;
                    final contentSectionHeight = cardH * 0.4;

                    // Dynamic sizing values.
                    final titleFontSize = max(cardW * 0.045, 14.0);
                    final subtitleFontSize = max(cardW * 0.042, 12.0);
                    final paddingVal = max(cardW * 0.04, 8.0);
                    final specFontSize = max(cardW * 0.032, 14.0);
                    final progressText = max(cardW * 0.024, 8.0);
                    final buttonHeight = cardH * 0.08;
                    final verticalSpacing = cardH * 0.02;
                    final responsiveSpacing =
                        screenWidth < 400 ? 4.0 : paddingVal * 0.2;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top image section.
                        SizedBox(
                          height: imageSectionHeight,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            child: Image.network(
                              imageUrl,
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
                        ),
                        // Bottom details section.
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(paddingVal),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: verticalSpacing),
                                // Title: Vehicle make/model.
                                Text(
                                  displayTitle.isEmpty
                                      ? 'LOADING...'
                                      : displayTitle,
                                  style: GoogleFonts.montserrat(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // Year text.
                                Text(
                                  year,
                                  style: GoogleFonts.montserrat(
                                    fontSize: subtitleFontSize,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white70,
                                  ),
                                ),
                                SizedBox(height: verticalSpacing * 0.9),
                                // Row of spec boxes.
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
                                    _buildSpecBox(context,
                                        vehicle.config ?? 'N/A', specFontSize),
                                  ],
                                ),
                                SizedBox(height: verticalSpacing * 0.9),
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
                                        // Background layer.
                                        Container(
                                          color: const Color(0xFF2F7FFF)
                                              .withOpacity(0.2),
                                        ),
                                        // Gray bar.
                                        Positioned(
                                          left: paddingVal * 0.7,
                                          right: paddingVal * 2.8,
                                          top: 0,
                                          bottom: 0,
                                          child: Container(
                                            margin: EdgeInsets.symmetric(
                                              vertical:
                                                  contentSectionHeight * 0.01,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0d1d4a),
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                            ),
                                          ),
                                        ),
                                        // Green fill representing progress.
                                        Positioned(
                                          left: paddingVal * 0.7,
                                          right: paddingVal * 2.8,
                                          top: 0,
                                          bottom: 0,
                                          child: FractionallySizedBox(
                                            widthFactor: progressRatio,
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              margin: EdgeInsets.symmetric(
                                                vertical:
                                                    contentSectionHeight * 0.01,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF4CAF50),
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Progress text.
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
                                SizedBox(height: verticalSpacing),
                                // "VIEW MORE DETAILS" button.
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: onTap,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2F7FFF),
                                      minimumSize:
                                          Size(double.infinity, buttonHeight),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            paddingVal * 0.5),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
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
              // Optional delete button for web.
              if (kIsWeb)
                Positioned(
                  top: 15,
                  right: 15,
                  child: InkWell(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
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
