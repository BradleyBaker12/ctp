import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cached_network_image.dart';
import '../models/vehicle.dart';
import '../models/trailer.dart';

class ListingCard extends StatelessWidget {
  final dynamic vehicle; // Change to dynamic to accept both Vehicle and Trailer
  final VoidCallback onTap;

  const ListingCard({
    super.key,
    required this.vehicle,
    required this.onTap,
  });

  Widget _buildSpecBox(String? value, double fontSize) {
    if (value == null || value.trim().isEmpty || value.toUpperCase() == 'N/A') {
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

  bool get isTrailer =>
      vehicle is Trailer ||
      (vehicle is Vehicle && vehicle.vehicleType.toLowerCase() == 'trailer');

  String get displayMakeModel {
    if (isTrailer) {
      final t = vehicle is Trailer ? vehicle : vehicle.trailer;
      // Fallback to vehicle.makeModel if trailer.makeModel is missing/empty
      final makeModel = (t?.makeModel != null && t!.makeModel!.isNotEmpty)
          ? t.makeModel
          : (vehicle.makeModel ?? 'N/A');
      return makeModel ?? 'N/A';
    }
    return '${vehicle.brands.join(" ")} ${vehicle.variant}'.trim();
  }

  String get displayYear {
    if (isTrailer) {
      final t = vehicle is Trailer ? vehicle : vehicle.trailer;
      // Fallback to vehicle.year if trailer.year is missing/empty
      final year = (t?.year != null && t!.year!.toString().isNotEmpty)
          ? t.year
          : (vehicle.year ?? 'N/A');
      return year ?? 'N/A';
    }
    return vehicle.year ?? 'N/A';
  }

  String get displayMileage {
    if (isTrailer) {
      final t = vehicle is Trailer ? vehicle : vehicle.trailer;
      return t?.mileage ?? 'N/A';
    }
    return vehicle.mileage ?? 'N/A';
  }

  String get displayConfig {
    if (isTrailer) {
      final t = vehicle is Trailer ? vehicle : vehicle.trailer;
      return t?.trailerType ?? 'N/A';
    }
    return vehicle.config ?? 'N/A';
  }

  String get displayTransmission {
    if (isTrailer) {
      final t = vehicle is Trailer ? vehicle : vehicle.trailer;
      final axles = t?.axles?.toString();
      return axles != null ? '$axles AXLES' : 'N/A';
    }
    return vehicle.transmissionType ?? 'N/A';
  }

  String get displayReferenceNumber {
    if (isTrailer) {
      final t = vehicle is Trailer ? vehicle : vehicle.trailer;
      return t?.referenceNumber ?? '';
    }
    return vehicle.referenceNumber ?? '';
  }

  bool _isFieldFilled(dynamic field) {
    if (field == null) return false;
    if (field is String) return field.isNotEmpty;
    if (field is List) return field.isNotEmpty;
    if (field is Map) return field.isNotEmpty;
    return true;
  }

  (int filled, int total) _calculateTrailerFieldsRatio(Trailer? trailer) {
    if (trailer == null) return (0, 1);

    final fieldsToCheck = [
      trailer.makeModel,
      trailer.year,
      trailer.trailerType,
      trailer.axles,
      trailer.length,
      trailer.vinNumber,
      trailer.registrationNumber,
      trailer.mileage,
      trailer.engineNumber,
      trailer.sellingPrice,
      trailer.warrantyDetails,
      trailer.referenceNumber,
      trailer.country,
      trailer.province,
      trailer.natisDocumentUrl,
      trailer.serviceHistoryUrl,
      trailer.mainImageUrl,
      trailer.damages,
      trailer.features,
    ];

    final filledFields = fieldsToCheck.where(_isFieldFilled).length;
    return (filledFields, fieldsToCheck.length);
  }

  (int filled, int total) _calculateFieldsRatio() {
    if (isTrailer) {
      return _calculateTrailerFieldsRatio(
          vehicle is Trailer ? vehicle : vehicle.trailer);
    }

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

      // Truck Conditions - Tyres
      vehicle.truckConditions.tyres['tyres']?.positions.isNotEmpty,
    ];

    final filledFields = fieldsToCheck.where(_isFieldFilled).length;
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
                      child: SafeNetworkImage(
                        imageUrl: (vehicle is Trailer
                                ? vehicle.mainImageUrl
                                : (vehicle.mainImageUrl ??
                                    vehicle.trailer?.mainImageUrl)) ??
                            '',
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
                            // Title derived without extra Firestore reads
                            if (isTrailer)
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '$displayYear $displayMakeModel'
                                      .toUpperCase(),
                                  style: GoogleFonts.montserrat(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                ),
                              )
                            else
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  displayMakeModel.toUpperCase(),
                                  style: GoogleFonts.montserrat(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            if (!isTrailer) ...[
                              SizedBox(height: paddingVal * 0.25),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  displayYear,
                                  style: GoogleFonts.montserrat(
                                    fontSize: subtitleFontSize,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Reference Number
                        if (displayReferenceNumber.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                                top: paddingVal * 0.15,
                                bottom: paddingVal * 0.15),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Ref: $displayReferenceNumber',
                                style: GoogleFonts.montserrat(
                                  fontSize: subtitleFontSize,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFF4E00),
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ),
                        SizedBox(height: paddingVal),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                                child: _buildSpecBox(
                                    displayMileage != 'N/A'
                                        ? '$displayMileage km'
                                        : 'N/A',
                                    specFontSize)),
                            SizedBox(width: paddingVal * 0.3),
                            Expanded(
                                child: _buildSpecBox(
                                    displayTransmission, specFontSize)),
                            SizedBox(width: paddingVal * 0.3),
                            Expanded(
                                child:
                                    _buildSpecBox(displayConfig, specFontSize)),
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
