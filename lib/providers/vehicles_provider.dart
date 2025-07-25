// lib/providers/vehicle_provider.dart

import 'package:ctp/models/vehicle.dart' as model;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_provider.dart';
import 'package:cloud_functions/cloud_functions.dart';

class VehicleProvider with ChangeNotifier {
  List<model.Vehicle> _vehicles = [];
  bool _isLoading = true;
  DocumentSnapshot? _lastFetchedDocument;
  String? _vehicleId; // Field to store the vehicleId

  List<model.Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get vehicleId => _vehicleId;

  // Add a list for bought vehicles
  List<model.Vehicle> _boughtVehicles = [];

  // Add getter for bought vehicles
  List<model.Vehicle> getBoughtVehicles() => _boughtVehicles;

  // Setter for vehicleId
  void setVehicleId(String id) {
    _vehicleId = id;
    notifyListeners(); // Notifies listeners when vehicleId changes
  }

  ValueNotifier<List<model.Vehicle>> vehicleListenable = ValueNotifier([]);

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
  void addVehicle(model.Vehicle vehicle) {
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
  List<model.Vehicle> getVehiclesByUserId(String userId) {
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

      // print('DEBUG: Fetching vehicles for userId: $userId');
      // print('DEBUG: Current user from UserProvider: ${userProvider.userId}');

      Query query = FirebaseFirestore.instance
          .collection('vehicles')
          .orderBy('createdAt', descending: true);

      if (userId != null) {
        // print('DEBUG: Filtering by userId: $userId');
        query = query.where('userId', isEqualTo: userId);
      }

      QuerySnapshot querySnapshot = await query.get();
      // print('DEBUG: Found ${querySnapshot.docs.length} vehicles in total');

      // Debug information about all vehicles
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // print('DEBUG: Vehicle ID: ${doc.id}');
        // print('DEBUG: Vehicle userId: ${data['userId']}');
        // print('DEBUG: Vehicle makeModel: ${data['makeModel']}');
        // print('DEBUG: Vehicle status: ${data['vehicleStatus']}');
        // print('-------------------');
      }

      _vehicles = querySnapshot.docs
          .map((doc) {
            try {
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

              // Safely handle trailer data
              if (data['trailerExtraInfo'] != null) {
                // print('DEBUG: Processing trailer data for vehicle ${doc.id}');
                // Convert any nested maps to proper format
                Map<String, dynamic> processedData =
                    Map<String, dynamic>.from(data);
                processedData['trailerExtraInfo'] =
                    _processTrailerData(data['trailerExtraInfo']);
                return model.Vehicle.fromFirestore(doc.id, processedData);
              }

              return model.Vehicle.fromFirestore(doc.id, data);
            } catch (e) {
              // print('Error processing vehicle ${doc.id}: $e');
              return null;
            }
          })
          .whereType<model.Vehicle>()
          .toList(); // Filter out null values

      // print('DEBUG: Final processed vehicles count: ${_vehicles.length}');
      if (userId != null) {
        // print('DEBUG: Vehicles matching userId $userId:');
        for (var vehicle in _vehicles) {
          // print('model.Vehicle ID: ${vehicle.id}, Model: ${vehicle.makeModel}');
        }
      }

      vehicleListenable.value = List<model.Vehicle>.from(_vehicles);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching vehicles: $e');
      print('Error stack trace: ${StackTrace.current}');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to process trailer data
  Map<String, dynamic> _processTrailerData(dynamic trailerData) {
    if (trailerData == null) return {};

    if (trailerData is Map) {
      var processed = Map<String, dynamic>.fromEntries(trailerData.entries.map(
          (e) => MapEntry(e.key.toString(),
              e.value is Map ? _processTrailerData(e.value) : e.value)));

      // Ensure additionalImages is properly formatted if it exists
      if (processed['additionalImages'] != null) {
        if (processed['additionalImages'] is List) {
          processed['additionalImages'] =
              (processed['additionalImages'] as List)
                  .map((item) {
                    if (item is Map) {
                      return Map<String, dynamic>.from(item);
                    }
                    return <String, dynamic>{
                      'description': '',
                      'imageUrl': '',
                    };
                  })
                  .where((item) =>
                      item['imageUrl'] != null &&
                      item['imageUrl'].toString().isNotEmpty)
                  .toList();
        } else {
          processed['additionalImages'] = [];
        }
      }

      return processed;
    }

    return {};
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
        return model.Vehicle.fromFirestore(
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
      // print('DEBUG: Starting fetchAllVehicles');

      Query query = FirebaseFirestore.instance
          .collection('vehicles')
          .orderBy('createdAt', descending: true);

      QuerySnapshot querySnapshot = await query.get();
      // print('DEBUG: Total vehicles in Firestore: ${querySnapshot.docs.length}');

      // Debug print all vehicles before processing
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // print('DEBUG: model.Vehicle ID: ${doc.id}');
        // print('DEBUG: model.Vehicle userId: ${data['userId']}');
        // print('DEBUG: model.Vehicle makeModel: ${data['makeModel']}');
        // print('DEBUG: model.Vehicle status: ${data['vehicleStatus']}');
        // print('-------------------');
      }

      _vehicles = querySnapshot.docs
          .map((doc) {
            if (doc.exists &&
                doc.data() != null &&
                doc.data() is Map<String, dynamic>) {
              // print('Processing model.Vehicle ID: ${doc.id}');
              try {
                return model.Vehicle.fromFirestore(
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
          .cast<model.Vehicle>()
          .toList();

      if (_vehicles.isEmpty) {
        print('No valid vehicles found after parsing.');
      }

      // print('DEBUG: Final processed vehicles count: ${_vehicles.length}');
      // print('DEBUG: Processed vehicles summary:');
      for (var vehicle in _vehicles) {
        // print('model.Vehicle ID: ${vehicle.id}');
        // print('UserID: ${vehicle.userId}');
        // print('Model: ${vehicle.makeModel}');
        // print('Status: ${vehicle.vehicleStatus}');
        // print('-------------------');
      }

      vehicleListenable.value = List.from(_vehicles);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error in fetchAllVehicles: $e');
      print('Error stack trace: ${StackTrace.current}');
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
  Future<List<model.Vehicle>> fetchRecentVehicles() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      final recentVehicles = querySnapshot.docs.map((doc) {
        return model.Vehicle.fromFirestore(
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

      print("model.Vehicle deleted successfully.");
    } catch (e) {
      print("Error deleting vehicle: $e");
      rethrow; // Rethrow the error to handle it in the UI
    }
  }

  // Update a vehicle
  Future<void> updateVehicle(model.Vehicle updatedVehicle) async {
    try {
      // Update the vehicle document
      DocumentReference vehicleRef = FirebaseFirestore.instance
          .collection('vehicles')
          .doc(updatedVehicle.id);
      await vehicleRef.update(updatedVehicle.toMap());
      print("model.Vehicle updated successfully.");

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

  // Add this method to get the total count of vehicles
  int getVehicleCount() {
    return _vehicles.length;
  }

  Future<List<model.Vehicle>> fetchVehiclesForDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    try {
      final QuerySnapshot vehicleSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('uploadTimestamp', isGreaterThanOrEqualTo: startDate)
          .where('uploadTimestamp', isLessThanOrEqualTo: endDate)
          .where('vehicleStatus', isEqualTo: 'Live')
          .orderBy('uploadTimestamp', descending: true)
          .limit(limit)
          .get();

      return vehicleSnapshot.docs.map((doc) {
        return model.Vehicle.fromFirestore(
            doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error fetching vehicles for date range: $e');
      return [];
    }
  }

  Future<List<model.Vehicle>> fetchVehiclesForToday() async {
    try {
      print('Fetching today\'s live vehicles...');

      final QuerySnapshot vehicleSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('vehicleStatus', isEqualTo: 'Live')
          .orderBy('createdAt', descending: true)
          .get();

      print('Found ${vehicleSnapshot.docs.length} documents, processing...');

      List<model.Vehicle> vehicles = [];
      for (var doc in vehicleSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // Check if the document was created today
          if (data['createdAt'] is Timestamp) {
            DateTime createdAt = (data['createdAt'] as Timestamp).toDate();
            DateTime now = DateTime.now();
            if (createdAt.year == now.year &&
                createdAt.month == now.month &&
                createdAt.day == now.day) {
              vehicles.add(model.Vehicle.fromFirestore(doc.id, data));
            }
          }
        } catch (e) {
          print('Error processing vehicle ${doc.id}: $e');
          continue;
        }
      }

      print('Successfully processed ${vehicles.length} vehicles for today');
      return vehicles;
    } catch (e) {
      print('Error fetching today\'s vehicles: $e');
      return [];
    }
  }

  Future<List<model.Vehicle>> fetchVehiclesForYesterday() async {
    try {
      print('Fetching yesterday\'s live vehicles...');

      final QuerySnapshot vehicleSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('vehicleStatus', isEqualTo: 'Live')
          .orderBy('createdAt', descending: true)
          .get();

      print('Found ${vehicleSnapshot.docs.length} documents, processing...');

      List<model.Vehicle> vehicles = [];
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      for (var doc in vehicleSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          // Check if the document was created yesterday
          if (data['createdAt'] is Timestamp) {
            DateTime createdAt = (data['createdAt'] as Timestamp).toDate();
            if (createdAt.year == yesterday.year &&
                createdAt.month == yesterday.month &&
                createdAt.day == yesterday.day) {
              vehicles.add(model.Vehicle.fromFirestore(doc.id, data));
            }
          }
        } catch (e) {
          print('Error processing vehicle ${doc.id}: $e');
          continue;
        }
      }

      print('Successfully processed ${vehicles.length} vehicles for yesterday');
      return vehicles;
    } catch (e) {
      print('Error fetching yesterday\'s vehicles: $e');
      return [];
    }
  }

   /// Returns a sorted list of unique company names (falling back to 'Anonymous'),
  /// with 'All' as the first option.
  List<String> getAllCompanies() {
    final companies = _vehicles
        .map((v) => v.companyName ?? 'Anonymous')
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ['All', ...companies];
  }

  // Update the method to fetch bought vehicles
  Future<void> fetchBoughtVehicles(UserProvider userProvider,
      {required String userId}) async {
    try {
      // First, get all offers where this dealer is the buyer and the offer is successful/completed
      final QuerySnapshot offerSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('dealerId', isEqualTo: userId)
          .where('offerStatus', whereIn: ['sold', 'completed']).get();

      // Extract vehicle IDs from the offers
      final vehicleIds = offerSnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['vehicleId'] as String?;
          })
          .where((id) => id != null)
          .toList();

      if (vehicleIds.isEmpty) {
        _boughtVehicles = [];
        notifyListeners();
        return;
      }

      // Fetch the actual vehicles using the vehicle IDs
      final vehiclesSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where(FieldPath.documentId, whereIn: vehicleIds)
          .get();

      _boughtVehicles = vehiclesSnapshot.docs
          .map((doc) => model.Vehicle.fromFirestore(doc.id, doc.data()))
          .toList();

      notifyListeners();
    } catch (e) {
      print('Error fetching bought vehicles: $e');
      _boughtVehicles = [];
      notifyListeners();
    }
  }

  Future<void> publishVehicle(String vehicleId) async {
    try {
      // Update vehicle status to live
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .update({
        'status': 'live',
        'publishedAt': FieldValue.serverTimestamp(),
      });

      // Trigger cloud function to send notifications
      final functions = FirebaseFunctions.instance;
      await functions.httpsCallable('sendNewVehicleNotification').call({
        'vehicleId': vehicleId,
      });

      notifyListeners();
    } catch (e) {
      print('Error publishing vehicle: $e');
      rethrow;
    }
  }
}
