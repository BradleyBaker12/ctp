import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class TruckConditionsProvider with ChangeNotifier {
  final String vehicleId;
  Map<String, dynamic> _cachedData = {};
  bool _isInitialized = false;

  TruckConditionsProvider(this.vehicleId);

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['truckConditions'] != null) {
          _cachedData = data['truckConditions'];
        }
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing truck conditions: $e');
    }
  }

  // Method to get cached data for a specific section
  Map<String, dynamic>? getSectionData(String section) {
    return _cachedData[section];
  }

  // Method to update section data
  Future<void> updateSectionData(String section, Map<String, dynamic> data) async {
    _cachedData[section] = data;
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .update({
        'truckConditions.$section': data,
      });
    } catch (e) {
      print('Error updating section data: $e');
      rethrow;
    }
  }

  // Method to clear cached data
  void clearCache() {
    _cachedData.clear();
    _isInitialized = false;
    notifyListeners();
  }
} 