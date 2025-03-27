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
  final String? truckType;

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

  Vehicle(
      {this.trailerType,
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
      this.truckType,
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
      this.deckImageUrl});

  /// Factory constructor to create a Vehicle instance from Firestore data.
  factory Vehicle.fromFirestore(String docId, Map<String, dynamic> data) {
    // Helper to safely convert maps
    Map<String, dynamic> safeMap(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, dynamic>) return value;
      if (value is Map) {
        return value.map((key, value) => MapEntry(key.toString(), value));
      }
      return {};
    }

    // Helper to safely get a String value from any non-null input
    String getString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map) {
        return ''; // Return empty string for maps instead of converting them
      }
      return value.toString();
    }

    // Helper to safely convert list to List<String?>
    List<String?> getStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((item) => getString(item)).toList();
      }
      return [];
    }

    // Parse createdAt timestamp
    DateTime parsedCreatedAt = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();

    // Handle application list with more robust type checking
    List<String> applications = [];
    final appData = data['application'];
    if (appData is List) {
      applications = appData.map((e) => getString(e)).toList();
    } else if (appData != null) {
      applications = [getString(appData)];
    }

    // Handle brands list with more robust type checking
    List<String> brands = [];
    final brandsData = data['brands'];
    if (brandsData is List) {
      brands = brandsData.map((e) => getString(e)).toList();
    } else if (brandsData != null) {
      brands = [getString(brandsData)];
    }

    // Get trailer type with more robust type checking
    String trailerTypeValue =
        getString(data['trailerType'] ?? data['trailertype']);

    // For trailer documents, if the vehicleType is "trailer", prepare the trailer data.
    Trailer? trailerObj;
    if (getString(data['vehicleType']).toLowerCase() == 'trailer') {
      // Get the nested trailerExtraInfo map.
      Map<String, dynamic> trailerExtraInfo = safeMap(data['trailerExtraInfo']);
      // If trailerExtraInfo is empty and this is a Superlink trailer, try to fall back
      // to top-level keys (for backward compatibility).
      if (trailerTypeValue == 'Superlink' && trailerExtraInfo.isEmpty) {
        debugPrint(
            'DEBUG: trailerExtraInfo is empty. Falling back to top-level superlink keys.');
        trailerExtraInfo = {
          'trailerA': safeMap({
            'length': getString(data['lengthTrailerA']),
            'vin': getString(data['vinA']),
            'registration': getString(data['registrationA']),
          }),
          'trailerB': safeMap({
            'length': getString(data['lengthTrailerB']),
            'vin': getString(data['vinB']),
            'registration': getString(data['registrationB']),
          }),
        };
      }
      // debugPrint(
      //     'DEBUG: trailerExtraInfo to be passed to Trailer.fromFirestore: $trailerExtraInfo');
      // Merge trailerExtraInfo into the full data map for the trailer.
      Map<String, dynamic> trailerData = safeMap(data);
      trailerData['trailerExtraInfo'] = trailerExtraInfo;
      trailerObj = Trailer.fromFirestore(docId, trailerData);
    }

    return Vehicle(
      id: docId,
      isAccepted: data['isAccepted'] ?? false,
      acceptedOfferId: getString(data['acceptedOfferId']),
      assignedSalesRepId: getString(data['assignedSalesRepId']),
      application: applications,
      damageDescription: getString(data['damageDescription']),
      damagePhotos: getStringList(data['damagePhotos']),
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
      photos: getStringList(data['photos']),
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
      maintenance: data['maintenanceData'] != null &&
              data['maintenanceData'] is Map<String, dynamic>
          ? Maintenance.fromMap(data['maintenanceData'])
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
      truckType: getString(data['truckType']),
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
      'truckType': truckType,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isAccepted': isAccepted,
      'acceptedOfferId': acceptedOfferId,
      'makeModel': makeModel,
      'year': year,
      'application': application,
      'damageDescription': damageDescription,
      'damagePhotos': damagePhotos,
      'dashboardPhoto': dashboardPhoto,
      'engineNumber': engineNumber,
      'expectedSellingPrice': expectedSellingPrice,
      'faultCodesPhoto': faultCodesPhoto,
      'hydraluicType': hydraluicType,
      'licenceDiskUrl': licenceDiskUrl,
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
      'warrentyType': warrentyType,
      'warrantyDetails': warrantyDetails,
      'createdAt': createdAt.toIso8601String(),
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
      'province': province,
      'variant': variant,
      'damagesDescription': damagesDescription,
      'additionalFeatures': additionalFeatures,
      'trailer': trailer?.toMap(),
      'truckType': truckType,
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      isAccepted: json['isAccepted'] as bool,
      acceptedOfferId: json['acceptedOfferId'] as String?,
      makeModel: json['makeModel'] as String,
      year: json['year'] as String,
      application: List<String>.from(json['application']),
      damageDescription: json['damageDescription'] as String,
      damagePhotos: List<String?>.from(json['damagePhotos']),
      dashboardPhoto: json['dashboardPhoto'] as String,
      engineNumber: json['engineNumber'] as String,
      expectedSellingPrice: json['expectedSellingPrice'] as String,
      faultCodesPhoto: json['faultCodesPhoto'] as String,
      hydraluicType: json['hydraluicType'] as String,
      licenceDiskUrl: json['licenceDiskUrl'] as String,
      mileage: json['mileage'] as String,
      mileageImage: json['mileageImage'] as String,
      mainImageUrl: json['mainImageUrl'] as String?,
      photos: List<String?>.from(json['photos']),
      rc1NatisFile: json['rc1NatisFile'] as String,
      registrationNumber: json['registrationNumber'] as String,
      suspensionType: json['suspensionType'] as String,
      transmissionType: json['transmissionType'] as String,
      config: json['config'] as String,
      userId: json['userId'] as String,
      vehicleType: json['vehicleType'] as String,
      vinNumber: json['vinNumber'] as String,
      warrentyType: json['warrentyType'] as String,
      warrantyDetails: json['warrantyDetails'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      vehicleStatus: json['vehicleStatus'] as String,
      vehicleAvailableImmediately:
          json['vehicleAvailableImmediately'] as String,
      availableDate: json['availableDate'] as String,
      adminData: AdminData.fromMap(json['adminData'] as Map<String, dynamic>),
      maintenance:
          Maintenance.fromMap(json['maintenance'] as Map<String, dynamic>),
      truckConditions: TruckConditions.fromMap(
          json['truckConditions'] as Map<String, dynamic>),
      referenceNumber: json['referenceNumber'] as String,
      brands: List<String>.from(json['brands']),
      requireToSettleType: json['requireToSettleType'] as String?,
      country: json['country'] as String,
      province: json['province'] as String,
      variant: json['variant'] as String?,
      damagesDescription: json['damagesDescription'] as String,
      additionalFeatures: json['additionalFeatures'] as String,
      trailer: json['trailer'] != null
          ? Trailer.fromJson(json['trailer'] as Map<String, dynamic>)
          : null,
      truckType: json['truckType'] as String?,
    );
  }
}
