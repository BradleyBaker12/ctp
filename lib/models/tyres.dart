// lib/models/tyres.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/timestamp_helper.dart';

class Tyres {
  final String chassisCondition;
  final String virginOrRecap;
  final String rimType;
  final DateTime lastUpdated;
  final Map<String, String> photos;

  Tyres({
    required this.chassisCondition,
    required this.virginOrRecap,
    required this.rimType,
    required this.lastUpdated,
    required this.photos,
  });

  factory Tyres.fromMap(Map<String, dynamic> data) {
    return Tyres(
      chassisCondition: data['chassisCondition'] ?? '',
      virginOrRecap: data['virginOrRecap'] ?? '',
      rimType: data['rimType'] ?? '',
      lastUpdated: parseTimestamp(data['lastUpdated'], ''),
      photos: {
        'Tyre_Pos_1 Photo': data['Tyre_Pos_1 Photo'] ?? '',
        'Tyre_Pos_2 Photo': data['Tyre_Pos_2 Photo'] ?? '',
        'Tyre_Pos_3 Photo': data['Tyre_Pos_3 Photo'] ?? '',
        'Tyre_Pos_4 Photo': data['Tyre_Pos_4 Photo'] ?? '',
        'Tyre_Pos_5 Photo': data['Tyre_Pos_5 Photo'] ?? '',
        'Tyre_Pos_6 Photo': data['Tyre_Pos_6 Photo'] ?? '',
      },
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chassisCondition': chassisCondition,
      'virginOrRecap': virginOrRecap,
      'rimType': rimType,
      ...photos,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}
