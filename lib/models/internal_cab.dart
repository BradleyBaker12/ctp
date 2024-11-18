// lib/models/internal_cab.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'damage.dart';
import 'additional_feature.dart';
import '../utils/timestamp_helper.dart';

class InternalCab {
  final String condition;
  final String oemInspectionType;
  final String oemInspectionReason;
  final DateTime lastUpdated;
  final Map<String, String> photos;
  final List<Damage> damages;
  final List<AdditionalFeature> additionalFeatures;
  final List<dynamic> faultCodes;

  InternalCab({
    required this.condition,
    required this.oemInspectionType,
    required this.oemInspectionReason,
    required this.lastUpdated,
    required this.photos,
    required this.damages,
    required this.additionalFeatures,
    required this.faultCodes,
  });

  factory InternalCab.fromMap(Map<String, dynamic> data) {
    return InternalCab(
      condition: data['condition'] ?? '',
      oemInspectionType: data['oemInspectionType'] ?? '',
      oemInspectionReason: data['oemInspectionReason'] ?? '',
      lastUpdated: parseTimestamp(data['lastUpdated'], ''),
      photos: {
        'Center Dash': data['Center Dash'] ?? '',
        'Left Dash': data['Left Dash'] ?? '',
        'Right Dash (Vehicle On)': data['Right Dash (Vehicle On)'] ?? '',
        'Mileage': data['Mileage'] ?? '',
        'Sun Visors': data['Sun Visors'] ?? '',
        'Center Console': data['Center Console'] ?? '',
        'Steering': data['Steering'] ?? '',
        'Left Door Panel': data['Left Door Panel'] ?? '',
        'Left Seat': data['Left Seat'] ?? '',
        'Roof': data['Roof'] ?? '',
        'Bunk Beds': data['Bunk Beds'] ?? '',
        'Rear Panel': data['Rear Panel'] ?? '',
        'Right Door Panel': data['Right Door Panel'] ?? '',
        'Right Seat': data['Right Seat'] ?? '',
      },
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
      'oemInspectionType': oemInspectionType,
      'oemInspectionReason': oemInspectionReason,
      ...photos,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'damages': damages.map((d) => d.toMap()).toList(),
      'additionalFeatures': additionalFeatures.map((a) => a.toMap()).toList(),
      'faultCodes': faultCodes,
    };
  }

  factory InternalCab.empty() {
    return InternalCab(
      condition: '',
      oemInspectionType: '',
      oemInspectionReason: '',
      lastUpdated: DateTime.now(),
      photos: {},
      damages: [],
      additionalFeatures: [],
      faultCodes: [],
    );
  }
}
