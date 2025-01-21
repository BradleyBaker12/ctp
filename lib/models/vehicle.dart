// lib/models/vehicle.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/models/chassis.dart';
import 'package:ctp/models/drive_train.dart';
import 'package:ctp/models/external_cab.dart';
import 'package:ctp/models/internal_cab.dart';
import 'package:ctp/models/tyres.dart';
import 'admin_data.dart';
import 'maintenance.dart';
import 'truck_conditions.dart';

class Vehicle {
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
  final String trailerType;
  final String axles;
  final String trailerLength;
  String? natisRc1Url;
  final String referenceNumber;
  final String length;
  final String vinTrailer;
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

  // ------------------------------
  // NEW FIELDS (all optional):
  // ------------------------------
  final String? natisDocumentUrl;
  final String? serviceHistoryUrl;
  final String? frontImageUrl;
  final String? sideImageUrl;
  final String? tyresImageUrl;
  final String? chassisImageUrl;
  final String? deckImageUrl;
  final String? makersPlateImageUrl;
  final List<String>? additionalImages;
  final String? damagesCondition;
  final List<Map<String, dynamic>>? damages;
  final String? featuresCondition;
  final List<Map<String, dynamic>>? features;

  Vehicle({
    this.assignedSalesRepId,
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
    required this.trailerType,
    required this.axles,
    required this.trailerLength,
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
    required this.length,
    required this.vinTrailer,
    required this.damagesDescription,
    required this.additionalFeatures,

    // NEW FIELDS in constructor (all optional)
    this.natisDocumentUrl,
    this.serviceHistoryUrl,
    this.frontImageUrl,
    this.sideImageUrl,
    this.tyresImageUrl,
    this.chassisImageUrl,
    this.deckImageUrl,
    this.makersPlateImageUrl,
    this.additionalImages,
    this.damagesCondition,
    this.damages,
    this.featuresCondition,
    this.features,
  });

  // ---------------------------------------------------------------------------
  // Factory constructor to create a Vehicle instance from Firestore data
  // (docId + Map<String, dynamic> data). Existing code preserved; we only add
  // the new fields with getString(...) / condition checks below.
  // ---------------------------------------------------------------------------
  factory Vehicle.fromFirestore(String docId, Map<String, dynamic> data) {
    print('''
  === VEHICLE DEBUG ===
  DocID: $docId
  Brand: ${data['brands']}
  MakeModel: ${data['makeModel']}
  MainImage: ${data['mainImageUrl']}
    ''');

    // Handle timestamp
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

    // Helper function to safely get a String
    String getString(dynamic value, [String fieldName = '']) {
      if (value is String) {
        return value;
      }
      return '';
    }

    // ---- NEW HELPER for additionalImages (List<String>) ----
    List<String>? parseAdditionalImages() {
      if (data['additionalImages'] != null &&
          data['additionalImages'] is List) {
        return List<String>.from(data['additionalImages']);
      }
      return null;
    }

    // ---- NEW HELPER for damages/features arrays of maps ----
    List<Map<String, dynamic>>? parseMapList(dynamic val) {
      if (val != null && val is List) {
        return List<Map<String, dynamic>>.from(val);
      }
      return null;
    }

    return Vehicle(
      id: docId,
      assignedSalesRepId: getString(data['assignedSalesRepId']),
      application: applications,
      length: getString(data['length']),
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
      trailerType: getString(data['trailerType']),
      axles: getString(data['axles']),
      trailerLength: getString(data['trailerLength']),
      adminData:
          data['adminData'] != null && data['adminData'] is Map<String, dynamic>
              ? AdminData.fromMap(data['adminData'])
              : AdminData(
                  settlementAmount: '0',
                  natisRc1Url: '',
                  licenseDiskUrl: '',
                  settlementLetterUrl: '',
                ),
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
      truckConditions: TruckConditions(
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
                ? Map<String, TyrePosition>.from((data['tyres']
                        as Map<String, dynamic>)
                    .map((key, value) => MapEntry(key,
                        TyrePosition.fromMap(value as Map<String, dynamic>))))
                : {},
            lastUpdated: DateTime.now(),
          )
        },
      ),
      referenceNumber: data['referenceNumber'] ?? '',
      brands: brands,
      requireToSettleType: data['requireToSettleType'] as String?,
      country: getString(data['country'] ?? ''),
      province: getString(data['province'] ?? ''),
      variant: getString(data['variant'] ?? ''),
      vinTrailer: getString(data['vinTrailer'] ?? ''),
      damagesDescription: getString(data['damagesDescription'] ?? ''),
      additionalFeatures: getString(data['additionalFeatures'] ?? ''),

      // ------------------------------
      // ADDED NEW FIELDS
      // ------------------------------
      natisDocumentUrl: getString(data['natisDocumentUrl']),
      serviceHistoryUrl: getString(data['serviceHistoryUrl']),
      frontImageUrl: getString(data['frontImageUrl']),
      sideImageUrl: getString(data['sideImageUrl']),
      tyresImageUrl: getString(data['tyresImageUrl']),
      chassisImageUrl: getString(data['chassisImageUrl']),
      deckImageUrl: getString(data['deckImageUrl']),
      makersPlateImageUrl: getString(data['makersPlateImageUrl']),
      additionalImages: parseAdditionalImages(),
      damagesCondition: getString(data['damagesCondition']),
      damages: parseMapList(data['damages']),
      featuresCondition: getString(data['featuresCondition']),
      features: parseMapList(data['features']),
    );
  }

  // ---------------------------------------------------------------------------
  // Method to convert Vehicle instance to a Map (for Firestore updates)
  // Original code preserved, plus we add the new fields at the bottom.
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'application': application,
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
      'trailerType': trailerType,
      'axles': axles,
      'trailerLength': trailerLength,
      'adminData': adminData.toMap(),
      'maintenance': maintenance.toMap(),
      'truckConditions': truckConditions.toMap(),
      'referenceNumber': referenceNumber,
      'brands': brands,
      'requireToSettleType': requireToSettleType,
      'country': country,
      'variant': variant,
      'assignedSalesRepId': assignedSalesRepId,

      // Existing line not to remove
      'length': length,

      // ----------------------------------------------------------------
      // NEW FIELDS appended at the bottom (unchanged existing code above)
      // ----------------------------------------------------------------
      'natisDocumentUrl': natisDocumentUrl ?? '',
      'serviceHistoryUrl': serviceHistoryUrl ?? '',
      'frontImageUrl': frontImageUrl ?? '',
      'sideImageUrl': sideImageUrl ?? '',
      'tyresImageUrl': tyresImageUrl ?? '',
      'chassisImageUrl': chassisImageUrl ?? '',
      'deckImageUrl': deckImageUrl ?? '',
      'makersPlateImageUrl': makersPlateImageUrl ?? '',
      'additionalImages': additionalImages ?? [],
      'damagesCondition': damagesCondition ?? '',
      'damages': damages ?? [],
      'featuresCondition': featuresCondition ?? '',
      'features': features ?? [],
      // done
    };
  }

  factory Vehicle.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse createdAt timestamp
    DateTime parsedCreatedAt;
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      parsedCreatedAt = (data['createdAt'] as Timestamp).toDate();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    // Parse application field
    List<String> applications = [];
    if (data['application'] is List) {
      applications =
          (data['application'] as List).map((e) => e.toString()).toList();
    } else if (data['application'] is String) {
      applications = [data['application'] as String];
    }

    // Parse brands field
    List<String> brands = [];
    if (data['brands'] is List) {
      brands = (data['brands'] as List).map((e) => e.toString()).toList();
    } else if (data['brands'] is String) {
      brands = [data['brands'] as String];
    }

    return Vehicle(
      id: doc.id,
      assignedSalesRepId: data['assignedSalesRepId'] ?? '',
      createdAt: parsedCreatedAt,
      application: applications,
      brands: brands,
      vinTrailer: data['vinTrailer'] ?? '',
      damagesDescription: data['damagesDescription'] ?? '',
      additionalFeatures: data['additionalFeatures'] ?? '',
      warrantyDetails: data['warrantyDetails'] ?? 'N/A',
      damageDescription: data['damageDescription'] ?? '',
      damagePhotos: data['damagePhotos'] != null
          ? List<String?>.from(data['damagePhotos'])
          : [],
      dashboardPhoto: data['dashboardPhoto'] ?? '',
      length: data['length'] ?? '',
      engineNumber: data['engineNumber'] ?? 'N/A',
      expectedSellingPrice: data['sellingPrice'] ?? 'N/A',
      faultCodesPhoto: data['faultCodesPhoto'] ?? '',
      hydraluicType: data['hydraulics'] ?? 'N/A',
      licenceDiskUrl: data['licenceDiskUrl'] ?? '',
      makeModel: data['makeModel'] ?? 'N/A',
      mileage: data['mileage'] ?? 'N/A',
      mileageImage: data['mileageImage'] ?? '',
      mainImageUrl: data['mainImageUrl'],
      photos: data['photos'] != null ? List<String?>.from(data['photos']) : [],
      rc1NatisFile: data['rc1NatisFile'] ?? '',
      registrationNumber: data['registrationNumber'] ?? 'N/A',
      suspensionType: data['suspensionType'] ?? 'N/A',
      transmissionType: data['transmissionType'] ?? 'N/A',
      config: data['config'] ?? '',
      userId: data['userId'] ?? 'N/A',
      vehicleType: data['vehicleType'] ?? 'N/A',
      vinNumber: data['vinNumber'] ?? 'N/A',
      warrentyType: data['warranty'] ?? 'N/A',
      year: data['year'] ?? 'N/A',
      vehicleStatus: data['vehicleStatus'] ?? 'Live',
      vehicleAvailableImmediately: data['vehicleAvailableImmediately'] ?? '',
      availableDate: data['availableDate'] ?? '',
      trailerType: data['trailerType'] ?? '',
      axles: data['axles'] ?? '',
      trailerLength: data['trailerLength'] ?? '',
      adminData:
          data['adminData'] != null && data['adminData'] is Map<String, dynamic>
              ? AdminData.fromMap(data['adminData'])
              : AdminData(
                  settlementAmount: '0',
                  natisRc1Url: '',
                  licenseDiskUrl: '',
                  settlementLetterUrl: '',
                ),
      maintenance: data['maintenance'] != null &&
              data['maintenance'] is Map<String, dynamic>
          ? Maintenance.fromMap(data['maintenance'])
          : Maintenance(
              vehicleId: doc.id,
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
      referenceNumber: data['referenceNumber'] ?? '',
      requireToSettleType: data['requireToSettleType'] as String?,
      country: data['country'] ?? 'N/A',
      province: data['province'] ?? 'N/A',
      variant: data['variant'] ?? '',

      // ------------------------------
      // ADDED NEW FIELDS
      // ------------------------------
      natisDocumentUrl: data['natisDocumentUrl'],
      serviceHistoryUrl: data['serviceHistoryUrl'],
      frontImageUrl: data['frontImageUrl'],
      sideImageUrl: data['sideImageUrl'],
      tyresImageUrl: data['tyresImageUrl'],
      chassisImageUrl: data['chassisImageUrl'],
      deckImageUrl: data['deckImageUrl'],
      makersPlateImageUrl: data['makersPlateImageUrl'],
      additionalImages: data['additionalImages'] != null
          ? List<String>.from(data['additionalImages'])
          : null,
      damagesCondition: data['damagesCondition'],
      damages: data['damages'] != null
          ? List<Map<String, dynamic>>.from(data['damages'])
          : null,
      featuresCondition: data['featuresCondition'],
      features: data['features'] != null
          ? List<Map<String, dynamic>>.from(data['features'])
          : null,
    );
  }

  factory Vehicle.fromMap(Map<String, dynamic> data) {
    return Vehicle(
      id: data['id'] ?? '',
      assignedSalesRepId: data['assignedSalesRepId'] ?? '',
      referenceNumber: data['referenceNumber'] ?? '',
      vinTrailer: data['vinTrailer'] ?? '',
      damagesDescription: data['damagesDescription'] ?? '',
      additionalFeatures: data['additionalFeatures'] ?? '',
      makeModel: data['makeModel'] ?? 'N/A',
      mainImageUrl: data['mainImageUrl'] ?? '',
      length: data['length'] ?? '',
      application: data['application'] ?? 'N/A',
      damageDescription: data['damageDescription'] ?? '',
      damagePhotos: data['damagePhotos'] != null
          ? List<String?>.from(data['damagePhotos'])
          : [],
      dashboardPhoto: data['dashboardPhoto'] ?? '',
      engineNumber: data['engineNumber'] ?? 'N/A',
      expectedSellingPrice: data['expectedSellingPrice'] ?? 'N/A',
      faultCodesPhoto: data['faultCodesPhoto'] ?? '',
      hydraluicType: data['hydraluicType'] ?? 'N/A',
      licenceDiskUrl: data['licenceDiskUrl'] ?? '',
      mileage: data['mileage'] ?? 'N/A',
      mileageImage: data['mileageImage'] ?? '',
      photos: data['photos'] != null ? List<String?>.from(data['photos']) : [],
      rc1NatisFile: data['rc1NatisFile'] ?? '',
      registrationNumber: data['registrationNumber'] ?? 'N/A',
      suspensionType: data['suspensionType'] ?? 'N/A',
      transmissionType: data['transmissionType'] ?? 'N/A',
      config: data['config'] ?? '',
      userId: data['userId'] ?? 'N/A',
      vehicleType: data['vehicleType'] ?? 'N/A',
      vinNumber: data['vinNumber'] ?? 'N/A',
      warrentyType: data['warrentyType'] ?? 'N/A',
      warrantyDetails: data['warrantyDetails'] ?? 'N/A',
      year: data['year'] ?? 'N/A',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      vehicleStatus: data['vehicleStatus'] ?? 'Live',
      vehicleAvailableImmediately: data['vehicleAvailableImmediately'] ?? '',
      availableDate: data['availableDate'] ?? '',
      trailerType: data['trailerType'] ?? '',
      axles: data['axles'] ?? '',
      trailerLength: data['trailerLength'] ?? '',
      adminData:
          data['adminData'] != null && data['adminData'] is Map<String, dynamic>
              ? AdminData.fromMap(data['adminData'])
              : AdminData(
                  settlementAmount: '0',
                  natisRc1Url: '',
                  licenseDiskUrl: '',
                  settlementLetterUrl: '',
                ),
      maintenance: data['maintenance'] != null &&
              data['maintenance'] is Map<String, dynamic>
          ? Maintenance.fromMap(data['maintenance'])
          : Maintenance(
              vehicleId: data['id'] ?? '',
              oemInspectionType: data['oemInspectionType'] ?? '',
              oemReason: data['oemReason'] ?? '',
              maintenanceDocUrl: data['maintenanceDocUrl'] ?? '',
              warrantyDocUrl: data['warrantyDocUrl'] ?? '',
              maintenanceSelection: data['maintenanceSelection'] ?? '',
              warrantySelection: data['warrantySelection'] ?? '',
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
      brands: data['brands'] ?? '',
      country: data['country'] ?? 'N/A',
      province: data['province'] ?? 'N/A',
      variant: data['variant'] ?? '',

      // ------------------------------
      // ADDED NEW FIELDS
      // ------------------------------
      natisDocumentUrl: data['natisDocumentUrl'],
      serviceHistoryUrl: data['serviceHistoryUrl'],
      frontImageUrl: data['frontImageUrl'],
      sideImageUrl: data['sideImageUrl'],
      tyresImageUrl: data['tyresImageUrl'],
      chassisImageUrl: data['chassisImageUrl'],
      deckImageUrl: data['deckImageUrl'],
      makersPlateImageUrl: data['makersPlateImageUrl'],
      additionalImages: data['additionalImages'] != null
          ? List<String>.from(data['additionalImages'])
          : null,
      damagesCondition: data['damagesCondition'],
      damages: data['damages'] != null
          ? List<Map<String, dynamic>>.from(data['damages'])
          : null,
      featuresCondition: data['featuresCondition'],
      features: data['features'] != null
          ? List<Map<String, dynamic>>.from(data['features'])
          : null,
    );
  }
}
