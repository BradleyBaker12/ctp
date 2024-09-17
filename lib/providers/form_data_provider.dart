import 'package:flutter/foundation.dart';
import 'dart:io';

class DamageEntry {
  String? damageDescription;
  File? damagePhoto;

  DamageEntry({this.damageDescription, this.damagePhoto});
}

class FormDataProvider with ChangeNotifier {
  // Form index management
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

  // List of damage entries
  List<DamageEntry> _damageEntries = [];

  List<DamageEntry> get damageEntries => _damageEntries;

  void addDamageEntry() {
    _damageEntries.add(DamageEntry());
    notifyListeners();
  }

  void removeDamageEntry(int index) {
    if (index >= 0 && index < _damageEntries.length) {
      _damageEntries.removeAt(index);
      notifyListeners();
    }
  }

  void updateDamageDescription(int index, String description) {
    if (index >= 0 && index < _damageEntries.length) {
      _damageEntries[index].damageDescription = description;
      notifyListeners();
    }
  }

  void updateDamagePhoto(int index, File? photo) {
    if (index >= 0 && index < _damageEntries.length) {
      _damageEntries[index].damagePhoto = photo;
      notifyListeners();
    }
  }

  // Fields for the first form section
  String? vehicleType;
  String? year;
  String? makeModel;
  String? sellingPrice;
  String? vinNumber;
  String? mileage;
  File? selectedMainImage;
  File? selectedLicenceDiskImage;
  List<String>? inspectionDates;
  List<Map<String, dynamic>>? inspectionLocations;
  List<String>? collectionDates;
  List<Map<String, dynamic>>? collectionLocations;

  // Additional fields
  String? weightClass;

  // Fields for the second form section
  String? application;
  String? transmission;
  String? engineNumber;
  String? suspension;
  String? registrationNumber;
  String? expectedSellingPrice;
  String? hydraulics;
  String? maintenance;
  String? oemInspection;
  String? warranty;
  String? warrantyType;
  String? firstOwner;
  String? accidentFree;
  String? roadWorthy;

  // Fields for the third form section
  String? settleBeforeSelling;
  File? settlementLetterFile;
  String? settlementAmount;

  // Fields for the fourth form section
  File? rc1NatisFile;

  // Fields for the fifth form section
  String? listDamages;
  String? damageDescription;
  File? dashboardPhoto;
  File? faultCodesPhoto;
  List<File?>? damagePhotos;

  // Fields for the sixth form section
  String? tyreType;
  String? spareTyre;
  File? frontRightTyre;
  File? frontLeftTyre;
  File? spareWheelTyre;
  String? treadLeft;

  // Fields for the seventh form section
  List<File?> photoPaths = List<File?>.filled(18, null, growable: false);

  // Constructor
  FormDataProvider();

  // Methods for the first form section
  void setVehicleType(String type) {
    vehicleType = type;
    notifyListeners();
  }

  void setYear(String yearValue) {
    year = yearValue;
    notifyListeners();
  }

  void setMakeModel(String makeModelValue) {
    makeModel = makeModelValue;
    notifyListeners();
  }

  void setSellingPrice(String sellingPriceValue) {
    sellingPrice = sellingPriceValue;
    notifyListeners();
  }

  void setVinNumber(String vinValue) {
    vinNumber = vinValue;
    notifyListeners();
  }

  void setMileage(String mileageValue) {
    mileage = mileageValue;
    notifyListeners();
  }

  void setSelectedMainImage(File? image) {
    selectedMainImage = image;
    notifyListeners();
  }

  void setSelectedLicenceDiskImage(File? image) {
    selectedLicenceDiskImage = image;
    notifyListeners();
  }

  void setInspectionDates(List<String>? dates) {
    inspectionDates = dates;
    notifyListeners();
  }

  void setInspectionLocations(List<Map<String, dynamic>>? locations) {
    inspectionLocations = locations;
    notifyListeners();
  }

  void setCollectionDates(List<String>? dates) {
    collectionDates = dates;
    notifyListeners();
  }

  void setCollectionLocations(List<Map<String, dynamic>>? locations) {
    collectionLocations = locations;
    notifyListeners();
  }

  void setWeightClass(String classValue) {
    weightClass = classValue;
    notifyListeners();
  }

  // Methods for the second form section
  void setApplication(String applicationValue) {
    application = applicationValue;
    notifyListeners();
  }

  void setTransmission(String transmissionValue) {
    transmission = transmissionValue;
    notifyListeners();
  }

  void setEngineNumber(String engineNumberValue) {
    engineNumber = engineNumberValue;
    notifyListeners();
  }

  void setSuspension(String suspensionValue) {
    suspension = suspensionValue;
    notifyListeners();
  }

  void setRegistrationNumber(String registrationNumberValue) {
    registrationNumber = registrationNumberValue;
    notifyListeners();
  }

  void setExpectedSellingPrice(String expectedSellingPriceValue) {
    expectedSellingPrice = expectedSellingPriceValue;
    notifyListeners();
  }

  void setHydraulics(String hydraulicsValue) {
    hydraulics = hydraulicsValue;
    notifyListeners();
  }

  void setMaintenance(String maintenanceValue) {
    maintenance = maintenanceValue;
    notifyListeners();
  }

  void setOemInspection(String oemInspectionValue) {
    oemInspection = oemInspectionValue;
    notifyListeners();
  }

  void setWarranty(String warrantyValue) {
    warranty = warrantyValue;
    notifyListeners();
  }

  void setWarrantyType(String warrantyTypeValue) {
    warrantyType = warrantyTypeValue;
    notifyListeners();
  }

  void setFirstOwner(String firstOwnerValue) {
    firstOwner = firstOwnerValue;
    notifyListeners();
  }

  void setAccidentFree(String accidentFreeValue) {
    accidentFree = accidentFreeValue;
    notifyListeners();
  }

  void setRoadWorthy(String roadWorthyValue) {
    roadWorthy = roadWorthyValue;
    notifyListeners();
  }

  // Methods for the third form section
  void setSettleBeforeSelling(String value) {
    settleBeforeSelling = value;
    notifyListeners();
  }

  void setSettlementLetterFile(File? file) {
    settlementLetterFile = file;
    notifyListeners();
  }

  void setSettlementAmount(String amount) {
    settlementAmount = amount;
    notifyListeners();
  }

  // Methods for the fourth form section
  void setRc1NatisFile(File? file) {
    rc1NatisFile = file;
    notifyListeners();
  }

  // Methods for the fifth form section
  void setListDamages(String value) {
    listDamages = value;
    notifyListeners();
  }

  void setDamageDescription(String value) {
    damageDescription = value;
    notifyListeners();
  }

  void setDashboardPhoto(File? file) {
    dashboardPhoto = file;
    notifyListeners();
  }

  void setFaultCodesPhoto(File? file) {
    faultCodesPhoto = file;
    notifyListeners();
  }

  void setDamagePhotos(List<File?> files) {
    damagePhotos = files;
    notifyListeners();
  }

  // Methods for the sixth form section
  void setTyreType(String value) {
    tyreType = value;
    notifyListeners();
  }

  void setSpareTyre(String value) {
    spareTyre = value;
    notifyListeners();
  }

  void setFrontRightTyre(File? file) {
    frontRightTyre = file;
    notifyListeners();
  }

  void setFrontLeftTyre(File? file) {
    frontLeftTyre = file;
    notifyListeners();
  }

  void setSpareWheelTyre(File? file) {
    spareWheelTyre = file;
    notifyListeners();
  }

  void setTreadLeft(String value) {
    treadLeft = value;
    notifyListeners();
  }

  // Methods for the seventh form section
  void setPhotoAtIndex(int index, File? file) {
    if (index >= 0 && index < photoPaths.length) {
      photoPaths[index] = file;
      notifyListeners();
    }
  }

  void setPhotoPaths(List<File?> files) {
    photoPaths = files;
    notifyListeners();
  }

  // Method to reset all data
  void resetFormData() {
    // Reset all form data including damage entries
    vehicleType = null;
    year = null;
    makeModel = null;
    sellingPrice = null;
    vinNumber = null;
    mileage = null;
    selectedMainImage = null;
    selectedLicenceDiskImage = null;
    inspectionDates = null;
    inspectionLocations = null;
    collectionDates = null;
    collectionLocations = null;
    weightClass = null;

    application = null;
    transmission = null;
    engineNumber = null;
    suspension = null;
    registrationNumber = null;
    expectedSellingPrice = null;
    hydraulics = null;
    maintenance = null;
    oemInspection = null;
    warranty = null;
    warrantyType = null;
    firstOwner = null;
    accidentFree = null;
    roadWorthy = null;

    settleBeforeSelling = null;
    settlementLetterFile = null;
    settlementAmount = null;

    rc1NatisFile = null;

    listDamages = null;
    damageDescription = null;
    dashboardPhoto = null;
    faultCodesPhoto = null;
    damagePhotos = null;

    tyreType = null;
    spareTyre = null;
    frontRightTyre = null;
    frontLeftTyre = null;
    spareWheelTyre = null;
    treadLeft = null;

    photoPaths = List<File?>.filled(18, null, growable: false);

    // Reset damage entries
    _damageEntries.clear();

    notifyListeners();
  }
}
