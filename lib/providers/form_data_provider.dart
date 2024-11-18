import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FormDataProvider with ChangeNotifier {
  // Form index management
  int _currentFormIndex = 0;
  String? _vehicleId;

  // SECTION 1: Basic Vehicle Information
  String? _vehicleType;
  String? _year;
  String? _makeModel;
  String? _sellingPrice;
  String? _vinNumber;
  String? _mileage;
  String? _config;
  String? _application;
  String? _engineNumber;
  String? _registrationNumber;
  String? _suspension;
  String? _transmissionType;
  String? _hydraulics;
  String? _maintenance;
  String? _warranty;
  String? _warrantyDetails;
  String? _requireToSettleType;

  // SECTION 2: Maintenance Information
  File? _maintenanceDocFile;
  String? _maintenanceDocUrl;
  File? _warrantyDocFile;
  String? _warrantyDocUrl;
  String _oemInspectionType = 'yes';
  String? _oemInspectionExplanation;

  // Add these properties at the top of the class
  File? _selectedMainImage;
  File? get selectedMainImage => _selectedMainImage;

  // Add these properties
  String? _mainImageUrl;
  String? get mainImageUrl => _mainImageUrl;

  // Add these properties for country management
  String? _country;
  String? get country => _country; // Getter for country

  // Getters for basic vehicle information
  String? get vehicleId => _vehicleId;
  String get vehicleType => _vehicleType ?? 'truck';
  String? get year => _year;
  String? get makeModel => _makeModel;
  String? get sellingPrice => _sellingPrice;
  String? get vinNumber => _vinNumber;
  String? get mileage => _mileage;
  String? get config => _config;
  String? get application => _application;
  String? get engineNumber => _engineNumber;
  String? get registrationNumber => _registrationNumber;
  String get suspension => _suspension ?? 'spring';
  String get transmissionType => _transmissionType ?? 'automatic';
  String get hydraulics => _hydraulics ?? 'yes';
  String get maintenance => _maintenance ?? 'yes';
  String get warranty => _warranty ?? 'yes';
  String? get warrantyDetails => _warrantyDetails;
  String get requireToSettleType => _requireToSettleType ?? 'yes';

  // Getters for maintenance information
  File? get maintenanceDocFile => _maintenanceDocFile;
  String? get maintenanceDocUrl => _maintenanceDocUrl;
  File? get warrantyDocFile => _warrantyDocFile;
  String? get warrantyDocUrl => _warrantyDocUrl;
  String get oemInspectionType => _oemInspectionType;
  String? get oemInspectionExplanation => _oemInspectionExplanation;

  // Setters for maintenance information
  void setMaintenanceDocFile(File? file, {bool notify = true}) {
    _maintenanceDocFile = file;
    if (notify) notifyListeners();
  }

  void setMaintenanceDocUrl(String? url, {bool notify = true}) {
    _maintenanceDocUrl = url;
    if (notify) notifyListeners();
  }

  void setWarrantyDocFile(File? file, {bool notify = true}) {
    _warrantyDocFile = file;
    if (notify) notifyListeners();
  }

  void setWarrantyDocUrl(String? url, {bool notify = true}) {
    _warrantyDocUrl = url;
    if (notify) notifyListeners();
  }

  void setOemInspectionType(String value, {bool notify = true}) {
    _oemInspectionType = value;
    if (value == 'yes') {
      _oemInspectionExplanation = null;
    }
    if (notify) notifyListeners();
  }

  void setOemInspectionExplanation(String? value, {bool notify = true}) {
    _oemInspectionExplanation = value;
    if (notify) notifyListeners();
  }

  // Setters for all fields
  void setVehicleId(String id, {bool notify = true}) {
    _vehicleId = id;
    if (notify) notifyListeners();
  }

  void setVehicleType(String? type, {bool notify = true}) {
    _vehicleType = type ?? 'truck';
    if (notify) notifyListeners();
  }

  void setYear(String? value, {bool notify = true}) {
    _year = value;
    if (notify) notifyListeners();
  }

  void setMakeModel(String? value, {bool notify = true}) {
    _makeModel = value;
    if (notify) notifyListeners();
  }

  void setSellingPrice(String? value, {bool notify = true}) {
    _sellingPrice = value;
    if (notify) notifyListeners();
  }

  void setVinNumber(String? value, {bool notify = true}) {
    _vinNumber = value;
    if (notify) notifyListeners();
  }

  void setMileage(String? value, {bool notify = true}) {
    _mileage = value;
    if (notify) notifyListeners();
  }

  void setConfig(String? value, {bool notify = true}) {
    _config = value;
    if (notify) notifyListeners();
  }

  void setApplication(String? value, {bool notify = true}) {
    _application = value;
    if (notify) notifyListeners();
  }

  void setEngineNumber(String? value, {bool notify = true}) {
    _engineNumber = value;
    if (notify) notifyListeners();
  }

  void setRegistrationNumber(String? value, {bool notify = true}) {
    _registrationNumber = value;
    if (notify) notifyListeners();
  }

  void setSuspension(String? value, {bool notify = true}) {
    _suspension = value;
    if (notify) notifyListeners();
  }

  void setTransmissionType(String? value, {bool notify = true}) {
    _transmissionType = value;
    if (notify) notifyListeners();
  }

  void setHydraulics(String? value, {bool notify = true}) {
    _hydraulics = value;
    if (notify) notifyListeners();
  }

  void setMaintenance(String? value, {bool notify = true}) {
    _maintenance = value;
    if (notify) notifyListeners();
  }

  void setWarranty(String? value, {bool notify = true}) {
    _warranty = value;
    if (notify) notifyListeners();
  }

  void setWarrantyDetails(String? value, {bool notify = true}) {
    _warrantyDetails = value;
    if (notify) notifyListeners();
  }

  void setRequireToSettleType(String? value, {bool notify = true}) {
    _requireToSettleType = value;
    if (notify) notifyListeners();
  }

  // Save form state to SharedPreferences
  Future<void> saveFormState() async {
    final prefs = await SharedPreferences.getInstance();

    // Save basic vehicle information
    await prefs.setString('vehicleType', _vehicleType ?? '');
    await prefs.setString('year', _year ?? '');
    await prefs.setString('makeModel', _makeModel ?? '');
    await prefs.setString('sellingPrice', _sellingPrice ?? '');
    await prefs.setString('vinNumber', _vinNumber ?? '');
    await prefs.setString('mileage', _mileage ?? '');
    await prefs.setString('config', _config ?? '');
    await prefs.setString('application', _application ?? '');
    await prefs.setString('engineNumber', _engineNumber ?? '');
    await prefs.setString('registrationNumber', _registrationNumber ?? '');
    await prefs.setString('suspension', _suspension ?? '');
    await prefs.setString('transmissionType', _transmissionType ?? '');
    await prefs.setString('hydraulics', _hydraulics ?? '');
    await prefs.setString('maintenance', _maintenance ?? '');
    await prefs.setString('warranty', _warranty ?? '');
    await prefs.setString('warrantyDetails', _warrantyDetails ?? '');
    await prefs.setString('requireToSettleType', _requireToSettleType ?? '');

    // Save maintenance information
    await prefs.setString('maintenanceDocUrl', _maintenanceDocUrl ?? '');
    await prefs.setString('warrantyDocUrl', _warrantyDocUrl ?? '');
    await prefs.setString('oemInspectionType', _oemInspectionType);
    await prefs.setString(
        'oemInspectionExplanation', _oemInspectionExplanation ?? '');
  }

  // Load form state from SharedPreferences
  Future<void> loadFormState() async {
    final prefs = await SharedPreferences.getInstance();

    // Load basic vehicle information
    _vehicleType = prefs.getString('vehicleType');
    _year = prefs.getString('year');
    _makeModel = prefs.getString('makeModel');
    _sellingPrice = prefs.getString('sellingPrice');
    _vinNumber = prefs.getString('vinNumber');
    _mileage = prefs.getString('mileage');
    _config = prefs.getString('config');
    _application = prefs.getString('application');
    _engineNumber = prefs.getString('engineNumber');
    _registrationNumber = prefs.getString('registrationNumber');
    _suspension = prefs.getString('suspension');
    _transmissionType = prefs.getString('transmissionType');
    _hydraulics = prefs.getString('hydraulics');
    _maintenance = prefs.getString('maintenance');
    _warranty = prefs.getString('warranty');
    _warrantyDetails = prefs.getString('warrantyDetails');
    _requireToSettleType = prefs.getString('requireToSettleType');

    // Load maintenance information
    _maintenanceDocUrl = prefs.getString('maintenanceDocUrl');
    _warrantyDocUrl = prefs.getString('warrantyDocUrl');
    _oemInspectionType = prefs.getString('oemInspectionType') ?? 'yes';
    _oemInspectionExplanation = prefs.getString('oemInspectionExplanation');

    notifyListeners();
  }

  // Clear all form data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _referenceNumber = null;
    _brands = null;

    // Clear basic vehicle information
    _vehicleId = null;
    _vehicleType = null;
    _year = null;
    _makeModel = null;
    _sellingPrice = null;
    _vinNumber = null;
    _mileage = null;
    _config = null;
    _application = null;
    _engineNumber = null;
    _registrationNumber = null;
    _suspension = null;
    _transmissionType = null;
    _maintenance = null;

    // Clear maintenance information
    _maintenanceDocFile = null;
    _maintenanceDocUrl = null;
    _warrantyDocFile = null;
    _warrantyDocUrl = null;
    _oemInspectionType = 'yes';
    _oemInspectionExplanation = null;

    _hydraulics = 'no';
    _maintenance = 'no';
    _warranty = 'no';
    _warrantyDetails = null;
    _requireToSettleType = 'no';
    _referenceNumber = null;
    _brands = [];
    _selectedMainImage = null;
    _mainImageUrl = null;
    _natisRc1Url = null;

    notifyListeners();
  }

  void setSelectedMainImage(File? image) {
    _selectedMainImage = image;
    notifyListeners();
  }

  // Add this method
  void setMainImageUrl(String? url, {bool notify = true}) {
    _mainImageUrl = url;
    if (notify) notifyListeners();
  }

  String? _natisRc1Url;

  String? get natisRc1Url => _natisRc1Url;

  void setNatisRc1Url(String? url, {bool notify = true}) {
    _natisRc1Url = url;
    if (notify) notifyListeners();
  }

  int get currentFormIndex => _currentFormIndex;

  void setCurrentFormIndex(int index) {
    _currentFormIndex = index;
    notifyListeners();
  }

  String? _referenceNumber;
  List<String>? _brands;

  String? get referenceNumber => _referenceNumber;
  List<String>? get brands => _brands;

  void setReferenceNumber(String? value, {bool notify = true}) {
    _referenceNumber = value;
    if (notify) notifyListeners();
  }

  void setBrands(List<String>? value, {bool notify = true}) {
    _brands = value;
    if (notify) notifyListeners();
  }

  String? _vehicleStatus;

  void setVehicleStatus(String? status) {
    _vehicleStatus = status;
    notifyListeners();
  }

  // Setter for country
  void setCountry(String? value, {bool notify = true}) {
    _country = value;
    if (notify) notifyListeners();
  }
}
