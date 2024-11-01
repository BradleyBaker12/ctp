import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';

class FormDataProvider with ChangeNotifier {
  // Form index management (if still needed)
  int _currentFormIndex = 0;

  int get currentFormIndex => _currentFormIndex;

  void setCurrentFormIndex(int index) {
    _currentFormIndex = index;
    notifyListeners();
  }

  void incrementFormIndex() {
    _currentFormIndex++;
    notifyListeners();
  }

  // Vehicle ID property
  String? _vehicleId;

  String? get vehicleId => _vehicleId;

  void setVehicleId(String id) {
    _vehicleId = id;
    notifyListeners();
  }

  // SECTION 1: Basic Vehicle Information
  String? _vehicleType;
  String? _year;
  String? _makeModel;
  String? _sellingPrice;
  String? _vinNumber;
  String? _mileage;
  File? _selectedMainImage;
  String? _mainImageUrl;
  String? _natisRc1Url;

  String? get year => _year;
  String? get makeModel => _makeModel;
  String? get sellingPrice => _sellingPrice;
  String? get vinNumber => _vinNumber;
  String? get mileage => _mileage;
  File? get selectedMainImage => _selectedMainImage;
  String? get mainImageUrl => _mainImageUrl;
  String? get natisRc1Url => _natisRc1Url;

  void setDataFromMap(Map<String, dynamic> data) {
    _year = data['year'];
    _makeModel = data['makeModel'];
    _vinNumber = data['vinNumber'];
    _config = data['config'];
    _mileage = data['mileage'];
    _application = data['application'];
    _engineNumber = data['engineNumber'];
    _registrationNumber = data['registrationNumber'];
    _sellingPrice = data['sellingPrice'];
    _vehicleType = data['vehicleType'];
    _suspension = data['suspensionType'];
    _transmissionType = data['transmissionType'];
    _hydraulics = data['hydraulics'];
    _maintenance = data['maintenance'];
    _warranty = data['warranty'];
    _warrantyDetails = data['warrantyDetails'];
    _requireToSettleType = data['requireToSettleType'];
    _mainImageUrl = data['mainImageUrl'];
    _natisRc1Url = data['natisRc1Url'];

    notifyListeners();
  }

  void setMainImageUrl(String? url, {bool notify = true}) {
    _mainImageUrl = url;
    if (notify) notifyListeners();
  }

  void setNatisRc1UrlUrl(String? url, {bool notify = true}) {
    _natisRc1Url = url;
    if (notify) notifyListeners();
  }

  void setVehicleType(String? type, {bool notify = true}) {
    _vehicleType = type ?? 'truck';
    if (notify) notifyListeners();
  }

  void setYear(String? yearValue, {bool notify = true}) {
    _year = yearValue;
    if (notify) notifyListeners();
  }

  void setMakeModel(String? makeModelValue, {bool notify = true}) {
    _makeModel = makeModelValue;
    if (notify) notifyListeners();
  }

  void setSellingPrice(String? sellingPriceValue, {bool notify = true}) {
    _sellingPrice = sellingPriceValue;
    if (notify) notifyListeners();
  }

  void setVinNumber(String? vinValue, {bool notify = true}) {
    _vinNumber = vinValue;
    if (notify) notifyListeners();
  }

  void setMileage(String? mileageValue, {bool notify = true}) {
    _mileage = mileageValue;
    if (notify) notifyListeners();
  }

  void setSelectedMainImage(File? image) {
    _selectedMainImage = image;
    WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
  }

  // SECTION 2: Additional Vehicle Details
  String? _application;
  String? _config;
  String? _transmissionType;
  String? _engineNumber;
  String? _suspension;
  String? _registrationNumber;
  String? _expectedSellingPrice;
  String? _hydraulics;
  String? _maintenance;
  String? _maintanenceType;
  String? _warranty;
  String? _warrantyType;
  String? _requireToSettleType;
  // Maintenance and Warranty Data
  File? _maintenanceDocFile;
  File? _warrantyDocFile;
  String _oemInspectionType = 'yes';
  String? _oemInspectionExplanation;

  String get vehicleType => _vehicleType ?? 'truck';
  String get suspension => _suspension ?? 'spring';
  String get transmissionType => _transmissionType ?? 'automatic';
  String get hydraulics => _hydraulics ?? 'yes';
  String get maintenance => _maintenance ?? 'yes';
  String get warranty => _warranty ?? 'yes';
  String get requireToSettleType => _requireToSettleType ?? 'yes';
  String get maintanenceType => _maintanenceType ?? 'yes';

  String? get application => _application;
  String? get config => _config;

  String? get engineNumber => _engineNumber;

  String? get registrationNumber => _registrationNumber;
  String? get expectedSellingPrice => _expectedSellingPrice;

  String? get warrantyType => _warrantyType;
  File? get maintenanceDocFile => _maintenanceDocFile;
  File? get warrantyDocFile => _warrantyDocFile;
  String get oemInspectionType => _oemInspectionType;
  String? get oemInspectionExplanation => _oemInspectionExplanation;

  void setMaintenanceDocFile(File? file, {bool notify = true}) {
    _maintenanceDocFile = file;
    if (notify) notifyListeners();
  }

  void setWarrantyDocFile(File? file, {bool notify = true}) {
    _warrantyDocFile = file;
    if (notify) notifyListeners();
  }

  void setOemInspectionType(String value, {bool notify = true}) {
    _oemInspectionType = value;
    if (notify) notifyListeners();
  }

  void setOemInspectionExplanation(String? explanation, {bool notify = true}) {
    _oemInspectionExplanation = explanation;
    if (notify) notifyListeners();
  }

  void setApplication(String? value, {bool notify = true}) {
    _application = value;
    if (notify) notifyListeners();
  }

  void setConfig(String? value, {bool notify = true}) {
    _config = value;
    if (notify) notifyListeners();
  }

  void setTransmissionType(String? value, {bool notify = true}) {
    _transmissionType = value;
    if (notify) notifyListeners();
  }

  void setEngineNumber(String? value, {bool notify = true}) {
    _engineNumber = value;
    if (notify) notifyListeners();
  }

  void setSuspension(String? value, {bool notify = true}) {
    _suspension = value;
    if (notify) notifyListeners();
  }

  void setRegistrationNumber(String? value, {bool notify = true}) {
    _registrationNumber = value;
    if (notify) notifyListeners();
  }

  void setExpectedSellingPrice(String? value, {bool notify = true}) {
    _expectedSellingPrice = value;
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

  void setMaintanenceType(String? value, {bool notify = true}) {
    _maintanenceType = value;
    if (notify) notifyListeners();
  }

  void setWarranty(String? value, {bool notify = true}) {
    _warranty = value;
    if (notify) notifyListeners();
  }

  void setWarrantyType(String? value, {bool notify = true}) {
    _warrantyType = value;
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

  // SECTION 3: Warranty Details (Conditional)
  String? _warrantyDetails;

  String? get warrantyDetails => _warrantyDetails;

  // SECTION 4: External Cab Data
  String _externalCabCondition = 'good';
  String _externalCabAnyDamages = 'no';
  String _externalCabAnyAdditionalFeatures = 'no';
  Map<String, File?> _externalCabSelectedImages = {
    'FRONT VIEW': null,
    'RIGHT SIDE VIEW': null,
    'REAR VIEW': null,
    'LEFT SIDE VIEW': null,
  };
  List<Map<String, dynamic>> _externalCabDamageList = [];
  List<Map<String, dynamic>> _externalCabAdditionalFeaturesList = [];

  String get externalCabCondition => _externalCabCondition;
  String get externalCabAnyDamages => _externalCabAnyDamages;
  String get externalCabAnyAdditionalFeatures =>
      _externalCabAnyAdditionalFeatures;
  Map<String, File?> get externalCabSelectedImages =>
      _externalCabSelectedImages;
  List<Map<String, dynamic>> get externalCabDamageList =>
      _externalCabDamageList;
  List<Map<String, dynamic>> get externalCabAdditionalFeaturesList =>
      _externalCabAdditionalFeaturesList;

  void setExternalCabCondition(String value, {bool notify = true}) {
    _externalCabCondition = value;
    if (notify) notifyListeners();
  }

  void setExternalCabAnyDamages(String value, {bool notify = true}) {
    _externalCabAnyDamages = value;
    if (notify) notifyListeners();
  }

  void setExternalCabAnyAdditionalFeatures(String value, {bool notify = true}) {
    _externalCabAnyAdditionalFeatures = value;
    if (notify) notifyListeners();
  }

  void setExternalCabSelectedImage(String key, File? file,
      {bool notify = true}) {
    _externalCabSelectedImages[key] = file;
    if (notify) notifyListeners();
  }

  void addExternalCabDamage(Map<String, dynamic> damage, {bool notify = true}) {
    _externalCabDamageList.add(damage);
    if (notify) notifyListeners();
  }

  void removeExternalCabDamage(int index, {bool notify = true}) {
    _externalCabDamageList.removeAt(index);
    if (notify) notifyListeners();
  }

  void addExternalCabAdditionalFeature(Map<String, dynamic> feature,
      {bool notify = true}) {
    _externalCabAdditionalFeaturesList.add(feature);
    if (notify) notifyListeners();
  }

  void removeExternalCabAdditionalFeature(int index, {bool notify = true}) {
    _externalCabAdditionalFeaturesList.removeAt(index);
    if (notify) notifyListeners();
  }

  // SECTION 5: Internal Cab Data
  String _internalCabCondition = 'good';
  String _internalCabDamagesCondition = 'no';
  String _internalCabAdditionalFeaturesCondition = 'no';
  String _internalCabFaultCodesCondition = 'no';
  Map<String, File?> _internalCabSelectedImages = {
    'Center Dash': null,
    'Left Dash': null,
    'Right Dash (Vehicle On)': null,
    'Mileage': null,
    'Sun Visors': null,
    'Center Console': null,
    'Steering': null,
    'Left Door Panel': null,
    'Left Seat': null,
    'Roof': null,
    'Bunk Beds': null,
    'Rear Panel': null,
    'Right Door Panel': null,
    'Right Seat': null,
  };
  List<Map<String, dynamic>> _internalCabDamageList = [];
  List<Map<String, dynamic>> _internalCabAdditionalFeaturesList = [];
  List<Map<String, dynamic>> _internalCabFaultCodesList = [];

  String get internalCabCondition => _internalCabCondition;
  String get internalCabDamagesCondition => _internalCabDamagesCondition;
  String get internalCabAdditionalFeaturesCondition =>
      _internalCabAdditionalFeaturesCondition;
  String get internalCabFaultCodesCondition => _internalCabFaultCodesCondition;
  Map<String, File?> get internalCabSelectedImages =>
      _internalCabSelectedImages;
  List<Map<String, dynamic>> get internalCabDamageList =>
      _internalCabDamageList;
  List<Map<String, dynamic>> get internalCabAdditionalFeaturesList =>
      _internalCabAdditionalFeaturesList;
  List<Map<String, dynamic>> get internalCabFaultCodesList =>
      _internalCabFaultCodesList;

  void setInternalCabCondition(String value, {bool notify = true}) {
    _internalCabCondition = value;
    if (notify) notifyListeners();
  }

  void setInternalCabDamagesCondition(String value, {bool notify = true}) {
    _internalCabDamagesCondition = value;
    if (notify) notifyListeners();
  }

  void setInternalCabAdditionalFeaturesCondition(String value,
      {bool notify = true}) {
    _internalCabAdditionalFeaturesCondition = value;
    if (notify) notifyListeners();
  }

  void setInternalCabFaultCodesCondition(String value, {bool notify = true}) {
    _internalCabFaultCodesCondition = value;
    if (notify) notifyListeners();
  }

  void setInternalCabSelectedImage(String key, File? file,
      {bool notify = true}) {
    _internalCabSelectedImages[key] = file;
    if (notify) notifyListeners();
  }

  void addInternalCabDamage(Map<String, dynamic> damage, {bool notify = true}) {
    _internalCabDamageList.add(damage);
    if (notify) notifyListeners();
  }

  void removeInternalCabDamage(int index, {bool notify = true}) {
    _internalCabDamageList.removeAt(index);
    if (notify) notifyListeners();
  }

  void addInternalCabAdditionalFeature(Map<String, dynamic> feature,
      {bool notify = true}) {
    _internalCabAdditionalFeaturesList.add(feature);
    if (notify) notifyListeners();
  }

  void removeInternalCabAdditionalFeature(int index, {bool notify = true}) {
    _internalCabAdditionalFeaturesList.removeAt(index);
    if (notify) notifyListeners();
  }

  void addInternalCabFaultCode(Map<String, dynamic> faultCode,
      {bool notify = true}) {
    _internalCabFaultCodesList.add(faultCode);
    if (notify) notifyListeners();
  }

  void removeInternalCabFaultCode(int index, {bool notify = true}) {
    _internalCabFaultCodesList.removeAt(index);
    if (notify) notifyListeners();
  }

  // SECTION 6: Drive Train Data
  String _driveTrainCondition = 'good';
  String _oilLeakConditionEngine = 'no';
  String _waterLeakConditionEngine = 'no';
  String _blowbyCondition = 'no';
  String _oilLeakConditionGearbox = 'no';
  String _retarderCondition = 'no';
  Map<String, File?> _driveTrainSelectedImages = {
    'Down': null,
    'Left': null,
    'Up': null,
    'Right': null,
    'Engine Left': null,
    'Engine Right': null,
    'Gearbox Top View': null,
    'Gearbox Bottom View': null,
    'Gearbox Rear Panel': null,
    'Diffs top view of front diff': null,
    'Diffs bottom view of diff front': null,
    'Diffs top view of rear diff': null,
    'Diffs bottom view of rear diff': null,
    'Engine Oil Leak': null,
    'Engine Water Leak': null,
    'Gearbox Oil Leak': null,
  };

  String get driveTrainCondition => _driveTrainCondition;
  String get oilLeakConditionEngine => _oilLeakConditionEngine;
  String get waterLeakConditionEngine => _waterLeakConditionEngine;
  String get blowbyCondition => _blowbyCondition;
  String get oilLeakConditionGearbox => _oilLeakConditionGearbox;
  String get retarderCondition => _retarderCondition;
  Map<String, File?> get driveTrainSelectedImages => _driveTrainSelectedImages;

  void setDriveTrainCondition(String value, {bool notify = true}) {
    _driveTrainCondition = value;
    if (notify) notifyListeners();
  }

  void setOilLeakConditionEngine(String value, {bool notify = true}) {
    _oilLeakConditionEngine = value;
    if (notify) notifyListeners();
  }

  void setWaterLeakConditionEngine(String value, {bool notify = true}) {
    _waterLeakConditionEngine = value;
    if (notify) notifyListeners();
  }

  void setBlowbyCondition(String value, {bool notify = true}) {
    _blowbyCondition = value;
    if (notify) notifyListeners();
  }

  void setOilLeakConditionGearbox(String value, {bool notify = true}) {
    _oilLeakConditionGearbox = value;
    if (notify) notifyListeners();
  }

  void setRetarderCondition(String value, {bool notify = true}) {
    _retarderCondition = value;
    if (notify) notifyListeners();
  }

  void setDriveTrainSelectedImage(String key, File? file,
      {bool notify = true}) {
    _driveTrainSelectedImages[key] = file;
    if (notify) notifyListeners();
  }

  // SECTION 7: Chassis Data
  String _chassisCondition = 'good';
  String _chassisDamagesCondition = 'no';
  String _chassisAdditionalFeaturesCondition = 'no';
  Map<String, String?> _chassisImageUrls = {
    'Right Brake': null,
    'Left Brake': null,
    'Front Axel': null,
    'Suspension': null,
    'Fuel Tank': null,
    'Battery': null,
    'Cat Walk': null,
    'Electrical Cable Black': null,
    'Air Cable Yellow': null,
    'Air Cable Red': null,
    'Tail Board': null,
    '5th Wheel': null,
    'Left Brake Rear Axel': null,
    'Right Brake Rear Axel': null,
  };
  Map<String, File?> _chassisSelectedImages = {
    'Right Brake': null,
    'Left Brake': null,
    'Front Axel': null,
    'Suspension': null,
    'Fuel Tank': null,
    'Battery': null,
    'Cat Walk': null,
    'Electrical Cable Black': null,
    'Air Cable Yellow': null,
    'Air Cable Red': null,
    'Tail Board': null,
    '5th Wheel': null,
    'Left Brake Rear Axel': null,
    'Right Brake Rear Axel': null,
  };
  List<Map<String, dynamic>> _chassisDamageList = [];
  List<Map<String, dynamic>> _chassisAdditionalFeaturesList = [];

  String get chassisCondition => _chassisCondition;
  String get chassisDamagesCondition => _chassisDamagesCondition;
  String get chassisAdditionalFeaturesCondition =>
      _chassisAdditionalFeaturesCondition;
  Map<String, String?> get chassisImageUrls => _chassisImageUrls;
  Map<String, File?> get chassisSelectedImages => _chassisSelectedImages;
  List<Map<String, dynamic>> get chassisDamageList => _chassisDamageList;
  List<Map<String, dynamic>> get chassisAdditionalFeaturesList =>
      _chassisAdditionalFeaturesList;

  void setChassisCondition(String value, {bool notify = true}) {
    _chassisCondition = value;
    if (notify) notifyListeners();
  }

  void setChassisDamagesCondition(String value, {bool notify = true}) {
    _chassisDamagesCondition = value;
    if (notify) notifyListeners();
  }

  void setChassisAdditionalFeaturesCondition(String value,
      {bool notify = true}) {
    _chassisAdditionalFeaturesCondition = value;
    if (notify) notifyListeners();
  }

  void setChassisSelectedImage(String key, File? file, {bool notify = true}) {
    _chassisSelectedImages[key] = file;
    if (notify) notifyListeners();
  }

  void addChassisDamage(Map<String, dynamic> damage, {bool notify = true}) {
    _chassisDamageList.add(damage);
    if (notify) notifyListeners();
  }

  void removeChassisDamage(int index, {bool notify = true}) {
    _chassisDamageList.removeAt(index);
    if (notify) notifyListeners();
  }

  void addChassisAdditionalFeature(Map<String, dynamic> feature,
      {bool notify = true}) {
    _chassisAdditionalFeaturesList.add(feature);
    if (notify) notifyListeners();
  }

  void removeChassisAdditionalFeature(int index, {bool notify = true}) {
    _chassisAdditionalFeaturesList.removeAt(index);
    if (notify) notifyListeners();
  }

  // SECTION 8: Tyres Data
  String _tyresChassisCondition = 'good';
  String _tyresVirginOrRecap = 'virgin';
  String _tyresRimType = 'aluminium';
  Map<String, File?> _tyresSelectedImages = {};
  // Add any additional fields as needed

  String get tyresChassisCondition => _tyresChassisCondition;
  String get tyresVirginOrRecap => _tyresVirginOrRecap;
  String get tyresRimType => _tyresRimType;
  Map<String, File?> get tyresSelectedImages => _tyresSelectedImages;

  void setTyresChassisCondition(String value, {bool notify = true}) {
    _tyresChassisCondition = value;
    if (notify) notifyListeners();
  }

  void setTyresVirginOrRecap(String value, {bool notify = true}) {
    _tyresVirginOrRecap = value;
    if (notify) notifyListeners();
  }

  void setTyresRimType(String value, {bool notify = true}) {
    _tyresRimType = value;
    if (notify) notifyListeners();
  }

  void setTyresSelectedImage(String key, File? file, {bool notify = true}) {
    _tyresSelectedImages[key] = file;
    if (notify) notifyListeners();
  }

  // Method to reset all data
  void resetFormData() {
    // Reset form index and vehicle ID
    _currentFormIndex = 0;
    _vehicleId = null;

    // Reset SECTION 1: Basic Vehicle Information
    _vehicleType = null;
    _year = null;
    _makeModel = null;
    _sellingPrice = null;
    _vinNumber = null;
    _mileage = null;
    _selectedMainImage = null;

    // Reset SECTION 2: Additional Vehicle Details
    _application = null;
    _config = null;
    _transmissionType = null;
    _engineNumber = null;
    _suspension = null;
    _registrationNumber = null;
    _expectedSellingPrice = null;
    _hydraulics = null;
    _maintenance = null;
    _warranty = null;
    _warrantyType = null;
    _requireToSettleType = null;

    // Reset SECTION 3: Warranty Details
    _warrantyDetails = null;

    // Reset SECTION 4: External Cab Data
    _externalCabCondition = 'good';
    _externalCabAnyDamages = 'no';
    _externalCabAnyAdditionalFeatures = 'no';
    _externalCabSelectedImages.updateAll((key, value) => null);
    _externalCabDamageList.clear();
    _externalCabAdditionalFeaturesList.clear();

    // Reset SECTION 5: Internal Cab Data
    _internalCabCondition = 'good';
    _internalCabDamagesCondition = 'no';
    _internalCabAdditionalFeaturesCondition = 'no';
    _internalCabFaultCodesCondition = 'no';
    _internalCabSelectedImages.updateAll((key, value) => null);
    _internalCabDamageList.clear();
    _internalCabAdditionalFeaturesList.clear();
    _internalCabFaultCodesList.clear();

    // Reset SECTION 6: Drive Train Data
    _driveTrainCondition = 'good';
    _oilLeakConditionEngine = 'no';
    _waterLeakConditionEngine = 'no';
    _blowbyCondition = 'no';
    _oilLeakConditionGearbox = 'no';
    _retarderCondition = 'no';
    _driveTrainSelectedImages.updateAll((key, value) => null);

    // Reset SECTION 7: Chassis Data
    _chassisCondition = 'good';
    _chassisDamagesCondition = 'no';
    _chassisAdditionalFeaturesCondition = 'no';
    _chassisImageUrls.updateAll((key, value) => null);
    _chassisSelectedImages.updateAll((key, value) => null);
    _chassisDamageList.clear();
    _chassisAdditionalFeaturesList.clear();

    // Reset SECTION 8: Tyres Data
    _tyresChassisCondition = 'good';
    _tyresVirginOrRecap = 'virgin';
    _tyresRimType = 'aluminium';
    _tyresSelectedImages.clear();

    notifyListeners();
  }
}
