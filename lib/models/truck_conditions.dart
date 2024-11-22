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
  final Map<String, Tyres> tyres;

  TruckConditions({
    required this.externalCab,
    required this.internalCab,
    required this.chassis,
    required this.driveTrain,
    required this.tyres,
  });

  factory TruckConditions.fromMap(Map<String, dynamic> map) {
    return TruckConditions(
      externalCab: map['externalCab'] != null
          ? ExternalCab.fromMap(map['externalCab'] as Map<String, dynamic>)
          : ExternalCab(
              damages: [],
              additionalFeatures: [],
              condition: '',
              damagesCondition: '',
              additionalFeaturesCondition: '',
              images: {},
            ),
      internalCab: InternalCab.fromMap(map['internalCab'] as Map<String, dynamic>),
      chassis: Chassis.fromMap(map['chassis'] as Map<String, dynamic>),
      driveTrain: DriveTrain.fromMap(map['driveTrain'] as Map<String, dynamic>),
      tyres: {
        'tyres': Tyres(
          positions: _parseTyrePositions(map['tyres'] as Map<String, dynamic>?),
          lastUpdated: DateTime.now(),
        )
      },
    );
  }

  static Map<String, TyrePosition> _parseTyrePositions(Map<String, dynamic>? data) {
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

  // Add an empty constructor for default values
  factory TruckConditions.empty() {
    return TruckConditions(
      tyres: {},
      chassis: Chassis.empty(),
      driveTrain: DriveTrain.empty(),
      externalCab: ExternalCab.empty(),
      internalCab: InternalCab.empty(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ExternalCab': externalCab.toMap(),
      'InternalCab': internalCab.toMap(),
      'Chassis': chassis.toMap(),
      'DriveTrain': driveTrain.toMap(),
      'Tyres': tyres.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}
