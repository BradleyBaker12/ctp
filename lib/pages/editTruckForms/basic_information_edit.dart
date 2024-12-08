// vehicle_upload_tabs.dart

import 'dart:io';
import 'dart:convert'; // Added for JSON decoding
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/services.dart'; // Added for loading assets

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

class BasicInformationEdit extends StatefulWidget {
  final bool isDuplicating;
  final Vehicle? vehicle;
  final bool isNewUpload;

  const BasicInformationEdit(
      {super.key,
      this.vehicle,
      this.isDuplicating = false,
      this.isNewUpload = false});

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
  final TextEditingController _countryController =
      TextEditingController(); // Added for country selection
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(1, (index) => GlobalKey<FormState>());
  bool _isLoading = false;
  String? _vehicleId;
  DateTime? _availableDate;
  bool isDealer = false;

  List<String> _countryOptions = []; // Define the country options list

  // Define application options
  final List<String> _applicationOptions = [
    'Bowser Trucks',
    'Cage Body',
    'Roll Back',
    'Cattle Body',
    'Chassis Cab',
    'Cherry Picker',
    'Compactor',
    'Concrete Mixer',
    'Crane Truck',
    'Curtain Side',
    'Diesel Tanker',
    'Drop side',
    'Fire Truck',
    'Flatbed',
    'Honey Sucker',
    'Hook lift',
    'Insulated Body',
    'Mass side',
    'Petrol Tanker',
    'Refrigerated body',
    'Side Tipper',
    'Tipper',
    'Volume Body',
  ];

  // Define configuration options
  final List<String> _configurationOptions = [
    '6X4',
    '6X2',
    '4X2',
    '8X4',
    // Add any other configurations if needed
  ];

  late Map<String, List<String>> _makeModelOptions = {};
  List<String> _variantOptions = [];
  final Map<String, List<String>> _modelVariants = {};
  List<String> _yearOptions = [];
  List<String> _brandOptions = [
    'Ashok Leyland',
    'Dayun',
    'Eicher',
    'FAW',
    'Fiat',
    'Ford',
    'Foton',
    'Fuso',
    'Hino',
    'Hyundai',
    'Isuzu',
    'Iveco',
    'JAC',
    'Joylong',
    'MAN',
    'Mercedes-Benz',
    'Peugeot',
    'Powerstar',
    'Renault',
    'Scania',
    'Tata',
    'Toyota',
    'UD Trucks',
    'US Truck',
    'Volkswagen',
    'Volvo',
    'CNHTC',
    'DAF',
    'Freightliner',
    'Mack',
    'Powerland'
  ];

  Future<void> _loadYearOptions() async {
    final String response =
        await rootBundle.loadString('lib/assets/reorganized_truck_data.json');
    final data = json.decode(response);
    setState(() {
      _yearOptions = (data as Map<String, dynamic>).keys.toList()..sort();
    });
  }

  Future<void> _loadBrandsForYear() async {
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    final String response =
        await rootBundle.loadString('lib/assets/reorganized_truck_data.json');
    final data = json.decode(response);
    setState(() {
      _brandOptions = data[formData.year]?.keys.toList() ?? [];
      formData.setBrands(null);
      formData.setMakeModel(null);
      formData.setVariant(null);
    });
  }

  Future<void> _loadModelsForBrand() async {
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    final String response =
        await rootBundle.loadString('lib/assets/reorganized_truck_data.json');
    final data = json.decode(response);

    if (formData.year != null && formData.brands?.isNotEmpty == true) {
      setState(() {
        final models = (data[formData.year][formData.brands!.first]
                as Map<String, dynamic>)
            .keys
            .toList();
        _makeModelOptions = {formData.brands!.first: models.cast<String>()};
        formData.setMakeModel(null);
        formData.setVariant(null);
      });
    }
  }

  Future<void> _loadVariantsForModel() async {
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    final String response =
        await rootBundle.loadString('lib/assets/reorganized_truck_data.json');
    final data = json.decode(response);

    if (formData.year != null &&
        formData.brands?.isNotEmpty == true &&
        formData.makeModel != null) {
      setState(() {
        _variantOptions = List<String>.from(
            data[formData.year][formData.brands!.first][formData.makeModel]);
        formData.setVariant(null);
      });
    }
  }

  String? _initialVehicleStatus;

  // Variable to hold selected RC1/NATIS file
  File? _natisRc1File;

  // Add this flag at the top with other variables
  bool isNewUpload = false;

  // Add these variables
  String? _existingNatisRc1Url;
  String? _existingNatisRc1Name;

  // Add this line with other class variables
  int _currentStep = 0;

  // Add these controllers
  final TextEditingController _configController = TextEditingController();
  final TextEditingController _applicationController = TextEditingController();

  // Add this new variable to hold the vehicle status
  String? _vehicleStatus;

  @override
  void initState() {
    super.initState();
    _loadCountryOptions(); // Load country options on initialization
    _loadYearOptions();
    _loadBrandsForYear();
    _loadModelsForBrand();
    _loadVariantsForModel();
    _checkUserRole();

    final formData = Provider.of<FormDataProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // If editing an existing vehicle
      if (widget.vehicle != null && !widget.isDuplicating) {
        _vehicleId = widget.vehicle!.id;
        _populateExistingVehicleData();
      }
      // If duplicating, clear the ID but keep the data
      else if (widget.isDuplicating) {
        _vehicleId = null;
        _populateExistingVehicleData();
      }
      // If new upload
      else if (widget.isNewUpload) {
        _clearAllData(formData);
      }

      _initializeTextControllers(formData);
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
    // Get current user's role from your auth system
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        isDealer = userData.data()?['role'] == 'dealer';
      });
    }
  }

  // New method to load country options from JSON
  Future<void> _loadCountryOptions() async {
    final String response =
        await rootBundle.loadString('lib/assets/country-by-name.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      _countryOptions =
          data.map((country) => country['country'] as String).toList();
    });

    final formData = Provider.of<FormDataProvider>(context, listen: false);

    // Set "South Africa" as the default country if not already set
    if (formData.country == null && _countryOptions.contains('South Africa')) {
      formData.setCountry('South Africa');
    }
  }

  void _clearAllData(FormDataProvider formData) {
    formData.clearAllData();
    formData.setSelectedMainImage(null);
    formData.setMainImageUrl(null);
    formData.setNatisRc1Url(null);

    formData.setYear(null);
    formData.setMakeModel(null);
    formData.setVinNumber(null);
    formData.setVariant(null);
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

      // Update the form data provider instead
      final formData = Provider.of<FormDataProvider>(context, listen: false);
      formData.setSelectedMainImage(null);
      formData.setMainImageUrl(null);
    });

    _vehicleId = null;
    _isLoading = false;
    _currentStep = 0;
  }

  void _initializeTextControllers(FormDataProvider formData) {
    _vinNumberController.text = formData.vinNumber ?? '';
    _mileageController.text = formData.mileage ?? '';
    _engineNumberController.text = formData.engineNumber ?? '';
    _registrationNumberController.text = formData.registrationNumber ?? '';
    _sellingPriceController.text = formData.sellingPrice ?? '';
    _warrantyDetailsController.text = formData.warrantyDetails ?? '';
    _referenceNumberController.text = formData.referenceNumber ?? '';
    _brandsController.text =
        (formData.brands != null && formData.brands!.isNotEmpty)
            ? formData.brands![0]
            : '';
    _countryController.text = formData.country ?? 'South Africa';
    _modelController.text = formData.makeModel ?? '';
    _variantController.text = formData.variant ?? '';
  }

  void _addControllerListeners(FormDataProvider formData) {
    // VIN Number controller
    _vinNumberController.addListener(() {
      formData.setVinNumber(_vinNumberController.text);
      formData.saveFormState();
    });

    // Mileage controller
    _mileageController.addListener(() {
      formData.setMileage(_mileageController.text);
      formData.saveFormState();
    });

    // Engine Number controller
    _engineNumberController.addListener(() {
      formData.setEngineNumber(_engineNumberController.text);
      formData.saveFormState();
    });

    // Registration Number controller
    _registrationNumberController.addListener(() {
      formData.setRegistrationNumber(_registrationNumberController.text);
      formData.saveFormState();
    });

    // Selling Price controller
    _sellingPriceController.addListener(() {
      formData.setSellingPrice(_sellingPriceController.text);
      formData.saveFormState();
    });

    // Warranty Details controller
    _warrantyDetailsController.addListener(() {
      formData.setWarrantyDetails(_warrantyDetailsController.text);
      formData.saveFormState();
    });

    // Reference Number controller
    _referenceNumberController.addListener(() {
      final value = _referenceNumberController.text;
      formData.setReferenceNumber(value);
      formData.saveFormState();
      // Ensure the controller text matches the new value
      if (_referenceNumberController.text != value) {
        setState(() {
          _referenceNumberController.text = value;
        });
      }
    });

    // Model controller
    _modelController.addListener(() {
      formData.setMakeModel(_modelController.text.trim());
      formData.saveFormState();
    });

// Variant controller
    _variantController.addListener(() {
      formData.setVariant(_variantController.text.trim());
      formData.saveFormState();
    });

// Brands controller
    _brandsController.addListener(() {
      if (_brandsController.text.isNotEmpty) {
        formData.setBrands([_brandsController.text.trim()]);
        formData.saveFormState();
      }
    });

    // Config controller
    _configController.addListener(() {
      formData.setConfig(_configController.text);
      formData.saveFormState();
    });

    // Application controller
    _applicationController.addListener(() {
      formData.setApplication(_applicationController.text);
      formData.saveFormState();
    });
  }

  void _populateExistingVehicleData() {
    final formData = Provider.of<FormDataProvider>(context, listen: false);

    print('DEBUG: Starting _populateExistingVehicleData');
    print(
        'DEBUG: Vehicle brands data type: ${widget.vehicle?.brands.runtimeType}');
    print('DEBUG: Vehicle brands content: ${widget.vehicle?.brands}');

    // Populate main image
    if (widget.vehicle?.mainImageUrl != null) {
      formData.setMainImageUrl(widget.vehicle!.mainImageUrl);
      print('DEBUG: Main image URL set: ${widget.vehicle!.mainImageUrl}');
    }

    // Populate NATIS/RC1 file
    setState(() {
      _existingNatisRc1Url = widget.vehicle?.rc1NatisFile;
      _existingNatisRc1Name = _getFileNameFromUrl(_existingNatisRc1Url);
      print('DEBUG: NATIS/RC1 file set: $_existingNatisRc1Url');
    });

    _initialVehicleStatus = widget.vehicle?.vehicleStatus ?? 'Draft';
    _vehicleStatus = _initialVehicleStatus;

    // Populate form fields with debug logging
    _modelController.text = widget.vehicle?.makeModel ?? '';
    _variantController.text = widget.vehicle?.variant ?? '';

    _vinNumberController.text = widget.vehicle?.vinNumber ?? '';
    _mileageController.text = widget.vehicle?.mileage ?? '';
    _engineNumberController.text = widget.vehicle?.engineNumber ?? '';
    _registrationNumberController.text =
        widget.vehicle?.registrationNumber ?? '';
    _sellingPriceController.text =
        widget.vehicle?.adminData.settlementAmount ?? '';
    _warrantyDetailsController.text = widget.vehicle?.warrantyDetails ?? '';
    _referenceNumberController.text = widget.vehicle?.referenceNumber ?? '';

    // Handle brands with type checking and debugging
    print('DEBUG: Processing brands data');
    if (widget.vehicle?.brands != null) {
      print('DEBUG: Brands type: ${widget.vehicle!.brands.runtimeType}');
      print('DEBUG: Raw brands data: ${widget.vehicle!.brands}');

      if (widget.vehicle!.brands.isNotEmpty) {
        _brandsController.text = widget.vehicle!.brands[0].toString();
        formData.setBrands(List<String>.from(widget.vehicle!.brands));
        print('DEBUG: Set brands from List: ${_brandsController.text}');
      }
      // Update the brands population
      // if (widget.vehicle?.brands != null && widget.vehicle!.brands.isNotEmpty) {
      //   formData.setBrands(List<String>.from(widget.vehicle!.brands));
      // }
    }

    // Update form provider
    print('DEBUG: Updating FormDataProvider');
    print('DEBUG: Starting data population');
    print('DEBUG: Year: ${widget.vehicle?.year}');
    print('DEBUG: Brands: ${widget.vehicle?.brands}');
    print('DEBUG: Model: ${widget.vehicle?.makeModel}');
    print('DEBUG: Variant: ${widget.vehicle?.variant}');
    formData.setYear(widget.vehicle?.year);
    _yearOptions = []; // Clear and reload year options
    _loadYearOptions().then((_) {
      // After years loaded, handle brands
      _loadBrandsForYear().then((_) {
        if (widget.vehicle?.brands != null &&
            widget.vehicle!.brands.isNotEmpty) {
          formData.setBrands(widget.vehicle!.brands);

          // After brands loaded, handle models
          _loadModelsForBrand().then((_) {
            formData.setMakeModel(widget.vehicle?.makeModel);

            // After models loaded, handle variants
            _loadVariantsForModel().then((_) {
              formData.setVariant(widget.vehicle?.variant);
            });
          });
        }
      });
    });
    formData.setMakeModel(widget.vehicle?.makeModel);
    formData.setVariant(widget.vehicle?.variant);
    formData.setVinNumber(widget.vehicle?.vinNumber);
    formData.setConfig(widget.vehicle?.config);
    formData.setMileage(widget.vehicle?.mileage);
    formData.setApplication(widget.vehicle?.application.isNotEmpty == true
        ? widget.vehicle?.application[0]
        : null);
    formData.setEngineNumber(widget.vehicle?.engineNumber);
    formData.setRegistrationNumber(widget.vehicle?.registrationNumber);
    formData.setSellingPrice(widget.vehicle?.adminData.settlementAmount);
    formData.setVehicleType(widget.vehicle?.vehicleType ?? 'truck');
    formData.setSuspension(widget.vehicle?.suspensionType ?? 'spring');
    formData
        .setTransmissionType(widget.vehicle?.transmissionType ?? 'automatic');
    formData.setHydraulics(widget.vehicle?.hydraluicType ?? 'no');

    formData
        .setMaintenance(widget.vehicle?.maintenance.oemInspectionType ?? 'no');

    formData.setWarranty(widget.vehicle?.warrentyType ?? 'no');
    formData.setWarrantyDetails(widget.vehicle?.warrantyDetails);
    formData
        .setRequireToSettleType(widget.vehicle?.requireToSettleType ?? 'no');
    formData.setReferenceNumber(widget.vehicle?.referenceNumber);
    formData.setCountry(widget.vehicle?.country ?? 'South Africa');
    // Set year and trigger brand loading
    formData.setYear(widget.vehicle?.year);
    _loadBrandsForYear();

    // Set brand and trigger model loading
    if (widget.vehicle?.brands != null && widget.vehicle!.brands.isNotEmpty) {
      formData.setBrands(widget.vehicle!.brands);
      _loadModelsForBrand();
    }

    // Set model and trigger variant loading
    formData.setMakeModel(widget.vehicle?.makeModel);
    _loadVariantsForModel();

    // Set variant
    formData.setVariant(widget.vehicle?.variant);

    print('DEBUG: Completed _populateExistingVehicleData');
  }

  // Helper to extract filename from URL
  String? _getFileNameFromUrl(String? url) {
    if (url == null) return null;
    return url.split('/').last.split('?').first;
  }

  // Function to pick RC1/NATIS file
  Future<void> _pickNatisRc1File() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _natisRc1File = File(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
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

  // Helper function to check if file is an image
  bool _isImageFile(String path) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    String extension = path.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }

  // Helper method to display uploaded files
  Widget _buildUploadedFile(File? file, bool isUploading) {
    if (file == null) {
      return const Text(
        'No file selected',
        style: TextStyle(color: Colors.white70),
      );
    } else {
      String fileName = file.path.split('/').last;
      String extension = fileName.split('.').last;
      return Column(
        children: [
          if (_isImageFile(file.path))
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.file(
                file,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            )
          else
            Column(
              children: [
                Icon(
                  _getFileIcon(extension),
                  color: Colors.white,
                  size: 50.0,
                ),
                const SizedBox(height: 8),
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          const SizedBox(height: 8),
          if (isUploading)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(width: 10),
                Text(
                  'Uploading...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formData = Provider.of<FormDataProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        if (widget.isNewUpload) {
          final formData =
              Provider.of<FormDataProvider>(context, listen: false);
          _clearAllData(formData);
        }
        return true;
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_left),
                color: Colors.white,
                iconSize: 40,
              ),
              backgroundColor: Color(0xFF0E4CAF),
              elevation: 0.0,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              centerTitle: true,
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
    final bool isAdmin = userRole == 'admin'; // Check if the user is an admin
    final bool isDealer = userRole == 'dealer'; // Check if the user is a dealer
    final bool isTransporter =
        userRole == 'transporter'; // Check if the user is a dealer
    final formData = Provider.of<FormDataProvider>(context);

    // Function to show image picker dialog
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

    // Function to handle image tap
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
                      formData.setSelectedMainImage(null);
                      formData.setMainImageUrl(null);
                    });
                  },
                  child: const Text(
                    'Remove Image',
                    style: TextStyle(color: Colors.red),
                  ),
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
                child: Image.file(
                  formData.selectedMainImage!,
                  width: double.infinity,
                  height: _imageHeight,
                  fit: BoxFit.cover,
                ),
              )
            else if (formData.mainImageUrl != null &&
                formData.mainImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(
                  formData.mainImageUrl!,
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
                  },
                ),
              )
            else
              ImagePickerWidget(
                onImagePicked: (File? image) {
                  if (image != null) {
                    formData.setSelectedMainImage(image);
                  }
                },
              ),
            // Add an overlay hint

            if (isTransporter)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Tap to modify image',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
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
    final bool isAdmin = userRole == 'admin'; // Check if the user is an admin
    final bool isDealer = userRole == 'dealer'; // Check if the user is a dealer
    final bool isTransporter =
        userRole == 'transporter'; // Check if the user is a dealer
    final formData = Provider.of<FormDataProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Text(
              'truck form'.toUpperCase(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          if (isTransporter)
            Center(
              child: Text(
                'Please fill out the required details below.',
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          Center(
            child: Text(
              'Your trusted partner on the road.',
              style: const TextStyle(fontSize: 14, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          // Vehicle Status Dropdown
          if (isTransporter)
            CustomDropdown(
              hintText: 'Vehicle Status',
              value: _vehicleStatus ?? _initialVehicleStatus ?? 'Draft',
              items: const ['Draft', 'Live'],
              onChanged: (value) {
                setState(() {
                  _vehicleStatus = value;
                  formData.setVehicleStatus(value);
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select the vehicle status';
                }
                return null;
              },
              isTransporter: isTransporter,
            ),

          const SizedBox(height: 15),
          // Reference Number field
          if (isTransporter) _buildReferenceNumberField(),
          const SizedBox(height: 15),
          // RC1/NATIS File Upload Section
          if (isTransporter) _buildNatisRc1Section(),
          const SizedBox(height: 15),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     CustomRadioButton(
          //       label: 'Truck',
          //       value: 'truck',
          //       groupValue: formData.vehicleType,
          //       enabled: !isDealer,
          //       onChanged: (value) {
          //         formData.setVehicleType(value);
          //         formData.saveFormState();
          //       },
          //     ),
          //     const SizedBox(width: 15),
          //     CustomRadioButton(
          //       label: 'Trailer',
          //       value: 'trailer',
          //       groupValue: formData.vehicleType,
          //       enabled: !isDealer,
          //       onChanged: (value) {
          //         formData.setVehicleType(value);
          //         formData.saveFormState();
          //       },
          //     ),
          //   ],
          // ),
          const SizedBox(height: 15),
          Form(
            key: _formKeys[0],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDealer)
                  Text(
                    'Year',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.start,
                  ),
                if (isDealer) const SizedBox(height: 15),
                // Year and Make/Model
                // CustomDropdown(
                //   hintText: 'Year',
                //   enabled: !isDealer,
                //   value: formData.year,
                //   items: _yearOptions,
                //   onChanged: (value) {
                //     formData.setYear(value);
                //     _loadBrandsForYear();
                //     formData.saveFormState();
                //   },
                //   isTransporter: isTransporter,
                // ),

                CustomDropdown(
                  hintText: 'Year',
                  enabled: !isDealer,
                  value: formData.year,
                  items:
                      List.generate(24, (index) => (2024 - index).toString()),
                  onChanged: (value) {
                    formData.setYear(value);
                    formData.saveFormState();
                  },
                  isTransporter: isTransporter,
                ),
                const SizedBox(height: 15),

// Manufacturer field
                if (isDealer)
                  Text(
                    'Manufacturer',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.start,
                  ),
                if (isDealer) const SizedBox(height: 15),
                CustomDropdown(
                  hintText: 'Manufacturer',
                  value: formData.brands?.isNotEmpty == true
                      ? formData.brands![0]
                      : null,
                  items: _brandOptions,
                  onChanged: (value) {
                    if (value != null) {
                      formData.setBrands([value]);
                      _brandsController.text = value;
                      formData.saveFormState();
                    }
                  },
                  enabled: !isDealer,
                ),

                // CustomDropdown(
                //   hintText: 'Brand',
                //   enabled: !isDealer,
                //   value: formData.brands?.isNotEmpty == true
                //       ? formData.brands![0]
                //       : null,
                //   items: [
                //     'Ashok Leyland',
                //     'Dayun',
                //     'Eicher',
                //     'FAW',
                //     'Fiat',
                //     'Ford',
                //     'Foton',
                //     'Fuso',
                //     'Hino',
                //     'Hyundai',
                //     'Isuzu',
                //     'Iveco',
                //     'JAC',
                //     'Joylong',
                //     'MAN',
                //     'Mercedes-Benz',
                //     'Peugeot',
                //     'Powerstar',
                //     'Renault',
                //     'Scania',
                //     'Tata',
                //     'Toyota',
                //     'UD Trucks',
                //     'US Truck',
                //     'Volkswagen',
                //     'Volvo',
                //     'CNHTC',
                //     'DAF',
                //     'Freightliner',
                //     'Mack',
                //     'Powerland'
                //   ],
                //   onChanged: (value) {
                //     if (value != null) {
                //       formData.setBrands([value]);
                //       formData.saveFormState();
                //     }
                //   },
                //   isTransporter: isTransporter,
                // ),

                const SizedBox(height: 15),

                if (isDealer)
                  Text(
                    'Model',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.start,
                  ),
                if (isDealer) const SizedBox(height: 15),
                // CustomDropdown(
                //   hintText: 'Make/Model',
                //   enabled: !isDealer,
                //   value: formData.makeModel,
                //   items: _makeModelOptions[formData.brands?.isNotEmpty == true
                //           ? formData.brands![0]
                //           : ''] ??
                //       [],
                //   onChanged: (value) {
                //     formData.setMakeModel(value);
                //     _loadVariantsForModel();
                //     formData.saveFormState();
                //   },
                //   isTransporter: isTransporter,
                // ),
                CustomTextField(
                  controller: _modelController,
                  enabled: !isDealer,
                  hintText: 'Model',
                  inputFormatter: [UpperCaseTextFormatter()],
                  onChanged: (value) {
                    formData.setMakeModel(value);
                    formData.saveFormState();
                  },
                ),
                const SizedBox(height: 15),

// Add the missing Variant dropdown
                if (isDealer)
                  Text(
                    'Variant',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.start,
                  ),
                if (isDealer) const SizedBox(height: 15),
                // CustomDropdown(
                //   hintText: 'Variant',
                //   value: formData.variant,
                //   enabled: !isDealer,
                //   items: _variantOptions,
                //   onChanged: (value) {
                //     formData.setVariant(value);
                //     formData.saveFormState();
                //   },
                //   isTransporter: isTransporter,
                // ),
                CustomTextField(
                  controller: _variantController,
                  enabled: !isDealer,
                  hintText: 'Variant',
                  inputFormatter: [UpperCaseTextFormatter()],
                  onChanged: (value) {
                    formData.setVariant(value);
                    formData.saveFormState();
                  },
                ),

                const SizedBox(height: 15),
                // Country Dropdown
                if (isDealer)
                  Text(
                    'Country',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.start,
                  ),
                if (isDealer) const SizedBox(height: 15),
                CustomDropdown(
                  hintText: 'Select Country',
                  enabled: !isDealer,
                  value: formData.country?.isNotEmpty == true
                      ? formData.country
                      : null,
                  items: _countryOptions,
                  onChanged: (value) {
                    formData.setCountry(value);
                  },
                  isTransporter: isTransporter,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a country';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                // Mileage
                if (isDealer)
                  Text(
                    'Mileage',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.start,
                  ),
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
                  Text(
                    'Configuration',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.start,
                  ),
                if (isDealer) const SizedBox(height: 15),
                CustomDropdown(
                  hintText: 'Configuration',
                  enabled: !isDealer,
                  value: formData.config?.isNotEmpty == true
                      ? formData.config
                      : null,
                  items: _configurationOptions,
                  onChanged: (value) {
                    formData.setConfig(value);
                    formData.saveFormState();
                  },
                  isTransporter: isTransporter,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select the configuration';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                // Application of Use
                if (isDealer)
                  Text(
                    'Application of Use',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.start,
                  ),
                if (isDealer) const SizedBox(height: 15),
                CustomDropdown(
                  hintText: 'Application of Use',
                  enabled: !isDealer,
                  value: formData.application?.isNotEmpty == true
                      ? formData.application
                      : null,
                  items: _applicationOptions,
                  onChanged: (value) {
                    formData.setApplication(value);
                    formData.saveFormState();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select the application of use';
                    }
                    return null;
                  },
                  isTransporter: isTransporter,
                ),
                const SizedBox(height: 15),
                // VIN Number
                if (isTransporter)
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
                if (isTransporter) const SizedBox(height: 15),
                // Engine Number

                if (isTransporter)
                  CustomTextField(
                    controller: _engineNumberController,
                    enabled: !isDealer,
                    hintText: 'Engine No.',
                    inputFormatter: [UpperCaseTextFormatter()],
                  ),
                if (isTransporter) const SizedBox(height: 15),
                // Registration Number
                if (isTransporter)
                  CustomTextField(
                    controller: _registrationNumberController,
                    enabled: !isDealer,
                    hintText: 'Registration No.',
                    inputFormatter: [UpperCaseTextFormatter()],
                  ),
                if (isTransporter) const SizedBox(height: 15),
                // Selling Price
                if (isTransporter)
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
                  child: Text(
                    'Suspension',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
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
                        formData.setSuspension(value);
                        formData.saveFormState();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Divider(),
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    'Transmission',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
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
                        formData.setTransmissionType(value);
                        formData.saveFormState();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Divider(),
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    'Hydraulics',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
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
                        formData.setHydraulics(value);
                        formData.saveFormState();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Divider(),
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    'Maintenance',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomRadioButton(
                      label: 'Yes',
                      value: 'yes',
                      groupValue: formData.maintenance,
                      enabled: !isDealer,
                      onChanged: (value) {
                        formData.setMaintenance(value);
                        formData.saveFormState();
                      },
                    ),
                    const SizedBox(width: 15),
                    CustomRadioButton(
                      label: 'No',
                      value: 'no',
                      groupValue: formData.maintenance,
                      enabled: !isDealer,
                      onChanged: (value) {
                        formData.setMaintenance(value);
                        formData.saveFormState();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Divider(),
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    'Warranty',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
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
                Divider(),
                const SizedBox(height: 15),

                if (isTransporter)
                  Center(
                    child: Text(
                      'Do you require the truck to be settled before selling'
                          .toUpperCase(),
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (isDealer)
                  Center(
                    child: Text(
                      'Settlement Needed',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
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
          if (isTransporter) _buildNextButton(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Future<String?> _saveSection1Data() async {
    try {
      final formData = Provider.of<FormDataProvider>(context, listen: false);

      String? imageUrl = formData.mainImageUrl;
      String? natisRc1Url = _existingNatisRc1Url;

      // Upload new main image if selected
      if (formData.selectedMainImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('vehicle_images')
            .child('${DateTime.now().toIso8601String()}.jpg');
        await ref.putFile(formData.selectedMainImage!);
        imageUrl = await ref.getDownloadURL();
      }

      // Upload new NATIS/RC1 file if selected
      if (_natisRc1File != null) {
        final ref = FirebaseStorage.instance.ref().child('vehicle_documents').child(
            '${DateTime.now().millisecondsSinceEpoch}_${_natisRc1File!.path.split('/').last}');
        await ref.putFile(_natisRc1File!);
        natisRc1Url = await ref.getDownloadURL();
      }

      final vehicleData = {
        'year': formData.year,
        'brands': formData.brands ?? [], // Ensure brands is always an array
        'makeModel': formData.makeModel?.trim() ?? '', // Trim whitespace
        'variant': formData.variant?.trim() ?? '', // Trim whitespace

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
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'vehicleStatus': _vehicleStatus ?? _initialVehicleStatus ?? 'Draft',
      };

      // Update existing document or create new one
      if (_vehicleId != null && !widget.isDuplicating) {
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

        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Vehicle updated successfully')),
        // );
      } else {
        // Create new document for duplicating or new vehicle
        final docRef =
            await FirebaseFirestore.instance.collection('vehicles').add({
          ...vehicleData,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': FirebaseAuth.instance.currentUser?.uid,
          'vehicleStatus': _vehicleStatus ?? 'Draft',
        });
        _vehicleId = docRef.id;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle created successfully')),
        );
      }

      return _vehicleId;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving vehicle: $e')),
      );
      return null;
    }
  }

  bool _validateRequiredFields(FormDataProvider formData) {
    if (formData.selectedMainImage == null &&
        (formData.mainImageUrl == null || formData.mainImageUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a main image')),
      );
      return false;
    }

    if (formData.year == null || formData.year!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the year')),
      );
      return false;
    }

    return true;
  }

  // Update the Next button handler
  Widget _buildNextButton() {
    return Center(
      child: CustomButton(
        text: 'Save',
        borderColor: AppColors.blue,
        onPressed: () async {
          final formData =
              Provider.of<FormDataProvider>(context, listen: false);

          if (!_validateRequiredFields(formData)) {
            return;
          }

          setState(() => _isLoading = true);

          try {
            String? vehicleId = await _saveSection1Data();
            if (vehicleId != null) {
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Changes saved successfully'),
                  duration: Duration(seconds: 2),
                ),
              );

              // Navigate back to previous screen
              Navigator.pop(context);
            }
          } finally {
            setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

  // Add this method to clear form controllers
  void _clearFormControllers() {
    _sellingPriceController.clear();
    _vinNumberController.clear();
    _mileageController.clear();
    _engineNumberController.clear();
    _warrantyDetailsController.clear();
    _registrationNumberController.clear();
    _referenceNumberController.clear();
    _brandsController.clear();
    _countryController.clear();

    // Clear image-related data
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    formData.setSelectedMainImage(null);
    formData.setMainImageUrl(null);

    setState(() {
      _natisRc1File = null;
      _existingNatisRc1Url = null;
      _existingNatisRc1Name = null;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      formData.setSelectedMainImage(File(image.path));
    }
  }

  // Add this new method to load saved form data
  Future<void> _loadSavedFormData(FormDataProvider formData) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(_vehicleId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        setState(() {
          _mileageController.text = data['mileage'] ?? '';
          _vinNumberController.text = data['vinNumber'] ?? '';
          _engineNumberController.text = data['engineNumber'] ?? '';
          _registrationNumberController.text = data['registrationNumber'] ?? '';
          _sellingPriceController.text = data['sellingPrice'] ?? '';
          _warrantyDetailsController.text = data['warrantyDetails'] ?? '';
          _referenceNumberController.text = data['referenceNumber'] ?? '';

          // Updated brands handling
          if (data['brands'] != null) {
            if (data['brands'] is List) {
              _brandsController.text =
                  (data['brands'] as List).firstOrNull?.toString() ?? '';
            } else if (data['brands'] is String) {
              _brandsController.text = data['brands'];
            }
          }

          _countryController.text = data['country'] ?? 'South Africa';

          // Update FormDataProvider
          formData.setYear(data['year']);
          formData.setMakeModel(data['makeModel']);
          formData.setVinNumber(data['vinNumber']);
          formData.setConfig(data['config']);
          formData.setMileage(data['mileage']);
          formData.setApplication(data['application']);
          formData.setEngineNumber(data['engineNumber']);
          formData.setRegistrationNumber(data['registrationNumber']);
          formData.setSellingPrice(data['sellingPrice']);
          formData.setVehicleType(data['vehicleType'] ?? 'truck');
          formData.setSuspension(data['suspensionType'] ?? 'spring');
          formData.setTransmissionType(data['transmissionType'] ?? 'automatic');
          formData.setHydraulics(data['hydraulics'] ?? 'yes');
          formData.setMaintenance(data['maintenance'] ?? 'yes');
          formData.setWarranty(data['warranty'] ?? 'yes');
          formData.setWarrantyDetails(data['warrantyDetails']);
          formData.setRequireToSettleType(data['requireToSettleType'] ?? 'yes');
          formData.setMainImageUrl(data['mainImageUrl']);
          formData.setReferenceNumber(data['referenceNumber']);

          // Updated brands setting in FormDataProvider
          if (data['brands'] != null) {
            if (data['brands'] is List) {
              formData.setBrands(List<String>.from(data['brands']));
            } else if (data['brands'] is String) {
              formData.setBrands([data['brands']]);
            }
          }

          formData.setCountry(data['country'] ?? 'South Africa');
        });
      }
    } catch (e) {
      print('Error loading saved form data: $e');
    }
  }

  Widget _buildNatisRc1Section() {
    Widget buildFileDisplay(String? fileName, bool isExisting) {
      String extension = fileName?.split('.').last.toLowerCase() ?? '';
      IconData iconData = _getFileIcon(extension);

      return Column(
        children: [
          Icon(
            iconData,
            color: Colors.white,
            size: 50.0,
          ),
          const SizedBox(height: 10),
          Text(
            fileName ?? (isExisting ? 'Existing Document' : 'Select Document'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return Column(
      children: [
        Center(
          child: Text(
            'NATIS/RC1 Documentation'.toUpperCase(),
            style: const TextStyle(
                fontSize: 15, color: Colors.white, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
        ),
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
              border: Border.all(
                color: const Color(0xFF0E4CAF),
                width: 2.0,
              ),
            ),
            child: _natisRc1File != null
                ? buildFileDisplay(_natisRc1File!.path.split('/').last, false)
                : _existingNatisRc1Url != null
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
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _viewDocument() async {
    final url = _natisRc1File != null ? null : _existingNatisRc1Url;
    if (url != null) {
      try {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open document')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening document: $e')),
          );
        }
      }
    }
  }

  void _removeDocument() {
    setState(() {
      _natisRc1File = null;
      _existingNatisRc1Url = null;
      _existingNatisRc1Name = null;
    });
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
          },
        );
      },
    );
  }
}

// UpperCaseTextFormatter remains the same
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Only keep digits
    final String cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Format with thousand separators
    final String formatted = NumberFormat('####').format(int.parse(cleanText));

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
