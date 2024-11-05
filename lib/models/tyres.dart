// lib/models/tyres.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/timestamp_helper.dart';

class Tyres {
  final Map<String, TyrePosition> positions;
  final DateTime lastUpdated;

  Tyres({
    required this.positions,
    required this.lastUpdated,
  });

  factory Tyres.fromMap(Map<String, dynamic> map) {
    Map<String, TyrePosition> positions = {};
    
    // Convert each tyre position data
    for (int i = 1; i <= 6; i++) {
      String key = 'Tyre_Pos_$i';
      if (map[key] != null && map[key] is Map) {
        positions[key] = TyrePosition.fromMap(map[key] as Map<String, dynamic>);
      }
    }

    return Tyres(
      positions: positions,
      lastUpdated: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {};
    positions.forEach((key, value) {
      map[key] = value.toMap();
    });
    return map;
  }
}

class TyrePosition {
  final String chassisCondition;
  final String rimType;
  final String virginOrRecap;
  final String? imageUrl;

  TyrePosition({
    required this.chassisCondition,
    required this.rimType,
    required this.virginOrRecap,
    this.imageUrl,
  });

  factory TyrePosition.fromMap(Map<String, dynamic> map) {
    return TyrePosition(
      chassisCondition: map['chassisCondition'] ?? '',
      rimType: map['rimType'] ?? '',
      virginOrRecap: map['virginOrRecap'] ?? '',
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chassisCondition': chassisCondition,
      'rimType': rimType,
      'virginOrRecap': virginOrRecap,
      'imageUrl': imageUrl,
    };
  }
}
