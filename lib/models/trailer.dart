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

  // Add these image URL fields
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
    this.damages = const [],
    this.damagesCondition = 'no',
    this.features = const [],
    this.featuresCondition = 'no',
    this.brands = const [],
  });

  factory Trailer.fromFirestore(String docId, Map<String, dynamic> data) {
    debugPrint('Trailer.fromFirestore docId: $docId, data: $data');
    final typeSpecificData = data['trailerExtraInfo'] as Map<String, dynamic>?;
    debugPrint('trailerExtraInfo: $typeSpecificData');

    SuperlinkTrailer? superlinkData;
    TriAxleTrailer? triAxleData;

    if (data['trailerType'] == 'Superlink') {
      if (typeSpecificData != null &&
          typeSpecificData.containsKey('trailerA')) {
        // Merge data from trailerA and trailerB
        final trailerAMap =
            typeSpecificData['trailerA'] as Map<String, dynamic>;
        final trailerBMap =
            typeSpecificData['trailerB'] as Map<String, dynamic>? ?? {};
        superlinkData = SuperlinkTrailer.fromJson({
          'lengthA': trailerAMap['length'] ?? 'N/A',
          'vinA': trailerAMap['vin'] ?? 'N/A',
          'registrationA': trailerAMap['registration'] ?? 'N/A',
          'lengthB': trailerBMap['length'] ?? 'N/A',
          'vinB': trailerBMap['vin'] ?? 'N/A',
          'registrationB': trailerBMap['registration'] ?? 'N/A',
        });
      } else if (typeSpecificData != null) {
        superlinkData = SuperlinkTrailer.fromJson(typeSpecificData);
      } else {
        debugPrint(
            'Fallback: No trailerExtraInfo for Superlink. Using fallback fields.');
        superlinkData = SuperlinkTrailer.fromJson({
          'lengthA': data['lengthA'] ?? 'N/A',
          'vinA': data['vinA'] ?? 'N/A',
          'registrationA': data['registrationA'] ?? 'N/A',
          'lengthB': data['lengthB'] ?? 'N/A',
          'vinB': data['vinB'] ?? 'N/A',
          'registrationB': data['registrationB'] ?? 'N/A',
        });
      }
    } else if (data['trailerType'] == 'Tri-Axle') {
      if (typeSpecificData != null) {
        triAxleData = TriAxleTrailer.fromJson(typeSpecificData);
      } else {
        debugPrint(
            'Fallback: No trailerExtraInfo for Tri-Axle. Using fallback fields.');
        triAxleData = TriAxleTrailer(
          length: data['lengthTrailer'] ?? 'N/A',
          vin: data['vin'] ?? 'N/A',
          registration: data['registration'] ?? 'N/A',
        );
      }
    }
    return Trailer(
      id: docId,
      makeModel: data['makeModel'] ?? '',
      year: data['year'] ?? '',
      trailerType: data['trailerType'] ?? '',
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
    );
  }

  // Rename toJson to toMap for compatibility
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

    // Add type-specific data
    if (trailerType == 'Superlink' && superlinkData != null) {
      data['trailerExtraInfo'] = superlinkData!.toJson();
    } else if (trailerType == 'Tri-Axle' && triAxleData != null) {
      data['trailerExtraInfo'] = triAxleData!.toJson();
    }

    return data;
  }
}
