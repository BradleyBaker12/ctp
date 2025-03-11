import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/models/trailer_types/superlink.dart';
import 'package:ctp/models/trailer_types/tri_axle.dart';
import 'package:flutter/material.dart';

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

  factory Trailer.fromFirestore(String docId, Map<String, dynamic> data) {
    final trailerType = data['trailerType'];
    SuperlinkTrailer? superlinkData;
    TriAxleTrailer? triAxleData;
    // Preserve the original trailerExtraInfo from Firestore.
    final rawExtra = data['trailerExtraInfo'] as Map<String, dynamic>?;

    if (trailerType == 'Superlink') {
      final fallbackTrailer = data['trailer'] as Map<String, dynamic>? ?? {};
      final trailerAMapExtra = rawExtra != null
          ? (rawExtra['trailerA'] as Map<String, dynamic>? ?? {})
          : {};
      final trailerBMapExtra = rawExtra != null
          ? (rawExtra['trailerB'] as Map<String, dynamic>? ?? {})
          : {};

      superlinkData = SuperlinkTrailer.fromJson({
        'lengthA': (trailerAMapExtra['length']?.toString().trim().isNotEmpty ==
                true)
            ? trailerAMapExtra['length']
            : ((fallbackTrailer['length']?.toString().trim().isNotEmpty == true)
                ? fallbackTrailer['length']
                : 'N/A'),
        'vinA': (trailerAMapExtra['vin']?.toString().trim().isNotEmpty == true)
            ? trailerAMapExtra['vin']
            : ((fallbackTrailer['vinNumber']?.toString().trim().isNotEmpty ==
                    true)
                ? fallbackTrailer['vinNumber']
                : 'N/A'),
        'registrationA':
            (trailerAMapExtra['registration']?.toString().trim().isNotEmpty ==
                    true)
                ? trailerAMapExtra['registration']
                : ((fallbackTrailer['registrationNumber']
                            ?.toString()
                            .trim()
                            .isNotEmpty ==
                        true)
                    ? fallbackTrailer['registrationNumber']
                    : 'N/A'),
        'lengthB': (trailerBMapExtra['length']?.toString().trim().isNotEmpty ==
                true)
            ? trailerBMapExtra['length']
            : ((data['lengthTrailerB']?.toString().trim().isNotEmpty == true)
                ? data['lengthTrailerB']
                : 'N/A'),
        'vinB': (trailerBMapExtra['vin']?.toString().trim().isNotEmpty == true)
            ? trailerBMapExtra['vin']
            : ((data['vinB']?.toString().trim().isNotEmpty == true)
                ? data['vinB']
                : 'N/A'),
        'registrationB':
            (trailerBMapExtra['registration']?.toString().trim().isNotEmpty ==
                    true)
                ? trailerBMapExtra['registration']
                : ((data['registrationB']?.toString().trim().isNotEmpty == true)
                    ? data['registrationB']
                    : 'N/A'),
      });
    } else if (trailerType == 'Tri-Axle') {
      if (rawExtra != null) {
        triAxleData = TriAxleTrailer.fromJson(rawExtra);
      } else {
        triAxleData = TriAxleTrailer(
          length: (data['lengthTrailer'] != null &&
                  data['lengthTrailer'].toString().trim().isNotEmpty)
              ? data['lengthTrailer']
              : 'N/A',
          vin: (data['vin'] != null && data['vin'].toString().trim().isNotEmpty)
              ? data['vin']
              : 'N/A',
          registration: (data['registration'] != null &&
                  data['registration'].toString().trim().isNotEmpty)
              ? data['registration']
              : 'N/A',
        );
      }
    }

    return Trailer(
      id: docId,
      makeModel: data['makeModel'] ?? '',
      year: data['year'] ?? '',
      trailerType: trailerType,
      axles: data['axles'] ?? '',
      length: data['length'] ?? '',
      vinNumber: data['vinNumber'] ?? '',
      registrationNumber: data['registrationNumber'] ?? '',
      mileage: data['mileage'] ?? '',
      engineNumber: data['engineNumber'] ?? '',
      sellingPrice: data['sellingPrice'] ?? '',
      warrantyDetails: data['warrantyDetails'] ?? '',
      referenceNumber: data['referenceNumber'] ?? '',
      country: data['country'] ?? '',
      province: data['province'] ?? '',
      vehicleStatus: data['vehicleStatus'] ?? '',
      userId: data['userId'] ?? '',
      assignedSalesRepId: data['assignedSalesRepId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      natisDocumentUrl: data['natisDocumentUrl'],
      serviceHistoryUrl: data['serviceHistoryUrl'],
      mainImageUrl: data['mainImageUrl'],
      frontImageUrl: data['frontImageUrl'],
      sideImageUrl: data['sideImageUrl'],
      tyresImageUrl: data['tyresImageUrl'],
      chassisImageUrl: data['chassisImageUrl'],
      deckImageUrl: data['deckImageUrl'],
      makersPlateImageUrl: data['makersPlateImageUrl'],
      additionalImages:
          List<Map<String, dynamic>>.from(data['additionalImages'] ?? []),
      superlinkData: superlinkData,
      triAxleData: triAxleData,
      damages: List<Map<String, dynamic>>.from(data['damages'] ?? []),
      damagesCondition: data['damagesCondition'] ?? 'no',
      features: List<Map<String, dynamic>>.from(data['features'] ?? []),
      featuresCondition: data['featuresCondition'] ?? 'no',
      brands: List<String>.from(data['brands'] ?? []),
      // Store the raw Firestore data for later use in the edit form.
      rawTrailerExtraInfo: data['trailerExtraInfo'] as Map<String, dynamic>?,
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
