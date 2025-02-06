import 'package:ctp/models/vehicle.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class WishCard extends StatelessWidget {
  final String vehicleMakeModel;
  final String vehicleImageUrl;
  final Size size;
  final TextStyle Function(double, FontWeight, Color) customFont;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool hasOffer;
  final String vehicleId;
  final Vehicle vehicle; // The vehicle model

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

  /// Builds one of the spec boxes (for mileage, transmission, config).
  Widget _buildSpecBox(String value, double fontSize) {
    if (value.trim().isEmpty || value.toUpperCase() == 'N/A') {
      return const SizedBox.shrink();
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.5,
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
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value.toUpperCase(),
          style: customFont(fontSize, FontWeight.bold, Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Here we use a fixed width and height similar to your TruckCard.
    // (You can adjust these numbers or make them responsive as needed.)
    const double fixedWidth = 400;
    const double fixedHeight = 500;

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
                width: fixedWidth,
                height: fixedHeight,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  // Use a background color and border similar to TruckCard.
                  color: const Color(0xFF2F7FFF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2F7FFF), width: 2),
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
                    double paddingVal = cardW * 0.04;
                    double titleFontSize = cardW * 0.045;
                    double specFontSize = cardW * 0.03;
                    double buttonFontSize = cardW * 0.035;

                    // Prepare the title from the vehicle's brands, make/model, and year.
                    final String brandModel = [
                      vehicle.brands.join(" "),
                      vehicle.makeModel
                    ].where((element) => element.isNotEmpty).join(" ");
                    final String year = vehicle.year.toString();

                    // Helper to check if a field is filled.
                    bool isFieldFilled(dynamic value) {
                      if (value == null) return false;
                      if (value is String)
                        return value.trim().isNotEmpty &&
                            value.trim().toUpperCase() != 'N/A';
                      if (value is List) return value.isNotEmpty;
                      return true;
                    }

                    // List of 41 fields (as used in TruckCard).
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

                    int totalFields = fields.length;
                    int filledFields =
                        fields.where((field) => isFieldFilled(field)).length;
                    double progressRatio = filledFields / totalFields;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Image Section (occupies 55% of the card's height).
                        SizedBox(
                          height: cardH * 0.55,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10)),
                            child: (vehicle.mainImageUrl != null &&
                                    vehicle.mainImageUrl!.isNotEmpty)
                                ? Image.network(
                                    vehicle.mainImageUrl!,
                                    width: cardW,
                                    height: cardH * 0.55,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Image.asset(
                                      'lib/assets/default_vehicle_image.png',
                                      width: cardW,
                                      height: cardH * 0.55,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    'lib/assets/default_vehicle_image.png',
                                    width: cardW,
                                    height: cardH * 0.55,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                        // Details Section: Vehicle title (brand, make/model, year).
                        Padding(
                          padding: EdgeInsets.all(paddingVal),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  brandModel.isEmpty
                                      ? 'LOADING...'
                                      : brandModel.toUpperCase(),
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
                                  year,
                                  style: GoogleFonts.montserrat(
                                    fontSize: titleFontSize * 0.9,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Row of Spec Boxes.
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: paddingVal),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: _buildSpecBox(
                                    '${vehicle.mileage ?? "N/A"} km',
                                    specFontSize),
                              ),
                              SizedBox(width: paddingVal * 0.3),
                              Expanded(
                                child: _buildSpecBox(
                                    vehicle.transmissionType ?? 'N/A',
                                    specFontSize),
                              ),
                              SizedBox(width: paddingVal * 0.3),
                              Expanded(
                                child: _buildSpecBox(
                                    vehicle.config ?? 'N/A', specFontSize),
                              ),
                            ],
                          ),
                        ),
                        // Progress Bar
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: paddingVal,
                            vertical: paddingVal * 0.3,
                          ),
                          child: Container(
                            height: cardH * 0.045,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(cardH * 0.025),
                              border: Border.all(
                                color: const Color(0xFF2F7FFF),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(cardH * 0.025),
                              child: Stack(
                                children: [
                                  // Base background layer.
                                  Container(
                                    color: const Color(0xFF2F7FFF)
                                        .withOpacity(0.2),
                                  ),
                                  // Dark gray bar layer.
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      color:
                                          Colors.grey.shade800.withOpacity(0.3),
                                    ),
                                  ),
                                  // Gray bar overlay (if needed, adjust opacity for contrast).
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      color: Colors.grey.withOpacity(0.1),
                                    ),
                                  ),
                                  // Green fill based on progressRatio.
                                  Positioned(
                                    left: paddingVal * 0.7,
                                    right: paddingVal * 2.8,
                                    top: 0,
                                    bottom: 0,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: cardH * 0.01,
                                      ),
                                      child: FractionallySizedBox(
                                        widthFactor: progressRatio,
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          height: 2.0,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4CAF50),
                                            borderRadius:
                                                BorderRadius.circular(100),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Progress text on top.
                                  Positioned(
                                    right: 5,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: Text(
                                        '$filledFields/$totalFields',
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
                          ),
                        ),
                        const Spacer(),
                        // Action Button Section.
                        Padding(
                          padding: EdgeInsets.only(
                            left: paddingVal,
                            right: paddingVal,
                            bottom: paddingVal,
                          ),
                          child: ElevatedButton(
                            onPressed: onTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasOffer
                                  ? const Color(0xFFFF4E00)
                                  : Colors.green,
                              padding: EdgeInsets.symmetric(
                                  vertical: paddingVal * 0.75),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(paddingVal * 0.5),
                              ),
                            ),
                            child: Text(
                              hasOffer ? 'OFFER MADE' : 'MAKE OFFER',
                              style: GoogleFonts.montserrat(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.bold,
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
              // Add delete button for web version
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
