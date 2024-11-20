// lib/models/vehicle.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/models/chassis.dart';
import 'package:ctp/models/drive_train.dart';
import 'package:ctp/models/external_cab.dart';
import 'package:ctp/models/internal_cab.dart';
import 'package:ctp/models/maintenance_data.dart';
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
  String? natisRc1Url; // Ensure this field exists
  final String referenceNumber;
  // In Vehicle class
  final List<String> brands;

  final String? requireToSettleType;
  final String country;

  // Nested Objects
  final AdminData adminData;
  final Maintenance maintenance;
  final TruckConditions truckConditions;

  Vehicle({
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
  });
  // Factory constructor to create a Vehicle instance from Firestore data
  factory Vehicle.fromFirestore(String docId, Map<String, dynamic> data) {
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

    // Helper function to safely get a String from data
    String getString(dynamic value, [String fieldName = '']) {
      if (value is String) {
        return value;
      }
      return '';
    }

    return Vehicle(
      id: docId,
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
              maintenanceDocumentUrl: '',
              warrantyDocumentUrl: '',
              oemInspectionType: '',
              oemInspectionReason: '',
              updatedAt: DateTime.now(),
              maintenanceData: MaintenanceData(
                vehicleId: docId,
                oemInspectionType: '',
                oemReason: '',
              ),
              warrantySelection: '',
            ),
      truckConditions: data['truckConditions'] != null &&
              data['truckConditions'] is Map<String, dynamic>
          ? TruckConditions.fromMap(data['truckConditions'])
          : TruckConditions(
              externalCab: ExternalCab(
                selectedCondition: '',
                anyDamages: '',
                anyAdditionalFeatures: '',
                photos: {
                  'FRONT VIEW': '',
                  'RIGHT SIDE VIEW': '',
                  'REAR VIEW': '',
                  'LEFT SIDE VIEW': '',
                },
                lastUpdated: DateTime.now(),
                damages: [],
                additionalFeatures: [],
              ),
              internalCab: InternalCab(
                condition: '',
                oemInspectionType: '',
                oemInspectionReason: '',
                lastUpdated: DateTime.now(),
                photos: {
                  'Center Dash': '',
                  'Left Dash': '',
                  'Right Dash (Vehicle On)': '',
                  'Mileage': '',
                  'Sun Visors': '',
                  'Center Console': '',
                  'Steering': '',
                  'Left Door Panel': '',
                  'Left Seat': '',
                  'Roof': '',
                  'Bunk Beds': '',
                  'Rear Panel': '',
                  'Right Door Panel': '',
                  'Right Seat': '',
                },
                damages: [],
                additionalFeatures: [],
                faultCodes: [],
              ),
              chassis: Chassis(
                condition: '',
                damagesCondition: '',
                additionalFeaturesCondition: '',
                photos: {
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
                lastUpdated: DateTime.now(),
                damages: [],
                additionalFeatures: [],
                faultCodes: [],
              ),
              driveTrain: DriveTrain(
                condition: '',
                oilLeakConditionEngine: '',
                waterLeakConditionEngine: '',
                blowbyCondition: '',
                oilLeakConditionGearbox: '',
                retarderCondition: '',
                lastUpdated: DateTime.now(),
                photos: {
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
              tyres: data['tyres'] ?? {},
            ),
      referenceNumber: data['referenceNumber'] ?? '',
      brands: brands,
      requireToSettleType: data['requireToSettleType'] as String?,
      country: getString(data['country'] ?? ''),
    );
  }
  // Method to convert Vehicle instance to a Map (for Firestore updates)
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
      createdAt: parsedCreatedAt,
      application: applications,
      brands: brands,
      warrantyDetails: data['warrantyDetails'] ?? 'N/A',
      damageDescription: data['damageDescription'] ?? '',
      damagePhotos: data['damagePhotos'] != null
          ? List<String?>.from(data['damagePhotos'])
          : [],
      dashboardPhoto: data['dashboardPhoto'] ?? '',
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
              maintenanceDocumentUrl: '',
              warrantyDocumentUrl: '',
              oemInspectionType: '',
              oemInspectionReason: '',
              updatedAt: DateTime.now(),
              maintenanceData: MaintenanceData(
                vehicleId: doc.id, // Use the passed docId
                oemInspectionType: '',
                oemReason: '',
              ),
              warrantySelection: '',
            ),
      truckConditions: data['truckConditions'] != null &&
              data['truckConditions'] is Map<String, dynamic>
          ? TruckConditions.fromMap(data['truckConditions'])
          : TruckConditions(
              externalCab: ExternalCab(
                selectedCondition: '',
                anyDamages: '',
                anyAdditionalFeatures: '',
                photos: {
                  'FRONT VIEW': '',
                  'RIGHT SIDE VIEW': '',
                  'REAR VIEW': '',
                  'LEFT SIDE VIEW': '',
                },
                lastUpdated: DateTime.now(),
                damages: [],
                additionalFeatures: [],
              ),
              internalCab: InternalCab(
                condition: '',
                oemInspectionType: '',
                oemInspectionReason: '',
                lastUpdated: DateTime.now(),
                photos: {
                  'Center Dash': '',
                  'Left Dash': '',
                  'Right Dash (Vehicle On)': '',
                  'Mileage': '',
                  'Sun Visors': '',
                  'Center Console': '',
                  'Steering': '',
                  'Left Door Panel': '',
                  'Left Seat': '',
                  'Roof': '',
                  'Bunk Beds': '',
                  'Rear Panel': '',
                  'Right Door Panel': '',
                  'Right Seat': '',
                },
                damages: [],
                additionalFeatures: [],
                faultCodes: [],
              ),
              chassis: Chassis(
                condition: '',
                damagesCondition: '',
                additionalFeaturesCondition: '',
                photos: {
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
                lastUpdated: DateTime.now(),
                damages: [],
                additionalFeatures: [],
                faultCodes: [],
              ),
              driveTrain: DriveTrain(
                condition: '',
                oilLeakConditionEngine: '',
                waterLeakConditionEngine: '',
                blowbyCondition: '',
                oilLeakConditionGearbox: '',
                retarderCondition: '',
                lastUpdated: DateTime.now(),
                photos: {
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
              tyres: data['tyres'] ?? {},
            ),
      referenceNumber: data['referenceNumber'] ?? '',
      requireToSettleType: data['requireToSettleType'] as String?,
      country: data['country'] ?? 'N/A',
    );
  }
  factory Vehicle.fromMap(Map<String, dynamic> data) {
    return Vehicle(
      id: data['id'] ?? '',
      referenceNumber: data['referenceNumber'] ?? '',
      makeModel: data['makeModel'] ?? 'N/A',
      mainImageUrl: data['mainImageUrl'] ?? '',
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
              maintenanceDocumentUrl: '',
              warrantyDocumentUrl: '',
              oemInspectionType: '',
              oemInspectionReason: '',
              updatedAt: DateTime.now(),
              maintenanceData: MaintenanceData(
                vehicleId: data['id'] ?? '',
                oemInspectionType: '',
                oemReason: '',
              ),
              warrantySelection: '',
            ),
      truckConditions: data['truckConditions'] != null &&
              data['truckConditions'] is Map<String, dynamic>
          ? TruckConditions.fromMap(data['truckConditions'])
          : TruckConditions(
              externalCab: ExternalCab(
                selectedCondition: '',
                anyDamages: '',
                anyAdditionalFeatures: '',
                photos: {
                  'FRONT VIEW': '',
                  'RIGHT SIDE VIEW': '',
                  'REAR VIEW': '',
                  'LEFT SIDE VIEW': '',
                },
                lastUpdated: DateTime.now(),
                damages: [],
                additionalFeatures: [],
              ),
              internalCab: InternalCab(
                condition: '',
                oemInspectionType: '',
                oemInspectionReason: '',
                lastUpdated: DateTime.now(),
                photos: {
                  'Center Dash': '',
                  'Left Dash': '',
                  'Right Dash (Vehicle On)': '',
                  'Mileage': '',
                  'Sun Visors': '',
                  'Center Console': '',
                  'Steering': '',
                  'Left Door Panel': '',
                  'Left Seat': '',
                  'Roof': '',
                  'Bunk Beds': '',
                  'Rear Panel': '',
                  'Right Door Panel': '',
                  'Right Seat': '',
                },
                damages: [],
                additionalFeatures: [],
                faultCodes: [],
              ),
              chassis: Chassis(
                condition: '',
                damagesCondition: '',
                additionalFeaturesCondition: '',
                photos: {
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
                lastUpdated: DateTime.now(),
                damages: [],
                additionalFeatures: [],
                faultCodes: [],
              ),
              driveTrain: DriveTrain(
                condition: '',
                oilLeakConditionEngine: '',
                waterLeakConditionEngine: '',
                blowbyCondition: '',
                oilLeakConditionGearbox: '',
                retarderCondition: '',
                lastUpdated: DateTime.now(),
                photos: {
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
              tyres: data['tyres'] ?? {},
            ),
      brands: data['brands'] ?? '',
      country: data['country'] ?? 'N/A',
    );
  }
}
