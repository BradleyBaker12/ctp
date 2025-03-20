// lib/pages/editTruckForms/basic_information_edit.dart

import 'dart:io';
import 'dart:convert'; // Added for JSON decoding
import 'package:ctp/pages/editTruckForms/maintenance_edit_section.dart';
import 'package:ctp/pages/vehicles_list.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/utils/navigation.dart';
import 'package:flutter/services.dart'; // Added for loading assets
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/truckForms/custom_dropdown.dart';
import 'package:ctp/pages/truckForms/custom_radio_button.dart';
import 'package:ctp/pages/truckForms/custom_text_field.dart';
import 'package:ctp/pages/truckForms/image_picker_widget.dart';
import 'package:ctp/providers/form_data_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart'; // Added for file picking
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ctp/components/truck_info_web_nav.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ctp/utils/camera_helper.dart'; // <-- New import for camera helper

class BasicInformationEdit extends StatefulWidget {
  final bool isDuplicating;
  final Vehicle? vehicle;
  final bool isNewUpload;

  const BasicInformationEdit({
    super.key,
    this.vehicle,
    this.isDuplicating = false,
    this.isNewUpload = false,
  });

  @override
  _BasicInformationEditState createState() => _BasicInformationEditState();
}

class _BasicInformationEditState extends State<BasicInformationEdit> {
  // Controllers and Variables
  final ScrollController _scrollController = ScrollController();
  double _imageHeight = 300.0;

  final TextEditingController _sellingPriceController = TextEditingController();
  final TextEditingController _vinNumberController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _engineNumberController = TextEditingController();
  final TextEditingController _warrantyDetailsController =
      TextEditingController();
  final TextEditingController _registrationNumberController =
      TextEditingController();
  final TextEditingController _referenceNumberController =
      TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _variantController = TextEditingController();

  final TextEditingController _brandsController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(1, (index) => GlobalKey<FormState>());

  bool _isLoading = false;
  String? _vehicleId;
  DateTime? _availableDate;
  bool isDealer = false;

  List<String> _countryOptions = []; // Define the country options list
  List<String> _provinceOptions = []; // New province options list

  // Define application options
  final List<String> _applicationOptions = [
    'Bowser Body Trucks',
    'Cage Body Trucks',
    'Cattle Body Trucks',
    'Chassis Cab Trucks',
    'Cherry Picker Trucks',
    'Compactor Body Trucks',
    'Concrete Mixer Body Trucks',
    'Crane Body Trucks',
    'Curtain Body Trucks',
    'Fuel Tanker Body Trucks',
    'Dropside Body Trucks',
    'Fire Fighting Body Trucks',
    'Flatbed Body Trucks',
    'Honey Sucker Body Trucks',
    'Hooklift Body Trucks',
    'Insulated Body Trucks',
    'Mass Side Body Trucks',
    'Pantechnicon Body Trucks',
    'Refrigerated Body Trucks',
    'Roll Back Body Trucks',
    'Side Tipper Body Trucks',
    'Skip Loader Body Trucks',
    'Tanker Body Trucks',
    'Tipper Body Trucks',
    'Volume Body Trucks',
    'Low Bed Trucks',
  ];

  // Define configuration options
  final List<String> _configurationOptions = [
    '6X4',
    '6X2',
    '4X2',
    '8X4',
  ];

  // We keep brand/model options loaded from JSON
  late Map<String, List<String>> _makeModelOptions = {};
  List<String> _brandOptions = [];
  List<String> _yearOptions = [];

  // List for variants is user-entered or from DB.
  List<String> _variantOptions = [];

  String? _initialVehicleStatus;

  // Variable to hold selected NATIS/RC1 file
  Uint8List? _natisRc1File;
  String? _natisRc1FileName;
  bool isNewUpload = false;
  String? _existingNatisRc1Url;
  String? _existingNatisRc1Name;

  int _currentStep = 0;

  final TextEditingController _configController = TextEditingController();
  final TextEditingController _applicationController = TextEditingController();

  String? _vehicleStatus;

  // ------------------------- Existing Transporter Fields ---------------------------
  // List of users who can own trucks (transporters and admins)
  List<Map<String, dynamic>> _transporterUsers = [];
  // Selected owner ID and email
  String? _selectedTransporterId;
  String? _selectedTransporterEmail;
  // ------------------------------------------------------------------

  // ------------------------- New Sales Rep Fields ---------------------------
  List<Map<String, dynamic>> _salesRepUsers = [];
  String? _selectedSalesRepId;
  String? _selectedSalesRepEmail;
  // ------------------------------------------------------------------

  // Add new properties for web navigation
  final bool _isDrawerOpen = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadCountryOptions();
    _loadYearOptions();
    _checkUserRole();

    // If admin, load transporter users (including admins) and sales rep users.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.getUserRole == 'admin') {
        await _loadTransporterUsers();
        await _loadSalesRepUsers(); // Load sales rep users with extra debugging
      } else if (userProvider.getUserRole == 'sales representative') {
        // Also load these for sales representatives.
        await _loadTransporterUsers();
        await _loadSalesRepUsers();
      }
      // Decide if we’re editing, duplicating, or new
      final formData = Provider.of<FormDataProvider>(context, listen: false);
      if (widget.vehicle != null && !widget.isDuplicating) {
        _vehicleId = widget.vehicle!.id;
        debugPrint('Editing existing vehicle with ID: $_vehicleId');
        await _populateExistingVehicleData();
      } else if (widget.isDuplicating) {
        _vehicleId = null;
        debugPrint('Duplicating vehicle. Clearing vehicle ID.');
        await _populateExistingVehicleData();
      } else if (widget.isNewUpload) {
        debugPrint('New vehicle upload. Clearing all data.');
        _clearAllData(formData);
      }
      _initializeTextControllers(formData, skipVariantIfDB: false);
      _addControllerListeners(formData);
    });

    _scrollController.addListener(() {
      setState(() {
        double offset = _scrollController.offset;
        if (offset < 0) offset = 0;
        if (offset > 150.0) offset = 150.0;
        _imageHeight = 300.0 - offset;
      });
    });
  }

  Future<void> _checkUserRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        // Using the "userRole" field
        setState(() {
          isDealer = userData.data()?['userRole'] == 'dealer';
        });
        debugPrint('User role fetched: ${userData.data()?['userRole']}');
      } else {
        debugPrint('No user is currently logged in.');
      }
    } catch (e) {
      debugPrint('Error fetching user role: $e');
    }
  }

  Future<void> _loadYearOptions() async {
    try {
      final response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/BradleyBaker12/truckData/refs/heads/main/updated_truck_data.json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _yearOptions = (data as Map<String, dynamic>).keys.toList()..sort();
        });
        debugPrint('Loaded Year Options: $_yearOptions');
      } else {
        debugPrint('Failed to load year options from GitHub');
      }
    } catch (e) {
      debugPrint('Error loading year options: $e');
    }
  }

  Future<void> _loadBrandsForYear(String year) async {
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    try {
      final response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/BradleyBaker12/truckData/refs/heads/main/updated_truck_data.json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _brandOptions = data[year]?.keys.toList() ?? [];
          // Clear values for a new upload or when duplicating
          if (widget.isNewUpload || widget.isDuplicating) {
            formData.setBrands(null);
            formData.setMakeModel(null);
            formData.setVariant(null);
          }
        });
        debugPrint('Loaded brands for year $year: $_brandOptions');
      } else {
        debugPrint('Failed to load brands for year from GitHub');
      }
    } catch (e) {
      debugPrint('Error loading brands for year $year: $e');
    }
  }

  Future<void> _loadModelsForBrand(String brand) async {
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    final year = formData.year;
    if (year == null) return;

    try {
      final response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/BradleyBaker12/truckData/refs/heads/main/updated_truck_data.json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (data[year] != null && data[year][brand] != null) {
            final models = data[year][brand].keys.toList();
            _makeModelOptions = {brand: models};
            // Clear model and variant for new uploads or duplication
            if (widget.isNewUpload || widget.isDuplicating) {
              formData.setMakeModel(null);
              formData.setVariant(null);
              _variantController.clear();
            }
          }
        });
        debugPrint(
            'Loaded models for brand $brand: ${_makeModelOptions[brand]}');
      } else {
        debugPrint('Failed to load models for brand from GitHub');
      }
    } catch (e) {
      debugPrint('Error loading models for brand $brand: $e');
    }
  }

  Future<void> _loadVariantsForModel(String model) async {
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    final year = formData.year;
    final brand = formData.brands?.first;
    if (year == null || brand == null) return;

    try {
      final response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/BradleyBaker12/truckData/refs/heads/main/updated_truck_data.json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (data[year]?[brand]?[model] != null) {
            _variantOptions = List<String>.from(data[year][brand][model]);
            // Clear variant for new uploads or when duplicating
            if (widget.isNewUpload || widget.isDuplicating) {
              formData.setVariant(null);
            }
          } else {
            _variantOptions = [];
          }
        });
        debugPrint('Loaded variants for model $model: $_variantOptions');
      } else {
        debugPrint('Failed to load variants for model from GitHub');
      }
    } catch (e) {
      debugPrint('Error loading variants for model $model: $e');
    }
  }

  // Load country options from JSON
  Future<void> _loadCountryOptions() async {
    try {
      final String response =
          await rootBundle.loadString('lib/assets/country-by-name.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        _countryOptions =
            data.map((country) => country['country'] as String).toList();
      });
      debugPrint('Loaded Country Options: $_countryOptions');
      final formData = Provider.of<FormDataProvider>(context, listen: false);
      if (formData.country == null &&
          _countryOptions.contains('South Africa')) {
        formData.setCountry('South Africa');
        debugPrint('Default country set to South Africa.');
        // Call the helper to update province options
        _updateProvinceOptions('South Africa');
      }
    } catch (e) {
      debugPrint('Error loading country options: $e');
    }
  }

  // New helper method to load province options based on selected country
  Future<void> _updateProvinceOptions(String selectedCountry) async {
    try {
      final String response =
          await rootBundle.loadString('lib/assets/countries.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        final country = data.firstWhere(
          (country) => country['name'] == selectedCountry,
          orElse: () => {'states': []},
        );
        _provinceOptions = (country['states'] as List<dynamic>)
            .map((state) => state['name'] as String)
            .toList();
      });
      debugPrint("Province options loaded: $_provinceOptions");
    } catch (e) {
      debugPrint("Error loading province options: $e");
    }
  }

  void _clearAllData(FormDataProvider formData) {
    debugPrint('Clearing all form data for new upload.');
    formData.clearAllData();
    formData.setSelectedMainImage(null, null);
    formData.setMainImageUrl(null);
    formData.setNatisRc1Url(null);
    formData.setYear(null);
    formData.setMakeModel(null);
    formData.setVinNumber(null);
    formData.setVariant('');
    formData.setConfig(null);
    formData.setMileage(null);
    formData.setApplication(null);
    formData.setEngineNumber(null);
    formData.setRegistrationNumber(null);
    formData.setSellingPrice(null);
    formData.setVehicleType(null);
    formData.setSuspension(null);
    formData.setTransmissionType(null);
    formData.setHydraulics('no');
    formData.setMaintenance('no');
    formData.setWarranty('no');
    formData.setWarrantyDetails(null);
    formData.setRequireToSettleType('no');
    formData.setReferenceNumber(null);
    formData.setBrands([]);
    _clearFormControllers();
    setState(() {
      _natisRc1File = null;
      _existingNatisRc1Url = null;
      _existingNatisRc1Name = null;
    });
    _vehicleId = null;
    _isLoading = false;
    _currentStep = 0;
    debugPrint('All form data cleared.');
  }

  /// Initialize controllers with FormDataProvider values.
  void _initializeTextControllers(FormDataProvider formData,
      {bool skipVariantIfDB = false}) {
    debugPrint('Initializing text controllers with form data.');
    _vinNumberController.text = formData.vinNumber ?? '';
    debugPrint(
        'VIN Number Controller initialized: ${_vinNumberController.text}');
    _mileageController.text = formData.mileage ?? '';
    debugPrint('Mileage Controller initialized: ${_mileageController.text}');
    _engineNumberController.text = formData.engineNumber ?? '';
    debugPrint(
        'Engine Number Controller initialized: ${_engineNumberController.text}');
    _registrationNumberController.text = formData.registrationNumber ?? '';
    debugPrint(
        'Registration Number Controller initialized: ${_registrationNumberController.text}');
    _sellingPriceController.text = formData.sellingPrice ?? '';
    debugPrint(
        'Selling Price Controller initialized: ${_sellingPriceController.text}');
    _warrantyDetailsController.text = formData.warrantyDetails ?? '';
    debugPrint(
        'Warranty Details Controller initialized: ${_warrantyDetailsController.text}');
    _referenceNumberController.text = formData.referenceNumber ?? '';
    debugPrint(
        'Reference Number Controller initialized: ${_referenceNumberController.text}');
    _brandsController.text =
        (formData.brands != null && formData.brands!.isNotEmpty)
            ? formData.brands![0]
            : '';
    debugPrint('Brands Controller initialized: ${_brandsController.text}');
    _countryController.text = formData.country ?? 'South Africa';
    debugPrint('Country Controller initialized: ${_countryController.text}');
    _modelController.text = formData.makeModel ?? '';
    debugPrint('Model Controller initialized: ${_modelController.text}');
    debugPrint(
        'formData.variant before variant assignment: ${formData.variant}');
    if (!skipVariantIfDB) {
      _variantController.text = formData.variant ?? '';
      debugPrint('Set _variantController.text to: ${_variantController.text}');
    } else {
      debugPrint(
          'Skipping variant assignment; controller remains: ${_variantController.text}');
    }
    debugPrint('Variant Controller initialized: ${_variantController.text}');
  }

  void _addControllerListeners(FormDataProvider formData) {
    _vinNumberController.addListener(() {
      formData.setVinNumber(_vinNumberController.text);
      formData.saveFormState();
      debugPrint('VIN Number updated: ${_vinNumberController.text}');
    });
    _mileageController.addListener(() {
      formData.setMileage(_mileageController.text);
      formData.saveFormState();
      debugPrint('Mileage updated: ${_mileageController.text}');
    });
    _engineNumberController.addListener(() {
      formData.setEngineNumber(_engineNumberController.text);
      formData.saveFormState();
      debugPrint('Engine Number updated: ${_engineNumberController.text}');
    });
    _registrationNumberController.addListener(() {
      formData.setRegistrationNumber(_registrationNumberController.text);
      formData.saveFormState();
      debugPrint(
          'Registration Number updated: ${_registrationNumberController.text}');
    });
    _sellingPriceController.addListener(() {
      formData.setSellingPrice(_sellingPriceController.text);
      formData.saveFormState();
      debugPrint('Selling Price updated: ${_sellingPriceController.text}');
    });
    _warrantyDetailsController.addListener(() {
      formData.setWarrantyDetails(_warrantyDetailsController.text);
      formData.saveFormState();
      debugPrint(
          'Warranty Details updated: ${_warrantyDetailsController.text}');
    });
    _referenceNumberController.addListener(() {
      final value = _referenceNumberController.text;
      formData.setReferenceNumber(value);
      formData.saveFormState();
      debugPrint('Reference Number updated: $value');
      if (_referenceNumberController.text != value) {
        setState(() {
          _referenceNumberController.text = value;
          debugPrint('Reference Number text re-synced: $value');
        });
      }
    });
    _modelController.addListener(() {
      final modelValue = _modelController.text.trim();
      formData.setMakeModel(modelValue);
      formData.saveFormState();
      debugPrint('MakeModel updated: $modelValue');
    });
    _variantController.addListener(() {
      final variantValue = _variantController.text.trim();
      formData.setVariant(variantValue);
      formData.saveFormState();
      debugPrint('Variant updated in controller to: $variantValue');
      debugPrint('formData.variant is now: ${formData.variant}');
    });
    _brandsController.addListener(() {
      if (_brandsController.text.isNotEmpty) {
        final brandValue = _brandsController.text.trim();
        formData.setBrands([brandValue]);
        formData.saveFormState();
        debugPrint('Brands updated: $brandValue');
      }
    });
    _configController.addListener(() {
      formData.setConfig(_configController.text);
      formData.saveFormState();
      debugPrint('Config updated: ${_configController.text}');
    });
    _applicationController.addListener(() {
      formData.setApplication(_applicationController.text);
      formData.saveFormState();
      debugPrint('Application updated: ${_applicationController.text}');
    });
  }

  Future<void> _populateExistingVehicleData() async {
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    try {
      debugPrint("Starting _populateExistingVehicleData");

      if (widget.vehicle == null) {
        debugPrint("Error: widget.vehicle is null");
        return;
      }

      // Log the full vehicle data for reference
      final vehicleMap = widget.vehicle!.toMap();
      debugPrint("Fetched vehicle data: $vehicleMap");

      // 1. Prepopulate Year, Brands, Models and Variants
      if (widget.vehicle?.year != null) {
        debugPrint("Vehicle year: ${widget.vehicle!.year}");
        formData.setYear(widget.vehicle!.year);
        await _loadBrandsForYear(widget.vehicle!.year);
      } else {
        debugPrint("Vehicle year is null");
      }

      if (widget.vehicle?.brands != null && widget.vehicle!.brands.isNotEmpty) {
        final brand = widget.vehicle!.brands[0];
        debugPrint("Vehicle brand: $brand");
        formData.setBrands([brand]);
        _brandsController.text = brand;
        await _loadModelsForBrand(brand);
      } else {
        debugPrint("No brand data in vehicle");
      }

      if (widget.vehicle?.makeModel != null &&
          widget.vehicle!.makeModel.isNotEmpty) {
        debugPrint("Vehicle model: ${widget.vehicle!.makeModel}");
        formData.setMakeModel(widget.vehicle!.makeModel);
        _modelController.text = widget.vehicle!.makeModel;
        await _loadVariantsForModel(widget.vehicle!.makeModel);
      } else {
        debugPrint("No model data in vehicle");
      }

      if (widget.vehicle?.variant != null &&
          widget.vehicle!.variant!.isNotEmpty) {
        debugPrint("Vehicle variant: ${widget.vehicle!.variant}");
        formData.setVariant(widget.vehicle!.variant);
        _variantController.text = widget.vehicle!.variant!;
      } else {
        debugPrint("No variant data in vehicle");
      }

      // 2. Prepopulate Image and Document Fields
      if (widget.vehicle?.mainImageUrl != null &&
          widget.vehicle!.mainImageUrl!.isNotEmpty) {
        debugPrint("Vehicle mainImageUrl: ${widget.vehicle!.mainImageUrl}");
        formData.setMainImageUrl(widget.vehicle!.mainImageUrl);
      } else {
        debugPrint("No mainImageUrl found in vehicle");
      }

      // For NATIS/RC1 document: first use rc1NatisFile; if empty, fallback to adminData.natisRc1Url
      setState(() {
        _existingNatisRc1Url = widget.vehicle?.rc1NatisFile;
        if ((_existingNatisRc1Url == null || _existingNatisRc1Url!.isEmpty) &&
            widget.vehicle?.adminData != null) {
          _existingNatisRc1Url = widget.vehicle!.natisRc1Url ?? '';
        }
        _existingNatisRc1Name = _getFileNameFromUrl(_existingNatisRc1Url);
        debugPrint(
            "NATIS/RC1 file from vehicle: '$_existingNatisRc1Url', name: '$_existingNatisRc1Name'");
      });

      // 3. Prepopulate Basic Text Fields (including Reference Number)
      setState(() {
        _referenceNumberController.text = widget.vehicle?.referenceNumber ?? '';
        if (_referenceNumberController.text.isEmpty &&
            widget.vehicle?.adminData != null) {
          _referenceNumberController.text =
              widget.vehicle!.referenceNumber ?? '';
        }
        debugPrint(
            "Prepopulated Reference Number: ${_referenceNumberController.text}");
      });

      // 4. Set Additional Form Data
      formData.setVinNumber(widget.vehicle?.vinNumber);
      formData.setMileage(widget.vehicle?.mileage);
      formData.setEngineNumber(widget.vehicle?.engineNumber);
      formData.setRegistrationNumber(widget.vehicle?.registrationNumber);

      // Use expectedSellingPrice if available; otherwise, fall back to settlementAmount.
      String sellingPrice = widget.vehicle!.expectedSellingPrice;
      if (sellingPrice.isEmpty || sellingPrice == "0") {
        sellingPrice =
            widget.vehicle?.adminData.settlementAmount.toString() ?? '';
      }
      formData.setSellingPrice(sellingPrice);
      formData.setWarrantyDetails(widget.vehicle?.warrantyDetails);
      formData.setReferenceNumber(widget.vehicle?.referenceNumber);

      // *** NEW: Prepopulate Configuration, Application, and Province ***
      if (widget.vehicle?.config != null && widget.vehicle!.config.isNotEmpty) {
        formData.setConfig(widget.vehicle!.config);
        _configController.text = widget.vehicle!.config;
      }
      if (widget.vehicle?.application != null &&
          widget.vehicle!.application.isNotEmpty) {
        String applicationText = widget.vehicle!.application.join(', ');
        formData.setApplication(applicationText);
        _applicationController.text = applicationText;
      }

      debugPrint("Vehicle config: ${widget.vehicle!.config}");
      debugPrint("Vehicle application: ${widget.vehicle!.application}");

      if (widget.vehicle?.province != null &&
          widget.vehicle!.province.isNotEmpty) {
        formData.setProvince(widget.vehicle!.province);
      }

      // ... continue with your remaining prepopulation logic ...

      debugPrint("Completed _populateExistingVehicleData");
    } catch (e) {
      debugPrint("Error in _populateExistingVehicleData: $e");
    }
  }

  // Helper to extract filename from URL
  String? _getFileNameFromUrl(String? url) {
    if (url == null) return null;
    return url.split('/').last.split('?').first;
  }

  // Function to pick NATIS/RC1 file
  Future<void> _pickNatisRc1File() async {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Choose Source for NATIS/RC1 Document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final imageBytes = await capturePhoto(context);
                  if (imageBytes != null) {
                    setState(() {
                      _natisRc1File = imageBytes;
                      _natisRc1FileName = "captured_natisRc1.png";
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: [
                      'pdf',
                      'jpg',
                      'jpeg',
                      'png',
                      'doc',
                      'docx',
                      'xls',
                      'xlsx'
                    ],
                  );
                  if (result != null) {
                    final bytes = await result.xFiles.first.readAsBytes();
                    final fileName = result.xFiles.first.name;
                    setState(() {
                      _natisRc1File = bytes;
                      _natisRc1FileName = fileName;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper function to get file icon based on extension
  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.grid_on;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Helper method to check if file is an image
  bool _isImageFile(String path) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    String extension = path.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }

  // Helper method to display uploaded files
  Widget _buildUploadedFile(File? file, bool isUploading) {
    if (file == null) {
      return const Text('No file selected',
          style: TextStyle(color: Colors.white70));
    } else {
      String fileName = file.path.split('/').last;
      String extension = fileName.split('.').last;
      return Column(
        children: [
          if (_isImageFile(file.path))
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child:
                  Image.file(file, width: 100, height: 100, fit: BoxFit.cover),
            )
          else
            Column(
              children: [
                Icon(_getFileIcon(extension), color: Colors.white, size: 50.0),
                const SizedBox(height: 8),
                Text(fileName,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center),
              ],
            ),
          const SizedBox(height: 8),
          if (isUploading)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(width: 10),
                Text('Uploading...', style: TextStyle(color: Colors.white)),
              ],
            ),
        ],
      );
    }
  }

  // -------------------------- New Function: Load Sales Rep Users ---------------------------
  /// Load users from Firestore whose userRole is either 'admin' or 'sales representative'
  Future<void> _loadSalesRepUsers() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userRole', whereIn: ['admin', 'sales representative']).get();
      setState(() {
        _salesRepUsers = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'email': data['email'] ?? 'No Email',
          };
        }).toList();
      });
      debugPrint('Loaded sales rep users: $_salesRepUsers');
      // Debug: log the email addresses and ids
      for (var user in _salesRepUsers) {
        debugPrint('Sales Rep - ID: ${user['id']}, Email: ${user['email']}');
      }
      // Prepopulate the sales rep dropdown if editing a vehicle.
      if (widget.vehicle != null) {
        String? currentSalesRepId;
        final vehMap = widget.vehicle!.toMap();
        if (vehMap.containsKey('assignedSalesRepId') &&
            (vehMap['assignedSalesRepId'] as String).isNotEmpty) {
          currentSalesRepId = vehMap['assignedSalesRepId'];
          debugPrint(
              'Found assignedSalesRepId in vehicle data: $currentSalesRepId');
        } else {
          debugPrint('No assignedSalesRepId found in vehicle data.');
        }
        if (currentSalesRepId != null) {
          _selectedSalesRepId = currentSalesRepId;
          debugPrint('Setting _selectedSalesRepId to: $_selectedSalesRepId');
          if (_salesRepUsers.isNotEmpty) {
            try {
              final matching = _salesRepUsers
                  .firstWhere((user) => user['id'] == currentSalesRepId);
              setState(() {
                _selectedSalesRepEmail = matching['email'];
              });
              debugPrint(
                  'Prepopulated sales rep email: $_selectedSalesRepEmail');
            } catch (e) {
              debugPrint(
                  'No matching sales rep found for id $currentSalesRepId');
            }
          } else {
            debugPrint('Sales rep users not loaded yet.');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading sales rep users: $e');
    }
  }
  // --------------------------------------------------------------------

  // -------------------------- Existing Function: Load Transporter Users --------------------------
  /// Load users from Firestore whose userRole is either 'transporter' or 'admin'
  Future<void> _loadTransporterUsers() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userRole', whereIn: ['transporter', 'admin']).get();
      setState(() {
        _transporterUsers = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'email': data['email'] ?? 'No Email',
          };
        }).toList();
      });
      debugPrint('Loaded owner users: $_transporterUsers');
      // Prepopulate the owner dropdown if editing a vehicle.
      if (widget.vehicle != null) {
        String? currentOwnerId;
        final vehMap = widget.vehicle!.toMap();
        if (vehMap.containsKey('assignedTransporterId') &&
            (vehMap['assignedTransporterId'] as String).isNotEmpty) {
          currentOwnerId = vehMap['assignedTransporterId'];
        } else {
          currentOwnerId = widget.vehicle!.userId;
        }
        _selectedTransporterId = currentOwnerId;
        debugPrint('Current owner ID set to: $_selectedTransporterId');
        if (_transporterUsers.isNotEmpty) {
          try {
            final matching = _transporterUsers
                .firstWhere((user) => user['id'] == currentOwnerId);
            _selectedTransporterEmail = matching['email'];
            debugPrint(
                'Prepopulated owner email: $_selectedTransporterEmail');
          } catch (e) {
            debugPrint('No matching owner found for id $currentOwnerId');
          }
        }
            }
    } catch (e) {
      debugPrint('Error loading owner users: $e');
    }
  }
  // --------------------------------------------------------------------

  // -------------------------- New Widget: Sales Rep Dropdown ---------------------------
  /// Widget to display and assign the truck's sales rep (admins and sales representatives)
  Widget _buildSalesRepField() {
    final List<String> salesRepEmails =
        _salesRepUsers.map((user) => user['email'] as String).toList();
    debugPrint('Building Sales Rep Field with emails: $salesRepEmails');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Currently Assigned Sales Rep: ${_selectedSalesRepEmail ?? "None"}",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 8),
        CustomDropdown(
          hintText: 'Assigned Sales Rep',
          value: _selectedSalesRepEmail,
          items: salesRepEmails,
          onChanged: (value) {
            setState(() {
              _selectedSalesRepEmail = value;
              try {
                final matching =
                    _salesRepUsers.firstWhere((user) => user['email'] == value);
                _selectedSalesRepId = matching['id'];
                debugPrint(
                    'Sales Rep selected - ID: $_selectedSalesRepId, Email: $_selectedSalesRepEmail');
              } catch (e) {
                _selectedSalesRepId = null;
                debugPrint(
                    'Error finding matching sales rep for value $value: $e');
              }
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a sales rep';
            }
            return null;
          },
          enabled: true,
          isTransporter: true,
        ),
      ],
    );
  }
  // --------------------------------------------------------------------

  // Existing Widget: Truck Owner Dropdown (Transporter)
  Widget _buildTruckOwnerField() {
    final List<String> ownerEmails =
        _transporterUsers.map((user) => user['email'] as String).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Currently Assigned Transporter: ${_selectedTransporterEmail ?? "None"}",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 8),
        CustomDropdown(
          hintText: 'Truck Belongs To',
          value: _selectedTransporterEmail,
          items: ownerEmails,
          onChanged: (value) {
            setState(() {
              _selectedTransporterEmail = value;
              try {
                final matching = _transporterUsers
                    .firstWhere((user) => user['email'] == value);
                _selectedTransporterId = matching['id'];
                debugPrint(
                    'Transporter selected - ID: $_selectedTransporterId, Email: $_selectedTransporterEmail');
              } catch (e) {
                _selectedTransporterId = null;
                debugPrint(
                    'Error finding matching transporter for value $value: $e');
              }
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select an owner';
            }
            return null;
          },
          enabled: true,
          isTransporter: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final formData = Provider.of<FormDataProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String userRole = userProvider.getUserRole;
    final bool isAdmin = userRole == 'admin';
    final bool isDealer = userRole == 'dealer';
    final bool isTransporter = userRole == 'transporter';
    // New flag for sales representatives
    final bool isSalesRep = userRole == 'sales representative';

    // Get the screen width
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isCompactNavigation = screenWidth < 800;

    return WillPopScope(
      onWillPop: () async {
        if (widget.isNewUpload) {
          final formData =
              Provider.of<FormDataProvider>(context, listen: false);
          _clearAllData(formData);
          debugPrint('Navigating back. Cleared all form data for new upload.');
        }
        return true;
      },
      child: Stack(
        children: [
          Scaffold(
            key: _scaffoldKey,
            drawer: kIsWeb && isCompactNavigation
                ? Drawer(
                    child: Container(
                      color: Colors.white,
                      child: ListView(
                        children: [
                          DrawerHeader(
                            decoration: const BoxDecoration(
                              color: Color(0xFF0E4CAF),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.vehicle?.referenceNumber ??
                                      'New Vehicle',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.vehicle?.makeModel ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Add your drawer items here
                        ],
                      ),
                    ),
                  )
                : null,
            appBar: !kIsWeb
                ? AppBar(
                    title: const Text('Basic Information'),
                    backgroundColor: const Color(0xFF0E4CAF),
                  )
                : PreferredSize(
                    preferredSize: const Size.fromHeight(70),
                    child: TruckInfoWebNavBar(
                      scaffoldKey: _scaffoldKey,
                      selectedTab: "Basic Information",
                      vehicleId: widget.vehicle?.id ?? '',
                      onHomePressed: () =>
                          Navigator.pushNamed(context, '/home'),
                      onBasicInfoPressed: () =>
                          Navigator.pushNamed(context, '/basic_information'),
                      onTruckConditionsPressed: () =>
                          Navigator.pushNamed(context, '/truck_conditions'),
                      onExternalCabPressed: () =>
                          Navigator.pushNamed(context, '/external_cab'),
                      onInternalCabPressed: () =>
                          Navigator.pushNamed(context, '/internal_cab'),
                      onChassisPressed: () =>
                          Navigator.pushNamed(context, '/chassis'),
                      onDriveTrainPressed: () =>
                          Navigator.pushNamed(context, '/drive_train'),
                      onTyresPressed: () =>
                          Navigator.pushNamed(context, '/tyres'),
                      onMaintenanceWarrantyPressed: () async {
                        // Add error handling and proper data passing
                        try {
                          if (widget.vehicle?.id != null) {
                            DocumentSnapshot doc = await FirebaseFirestore
                                .instance
                                .collection('vehicles')
                                .doc(widget.vehicle!.id)
                                .get();

                            Map<String, dynamic> data =
                                doc.data() as Map<String, dynamic>;
                            Map<String, dynamic> maintenanceData =
                                data['maintenanceData']
                                        as Map<String, dynamic>? ??
                                    {};

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MaintenanceEditSection(
                                  vehicleId: widget.vehicle!.id,
                                  isUploading: false,
                                  isEditing: true,
                                  isFromAdmin: true,
                                  onMaintenanceFileSelected: (file) {},
                                  onWarrantyFileSelected: (file) {},
                                  oemInspectionType:
                                      maintenanceData['oemInspectionType'] ??
                                          'yes',
                                  oemInspectionExplanation:
                                      maintenanceData['oemReason'] ?? '',
                                  onProgressUpdate: () {},
                                  maintenanceSelection:
                                      maintenanceData['maintenanceSelection'] ??
                                          'yes',
                                  warrantySelection:
                                      maintenanceData['warrantySelection'] ??
                                          'yes',
                                  maintenanceDocUrl:
                                      maintenanceData['maintenanceDocUrl'],
                                  warrantyDocUrl:
                                      maintenanceData['warrantyDocUrl'],
                                  isFromTransporter: true,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Vehicle ID is not available')),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Error loading maintenance data: $e')),
                          );
                        }
                      },
                      // ... rest of the nav bar callbacks ...
                    ),
                  ),
            body: GradientBackground(
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification.metrics.axis == Axis.vertical) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        double offset = scrollNotification.metrics.pixels;
                        if (offset < 0) offset = 0;
                        if (offset > 150.0) offset = 150.0;
                        _imageHeight = 300.0 - offset;
                      });
                    });
                  }
                  return true;
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      _buildImageSection(),
                      _buildMandatorySection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Image.asset(
                    'lib/assets/Loading_Logo_CTP.gif',
                    width: 100,
                    height: 100,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String userRole = userProvider.getUserRole;
    final bool isAdmin = userRole == 'admin';
    final bool isDealer = userRole == 'dealer';
    final bool isTransporter = userRole == 'transporter';
    // Allow sales representatives the same image options as admin
    final bool isSalesRep = userRole == 'sales representative';
    final formData = Provider.of<FormDataProvider>(context);
    void showImagePickerDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          );
        },
      );
    }

    void handleImageTap() {
      if (isDealer) return;
      if (formData.selectedMainImage != null ||
          (formData.mainImageUrl != null &&
              formData.mainImageUrl!.isNotEmpty)) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Image Options'),
              content: const Text('What would you like to do with the image?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    showImagePickerDialog();
                  },
                  child: const Text('Change Image'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      formData.setSelectedMainImage(null, null);
                      formData.setMainImageUrl(null);
                    });
                    debugPrint('Main image removed by user.');
                  },
                  child: const Text('Remove Image',
                      style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      } else {
        showImagePickerDialog();
      }
    }

    return GestureDetector(
      onTap: handleImageTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 0),
        height: _imageHeight,
        width: double.infinity,
        child: Stack(
          children: [
            if (formData.selectedMainImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.memory(formData.selectedMainImage!,
                    width: double.infinity,
                    height: _imageHeight,
                    fit: BoxFit.cover),
              )
            else if (formData.mainImageUrl != null &&
                formData.mainImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(formData.mainImageUrl!,
                    width: double.infinity,
                    height: _imageHeight,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                }),
              )
            else
              ImagePickerWidget(
                onImagePicked: (Uint8List? image, fileName) {
                  if (image != null) {
                    formData.setSelectedMainImage(image, fileName);
                    debugPrint('Main image picked: $fileName');
                  }
                },
              ),
            if (isTransporter || isAdmin || isSalesRep)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4)),
                  child: const Text('Tap to modify image',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMandatorySection() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String userRole = userProvider.getUserRole;
    final bool isAdmin = userRole == 'admin';
    final bool isDealer = userRole == 'dealer';
    final bool isTransporter = userRole == 'transporter';
    final bool isSalesRep = userRole == 'sales representative';
    final formData = Provider.of<FormDataProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Text('BASIC INFORMATION'.toUpperCase(),
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 10),
          if (isTransporter || isAdmin || isSalesRep)
            Center(
                child: Text('Please fill out the required details below.',
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center)),
          if (isTransporter || isAdmin || isSalesRep)
            Center(
                child: Text('Your trusted partner on the road.',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    textAlign: TextAlign.center)),
          const SizedBox(height: 20),
          if (isTransporter || isAdmin || isSalesRep)
            CustomDropdown(
              hintText: 'Vehicle Status',
              value: _vehicleStatus ?? _initialVehicleStatus ?? 'Draft',
              items: const ['Draft', 'Live'],
              onChanged: (value) {
                setState(() {
                  _vehicleStatus = value;
                  formData.setVehicleStatus(value);
                });
                debugPrint('Vehicle Status selected: $value');
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select the vehicle status';
                }
                return null;
              },
              isTransporter: isTransporter || isAdmin || isSalesRep,
            ),
          const SizedBox(height: 15),
          if (isTransporter || isAdmin || isSalesRep)
            _buildReferenceNumberField(),
          const SizedBox(height: 15),
          if (isTransporter || isAdmin || isSalesRep) _buildNatisRc1Section(),
          const SizedBox(height: 15),
          if (isAdmin || isSalesRep) ...[
            _buildTruckOwnerField(),
            const SizedBox(height: 15),
          ],
          if (isAdmin) ...[
            _buildSalesRepField(),
            const SizedBox(height: 15),
          ],
          Form(
            key: _formKeys[0],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDealer)
                  const Text('Year',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                if (isDealer) const SizedBox(height: 15),
                CustomDropdown(
                  hintText: 'Year',
                  enabled: !isDealer,
                  value: formData.year,
                  items: _yearOptions,
                  onChanged: (value) {
                    debugPrint('Year selected: $value');
                    formData.setYear(value);
                    _loadBrandsForYear(value!);
                    formData.saveFormState();
                  },
                  isTransporter: isTransporter || isAdmin || isSalesRep,
                ),
                const SizedBox(height: 15),
                if (isDealer)
                  const Text('Manufacturer',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                if (isDealer) const SizedBox(height: 15),
                CustomDropdown(
                  hintText: 'Manufacturer',
                  value: formData.brands?.isNotEmpty == true
                      ? formData.brands![0]
                      : null,
                  items: _brandOptions,
                  onChanged: (value) async {
                    if (value != null) {
                      debugPrint('Manufacturer selected: $value');
                      formData.setBrands([value]);
                      await _loadModelsForBrand(value);
                      formData.saveFormState();
                    }
                  },
                  enabled: !isDealer,
                ),
                const SizedBox(height: 15),
                if (isDealer)
                  const Text('Model',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                if (isDealer) const SizedBox(height: 15),
                CustomDropdown(
                  hintText: 'Model',
                  value: formData.makeModel,
                  items: _makeModelOptions[formData.brands?.isNotEmpty == true
                          ? formData.brands![0]
                          : ''] ??
                      [],
                  onChanged: (value) async {
                    if (value != null) {
                      formData.setMakeModel(value);
                      await _loadVariantsForModel(value);
                      formData.saveFormState();
                    }
                  },
                  enabled: !isDealer,
                ),
                const SizedBox(height: 15),
                if (isDealer)
                  const Text('Variant',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                if (isDealer) const SizedBox(height: 15),
                CustomDropdown(
                  hintText: 'Select Variant',
                  value: formData.variant,
                  items: _variantOptions,
                  onChanged: (value) {
                    formData.setVariant(value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a variant';
                    }
                    return null;
                  },
                  enabled: !isDealer,
                ),
                const SizedBox(height: 15),
                if (isDealer)
                  const Text('Country',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                if (isDealer) const SizedBox(height: 15),
                CustomDropdown(
                  hintText: 'Select Country',
                  enabled: !isDealer,
                  value: (formData.country?.isNotEmpty == true
                      ? formData.country
                      : null),
                  items: _countryOptions,
                  onChanged: (value) {
                    debugPrint('Country selected: $value');
                    formData.setCountry(value);
                    if (value != null) {
                      _updateProvinceOptions(value);
                      // Optionally clear any previously selected province
                      formData.setProvince(null);
                    }
                  },
                  isTransporter: isTransporter || isAdmin || isSalesRep,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a country';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                // New Province/State Dropdown – exactly like on vehicle upload screen
                CustomDropdown(
                  hintText: 'Select Province/State',
                  value: (formData.province?.isNotEmpty == true
                      ? formData.province
                      : null), // Assumes formData has province field and setter
                  items: _provinceOptions,
                  onChanged: (value) {
                    debugPrint('Province selected: $value');
                    formData.setProvince(value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a province/state';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                if (isDealer)
                  const Text('Mileage',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                if (isDealer) const SizedBox(height: 15),
                CustomTextField(
                  controller: _mileageController,
                  hintText: 'Mileage',
                  enabled: !isDealer,
                  keyboardType: TextInputType.number,
                  inputFormatter: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the mileage';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                if (isDealer)
                  const Text('Configuration',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                if (isDealer) const SizedBox(height: 15),
                CustomDropdown(
                  hintText: 'Configuration',
                  enabled: !isDealer,
                  value: (formData.config?.isNotEmpty == true
                      ? formData.config
                      : null),
                  items: _configurationOptions,
                  onChanged: (value) {
                    debugPrint('Configuration selected: $value');
                    formData.setConfig(value);
                    formData.saveFormState();
                  },
                  isTransporter: isTransporter || isAdmin || isSalesRep,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select the configuration';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                if (isDealer)
                  const Text('Application of Use',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                if (isDealer) const SizedBox(height: 15),
                CustomDropdown(
                  hintText: 'Application of Use',
                  enabled: !isDealer,
                  value: (formData.application?.isNotEmpty == true
                      ? formData.application
                      : null),
                  items: _applicationOptions,
                  onChanged: (value) {
                    debugPrint('Application of Use selected: $value');
                    formData.setApplication(value);
                    formData.saveFormState();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select the application of use';
                    }
                    return null;
                  },
                  isTransporter: isTransporter || isAdmin || isSalesRep,
                ),
                const SizedBox(height: 15),
                if (isTransporter || isAdmin || isSalesRep)
                  CustomTextField(
                    controller: _vinNumberController,
                    hintText: 'VIN Number',
                    inputFormatter: [UpperCaseTextFormatter()],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the VIN number';
                      }
                      return null;
                    },
                  ),
                if (isTransporter || isAdmin || isSalesRep)
                  const SizedBox(height: 15),
                if (isTransporter || isAdmin || isSalesRep)
                  CustomTextField(
                    controller: _engineNumberController,
                    enabled: !isDealer,
                    hintText: 'Engine No.',
                    inputFormatter: [UpperCaseTextFormatter()],
                  ),
                if (isTransporter || isAdmin || isSalesRep)
                  const SizedBox(height: 15),
                if (isTransporter || isAdmin || isSalesRep)
                  CustomTextField(
                    controller: _registrationNumberController,
                    enabled: !isDealer,
                    hintText: 'Registration No.',
                    inputFormatter: [UpperCaseTextFormatter()],
                  ),
                if (isTransporter || isAdmin || isSalesRep)
                  const SizedBox(height: 15),
                if (isTransporter || isAdmin || isSalesRep)
                  CustomTextField(
                    controller: _sellingPriceController,
                    hintText: 'Selling Price',
                    isCurrency: true,
                    keyboardType: TextInputType.number,
                    inputFormatter: [
                      FilteringTextInputFormatter.digitsOnly,
                      ThousandsSeparatorInputFormatter(),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the selling price';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 15),
                Center(
                    child: Text('Suspension',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white),
                        textAlign: TextAlign.center)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomRadioButton(
                      label: 'Spring',
                      value: 'spring',
                      groupValue: formData.suspension,
                      enabled: !isDealer,
                      onChanged: (value) {
                        debugPrint('Suspension selected: $value');
                        formData.setSuspension(value);
                        formData.saveFormState();
                      },
                    ),
                    const SizedBox(width: 15),
                    CustomRadioButton(
                      label: 'Air',
                      value: 'air',
                      groupValue: formData.suspension,
                      enabled: !isDealer,
                      onChanged: (value) {
                        debugPrint('Suspension selected: $value');
                        formData.setSuspension(value);
                        formData.saveFormState();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),
                Center(
                    child: Text('Transmission',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white),
                        textAlign: TextAlign.center)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomRadioButton(
                      label: 'Automatic',
                      value: 'automatic',
                      groupValue: formData.transmissionType,
                      enabled: !isDealer,
                      onChanged: (value) {
                        debugPrint('Transmission Type selected: $value');
                        formData.setTransmissionType(value);
                        formData.saveFormState();
                      },
                    ),
                    const SizedBox(width: 15),
                    CustomRadioButton(
                      label: 'Manual',
                      value: 'manual',
                      groupValue: formData.transmissionType,
                      enabled: !isDealer,
                      onChanged: (value) {
                        debugPrint('Transmission Type selected: $value');
                        formData.setTransmissionType(value);
                        formData.saveFormState();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),
                Center(
                    child: Text('Hydraulics',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white),
                        textAlign: TextAlign.center)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomRadioButton(
                      label: 'Yes',
                      value: 'yes',
                      groupValue: formData.hydraulics,
                      enabled: !isDealer,
                      onChanged: (value) {
                        debugPrint('Hydraulics selected: $value');
                        formData.setHydraulics(value);
                        formData.saveFormState();
                      },
                    ),
                    const SizedBox(width: 15),
                    CustomRadioButton(
                      label: 'No',
                      value: 'no',
                      groupValue: formData.hydraulics,
                      enabled: !isDealer,
                      onChanged: (value) {
                        debugPrint('Hydraulics selected: $value');
                        formData.setHydraulics(value);
                        formData.saveFormState();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),
                Center(
                    child: Text('Maintenance',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white),
                        textAlign: TextAlign.center)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomRadioButton(
                      label: 'Yes',
                      value: 'yes',
                      groupValue:
                          formData.maintenance.toString(), // Convert to string
                      enabled: !isDealer,
                      onChanged: (value) {
                        setState(() {
                          formData.setMaintenance(value);
                        });
                        formData.saveFormState();
                        debugPrint(
                            'Maintenance onChanged callback called with value: $value');
                        debugPrint(
                            'FormData maintenance after onChanged: ${formData.maintenance}');
                      },
                    ),
                    const SizedBox(width: 15),
                    CustomRadioButton(
                      label: 'No',
                      value: 'no',
                      groupValue:
                          formData.maintenance.toString(), // Convert to string
                      enabled: !isDealer,
                      onChanged: (value) {
                        setState(() {
                          formData.setMaintenance(value);
                        });
                        formData.saveFormState();
                        debugPrint(
                            'Maintenance onChanged callback called with value: $value');
                        debugPrint(
                            'FormData maintenance after onChanged: ${formData.maintenance}');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),
                Center(
                    child: Text('Warranty',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white),
                        textAlign: TextAlign.center)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomRadioButton(
                      label: 'Yes',
                      value: 'yes',
                      groupValue: formData.warranty,
                      enabled: !isDealer,
                      onChanged: (value) {
                        debugPrint('Warranty selected: $value');
                        formData.setWarranty(value);
                        formData.saveFormState();
                      },
                    ),
                    const SizedBox(width: 15),
                    CustomRadioButton(
                      label: 'No',
                      value: 'no',
                      groupValue: formData.warranty,
                      enabled: !isDealer,
                      onChanged: (value) {
                        debugPrint('Warranty selected: $value');
                        formData.setWarranty(value);
                        formData.saveFormState();
                      },
                    ),
                  ],
                ),
                if (formData.warranty == 'yes') ...[
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _warrantyDetailsController,
                    hintText: 'WHAT MAIN WARRANTY IS THE VEHICLE ON',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the warranty details';
                      }
                      return null;
                    },
                    enabled: !isDealer,
                  ),
                ],
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),
                if (isTransporter || isAdmin || isSalesRep)
                  Center(
                      child: Text(
                          'DO YOU REQUIRE THE TRUCK TO BE SETTLED BEFORE SELLING'
                              .toUpperCase(),
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white),
                          textAlign: TextAlign.center)),
                if (isDealer)
                  Center(
                      child: Text('Settlement Needed',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white),
                          textAlign: TextAlign.start)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomRadioButton(
                      label: 'Yes',
                      value: 'yes',
                      groupValue: formData.requireToSettleType,
                      enabled: !isDealer,
                      onChanged: (value) {
                        debugPrint('Require to Settle selected: $value');
                        formData.setRequireToSettleType(value);
                        formData.saveFormState();
                      },
                    ),
                    const SizedBox(width: 15),
                    CustomRadioButton(
                      label: 'No',
                      value: 'no',
                      groupValue: formData.requireToSettleType,
                      enabled: !isDealer,
                      onChanged: (value) {
                        debugPrint('Require to Settle selected: $value');
                        formData.setRequireToSettleType(value);
                        formData.saveFormState();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (isTransporter || isAdmin || isSalesRep) _buildNextButton(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Future<String?> _saveSection1Data() async {
    try {
      final formData = Provider.of<FormDataProvider>(context, listen: false);
      debugPrint('Starting _saveSection1Data');
      String? imageUrl = formData.mainImageUrl;
      String? natisRc1Url = _existingNatisRc1Url;
      if (formData.selectedMainImage != null) {
        debugPrint('Uploading main image...');
        final ref = FirebaseStorage.instance
            .ref()
            .child('vehicle_images')
            .child('${DateTime.now().toIso8601String()}.jpg');
        await ref.putData(formData.selectedMainImage!);
        imageUrl = await ref.getDownloadURL();
        debugPrint('Main image uploaded. URL: $imageUrl');
      }
      if (_natisRc1File != null) {
        debugPrint('Uploading NATIS/RC1 file...');
        final ref = FirebaseStorage.instance.ref().child('vehicle_documents').child(
            '${DateTime.now().millisecondsSinceEpoch}_${_natisRc1FileName!.split('/').last}');
        await ref.putData(_natisRc1File!);
        natisRc1Url = await ref.getDownloadURL();
        debugPrint('NATIS/RC1 file uploaded. URL: $natisRc1Url');
      }
      final vehicleData = {
        'year': formData.year,
        'brands': formData.brands ?? [],
        'makeModel': formData.makeModel?.trim() ?? '',
        'variant': formData.variant?.trim() ?? '',
        'vinNumber': formData.vinNumber,
        'config': formData.config,
        'mileage': formData.mileage,
        'application': formData.application,
        'engineNumber': formData.engineNumber,
        'registrationNumber': formData.registrationNumber,
        'sellingPrice': formData.sellingPrice,
        'vehicleType': formData.vehicleType,
        'suspensionType': formData.suspension,
        'transmissionType': formData.transmissionType,
        'hydraulics': formData.hydraulics,
        'maintenance': formData.maintenance,
        'warranty': formData.warranty,
        'warrantyDetails': formData.warrantyDetails,
        'requireToSettleType': formData.requireToSettleType,
        'referenceNumber': formData.referenceNumber,
        'mainImageUrl': imageUrl,
        'rc1NatisFile': natisRc1Url,
        'country': formData.country,
        'province': formData.province,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        // Use the selected transporter id if available; otherwise use the current user id.
        'userId':
            _selectedTransporterId ?? FirebaseAuth.instance.currentUser?.uid,
        'vehicleStatus': _vehicleStatus ?? _initialVehicleStatus ?? 'Draft',
        if (_selectedTransporterId != null)
          'assignedTransporterId': _selectedTransporterId,
        // NEW: Save the assigned sales rep ID if it exists.
        if (_selectedSalesRepId != null)
          'assignedSalesRepId': _selectedSalesRepId,
        'modelDetails': {
          'year': formData.year,
          'manufacturer': formData.brands?.first ?? '',
          'model': formData.makeModel,
          'variant': formData.variant,
        },
      };
      debugPrint('Vehicle Data to Save: $vehicleData');
      if (_vehicleId != null && !widget.isDuplicating) {
        debugPrint('Updating existing vehicle with ID: $_vehicleId');
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(_vehicleId)
            .update(vehicleData);
        setState(() {
          formData.setReferenceNumber(_referenceNumberController.text.trim());
          if (_referenceNumberController.text != formData.referenceNumber) {
            _referenceNumberController.text = formData.referenceNumber ?? '';
          }
        });
        debugPrint('Vehicle updated successfully.');
      } else {
        debugPrint('Creating new vehicle entry.');
        final docRef =
            await FirebaseFirestore.instance.collection('vehicles').add({
          ...vehicleData,
          'createdAt': FieldValue.serverTimestamp(),
          'userId':
              _selectedTransporterId ?? FirebaseAuth.instance.currentUser?.uid,
          'vehicleStatus': _vehicleStatus ?? 'Draft',
        });
        _vehicleId = docRef.id;
        debugPrint('Vehicle created successfully with ID: $_vehicleId');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle created successfully')),
        );
      }
      return _vehicleId;
    } catch (e) {
      debugPrint('Error saving vehicle: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error saving vehicle: $e')));
      return null;
    }
  }

  bool _validateRequiredFields(FormDataProvider formData) {
    if (formData.selectedMainImage == null &&
        (formData.mainImageUrl == null || formData.mainImageUrl!.isEmpty)) {
      debugPrint('Validation failed: No main image added.');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add a main image')));
      return false;
    }
    if (formData.year == null || formData.year!.isEmpty) {
      debugPrint('Validation failed: Year is missing.');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter the year')));
      return false;
    }
    return true;
  }

  Widget _buildNextButton() {
    return Center(
      child: CustomButton(
        text: 'Save Changes',
        borderColor: AppColors.orange,
        onPressed: () async {
          final formData =
              Provider.of<FormDataProvider>(context, listen: false);
          if (!_validateRequiredFields(formData)) return;
          setState(() => _isLoading = true);
          debugPrint('Form submission initiated.');
          try {
            String? vehicleId = await _saveSection1Data();
            if (vehicleId != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Changes saved successfully'),
                    duration: Duration(seconds: 2)),
              );
              await MyNavigator.pushReplacement(context, VehiclesListPage());
              debugPrint('Navigating back after successful save.');
              setState(() {});
            }
          } finally {
            setState(() => _isLoading = false);
            debugPrint('Form submission completed.');
          }
        },
      ),
    );
  }

  void _clearFormControllers() {
    debugPrint('Clearing all form controllers.');
    _sellingPriceController.clear();
    _vinNumberController.clear();
    _mileageController.clear();
    _engineNumberController.clear();
    _warrantyDetailsController.clear();
    _registrationNumberController.clear();
    _referenceNumberController.clear();
    _brandsController.clear();
    _countryController.clear();
    _modelController.clear();
    _variantController.clear();
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    formData.setSelectedMainImage(null, null);
    formData.setMainImageUrl(null);
    setState(() {
      _natisRc1File = null;
      _natisRc1FileName = null;
      _existingNatisRc1Url = null;
      _existingNatisRc1Name = null;
    });
    debugPrint('NATIS/RC1 file data cleared.');
  }

  Future<void> _pickImage(ImageSource source) async {
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    final ImagePicker picker = ImagePicker();
    try {
      if (source == ImageSource.camera) {
        // Use the shared camera helper to capture a photo
        final imageBytes = await capturePhoto(context);
        if (imageBytes != null) {
          formData.setSelectedMainImage(imageBytes, 'captured.png');
          debugPrint("Image captured from camera.");
        } else {
          debugPrint("No image captured from camera.");
        }
      } else {
        // Use the gallery via ImagePicker
        final XFile? image = await picker.pickImage(source: source);
        if (image != null) {
          final bytes = await image.readAsBytes();
          final fileName = image.name;
          formData.setSelectedMainImage(bytes, fileName);
          debugPrint('Image picked from gallery: ${image.path}');
        } else {
          debugPrint('No image selected.');
        }
      }
    } catch (e) {
      debugPrint('Error picking image from $source: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Widget _buildNatisRc1Section() {
    Widget buildFileDisplay(String? fileName, bool isExisting) {
      String extension = fileName?.split('.').last.toLowerCase() ?? '';
      IconData iconData = _getFileIcon(extension);
      return Column(
        children: [
          Icon(iconData, color: Colors.white, size: 50.0),
          const SizedBox(height: 10),
          Text(
              fileName ??
                  (isExisting ? 'Existing Document' : 'Select Document'),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      );
    }

    return Column(
      children: [
        Center(
            child: Text('NATIS/RC1 Documentation'.toUpperCase(),
                style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w900),
                textAlign: TextAlign.center)),
        const SizedBox(height: 15),
        InkWell(
          onTap: () {
            if (_existingNatisRc1Url != null || _natisRc1File != null) {
              _showDocumentOptions();
            } else {
              _pickNatisRc1File();
            }
          },
          borderRadius: BorderRadius.circular(10.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0E4CAF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: const Color(0xFF0E4CAF), width: 2.0),
            ),
            child: _natisRc1File != null
                ? buildFileDisplay(_natisRc1FileName?.split('/').last, false)
                : _existingNatisRc1Url != null &&
                        _existingNatisRc1Url!.isNotEmpty
                    ? buildFileDisplay(_existingNatisRc1Name, true)
                    : buildFileDisplay(null, false),
          ),
        ),
      ],
    );
  }

  void _showDocumentOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Document Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.remove_red_eye),
                title: const Text('View Document'),
                onTap: () {
                  Navigator.pop(context);
                  _viewDocument();
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Replace Document'),
                onTap: () {
                  Navigator.pop(context);
                  _pickNatisRc1File();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Document',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removeDocument();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
          ],
        );
      },
    );
  }

  void _viewDocument() async {
    final url = _natisRc1FileName != null ? null : _existingNatisRc1Url;
    if (url != null && url.isNotEmpty) {
      debugPrint('Attempting to view document at URL: $url');
      try {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          debugPrint('Document opened successfully.');
        } else {
          debugPrint('Could not open document URL.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open document')));
          }
        }
      } catch (e) {
        debugPrint('Error opening document: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error opening document: $e')));
        }
      }
    } else if (_natisRc1File != null) {
      debugPrint('Viewing local NATIS/RC1 file: $_natisRc1FileName');
    }
  }

  void _removeDocument() {
    debugPrint('Removing NATIS/RC1 document.');
    setState(() {
      _natisRc1File = null;
      _existingNatisRc1Url = null;
      _existingNatisRc1Name = null;
    });
    debugPrint('NATIS/RC1 document removed.');
  }

  Widget _buildReferenceNumberField() {
    return Consumer<FormDataProvider>(
      builder: (context, formData, child) {
        return CustomTextField(
          controller: _referenceNumberController,
          hintText: 'Reference Number',
          onChanged: (value) {
            setState(() {
              _referenceNumberController.text = value;
              formData.setReferenceNumber(value);
            });
            debugPrint('Reference Number updated: $value');
          },
        );
      },
    );
  }
}

// Formatter for uppercase text fields
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
        text: newValue.text.toUpperCase(), selection: newValue.selection);
  }
}

// Formatter for inserting thousands separators (e.g., 1234 -> 1,234)
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final String cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final String formatted = NumberFormat('#,###').format(int.parse(cleanText));
    debugPrint('Formatted Selling Price: $formatted');
    return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length));
  }
}
