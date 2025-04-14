import 'package:flutter/material.dart';
import 'dart:typed_data';

class TrailerFormProvider with ChangeNotifier {
  // Trailer common fields
  String? _trailerType;
  String? _axles;
  String? _length;

  // Tri-Axle fields
  String? _triAxleVin;
  String? _triAxleRegistration;
  String? _triAxleLength;

  // Superlink Trailer A fields
  String? _superlinkAVin;
  String? _superlinkARegistration;
  String? _superlinkALength;
  Uint8List? _superlinkAFrontImage;

  // Superlink Trailer B fields
  String? _superlinkBVin;
  String? _superlinkBRegistration;
  String? _superlinkBLength;
  Uint8List? _superlinkBFrontImage;

  // Generic images for other trailer types
  Uint8List? _selectedMainImage;
  String? _referenceNumber; // NEW field added

  // Add these new fields near the top with other fields
  String? _featuresCondition;
  List<Map<String, dynamic>>? _features;
  String? _damagesCondition;
  List<Map<String, dynamic>>? _damages;

  // Suspension fields
  String? _suspensionA;
  String? _suspensionB;
  String get suspensionA => _suspensionA ?? 'none';
  String get suspensionB => _suspensionB ?? 'none';

  // ABS fields
  String? _absA;
  String? _absB;
  String get absA => _absA ?? 'no';
  String get absB => _absB ?? 'no';

  // Getters
  String? get trailerType => _trailerType;
  String? get axles => _axles;
  String? get length => _length;
  String? get triAxleVin => _triAxleVin;
  String? get triAxleRegistration => _triAxleRegistration;
  String? get triAxleLength => _triAxleLength;
  String? get superlinkAVin => _superlinkAVin;
  String? get superlinkARegistration => _superlinkARegistration;
  String? get superlinkALength => _superlinkALength;
  String? get superlinkBVin => _superlinkBVin;
  String? get superlinkBRegistration => _superlinkBRegistration;
  String? get superlinkBLength => _superlinkBLength;
  String? get referenceNumber => _referenceNumber;
  Uint8List? get selectedMainImage => _selectedMainImage;

  // Add these getters with other getters
  String get featuresCondition => _featuresCondition ?? 'no';
  List<Map<String, dynamic>> get features => _features ?? [];
  String get damagesCondition => _damagesCondition ?? 'no';
  List<Map<String, dynamic>> get damages => _damages ?? [];

  // Setters
  void setTrailerType(String? type) {
    _trailerType = type;
    notifyListeners();
  }

  void setAxles(String? value) {
    _axles = value;
    notifyListeners();
  }

  void setLength(String? value) {
    _length = value;
    notifyListeners();
  }

  void setTriAxleVin(String? value) {
    _triAxleVin = value;
    notifyListeners();
  }

  void setTriAxleRegistration(String? value) {
    _triAxleRegistration = value;
    notifyListeners();
  }

  void setTriAxleLength(String? value) {
    _triAxleLength = value;
    notifyListeners();
  }

  void setSuperlinkAVin(String? value) {
    _superlinkAVin = value;
    notifyListeners();
  }

  void setSuperlinkARegistration(String? value) {
    _superlinkARegistration = value;
    notifyListeners();
  }

  void setSuperlinkALength(String? value) {
    _superlinkALength = value;
    notifyListeners();
  }

  void setSuperlinkAFrontImage(Uint8List? image) {
    _superlinkAFrontImage = image;
    notifyListeners();
  }

  void setSuperlinkBVin(String? value) {
    _superlinkBVin = value;
    notifyListeners();
  }

  void setSuperlinkBRegistration(String? value) {
    _superlinkBRegistration = value;
    notifyListeners();
  }

  void setSuperlinkBLength(String? value) {
    _superlinkBLength = value;
    notifyListeners();
  }

  void setSuperlinkBFrontImage(Uint8List? image) {
    _superlinkBFrontImage = image;
    notifyListeners();
  }

  void setSelectedMainImage(Uint8List? image) {
    _selectedMainImage = image;
    notifyListeners();
  }

  void setReferenceNumber(String? value) {
    _referenceNumber = value;
    notifyListeners();
  }

  // Add these setters with other setters
  void setFeaturesCondition(String value) {
    _featuresCondition = value;
    notifyListeners();
  }

  void setFeatures(List<Map<String, dynamic>> value) {
    _features = value;
    notifyListeners();
  }

  void setDamagesCondition(String value) {
    _damagesCondition = value;
    notifyListeners();
  }

  void setDamages(List<Map<String, dynamic>> value) {
    debugPrint('\n=== SETTING DAMAGES ===');

    final processedDamages = value.map((damage) {
      // Create controller with description if it doesn't exist
      if (damage['controller'] == null && damage['description'] != null) {
        damage['controller'] =
            TextEditingController(text: damage['description'].toString());
        debugPrint(
            'Created new controller with text: "${damage['description']}"');
      }

      debugPrint('Processing damage:');
      debugPrint('Description: ${damage['description']}');
      debugPrint('Controller text: ${damage['controller']?.text}');
      return damage;
    }).toList();

    _damages = processedDamages;
    notifyListeners();
  }

  void setSuspensionA(String? value) {
    _suspensionA = value;
    notifyListeners();
  }

  void setSuspensionB(String? value) {
    _suspensionB = value;
    notifyListeners();
  }

  void setAbsA(String? value) {
    _absA = value;
    notifyListeners();
  }

  void setAbsB(String? value) {
    _absB = value;
    notifyListeners();
  }

  void saveFormState() {
    notifyListeners();
  }

  // Clear all trailer form data
  void clearAll() {
    _trailerType = null;
    _axles = null;
    _length = null;
    _triAxleVin = null;
    _triAxleRegistration = null;
    _triAxleLength = null;
    _superlinkAVin = null;
    _superlinkARegistration = null;
    _superlinkALength = null;
    _superlinkAFrontImage = null;
    _superlinkBVin = null;
    _superlinkBRegistration = null;
    _superlinkBLength = null;
    _superlinkBFrontImage = null;
    _selectedMainImage = null;
    _referenceNumber = null;
    _featuresCondition = null;
    _features = null;
    _damagesCondition = null;
    _damages = null;
    notifyListeners();
  }

  // Convert the trailer form data into a map based on trailer type.
  Map<String, dynamic> toTrailerMap() {
    debugPrint('\n=== SAVE DEBUG ===');

    final Map<String, dynamic> map = {
      'trailerType': _trailerType,
      'axles': _axles,
      'length': _length,
      'featuresCondition': _featuresCondition ?? 'no',
      'damagesCondition': _damagesCondition ?? 'no',
    };

    // Process damages with strict checking
    if (_damages != null) {
      debugPrint('Processing damages: ${_damages!.length} items');

      map['damages'] = _damages!.map((damage) {
        debugPrint('\nDamage item before processing: $damage');

        // Try to get description from controller first
        String description = '';
        if (damage['controller'] != null) {
          final controller = damage['controller'] as TextEditingController;
          description = controller.text;
          debugPrint('Description from controller: "$description"');
        }

        // If controller description is empty, try getting from description field
        if (description.isEmpty) {
          description = damage['description']?.toString() ?? '';
          debugPrint('Description from field: "$description"');
        }

        final result = {
          'description': description.trim(),
          'imageUrl': damage['imageUrl'] ?? '',
        };

        debugPrint('Final processed damage: $result');
        return result;
      }).toList();

      debugPrint('Final damages list: ${map['damages']}');
    } else {
      map['damages'] = [];
    }

    // Process features
    if (_features != null) {
      map['features'] = _features!.map((feature) {
        String description;
        if (feature['controller'] != null) {
          final TextEditingController ctrl = feature['controller'];
          description = ctrl.text.trim();
        } else {
          description = feature['description']?.toString().trim() ?? '';
        }
        return {
          'description': description,
          'imageUrl': feature['imageUrl'] ?? '',
        };
      }).toList();
    } else {
      map['features'] = [];
    }

    // Add trailer type specific data
    if (_trailerType == 'Tri-Axle') {
      map.addAll({
        'vin': _triAxleVin,
        'registration': _triAxleRegistration,
        'lengthTrailer': _triAxleLength,
      });
    } else if (_trailerType == 'Superlink') {
      map.addAll({
        'superlinkAVin': _superlinkAVin,
        'superlinkARegistration': _superlinkARegistration,
        'superlinkALength': _superlinkALength,
        'superlinkBVin': _superlinkBVin,
        'superlinkBRegistration': _superlinkBRegistration,
        'superlinkBLength': _superlinkBLength,
      });
    }

    debugPrint('Final map damages: ${map['damages']}');
    debugPrint('Final map features: ${map['features']}');
    debugPrint(
        '\n================== END TRAILER MAP DEBUG ==================\n');
    return map;
  }

  // Populate the form provider from a given trailer data map.
  void populateFromTrailer(Map<String, dynamic> data) {
    debugPrint('\n=== POPULATING TRAILER DATA ===');

    // Get base data first (trailer data from either source)
    final trailerData = data['trailer'] as Map<String, dynamic>? ?? data;

    // Try to get damages from trailer first, then fallback to root data
    final damagesList = (trailerData['damages'] != null)
        ? List<Map<String, dynamic>>.from(trailerData['damages'])
        : (data['damages'] != null)
            ? List<Map<String, dynamic>>.from(data['damages'])
            : [];

    debugPrint('Found ${damagesList.length} damages to process');

    if (damagesList.isNotEmpty) {
      final processedDamages = damagesList.map((damage) {
        debugPrint('\nProcessing damage:');
        debugPrint('Raw damage data: $damage');

        final description = damage['description'] ?? '';
        debugPrint('Extracted description: "$description"');

        final controller = TextEditingController(text: description);
        debugPrint('Created controller with text: "${controller.text}"');

        return {
          'description': description,
          'imageUrl': damage['imageUrl'] ?? '',
          'image': null,
          'controller': controller,
        };
      }).toList();

      debugPrint('\nSetting damages condition and list');
      setDamagesCondition('yes');
      setDamages(processedDamages);

      debugPrint('\nVerifying processed damages:');
      for (var damage in processedDamages) {
        final ctrl = damage['controller'] as TextEditingController;
        debugPrint(
            'Damage description: "${damage['description']}", Controller text: "${ctrl.text}"');
      }
    } else {
      debugPrint('No damages found to process');
      setDamagesCondition('no');
      setDamages([]);
    }

    // Get the trailer data from either the trailer field or the root
    final trailerType = trailerData['trailerType'];
    setTrailerType(trailerType);

    // Get basic fields
    setReferenceNumber(trailerData['referenceNumber']);
    setAxles(trailerData['axles']);
    setLength(trailerData['length']);

    // Get the nested trailer data with priority handling
    Map<String, dynamic> trailerExtraInfo = {};

    // Try to get trailerExtraInfo from either direct path or nested path
    if (trailerData['trailerExtraInfo'] != null) {
      debugPrint('Found trailerExtraInfo in data');
      trailerExtraInfo =
          Map<String, dynamic>.from(trailerData['trailerExtraInfo']);
    } else if (data['trailerExtraInfo'] != null) {
      debugPrint('Found trailerExtraInfo in root');
      trailerExtraInfo = Map<String, dynamic>.from(data['trailerExtraInfo']);
    }
    debugPrint('DEBUG: Final trailerExtraInfo: $trailerExtraInfo');

    if (trailerType == 'Superlink') {
      debugPrint('DEBUG: Processing Superlink data');

      // Extract and process Trailer A data
      Map<String, dynamic> trailerA = {};
      if (trailerExtraInfo['trailerA'] != null) {
        trailerA = Map<String, dynamic>.from(trailerExtraInfo['trailerA']);
        // Set suspension and ABS for Trailer A
        _suspensionA = trailerA['suspension']?.toString() ?? 'steel';
        _absA = trailerA['abs']?.toString() ?? 'no';
      }
      // debugPrint('DEBUG: Raw Trailer A data: $trailerA');

      // Set Trailer A values, providing clear defaults
      final aLength = trailerA['length']?.toString() ??
          trailerA['lengthTrailer']?.toString() ??
          '';
      final aVin = trailerA['vin']?.toString() ??
          trailerA['vinNumber']?.toString() ??
          '';
      final aReg = trailerA['registration']?.toString() ??
          trailerA['registrationNumber']?.toString() ??
          '';

      debugPrint(
          'DEBUG: Setting Trailer A - Length: $aLength, VIN: $aVin, Reg: $aReg');

      setSuperlinkALength(aLength);
      setSuperlinkAVin(aVin);
      setSuperlinkARegistration(aReg);

      // Extract and process Trailer B data
      Map<String, dynamic> trailerB = {};
      if (trailerExtraInfo['trailerB'] != null) {
        trailerB = Map<String, dynamic>.from(trailerExtraInfo['trailerB']);
        // Set suspension and ABS for Trailer B
        _suspensionB = trailerB['suspension']?.toString() ?? 'steel';
        _absB = trailerB['abs']?.toString() ?? 'no';
      }
      // debugPrint('DEBUG: Raw Trailer B data: $trailerB');

      // Set Trailer B values, providing clear defaults
      final bLength = trailerB['length']?.toString() ??
          trailerB['lengthTrailer']?.toString() ??
          '';
      final bVin = trailerB['vin']?.toString() ??
          trailerB['vinNumber']?.toString() ??
          '';
      final bReg = trailerB['registration']?.toString() ??
          trailerB['registrationNumber']?.toString() ??
          '';

      debugPrint(
          'DEBUG: Setting Trailer B - Length: $bLength, VIN: $bVin, Reg: $bReg');

      setSuperlinkBLength(bLength);
      setSuperlinkBVin(bVin);
      setSuperlinkBRegistration(bReg);

      // Print final state for verification
      debugPrint(
          'DEBUG: Final Trailer A state - Length: $_superlinkALength, VIN: $_superlinkAVin, Reg: $_superlinkARegistration');
      debugPrint(
          'DEBUG: Final Trailer B state - Length: $_superlinkBLength, VIN: $_superlinkBVin, Reg: $_superlinkBRegistration');
    } else if (trailerType == 'Tri-Axle') {
      debugPrint('DEBUG: Processing Tri-Axle data');
      setTriAxleVin(trailerExtraInfo['vin']?.toString() ?? '');
      setTriAxleRegistration(
          trailerExtraInfo['registration']?.toString() ?? '');
      setTriAxleLength(trailerExtraInfo['lengthTrailer']?.toString() ?? '');
    }

    // Helper function to process items (damages or features)
    List<Map<String, dynamic>> processItems(
        List<Map<String, dynamic>> items, String type) {
      return items.map((item) {
        final description = item['description'] ?? '';
        debugPrint('DEBUG: Processing $type with description: $description');

        return {
          'description': description,
          'imageUrl': item['imageUrl'] ?? '',
          'image': null,
          'controller': TextEditingController(text: description),
        };
      }).toList();
    }

    // Handle damages
    if (data['damages'] != null) {
      final damagesList = List<Map<String, dynamic>>.from(data['damages']);
      debugPrint('DEBUG: Found damages: $damagesList');

      final processedDamages = processItems(damagesList, 'damage');
      setDamages(processedDamages);
      setDamagesCondition(damagesList.isNotEmpty ? 'yes' : 'no');

      for (var damage in processedDamages) {
        debugPrint(
            'DEBUG: Damage description: ${damage['description']}, Controller text: ${damage['controller'].text}');
      }
    }

    // Handle features
    if (data['features'] != null) {
      final featuresList = List<Map<String, dynamic>>.from(data['features']);
      debugPrint('DEBUG: Found features: $featuresList');

      final processedFeatures = processItems(featuresList, 'feature');
      setFeatures(processedFeatures);
      setFeaturesCondition(featuresList.isNotEmpty ? 'yes' : 'no');

      for (var feature in processedFeatures) {
        debugPrint(
            'DEBUG: Feature description: ${feature['description']}, Controller text: ${feature['controller'].text}');
      }
    }

    debugPrint(
        'DEBUG: Final state - Superlink A - VIN: $_superlinkAVin, Reg: $_superlinkARegistration, Length: $_superlinkALength');
    debugPrint(
        'DEBUG: Final state - Superlink B - VIN: $_superlinkBVin, Reg: $_superlinkBRegistration, Length: $_superlinkBLength');
  }
}
