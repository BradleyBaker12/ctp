import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/models/chassis.dart';
import 'package:ctp/models/drive_train.dart';
import 'package:ctp/models/external_cab.dart';
import 'package:ctp/models/internal_cab.dart';
import 'package:ctp/models/tyres.dart';
import 'admin_data.dart';
import 'maintenance.dart';
import 'truck_conditions.dart';
import 'trailer.dart';
import 'package:flutter/foundation.dart'; // for debugPrint

class Vehicle {
  final bool isAccepted;
  final String? trailerType;
  final String? acceptedOfferId;
  final String makeModel;
  final String year;
  final String id;
  final List<String> application;
  final String damageDescription;
  final List<String?> damagePhotos;
  final String dashboardPhoto;
  final String engineNumber;
  final String expectedSellingPrice;
  final String faultCodesPhoto;
  final String hydraluicType;
  final String licenceDiskUrl;
  final String mileage;
  final String mileageImage;
  final String? mainImageUrl;
  final List<String?> photos;
  final String rc1NatisFile;
  final String registrationNumber;
  final String suspensionType;
  final String transmissionType;
  final String config;
  final String userId;
  final String vehicleType;
  final String vinNumber;
  final String warrentyType;
  final String warrantyDetails;
  final DateTime createdAt;
  final String vehicleStatus;
  final String vehicleAvailableImmediately;
  final String availableDate;
  final Trailer? trailer;
  String? natisRc1Url;
  final String referenceNumber;
  final String damagesDescription;
  final String additionalFeatures;
  final List<String> brands;

  final String? requireToSettleType;
  final String country;
  final String province;
  final String? variant;

  // Nested Objects
  final AdminData adminData;
  final Maintenance maintenance;
  final TruckConditions truckConditions;

  final String? assignedSalesRepId;

  // NEW FIELDS (all optional)
  final String? natisDocumentUrl;
  final String? serviceHistoryUrl;
  final String? frontImageUrl;
  final String? sideImageUrl;
  final String? tyresImageUrl;
  final String? chassisImageUrl;
  final String? makersPlateImageUrl;
  final List<String>? additionalImages;
  final String? damagesCondition;
  final List<Map<String, dynamic>>? damages;
  final String? featuresCondition;
  final List<Map<String, dynamic>>? features;
  final String? deckImageUrl;

  Vehicle({
    this.trailerType,
    this.assignedSalesRepId,
    required this.isAccepted,
    required this.acceptedOfferId,
    required this.id,
    required this.application,
    required this.damageDescription,
    required this.damagePhotos,
    required this.dashboardPhoto,
    required this.engineNumber,
    required this.expectedSellingPrice,
    required this.faultCodesPhoto,
    required this.hydraluicType,
    required this.licenceDiskUrl,
    required this.makeModel,
    required this.mileage,
    required this.mileageImage,
    this.mainImageUrl,
    required this.photos,
    required this.rc1NatisFile,
    required this.registrationNumber,
    required this.suspensionType,
    required this.transmissionType,
    required this.config,
    required this.userId,
    required this.vehicleType,
    required this.vinNumber,
    required this.warrentyType,
    required this.warrantyDetails,
    required this.year,
    required this.createdAt,
    required this.vehicleStatus,
    required this.vehicleAvailableImmediately,
    required this.availableDate,
    required this.adminData,
    required this.maintenance,
    required this.truckConditions,
    this.natisRc1Url,
    required this.referenceNumber,
    required this.brands,
    this.requireToSettleType,
    required this.country,
    required this.province,
    this.variant,
    required this.damagesDescription,
    required this.additionalFeatures,
    this.trailer,
    // NEW FIELDS in constructor (all optional)
    this.natisDocumentUrl,
    this.serviceHistoryUrl,
    this.frontImageUrl,
    this.sideImageUrl,
    this.tyresImageUrl,
    this.chassisImageUrl,
    this.makersPlateImageUrl,
    this.additionalImages,
    this.damagesCondition,
    this.damages,
    this.featuresCondition,
    this.features,
    this.deckImageUrl
  });

  /// Factory constructor to create a Vehicle instance from Firestore data.
  factory Vehicle.fromFirestore(String docId, Map<String, dynamic> data) {
    // Helper to safely get a String value.
    String getString(dynamic value) {
      return value is String ? value : '';
    }

    // Parse createdAt timestamp
    DateTime parsedCreatedAt = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();

    // Handle application list
    List<String> applications = [];
    if (data['application'] is List) {
      applications =
          (data['application'] as List).map((e) => e.toString()).toList();
    } else if (data['application'] is String) {
      applications = [data['application'] as String];
    }

    // Handle brands list
    List<String> brands = [];
    if (data['brands'] is List) {
      brands = (data['brands'] as List).map((e) => e.toString()).toList();
    } else if (data['brands'] is String) {
      brands = [data['brands'] as String];
    }

    // Get trailer type from either key (Firestore might use different casing)
    String trailerTypeValue =
        getString(data['trailerType'] ?? data['trailertype']);
    debugPrint(
        'DEBUG: In Vehicle.fromFirestore - extracted trailerType: $trailerTypeValue');

    // For trailer documents, if the vehicleType is "trailer", prepare the trailer data.
    Trailer? trailerObj;
    if (getString(data['vehicleType']).toLowerCase() == 'trailer') {
      // Get the nested trailerExtraInfo map.
      Map<String, dynamic> trailerExtraInfo = data['trailerExtraInfo'] ?? {};
      // If trailerExtraInfo is empty and this is a Superlink trailer, try to fall back
      // to top-level keys (for backward compatibility).
      if (trailerTypeValue == 'Superlink' && trailerExtraInfo.isEmpty) {
        debugPrint(
            'DEBUG: trailerExtraInfo is empty. Falling back to top-level superlink keys.');
        trailerExtraInfo = {
          'trailerA': {
            'length': getString(data['lengthTrailerA']),
            'vin': getString(data['vinA']),
            'registration': getString(data['registrationA']),
          },
          'trailerB': {
            'length': getString(data['lengthTrailerB']),
            'vin': getString(data['vinB']),
            'registration': getString(data['registrationB']),
          },
        };
      }
      debugPrint(
          'DEBUG: trailerExtraInfo to be passed to Trailer.fromFirestore: $trailerExtraInfo');
      // Merge trailerExtraInfo into the full data map for the trailer.
      Map<String, dynamic> trailerData = Map<String, dynamic>.from(data);
      trailerData['trailerExtraInfo'] = trailerExtraInfo;
      trailerObj = Trailer.fromFirestore(docId, trailerData);
    }

    return Vehicle(
      id: docId,
      isAccepted: data['isAccepted'] ?? false,
      acceptedOfferId: data['acceptedOfferId'] ?? '',
      assignedSalesRepId: getString(data['assignedSalesRepId']),
      application: applications,
      damageDescription: getString(data['damageDescription']),
      damagePhotos: data['damagePhotos'] != null
          ? List<String?>.from(data['damagePhotos'])
          : [],
      dashboardPhoto: getString(data['dashboardPhoto']),
      engineNumber: getString(data['engineNumber']),
      expectedSellingPrice: getString(data['sellingPrice']),
      faultCodesPhoto: getString(data['faultCodesPhoto']),
      hydraluicType: getString(data['hydraulics']),
      licenceDiskUrl: getString(data['licenceDiskUrl']),
      makeModel: getString(data['makeModel']),
      mileage: getString(data['mileage']),
      mileageImage: getString(data['mileageImage']),
      mainImageUrl: getString(data['mainImageUrl']),
      photos: data['photos'] != null ? List<String?>.from(data['photos']) : [],
      rc1NatisFile: getString(data['rc1NatisFile']),
      registrationNumber: getString(data['registrationNumber']),
      suspensionType: getString(data['suspensionType']),
      transmissionType: getString(data['transmissionType']),
      config: getString(data['config']),
      userId: getString(data['userId']),
      vehicleType: getString(data['vehicleType']),
      vinNumber: getString(data['vinNumber']),
      warrentyType: getString(data['warranty']),
      warrantyDetails: getString(data['warrantyDetails']),
      year: getString(data['year']),
      createdAt: parsedCreatedAt,
      vehicleStatus: getString(data['vehicleStatus']),
      vehicleAvailableImmediately:
          getString(data['vehicleAvailableImmediately']),
      availableDate: getString(data['availableDate']),
      adminData:
          data['adminData'] != null && data['adminData'] is Map<String, dynamic>
              ? AdminData.fromMap(data['adminData'])
              : AdminData(
                  settlementAmount: '0',
                  natisRc1Url: '',
                  licenseDiskUrl: '',
                  settlementLetterUrl: ''),
      maintenance: data['maintenance'] != null &&
              data['maintenance'] is Map<String, dynamic>
          ? Maintenance.fromMap(data['maintenance'])
          : Maintenance(
              vehicleId: docId,
              oemInspectionType: '',
              oemReason: '',
              maintenanceDocUrl: '',
              warrantyDocUrl: '',
              maintenanceSelection: '',
              warrantySelection: '',
              lastUpdated: DateTime.now(),
            ),
      truckConditions: data['truckConditions'] != null &&
              data['truckConditions'] is Map<String, dynamic>
          ? TruckConditions.fromMap(data['truckConditions'])
          : TruckConditions(
              externalCab: ExternalCab(
                damages: [],
                additionalFeatures: [],
                condition: '',
                damagesCondition: '',
                additionalFeaturesCondition: '',
                images: {},
              ),
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
                images: {
                  'Right Brake': '',
                  'Left Brake': '',
                  'Front Axel': '',
                  'Suspension': '',
                  'Fuel Tank': '',
                  'Battery': '',
                  'Cat Walk': '',
                  'Electrical Cable Black': '',
                  'Air Cable Yellow': '',
                  'Air Cable Red': '',
                  'Tail Board': '',
                  '5th Wheel': '',
                  'Left Brake Rear Axel': '',
                  'Right Brake Rear Axel': '',
                },
                damages: [],
                additionalFeatures: [],
                faultCodes: [],
              ),
              tyres: {
                'tyres': Tyres(
                  positions: data['tyres'] != null
                      ? Map<String, TyrePosition>.from(
                          (data['tyres'] as Map<String, dynamic>).map(
                              (key, value) => MapEntry(
                                  key,
                                  TyrePosition.fromMap(
                                      value as Map<String, dynamic>))))
                      : {},
                  lastUpdated: DateTime.now(),
                )
              },
            ),
      referenceNumber: getString(data['referenceNumber']),
      brands: brands,
      requireToSettleType: data['requireToSettleType'] as String?,
      country: getString(data['country'] ?? ''),
      province: getString(data['province'] ?? ''),
      variant: getString(data['variant'] ?? ''),
      damagesDescription: getString(data['damagesDescription'] ?? ''),
      additionalFeatures: getString(data['additionalFeatures'] ?? ''),
      trailer: trailerObj,
      // NEW FIELDS
      natisDocumentUrl: getString(data['natisDocumentUrl']),
      serviceHistoryUrl: getString(data['serviceHistoryUrl']),
      frontImageUrl: getString(data['frontImageUrl']),
      sideImageUrl: getString(data['sideImageUrl']),
      tyresImageUrl: getString(data['tyresImageUrl']),
      chassisImageUrl: getString(data['chassisImageUrl']),
      makersPlateImageUrl: getString(data['makersPlateImageUrl']),
      additionalImages: data['additionalImages'] != null
          ? List<String>.from(data['additionalImages'])
          : null,
      damagesCondition: getString(data['damagesCondition']),
      damages: data['damages'] != null
          ? List<Map<String, dynamic>>.from(data['damages'])
          : null,
      featuresCondition: getString(data['featuresCondition']),
      features: data['features'] != null
          ? List<Map<String, dynamic>>.from(data['features'])
          : null,
      trailerType: trailerTypeValue,
    );
  }

  /// Converts this Vehicle instance into a Map (for Firestore updates).
  Map<String, dynamic> toMap() {
    return {
      'application': application,
      'trailerType': trailerType, // Use consistent casing.
      'damageDescription': damageDescription,
      'damagePhotos': damagePhotos,
      'dashboardPhoto': dashboardPhoto,
      'engineNumber': engineNumber,
      'sellingPrice': expectedSellingPrice,
      'faultCodesPhoto': faultCodesPhoto,
      'hydraulics': hydraluicType,
      'licenceDiskUrl': licenceDiskUrl,
      'makeModel': makeModel,
      'mileage': mileage,
      'mileageImage': mileageImage,
      'mainImageUrl': mainImageUrl,
      'photos': photos,
      'rc1NatisFile': rc1NatisFile,
      'registrationNumber': registrationNumber,
      'suspensionType': suspensionType,
      'transmissionType': transmissionType,
      'config': config,
      'userId': userId,
      'vehicleType': vehicleType,
      'vinNumber': vinNumber,
      'warranty': warrentyType,
      'warrantyDetails': warrantyDetails,
      'year': year,
      'createdAt': Timestamp.fromDate(createdAt),
      'vehicleStatus': vehicleStatus,
      'vehicleAvailableImmediately': vehicleAvailableImmediately,
      'availableDate': availableDate,
      'adminData': adminData.toMap(),
      'maintenance': maintenance.toMap(),
      'truckConditions': truckConditions.toMap(),
      'referenceNumber': referenceNumber,
      'brands': brands,
      'requireToSettleType': requireToSettleType,
      'country': country,
      'variant': variant,
      'assignedSalesRepId': assignedSalesRepId,
      'damagesDescription': damagesDescription,
      'additionalFeatures': additionalFeatures,
      'trailer': trailer?.toMap(),
      // NEW FIELDS
      'natisDocumentUrl': natisDocumentUrl ?? '',
      'serviceHistoryUrl': serviceHistoryUrl ?? '',
      'frontImageUrl': frontImageUrl ?? '',
      'sideImageUrl': sideImageUrl ?? '',
      'tyresImageUrl': tyresImageUrl ?? '',
      'chassisImageUrl': chassisImageUrl ?? '',
      'makersPlateImageUrl': makersPlateImageUrl ?? '',
      'additionalImages': additionalImages ?? [],
      'damagesCondition': damagesCondition ?? '',
      'damages': damages ?? [],
      'featuresCondition': featuresCondition ?? '',
      'features': features ?? [],
    };
  }

  /// Factory constructor for convenience when you have a DocumentSnapshot.
  factory Vehicle.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Vehicle.fromFirestore(doc.id, data);
  }
}
