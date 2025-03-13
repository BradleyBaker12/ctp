// lib/models/drive_train.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/timestamp_helper.dart';

class DriveTrain {
  final String condition;
  final String oilLeakConditionEngine;
  final String waterLeakConditionEngine;
  final String blowbyCondition;
  final String oilLeakConditionGearbox;
  final String retarderCondition;
  final DateTime lastUpdated;
  final Map<String, dynamic>
      images; // Updated to store image data with paths and URLs
  final List<dynamic> damages;
  final List<dynamic> additionalFeatures;
  final List<dynamic> faultCodes;

  DriveTrain({
    required this.condition,
    required this.oilLeakConditionEngine,
    required this.waterLeakConditionEngine,
    required this.blowbyCondition,
    required this.oilLeakConditionGearbox,
    required this.retarderCondition,
    required this.lastUpdated,
    required this.images,
    required this.damages,
    required this.additionalFeatures,
    required this.faultCodes,
  });

  factory DriveTrain.fromMap(Map<String, dynamic> data) {
    Map<String, dynamic> imagesData = {};
    if (data['images'] != null && data['images'] is Map) {
      imagesData = Map<String, dynamic>.from(data['images']);
    }

    return DriveTrain(
      condition: data['condition'] ?? '',
      oilLeakConditionEngine: data['engineOilLeak'] ?? '',
      waterLeakConditionEngine: data['engineWaterLeak'] ?? '',
      blowbyCondition: data['blowbyCondition'] ?? '',
      oilLeakConditionGearbox: data['gearboxOilLeak'] ?? '',
      retarderCondition: data['retarderCondition'] ?? '',
      lastUpdated: parseTimestamp(data['lastUpdated'], ''),
      images: imagesData,
      damages: data['damages'] ?? [],
      additionalFeatures: data['additionalFeatures'] ?? [],
      faultCodes: data['faultCodes'] ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'condition': condition,
      'engineOilLeak': oilLeakConditionEngine,
      'engineWaterLeak': waterLeakConditionEngine,
      'blowbyCondition': blowbyCondition,
      'gearboxOilLeak': oilLeakConditionGearbox,
      'retarderCondition': retarderCondition,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'images': images,
      'damages': damages,
      'additionalFeatures': additionalFeatures,
      'faultCodes': faultCodes,
    };
  }

  factory DriveTrain.empty() {
    return DriveTrain(
      condition: '',
      oilLeakConditionEngine: '',
      waterLeakConditionEngine: '',
      blowbyCondition: '',
      oilLeakConditionGearbox: '',
      retarderCondition: '',
      lastUpdated: DateTime.now(),
      images: {},
      damages: [],
      additionalFeatures: [],
      faultCodes: [],
    );
  }
}
