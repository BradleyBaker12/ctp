// lib/models/tyres.dart



class Tyres {
  final Map<String, TyrePosition> positions;
  final DateTime lastUpdated;

  Tyres({
    required this.positions,
    required this.lastUpdated,
  });

  factory Tyres.fromMap(Map<String, dynamic> map) {
    Map<String, TyrePosition> positions = {};
    
    map.forEach((key, value) {
      if (key.startsWith('Tyre_Pos_') && value is Map) {
        positions[key] = TyrePosition.fromMap(value as Map<String, dynamic>);
      }
    });

    return Tyres(
      positions: positions,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
          map['lastUpdated'] ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      ...positions.map((key, value) => MapEntry(key, value.toMap())),
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    };
  }
}

class TyrePosition {
  final String chassisCondition;
  final String rimType;
  final String virginOrRecap;
  final String imagePath;
  final String isNew;

  TyrePosition({
    required this.chassisCondition,
    required this.rimType,
    required this.virginOrRecap,
    required this.imagePath,
    required this.isNew,
  });

  factory TyrePosition.fromMap(Map<String, dynamic> map) {
    return TyrePosition(
      chassisCondition: map['chassisCondition'] ?? '',
      rimType: map['rimType'] ?? '',
      virginOrRecap: map['virginOrRecap'] ?? '',
      imagePath: map['imagePath'] ?? '',
      isNew: map['isNew'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chassisCondition': chassisCondition,
      'rimType': rimType,
      'virginOrRecap': virginOrRecap,
      'imagePath': imagePath,
      'isNew': isNew,
    };
  }
}