import 'package:flutter/material.dart';

class Vehicle {
  final String id;
  final String make;
  final String model;
  final String registration;
  final String year;
  final String vinNumber;
  // Add other vehicle properties as needed

  Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.registration,
    required this.year,
    required this.vinNumber,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      registration: json['registration'] ?? '',
      year: json['year'] ?? '',
      vinNumber: json['vinNumber'] ?? '',
    );
  }
}

class VehicleProvider with ChangeNotifier {
  List<Vehicle> _vehicles = [];

  List<Vehicle> get vehicles => [..._vehicles];

  Vehicle? getVehicleById(String id) {
    try {
      return _vehicles.firstWhere((vehicle) => vehicle.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> fetchVehicles() async {
    // TODO: Implement fetching vehicles from your database
    notifyListeners();
  }
}
