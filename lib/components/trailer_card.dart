import 'dart:math';
import 'package:ctp/models/admin_data.dart';
import 'package:ctp/models/chassis.dart';
import 'package:ctp/models/drive_train.dart';
import 'package:ctp/models/external_cab.dart';
import 'package:ctp/models/internal_cab.dart';
import 'package:ctp/models/maintenance.dart';
import 'package:ctp/models/truck_conditions.dart';
import 'package:ctp/models/tyres.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trailer.dart';
import '../pages/vehicle_details_page.dart';
import '../providers/user_provider.dart';

class TrailerCard extends StatelessWidget {
  final Trailer trailer;
  final Function(Trailer) onInterested;
  final Color? borderColor;

  const TrailerCard({
    super.key,
    required this.trailer,
    required this.onInterested,
    this.borderColor,
  });

  // Modified: get detailed trailer info based on type with make and model information
  String getTrailerDetails() {
    // Direct console printing for better visibility
    print('====== TRAILER DEBUG ======');
    print('Trailer type: ${trailer.trailerType}');
    print('Complete trailer data: ${trailer.toJson()}');

    switch (trailer.trailerType) {
      case 'Superlink':
        final data = trailer.superlinkData;
        print('Superlink data: $data');
        if (data != null) {
          try {
            // Access data using toJson to handle the data structure properly
            final jsonData = data.toJson();
            print('Superlink jsonData structure: ${jsonData.keys}');
            print('Full Superlink jsonData: $jsonData');

            // Try different access patterns
            if (jsonData.containsKey('trailerA')) {
              final trailerA = jsonData['trailerA'] as Map<String, dynamic>?;
              print('Superlink trailerA data: $trailerA');

              if (trailerA != null) {
                final make = trailerA['make'] as String? ?? '';
                final model = trailerA['model'] as String? ?? '';
                print(
                    'Superlink values found - make: "$make", model: "$model"');

                if (make.isNotEmpty || model.isNotEmpty) {
                  final result = '$make $model'.trim();
                  print('RETURNING Superlink result: "$result"');
                  return result;
                }
              }
            }

            // Fallback: try to access data directly
            if (jsonData.containsKey('make') && jsonData.containsKey('model')) {
              final make = jsonData['make'] as String? ?? '';
              final model = jsonData['model'] as String? ?? '';
              print('Direct superlink values - make: "$make", model: "$model"');
              if (make.isNotEmpty || model.isNotEmpty) {
                final result = '$make $model'.trim();
                print('RETURNING direct Superlink result: "$result"');
                return result;
              }
            }

            // Dump all potential data locations
            print('Checking all superlink data paths...');
            jsonData.forEach((key, value) {
              if (value is Map && value.containsKey('make')) {
                print('Found make in key: $key, value: ${value['make']}');
              }
            });
          } catch (e) {
            print('ERROR accessing Superlink data: $e');
          }
        }
        print('Falling back to default: "Superlink"');
        return 'Superlink';

      case 'Tri-Axle':
        final data = trailer.triAxleData;
        print('Tri-Axle data: $data');
        if (data != null) {
          try {
            // Access data using toJson to get the map
            final jsonData = data.toJson();
            print('Tri-Axle jsonData structure: ${jsonData.keys}');
            print('Full Tri-Axle jsonData: $jsonData');

            final make = jsonData['make'] as String? ?? '';
            final model = jsonData['model'] as String? ?? '';
            print('Tri-Axle values - make: "$make", model: "$model"');

            if (make.isNotEmpty || model.isNotEmpty) {
              final result = '$make $model'.trim();
              print('RETURNING Tri-Axle result: "$result"');
              return result;
            }
          } catch (e) {
            print('ERROR accessing Tri-Axle data: $e');
          }
        }
        print('Falling back to default: "${trailer.trailerType}"');
        return trailer.trailerType;

      case 'Double Axle':
      case 'Other':
        // Get trailer extra info from trailer data map
        print('Processing ${trailer.trailerType} trailer');
        try {
          final trailerData = trailer.toJson();
          print('${trailer.trailerType} trailerData keys: ${trailerData.keys}');

          // Try all possible fields for trailer extra info
          final possibleFields = [
            'trailerExtraInfo',
            'trailerExtra',
            'trailerExtraData',
            'extraInfo'
          ];

          for (final fieldName in possibleFields) {
            if (trailerData.containsKey(fieldName)) {
              print('Found field: $fieldName');
              final extraInfo = trailerData[fieldName] as Map<String, dynamic>?;
              print('${trailer.trailerType} $fieldName: $extraInfo');

              if (extraInfo != null) {
                final make = extraInfo['make'] as String? ?? '';
                final model = extraInfo['model'] as String? ?? '';
                print(
                    '${trailer.trailerType} $fieldName - make: "$make", model: "$model"');

                if (make.isNotEmpty || model.isNotEmpty) {
                  final result = '$make $model'.trim();
                  print(
                      'RETURNING ${trailer.trailerType} result from $fieldName: "$result"');
                  return result;
                }
              }
            }
          }

          // Last attempt - check trailerData directly
          if (trailerData.containsKey('make') &&
              trailerData.containsKey('model')) {
            final make = trailerData['make'] as String? ?? '';
            final model = trailerData['model'] as String? ?? '';
            print('Direct trailer values - make: "$make", model: "$model"');

            if (make.isNotEmpty || model.isNotEmpty) {
              final result = '$make $model'.trim();
              print('RETURNING direct trailer result: "$result"');
              return result;
            }
          }
        } catch (e) {
          print('ERROR accessing trailer extra info: $e');
        }
        print('Falling back to default: "${trailer.trailerType}"');
        return trailer.trailerType;

      default:
        return trailer.trailerType;
    }
  }

  // Calculate completeness ratio for the progress bar
  (int filled, int total) _calculateFieldsRatio() {
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
      trailer.mainImageUrl,
      trailer.frontImageUrl,
      trailer.sideImageUrl,
      trailer.tyresImageUrl,
      trailer.chassisImageUrl,
      trailer.deckImageUrl,
      trailer.makersPlateImageUrl,
      trailer.natisDocumentUrl,
      trailer.serviceHistoryUrl,
      if (trailer.damages.isNotEmpty) trailer.damages,
      if (trailer.features.isNotEmpty) trailer.features,
    ];

    final filledFields =
        fieldsToCheck.where((field) => field != null && field != '').length;
    return (filledFields, fieldsToCheck.length);
  }

  Widget _buildSpecBox(BuildContext context, String text, double fontSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0d1d4a),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AutoSizeText(
        text.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        maxLines: 1,
        minFontSize: 8,
      ),
    );
  }

  Future<void> _markAsInterested(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      try {
        final userDoc =
            FirebaseFirestore.instance.collection('users').doc(user.uid);

        if (userProvider.getLikedVehicles.contains(trailer.id)) {
          await userDoc.update({
            'likedVehicles': FieldValue.arrayRemove([trailer.id])
          });
          userProvider.unlikeVehicle(trailer.id);
        } else {
          await userDoc.update({
            'likedVehicles': FieldValue.arrayUnion([trailer.id])
          });
          userProvider.likeVehicle(trailer.id);
        }
      } catch (e) {
        debugPrint('Error updating liked trailers: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug: print complete trailer data
    debugPrint('Building TrailerCard with data: ${trailer.toJson()}');

    const double cardHeight = 600.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = min(screenWidth * 0.95, 500.0);

    final (filledFields, totalFields) = _calculateFieldsRatio();
    final progressRatio = totalFields > 0 ? filledFields / totalFields : 0.0;

    // Brand + Model text (derived directly when needed)

    // Create a conversion method from Trailer to Vehicle
    Vehicle trailerToVehicle(Trailer trailer) {
      return Vehicle(
        id: trailer.id,
        makeModel: trailer.makeModel,
        year: trailer.year,
        mainImageUrl: trailer.mainImageUrl,
        damagePhotos: [], // Empty for trailers
        damageDescription: '', // Empty for trailers
        expectedSellingPrice: trailer.sellingPrice,
        userId: trailer.userId,
        referenceNumber: trailer.referenceNumber,
        vehicleType: 'trailer', // Important to identify as trailer
        vehicleStatus: trailer.vehicleStatus,
        createdAt: trailer.createdAt ?? DateTime.now(),
        assignedSalesRepId: trailer.assignedSalesRepId,
        trailer: trailer, // Store the original trailer object
        isAccepted: false,
        acceptedOfferId: '',
        application: [],
        dashboardPhoto: '',
        engineNumber: trailer.engineNumber,
        faultCodesPhoto: '',
        hydraluicType: '',
        licenceDiskUrl: '',
        mileage: trailer.mileage,
        mileageImage: '',
        photos: const [],
        rc1NatisFile: '',
        registrationNumber: trailer.registrationNumber,
        suspensionType: '',
        transmissionType: '',
        config: '',
        vinNumber: trailer.vinNumber,
        warrentyType: '',
        warrantyDetails: trailer.warrantyDetails,
        vehicleAvailableImmediately: '',
        availableDate: '',
        adminData: AdminData(
            settlementAmount: '',
            natisRc1Url: '',
            licenseDiskUrl: '',
            settlementLetterUrl: ''),
        maintenance: Maintenance(vehicleId: ''),
        truckConditions: TruckConditions(
            externalCab: ExternalCab(
                condition: '',
                damagesCondition: '',
                additionalFeaturesCondition: '',
                images: {},
                damages: [],
                additionalFeatures: []),
            internalCab: InternalCab(
                condition: '',
                damagesCondition: '',
                additionalFeaturesCondition: '',
                faultCodesCondition: '',
                viewImages: {},
                damages: [],
                additionalFeatures: [],
                faultCodes: []),
            chassis: Chassis(
                condition: '',
                damagesCondition: '',
                additionalFeaturesCondition: '',
                images: {},
                damages: [],
                additionalFeatures: []),
            driveTrain: DriveTrain(
                condition: '',
                oilLeakConditionEngine: '',
                waterLeakConditionEngine: '',
                blowbyCondition: '',
                oilLeakConditionGearbox: '',
                retarderCondition: '',
                lastUpdated: DateTime.now(),
                images: {},
                damages: [],
                additionalFeatures: [],
                faultCodes: []),
            tyres: {
              'current': Tyres(positions: {}, lastUpdated: DateTime.now())
            }),
        country: '',
        province: '',
        damagesDescription: '',
        additionalFeatures: '', brands: [],
      );
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                VehicleDetailsPage(vehicle: trailerToVehicle(trailer)),
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
              final imageSectionHeight = cardH * 0.6;
              final titleFontSize = max(cardW * 0.045, 14.0);
              final specFontSize = max(cardW * 0.032, 14.0);
              final progressText = max(cardW * 0.024, 8.0);
              final buttonHeight = cardH * 0.08;
              final responsiveSpacing = screenWidth < 400 ? 4.0 : 8.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: imageSectionHeight,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24)),
                          child: (trailer.mainImageUrl != null &&
                                  trailer.mainImageUrl!.isNotEmpty)
                              ? Image.network(
                                  trailer.mainImageUrl!,
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
                                )
                              : Image.asset(
                                  'lib/assets/default_vehicle_image.png',
                                  width: cardW,
                                  height: imageSectionHeight,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Consumer<UserProvider>(
                            builder: (context, userProvider, child) {
                              bool isLiked = userProvider.getLikedVehicles
                                  .contains(trailer.id);
                              return IconButton(
                                icon: Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isLiked ? Colors.red : Colors.white,
                                  size: titleFontSize + 10,
                                ),
                                onPressed: () => _markAsInterested(context),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${trailer.year} ${getTrailerDetails()}'
                                .trim()
                                .toUpperCase(),
                            style: GoogleFonts.montserrat(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _buildSpecBox(
                                  context, trailer.trailerType, specFontSize),
                              SizedBox(width: responsiveSpacing),
                              _buildSpecBox(context, '${trailer.axles} AXLES',
                                  specFontSize),
                              SizedBox(width: responsiveSpacing),
                              _buildSpecBox(
                                  context, getTrailerDetails(), specFontSize),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Container(
                            height: cardH * 0.03,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: const Color(0xFF2F7FFF),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(50),
                              child: Stack(
                                children: [
                                  Container(
                                      color: const Color(0xFF2F7FFF)
                                          .withOpacity(0.2)),
                                  FractionallySizedBox(
                                    widthFactor: progressRatio,
                                    child: Container(
                                        color: const Color(0xFF4CAF50)),
                                  ),
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
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VehicleDetailsPage(
                                        vehicle: trailerToVehicle(trailer)),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2F7FFF),
                                minimumSize:
                                    Size(double.infinity, buttonHeight),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
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
