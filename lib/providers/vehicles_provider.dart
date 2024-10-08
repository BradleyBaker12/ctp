// lib/providers/vehicle_provider.dart

import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart'; // Ensure this import for ValueListenableBuilder

class VehicleProvider with ChangeNotifier {
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;
  DocumentSnapshot? _lastFetchedDocument;
  String? _vehicleId; // Field to store the vehicleId

  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;

  String? get vehicleId => _vehicleId; // Getter for vehicleId

  // Setter for vehicleId
  void setVehicleId(String id) {
    _vehicleId = id;
    notifyListeners(); // Notifies listeners when vehicleId changes
  }

  ValueNotifier<List<Vehicle>> vehicleListenable = ValueNotifier([]);

  VehicleProvider();

  void initialize(UserProvider userProvider) {
    fetchVehicles(userProvider); // Fetch vehicles as usual
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

  List<Vehicle> getVehiclesByUserId(String userId) {
    return _vehicles.where((vehicle) => vehicle.userId == userId).toList();
  }

  Future<void> fetchVehicles(UserProvider userProvider,
      {String? vehicleType,
      String? userId,
      bool filterLikedDisliked = true,
      int limit = 20}) async {
    try {
      _isLoading = true;

      Query query =
          FirebaseFirestore.instance.collection('vehicles').limit(limit);

      if (vehicleType != null) {
        query = query.where('vehicleType', isEqualTo: vehicleType);
      }

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastFetchedDocument = querySnapshot.docs.last;
      }

      _vehicles = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Vehicle.fromFirestore(data);
      }).toList();

      if (filterLikedDisliked) {
        _vehicles = _vehicles.where((vehicle) {
          return !userProvider.getLikedVehicles.contains(vehicle.id) &&
              !userProvider.getDislikedVehicles.contains(vehicle.id);
        }).toList();
      }

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

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .startAfterDocument(_lastFetchedDocument!)
          .limit(20) // Fetch 20 more vehicles
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastFetchedDocument = querySnapshot.docs.last;
      }

      final moreVehicles = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Vehicle.fromFirestore(data);
      }).toList();

      _vehicles.addAll(moreVehicles);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching more vehicles: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  List<String> getAllMakeModels() {
    final List<String> brands = [
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

    final Set<String> matchedBrands = {};

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
    final Set<String> normalizedTransmissions = {};

    for (var vehicle in _vehicles) {
      String normalized = _normalizeTransmission(vehicle.transmission);
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

  Future<List<Vehicle>> fetchRecentVehicles() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .orderBy('createdAt', descending: true)
          .limit(5)
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

  /// **New Method**: Update Vehicle
  Future<void> updateVehicle(Vehicle updatedVehicle) async {
    try {
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(updatedVehicle.id)
          .update(updatedVehicle.toMap());

      // Update the local list and notify listeners
      int index = _vehicles.indexWhere((v) => v.id == updatedVehicle.id);
      if (index != -1) {
        _vehicles[index] = updatedVehicle;
        notifyListeners();
      }
    } catch (e) {
      print("Error updating vehicle: $e");
    }
  }

  // Other existing methods...
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
  String vehicleAvailableImmediately; // Add this property
  String availableDate; // Add this property

  // New fields for additional photos
  final String? bed_bunk;
  final String? dashboard;
  final String? door_panels;
  final String? front_tyres_tread;
  final String? front_view;
  final String? left_front_45;
  final String? left_rear_45;
  final String? left_side_view;
  final String? license_disk;
  final String? rear_tyres_tread;
  final String? rear_view;
  final String? right_front_45;
  final String? right_rear_45;
  final String? right_side_view;
  final String? roof;
  final String? seats;
  final String? spare_wheel;

  final String vehicleStatus;

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
    this.bed_bunk,
    this.dashboard,
    this.door_panels,
    this.front_tyres_tread,
    this.front_view,
    this.left_front_45,
    this.left_rear_45,
    this.left_side_view,
    this.license_disk,
    this.rear_tyres_tread,
    this.rear_view,
    this.right_front_45,
    this.right_rear_45,
    this.right_side_view,
    this.roof,
    this.seats,
    this.spare_wheel,
    required this.vehicleStatus,
    required this.vehicleAvailableImmediately, // Initialize this property
    required this.availableDate, // Initialize this property
  });

  // Updated copyWith method
  Vehicle copyWith({
    String? id,
    String? accidentFree,
    String? application,
    String? bookValue,
    String? damageDescription,
    List<String?>? damagePhotos,
    String? dashboardPhoto,
    String? engineNumber,
    String? expectedSellingPrice,
    String? faultCodesPhoto,
    String? firstOwner,
    String? hydraulics,
    String? licenceDiskUrl,
    String? listDamages,
    String? maintenance,
    String? makeModel,
    String? mileage,
    String? mileageImage,
    String? oemInspection,
    String? mainImageUrl,
    List<String?>? photos,
    String? rc1NatisFile,
    String? registrationNumber,
    String? roadWorthy,
    String? settleBeforeSelling,
    String? settlementAmount,
    String? settlementLetterFile,
    String? spareTyre,
    String? suspension,
    String? transmission,
    String? config,
    String? treadLeft,
    String? tyrePhoto1,
    String? tyrePhoto2,
    String? tyreType,
    String? userId,
    String? vehicleType,
    String? vinNumber,
    String? warranty,
    String? warrantyType,
    String? weightClass,
    String? year,
    DateTime? createdAt,
    String? bed_bunk,
    String? dashboard,
    String? door_panels,
    String? front_tyres_tread,
    String? front_view,
    String? left_front_45,
    String? left_rear_45,
    String? left_side_view,
    String? license_disk,
    String? rear_tyres_tread,
    String? rear_view,
    String? right_front_45,
    String? right_rear_45,
    String? right_side_view,
    String? roof,
    String? seats,
    String? spare_wheel,
    String? vehicleStatus,
  }) {
    return Vehicle(
      id: id ?? this.id,
      accidentFree: accidentFree ?? this.accidentFree,
      application: application ?? this.application,
      bookValue: bookValue ?? this.bookValue,
      damageDescription: damageDescription ?? this.damageDescription,
      damagePhotos: damagePhotos ?? this.damagePhotos,
      dashboardPhoto: dashboardPhoto ?? this.dashboardPhoto,
      engineNumber: engineNumber ?? this.engineNumber,
      expectedSellingPrice: expectedSellingPrice ?? this.expectedSellingPrice,
      faultCodesPhoto: faultCodesPhoto ?? this.faultCodesPhoto,
      firstOwner: firstOwner ?? this.firstOwner,
      hydraulics: hydraulics ?? this.hydraulics,
      licenceDiskUrl: licenceDiskUrl ?? this.licenceDiskUrl,
      listDamages: listDamages ?? this.listDamages,
      maintenance: maintenance ?? this.maintenance,
      makeModel: makeModel ?? this.makeModel,
      mileage: mileage ?? this.mileage,
      mileageImage: mileageImage ?? this.mileageImage,
      oemInspection: oemInspection ?? this.oemInspection,
      mainImageUrl: mainImageUrl ?? this.mainImageUrl,
      photos: photos ?? this.photos,
      rc1NatisFile: rc1NatisFile ?? this.rc1NatisFile,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      roadWorthy: roadWorthy ?? this.roadWorthy,
      settleBeforeSelling: settleBeforeSelling ?? this.settleBeforeSelling,
      settlementAmount: settlementAmount ?? this.settlementAmount,
      settlementLetterFile: settlementLetterFile ?? this.settlementLetterFile,
      spareTyre: spareTyre ?? this.spareTyre,
      suspension: suspension ?? this.suspension,
      transmission: transmission ?? this.transmission,
      config: config ?? this.config,
      treadLeft: treadLeft ?? this.treadLeft,
      tyrePhoto1: tyrePhoto1 ?? this.tyrePhoto1,
      tyrePhoto2: tyrePhoto2 ?? this.tyrePhoto2,
      tyreType: tyreType ?? this.tyreType,
      userId: userId ?? this.userId,
      vehicleType: vehicleType ?? this.vehicleType,
      vinNumber: vinNumber ?? this.vinNumber,
      warranty: warranty ?? this.warranty,
      warrantyType: warrantyType ?? this.warrantyType,
      weightClass: weightClass ?? this.weightClass,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      bed_bunk: bed_bunk ?? this.bed_bunk,
      dashboard: dashboard ?? this.dashboard,
      door_panels: door_panels ?? this.door_panels,
      front_tyres_tread: front_tyres_tread ?? this.front_tyres_tread,
      front_view: front_view ?? this.front_view,
      left_front_45: left_front_45 ?? this.left_front_45,
      left_rear_45: left_rear_45 ?? this.left_rear_45,
      left_side_view: left_side_view ?? this.left_side_view,
      license_disk: license_disk ?? this.license_disk,
      rear_tyres_tread: rear_tyres_tread ?? this.rear_tyres_tread,
      rear_view: rear_view ?? this.rear_view,
      right_front_45: right_front_45 ?? this.right_front_45,
      right_rear_45: right_rear_45 ?? this.right_rear_45,
      right_side_view: right_side_view ?? this.right_side_view,
      roof: roof ?? this.roof,
      seats: seats ?? this.seats,
      spare_wheel: spare_wheel ?? this.spare_wheel,
      vehicleStatus: vehicleStatus ?? this.vehicleStatus,
      vehicleAvailableImmediately:
          vehicleAvailableImmediately ?? this.vehicleAvailableImmediately,
      availableDate: availableDate ?? this.availableDate,
    );
  }

  factory Vehicle.fromFirestore(Map<String, dynamic> data) {
    return Vehicle(
      id: data['id'] ?? '',
      accidentFree: data['accidentFree'] ?? 'N/A',
      application: data['application'] ?? 'N/A',
      bookValue: data['bookValue'] ?? 'N/A',
      damageDescription: data['damageDescription'] ?? '',
      damagePhotos: List<String?>.from(
          data['damagePhotos'] ?? []), // Ensure a list is always provided
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
      photos: List<String?>.from(
          data['photos'] ?? []), // Same here to ensure a valid list
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
      createdAt: _parseTimestamp(data['createdAt'], data['id']),
      bed_bunk: data['bed_bunk'],
      dashboard: data['dashboard'],
      door_panels: data['door_panels'],
      front_tyres_tread: data['front_tyres_tread'],
      front_view: data['front_view'],
      left_front_45: data['left_front_45'],
      left_rear_45: data['left_rear_45'],
      left_side_view: data['left_side_view'],
      license_disk: data['license_disk'],
      rear_tyres_tread: data['rear_tyres_tread'],
      rear_view: data['rear_view'],
      right_front_45: data['right_front_45'],
      right_rear_45: data['right_rear_45'],
      right_side_view: data['right_side_view'],
      roof: data['roof'],
      seats: data['seats'],
      spare_wheel: data['spare_wheel'],

      vehicleStatus: data['vehicleStatus'] ?? 'Live',
      vehicleAvailableImmediately: data['vehicleAvailableImmediately'] ?? '',
      availableDate: data['availableDate'] ?? '',
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp, String vehicleId) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else {
      print(
          'Warning: createdAt is null or invalid for vehicle ID $vehicleId. Using DateTime.now() as default.');
      return DateTime.now();
    }
  }

  factory Vehicle.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return Vehicle.fromFirestore(data);
  }

  /// **New Method**: Convert Vehicle to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'accidentFree': accidentFree,
      'application': application,
      'bookValue': bookValue,
      'damageDescription': damageDescription,
      'damagePhotos': damagePhotos,
      'dashboardPhoto': dashboardPhoto,
      'engineNumber': engineNumber,
      'expectedSellingPrice': expectedSellingPrice,
      'faultCodesPhoto': faultCodesPhoto,
      'firstOwner': firstOwner,
      'hydraulics': hydraulics,
      'licenceDiskUrl': licenceDiskUrl,
      'listDamages': listDamages,
      'maintenance': maintenance,
      'makeModel': makeModel,
      'mileage': mileage,
      'mileageImage': mileageImage,
      'oemInspection': oemInspection,
      'mainImageUrl': mainImageUrl,
      'photos': photos,
      'rc1NatisFile': rc1NatisFile,
      'registrationNumber': registrationNumber,
      'roadWorthy': roadWorthy,
      'settleBeforeSelling': settleBeforeSelling,
      'settlementAmount': settlementAmount,
      'settlementLetterFile': settlementLetterFile,
      'spareTyre': spareTyre,
      'suspension': suspension,
      'transmission': transmission,
      'config': config,
      'treadLeft': treadLeft,
      'tyrePhoto1': tyrePhoto1,
      'tyrePhoto2': tyrePhoto2,
      'tyreType': tyreType,
      'userId': userId,
      'vehicleType': vehicleType,
      'vinNumber': vinNumber,
      'warranty': warranty,
      'warrantyType': warrantyType,
      'weightClass': weightClass,
      'year': year,
      'createdAt': Timestamp.fromDate(createdAt),
      'bed_bunk': bed_bunk,
      'dashboard': dashboard,
      'door_panels': door_panels,
      'front_tyres_tread': front_tyres_tread,
      'front_view': front_view,
      'left_front_45': left_front_45,
      'left_rear_45': left_rear_45,
      'left_side_view': left_side_view,
      'license_disk': license_disk,
      'rear_tyres_tread': rear_tyres_tread,
      'rear_view': rear_view,
      'right_front_45': right_front_45,
      'right_rear_45': right_rear_45,
      'right_side_view': right_side_view,
      'roof': roof,
      'seats': seats,
      'spare_wheel': spare_wheel,
      'vehicleStatus': vehicleStatus,
    };
  }
}
