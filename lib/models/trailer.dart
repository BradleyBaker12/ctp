import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/models/trailer_types/superlink.dart';
import 'package:ctp/models/trailer_types/tri_axle.dart';

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
  final List<Map<String, dynamic>> additionalImages;

  // Type-specific data
  final SuperlinkTrailer? superlinkData;
  final TriAxleTrailer? triAxleData;

  // To preserve the exact structure from Firestore.
  final Map<String, dynamic>? rawTrailerExtraInfo;

  // Additional Features and Damages
  final List<Map<String, dynamic>> damages;
  final String damagesCondition;
  final List<Map<String, dynamic>> features;
  final String featuresCondition;
  final List<String> brands;

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
    this.additionalImages = const [],
    this.superlinkData,
    this.triAxleData,
    this.rawTrailerExtraInfo,
    this.damages = const [],
    this.damagesCondition = 'no',
    this.features = const [],
    this.featuresCondition = 'no',
    this.brands = const [],
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

    if (trailerType.toLowerCase() == 'superlink') {
      final trailerA = _safeMapConversion(rawExtra['trailerA']);
      final trailerB = _safeMapConversion(rawExtra['trailerB']);

      // debugPrint('DEBUG: Raw Trailer A data: $trailerA');
      // debugPrint('DEBUG: Raw Trailer B data: $trailerB');

      // Create map for SuperlinkTrailer with all fields preserved
      final superlinkMap = {
        'trailerA': {
          'length': trailerA['length']?.toString() ?? '',
          'vin': trailerA['vin']?.toString() ?? '',
          'registration': trailerA['registration']?.toString() ?? '',
          'natisDocUrl': trailerA['natisDocUrl']?.toString() ?? '',
          'frontImageUrl': trailerA['frontImageUrl']?.toString() ?? '',
          'sideImageUrl': trailerA['sideImageUrl']?.toString() ?? '',
          'tyresImageUrl': trailerA['tyresImageUrl']?.toString() ?? '',
          'chassisImageUrl': trailerA['chassisImageUrl']?.toString() ?? '',
          'deckImageUrl': trailerA['deckImageUrl']?.toString() ?? '',
          'makersPlateImageUrl':
              trailerA['makersPlateImageUrl']?.toString() ?? '',
          'additionalImages': trailerA['additionalImages'] ?? [],
        },
        'trailerB': {
          'length': trailerB['length']?.toString() ?? '',
          'vin': trailerB['vin']?.toString() ?? '',
          'registration': trailerB['registration']?.toString() ?? '',
          'natisDocUrl': trailerB['natisDocUrl']?.toString() ?? '',
          'frontImageUrl': trailerB['frontImageUrl']?.toString() ?? '',
          'sideImageUrl': trailerB['sideImageUrl']?.toString() ?? '',
          'tyresImageUrl': trailerB['tyresImageUrl']?.toString() ?? '',
          'chassisImageUrl': trailerB['chassisImageUrl']?.toString() ?? '',
          'deckImageUrl': trailerB['deckImageUrl']?.toString() ?? '',
          'makersPlateImageUrl':
              trailerB['makersPlateImageUrl']?.toString() ?? '',
          'additionalImages': trailerB['additionalImages'] ?? [],
        }
      };

      superlinkData = SuperlinkTrailer.fromJson(superlinkMap);
      // debugPrint(
      //     'DEBUG: Created SuperlinkTrailer data: ${superlinkData.toJson()}');
    } else if (trailerType == 'Tri-Axle') {
      triAxleData = TriAxleTrailer.fromJson(rawExtra);
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
      additionalImages: parseAdditionalImages(data['additionalImages']),
      superlinkData: superlinkData,
      triAxleData: triAxleData,
      damages: List<Map<String, dynamic>>.from(data['damages'] ?? []),
      damagesCondition: safeString(data['damagesCondition'] ?? 'no'),
      features: List<Map<String, dynamic>>.from(data['features'] ?? []),
      featuresCondition: safeString(data['featuresCondition'] ?? 'no'),
      brands: List<String>.from(data['brands'] ?? []),
      // Store the raw Firestore data for later use in the edit form.
      rawTrailerExtraInfo: data['trailerExtraInfo'] as Map<String, dynamic>?,
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
      additionalImages:
          List<Map<String, dynamic>>.from(json['additionalImages'] ?? []),
      superlinkData: json['superlinkData'] != null
          ? SuperlinkTrailer.fromJson(
              json['superlinkData'] as Map<String, dynamic>)
          : null,
      triAxleData: json['triAxleData'] != null
          ? TriAxleTrailer.fromJson(json['triAxleData'] as Map<String, dynamic>)
          : null,
      rawTrailerExtraInfo: json['rawTrailerExtraInfo'] as Map<String, dynamic>?,
      damages: List<Map<String, dynamic>>.from(json['damages'] ?? []),
      damagesCondition: json['damagesCondition'] as String? ?? 'no',
      features: List<Map<String, dynamic>>.from(json['features'] ?? []),
      featuresCondition: json['featuresCondition'] as String? ?? 'no',
      brands: List<String>.from(json['brands'] ?? []),
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
      'additionalImages': additionalImages,
      'damages': damages,
      'damagesCondition': damagesCondition,
      'features': features,
      'featuresCondition': featuresCondition,
      'brands': brands,
    };

    // Always include the raw data if available.
    if (rawTrailerExtraInfo != null) {
      data['trailerExtraInfo'] = rawTrailerExtraInfo;
    } else if (trailerType == 'Superlink' && superlinkData != null) {
      data['trailerExtraInfo'] = superlinkData!.toJson();
    } else if (trailerType == 'Tri-Axle' && triAxleData != null) {
      data['trailerExtraInfo'] = triAxleData!.toJson();
    }

    return data;
  }
}
