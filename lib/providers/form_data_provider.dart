import 'package:flutter/foundation.dart';
import 'dart:io';
// Added for Uint8List
import 'package:shared_preferences/shared_preferences.dart';

class FormDataProvider with ChangeNotifier {
  // Form index management
  int _currentFormIndex = 0;
  String? _vehicleId;

  // SECTION 1: Basic Vehicle Information
  String? _vehicleType;
  String? _year;
  String? _variant;
  String? _makeModel;
  String? _make; // Newly added
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

  // Main Image
  // --- FIX APPLIED: Change type from File? to Uint8List? ---
  Uint8List? _selectedMainImage;
  Uint8List? get selectedMainImage => _selectedMainImage;

  String? _mainImageUrl;
  String? get mainImageUrl => _mainImageUrl;

  String? _country;
  String? get country => _country;

  // Basic Vehicle Information Getters
  String? get vehicleId => _vehicleId;
  String get vehicleType => _vehicleType ?? 'truck';
  String? get year => _year;
  String? get make => _make; // Getter for make
  String? get variant => _variant;
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

  // Maintenance Information Getters
  File? get maintenanceDocFile => _maintenanceDocFile;
  String? get maintenanceDocUrl => _maintenanceDocUrl;
  File? get warrantyDocFile => _warrantyDocFile;
  String? get warrantyDocUrl => _warrantyDocUrl;
  String get oemInspectionType => _oemInspectionType;
  String? get oemInspectionExplanation => _oemInspectionExplanation;

  // Maintenance Setters
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

  // Setters for basic vehicle information
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

  void setVariant(String? value, {bool notify = true}) {
    _variant = value;
    if (notify) notifyListeners();
  }

  void setMakeModel(String? value, {bool notify = true}) {
    _makeModel = value;
    if (notify) notifyListeners();
  }

  void setMake(String? value, {bool notify = true}) {
    _make = value;
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

  // --- FIX APPLIED: Update the main image setter to accept Uint8List instead of File ---
  void setSelectedMainImage(Uint8List? image, fileName) {
    _selectedMainImage = image;
    notifyListeners();
  }

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

  void setCountry(String? value, {bool notify = true}) {
    _country = value;
    if (notify) notifyListeners();
  }

  String? _province;
  String? get province => _province;
  void setProvince(String? value, {bool notify = true}) {
    _province = value;
    if (notify) notifyListeners();
  }

  // Trailer fields
  String? _trailerType;
  // Change axles to String? to allow isEmpty checks
  String? _axles;
  String? _length;
  String? _vinTrailerA;
  String? _registrationTrailerA;
  String? _vinTrailerB;
  String? _registrationTrailerB;
  String? _damagesDescription;
  String? _additionalFeatures;

  File? _frontSidesImage;
  File? _frontTyresImage;
  File? _frontChassisImage;
  File? _frontDeckImage;
  File? _frontMakersPlateImage;

  File? _rearSidesImage;
  File? _rearTyresImage;
  File? _rearChassisImage;
  File? _rearDeckImage;
  File? _rearMakersPlateImage;

  final List<File> _damageImages = [];

  // Getters for Trailer
  String? get trailerType => _trailerType;
  String? get axles => _axles;
  String? get length => _length;
  String? get vinTrailerA => _vinTrailerA;
  String? get registrationTrailerA => _registrationTrailerA;
  String? get vinTrailerB => _vinTrailerB;
  String? get registrationTrailerB => _registrationTrailerB;
  String? get damagesDescription => _damagesDescription;
  String? get additionalFeatures => _additionalFeatures;

  File? get frontSidesImage => _frontSidesImage;
  File? get frontTyresImage => _frontTyresImage;
  File? get frontChassisImage => _frontChassisImage;
  File? get frontDeckImage => _frontDeckImage;
  File? get frontMakersPlateImage => _frontMakersPlateImage;

  File? get rearSidesImage => _rearSidesImage;
  File? get rearTyresImage => _rearTyresImage;
  File? get rearChassisImage => _rearChassisImage;
  File? get rearDeckImage => _rearDeckImage;
  File? get rearMakersPlateImage => _rearMakersPlateImage;

  List<File> get damageImages => _damageImages;

  // Trailer Setters
  void setTrailerType(String? value, {bool notify = true}) {
    _trailerType = value;
    if (notify) notifyListeners();
  }

  void setAxles(String? value, {bool notify = true}) {
    _axles = value;
    if (notify) notifyListeners();
  }

  void setLength(String? value, {bool notify = true}) {
    _length = value;
    if (notify) notifyListeners();
  }

  void setVinTrailer(String? value, {bool notify = true}) {
    _vinTrailerA = value;
    if (notify) notifyListeners();
  }

  void setRegistrationTrailerA(String? value, {bool notify = true}) {
    _registrationTrailerA = value;
    if (notify) notifyListeners();
  }

  void setVinTrailerB(String? value, {bool notify = true}) {
    _vinTrailerB = value;
    if (notify) notifyListeners();
  }

  void setRegistrationTrailerB(String? value, {bool notify = true}) {
    _registrationTrailerB = value;
    if (notify) notifyListeners();
  }

  void setDamagesDescription(String? value, {bool notify = true}) {
    _damagesDescription = value;
    if (notify) notifyListeners();
  }

  void setAdditionalFeatures(String? value, {bool notify = true}) {
    _additionalFeatures = value;
    if (notify) notifyListeners();
  }

  // Trailer Images Setters
  void setFrontSidesImage(File? image, {bool notify = true}) {
    _frontSidesImage = image;
    if (notify) notifyListeners();
  }

  void setFrontTyresImage(File? image, {bool notify = true}) {
    _frontTyresImage = image;
    if (notify) notifyListeners();
  }

  void setFrontChassisImage(File? image, {bool notify = true}) {
    _frontChassisImage = image;
    if (notify) notifyListeners();
  }

  void setFrontDeckImage(File? image, {bool notify = true}) {
    _frontDeckImage = image;
    if (notify) notifyListeners();
  }

  void setFrontMakersPlateImage(File? image, {bool notify = true}) {
    _frontMakersPlateImage = image;
    if (notify) notifyListeners();
  }

  void setRearSidesImage(File? image, {bool notify = true}) {
    _rearSidesImage = image;
    if (notify) notifyListeners();
  }

  void setRearTyresImage(File? image, {bool notify = true}) {
    _rearTyresImage = image;
    if (notify) notifyListeners();
  }

  void setRearChassisImage(File? image, {bool notify = true}) {
    _rearChassisImage = image;
    if (notify) notifyListeners();
  }

  void setRearDeckImage(File? image, {bool notify = true}) {
    _rearDeckImage = image;
    if (notify) notifyListeners();
  }

  void setRearMakersPlateImage(File? image, {bool notify = true}) {
    _rearMakersPlateImage = image;
    if (notify) notifyListeners();
  }

  // Damage Images
  void addDamageImage(File image, {bool notify = true}) {
    _damageImages.add(image);
    if (notify) notifyListeners();
  }

  void removeDamageImage(File image, {bool notify = true}) {
    _damageImages.remove(image);
    if (notify) notifyListeners();
  }

  void clearDamageImages({bool notify = true}) {
    _damageImages.clear();
    if (notify) notifyListeners();
  }

  void clearTrailerImages({bool notify = true}) {
    _trailerType = null;
    _axles = null;
    _length = null;
    _vinTrailerA = null;
    _registrationTrailerA = null;
    _vinTrailerB = null;
    _registrationTrailerB = null;
    _damagesDescription = null;
    _additionalFeatures = null;

    _frontSidesImage = null;
    _frontTyresImage = null;
    _frontChassisImage = null;
    _frontDeckImage = null;
    _frontMakersPlateImage = null;

    _rearSidesImage = null;
    _rearTyresImage = null;
    _rearChassisImage = null;
    _rearDeckImage = null;
    _rearMakersPlateImage = null;

    clearDamageImages(notify: false);
    if (notify) notifyListeners();
  }

  void clearDamagesAndFeatures({bool notify = true}) {
    _damagesDescription = null;
    _additionalFeatures = null;
    if (notify) notifyListeners();
  }

  // Save form state to SharedPreferences
  Future<void> saveFormState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('vehicleType', _vehicleType ?? '');
    await prefs.setString('year', _year ?? '');
    await prefs.setString('variant', _variant ?? '');
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

    // Save maintenance info
    await prefs.setString('maintenanceDocUrl', _maintenanceDocUrl ?? '');
    await prefs.setString('warrantyDocUrl', _warrantyDocUrl ?? '');
    await prefs.setString('oemInspectionType', _oemInspectionType);
    await prefs.setString(
        'oemInspectionExplanation', _oemInspectionExplanation ?? '');
  }

  // Load form state from SharedPreferences
  Future<void> loadFormState() async {
    final prefs = await SharedPreferences.getInstance();
    _vehicleType = prefs.getString('vehicleType');
    _year = prefs.getString('year');
    _variant = prefs.getString('variant');
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

    _vehicleId = null;
    _vehicleType = null;
    _year = null;
    _variant = null;
    _makeModel = null;
    _make = null;
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
    _hydraulics = 'no';
    _maintenance = 'no';
    _warranty = 'no';
    _warrantyDetails = null;
    _requireToSettleType = 'no';
    _referenceNumber = null;
    _brands = [];
    _selectedMainImage = null; // Uint8List now
    _mainImageUrl = null;
    _natisRc1Url = null;

    // Maintenance info
    _maintenanceDocFile = null;
    _maintenanceDocUrl = null;
    _warrantyDocFile = null;
    _warrantyDocUrl = null;
    _oemInspectionType = 'yes';
    _oemInspectionExplanation = null;

    clearTrailerImages(notify: false);
    clearDamagesAndFeatures(notify: false);

    notifyListeners();
  }
}
