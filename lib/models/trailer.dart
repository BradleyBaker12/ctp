import 'package:cloud_firestore/cloud_firestore.dart';

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

  // URLs for documents
  final String? natisDocumentUrl;
  final String? serviceHistoryUrl;

  // URLs for images
  final String? mainImageUrl;
  final String? frontImageUrl;
  final String? sideImageUrl;
  final String? tyresImageUrl;
  final String? chassisImageUrl;
  final String? deckImageUrl;
  final String? makersPlateImageUrl;

  // Lists for additional data
  final List<Map<String, dynamic>> additionalImages;
  final String damagesCondition;
  final List<Map<String, dynamic>> damages;
  final String featuresCondition;
  final List<Map<String, dynamic>> features;
  final List<String> brands;

  final String vehicleType;

  Trailer({
    required this.id,
    this.vehicleType = 'trailer', // Always "trailer" for this class
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
    this.damagesCondition = 'no',
    this.damages = const [],
    this.featuresCondition = 'no',
    this.features = const [],
    this.brands = const [],
  });

  factory Trailer.fromFirestore(String docId, Map<String, dynamic> data) {
    return Trailer(
      id: docId,
      vehicleType: data['vehicleType'] ?? 'trailer',
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
      damagesCondition: data['damagesCondition'] ?? 'no',
      damages: List<Map<String, dynamic>>.from(data['damages'] ?? []),
      featuresCondition: data['featuresCondition'] ?? 'no',
      features: List<Map<String, dynamic>>.from(data['features'] ?? []),
      brands: List<String>.from(data['brands'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleType': vehicleType,
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
      'damagesCondition': damagesCondition,
      'damages': damages,
      'featuresCondition': featuresCondition,
      'features': features,
      'brands': brands,
    };
  }
}
