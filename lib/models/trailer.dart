import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/models/trailer_types/superlink.dart';
import 'package:ctp/models/trailer_types/tri_axle.dart';
import 'package:ctp/models/trailer_types/double_axle.dart';

class Trailer {
  final String id;
  final String makeModel;
  final String year;
  final String trailerType;
  final String axles;
  final String length;
  final String vinNumber;
  final String registrationNumber;
  final String mileage;
  final String engineNumber;
  final String sellingPrice;
  final String warrantyDetails;
  final String referenceNumber;
  final String country;
  final String province;
  final String vehicleStatus;
  final String userId;
  final String? assignedSalesRepId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Documents
  final String? natisDocumentUrl;
  final String? serviceHistoryUrl;

  // Main Image
  final String? mainImageUrl;

  // Additional image URLs
  final String? frontImageUrl;
  final String? sideImageUrl;
  final String? tyresImageUrl;
  final String? chassisImageUrl;
  final String? deckImageUrl;
  final String? makersPlateImageUrl;
  final String? hookingPinImageUrl; // <-- add
  final String? roofImageUrl; // <-- add
  final String? tailBoardImageUrl; // <-- add
  final String? spareWheelImageUrl; // <-- add
  final String? landingLegsImageUrl; // <-- add
  final String? hoseAndElectricCableImageUrl; // <-- add
  final String? licenseDiskImageUrl; // <-- add
  final List<Map<String, dynamic>> additionalImages;

  // Type-specific data
  final SuperlinkTrailer? superlinkData;
  final TriAxleTrailer? triAxleData;
  final DoubleAxleTrailer? doubleAxleData;

  // To preserve the exact structure from Firestore.
  final Map<String, dynamic>? rawTrailerExtraInfo;

  // Additional Features and Damages
  final List<Map<String, dynamic>> damages;
  final String damagesCondition;
  final List<Map<String, dynamic>> features;
  final String featuresCondition;
  final List<String> brands;

  // New field for number of axles
  final String numberOfAxles;

  Trailer({
    required this.id,
    required this.makeModel,
    required this.year,
    required this.trailerType,
    required this.axles,
    required this.length,
    required this.vinNumber,
    required this.registrationNumber,
    required this.mileage,
    required this.engineNumber,
    required this.sellingPrice,
    required this.warrantyDetails,
    required this.referenceNumber,
    required this.country,
    required this.province,
    required this.vehicleStatus,
    required this.userId,
    this.assignedSalesRepId,
    this.createdAt,
    this.updatedAt,
    this.natisDocumentUrl,
    this.serviceHistoryUrl,
    this.mainImageUrl,
    this.frontImageUrl,
    this.sideImageUrl,
    this.tyresImageUrl,
    this.chassisImageUrl,
    this.deckImageUrl,
    this.makersPlateImageUrl,
    this.hookingPinImageUrl, // <-- add
    this.roofImageUrl, // <-- add
    this.tailBoardImageUrl, // <-- add
    this.spareWheelImageUrl, // <-- add
    this.landingLegsImageUrl, // <-- add
    this.hoseAndElectricCableImageUrl, // <-- add
    this.licenseDiskImageUrl, // <-- add
    this.additionalImages = const [],
    this.superlinkData,
    this.triAxleData,
    this.doubleAxleData,
    this.rawTrailerExtraInfo,
    this.damages = const [],
    this.damagesCondition = 'no',
    this.features = const [],
    this.featuresCondition = 'no',
    this.brands = const [],
    this.numberOfAxles = '',
  });

  static Map<String, dynamic> _safeMapConversion(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(value.map((key, value) {
        if (value is Map) {
          return MapEntry(key.toString(), _safeMapConversion(value));
        }
        return MapEntry(key.toString(), value);
      }));
    }
    return {};
  }

  factory Trailer.fromFirestore(String docId, Map<String, dynamic> data) {
    // debugPrint(
    //     'DEBUG: Converting trailer data to Trailer object: ${data['trailerExtraInfo']}');

    // Always convert trailer extra info to a proper map
    final rawExtra = _safeMapConversion(data['trailerExtraInfo'] ?? {});

    // Safely get trailer type
    final trailerType = (data['trailerType'] ?? '').toString();

    SuperlinkTrailer? superlinkData;
    TriAxleTrailer? triAxleData;
    DoubleAxleTrailer? doubleAxleData;

    if (trailerType.toLowerCase() == 'superlink') {
      final trailerA = _safeMapConversion(rawExtra['trailerA']);
      final trailerB = _safeMapConversion(rawExtra['trailerB']);

      // --- PATCH: Ensure axles are included in superlinkMap ---
      final superlinkMap = {
        'trailerA': {
          'length': trailerA['length']?.toString() ?? '',
          'vin': trailerA['vin']?.toString() ?? '',
          'registration': trailerA['registration']?.toString() ?? '',
          'axles':
              trailerA['axles']?.toString() ?? '', // <-- Ensure axles present
          'make': trailerA['make']?.toString(),
          'model': trailerA['model']?.toString(),
          'year': trailerA['year']?.toString(),
          'licenceExp': trailerA['licenceExp']?.toString(),
          'abs': trailerA['abs']?.toString(),
          'suspension': trailerA['suspension']?.toString(),
          'natisDoc1Url': trailerA['natisDoc1Url']?.toString(),
          'frontImageUrl': trailerA['frontImageUrl']?.toString(),
          'sideImageUrl': trailerA['sideImageUrl']?.toString(),
          'tyresImageUrl': trailerA['tyresImageUrl']?.toString(),
          'chassisImageUrl': trailerA['chassisImageUrl']?.toString(),
          'deckImageUrl': trailerA['deckImageUrl']?.toString(),
          'makersPlateImageUrl': trailerA['makersPlateImageUrl']?.toString(),
          'hookPinImageUrl': trailerA['hookPinImageUrl']?.toString(),
          'roofImageUrl': trailerA['roofImageUrl']?.toString(),
          'tailBoardImageUrl': trailerA['tailBoardImageUrl']?.toString(),
          'spareWheelImageUrl': trailerA['spareWheelImageUrl']?.toString(),
          'landingLegImageUrl': trailerA['landingLegImageUrl']?.toString(),
          'hoseAndElecticalCableImageUrl':
              trailerA['hoseAndElecticalCableImageUrl']?.toString(),
          'brakesAxle1ImageUrl': trailerA['brakesAxle1ImageUrl']?.toString(),
          'brakesAxle2ImageUrl': trailerA['brakesAxle2ImageUrl']?.toString(),
          'axle1ImageUrl': trailerA['axle1ImageUrl']?.toString(),
          'axle2ImageUrl': trailerA['axle2ImageUrl']?.toString(),
          'trailerAAdditionalImages':
              trailerA['trailerAAdditionalImages'] ?? [],
        },
        'trailerB': {
          'length': trailerB['length']?.toString() ?? '',
          'vin': trailerB['vin']?.toString() ?? '',
          'registration': trailerB['registration']?.toString() ?? '',
          'axles':
              trailerB['axles']?.toString() ?? '', // <-- Ensure axles present
          'make': trailerB['make']?.toString(),
          'model': trailerB['model']?.toString(),
          'year': trailerB['year']?.toString(),
          'licenceExp': trailerB['licenceExp']?.toString(),
          'abs': trailerB['abs']?.toString(),
          'suspension': trailerB['suspension']?.toString(),
          'natisDoc1Url': trailerB['natisDoc1Url']?.toString(),
          'frontImageUrl': trailerB['frontImageUrl']?.toString(),
          'sideImageUrl': trailerB['sideImageUrl']?.toString(),
          'tyresImageUrl': trailerB['tyresImageUrl']?.toString(),
          'chassisImageUrl': trailerB['chassisImageUrl']?.toString(),
          'deckImageUrl': trailerB['deckImageUrl']?.toString(),
          'makersPlateImageUrl': trailerB['makersPlateImageUrl']?.toString(),
          'hookPinImageUrl': trailerB['hookPinImageUrl']?.toString(),
          'roofImageUrl': trailerB['roofImageUrl']?.toString(),
          'tailBoardImageUrl': trailerB['tailBoardImageUrl']?.toString(),
          'spareWheelImageUrl': trailerB['spareWheelImageUrl']?.toString(),
          'landingLegImageUrl': trailerB['landingLegImageUrl']?.toString(),
          'hoseAndElecticalCableImageUrl':
              trailerB['hoseAndElecticalCableImageUrl']?.toString(),
          'brakesAxle1ImageUrl': trailerB['brakesAxle1ImageUrl']?.toString(),
          'brakesAxle2ImageUrl': trailerB['brakesAxle2ImageUrl']?.toString(),
          'axle1ImageUrl': trailerB['axle1ImageUrl']?.toString(),
          'axle2ImageUrl': trailerB['axle2ImageUrl']?.toString(),
          'trailerBAdditionalImages':
              trailerB['trailerBAdditionalImages'] ?? [],
        }
      };

      superlinkData = SuperlinkTrailer.fromJson(superlinkMap);
      // debugPrint(
      //     'DEBUG: Created SuperlinkTrailer data: ${superlinkData.toJson()}');
    } else if (trailerType == 'Tri-Axle') {
      triAxleData = TriAxleTrailer.fromJson(rawExtra);
    } else if (trailerType == 'Double-Axle') {
      doubleAxleData = DoubleAxleTrailer.fromJson(rawExtra);
    }

    // Helper to safely convert a value to String.
    String safeString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map) {
        // Convert the map to a JSON string so that even if a LinkedMap is passed, you get a string.
        return jsonEncode(value);
      }
      return value.toString();
    }

    // Helper method to safely parse additional images
    List<Map<String, dynamic>> parseAdditionalImages(dynamic images) {
      if (images == null) return [];
      if (images is List) {
        return images
            .map((item) {
              if (item is Map) {
                var parsed = Map<String, dynamic>.from(item);
                // Ensure required fields exist
                return {
                  'description': parsed['description']?.toString() ?? '',
                  'imageUrl': parsed['imageUrl']?.toString() ?? '',
                };
              }
              return <String, dynamic>{
                'description': '',
                'imageUrl': '',
              };
            })
            .where((item) =>
                item['imageUrl'] != null &&
                item['imageUrl'].toString().isNotEmpty)
            .toList();
      }
      return [];
    }

    return Trailer(
      id: docId,
      makeModel: safeString(data['makeModel']),
      year: safeString(data['year']),
      trailerType: safeString(trailerType),
      axles: safeString(data['axles']),
      length: safeString(data['length']),
      vinNumber: safeString(data['vinNumber']),
      registrationNumber: safeString(data['registrationNumber']),
      mileage: safeString(data['mileage']),
      engineNumber: safeString(data['engineNumber']),
      sellingPrice: safeString(data['sellingPrice']),
      warrantyDetails: safeString(data['warrantyDetails']),
      referenceNumber: safeString(data['referenceNumber']),
      country: safeString(data['country']),
      province: safeString(data['province']),
      vehicleStatus: safeString(data['vehicleStatus']),
      userId: safeString(data['userId']),
      assignedSalesRepId: data['assignedSalesRepId'] != null
          ? safeString(data['assignedSalesRepId'])
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      natisDocumentUrl: data['natisDocumentUrl'] != null
          ? safeString(data['natisDocumentUrl'])
          : null,
      serviceHistoryUrl: data['serviceHistoryUrl'] != null
          ? safeString(data['serviceHistoryUrl'])
          : null,
      mainImageUrl: data['mainImageUrl'] != null
          ? safeString(data['mainImageUrl'])
          : null,
      frontImageUrl: data['frontImageUrl'] != null
          ? safeString(data['frontImageUrl'])
          : null,
      sideImageUrl: data['sideImageUrl'] != null
          ? safeString(data['sideImageUrl'])
          : null,
      tyresImageUrl: data['tyresImageUrl'] != null
          ? safeString(data['tyresImageUrl'])
          : null,
      chassisImageUrl: data['chassisImageUrl'] != null
          ? safeString(data['chassisImageUrl'])
          : null,
      deckImageUrl: data['deckImageUrl'] != null
          ? safeString(data['deckImageUrl'])
          : null,
      makersPlateImageUrl: data['makersPlateImageUrl'] != null
          ? safeString(data['makersPlateImageUrl'])
          : null,
      hookingPinImageUrl: data['hookingPinImageUrl'] != null
          ? safeString(data['hookingPinImageUrl'])
          : null,
      roofImageUrl: data['roofImageUrl'] != null
          ? safeString(data['roofImageUrl'])
          : null,
      tailBoardImageUrl: data['tailBoardImageUrl'] != null
          ? safeString(data['tailBoardImageUrl'])
          : null,
      spareWheelImageUrl: data['spareWheelImageUrl'] != null
          ? safeString(data['spareWheelImageUrl'])
          : null,
      landingLegsImageUrl: data['landingLegsImageUrl'] != null
          ? safeString(data['landingLegsImageUrl'])
          : null,
      hoseAndElectricCableImageUrl: data['hoseAndElectricCableImageUrl'] != null
          ? safeString(data['hoseAndElectricCableImageUrl'])
          : null,
      licenseDiskImageUrl: data['licenseDiskImageUrl'] != null
          ? safeString(data['licenseDiskImageUrl'])
          : null,
      additionalImages: parseAdditionalImages(data['additionalImages']),
      superlinkData: superlinkData,
      triAxleData: triAxleData,
      doubleAxleData: doubleAxleData,
      damages: List<Map<String, dynamic>>.from(data['damages'] ?? []),
      damagesCondition: safeString(data['damagesCondition'] ?? 'no'),
      features: List<Map<String, dynamic>>.from(data['features'] ?? []),
      featuresCondition: safeString(data['featuresCondition'] ?? 'no'),
      brands: List<String>.from(data['brands'] ?? []),
      // Store the raw Firestore data for later use in the edit form.
      rawTrailerExtraInfo: data['trailerExtraInfo'] as Map<String, dynamic>?,
      numberOfAxles: data['numberOfAxles']?.toString() ??
          data['axles']?.toString() ??
          '', // fallback to axles if not present
    );
  }

  factory Trailer.fromJson(Map<String, dynamic> json) {
    return Trailer(
      id: json['id'] as String,
      makeModel: json['makeModel'] as String,
      year: json['year'] as String,
      trailerType: json['trailerType'] as String,
      axles: json['axles'] as String,
      length: json['length'] as String,
      vinNumber: json['vinNumber'] as String,
      registrationNumber: json['registrationNumber'] as String,
      mileage: json['mileage'] as String,
      engineNumber: json['engineNumber'] as String,
      sellingPrice: json['sellingPrice'] as String,
      warrantyDetails: json['warrantyDetails'] as String,
      referenceNumber: json['referenceNumber'] as String,
      country: json['country'] as String,
      province: json['province'] as String,
      vehicleStatus: json['vehicleStatus'] as String,
      userId: json['userId'] as String,
      assignedSalesRepId: json['assignedSalesRepId'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      natisDocumentUrl: json['natisDocumentUrl'] as String?,
      serviceHistoryUrl: json['serviceHistoryUrl'] as String?,
      mainImageUrl: json['mainImageUrl'] as String?,
      frontImageUrl: json['frontImageUrl'] as String?,
      sideImageUrl: json['sideImageUrl'] as String?,
      tyresImageUrl: json['tyresImageUrl'] as String?,
      chassisImageUrl: json['chassisImageUrl'] as String?,
      deckImageUrl: json['deckImageUrl'] as String?,
      makersPlateImageUrl: json['makersPlateImageUrl'] as String?,
      hookingPinImageUrl: json['hookingPinImageUrl'] as String?, // <-- add
      roofImageUrl: json['roofImageUrl'] as String?, // <-- add
      tailBoardImageUrl: json['tailBoardImageUrl'] as String?, // <-- add
      spareWheelImageUrl: json['spareWheelImageUrl'] as String?, // <-- add
      landingLegsImageUrl: json['landingLegsImageUrl'] as String?, // <-- add
      hoseAndElectricCableImageUrl:
          json['hoseAndElectricCableImageUrl'] as String?, // <-- add
      licenseDiskImageUrl: json['licenseDiskImageUrl'] as String?, // <-- add
      additionalImages:
          List<Map<String, dynamic>>.from(json['additionalImages'] ?? []),
      superlinkData: json['superlinkData'] != null
          ? SuperlinkTrailer.fromJson(
              json['superlinkData'] as Map<String, dynamic>)
          : null,
      triAxleData: json['triAxleData'] != null
          ? TriAxleTrailer.fromJson(json['triAxleData'] as Map<String, dynamic>)
          : null,
      doubleAxleData: json['doubleAxleData'] != null
          ? DoubleAxleTrailer.fromJson(
              json['doubleAxleData'] as Map<String, dynamic>)
          : null,
      rawTrailerExtraInfo: json['rawTrailerExtraInfo'] as Map<String, dynamic>?,
      damages: List<Map<String, dynamic>>.from(json['damages'] ?? []),
      damagesCondition: json['damagesCondition'] as String? ?? 'no',
      features: List<Map<String, dynamic>>.from(json['features'] ?? []),
      featuresCondition: json['featuresCondition'] as String? ?? 'no',
      brands: List<String>.from(json['brands'] ?? []),
      numberOfAxles:
          json['numberOfAxles']?.toString() ?? json['axles']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => toJson();

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'makeModel': makeModel,
      'year': year,
      'trailerType': trailerType,
      'axles': axles,
      'length': length,
      'vinNumber': vinNumber,
      'registrationNumber': registrationNumber,
      'mileage': mileage,
      'engineNumber': engineNumber,
      'sellingPrice': sellingPrice,
      'warrantyDetails': warrantyDetails,
      'referenceNumber': referenceNumber,
      'country': country,
      'province': province,
      'vehicleStatus': vehicleStatus,
      'userId': userId,
      'assignedSalesRepId': assignedSalesRepId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'natisDocumentUrl': natisDocumentUrl,
      'serviceHistoryUrl': serviceHistoryUrl,
      'mainImageUrl': mainImageUrl,
      'frontImageUrl': frontImageUrl,
      'sideImageUrl': sideImageUrl,
      'tyresImageUrl': tyresImageUrl,
      'chassisImageUrl': chassisImageUrl,
      'deckImageUrl': deckImageUrl,
      'makersPlateImageUrl': makersPlateImageUrl,
      'hookingPinImageUrl': hookingPinImageUrl, // <-- add
      'roofImageUrl': roofImageUrl, // <-- add
      'tailBoardImageUrl': tailBoardImageUrl, // <-- add
      'spareWheelImageUrl': spareWheelImageUrl, // <-- add
      'landingLegsImageUrl': landingLegsImageUrl, // <-- add
      'hoseAndElectricCableImageUrl': hoseAndElectricCableImageUrl, // <-- add
      'licenseDiskImageUrl': licenseDiskImageUrl, // <-- add
      'additionalImages': additionalImages,
      'damages': damages,
      'damagesCondition': damagesCondition,
      'features': features,
      'featuresCondition': featuresCondition,
      'brands': brands,
      'numberOfAxles': numberOfAxles,
    };

    // Always include the raw data if available.
    if (rawTrailerExtraInfo != null) {
      data['trailerExtraInfo'] = rawTrailerExtraInfo;
    } else if (trailerType == 'Superlink' && superlinkData != null) {
      data['trailerExtraInfo'] = superlinkData!.toJson();
    } else if (trailerType == 'Tri-Axle' && triAxleData != null) {
      data['trailerExtraInfo'] = triAxleData!.toJson();
    } else if (trailerType == 'Double-Axle' && doubleAxleData != null) {
      data['trailerExtraInfo'] = doubleAxleData!.toJson();
    }

    return data;
  }
}
