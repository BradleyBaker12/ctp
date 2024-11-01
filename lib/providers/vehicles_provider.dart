// lib/providers/vehicle_provider.dart

import 'package:ctp/models/vehicle.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    fetchVehicles(userProvider); // Fetch vehicles as usual
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
      notifyListeners(); // Notify listeners about loading state

      Query query = FirebaseFirestore.instance.collection('vehicles');

      if (vehicleType != null) {
        query = query.where('vehicleType', isEqualTo: vehicleType);
      }

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      // Apply limit if needed
      if (limit > 0) {
        query = query.limit(limit);
      }

      QuerySnapshot querySnapshot = await query.get();

      print('Fetched ${querySnapshot.docs.length} vehicles from Firestore.');

      if (querySnapshot.docs.isNotEmpty) {
        _lastFetchedDocument = querySnapshot.docs.last;
      }

      // Pass the document ID to Vehicle.fromFirestore
      _vehicles = querySnapshot.docs.map((doc) {
        return Vehicle.fromFirestore(
            doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      print('Total vehicles after mapping: ${_vehicles.length}');
      print(
          'Vehicle IDs after fetching: ${_vehicles.map((v) => v.id).toList()}');

      if (filterLikedDisliked) {
        print('Filtering out liked/disliked vehicles...');
        _vehicles = _vehicles.where((vehicle) {
          bool isLiked = userProvider.getLikedVehicles.contains(vehicle.id);
          bool isDisliked =
              userProvider.getDislikedVehicles.contains(vehicle.id);
          if (isLiked || isDisliked) {
            print(
                'Excluding vehicle ID ${vehicle.id} because it is ${isLiked ? 'liked' : 'disliked'}.');
          }
          return !isLiked && !isDisliked;
        }).toList();
        print('Vehicles after filtering liked/disliked: ${_vehicles.length}');
      }

      _isLoading = false;
      notifyListeners();
      vehicleListenable.value = List.from(_vehicles);
    } catch (e) {
      print('Error fetching vehicles: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch more vehicles for pagination
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
        if (vehicle.makeModel.toLowerCase().contains(brand.toLowerCase())) {
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
          .delete();

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
