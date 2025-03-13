// lib/providers/vehicle_provider.dart

import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:flutter/material.dart';

import 'user_provider.dart';

class VehicleProvider with ChangeNotifier {
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;
  DocumentSnapshot? _lastFetchedDocument;
  String? _vehicleId; // Field to store the vehicleId

  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get vehicleId => _vehicleId;

  // Setter for vehicleId
  void setVehicleId(String id) {
    _vehicleId = id;
    notifyListeners(); // Notifies listeners when vehicleId changes
  }

  ValueNotifier<List<Vehicle>> vehicleListenable = ValueNotifier([]);

  VehicleProvider();

  // Initialize the provider by fetching vehicles
  void initialize(UserProvider userProvider) {
    String? userId = userProvider.userId; // Extract userId
    if (userId != null && userId.isNotEmpty) {
      fetchVehicles(userProvider, userId: userId); // Pass userId
    } else {
      print('User ID is null or empty, cannot fetch vehicles.');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a vehicle to the local list
  void addVehicle(Vehicle vehicle) {
    _vehicles.add(vehicle);
    vehicleListenable.value = List.from(_vehicles);
    notifyListeners();
  }

  // Remove a vehicle from the local list by index
  void removeVehicle(int index) {
    _vehicles.removeAt(index);
    vehicleListenable.value = List.from(_vehicles);
    notifyListeners();
  }

  // Get vehicles by a specific user ID
  List<Vehicle> getVehiclesByUserId(String userId) {
    return _vehicles.where((vehicle) => vehicle.userId == userId).toList();
  }

  // Fetch vehicles from Firestore with optional filters
  Future<void> fetchVehicles(UserProvider userProvider,
      {String? vehicleType,
      String? userId,
      bool filterLikedDisliked = true,
      int limit = 1000}) async {
    try {
      _isLoading = true;
      notifyListeners();

      Query query = FirebaseFirestore.instance
          .collection('vehicles')
          .orderBy('createdAt', descending: true);
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      QuerySnapshot querySnapshot = await query.get();

      _vehicles = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Handle brands field
        if (data['brands'] is String) {
          data['brands'] = [data['brands']];
        } else if (data['brands'] == null) {
          data['brands'] = [];
        }

        // Handle application field
        if (data['application'] is String) {
          data['application'] = [data['application']];
        } else if (data['application'] == null) {
          data['application'] = [];
        }

        // Initialize truck conditions
        if (data['truckConditions'] is Map) {
          var conditions = data['truckConditions'] as Map<String, dynamic>;
          for (var section in [
            'chassis',
            'externalCab',
            'driveTrain',
            'internalCab'
          ]) {
            if (conditions[section] is Map) {
              var sectionData = conditions[section] as Map<String, dynamic>;
              sectionData['damages'] = [];
              sectionData['additionalFeatures'] = [];
              if (section == 'internalCab') {
                sectionData['faultCodes'] = [];
              }
            }
          }
        }

        // Ensure createdAt is valid
        if (data['createdAt'] == null) {
          data['createdAt'] = Timestamp.now();
        }

        return Vehicle.fromFirestore(doc.id, data);
      }).toList();

      vehicleListenable.value = List<Vehicle>.from(_vehicles);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching vehicles: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreVehicles() async {
    if (_lastFetchedDocument == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .startAfterDocument(_lastFetchedDocument!)
          .limit(1000) // Adjust as needed
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastFetchedDocument = querySnapshot.docs.last;
      }

      final moreVehicles = querySnapshot.docs.map((doc) {
        return Vehicle.fromFirestore(
            doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      _vehicles.addAll(moreVehicles);
      vehicleListenable.value = List.from(_vehicles);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching more vehicles: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // **New Method: Fetch All Vehicles with Enhanced Debugging and Error Handling**
  Future<void> fetchAllVehicles() async {
    try {
      _isLoading = true;
      notifyListeners();
      // print('Starting to fetch all vehicles from Firestore.');

      Query query = FirebaseFirestore.instance
          .collection('vehicles')
          .orderBy('createdAt', descending: true);

      // Fetch all vehicles without any filters
      QuerySnapshot querySnapshot = await query.get();

      // print(
      // 'Successfully fetched ${querySnapshot.docs.length} vehicles from Firestore.');

      _vehicles = querySnapshot.docs
          .map((doc) {
            if (doc.exists &&
                doc.data() != null &&
                doc.data() is Map<String, dynamic>) {
              // print('Processing Vehicle ID: ${doc.id}');
              try {
                return Vehicle.fromFirestore(
                    doc.id, doc.data() as Map<String, dynamic>);
              } catch (e) {
                // print('Error parsing vehicle data for ID ${doc.id}: $e');
                // Optionally, log the problematic data for further inspection
                // Uncomment the line below to log problematic data
                // print('Problematic data for ID ${doc.id}: ${doc.data()}');
                return null;
              }
            } else {
              // print(
              //     'Warning: Document ID ${doc.id} does not exist, has null data, or is not a Map<String, dynamic>.');
              return null;
            }
          })
          .where((vehicle) => vehicle != null)
          .cast<Vehicle>()
          .toList();

      if (_vehicles.isEmpty) {
        print('No valid vehicles found after parsing.');
      }

      // print('Total vehicles after processing: ${_vehicles.length}');

      vehicleListenable.value = List.from(_vehicles);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error in fetchAllVehicles: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get all unique makeModels
  List<String> getAllMakeModels() {
    List<String> brands = [
      'DAF',
      'FUSO',
      'HINO',
      'ISUZU',
      'IVECO',
      'MAN',
      'MERCEDES-BENZ',
      'SCANIA',
      'UD TRUCKS',
      'VW',
      'VOLVO',
      'FORD',
      'TOYOTA',
      'MAKE',
      'CNHTC',
      'EICHER',
      'FAW',
      'JAC',
      'POWERSTAR',
      'RENAULT',
      'TATA',
      'ASHOK LEYLAND',
      'DAYUN',
      'FIAT',
      'FOTON',
      'HYUNDAI',
      'JOYLONG',
      'PEUGEOT',
      'US TRUCKS'
    ];

    Set<String> matchedBrands = {};

    for (var vehicle in _vehicles) {
      for (var brand in brands) {
        if (vehicle.makeModel.contains(brand.toLowerCase())) {
          matchedBrands.add(brand);
          break;
        }
      }
    }

    return ['All', ...matchedBrands];
  }

  bool doesMakeModelContainBrand(String makeModel, String? brand) {
    if (brand == null || brand == 'All') {
      return true;
    }
    return makeModel.toLowerCase().contains(brand.toLowerCase());
  }

  List<String> getAllYears() {
    List<String> years =
        _vehicles.map((vehicle) => vehicle.year).toSet().toList();

    years.sort((a, b) {
      if (a == 'N/A') return 1;
      if (b == 'N/A') return -1;
      return int.parse(a).compareTo(int.parse(b));
    });

    return ['All', ...years];
  }

  List<String> getAllTransmissions() {
    Set<String> normalizedTransmissions = {};

    for (var vehicle in _vehicles) {
      String normalized = _normalizeTransmission(vehicle.transmissionType);
      if (normalized.isNotEmpty && normalized != 'n/a') {
        normalizedTransmissions.add(normalized);
      }
    }

    return [
      'All',
      ...normalizedTransmissions
          .where((trans) => trans != 'n/a' && trans != 'automatic')
    ];
  }

  String _normalizeTransmission(String transmission) {
    transmission = transmission.toLowerCase();
    if (transmission == 'auto' || transmission == 'automatic') {
      return 'Automatic';
    } else if (transmission == 'manual') {
      return 'Manual';
    }
    return transmission;
  }

  // Fetch recent vehicles (e.g., latest 5)
  Future<List<Vehicle>> fetchRecentVehicles() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();
      querySnapshot.docs.forEach((doc) {
        if (doc.id == "X4EYMzg6jS3aEtdEAtKF") {
          log("Truck data");
          log(jsonEncode(doc.data().toString()));
        }
      });
      final recentVehicles = querySnapshot.docs.map((doc) {
        return Vehicle.fromFirestore(
            doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      return recentVehicles;
    } catch (e) {
      print('Error fetching recent vehicles: $e');
      return [];
    }
  }

  // Delete a vehicle
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .update({
        'vehicleStatus': 'Archived',
      });

      // Remove the vehicle from the local list
      _vehicles.removeWhere((vehicle) => vehicle.id == vehicleId);
      vehicleListenable.value = List.from(_vehicles);
      notifyListeners();

      print("Vehicle deleted successfully.");
    } catch (e) {
      print("Error deleting vehicle: $e");
      rethrow; // Rethrow the error to handle it in the UI
    }
  }

  // Update a vehicle
  Future<void> updateVehicle(Vehicle updatedVehicle) async {
    try {
      // Update the vehicle document
      DocumentReference vehicleRef = FirebaseFirestore.instance
          .collection('vehicles')
          .doc(updatedVehicle.id);
      await vehicleRef.update(updatedVehicle.toMap());
      print("Vehicle updated successfully.");

      // Clean up duplicate drafts
      await cleanupDrafts(updatedVehicle.id);

      // Update the local list and notify listeners
      int index = _vehicles.indexWhere((v) => v.id == updatedVehicle.id);
      if (index != -1) {
        _vehicles[index] = updatedVehicle;
        vehicleListenable.value = List.from(_vehicles);
        notifyListeners();
      }
    } catch (e) {
      print("Error updating vehicle: $e");
      // Optionally, handle the error (e.g., notify the user)
    }
  }

  // Cleanup duplicate drafts
  Future<void> cleanupDrafts(String vehicleId) async {
    try {
      QuerySnapshot draftSnapshots = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('id', isEqualTo: vehicleId)
          .where('vehicleStatus', isEqualTo: 'Draft')
          .get();

      for (var doc in draftSnapshots.docs) {
        if (doc.id != vehicleId) {
          // Keep one draft
          await doc.reference.delete();
          print("Removed duplicate draft with ID: ${doc.id}");
        }
      }
    } catch (e) {
      print("Error cleaning up drafts: $e");
    }
  }
}
