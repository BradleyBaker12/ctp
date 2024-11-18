// lib/models/external_cab.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'damage.dart';
import 'additional_feature.dart';
import '../utils/timestamp_helper.dart';

class ExternalCab {
  final String selectedCondition;
  final String anyDamages;
  final String anyAdditionalFeatures;
  final Map<String, String> photos;
  final DateTime lastUpdated;
  final List<Damage> damages;
  final List<AdditionalFeature> additionalFeatures;

  ExternalCab({
    required this.selectedCondition,
    required this.anyDamages,
    required this.anyAdditionalFeatures,
    required this.photos,
    required this.lastUpdated,
    required this.damages,
    required this.additionalFeatures,
  });

  factory ExternalCab.fromMap(Map<String, dynamic> data) {
    return ExternalCab(
      selectedCondition: data['selectedCondition'] ?? '',
      anyDamages: data['anyDamages'] ?? '',
      anyAdditionalFeatures: data['anyAdditionalFeatures'] ?? '',
      photos: {
        'FRONT VIEW': data['FRONT VIEW'] ?? '',
        'RIGHT SIDE VIEW': data['RIGHT SIDE VIEW'] ?? '',
        'REAR VIEW': data['REAR VIEW'] ?? '',
        'LEFT SIDE VIEW': data['LEFT SIDE VIEW'] ?? '',
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'selectedCondition': selectedCondition,
      'anyDamages': anyDamages,
      'anyAdditionalFeatures': anyAdditionalFeatures,
      ...photos,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'damages': damages.map((d) => d.toMap()).toList(),
      'additionalFeatures': additionalFeatures.map((a) => a.toMap()).toList(),
    };
  }

  factory ExternalCab.empty() {
    return ExternalCab(
      selectedCondition: '',
      anyDamages: '',
      anyAdditionalFeatures: '',
      photos: {},
      lastUpdated: DateTime.now(),
      damages: [],
      additionalFeatures: [],
    );
  }
}
