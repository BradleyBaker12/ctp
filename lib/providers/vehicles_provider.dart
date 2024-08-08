import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleProvider with ChangeNotifier {
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;

  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;

  ValueNotifier<List<Vehicle>> vehicleListenable = ValueNotifier([]);

  VehicleProvider() {
    fetchVehicles();
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
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('vehicles').get();
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
  final String treadLeft;
  final String? tyrePhoto1;
  final String? tyrePhoto2;
  final String tyreType;
  final String userId;
  final String vinNumber;
  final String warranty;
  final String warrantyType;
  final String year;

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
    required this.treadLeft,
    this.tyrePhoto1,
    this.tyrePhoto2,
    required this.tyreType,
    required this.userId,
    required this.vinNumber,
    required this.warranty,
    required this.warrantyType,
    required this.year,
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
      treadLeft: data['treadLeft'] ?? 'N/A',
      tyrePhoto1: data['tyrePhoto1'],
      tyrePhoto2: data['tyrePhoto2'],
      tyreType: data['tyreType'] ?? 'N/A',
      userId: data['userId'] ?? 'N/A',
      vinNumber: data['vinNumber'] ?? 'N/A',
      warranty: data['warranty'] ?? 'N/A',
      warrantyType: data['warrantyType'] ?? 'N/A',
      year: data['year'] ?? 'N/A',
    );
  }

  factory Vehicle.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return Vehicle.fromFirestore(data);
  }
}

