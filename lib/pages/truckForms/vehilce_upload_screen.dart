import 'dart:io';
import 'dart:convert'; // For JSON decoding
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/services.dart'; // For loading assets
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/truckForms/custom_dropdown.dart';
import 'package:ctp/pages/truckForms/maintenance_warrenty_screen.dart';
import 'package:ctp/providers/form_data_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart'; // For file picking
import 'custom_text_field.dart';
import 'custom_radio_button.dart';
import 'image_picker_widget.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class VehicleUploadScreen extends StatefulWidget {
  final bool isDuplicating;
  final Vehicle? vehicle;
  final bool isNewUpload;
  final bool isAdminUpload;
  // transporterId removed because admins now select Sales Rep from a dropdown.
  const VehicleUploadScreen({
    super.key,
    this.vehicle,
    this.isAdminUpload = false,
    this.isDuplicating = false,
    this.isNewUpload = false,
  });

  @override
  _VehicleUploadScreenState createState() => _VehicleUploadScreenState();
}

class _VehicleUploadScreenState extends State<VehicleUploadScreen> {
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
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(1, (index) => GlobalKey<FormState>());
  bool _isLoading = false;
  String? _vehicleId;
  DateTime? _availableDate;

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
  ];

  // Define configuration options
  final List<String> _configurationOptions = [
    '6X4',
    '6X2',
    '4X2',
    '8X4',
  ];

  late Map<String, List<String>> _makeModelOptions = {};
  List<String> _brandOptions = [];
  List<String> _variantOptions = [];
  final Map<String, List<String>> _modelVariants = {};

  // Variable to hold selected RC1/NATIS file
  // --- FIX APPLIED: Store file bytes and file name separately
  Uint8List? _natisRc1File;
  String? _natisRc1FileName;

  // --- Added Missing Fields ---
  String? _existingNatisRc1Url;
  String? _existingNatisRc1Name;

  // For multi-step forms
  int _currentStep = 0;

  // Additional controllers
  final TextEditingController _configController = TextEditingController();
  final TextEditingController _applicationController = TextEditingController();
  final TextEditingController _countryController =
      TextEditingController(); // For country selection

  List<String> _countryOptions = []; // Country options list
  List<String> _provinceOptions = [];
  List<String> _yearOptions = [];

  // --- New: Variables for Admin Sales Rep selection ---
  // Instead of a dummy list, we'll fetch from UserProvider's dealers.
  String? _selectedSalesRep;

  Uint8List? _selectedMainImage;
  String? _selectedMainImageFileName;

  Future<void> _loadYearOptions() async {
    final String response =
        await rootBundle.loadString('lib/assets/updated_truck_data.json');
    final data = json.decode(response);
    setState(() {
      _yearOptions = (data as Map<String, dynamic>).keys.toList()..sort();
    });
  }

  Future<void> _loadBrandsForYear(String year) async {
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    final String response =
        await rootBundle.loadString('lib/assets/updated_truck_data.json');
    final data = json.decode(response);
    setState(() {
      _brandOptions = data[year]?.keys.toList() ?? [];
      if (!widget.isDuplicating) {
        formData.setBrands(null);
        formData.setMakeModel(null);
        formData.setVariant(null);
      }
    });
  }

  Future<void> _loadModelsForBrand(String brand) async {
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    final year = formData.year;
    if (year == null) return;
    final String response =
        await rootBundle.loadString('lib/assets/updated_truck_data.json');
    final data = json.decode(response);
    setState(() {
      if (data[year] != null && data[year][brand] != null) {
        final models = data[year][brand] as List<dynamic>;
        _makeModelOptions = {brand: models.cast<String>()};
        if (!widget.isDuplicating) {
          formData.setMakeModel(null);
        }
      }
    });
  }

  Future<void> _loadVariantsForModel(String model) async {
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    final year = formData.year;
    final brand = formData.brands?.first;
    final String response =
        await rootBundle.loadString('lib/assets/updated_truck_data.json');
    final data = json.decode(response);
    setState(() {
      _variantOptions = List<String>.from(data[year][brand][model]);
      formData.setVariant(null);
    });
  }

  void _updateProvinceOptions(String selectedCountry) async {
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
      debugPrint("Provinces loaded: $_provinceOptions");
    });
  }

  Future<bool> _isVinNumberUnique(String vinNumber) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('vehicles')
        .where('vinNumber', isEqualTo: vinNumber)
        .get();
    return querySnapshot.docs.isEmpty;
  }

  @override
  void initState() {
    super.initState();
    _loadCountryOptions(); // Load country options on init
    _updateProvinceOptions('South Africa');
    _loadTruckData();
    _loadYearOptions();

    final formData = Provider.of<FormDataProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isNewUpload) {
        _clearAllData(formData);
      } else if (widget.vehicle != null) {
        if (widget.isDuplicating) {
          _populateDuplicatedData(formData);
        } else {
          _vehicleId = widget.vehicle!.id;
          _populateVehicleData();
        }
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

  Future<void> _loadTruckData() async {
    final String response =
        await rootBundle.loadString('lib/assets/updated_truck_data.json');
    final data = json.decode(response) as Map<String, dynamic>;
    setState(() {
      // Fix: Properly handle the nested structure
      _makeModelOptions = {};
      for (var year in data.keys) {
        for (var brand in (data[year] as Map<String, dynamic>).keys) {
          if (!_makeModelOptions.containsKey(brand)) {
            _makeModelOptions[brand] = [];
          }
          final models = data[year][brand];
          if (models is List) {
            _makeModelOptions[brand]!.addAll(models.map((m) => m.toString()));
          }
        }
      }
    });
  }

  Future<void> _loadCountryOptions() async {
    final String response =
        await rootBundle.loadString('lib/assets/country-by-name.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      _countryOptions =
          data.map((country) => country['country'] as String).toList();
    });
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    if (formData.country == null && _countryOptions.contains('South Africa')) {
      formData.setCountry('South Africa');
    }
  }

  void _clearAllData(FormDataProvider formData) {
    formData.clearAllData();
    formData.setSelectedMainImage(null, null);
    formData.setMainImageUrl(null);
    formData.setNatisRc1Url(null);
    formData.setYear(null);
    formData.setMakeModel(null);
    formData.setVinNumber(null);
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
      final formData = Provider.of<FormDataProvider>(context, listen: false);
      formData.setSelectedMainImage(null, null);
      formData.setMainImageUrl(null);
    });
    _vehicleId = null;
    _isLoading = false;
    _currentStep = 0;
  }

  void _initializeDefaultValues(FormDataProvider formData) {
    formData.setVehicleType('truck');
    formData.setSuspension('spring');
    formData.setTransmissionType('automatic');
    formData.setHydraulics('no');
    formData.setMaintenance('no');
    formData.setWarranty('no');
    formData.setRequireToSettleType('no');
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
        (formData.brands)?.isNotEmpty == true ? formData.brands!.first : '';
    _countryController.text = formData.country ?? 'South Africa';
  }

  void _addControllerListeners(FormDataProvider formData) {
    _vinNumberController.addListener(() {
      formData.setVinNumber(_vinNumberController.text);
    });
    _mileageController.addListener(() {
      formData.setMileage(_mileageController.text);
    });
    _engineNumberController.addListener(() {
      formData.setEngineNumber(_engineNumberController.text);
    });
    _registrationNumberController.addListener(() {
      formData.setRegistrationNumber(_registrationNumberController.text);
    });
    _sellingPriceController.addListener(() {
      formData.setSellingPrice(_sellingPriceController.text);
    });
    _warrantyDetailsController.addListener(() {
      formData.setWarrantyDetails(_warrantyDetailsController.text);
    });
    _referenceNumberController.addListener(() {
      formData.setReferenceNumber(_referenceNumberController.text);
    });
    _brandsController.addListener(() {
      formData.setBrands([_brandsController.text]);
    });
  }

  void _populateVehicleData() {
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    _existingNatisRc1Url = widget.vehicle!.rc1NatisFile;
    _existingNatisRc1Name = _getFileNameFromUrl(_existingNatisRc1Url);
    formData.setNatisRc1Url(widget.vehicle!.rc1NatisFile, notify: false);
    formData.setVehicleType(widget.vehicle!.vehicleType, notify: false);
    formData.setYear(widget.vehicle!.year, notify: false);
    formData.setMakeModel(widget.vehicle!.makeModel, notify: false);
    formData.setVinNumber(widget.vehicle!.vinNumber, notify: false);
    formData.setMileage(widget.vehicle!.mileage, notify: false);
    formData.setEngineNumber(widget.vehicle!.engineNumber, notify: false);
    formData.setRegistrationNumber(widget.vehicle!.registrationNumber,
        notify: false);
    formData.setSellingPrice(widget.vehicle!.adminData.settlementAmount,
        notify: false);
    formData.setMainImageUrl(widget.vehicle!.mainImageUrl, notify: false);
    formData.setApplication(widget.vehicle!.application as String,
        notify: false);
    formData.setConfig(widget.vehicle!.config, notify: false);
    formData.setSuspension(widget.vehicle!.suspensionType, notify: false);
    formData.setTransmissionType(widget.vehicle!.transmissionType,
        notify: false);
    formData.setHydraulics(widget.vehicle!.hydraluicType, notify: false);
    formData.setWarranty(widget.vehicle!.warrentyType, notify: false);
    formData.setWarrantyDetails(widget.vehicle!.warrantyDetails, notify: false);
    formData.setReferenceNumber(widget.vehicle!.referenceNumber, notify: false);
    formData.setBrands(widget.vehicle!.brands ?? [], notify: false);
    if (widget.isDuplicating) {
      _vehicleId = null;
    } else {
      _vehicleId = widget.vehicle!.id;
    }
  }

  void _populateDuplicatedData(FormDataProvider formData) {
    if (widget.vehicle != null) {
      debugPrint('=== Populating Duplicated Data ===');
      formData.setYear(widget.vehicle!.year);
      _loadBrandsForYear(widget.vehicle!.year!).then((_) {
        if (widget.vehicle!.brands?.isNotEmpty == true) {
          formData.setBrands(widget.vehicle!.brands);
          _loadModelsForBrand(widget.vehicle!.brands!.first).then((_) {
            formData.setMakeModel(widget.vehicle!.makeModel);
          });
        }
      });
      formData.setConfig(widget.vehicle!.config);
      formData.setCountry(widget.vehicle!.country);
      formData.setHydraulics(widget.vehicle!.hydraluicType);
      formData.setProvince(widget.vehicle!.province);
      formData.setSuspension(widget.vehicle!.suspensionType);
      formData.setTransmissionType(widget.vehicle!.transmissionType);
      if (widget.vehicle!.application is String) {
        formData.setApplication(widget.vehicle!.application as String);
      } else if (widget.vehicle!.application is List) {
        final List appList = widget.vehicle!.application as List;
        formData
            .setApplication(appList.isNotEmpty ? appList.first.toString() : '');
      }
      _updateProvinceOptions(widget.vehicle!.country!);
      debugPrint('=== Duplication Data Population Complete ===');
    }
  }

  String? _getFileNameFromUrl(String? url) {
    if (url == null) return null;
    return url.split('/').last.split('?').first;
  }

  Future<void> _pickNatisRc1File() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
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
        Uint8List? bytes;
        if (result.files.single.bytes != null) {
          bytes = result.files.single.bytes;
        } else if (result.files.single.path != null) {
          final file = File(result.files.single.path!);
          bytes = await file.readAsBytes();
        }
        final fileName = result.files.single.name;
        setState(() {
          _natisRc1File = bytes;
          _natisRc1FileName = fileName;
        });
        debugPrint("Picked NATIS/RC1 file: $_natisRc1FileName");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

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

  bool _isImageFile(String path) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    String extension = path.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }

  // Build the uploaded file widget for NATIS/RC1 preview.
  Widget _buildUploadedFile(
      Uint8List? file, String fileName, bool isUploading) {
    if (file == null) {
      return const Text(
        'No file selected',
        style: TextStyle(color: Colors.white70),
      );
    } else {
      String _fileName = fileName;
      String extension = _fileName.split('.').last;
      return Column(
        children: [
          if (_isImageFile(_fileName))
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.memory(
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
                  _fileName,
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
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

  Future<List<Map<String, String>>> _getSalesReps() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.fetchAdmins();
    return userProvider.dealers.map((dealer) {
      String displayName =
          dealer.tradingName ?? '${dealer.firstName} ${dealer.lastName}'.trim();
      return {'id': dealer.id, 'display': displayName};
    }).toList();
  }

  @override
  void dispose() {
    _sellingPriceController.dispose();
    _vinNumberController.dispose();
    _mileageController.dispose();
    _engineNumberController.dispose();
    _warrantyDetailsController.dispose();
    _registrationNumberController.dispose();
    _referenceNumberController.dispose();
    _brandsController.dispose();
    _modelController.dispose();
    _variantController.dispose();
    _configController.dispose();
    _applicationController.dispose();
    _countryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formData = Provider.of<FormDataProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebView = screenWidth > 600; // Threshold for web view

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
              backgroundColor: const Color(0xFF0E4CAF),
              elevation: 0.0,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              centerTitle: true,
            ),
            body: GradientBackground(
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isWebView ? 800 : double.infinity,
                  ),
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
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWebView ? 40.0 : 16.0,
                          vertical: 8.0,
                        ),
                        child: Column(
                          children: [
                            // Constrain image section for web
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: isWebView ? 600 : double.infinity,
                              ),
                              child: _buildImageSection(),
                            ),
                            // Constrain form section for web
                            Container(
                              constraints: BoxConstraints(
                                maxWidth: isWebView ? 600 : double.infinity,
                              ),
                              child: _buildMandatorySection(),
                            ),
                          ],
                        ),
                      ),
                    ),
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
    final formData = Provider.of<FormDataProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebView = screenWidth > 600;
    final imageWidth = isWebView ? 600.0 : screenWidth;
    final calculatedHeight = isWebView ? 400.0 : _imageHeight;

    void showImagePickerDialog() {
      debugPrint("showImagePickerDialog triggered");
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
                    debugPrint("Take Photo tapped");
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    debugPrint("Choose from Gallery tapped");
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
      debugPrint("handleImageTap triggered");
      if (formData.selectedMainImage != null ||
          (formData.mainImageUrl != null &&
              formData.mainImageUrl!.isNotEmpty)) {
        debugPrint("Image exists, showing options dialog");
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Image Options'),
              content: const Text('What would you like to do with the image?'),
              actions: [
                TextButton(
                  onPressed: () {
                    debugPrint("Change Image selected");
                    Navigator.pop(context);
                    showImagePickerDialog();
                  },
                  child: const Text('Change Image'),
                ),
                TextButton(
                  onPressed: () {
                    debugPrint("Remove Image selected");
                    Navigator.pop(context);
                    setState(() {
                      formData.setSelectedMainImage(null, null);
                      formData.setMainImageUrl(null);
                    });
                  },
                  child: const Text(
                    'Remove Image',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    debugPrint("Cancel selected in image options dialog");
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      } else {
        debugPrint("No image exists, showing image picker dialog");
        showImagePickerDialog();
      }
    }

    debugPrint("Building image section");
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Entire container is clickable
      onTap: () {
        debugPrint("GestureDetector onTap triggered");
        handleImageTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 0),
        height: calculatedHeight,
        width: imageWidth,
        child: Stack(
          children: [
            if (formData.selectedMainImage != null)
              _buildStyledContainer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.memory(
                    formData.selectedMainImage!,
                    width: double.infinity,
                    height: calculatedHeight,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else if (formData.mainImageUrl != null &&
                formData.mainImageUrl!.isNotEmpty)
              _buildStyledContainer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.network(
                    formData.mainImageUrl!,
                    width: double.infinity,
                    height: calculatedHeight,
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
                ),
              )
            else
              _buildStyledContainer(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 50.0,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Tap here to upload main image',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  kIsWeb ? 'Click to modify image' : 'Tap to modify image',
                  style: const TextStyle(
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

  // "Old style" container for image preview and placeholders.
  Widget _buildStyledContainer({required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  Widget _buildVehicleTypeRadios(FormDataProvider formData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle Type',
          style: TextStyle(fontSize: 14, color: Colors.white),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomRadioButton(
              label: 'Truck',
              value: 'truck',
              groupValue: formData.vehicleType,
              onChanged: (value) {
                formData.setVehicleType(value);
              },
            ),
            const SizedBox(width: 15),
            CustomRadioButton(
              label: 'Trailer',
              value: 'trailer',
              groupValue: formData.vehicleType,
              onChanged: (value) {
                formData.setVehicleType(value);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMandatorySection() {
    final formData = Provider.of<FormDataProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebView = screenWidth > 600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Text(
              'TRUCK/TRAILER FORM'.toUpperCase(),
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
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
          // Reference Number Field using old style (CustomTextField)
          CustomTextField(
            controller: _referenceNumberController,
            hintText: 'Reference Number',
            inputFormatter: [UpperCaseTextFormatter()],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the reference number';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          // For Admins: Sales Rep Dropdown using old style CustomDropdown
          if (widget.isAdminUpload) ...[
            FutureBuilder<List<Map<String, String>>>(
              future: _getSalesReps(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final salesReps = snapshot.data!;
                return CustomDropdown(
                  hintText: 'Select Sales Rep',
                  value: _selectedSalesRep,
                  items: salesReps.map((rep) => rep['display']!).toList(),
                  onChanged: (value) {
                    // Find the matching rep id from the display value.
                    final match = salesReps.firstWhere(
                        (rep) => rep['display'] == value,
                        orElse: () => {});
                    setState(() {
                      _selectedSalesRep = match['id'];
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a Sales Rep';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 15),
          ],
          // NATIS/RC1 Section
          _buildNatisRc1Section(),
          const SizedBox(height: 15),
          Wrap(
            spacing: isWebView ? 20.0 : 0.0,
            runSpacing: 15.0,
            alignment: WrapAlignment.center,
            children: [
              // Vehicle Type Radios
              _buildVehicleTypeRadios(formData),
              // Form fields
              Form(
                key: _formKeys[0],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    CustomDropdown(
                      hintText: 'Year',
                      value: formData.year,
                      items: _yearOptions,
                      onChanged: (value) {
                        formData.setYear(value);
                        _loadBrandsForYear(value!);
                      },
                    ),
                    const SizedBox(height: 15),
                    CustomDropdown(
                      hintText: 'Manufacturer',
                      value: formData.brands?.isNotEmpty == true
                          ? formData.brands![0]
                          : null,
                      items: _brandOptions,
                      onChanged: (value) {
                        if (value != null) {
                          formData.setBrands([value]);
                          _loadModelsForBrand(value);
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    CustomDropdown(
                      hintText: 'Model',
                      value: formData.makeModel,
                      items: _makeModelOptions[
                              formData.brands?.isNotEmpty == true
                                  ? formData.brands![0]
                                  : ''] ??
                          [],
                      onChanged: (value) {
                        formData.setMakeModel(value);
                      },
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: _variantController,
                      hintText: 'Variant',
                      inputFormatter: [UpperCaseTextFormatter()],
                      onChanged: (value) {
                        formData.setVariant(value);
                      },
                    ),
                    const SizedBox(height: 15),
                    CustomDropdown(
                      hintText: 'Select Country',
                      value: formData.country?.isNotEmpty == true
                          ? formData.country
                          : null,
                      items: _countryOptions,
                      onChanged: (value) {
                        formData.setCountry(value);
                        if (value != null) {
                          _updateProvinceOptions(value);
                          formData.setProvince(null);
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a country';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    CustomDropdown(
                      hintText: 'Select Province/State',
                      value: formData.province,
                      items: _provinceOptions,
                      onChanged: (value) {
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
                    CustomTextField(
                      controller: _mileageController,
                      hintText: 'Mileage',
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
                    CustomDropdown(
                      hintText: 'Configuration',
                      value: formData.config?.isNotEmpty == true
                          ? formData.config
                          : null,
                      items: _configurationOptions,
                      onChanged: (value) {
                        formData.setConfig(value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select the configuration';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    CustomDropdown(
                      hintText: 'Application of Use',
                      value: formData.application?.isNotEmpty == true
                          ? formData.application
                          : null,
                      items: _applicationOptions,
                      onChanged: (value) {
                        formData.setApplication(value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select the application of use';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: _vinNumberController,
                      hintText: 'VIN Number',
                      inputFormatter: [UpperCaseTextFormatter()],
                      onChanged: (value) async {
                        if (value.length >= 17) {
                          bool isUnique = await _isVinNumberUnique(value);
                          if (!isUnique) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Warning: This VIN number is already registered in the system'),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 5),
                                action: SnackBarAction(
                                  label: 'Dismiss',
                                  textColor: Colors.white,
                                  onPressed: () {},
                                ),
                              ),
                            );
                          }
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the VIN number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: _engineNumberController,
                      hintText: 'Engine No.',
                      inputFormatter: [UpperCaseTextFormatter()],
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: _registrationNumberController,
                      hintText: 'Registration No.',
                      inputFormatter: [UpperCaseTextFormatter()],
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: _sellingPriceController,
                      hintText: 'Expected Selling Price',
                      isCurrency: true,
                      keyboardType: TextInputType.number,
                      inputFormatter: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsSeparatorInputFormatter(),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the expected selling price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: Text(
                        'Suspension',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white),
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
                          onChanged: (value) {
                            formData.setSuspension(value);
                          },
                        ),
                        const SizedBox(width: 15),
                        CustomRadioButton(
                          label: 'Air',
                          value: 'air',
                          groupValue: formData.suspension,
                          onChanged: (value) {
                            formData.setSuspension(value);
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
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white),
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
                          onChanged: (value) {
                            formData.setTransmissionType(value);
                          },
                        ),
                        const SizedBox(width: 15),
                        CustomRadioButton(
                          label: 'Manual',
                          value: 'manual',
                          groupValue: formData.transmissionType,
                          onChanged: (value) {
                            formData.setTransmissionType(value);
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
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white),
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
                          onChanged: (value) {
                            formData.setHydraulics(value);
                          },
                        ),
                        const SizedBox(width: 15),
                        CustomRadioButton(
                          label: 'No',
                          value: 'no',
                          groupValue: formData.hydraulics,
                          onChanged: (value) {
                            formData.setHydraulics(value);
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
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white),
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
                          onChanged: (value) {
                            formData.setMaintenance(value);
                          },
                        ),
                        const SizedBox(width: 15),
                        CustomRadioButton(
                          label: 'No',
                          value: 'no',
                          groupValue: formData.maintenance,
                          onChanged: (value) {
                            formData.setMaintenance(value);
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
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white),
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
                          onChanged: (value) {
                            formData.setWarranty(value);
                          },
                        ),
                        const SizedBox(width: 15),
                        CustomRadioButton(
                          label: 'No',
                          value: 'no',
                          groupValue: formData.warranty,
                          onChanged: (value) {
                            formData.setWarranty(value);
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
                      ),
                    ],
                    const SizedBox(height: 15),
                    Divider(),
                    const SizedBox(height: 15),
                    Center(
                      child: Text(
                        'DO YOU REQUIRE THE TRUCK TO BE SETTLED BEFORE SELLING',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.white),
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
                          groupValue: formData.requireToSettleType,
                          onChanged: (value) {
                            formData.setRequireToSettleType(value);
                          },
                        ),
                        const SizedBox(width: 15),
                        CustomRadioButton(
                          label: 'No',
                          value: 'no',
                          groupValue: formData.requireToSettleType,
                          onChanged: (value) {
                            formData.setRequireToSettleType(value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _buildNextButton(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Save Section 1 Data with Sales Rep Assignment Logic and Debugging
  Future<String?> _saveSection1Data() async {
    try {
      final formData = Provider.of<FormDataProvider>(context, listen: false);

      // For admin uploads, ensure that a Sales Rep has been selected.
      if (widget.isAdminUpload) {
        if (_selectedSalesRep == null || _selectedSalesRep!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a Sales Rep')),
          );
          return null;
        }
      } else {
        if (!_validateRequiredFields(formData)) {
          return null;
        }
      }

      debugPrint("=== _saveSection1Data START ===");
      String? imageUrl;
      if (formData.selectedMainImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('vehicle_images')
            .child('${DateTime.now().toIso8601String()}.jpg');
        await ref.putData(formData.selectedMainImage!);
        imageUrl = await ref.getDownloadURL();
        debugPrint("Main image uploaded. URL: $imageUrl");
      } else {
        debugPrint("No main image selected.");
      }

      String? natisRc1Url;
      if (_natisRc1File != null) {
        final fileName = _natisRc1FileName ?? 'document';
        final ref = FirebaseStorage.instance
            .ref()
            .child('vehicle_documents')
            .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');
        await ref.putData(_natisRc1File!);
        natisRc1Url = await ref.getDownloadURL();
        debugPrint("NATIS/RC1 file uploaded. URL: $natisRc1Url");
      } else {
        debugPrint("No NATIS/RC1 file selected.");
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      debugPrint(
          "Current Firebase user: ${currentUser?.uid ?? 'No user found'}");
      String? assignedSalesRepId;
      if (widget.isAdminUpload) {
        assignedSalesRepId = _selectedSalesRep;
        debugPrint(
            "Admin upload selected. Using Sales Rep: $assignedSalesRepId");
      } else {
        assignedSalesRepId = currentUser?.uid;
      }
      debugPrint("Assigned Sales Rep ID to be saved: $assignedSalesRepId");

      final vehicleData = {
        'year': formData.year,
        'makeModel': formData.makeModel,
        'variant': formData.variant,
        'vinNumber': formData.vinNumber,
        'config': formData.config,
        'mileage': formData.mileage,
        'application': formData.application,
        'engineNumber': formData.engineNumber,
        'registrationNumber': formData.registrationNumber,
        'sellingPrice': formData.sellingPrice,
        'vehicleType': 'truck',
        'suspensionType': formData.suspension,
        'transmissionType': formData.transmissionType,
        'hydraulics': formData.hydraulics,
        'maintenance': formData.maintenance,
        'warranty': formData.warranty,
        'warrantyDetails': formData.warrantyDetails,
        'requireToSettleType': formData.requireToSettleType,
        'referenceNumber': formData.referenceNumber,
        'brands': formData.brands,
        'mainImageUrl': imageUrl,
        'rc1NatisFile': natisRc1Url,
        'country': formData.country,
        'province': formData.province,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': currentUser?.uid,
        'assignedSalesRepId': assignedSalesRepId,
        'vehicleStatus': 'Draft',
      };

      debugPrint("Vehicle data being saved to Firestore: $vehicleData");

      final docRef = await FirebaseFirestore.instance
          .collection('vehicles')
          .add(vehicleData);
      _vehicleId = docRef.id;
      debugPrint("Vehicle successfully created with document ID: $_vehicleId");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle created successfully')),
      );
      debugPrint("=== _saveSection1Data END ===");
      return _vehicleId;
    } catch (e) {
      debugPrint("Error in _saveSection1Data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving vehicle: $e')),
      );
      return null;
    }
  }

  bool _validateRequiredFields(FormDataProvider formData) {
    if (formData.selectedMainImage == null) {
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

  Widget _buildNextButton() {
    return Center(
      child: CustomButton(
        text: 'Next',
        borderColor: AppColors.blue,
        onPressed: () async {
          final formData =
              Provider.of<FormDataProvider>(context, listen: false);
          if (!widget.isAdminUpload &&
              widget.isNewUpload &&
              !_validateRequiredFields(formData)) {
            return;
          }
          setState(() => _isLoading = true);
          try {
            String? vehicleId = await _saveSection1Data();
            if (vehicleId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MaintenanceWarrantyScreen(
                    vehicleId: vehicleId,
                    vehicleRef: formData.referenceNumber ?? '',
                    maintenanceSelection: formData.maintenance,
                    warrantySelection: formData.warranty,
                    requireToSettleType: formData.requireToSettleType,
                    makeModel: formData.makeModel ?? '',
                    mainImageUrl: formData.mainImageUrl ?? '',
                  ),
                ),
              );
            }
          } finally {
            setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

  void _clearFormControllers() {
    _sellingPriceController.clear();
    _vinNumberController.clear();
    _mileageController.clear();
    _engineNumberController.clear();
    _warrantyDetailsController.clear();
    _registrationNumberController.clear();
    _referenceNumberController.clear();
    _brandsController.clear();
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    formData.setSelectedMainImage(null, null);
    formData.setMainImageUrl(null);
    setState(() {
      _natisRc1File = null;
      _existingNatisRc1Url = null;
      _existingNatisRc1Name = null;
    });
  }

  // Modified image picking method – pass only the image bytes.
  Future<void> _pickImage(ImageSource source) async {
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      final bytes = await image.readAsBytes();
      final fileName = image.name;
      _selectedMainImageFileName = image.name;
      setState(() {
        _selectedMainImage = bytes;
      });
      debugPrint("Picked main image: $_selectedMainImageFileName");
      formData.setSelectedMainImage(bytes, fileName);

      if (_vehicleId != null) {
        _uploadAndUpdateMainImage(bytes);
      }
    } else {
      debugPrint("No image selected from source: $source");
    }
  }

  // Method to upload and update main image
  Future<void> _uploadAndUpdateMainImage(Uint8List imageBytes) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('vehicle_images').child(
          '${DateTime.now().toIso8601String()}_${_selectedMainImageFileName ?? "image.jpg"}');

      await ref.putData(imageBytes);
      final imageUrl = await ref.getDownloadURL();

      // Update Firestore with the new image URL
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(_vehicleId)
          .update({'mainImageUrl': imageUrl});

      final formData = Provider.of<FormDataProvider>(context, listen: false);
      formData.setMainImageUrl(imageUrl);
      debugPrint("Main image URL updated: $imageUrl");
    } catch (e) {
      debugPrint('Error uploading main image: $e');
    }
  }

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
          _brandsController.text =
              (data['brands'] as List<String>?)?.first ?? '';
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
          formData.setBrands(data['brands']);
        });
      }
    } catch (e) {
      debugPrint('Error loading saved form data: $e');
    }
  }

  Widget _buildNatisRc1Section() {
    return Column(
      children: [
        Center(
          child: Text(
            'NATIS/RC1 DOCUMENTATION'.toUpperCase(),
            style: const TextStyle(
                fontSize: 15, color: Colors.white, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 15),
        InkWell(
          onTap: () {
            debugPrint("NATIS/RC1 section tapped");
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
            child: Column(
              children: [
                if (_natisRc1File != null)
                  _buildUploadedFile(_natisRc1File,
                      _natisRc1FileName ?? 'Document', _isLoading)
                else if (_existingNatisRc1Url != null)
                  Column(
                    children: [
                      Icon(
                        _getFileIcon(
                            _existingNatisRc1Name?.split('.').last ?? ''),
                        color: Colors.white,
                        size: 50.0,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _existingNatisRc1Name ?? 'Existing Document',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  )
                else
                  Column(
                    children: const [
                      Icon(
                        Icons.drive_folder_upload_outlined,
                        color: Colors.white,
                        size: 50.0,
                        semanticLabel: 'NATIS/RC1 Upload',
                      ),
                      SizedBox(height: 10),
                      Text(
                        'NATIS/RC1 Upload',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDocumentOptions() {
    debugPrint("Showing document options dialog");
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
                  debugPrint("View Document option selected");
                  Navigator.pop(context);
                  _viewDocument();
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Replace Document'),
                onTap: () {
                  debugPrint("Replace Document option selected");
                  Navigator.pop(context);
                  _pickNatisRc1File();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Document',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  debugPrint("Remove Document option selected");
                  Navigator.pop(context);
                  _removeDocument();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                debugPrint("Cancel pressed in document options dialog");
                Navigator.pop(context);
              },
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
      debugPrint("View document: URL = $url");
      // Implement document viewing logic here (e.g., using url_launcher)
    }
  }

  void _removeDocument() {
    debugPrint("Removing NATIS/RC1 document");
    setState(() {
      _natisRc1File = null;
      _existingNatisRc1Url = null;
      _existingNatisRc1Name = null;
    });
    debugPrint("NATIS/RC1 document removed");
  }
}

// UpperCaseTextFormatter remains the same
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    final String cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final String formatted = NumberFormat('####').format(int.parse(cleanText));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
