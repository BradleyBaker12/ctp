// import 'dart:io';

// class VehicleFormModel {
//   String? vehicleId;
//   String? brand;
//   String? makeModel;
//   String? year;
//   String? mileage;
//   String? vinNumber;
//   String? engineNumber;
//   String? registrationNumber;
//   String? expectedSellingPrice;
//   String? warrantyDetails;
//   String? referenceNumber;
//   String? vehicleType;
//   String? configuration;
//   String? suspension;
//   String? transmission;
//   bool? hasHydraulics;
//   bool? hasMaintenance;
//   bool? hasWarranty;
//   bool? requiresSettlement;
//   File? coverPhoto;
//   String? coverPhotoUrl;
//   File? natisRc1File;
//   DateTime? createdAt;
//   DateTime? updatedAt;

//   // Add form section completion flags
//   bool isBasicInfoComplete = false;
//   bool isExternalCabComplete = false;
//   bool isInternalCabComplete = false;
//   bool isDriveTrainComplete = false;
//   bool isChassisComplete = false;
//   bool isTyresComplete = false;

//   bool isSaving = false;

//   Map<String, dynamic>? chassis;
//   Map<String, dynamic>? driveTrain;
//   Map<String, dynamic>? tyres;

//   VehicleFormModel({
//     this.vehicleId,
//     this.brand,
//     this.makeModel,
//     this.year,
//     this.mileage,
//     this.isSaving = false,
//     this.chassis,
//     this.driveTrain,
//     this.tyres,
//     // ... add other fields
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'vehicleId': vehicleId,
//       'brand': brand,
//       'makeModel': makeModel,
//       'year': year,
//       // ... add other fields
//       'isBasicInfoComplete': isBasicInfoComplete,
//       'isExternalCabComplete': isExternalCabComplete,
//       'isInternalCabComplete': isInternalCabComplete,
//       'isDriveTrainComplete': isDriveTrainComplete,
//       'isChassisComplete': isChassisComplete,
//       'isTyresComplete': isTyresComplete,
//       'chassis': chassis,
//       'driveTrain': driveTrain,
//       'tyres': tyres,
//     };
//   }

//   factory VehicleFormModel.fromMap(Map<String, dynamic> map) {
//     return VehicleFormModel(
//       vehicleId: map['vehicleId'],
//       brand: map['brand'],
//       makeModel: map['makeModel'],
//       // ... add other fields
//       chassis: map['chassis'],
//       driveTrain: map['driveTrain'],
//       tyres: map['tyres'],
//     );
//   }

//   VehicleFormModel copyWith({
//     String? vehicleId,
//     String? brand,
//     String? makeModel,
//     String? year,
//     String? mileage,
//     bool? isSaving,
//     Map<String, dynamic>? chassis,
//     Map<String, dynamic>? driveTrain,
//     Map<String, dynamic>? tyres,
//     // ... other fields
//   }) {
//     return VehicleFormModel(
//       vehicleId: vehicleId ?? this.vehicleId,
//       brand: brand ?? this.brand,
//       makeModel: makeModel ?? this.makeModel,
//       year: year ?? this.year,
//       mileage: mileage ?? this.mileage,
//       isSaving: isSaving ?? this.isSaving,
//       chassis: chassis ?? this.chassis,
//       driveTrain: driveTrain ?? this.driveTrain,
//       tyres: tyres ?? this.tyres,
//       // ... other fields
//     );
//   }

//   Future<void> saveForm() async {
//     isSaving = true;
//     // Add your saving logic here
//     // For example: API calls, database operations, etc.
//     await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
//     isSaving = false;
//   }
// }
