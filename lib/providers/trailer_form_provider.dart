import 'package:flutter/foundation.dart';
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
  // ... add additional images if needed ...

  // Superlink Trailer B fields
  String? _superlinkBVin;
  String? _superlinkBRegistration;
  String? _superlinkBLength;
  Uint8List? _superlinkBFrontImage;
  // ... add additional images if needed ...

  // Generic images for other trailer types
  Uint8List? _selectedMainImage;
  Uint8List? get selectedMainImage => _selectedMainImage;

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
    notifyListeners();
  }
}
