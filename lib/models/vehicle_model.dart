// class VehicleModel {
//   String? vehicleId;
//   String? referenceNumber;
//   String? makeModel;
//   String? coverPhotoUrl;
//   DateTime? createdAt;
//   DateTime? updatedAt;

//   // Basic Information
//   Map<String, dynamic> basicInfo = {};

//   // External Cab
//   Map<String, dynamic> externalCab = {
//     'condition': null,
//     'photos': {},
//     'damages': [],
//     'features': [],
//   };

//   // Internal Cab
//   Map<String, dynamic> internalCab = {
//     'condition': null,
//     'damages': [],
//     'features': [],
//     'faultCodes': [],
//   };

//   // Drive Train
//   Map<String, dynamic> driveTrain = {
//     'condition': null,
//     'engineLeaks': false,
//     'oilLeaks': false,
//     'engineBreaking': false,
//     'gearboxLeaking': false,
//     'gearboxNoise': false,
//     'damages': [],
//   };

//   // Chassis
//   Map<String, dynamic> chassis = {
//     'condition': null,
//     'damages': [],
//     'features': [],
//   };

//   // Tyres
//   Map<String, dynamic> tyres = {
//     'overallCondition': null,
//     'tyreConditions': {},
//     'rimTypes': {},
//     'damages': [],
//   };

//   // Maintenance
//   Map<String, dynamic> maintenance = {
//     'canSendToOEM': false,
//     'oemReason': '',
//     'maintenanceDocUrl': '',
//     'warrantyDocUrl': '',
//   };

//   // Admin
//   Map<String, dynamic> admin = {
//     'natisUrl': '',
//     'licenseDiskUrl': '',
//     'settlementLetterUrl': '',
//   };

//   VehicleModel({
//     this.vehicleId,
//     this.referenceNumber,
//     this.makeModel,
//     this.coverPhotoUrl,
//     this.createdAt,
//     this.updatedAt,
//   });

//   Map<String, dynamic> toJson() {
//     return {
//       'vehicleId': vehicleId,
//       'referenceNumber': referenceNumber,
//       'makeModel': makeModel,
//       'coverPhotoUrl': coverPhotoUrl,
//       'createdAt': createdAt?.toIso8601String(),
//       'updatedAt': updatedAt?.toIso8601String(),
//       'basicInfo': basicInfo,
//       'externalCab': externalCab,
//       'internalCab': internalCab,
//       'driveTrain': driveTrain,
//       'chassis': chassis,
//       'tyres': tyres,
//       'maintenance': maintenance,
//       'admin': admin,
//     };
//   }

//   factory VehicleModel.fromJson(Map<String, dynamic> json) {
//     return VehicleModel(
//       vehicleId: json['vehicleId'],
//       referenceNumber: json['referenceNumber'],
//       makeModel: json['makeModel'],
//       coverPhotoUrl: json['coverPhotoUrl'],
//       createdAt:
//           json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
//       updatedAt:
//           json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
//     )
//       ..basicInfo = json['basicInfo'] ?? {}
//       ..externalCab = json['externalCab'] ?? {}
//       ..internalCab = json['internalCab'] ?? {}
//       ..driveTrain = json['driveTrain'] ?? {}
//       ..chassis = json['chassis'] ?? {}
//       ..tyres = json['tyres'] ?? {}
//       ..maintenance = json['maintenance'] ?? {}
//       ..admin = json['admin'] ?? {};
//   }

//   VehicleModel copyWith({
//     String? vehicleId,
//     String? referenceNumber,
//     String? makeModel,
//     String? coverPhotoUrl,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//     Map<String, dynamic>? basicInfo,
//     Map<String, dynamic>? externalCab,
//     Map<String, dynamic>? internalCab,
//     Map<String, dynamic>? driveTrain,
//     Map<String, dynamic>? chassis,
//     Map<String, dynamic>? tyres,
//     Map<String, dynamic>? maintenance,
//     Map<String, dynamic>? admin,
//   }) {
//     return VehicleModel(
//       vehicleId: vehicleId ?? this.vehicleId,
//       referenceNumber: referenceNumber ?? this.referenceNumber,
//       makeModel: makeModel ?? this.makeModel,
//       coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//     )..basicInfo = basicInfo ?? this.basicInfo
//       ..externalCab = externalCab ?? this.externalCab
//       ..internalCab = internalCab ?? this.internalCab
//       ..driveTrain = driveTrain ?? this.driveTrain
//       ..chassis = chassis ?? this.chassis
//       ..tyres = tyres ?? this.tyres
//       ..maintenance = maintenance ?? this.maintenance
//       ..admin = admin ?? this.admin;
//   }
// }
