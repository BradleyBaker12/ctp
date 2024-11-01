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
  final Map<String, String> photos;
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
    required this.photos,
    required this.damages,
    required this.additionalFeatures,
    required this.faultCodes,
  });

  factory DriveTrain.fromMap(Map<String, dynamic> data) {
    return DriveTrain(
      condition: data['condition'] ?? '',
      oilLeakConditionEngine: data['oilLeakConditionEngine'] ?? '',
      waterLeakConditionEngine: data['waterLeakConditionEngine'] ?? '',
      blowbyCondition: data['blowbyCondition'] ?? '',
      oilLeakConditionGearbox: data['oilLeakConditionGearbox'] ?? '',
      retarderCondition: data['retarderCondition'] ?? '',
      lastUpdated: parseTimestamp(data['lastUpdated'], ''),
      photos: {
        'Right Brake': data['Right Brake'] ?? '',
        'Left Brake': data['Left Brake'] ?? '',
        'Front Axel': data['Front Axel'] ?? '',
        'Suspension': data['Suspension'] ?? '',
        'Fuel Tank': data['Fuel Tank'] ?? '',
        'Battery': data['Battery'] ?? '',
        'Cat Walk': data['Cat Walk'] ?? '',
        'Electrical Cable Black': data['Electrical Cable Black'] ?? '',
        'Air Cable Yellow': data['Air Cable Yellow'] ?? '',
        'Air Cable Red': data['Air Cable Red'] ?? '',
        'Tail Board': data['Tail Board'] ?? '',
        '5th Wheel': data['5th Wheel'] ?? '',
        'Left Brake Rear Axel': data['Left Brake Rear Axel'] ?? '',
        'Right Brake Rear Axel': data['Right Brake Rear Axel'] ?? '',
      },
      damages: data['damages'] ?? [],
      additionalFeatures: data['additionalFeatures'] ?? [],
      faultCodes: data['faultCodes'] ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'condition': condition,
      'oilLeakConditionEngine': oilLeakConditionEngine,
      'waterLeakConditionEngine': waterLeakConditionEngine,
      'blowbyCondition': blowbyCondition,
      'oilLeakConditionGearbox': oilLeakConditionGearbox,
      'retarderCondition': retarderCondition,
      ...photos,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'damages': damages,
      'additionalFeatures': additionalFeatures,
      'faultCodes': faultCodes,
    };
  }
}
