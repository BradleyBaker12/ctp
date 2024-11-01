// lib/models/truck_conditions.dart

import 'external_cab.dart';
import 'internal_cab.dart';
import 'chassis.dart';
import 'drive_train.dart';
import 'tyres.dart';

class TruckConditions {
  final ExternalCab externalCab;
  final InternalCab internalCab;
  final Chassis chassis;
  final DriveTrain driveTrain;
  final Tyres tyres;

  TruckConditions({
    required this.externalCab,
    required this.internalCab,
    required this.chassis,
    required this.driveTrain,
    required this.tyres,
  });

  factory TruckConditions.fromMap(Map<String, dynamic> data) {
    return TruckConditions(
      externalCab: ExternalCab.fromMap(data['ExternalCab'] ?? {}),
      internalCab: InternalCab.fromMap(data['InternalCab'] ?? {}),
      chassis: Chassis.fromMap(data['Chassis'] ?? {}),
      driveTrain: DriveTrain.fromMap(data['DriveTrain'] ?? {}),
      tyres: Tyres.fromMap(data['Tyres'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ExternalCab': externalCab.toMap(),
      'InternalCab': internalCab.toMap(),
      'Chassis': chassis.toMap(),
      'DriveTrain': driveTrain.toMap(),
      'Tyres': tyres.toMap(),
    };
  }
}
