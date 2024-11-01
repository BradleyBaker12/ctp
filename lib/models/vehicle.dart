// lib/models/vehicle.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/models/chassis.dart';
import 'package:ctp/models/drive_train.dart';
import 'package:ctp/models/external_cab.dart';
import 'package:ctp/models/internal_cab.dart';
import 'package:ctp/models/maintenance_data.dart';
import 'package:ctp/models/tyres.dart';
import 'admin_data.dart';
import 'maintenance.dart';
import 'truck_conditions.dart';

class Vehicle {
  final String id;
  final String application;
  final String damageDescription;
  final List<String?> damagePhotos;
  final String dashboardPhoto;
  final String engineNumber;
  final String expectedSellingPrice;
  final String faultCodesPhoto;
  final String hydraluicType;
  final String licenceDiskUrl;
  final String makeModel;
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
  final String year;
  final DateTime createdAt;
  final String vehicleStatus;
  final String vehicleAvailableImmediately;
  final String availableDate;
  final String trailerType;
  final String axles;
  final String trailerLength;
  String? natisRc1Url; // Ensure this field exists

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
  });

  // Factory constructor to create a Vehicle instance from Firestore data
  factory Vehicle.fromFirestore(String docId, Map<String, dynamic> data) {
    // Parse the 'createdAt' field
    DateTime parsedCreatedAt;
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      parsedCreatedAt = (data['createdAt'] as Timestamp).toDate();
    } else {
      print(
          "Warning: Timestamp is null or invalid for vehicle ID $docId. Using DateTime.now() as default.");
      parsedCreatedAt = DateTime.now();
    }

    return Vehicle(
      id: docId, // Use the Firestore document ID
      application: data['application'] ?? 'N/A',
      warrantyDetails: data['warrantyDetails'] ?? 'N/A',
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
      makeModel: data['makeModel'] ?? 'N/A',
      mileage: data['mileage'] ?? 'N/A',
      mileageImage: data['mileageImage'] ?? '',
      mainImageUrl: data['mainImageUrl'],
      photos: data['photos'] != null ? List<String?>.from(data['photos']) : [],
      rc1NatisFile: data['rc1NatisFile'] ?? '',
      registrationNumber: data['registrationNumber'] ?? 'N/A',
      suspensionType: data['suspensionType'] ?? 'N/A',
      transmissionType: data['transmissionType'] ?? 'N/A',
      config: data['configuration'] ?? '',
      userId: data['userId'] ?? 'N/A',
      vehicleType: data['vehicleType'] ?? 'N/A',
      vinNumber: data['vinNumber'] ?? 'N/A',
      warrentyType: data['warrentyType'] ?? 'N/A',
      year: data['year'] ?? 'N/A',
      createdAt: parsedCreatedAt,
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
                vehicleId: docId, // Use the passed docId
                oemInspectionType: '',
                oemReason: '',
              ),
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
              tyres: Tyres(
                chassisCondition: '',
                virginOrRecap: '',
                rimType: '',
                lastUpdated: DateTime.now(),
                photos: {
                  'Tyre_Pos_1 Photo': '',
                  'Tyre_Pos_2 Photo': '',
                  'Tyre_Pos_3 Photo': '',
                  'Tyre_Pos_4 Photo': '',
                  'Tyre_Pos_5 Photo': '',
                  'Tyre_Pos_6 Photo': '',
                },
              ),
            ),
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
      'expectedSellingPrice': expectedSellingPrice,
      'faultCodesPhoto': faultCodesPhoto,
      'hydraluicType': hydraluicType,
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
      'warrentyType': warrentyType,
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
    };
  }
}
