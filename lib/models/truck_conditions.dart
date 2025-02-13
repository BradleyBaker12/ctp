// lib/models/truck_conditions.dart

import 'external_cab.dart';
import 'internal_cab.dart';
import 'chassis.dart';
import 'drive_train.dart';
import 'tyres.dart';
import 'package:flutter/foundation.dart';

class TruckConditions {
  final ExternalCab externalCab;
  final InternalCab internalCab;
  final Chassis chassis;
  final DriveTrain driveTrain;
  final Map<String, Tyres> tyres;

  TruckConditions({
    required this.externalCab,
    required this.internalCab,
    required this.chassis,
    required this.driveTrain,
    required this.tyres,
  });

  factory TruckConditions.fromMap(Map<String, dynamic> map) {
    debugPrint('=== TruckConditions Raw Data ===');
    debugPrint('Raw map: $map');

    // First try to get the nested cab data
    Map<String, dynamic> extData = {};
    Map<String, dynamic> intData = {};
    Map<String, dynamic> chassisData = {};
    Map<String, dynamic> driveTrainData = {};
    Map<String, dynamic> tyresData = {};

    try {
      if (map['externalCab'] is Map) {
        extData = Map<String, dynamic>.from(map['externalCab']);
      }
      if (map['internalCab'] is Map) {
        intData = Map<String, dynamic>.from(map['internalCab']);
      }
      if (map['chassis'] is Map) {
        chassisData = Map<String, dynamic>.from(map['chassis']);
      }
      if (map['driveTrain'] is Map) {
        driveTrainData = Map<String, dynamic>.from(map['driveTrain']);
      }
      if (map['tyres'] is Map) {
        tyresData = Map<String, dynamic>.from(map['tyres']);
      }

      debugPrint('=== Parsed Data ===');
      debugPrint('External Cab: $extData');
      debugPrint('Internal Cab: $intData');
      debugPrint('Chassis: $chassisData');
      debugPrint('Drive Train: $driveTrainData');
      debugPrint('Tyres: $tyresData');
    } catch (e) {
      debugPrint('Error parsing TruckConditions data: $e');
    }

    return TruckConditions(
      externalCab: ExternalCab.fromMap(extData),
      internalCab: InternalCab.fromMap(intData),
      chassis: Chassis.fromMap(chassisData),
      driveTrain: DriveTrain.fromMap(driveTrainData),
      tyres: {
        'tyres': Tyres(
          positions: _parseTyrePositions(tyresData),
          lastUpdated: DateTime.now(),
        )
      },
    );
  }

  static Map<String, TyrePosition> _parseTyrePositions(
      Map<String, dynamic>? data) {
    final positions = <String, TyrePosition>{};
    if (data != null) {
      data.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          positions[key] = TyrePosition.fromMap(value);
        }
      });
    }
    return positions;
  }

  // Provide an empty constructor for default values.
  factory TruckConditions.empty() {
    return TruckConditions(
      externalCab: ExternalCab.empty(),
      internalCab: InternalCab.empty(),
      chassis: Chassis.empty(),
      driveTrain: DriveTrain.empty(),
      tyres: {},
    );
  }

  Map<String, dynamic> toMap() {
    // Save all keys in lowercase for consistency.
    return {
      'externalCab': externalCab.toMap(),
      'internalCab': internalCab.toMap(),
      'chassis': chassis.toMap(),
      'driveTrain': driveTrain.toMap(),
      'tyres': tyres.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}
