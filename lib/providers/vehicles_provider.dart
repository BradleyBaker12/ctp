import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleProvider with ChangeNotifier {
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;
  DocumentSnapshot? _lastFetchedDocument;

  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;

  ValueNotifier<List<Vehicle>> vehicleListenable = ValueNotifier([]);

  VehicleProvider() {
    fetchVehicles(); // Fetch vehicles as usual
  }

  void addVehicle(Vehicle vehicle) {
    _vehicles.add(vehicle);
    vehicleListenable.value = List.from(_vehicles);
    notifyListeners();
  }

  void removeVehicle(int index) {
    _vehicles.removeAt(index);
    vehicleListenable.value = List.from(_vehicles);
    notifyListeners();
  }

  Future<void> fetchVehicles() async {
    try {
      _isLoading = true;
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .limit(10) // Limit the initial fetch to 10 documents
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastFetchedDocument =
            querySnapshot.docs.last; // Keep track of the last fetched document
      }

      _vehicles = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Vehicle.fromFirestore(data);
      }).toList();

      _isLoading = false;
      vehicleListenable.value = List.from(_vehicles);
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

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .startAfterDocument(
              _lastFetchedDocument!) // Start fetching after the last fetched document
          .limit(10) // Limit to next 10 documents
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastFetchedDocument =
            querySnapshot.docs.last; // Update the last fetched document
      }

      final moreVehicles = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Vehicle.fromFirestore(data);
      }).toList();

      _vehicles.addAll(moreVehicles);
      _isLoading = false;
      vehicleListenable.value = List.from(_vehicles);
      notifyListeners();
    } catch (e) {
      print('Error fetching more vehicles: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to get unique makeModels from the vehicle list
  List<String> getAllMakeModels() {
    // List of brand names to filter by
    final List<String> brands = [
      'DAF',
      'FUSO',
      'HINO',
      'ISUZU',
      'IVECO',
      'MAN',
      'MERCEDES-BENZ',
      'SSCANIA',
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

    final Set<String> matchedBrands = {};

    for (var vehicle in _vehicles) {
      for (var brand in brands) {
        if (vehicle.makeModel.toLowerCase().contains(brand.toLowerCase())) {
          matchedBrands.add(brand);
          break; // No need to check other brands if one is matched
        }
      }
    }

    return ['All', ...matchedBrands];
  }

  // Method to check if a vehicle's makeModel contains a specific brand
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
      // Handle cases where year might be "N/A" or non-numeric
      if (a == 'N/A') return 1;
      if (b == 'N/A') return -1;
      return int.parse(a).compareTo(int.parse(b));
    });

    return ['All', ...years];
  }

  // Method to get unique transmissions from the vehicle list with normalization
  List<String> getAllTransmissions() {
    final Set<String> normalizedTransmissions = {};

    for (var vehicle in _vehicles) {
      String normalized = _normalizeTransmission(vehicle.transmission);
      if (normalized.isNotEmpty && normalized != 'n/a') {
        normalizedTransmissions.add(normalized);
      }
    }

    // Add 'All' as the first option and remove duplicates
    return [
      'All',
      ...normalizedTransmissions
          .where((trans) => trans != 'n/a' && trans != 'automatic')
    ];
  }

  // Helper method to normalize transmission names
  String _normalizeTransmission(String transmission) {
    transmission = transmission.toLowerCase();
    if (transmission == 'auto' || transmission == 'automatic') {
      return 'Automatic';
    } else if (transmission == 'manual') {
      return 'Manual';
    }
    return transmission; // Return as is for other values, like "n/a"
  }

  // New method to fetch 5 most recently added vehicles
  Future<List<Vehicle>> fetchRecentVehicles() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .orderBy('createdAt', descending: true) // Order by createdAt field
          .limit(5) // Limit to 5 most recent vehicles
          .get();

      final recentVehicles = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Vehicle.fromFirestore(data);
      }).toList();

      return recentVehicles;
    } catch (e) {
      print('Error fetching recent vehicles: $e');
      return [];
    }
  }
}

class Vehicle {
  final String id;
  final String accidentFree;
  final String application;
  final String bookValue;
  final String damageDescription;
  final List<String?> damagePhotos;
  final String? dashboardPhoto;
  final String engineNumber;
  final String expectedSellingPrice;
  final String? faultCodesPhoto;
  final String firstOwner;
  final String hydraulics;
  final String? licenceDiskUrl;
  final String listDamages;
  final String maintenance;
  final String makeModel;
  final String mileage;
  final String? mileageImage;
  final String oemInspection;
  final String? mainImageUrl;
  final List<String?> photos;
  final String? rc1NatisFile;
  final String registrationNumber;
  final String roadWorthy;
  final String settleBeforeSelling;
  final String settlementAmount;
  final String? settlementLetterFile;
  final String spareTyre;
  final String suspension;
  final String transmission;
  final String? config;
  final String? treadLeft;
  final String? tyrePhoto1;
  final String? tyrePhoto2;
  final String tyreType;
  final String userId;
  final String vehicleType;
  final String vinNumber;
  final String warranty;
  final String warrantyType;
  final String weightClass;
  final String year;
  final DateTime createdAt;

  Vehicle({
    required this.id,
    required this.accidentFree,
    required this.application,
    required this.bookValue,
    required this.damageDescription,
    required this.damagePhotos,
    this.dashboardPhoto,
    required this.engineNumber,
    required this.expectedSellingPrice,
    this.faultCodesPhoto,
    required this.firstOwner,
    required this.hydraulics,
    this.licenceDiskUrl,
    required this.listDamages,
    required this.maintenance,
    required this.makeModel,
    required this.mileage,
    this.mileageImage,
    required this.oemInspection,
    this.mainImageUrl,
    required this.photos,
    this.rc1NatisFile,
    required this.registrationNumber,
    required this.roadWorthy,
    required this.settleBeforeSelling,
    required this.settlementAmount,
    this.settlementLetterFile,
    required this.spareTyre,
    required this.suspension,
    required this.transmission,
    this.config,
    this.treadLeft,
    this.tyrePhoto1,
    this.tyrePhoto2,
    required this.tyreType,
    required this.userId,
    required this.vehicleType,
    required this.vinNumber,
    required this.warranty,
    required this.warrantyType,
    required this.weightClass,
    required this.year,
    required this.createdAt,
  });

  factory Vehicle.fromFirestore(Map<String, dynamic> data) {
    return Vehicle(
      id: data['id'] ?? '',
      accidentFree: data['accidentFree'] ?? 'N/A',
      application: data['application'] ?? 'N/A',
      bookValue: data['bookValue'] ?? 'N/A',
      damageDescription: data['damageDescription'] ?? '',
      damagePhotos: List<String?>.from(data['damagePhotos'] ?? []),
      dashboardPhoto: data['dashboardPhoto'],
      engineNumber: data['engineNumber'] ?? 'N/A',
      expectedSellingPrice: data['expectedSellingPrice'] ?? 'N/A',
      faultCodesPhoto: data['faultCodesPhoto'],
      firstOwner: data['firstOwner'] ?? 'N/A',
      hydraulics: data['hydraulics'] ?? 'N/A',
      licenceDiskUrl: data['licenceDiskUrl'],
      listDamages: data['listDamages'] ?? 'N/A',
      maintenance: data['maintenance'] ?? 'N/A',
      makeModel: data['makeModel'] ?? 'N/A',
      mileage: data['mileage'] ?? 'N/A',
      mileageImage: data['mileageImage'],
      oemInspection: data['oemInspection'] ?? 'N/A',
      mainImageUrl: data['mainImageUrl'],
      photos: List<String?>.from(data['photos'] ?? []),
      rc1NatisFile: data['rc1NatisFile'],
      registrationNumber: data['registrationNumber'] ?? 'N/A',
      roadWorthy: data['roadWorthy'] ?? 'N/A',
      settleBeforeSelling: data['settleBeforeSelling'] ?? 'N/A',
      settlementAmount: data['settlementAmount'] ?? 'N/A',
      settlementLetterFile: data['settlementLetterFile'],
      spareTyre: data['spareTyre'] ?? 'N/A',
      suspension: data['suspension'] ?? 'N/A',
      transmission: data['transmission'] ?? 'N/A',
      treadLeft: data['treadLeft'],
      tyrePhoto1: data['tyrePhoto1'],
      tyrePhoto2: data['tyrePhoto2'],
      tyreType: data['tyreType'] ?? 'N/A',
      userId: data['userId'] ?? 'N/A',
      vehicleType: data['vehicleType'] ?? 'N/A',
      vinNumber: data['vinNumber'] ?? 'N/A',
      warranty: data['warranty'] ?? 'N/A',
      warrantyType: data['warrantyType'] ?? 'N/A',
      weightClass: data['weightClass'] ?? 'N/A',
      year: data['year'] ?? 'N/A',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  factory Vehicle.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return Vehicle.fromFirestore(data);
  }
}
