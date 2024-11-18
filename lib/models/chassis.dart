// lib/models/chassis.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'damage.dart';
import 'additional_feature.dart';
import '../utils/timestamp_helper.dart';

class Chassis {
  final String condition;
  final String damagesCondition;
  final String additionalFeaturesCondition;
  final Map<String, String> photos;
  final DateTime lastUpdated;
  final List<Damage> damages;
  final List<AdditionalFeature> additionalFeatures;
  final List<dynamic> faultCodes;

  Chassis({
    required this.condition,
    required this.damagesCondition,
    required this.additionalFeaturesCondition,
    required this.photos,
    required this.lastUpdated,
    required this.damages,
    required this.additionalFeatures,
    required this.faultCodes,
  });

  factory Chassis.fromMap(Map<String, dynamic> data) {
    return Chassis(
      condition: data['condition'] ?? '',
      damagesCondition: data['damagesCondition'] ?? '',
      additionalFeaturesCondition: data['additionalFeaturesCondition'] ?? '',
      photos: {
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
      lastUpdated: parseTimestamp(data['lastUpdated'], ''),
      damages: (data['damages'] as List<dynamic>?)
              ?.map((d) => Damage.fromMap(d as Map<String, dynamic>))
              .toList() ??
          [],
      additionalFeatures: (data['additionalFeatures'] as List<dynamic>?)
              ?.map((a) => AdditionalFeature.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
      faultCodes: data['faultCodes'] ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'condition': condition,
      'damagesCondition': damagesCondition,
      'additionalFeaturesCondition': additionalFeaturesCondition,
      ...photos,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'damages': damages.map((d) => d.toMap()).toList(),
      'additionalFeatures': additionalFeatures.map((a) => a.toMap()).toList(),
      'faultCodes': faultCodes,
    };
  }

  factory Chassis.empty() {
    return Chassis(
      condition: '',
      damagesCondition: '',
      additionalFeaturesCondition: '',
      photos: {},
      lastUpdated: DateTime.now(),
      damages: [],
      additionalFeatures: [],
      faultCodes: [],
    );
  }
}
