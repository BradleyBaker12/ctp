// import 'package:auto_route/auto_route.dart';
import 'package:ctp/pages/home_page.dart';
import 'package:ctp/utils/camera_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' hide VoidCallback;
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/providers/form_data_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart' hide VoidCallback;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/pages/truckForms/custom_dropdown.dart';
import 'package:universal_html/html.dart' as html;
import '../truckForms/custom_text_field.dart';
import 'package:ctp/components/custom_radio_button.dart';
// Only include this if not targeting web
import 'dart:io' as io;

/// Formats input text to uppercase.
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

/// Formats numbers with thousand separators.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###');
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    final String cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final String formatted = _formatter.format(int.parse(cleanText));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}


// @RoutePage()
class TrailerUploadScreen extends StatefulWidget {
  final bool isDuplicating;
  final Vehicle? vehicle;
  final bool isNewUpload;
  final bool isAdminUpload;
  final String? transporterId;

  const TrailerUploadScreen({
    super.key,
    this.vehicle,
    this.transporterId,
    this.isAdminUpload = false,
    this.isDuplicating = false,
    this.isNewUpload = false,
  });

  @override
  _TrailerUploadScreenState createState() => _TrailerUploadScreenState();
}

class _TrailerUploadScreenState extends State<TrailerUploadScreen> {
  final ScrollController _scrollController = ScrollController();
  double _imageHeight = 300.0;

  // Common Controllers
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
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _axlesController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _lengthDoubleAxleController =
      TextEditingController();

  // Add these new controllers for Trailer A
  final TextEditingController _makeTrailerAController = TextEditingController();
  final TextEditingController _modelTrailerAController =
      TextEditingController();
  final TextEditingController _yearTrailerAController = TextEditingController();
  final TextEditingController _licenceDiskExpTrailerAController =
      TextEditingController();
  // Add these new controllers for Trailer B
  final TextEditingController _makeTrailerBController = TextEditingController();
  final TextEditingController _modelTrailerBController =
      TextEditingController();
  final TextEditingController _yearTrailerBController = TextEditingController();
  final TextEditingController _licenceDiskExpTrailerBController =
      TextEditingController();

  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _licenseExpController = TextEditingController();
  final TextEditingController _numbAxelController = TextEditingController();

  // Tri-Axle specific radio button state variables
  String _suspensionTriAxle = 'steel';
  String _absTriAxle = 'no';

// Tri-Axle specific image fields
  Uint8List? _hookpinImage;
  Uint8List? _roofImage;
  Uint8List? _tailboardImage;
  Uint8List? _spareWheelImage;
  Uint8List? _landingLegsImage;
  Uint8List? _hoseAndElctricCableImage;
  Uint8List? _brakeAxel1Image; // Note: retains original spelling to match usage
  Uint8List? _brakeAxel2Image;
  Uint8List? _brakeAxel3Image;
  Uint8List? _axel1Image;
  Uint8List? _axel2Image;
  Uint8List? _axel3Image;
  Uint8List? _licenseDiskImage;

  // Additional image fields for Trailer A
  Uint8List? _hookPinImageA;
  Uint8List? _roofImageA;
  Uint8List? _tailBoardImageA;
  Uint8List? _spareWheelImageA;
  Uint8List? _landingLegImageA;
  Uint8List? _hoseAndElecticalCableImageA;
  Uint8List? _brakesAxle1ImageA;
  Uint8List? _brakesAxle2ImageA;
  Uint8List? _axle1ImageA;
  Uint8List? _axle2ImageA;

  // Additional image fields for Trailer B
  Uint8List? _hookPinImageB;
  Uint8List? _roofImageB;
  Uint8List? _tailBoardImageB;
  Uint8List? _spareWheelImageB;
  Uint8List? _landingLegImageB;
  Uint8List? _hoseAndElecticalCableImageB;
  Uint8List? _brakesAxle1ImageB;
  Uint8List? _brakesAxle2ImageB;
  Uint8List? _axle1ImageB;
  Uint8List? _axle2ImageB;

  // Trailer Type Dropdown (Superlink, Tri-Axle, Double Axle, Other)
  String? _selectedTrailerType;

  // Main image field
  Uint8List? _selectedMainImage;

  // Superlink – Trailer A
  final TextEditingController _lengthTrailerAController =
      TextEditingController();
  final TextEditingController _vinAController = TextEditingController();
  final TextEditingController _registrationAController =
      TextEditingController();
  Uint8List? _frontImageA;
  Uint8List? _sideImageA;
  Uint8List? _tyresImageA;
  Uint8List? _chassisImageA;
  Uint8List? _deckImageA;
  Uint8List? _makersPlateImageA;
  final List<Map<String, dynamic>> _additionalImagesListTrailerA = [];

  // New fields for Trailer A: Axles and two NATIS document uploads
  final TextEditingController _axlesTrailerAController =
      TextEditingController();
  Uint8List? _natisTrailerADoc1File;
  String? _natisTrailerADoc1FileName;
  Uint8List? _natisTrailerADoc2File;
  String? _natisTrailerADoc2FileName;

  // Superlink – Trailer B
  final TextEditingController _lengthTrailerBController =
      TextEditingController();
  final TextEditingController _vinBController = TextEditingController();
  final TextEditingController _registrationBController =
      TextEditingController();
  Uint8List? _frontImageB;
  Uint8List? _sideImageB;
  Uint8List? _tyresImageB;
  Uint8List? _chassisImageB;
  Uint8List? _deckImageB;
  Uint8List? _makersPlateImageB;
  final List<Map<String, dynamic>> _additionalImagesListTrailerB = [];

  // New fields for Trailer B: Axles and two NATIS document uploads
  final TextEditingController _axlesTrailerBController =
      TextEditingController();
  Uint8List? _natisTrailerBDoc1File;
  String? _natisTrailerBDoc1FileName;
  Uint8List? _natisTriAxleDocFile;
  String? _natisTriAxleDocFileName;
  Uint8List? _natisDoubleAxleDocFile;
  String? _natisDoubleAxleDocFileName;

  // Tri-Axle
  final TextEditingController _lengthTrailerController =
      TextEditingController();
  final TextEditingController _vinController = TextEditingController();
  final TextEditingController _registrationController = TextEditingController();
  Uint8List? _frontImage;
  Uint8List? _sideImage;
  Uint8List? _tyresImage;
  Uint8List? _chassisImage;
  Uint8List? _deckImage;
  Uint8List? _makersPlateImage;
  final List<Map<String, dynamic>> _additionalImagesList = [];

  // Documents
  Uint8List? _natisRc1File;
  String? _natisRc1FileName;
  Uint8List? _serviceHistoryFile;
  String? _serviceHistoryFileName;
  String? _existingNatisRc1Url;

  // Damages & Additional Features
  String _damagesCondition = 'no';
  String _featuresCondition = 'no';
  final List<Map<String, dynamic>> _damageList = [];
  final List<Map<String, dynamic>> _featureList = [];

  bool _isLoading = false;
  String? _vehicleId;

  // Admin fields
  String? _selectedSalesRep;
  String? _existingNatisRc1Name;
  String? _selectedMainImageFileName;
  String? _selectedTransporter;
  String? _selectedTransporterId;

  // Form validations
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(1, (index) => GlobalKey<FormState>());

  // JSON data for options
  List<String> _yearOptions = [];
  final List<String> _brandOptions = [];
  List<String> _countryOptions = [];
  List<String> _provinceOptions = [];

  // Missing image URL fields for Superlink Trailer A
  String? _frontImageAUrl;
  String? _sideImageAUrl;
  String? _tyresImageAUrl;
  String? _chassisImageAUrl;
  String? _deckImageAUrl;
  String? _makersPlateImageAUrl;

  // Missing image URL fields for Superlink Trailer B
  String? _frontImageBUrl;
  String? _sideImageBUrl;
  String? _tyresImageBUrl;
  String? _chassisImageBUrl;
  String? _deckImageBUrl;
  String? _makersPlateImageBUrl;

  // Additional Features variables
  final String _additionalFeaturesType = 'no';
  final List<Map<String, dynamic>> _additionalFeaturesList = [];

  // Additional state variables for transporter and sales rep users
  List<Map<String, dynamic>> _transporterUsers = [];
  List<Map<String, dynamic>> _salesRepUsers = [];
  String? _selectedTransporterEmail;
  String? _selectedSalesRepEmail;

  // URL fields for image prepopulation
  String? _frontImageUrl;
  String? _sideImageUrl;
  String? _tyresImageUrl;
  String? _chassisImageUrl;
  String? _deckImageUrl;
  String? _makersPlateImageUrl;

  // Double Axle specific controllers
  final TextEditingController _makeDoubleAxleController =
      TextEditingController();
  final TextEditingController _modelDoubleAxleController =
      TextEditingController();
  final TextEditingController _yearDoubleAxleController =
      TextEditingController();
  final TextEditingController _licenceDiskExpDoubleAxleController =
      TextEditingController();
  final TextEditingController _numbAxelDoubleAxleController =
      TextEditingController();

  // Double Axle specific state variables
  String _suspensionDoubleAxle = 'steel';
  String _absDoubleAxle = 'no';

  // Double Axle specific image fields
  Uint8List? _hookingPinDoubleAxleImage;
  Uint8List? _roofDoubleAxleImage;
  Uint8List? _tailBoardDoubleAxleImage;
  Uint8List? _spareWheelDoubleAxleImage;
  Uint8List? _landingLegsDoubleAxleImage;
  Uint8List? _hoseAndElecCableDoubleAxleImage;
  Uint8List? _brakesAxle1DoubleAxleImage;
  Uint8List? _brakesAxle2DoubleAxleImage;
  Uint8List? _axle1DoubleAxleImage;
  Uint8List? _axle2DoubleAxleImage;
  Uint8List? _licenseDiskDoubleAxleImage;
  Uint8List? _makersPlateDblAxleImage;
  Uint8List? _tyresDoubleAxleImage;

  // Other trailer type specific controllers
  final TextEditingController _makeOtherController = TextEditingController();
  final TextEditingController _modelOtherController = TextEditingController();
  final TextEditingController _yearOtherController = TextEditingController();
  final TextEditingController _lengthOtherController = TextEditingController();
  final TextEditingController _vinOtherController = TextEditingController();
  final TextEditingController _registrationOtherController =
      TextEditingController();
  final TextEditingController _licenceDiskExpOtherController =
      TextEditingController();
  final TextEditingController _numbAxelOtherController =
      TextEditingController();

  // Other trailer type specific state variables
  String _suspensionOther = 'steel';
  String _absOther = 'no';

  // Other trailer type specific image fields
  Uint8List? _frontOtherImage;
  Uint8List? _sideOtherImage;
  Uint8List? _chassisOtherImage;
  Uint8List? _hookingPinOtherImage;
  Uint8List? _deckOtherImage;
  Uint8List? _roofOtherImage;
  Uint8List? _tyresOtherImage;
  Uint8List? _tailBoardOtherImage;
  Uint8List? _spareWheelOtherImage;
  Uint8List? _landingLegsOtherImage;
  Uint8List? _hoseAndElecCableOtherImage;
  Uint8List? _licenseDiskOtherImage;
  Uint8List? _makersPlateOtherImage;
  List<Uint8List?> _brakesAxleOtherImages = [];
  List<Uint8List?> _axleOtherImages = [];
  Uint8List? _natisOtherDocFile;
  String? _natisOtherDocFileName;

  @override
  void initState() {
    super.initState();
    _loadCountryOptions();
    _updateProvinceOptions('South Africa');
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

    // Add initialization for admin fields
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.getUserRole == 'admin') {
        _loadTransporterUsers();
        _loadSalesRepUsers();
      }
    });
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
    _makeController.dispose();
    _yearController.dispose();
    _lengthTrailerAController.dispose();
    _vinAController.dispose();
    _registrationAController.dispose();
    _lengthTrailerBController.dispose();
    _vinBController.dispose();
    _registrationBController.dispose();
    _lengthTrailerController.dispose();
    _vinController.dispose();
    _registrationController.dispose();
    _axlesController.dispose();
    _lengthController.dispose();
    _lengthDoubleAxleController.dispose();
    _scrollController.dispose();
    _makeTrailerAController.dispose();
    _modelTrailerAController.dispose();
    _yearTrailerAController.dispose();
    _makeTrailerBController.dispose();
    _modelTrailerBController.dispose();
    _yearTrailerBController.dispose();
    _licenceDiskExpTrailerAController.dispose();
    _modelController.dispose();
    _licenseExpController.dispose();
    _numbAxelController.dispose();
    _makeDoubleAxleController.dispose();
    _modelDoubleAxleController.dispose();
    _yearDoubleAxleController.dispose();
    _licenceDiskExpDoubleAxleController.dispose();
    _numbAxelDoubleAxleController.dispose();
    _makeOtherController.dispose();
    _modelOtherController.dispose();
    _yearOtherController.dispose();
    _lengthOtherController.dispose();
    _vinOtherController.dispose();
    _registrationOtherController.dispose();
    _licenceDiskExpOtherController.dispose();
    _numbAxelOtherController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formData = Provider.of<FormDataProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebView = screenWidth > 600;

    return WillPopScope(
      onWillPop: () async {
        if (widget.isNewUpload) {
          formData.clearAllData();
        }
        return true;
      },
      child: GradientBackground(
        child: Stack(
          children: [
            Scaffold(
              resizeToAvoidBottomInset: true,
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                leading: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_left),
                  color: Colors.white,
                  iconSize: 40,
                ),
                backgroundColor: Colors.transparent,
                elevation: 0.0,
                systemOverlayStyle: SystemUiOverlayStyle.light,
                centerTitle: true,
              ),
              body: Stack(
                children: [
                  SafeArea(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Center(
                        child: Container(
                          constraints: BoxConstraints(
                              maxWidth: isWebView ? 800 : double.infinity),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: isWebView ? 40.0 : 16.0,
                                vertical: 8.0),
                            child: Column(
                              children: [
                                Container(
                                  constraints: BoxConstraints(
                                      maxWidth:
                                          isWebView ? 600 : double.infinity),
                                  child: _buildMainImageSection(formData),
                                ),
                                Container(
                                  constraints: BoxConstraints(
                                      maxWidth:
                                          isWebView ? 600 : double.infinity),
                                  child: _buildFormSection(formData),
                                ),
                              ],
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
            ),
          ],
        ),
      ),
    );
  }

  void _populateDuplicatedData(FormDataProvider formData) {
    if (widget.vehicle != null) {
      debugPrint('=== Populating Duplicated Trailer Data ===');
      formData.setYear(widget.vehicle!.year);
      formData.setMake(widget.vehicle!.makeModel);
      formData.setCountry(widget.vehicle!.country);
      formData.setProvince(widget.vehicle!.province);
      _updateProvinceOptions(widget.vehicle!.country);
      _selectedTrailerType = widget.vehicle!.trailerType;
      if (_selectedTrailerType == 'Superlink') {
        if (widget.vehicle!.trailer != null &&
            widget.vehicle!.trailer!.superlinkData != null) {
          _lengthTrailerAController.text =
              widget.vehicle!.trailer!.superlinkData!.lengthA ?? '';
          _vinAController.text =
              widget.vehicle!.trailer!.superlinkData!.vinA ?? '';
          _registrationAController.text =
              widget.vehicle!.trailer!.superlinkData!.registrationA ?? '';
          // If your data model includes axles and NATIS docs, populate them here as well.
          _lengthTrailerBController.text =
              widget.vehicle!.trailer!.superlinkData!.lengthB ?? '';
          _vinBController.text =
              widget.vehicle!.trailer!.superlinkData!.vinB ?? '';
          _registrationBController.text =
              widget.vehicle!.trailer!.superlinkData!.registrationB ?? '';
        }
      } else if (_selectedTrailerType == 'Tri-Axle') {
        if (widget.vehicle!.trailer != null &&
            widget.vehicle!.trailer!.triAxleData != null) {
          _lengthTrailerController.text =
              widget.vehicle!.trailer!.triAxleData!.length ?? '';
          _vinController.text = widget.vehicle!.trailer!.triAxleData!.vin ?? '';
          _registrationController.text =
              widget.vehicle!.trailer!.triAxleData!.registration ?? '';
        }
      }
      debugPrint('=== Duplicated Trailer Data Population Complete ===');
    }
  }

  void _pickImageOrFile({
    required String title,
    required bool pickImageOnly,
    required void Function(Uint8List?, String fileName) callback,
  }) async {
    try {
      if (pickImageOnly) {
        if (kIsWeb) {
          // Web: Already using html and file picker
          bool cameraAvailable = false;
          try {
            cameraAvailable = html.window.navigator.mediaDevices != null;
          } catch (e) {
            cameraAvailable = false;
          }

          showDialog(
            context: context,
            builder: (BuildContext ctx) {
              return AlertDialog(
                title: Text(title),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (cameraAvailable)
                      ListTile(
                        leading: const Icon(Icons.camera_alt),
                        title: const Text('Take Photo'),
                        onTap: () async {
                          Navigator.of(ctx).pop();
                          final imageBytes = await capturePhoto(context);
                          if (imageBytes != null) {
                            callback(imageBytes, 'captured.png');
                          }
                        },
                      ),
                    ListTile(
                      leading: const Icon(Icons.folder),
                      title: const Text('Pick from Device'),
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles(
                          type: FileType.image,
                        );
                        if (result != null && result.files.isNotEmpty) {
                          final fileName = result.files.first.name;
                          final bytes = result.files.first.bytes;
                          callback(bytes, fileName);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        } else {
          // Mobile/Desktop: use image_picker
          showModalBottomSheet(
            context: context,
            builder: (_) {
              return SafeArea(
                child: Wrap(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: const Text('Take Photo'),
                      onTap: () async {
                        Navigator.of(context).pop();
                        final XFile? image = await ImagePicker().pickImage(
                          source: ImageSource.camera,
                          maxWidth: 1800,
                          maxHeight: 1800,
                        );
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          callback(bytes, image.name);
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_library),
                      title: const Text('Pick from Gallery'),
                      onTap: () async {
                        Navigator.of(context).pop();
                        final XFile? image = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          callback(bytes, image.name);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        }
      } else {
        // Files of any type
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.any,
        );
        debugPrint('FilePickerResult: $result');
        if (result != null && result.files.isNotEmpty) {
          final fileName = result.files.first.name;
          Uint8List? bytes = result.files.first.bytes;
          debugPrint('Picked file: $fileName, bytes: ${bytes?.length}');
          // If bytes are null, try reading from the file path (mobile fallback)
          if (bytes == null && result.files.first.path != null) {
            final io.File file = io.File(result.files.first.path!);
            bytes = await file.readAsBytes();
            debugPrint('Read bytes from file path: ${bytes.length}');
          }
          // Call the callback with the file bytes and name
          callback(bytes, fileName);
        } else {
          debugPrint('No file picked or result.files is empty');
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Widget _buildMainImageSection(FormDataProvider formData) {
    void onTapMainImage() {
      if (_selectedMainImage != null) {
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
                    _pickImageOrFile(
                      title: 'Change Main Image',
                      pickImageOnly: true,
                      callback: (file, fileName) {
                        if (file != null) {
                          setState(() => _selectedMainImage = file);
                        }
                      },
                    );
                  },
                  child: const Text('Change Image'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _selectedMainImage = null);
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
        _pickImageOrFile(
          title: 'Select Main Image',
          pickImageOnly: true,
          callback: (file, fileName) {
            if (file != null) {
              setState(() => _selectedMainImage = file);
            }
          },
        );
      }
    }

    return GestureDetector(
      onTap: onTapMainImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 0),
        height: _imageHeight,
        width: double.infinity,
        child: Stack(
          children: [
            if (_selectedMainImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.memory(
                  _selectedMainImage!,
                  width: double.infinity,
                  height: _imageHeight,
                  fit: BoxFit.cover,
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
                          Icon(Icons.camera_alt,
                              color: Colors.white, size: 50.0),
                          SizedBox(height: 10),
                          Text(
                            'Tap here to upload main image',
                            style:
                                TextStyle(fontSize: 14, color: Colors.white70),
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
                child: const Text('Tap to modify image',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0E4CAF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: const Color(0xFF0E4CAF), width: 2.0),
      ),
      child: child,
    );
  }

  Widget _buildFormSection(FormDataProvider formData) {
    final screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(children: [
            // Add admin fields if user is admin
            if (Provider.of<UserProvider>(context, listen: false).getUserRole ==
                'admin') ...[
              const SizedBox(height: 15),
              _buildTransporterField(),
              const SizedBox(height: 15),
              _buildSalesRepField(),
            ],
            CustomTextField(
              controller: _referenceNumberController,
              hintText: 'Reference Number',
              inputFormatter: [UpperCaseTextFormatter()],
            ),
            // _buildSalesRepField(),
            const SizedBox(height: 15),
            CustomDropdown(
              hintText: 'Select Trailer Type',
              value: _selectedTrailerType,
              items: const ['Superlink', 'Tri-Axle', 'Double Axle', 'Other'],
              onChanged: (value) {
                setState(() {
                  _selectedTrailerType = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select the trailer type';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            if (_selectedTrailerType == 'Other') ...[
              const SizedBox(height: 15),
              CustomTextField(
                controller: _makeOtherController,
                hintText: 'Make of Trailer',
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _modelOtherController,
                hintText: 'Model of Trailer',
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _yearOtherController,
                hintText: 'Year of Trailer',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              Center(
                  child: Text('Suspension',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      textAlign: TextAlign.center)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomRadioButton(
                    label: 'Steel',
                    value: 'steel',
                    groupValue: _suspensionOther,
                    onChanged: (value) {
                      setState(() {
                        _suspensionOther = value ?? 'steel';
                      });
                    },
                  ),
                  const SizedBox(width: 15),
                  CustomRadioButton(
                    label: 'Air',
                    value: 'air',
                    groupValue: _suspensionOther,
                    onChanged: (value) {
                      setState(() {
                        _suspensionOther = value ?? 'air';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _lengthOtherController,
                hintText: 'Length Trailer',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _vinOtherController,
                hintText: 'VIN',
                inputFormatter: [UpperCaseTextFormatter()],
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _registrationOtherController,
                hintText: 'Registration',
                inputFormatter: [UpperCaseTextFormatter()],
              ),
              const SizedBox(height: 15),
              InkWell(
                onTap: () =>
                    _selectDate(context, _licenceDiskExpOtherController),
                child: CustomTextField(
                  controller: _licenceDiskExpOtherController,
                  hintText: 'Licence Disk Expiry Date',
                  enabled: false,
                ),
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _numbAxelOtherController,
                hintText: 'Number of Axles',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              Center(
                  child: Text('ABS',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      textAlign: TextAlign.center)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomRadioButton(
                    label: 'Yes',
                    value: 'yes',
                    groupValue: _absOther,
                    onChanged: (value) {
                      setState(() {
                        _absOther = value ?? 'yes';
                      });
                    },
                  ),
                  const SizedBox(width: 15),
                  CustomRadioButton(
                    label: 'No',
                    value: 'no',
                    groupValue: _absOther,
                    onChanged: (value) {
                      setState(() {
                        _absOther = value ?? 'no';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                'NATIS Document',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  debugPrint(
                      'NATIS doc tap: file=$_natisOtherDocFile, name=$_natisOtherDocFileName');
                  if (_natisOtherDocFile != null) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('NATIS Document'),
                        content: const Text(
                            'What would you like to do with the file?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _pickImageOrFile(
                                title: 'Change NATIS Document',
                                pickImageOnly: false,
                                callback: (file, fileName) {
                                  debugPrint(
                                      'Change NATIS callback: file=$file, name=$fileName');
                                  if (file != null) {
                                    setState(() {
                                      _natisOtherDocFile = file;
                                      _natisOtherDocFileName = fileName;
                                    });
                                  }
                                },
                              );
                            },
                            child: const Text('Change File'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {
                                _natisOtherDocFile = null;
                                _natisOtherDocFileName = null;
                              });
                            },
                            child: const Text('Remove File',
                                style: TextStyle(color: Colors.red)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    _pickImageOrFile(
                      title: 'Select NATIS Document',
                      pickImageOnly: false,
                      callback: (file, fileName) {
                        debugPrint(
                            'Select NATIS callback: file=$file, name=$fileName');
                        if (file != null) {
                          setState(() {
                            _natisOtherDocFile = file;
                            _natisOtherDocFileName = fileName;
                          });
                        }
                      },
                    );
                  }
                },
                borderRadius: BorderRadius.circular(10.0),
                child: _buildStyledContainer(
                  child: _natisOtherDocFile == null
                      ? const Column(
                          children: [
                            Icon(Icons.upload_file,
                                color: Colors.white, size: 50.0),
                            SizedBox(height: 10),
                            Text(
                              'Upload NATIS Document',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Icon(Icons.description,
                                color: Colors.white, size: 50.0),
                            SizedBox(height: 10),
                            Text(
                              _natisOtherDocFileName != null
                                  ? _natisOtherDocFileName!.split('/').last
                                  : 'No file name',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            // Debug info
                            Builder(builder: (_) {
                              debugPrint(
                                  'NATIS doc widget: file=$_natisOtherDocFile, name=$_natisOtherDocFileName');
                              return const SizedBox.shrink();
                            }),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle('Front Image', _frontOtherImage,
                  (img) => setState(() => _frontOtherImage = img)),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle('Side Image', _sideOtherImage,
                  (img) => setState(() => _sideOtherImage = img)),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle('Chassis Image', _chassisOtherImage,
                  (img) => setState(() => _chassisOtherImage = img)),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                  'Hooking Pin Image',
                  _hookingPinOtherImage,
                  (img) => setState(() => _hookingPinOtherImage = img)),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle('Deck Image', _deckOtherImage,
                  (img) => setState(() => _deckOtherImage = img)),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                  'Roof Image (if applicable)',
                  _roofOtherImage,
                  (img) => setState(() => _roofOtherImage = img)),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle('Tyres Image', _tyresOtherImage,
                  (img) => setState(() => _tyresOtherImage = img)),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                  'Tail Board Image',
                  _tailBoardOtherImage,
                  (img) => setState(() => _tailBoardOtherImage = img)),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                  'Spare Wheel Image',
                  _spareWheelOtherImage,
                  (img) => setState(() => _spareWheelOtherImage = img)),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                  'Landing Legs Image',
                  _landingLegsOtherImage,
                  (img) => setState(() => _landingLegsOtherImage = img)),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                  'Hose and Electrical Cable Image',
                  _hoseAndElecCableOtherImage,
                  (img) => setState(() => _hoseAndElecCableOtherImage = img)),
              const SizedBox(height: 15),
              _buildDynamicAxleImageSection(),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                  'Licence Disk Image',
                  _licenseDiskOtherImage,
                  (img) => setState(() => _licenseDiskOtherImage = img)),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                  'Makers Plate Image',
                  _makersPlateOtherImage,
                  (img) => setState(() => _makersPlateOtherImage = img)),
              _buildAdditionalImagesSection(),
              const SizedBox(height: 15),
              const Text(
                'Are there any damages?',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomRadioButton(
                    label: 'Yes',
                    value: 'yes',
                    groupValue: _damagesCondition,
                    onChanged: (val) {
                      setState(() {
                        _damagesCondition = val ?? 'no';
                        if (_damagesCondition == 'yes' && _damageList.isEmpty) {
                          _damageList.add({'description': '', 'image': null});
                        } else if (_damagesCondition == 'no') {
                          _damageList.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 20),
                  CustomRadioButton(
                    label: 'No',
                    value: 'no',
                    groupValue: _damagesCondition,
                    onChanged: (val) {
                      setState(() {
                        _damagesCondition = val ?? 'no';
                        if (_damagesCondition == 'no') {
                          _damageList.clear();
                        } else if (_damageList.isEmpty) {
                          _damageList.add({'description': '', 'image': null});
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              if (_damagesCondition == 'yes') _buildDamageSection(),
              const SizedBox(height: 20),
              const Text(
                'Are there any additional features?',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomRadioButton(
                    label: 'Yes',
                    value: 'yes',
                    groupValue: _featuresCondition,
                    onChanged: (val) {
                      setState(() {
                        _featuresCondition = val ?? 'no';
                        if (_featuresCondition == 'yes' &&
                            _featureList.isEmpty) {
                          _featureList.add({'description': '', 'image': null});
                        } else if (_featuresCondition == 'no') {
                          _featureList.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 20),
                  CustomRadioButton(
                    label: 'No',
                    value: 'no',
                    groupValue: _featuresCondition,
                    onChanged: (val) {
                      setState(() {
                        _featuresCondition = val ?? 'no';
                        if (_featuresCondition == 'no') {
                          _featureList.clear();
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              if (_featuresCondition == 'yes')
                _buildAdditionalFeaturesSection(),
              _buildDoneButton(),
              const SizedBox(height: 30),
            ] else if (_selectedTrailerType != null) ...[
              if (_selectedTrailerType != null) ...[
                if (_selectedTrailerType == 'Superlink') ...[
                  const Text("Trailer A Details",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  CustomTextField(
                    controller: _makeTrailerAController,
                    hintText: 'Make Trailer A',
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _modelTrailerAController,
                    hintText: 'Model Trailer A',
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _yearTrailerAController,
                    hintText: 'Year Trailer A',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  Center(
                      child: Text('Suspension Trailer A',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white),
                          textAlign: TextAlign.center)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomRadioButton(
                        label: 'Steel',
                        value: 'steel',
                        groupValue: formData.suspensionA,
                        onChanged: (value) {
                          formData.setSuspensionA(value);
                          formData.saveFormState();
                        },
                      ),
                      const SizedBox(width: 15),
                      CustomRadioButton(
                        label: 'Air',
                        value: 'air',
                        groupValue: formData.suspensionA,
                        onChanged: (value) {
                          formData.setSuspensionA(value);
                          formData.saveFormState();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _lengthTrailerAController,
                    hintText: 'Length Trailer A',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _vinAController,
                    hintText: 'VIN A',
                    inputFormatter: [UpperCaseTextFormatter()],
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _registrationAController,
                    hintText: 'Registration A',
                    inputFormatter: [UpperCaseTextFormatter()],
                  ),
                  // New fields for Trailer A
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _axlesTrailerAController,
                    hintText: 'Number of Axles Trailer A',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                      controller: _licenceDiskExpTrailerAController,
                      hintText: 'Licence Disk Expriry Date Trailer A',
                      inputFormatter: [UpperCaseTextFormatter()]),
                  const SizedBox(height: 15),
                  Center(
                      child: Text('ABS Trailer A',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white),
                          textAlign: TextAlign.center)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomRadioButton(
                        label: 'Yes',
                        value: 'yes',
                        groupValue: formData.absA,
                        onChanged: (value) {
                          formData.setAbsA(value);
                          formData.saveFormState();
                        },
                      ),
                      const SizedBox(width: 15),
                      CustomRadioButton(
                        label: 'No',
                        value: 'no',
                        groupValue: formData.absA,
                        onChanged: (value) {
                          formData.setAbsA(value);
                          formData.saveFormState();
                        },
                      ),
                    ],
                  ),
                  const Text(
                    'NATIS Document for Trailer A',
                    style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      _pickImageOrFile(
                        title: 'Select NATIS Document 1 for Trailer A',
                        pickImageOnly: false,
                        callback: (file, fileName) {
                          if (file != null) {
                            setState(() {
                              _natisTrailerADoc1File = file;
                              _natisTrailerADoc1FileName = fileName;
                            });
                          }
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(10.0),
                    child: _buildStyledContainer(
                      child: _natisTrailerADoc1File == null
                          ? const Column(
                              children: [
                                Icon(Icons.upload_file,
                                    color: Colors.white, size: 50.0),
                                SizedBox(height: 10),
                                Text('Upload NATIS Document 1',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.white70),
                                    textAlign: TextAlign.center),
                              ],
                            )
                          : Column(
                              children: [
                                Icon(Icons.description,
                                    color: Colors.white, size: 50.0),
                                SizedBox(height: 10),
                                Text(
                                    _natisTrailerADoc1FileName!.split('/').last,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 14)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle(
                      'Trailer A - Front Image',
                      _frontImageA,
                      (img) => setState(() => _frontImageA = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle('Trailer A - Side Image',
                      _sideImageA, (img) => setState(() => _sideImageA = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle(
                      'Trailer A - Tyres Image',
                      _tyresImageA,
                      (img) => setState(() => _tyresImageA = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle(
                      'Trailer A - Chassis Image',
                      _chassisImageA,
                      (img) => setState(() => _chassisImageA = img)),
                  _buildImageSectionWithTitle('Trailer A - Deck Image',
                      _deckImageA, (img) => setState(() => _deckImageA = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle(
                      'Trailer A - Makers Plate Image',
                      _makersPlateImageA,
                      (img) => setState(() => _makersPlateImageA = img)),
                  _buildImageSectionWithTitle(
                      'Trailer A - Hook Pin Image',
                      _hookPinImageA,
                      (img) => setState(() => _hookPinImageA = img)),
                  _buildImageSectionWithTitle(
                      'Trailer A -Roof image (if applicable) ',
                      _roofImageA,
                      (img) => setState(() => _roofImageA = img)),
                  _buildImageSectionWithTitle(
                      'Trailer A - Tail Board Image',
                      _tailBoardImageA,
                      (img) => setState(() => _tailBoardImageA = img)),
                  _buildImageSectionWithTitle(
                      'Trailer A - Spare Wheel Image',
                      _spareWheelImageA,
                      (img) => setState(() => _spareWheelImageA = img)),
                  _buildImageSectionWithTitle(
                      'Trailer A - Landing Legs Image',
                      _landingLegImageA,
                      (img) => setState(() => _landingLegImageA = img)),
                  _buildImageSectionWithTitle(
                      'Trailer A - Hose and Electrical Cable Image',
                      _hoseAndElecticalCableImageA,
                      (img) =>
                          setState(() => _hoseAndElecticalCableImageA = img)),
                  _buildImageSectionWithTitle(
                      'Trailer A - Brakes Axle 1 Image',
                      _brakesAxle1ImageA,
                      (img) => setState(() => _brakesAxle1ImageA = img)),
                  _buildImageSectionWithTitle(
                      'Trailer A - Brakes Axle 2 Image',
                      _brakesAxle2ImageA,
                      (img) => setState(() => _brakesAxle2ImageA = img)),
                  _buildImageSectionWithTitle(
                      'Trailer A - Axle 1 Image',
                      _axle1ImageA,
                      (img) => setState(() => _axle1ImageA = img)),
                  _buildImageSectionWithTitle(
                      'Trailer A - Axle 2 Image',
                      _axle2ImageA,
                      (img) => setState(() => _axle2ImageA = img)),
                  const SizedBox(height: 15),
                  _buildAdditionalImagesSectionForTrailerA(),
                  const SizedBox(height: 15),
                  const Text("Trailer B Details",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  CustomTextField(
                    controller: _makeTrailerBController,
                    hintText: 'Make Trailer B',
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _modelTrailerBController,
                    hintText: 'Model Trailer B',
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _yearTrailerBController,
                    hintText: 'Year Trailer B',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _sellingPriceController,
                    hintText: 'Expected Selling Price Trailer B',
                    keyboardType: TextInputType.number,
                    inputFormatter: [
                      FilteringTextInputFormatter.digitsOnly,
                      ThousandsSeparatorInputFormatter(),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Center(
                      child: Text('Suspension Trailer B',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white),
                          textAlign: TextAlign.center)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomRadioButton(
                        label: 'Steel',
                        value: 'steel',
                        groupValue: formData.suspensionB,
                        onChanged: (value) {
                          formData.setSuspensionB(value);
                          formData.saveFormState();
                        },
                      ),
                      const SizedBox(width: 15),
                      CustomRadioButton(
                        label: 'Air',
                        value: 'air',
                        groupValue: formData.suspensionB,
                        onChanged: (value) {
                          formData.setSuspensionB(value);
                          formData.saveFormState();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _lengthTrailerBController,
                    hintText: 'Length Trailer B',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _vinBController,
                    hintText: 'VIN B',
                    inputFormatter: [UpperCaseTextFormatter()],
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _registrationBController,
                    hintText: 'Registration B',
                    inputFormatter: [UpperCaseTextFormatter()],
                  ),
                  // New fields for Trailer B
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _axlesTrailerBController,
                    hintText: 'Number of Axles Trailer B',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                      controller: _licenceDiskExpTrailerBController,
                      hintText: 'Licence Disk Expriry Date Trailer B',
                      inputFormatter: [UpperCaseTextFormatter()]),
                  const SizedBox(height: 15),
                  Center(
                      child: Text('ABS Trailer B',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white),
                          textAlign: TextAlign.center)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomRadioButton(
                        label: 'Yes',
                        value: 'yes',
                        groupValue: formData.absB,
                        onChanged: (value) {
                          formData.setAbsB(value);
                          formData.saveFormState();
                        },
                      ),
                      const SizedBox(width: 15),
                      CustomRadioButton(
                        label: 'No',
                        value: 'no',
                        groupValue: formData.absB,
                        onChanged: (value) {
                          formData.setAbsB(value);
                          formData.saveFormState();
                        },
                      ),
                    ],
                  ),
                  const Text(
                    'NATIS Document 1 for Trailer B',
                    style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      _pickImageOrFile(
                        title: 'Select NATIS Document 1 for Trailer B',
                        pickImageOnly: false,
                        callback: (file, fileName) {
                          if (file != null) {
                            setState(() {
                              _natisTrailerBDoc1File = file;
                              _natisTrailerBDoc1FileName = fileName;
                            });
                          }
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(10.0),
                    child: _buildStyledContainer(
                      child: _natisTrailerBDoc1File == null
                          ? const Column(
                              children: [
                                Icon(Icons.upload_file,
                                    color: Colors.white, size: 50.0),
                                SizedBox(height: 10),
                                Text('Upload NATIS Document 1',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.white70),
                                    textAlign: TextAlign.center),
                              ],
                            )
                          : Column(
                              children: [
                                Icon(Icons.description,
                                    color: Colors.white, size: 50.0),
                                SizedBox(height: 10),
                                Text(
                                    _natisTrailerBDoc1FileName!.split('/').last,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 14)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle(
                      'Trailer B - Front Image',
                      _frontImageB,
                      (img) => setState(() => _frontImageB = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle('Trailer B - Side Image',
                      _sideImageB, (img) => setState(() => _sideImageB = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle(
                      'Trailer B - Tyres Image',
                      _tyresImageB,
                      (img) => setState(() => _tyresImageB = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle(
                      'Trailer B - Chassis Image',
                      _chassisImageB,
                      (img) => setState(() => _chassisImageB = img)),
                  _buildImageSectionWithTitle('Trailer B - Deck Image',
                      _deckImageB, (img) => setState(() => _deckImageB = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle(
                      'Trailer B - Makers Plate Image',
                      _makersPlateImageB,
                      (img) => setState(() => _makersPlateImageB = img)),
                  _buildImageSectionWithTitle(
                      'Trailer B - Hook Pin Image',
                      _hookPinImageB,
                      (img) => setState(() => _hookPinImageB = img)),
                  _buildImageSectionWithTitle(
                      'Trailer B -Roof image (if applicable) ',
                      _roofImageB,
                      (img) => setState(() => _roofImageB = img)),
                  _buildImageSectionWithTitle(
                      'Trailer B - Tail Board Image',
                      _tailBoardImageB,
                      (img) => setState(() => _tailBoardImageB = img)),
                  _buildImageSectionWithTitle(
                      'Trailer B - Spare Wheel Image',
                      _spareWheelImageB,
                      (img) => setState(() => _spareWheelImageB = img)),
                  _buildImageSectionWithTitle(
                      'Trailer B - Landing Legs Image',
                      _landingLegImageB,
                      (img) => setState(() => _landingLegImageB = img)),
                  _buildImageSectionWithTitle(
                      'Trailer B - Hose and Electrical Cable Image',
                      _hoseAndElecticalCableImageB,
                      (img) =>
                          setState(() => _hoseAndElecticalCableImageB = img)),
                  _buildImageSectionWithTitle(
                      'Trailer B - Brakes Axle 1 Image',
                      _brakesAxle1ImageB,
                      (img) => setState(() => _brakesAxle1ImageB = img)),
                  _buildImageSectionWithTitle(
                      'Trailer B - Brakes Axle 2 Image',
                      _brakesAxle2ImageB,
                      (img) => setState(() => _brakesAxle2ImageB = img)),
                  _buildImageSectionWithTitle(
                      'Trailer B - Axle 1 Image',
                      _axle1ImageB,
                      (img) => setState(() => _axle1ImageB = img)),
                  _buildImageSectionWithTitle(
                      'Trailer B - Axle 2 Image',
                      _axle2ImageB,
                      (img) => setState(() => _axle2ImageB = img)),
                  const SizedBox(height: 15),
                  const Text('Are there additional images for Trailer B?',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildAdditionalImagesSectionForTrailerB(),
                  const SizedBox(height: 15),
                ] else if (_selectedTrailerType == 'Tri-Axle') ...[
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _makeController,
                    hintText: 'Make of Trailer',
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _modelController,
                    hintText: 'Model of Trailer',
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _yearController,
                    hintText: 'Year of Trailer',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  Center(
                      child: Text('Suspension',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white),
                          textAlign: TextAlign.center)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomRadioButton(
                        label: 'Steel',
                        value: 'steel',
                        groupValue: _suspensionTriAxle,
                        onChanged: (value) {
                          setState(() {
                            _suspensionTriAxle = value ?? 'steel';
                          });
                        },
                      ),
                      const SizedBox(width: 15),
                      CustomRadioButton(
                        label: 'Air',
                        value: 'air',
                        groupValue: _suspensionTriAxle,
                        onChanged: (value) {
                          setState(() {
                            _suspensionTriAxle = value ?? 'air';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _lengthTrailerController,
                    hintText: 'Length Trailer',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _vinController,
                    hintText: 'VIN',
                    inputFormatter: [UpperCaseTextFormatter()],
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _registrationController,
                    hintText: 'Registration',
                    inputFormatter: [UpperCaseTextFormatter()],
                  ),
                  const SizedBox(height: 15),
                  InkWell(
                    onTap: () => _selectDate(context, _licenseExpController),
                    child: CustomTextField(
                      controller: _licenseExpController,
                      hintText: 'Licence disk expiry date',
                      enabled: false,
                    ),
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _numbAxelController,
                    hintText: 'Number of Axles',
                    inputFormatter: [UpperCaseTextFormatter()],
                  ),
                  const SizedBox(height: 15),
                  Center(
                      child: Text('ABS',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white),
                          textAlign: TextAlign.center)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomRadioButton(
                        label: 'Yes',
                        value: 'yes',
                        groupValue: _absTriAxle,
                        onChanged: (value) {
                          setState(() {
                            _absTriAxle = value ?? 'yes';
                          });
                        },
                      ),
                      const SizedBox(width: 15),
                      CustomRadioButton(
                        label: 'No',
                        value: 'no',
                        groupValue: _absTriAxle,
                        onChanged: (value) {
                          setState(() {
                            _absTriAxle = value ?? 'no';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'NATIS Document for Tri-Axle',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      if (_natisTriAxleDocFile != null) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('NATIS Document'),
                            content: const Text(
                                'What would you like to do with the file?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _pickImageOrFile(
                                    title: 'Change NATIS Document for Tri-Axle',
                                    pickImageOnly: false,
                                    callback: (file, fileName) {
                                      if (file != null) {
                                        setState(() {
                                          _natisTriAxleDocFile = file;
                                          _natisTriAxleDocFileName = fileName;
                                        });
                                      }
                                    },
                                  );
                                },
                                child: const Text('Change File'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _natisTriAxleDocFile = null;
                                    _natisTriAxleDocFileName = null;
                                  });
                                },
                                child: const Text('Remove File',
                                    style: TextStyle(color: Colors.red)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        _pickImageOrFile(
                          title: 'Select NATIS Document for Tri-Axle',
                          pickImageOnly: false,
                          callback: (file, fileName) {
                            if (file != null) {
                              setState(() {
                                _natisTriAxleDocFile = file;
                                _natisTriAxleDocFileName = fileName;
                              });
                            }
                          },
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(10.0),
                    child: _buildStyledContainer(
                      child: _natisTriAxleDocFile == null
                          ? const Column(
                              children: [
                                Icon(Icons.upload_file,
                                    color: Colors.white, size: 50.0),
                                SizedBox(height: 10),
                                Text(
                                  'Upload NATIS Document',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.white70),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Icon(Icons.description,
                                    color: Colors.white, size: 50.0),
                                SizedBox(height: 10),
                                Text(
                                  _natisTriAxleDocFileName!.split('/').last,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle('Front Trailer Image',
                      _frontImage, (img) => setState(() => _frontImage = img)),
                  _buildImageSectionWithTitle('Side Image', _sideImage,
                      (img) => setState(() => _sideImage = img)),
                  _buildImageSectionWithTitle('Chassis Image', _chassisImage,
                      (img) => setState(() => _chassisImage = img)),
                  _buildImageSectionWithTitle('Hook Pin Image', _hookpinImage,
                      (img) => setState(() => _hookpinImage = img)),
                  _buildImageSectionWithTitle('Deck Image', _deckImage,
                      (img) => setState(() => _deckImage = img)),
                  _buildImageSectionWithTitle('Roof Image If Applicable',
                      _roofImage, (img) => setState(() => _roofImage = img)),
                  _buildImageSectionWithTitle(
                      'Tail Board Image ',
                      _tailboardImage,
                      (img) => setState(() => _tailboardImage = img)),
                  _buildImageSectionWithTitle(
                      'Spare Wheel Image',
                      _spareWheelImage,
                      (img) => setState(() => _spareWheelImage = img)),
                  _buildImageSectionWithTitle(
                      'Landing Legs Image',
                      _landingLegsImage,
                      (img) => setState(() => _landingLegsImage = img)),
                  _buildImageSectionWithTitle(
                      'Hose and Elctrical Cable Image',
                      _hoseAndElctricCableImage,
                      (img) => setState(() => _hoseAndElctricCableImage = img)),
                  _buildImageSectionWithTitle(
                      'Brake Axel 1 Image',
                      _brakeAxel1Image,
                      (img) => setState(() => _brakeAxel1Image = img)),
                  _buildImageSectionWithTitle(
                      'Brake Axel 2 Image',
                      _brakeAxel2Image,
                      (img) => setState(() => _brakeAxel2Image = img)),
                  _buildImageSectionWithTitle(
                      'Brake Axel 3 Image',
                      _brakeAxel3Image,
                      (img) => setState(() => _brakeAxel3Image = img)),
                  _buildImageSectionWithTitle('Axel 1 Image', _axel1Image,
                      (img) => setState(() => _axel1Image = img)),
                  _buildImageSectionWithTitle(' Axel 2 Image', _axel2Image,
                      (img) => setState(() => _axel2Image = img)),
                  _buildImageSectionWithTitle(' Axel 3 Image', _axel3Image,
                      (img) => setState(() => _axel3Image = img)),
                  _buildImageSectionWithTitle('Tyres Image', _tyresImage,
                      (img) => setState(() => _tyresImage = img)),
                  _buildImageSectionWithTitle(
                      'Makers Plate Image',
                      _makersPlateImage,
                      (img) => setState(() => _makersPlateImage = img)),
                  _buildImageSectionWithTitle(
                      'License Disk Image',
                      _licenseDiskImage,
                      (img) => setState(() => _licenseDiskImage = img)),
                  _buildAdditionalImagesSection(),
                  const SizedBox(height: 15),
                ] else if (_selectedTrailerType == 'Double Axle') ...[
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _makeDoubleAxleController,
                    hintText: 'Make of Trailer',
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _modelDoubleAxleController,
                    hintText: 'Model of Trailer',
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _yearDoubleAxleController,
                    hintText: 'Year of Trailer',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  Center(
                      child: Text('Suspension',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white),
                          textAlign: TextAlign.center)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomRadioButton(
                        label: 'Steel',
                        value: 'steel',
                        groupValue: _suspensionDoubleAxle,
                        onChanged: (value) {
                          setState(() {
                            _suspensionDoubleAxle = value ?? 'steel';
                          });
                        },
                      ),
                      const SizedBox(width: 15),
                      CustomRadioButton(
                        label: 'Air',
                        value: 'air',
                        groupValue: _suspensionDoubleAxle,
                        onChanged: (value) {
                          setState(() {
                            _suspensionDoubleAxle = value ?? 'air';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _lengthDoubleAxleController,
                    hintText: 'Length Trailer',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _vinController,
                    hintText: 'VIN',
                    inputFormatter: [UpperCaseTextFormatter()],
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _registrationController,
                    hintText: 'Registration',
                    inputFormatter: [UpperCaseTextFormatter()],
                  ),
                  // New fields for Double Axle
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _axlesTrailerBController,
                    hintText: 'Number of Axles Trailer B',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  CustomTextField(
                      controller: _licenceDiskExpDoubleAxleController,
                      hintText: 'Licence Disk Expriry Date Trailer B',
                      inputFormatter: [UpperCaseTextFormatter()]),
                  const SizedBox(height: 15),
                  Center(
                      child: Text('ABS Trailer B',
                          style: const TextStyle(
                              fontSize: 14, color: Colors.white),
                          textAlign: TextAlign.center)),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomRadioButton(
                        label: 'Yes',
                        value: 'yes',
                        groupValue: _absDoubleAxle,
                        onChanged: (value) {
                          setState(() {
                            _absDoubleAxle = value ?? 'yes';
                          });
                        },
                      ),
                      const SizedBox(width: 15),
                      CustomRadioButton(
                        label: 'No',
                        value: 'no',
                        groupValue: _absDoubleAxle,
                        onChanged: (value) {
                          setState(() {
                            _absDoubleAxle = value ?? 'no';
                          });
                        },
                      ),
                    ],
                  ),
                  const Text(
                    'NATIS Document for Double Axle',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      if (_natisDoubleAxleDocFile != null) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('NATIS Document'),
                            content: const Text(
                                'What would you like to do with the file?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _pickImageOrFile(
                                    title:
                                        'Change NATIS Document for Double Axle',
                                    pickImageOnly: false,
                                    callback: (file, fileName) {
                                      if (file != null) {
                                        setState(() {
                                          _natisDoubleAxleDocFile = file;
                                          _natisDoubleAxleDocFileName =
                                              fileName;
                                        });
                                      }
                                    },
                                  );
                                },
                                child: const Text('Change File'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _natisDoubleAxleDocFile = null;
                                    _natisDoubleAxleDocFileName = null;
                                  });
                                },
                                child: const Text('Remove File',
                                    style: TextStyle(color: Colors.red)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        _pickImageOrFile(
                          title: 'Select NATIS Document for Double Axle',
                          pickImageOnly: false,
                          callback: (file, fileName) {
                            if (file != null) {
                              setState(() {
                                _natisDoubleAxleDocFile = file;
                                _natisDoubleAxleDocFileName = fileName;
                              });
                            }
                          },
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(10.0),
                    child: _buildStyledContainer(
                      child: _natisDoubleAxleDocFile == null
                          ? const Column(
                              children: [
                                Icon(Icons.upload_file,
                                    color: Colors.white, size: 50.0),
                                SizedBox(height: 10),
                                Text(
                                  'Upload NATIS Document',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.white70),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Icon(Icons.description,
                                    color: Colors.white, size: 50.0),
                                SizedBox(height: 10),
                                Text(
                                  _natisDoubleAxleDocFileName!.split('/').last,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle('Front Image', _frontImage,
                      (img) => setState(() => _frontImage = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle('Side Image', _sideImage,
                      (img) => setState(() => _sideImage = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle('Chassis Image', _chassisImage,
                      (img) => setState(() => _chassisImage = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle(
                      'Hooking Pin Image',
                      _hookingPinDoubleAxleImage,
                      (img) =>
                          setState(() => _hookingPinDoubleAxleImage = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle('Deck Image', _deckImage,
                      (img) => setState(() => _deckImage = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle(
                      'Roof Image (if applicable)',
                      _roofDoubleAxleImage,
                      (img) => setState(() => _roofDoubleAxleImage = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle(
                      'Tyres Image',
                      _tyresDoubleAxleImage,
                      (img) => setState(() => _tyresDoubleAxleImage = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle(
                      'Tail Board Image',
                      _tailBoardDoubleAxleImage,
                      (img) => setState(() => _tailBoardDoubleAxleImage = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle(
                      'Spare Wheel Image',
                      _spareWheelDoubleAxleImage,
                      (img) =>
                          setState(() => _spareWheelDoubleAxleImage = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle(
                      'Landing Legs Image',
                      _landingLegsDoubleAxleImage,
                      (img) =>
                          setState(() => _landingLegsDoubleAxleImage = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle(
                      'Hose and Electrical Cable Image',
                      _hoseAndElecCableDoubleAxleImage,
                      (img) => setState(
                          () => _hoseAndElecCableDoubleAxleImage = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle(
                      'Brakes Axle 1 Image',
                      _brakesAxle1DoubleAxleImage,
                      (img) =>
                          setState(() => _brakesAxle1DoubleAxleImage = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle(
                      'Brakes Axle 2 Image',
                      _brakesAxle2DoubleAxleImage,
                      (img) =>
                          setState(() => _brakesAxle2DoubleAxleImage = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle(
                      'Axle 1 Image',
                      _axle1DoubleAxleImage,
                      (img) => setState(() => _axle1DoubleAxleImage = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle(
                      'Axle 2 Image',
                      _axle2DoubleAxleImage,
                      (img) => setState(() => _axle2DoubleAxleImage = img)),
                  const SizedBox(height: 15),
                  _buildAdditionalImagesSection(),
                  const SizedBox(height: 15),
                ],
                const SizedBox(height: 15),
                const Text(
                  'SERVICE HISTORY (IF ANY)',
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                InkWell(
                  onTap: () {
                    if (_serviceHistoryFile != null) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Service History'),
                          content: const Text(
                              'What would you like to do with the file?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _pickImageOrFile(
                                  title: 'Select Service History',
                                  pickImageOnly: false,
                                  callback: (file, fileName) {
                                    if (file != null) {
                                      setState(() {
                                        _serviceHistoryFile = file;
                                        _serviceHistoryFileName = fileName;
                                      });
                                    }
                                  },
                                );
                              },
                              child: const Text('Change File'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  _serviceHistoryFile = null;
                                });
                              },
                              child: const Text('Remove File',
                                  style: TextStyle(color: Colors.red)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      _pickImageOrFile(
                        title: 'Select Service History',
                        pickImageOnly: false,
                        callback: (file, fileName) {
                          if (file != null) {
                            setState(() {
                              _serviceHistoryFile = file;
                              _serviceHistoryFileName = fileName;
                            });
                          }
                        },
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(10.0),
                  child: _buildStyledContainer(
                    child: _serviceHistoryFile == null
                        ? const Column(
                            children: [
                              Icon(Icons.drive_folder_upload_outlined,
                                  color: Colors.white, size: 50.0),
                              SizedBox(height: 10),
                              Text(
                                'Upload Service History',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              const Icon(Icons.description,
                                  color: Colors.white, size: 50.0),
                              const SizedBox(height: 10),
                              Text(
                                _serviceHistoryFileName!.split('/').last,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Are there any damages?',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomRadioButton(
                      label: 'Yes',
                      value: 'yes',
                      groupValue: _damagesCondition,
                      onChanged: (val) {
                        setState(() {
                          _damagesCondition = val ?? 'no';
                          if (_damagesCondition == 'yes' &&
                              _damageList.isEmpty) {
                            _damageList.add({'description': '', 'image': null});
                          } else if (_damagesCondition == 'no') {
                            _damageList.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 20),
                    CustomRadioButton(
                      label: 'No',
                      value: 'no',
                      groupValue: _damagesCondition,
                      onChanged: (val) {
                        setState(() {
                          _damagesCondition = val ?? 'no';
                          if (_damagesCondition == 'no') {
                            _damageList.clear();
                          } else if (_damageList.isEmpty) {
                            _damageList.add({'description': '', 'image': null});
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                if (_damagesCondition == 'yes') _buildDamageSection(),
                const SizedBox(height: 20),
                const Text(
                  'Are there any additional features?',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomRadioButton(
                      label: 'Yes',
                      value: 'yes',
                      groupValue: _featuresCondition,
                      onChanged: (val) {
                        setState(() {
                          _featuresCondition = val ?? 'no';
                          if (_featuresCondition == 'yes' &&
                              _featureList.isEmpty) {
                            _featureList
                                .add({'description': '', 'image': null});
                          } else if (_featuresCondition == 'no') {
                            _featureList.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 20),
                    CustomRadioButton(
                      label: 'No',
                      value: 'no',
                      groupValue: _featuresCondition,
                      onChanged: (val) {
                        setState(() {
                          _featuresCondition = val ?? 'no';
                          if (_featuresCondition == 'no') {
                            _featureList.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                if (_featuresCondition == 'yes')
                  _buildAdditionalFeaturesSection(),
                _buildDoneButton(),
                const SizedBox(height: 30),
              ],
            ]
          ])),
    );
  }

  Widget _buildImageSectionWithTitle(
      String title, Uint8List? image, Function(Uint8List?) onImagePicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () {
            if (image != null) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(title),
                  content: Text('What would you like to do with this image?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _pickImageOrFile(
                          title: 'Change $title',
                          pickImageOnly: true,
                          callback: (file, fileName) {
                            if (file != null) onImagePicked(file);
                          },
                        );
                      },
                      child: const Text('Change Image'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onImagePicked(null);
                      },
                      child: const Text('Remove Image',
                          style: TextStyle(color: Colors.red)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              );
            } else {
              _pickImageOrFile(
                title: title,
                pickImageOnly: true,
                callback: (file, fileName) {
                  if (file != null) onImagePicked(file);
                },
              );
            }
          },
          borderRadius: BorderRadius.circular(10.0),
          child: _buildStyledContainer(
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.memory(image,
                        fit: BoxFit.cover, height: 150, width: double.infinity),
                  )
                : const Column(
                    children: [
                      Icon(Icons.camera_alt, color: Colors.white, size: 50.0),
                      SizedBox(height: 10),
                      Text('Tap to upload image',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                          textAlign: TextAlign.center),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Images',
          style: TextStyle(
              fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        for (int i = 0; i < _additionalImagesList.length; i++)
          _buildItemWidget(i, _additionalImagesList[i], _additionalImagesList,
              (item) => _showAdditionalImageSourceDialog(item)),
        const SizedBox(height: 16.0),
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _additionalImagesList.add({'description': '', 'image': null});
              });
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.blue, size: 30.0),
                SizedBox(width: 8.0),
                Text('Add Additional Item',
                    style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalImagesSectionForTrailerA() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Images - Trailer A',
          style: TextStyle(
              fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        for (int i = 0; i < _additionalImagesListTrailerA.length; i++)
          _buildItemWidget(
              i,
              _additionalImagesListTrailerA[i],
              _additionalImagesListTrailerA,
              (item) => _showAdditionalImageSourceDialogForTrailerA(item)),
        const SizedBox(height: 16.0),
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _additionalImagesListTrailerA
                    .add({'description': '', 'image': null});
              });
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.blue, size: 30.0),
                SizedBox(width: 8.0),
                Text('Add Additional Image for Trailer A',
                    style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalImagesSectionForTrailerB() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Images - Trailer B',
          style: TextStyle(
              fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        for (int i = 0; i < _additionalImagesListTrailerB.length; i++)
          _buildItemWidget(
              i,
              _additionalImagesListTrailerB[i],
              _additionalImagesListTrailerB,
              (item) => _showAdditionalImageSourceDialogForTrailerB(item)),
        const SizedBox(height: 16.0),
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _additionalImagesListTrailerB
                    .add({'description': '', 'image': null});
              });
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.blue, size: 30.0),
                SizedBox(width: 8.0),
                Text('Add Additional Image for Trailer B',
                    style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemWidget(
      int index,
      Map<String, dynamic> item,
      List<Map<String, dynamic>> itemList,
      void Function(Map<String, dynamic>) showImageSourceDialog) {
    if (item['controller'] == null) {
      item['controller'] =
          TextEditingController(text: item['description'] ?? '');
    }
    final TextEditingController descController = item['controller'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: descController,
          hintText: 'Describe the item',
          onChanged: (val) {
            setState(() {
              item['description'] = val;
            });
          },
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => showImageSourceDialog(item),
          borderRadius: BorderRadius.circular(10.0),
          child: _buildStyledContainer(
            child: item['image'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.memory(item['image'],
                        fit: BoxFit.cover, height: 150, width: double.infinity),
                  )
                : const Column(
                    children: [
                      Icon(Icons.camera_alt, color: Colors.white, size: 50.0),
                      SizedBox(height: 10),
                      Text('Tap to upload image',
                          style: TextStyle(fontSize: 14, color: Colors.white70),
                          textAlign: TextAlign.center),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                itemList.removeAt(index);
              });
            },
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            label: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ),
      ],
    );
  }

  void _showAdditionalImageSourceDialog(Map<String, dynamic> item) {
    if (item['image'] != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Additional Image'),
          content: const Text('What would you like to do with this image?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImageOrFile(
                  title: 'Change Additional Image',
                  pickImageOnly: true,
                  callback: (file, fileName) {
                    if (file != null) {
                      setState(() {
                        item['image'] = file;
                      });
                    }
                  },
                );
              },
              child: const Text('Change Image'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  item['image'] = null;
                });
              },
              child: const Text('Remove Image',
                  style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } else {
      _pickImageOrFile(
        title: 'Additional Image',
        pickImageOnly: true,
        callback: (file, fileName) {
          if (file != null) {
            setState(() {
              item['image'] = file;
            });
          }
        },
      );
    }
  }

  void _showAdditionalImageSourceDialogForTrailerA(Map<String, dynamic> item) {
    if (item['image'] != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Additional Image - Trailer A'),
          content: const Text('What would you like to do with this image?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImageOrFile(
                  title: 'Change Additional Image - Trailer A',
                  pickImageOnly: true,
                  callback: (file, fileName) {
                    if (file != null) {
                      setState(() {
                        item['image'] = file;
                      });
                    }
                  },
                );
              },
              child: const Text('Change Image'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  item['image'] = null;
                });
              },
              child: const Text('Remove Image',
                  style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } else {
      _pickImageOrFile(
        title: 'Additional Image - Trailer A',
        pickImageOnly: true,
        callback: (file, fileName) {
          if (file != null) {
            setState(() {
              item['image'] = file;
            });
          }
        },
      );
    }
  }

  void _showAdditionalImageSourceDialogForTrailerB(Map<String, dynamic> item) {
    if (item['image'] != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Additional Image - Trailer B'),
          content: const Text('What would you like to do with this image?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImageOrFile(
                  title: 'Change Additional Image - Trailer B',
                  pickImageOnly: true,
                  callback: (file, fileName) {
                    if (file != null) {
                      setState(() {
                        item['image'] = file;
                      });
                    }
                  },
                );
              },
              child: const Text('Change Image'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  item['image'] = null;
                });
              },
              child: const Text('Remove Image',
                  style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } else {
      _pickImageOrFile(
        title: 'Additional Image - Trailer B',
        pickImageOnly: true,
        callback: (file, fileName) {
          if (file != null) {
            setState(() {
              item['image'] = file;
            });
          }
        },
      );
    }
  }

  Widget _buildDamageSection() {
    return _buildItemSection(
      title: 'List Current Damages',
      items: _damageList,
      onAdd: () {
        setState(() {
          _damageList.add({'description': '', 'image': null});
        });
      },
      showImageSourceDialog: _showDamageImageSourceDialog,
    );
  }

  Widget _buildFeaturesSection() {
    return _buildItemSection(
      title: 'Additional Features',
      items: _featureList,
      onAdd: () {
        setState(() {
          _featureList.add({'description': '', 'image': null});
        });
      },
      showImageSourceDialog: _showFeatureImageSourceDialog,
    );
  }

  Widget _buildItemSection({
    required String title,
    required List<Map<String, dynamic>> items,
    required VoidCallback onAdd,
    required void Function(Map<String, dynamic>) showImageSourceDialog,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < items.length; i++)
          _buildItemWidget(i, items[i], items, showImageSourceDialog),
        const SizedBox(height: 10),
        Center(
          child: GestureDetector(
            onTap: onAdd,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.blue, size: 30.0),
                SizedBox(width: 8.0),
                Text('Add Additional Item',
                    style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDamageImageSourceDialog(Map<String, dynamic> item) {
    if (item['image'] != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Damage Image'),
          content: const Text('What would you like to do with this image?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImageOrFile(
                  title: 'Change Damage Image',
                  pickImageOnly: true,
                  callback: (file, fileName) {
                    if (file != null) {
                      setState(() {
                        item['image'] = file;
                      });
                    }
                  },
                );
              },
              child: const Text('Change Image'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  item['image'] = null;
                });
              },
              child: const Text('Remove Image',
                  style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } else {
      _pickImageOrFile(
        title: 'Damage Image',
        pickImageOnly: true,
        callback: (file, fileName) {
          if (file != null) {
            setState(() {
              item['image'] = file;
            });
          }
        },
      );
    }
  }

  void _showFeatureImageSourceDialog(Map<String, dynamic> item) {
    if (item['image'] != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Feature Image'),
          content: const Text('What would you like to do with this image?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImageOrFile(
                  title: 'Change Feature Image',
                  pickImageOnly: true,
                  callback: (file, fileName) {
                    if (file != null) {
                      setState(() {
                        item['image'] = file;
                      });
                    }
                  },
                );
              },
              child: const Text('Change Image'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  item['image'] = null;
                });
              },
              child: const Text('Remove Image',
                  style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } else {
      _pickImageOrFile(
        title: 'Feature Image',
        pickImageOnly: true,
        callback: (file, fileName) {
          if (file != null) {
            setState(() {
              item['image'] = file;
            });
          }
        },
      );
    }
  }

  Widget _buildDoneButton() {
    return Center(
      child: CustomButton(
        text: 'Done',
        borderColor: AppColors.orange,
        onPressed: _saveDataAndFinish,
      ),
    );
  }

  Future<void> _saveDataAndFinish() async {
    if (widget.isAdminUpload &&
        (_selectedSalesRep == null || _selectedSalesRep!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a Sales Rep')));
      return;
    }
    if (_selectedTrailerType == 'Double Axle' &&
        _lengthDoubleAxleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the length')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final formData = Provider.of<FormDataProvider>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;

      String? assignedTransporterId = widget.transporterId ?? currentUser?.uid;
      String? assignedSalesRepId;
      if (widget.isAdminUpload) {
        assignedSalesRepId = _selectedSalesRep;
      } else {
        assignedSalesRepId = currentUser?.uid;
      }

      if (_selectedMainImage != null) {
        formData.setSelectedMainImage(_selectedMainImage, "MainImage");
      }
      if (!_validateRequiredFields(formData)) {
        setState(() => _isLoading = false);
        return;
      }
      Map<String, String?> commonUrls = await _uploadCommonFiles();
      Map<String, dynamic> trailerExtraInfo = await _buildTrailerTypeData();

      final Map<String, dynamic> trailerData = {
        'trailerType': _selectedTrailerType,
        'vehicleType': 'trailer',
        'mainImageUrl': commonUrls['mainImageUrl'] ?? '',
        'serviceHistoryUrl': commonUrls['serviceHistoryUrl'] ?? '',
        'trailerExtraInfo': trailerExtraInfo,
        // Add these fields for damages
        'damagesCondition': _damagesCondition,
        'damages': await _uploadListItems(_damageList),
        'featuresCondition': _featuresCondition,
        'features': await _uploadListItems(_featureList),
        'transporterId': assignedTransporterId,
        'assignedSalesRepId': assignedSalesRepId,
        'userId': currentUser?.uid,
        'registrationNumber': formData.registrationNumber,
        'vehicleStatus': 'Draft',
        'listingStatus': 'Active',
        'isApproved': false,
        'isFeatured': false,
        'isSold': false,
        'isArchived': false,
        'viewCount': 0,
        'savedCount': 0,
        'inquiryCount': 0,
        'country': formData.country,
        'province': formData.province,
        'referenceNumber': _referenceNumberController.text,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': currentUser?.uid,
        'adminData': {
          'settlementAmount': _sellingPriceController.text,
          'requireSettlement': false,
          'isSettled': false,
          'settlementDate': null,
          'settlementBy': null,
        },
      };

      final docRef = FirebaseFirestore.instance.collection('vehicles').doc();
      await docRef.set(trailerData);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trailer created successfully')));
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error saving trailer: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _buildTrailerTypeData() async {
    final formData = Provider.of<FormDataProvider>(context, listen: false);

    switch (_selectedTrailerType) {
      case 'Superlink':
        return {
          'trailerA': {
            'make': _makeTrailerAController.text,
            'model': _modelTrailerAController.text,
            'year': _yearTrailerAController.text,
            'length': _lengthTrailerAController.text,
            'vin': _vinAController.text,
            'registration': _registrationAController.text,
            'axles': _axlesTrailerAController.text,
            'suspension': formData.suspensionA ??
                'air', // Changed to use FormDataProvider
            'licenseExp': _licenceDiskExpTrailerAController.text,
            'abs': formData.absA ?? 'no', // Changed to use FormDataProvider
            'natisDoc1Url': _natisTrailerADoc1File != null
                ? await _uploadFileToFirebaseStorage(
                    _natisTrailerADoc1File!, 'vehicle_documents')
                : '',
            'frontImageUrl': _frontImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _frontImageA!, 'vehicle_images')
                : '',
            'sideImageUrl': _sideImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _sideImageA!, 'vehicle_images')
                : '',
            'tyresImageUrl': _tyresImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _tyresImageA!, 'vehicle_images')
                : '',
            'chassisImageUrl': _chassisImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _chassisImageA!, 'vehicle_images')
                : '',
            'deckImageUrl': _deckImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _deckImageA!, 'vehicle_images')
                : '',
            'makersPlateImageUrl': _makersPlateImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _makersPlateImageA!, 'vehicle_images')
                : '',
            'hookPinImageUrl': _hookPinImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _hookPinImageA!, 'vehicle_images')
                : '',
            'roofImageUrl': _roofImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _roofImageA!, 'vehicle_images')
                : '',
            'tailBoardImageUrl': _tailBoardImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _tailBoardImageA!, 'vehicle_images')
                : '',
            'spareWheelImageUrl': _spareWheelImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _spareWheelImageA!, 'vehicle_images')
                : '',
            'landingLegImageUrl': _landingLegImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _landingLegImageA!, 'vehicle_images')
                : '',
            'hoseAndElecticalCableImageUrl':
                _hoseAndElecticalCableImageA != null
                    ? await _uploadFileToFirebaseStorage(
                        _hoseAndElecticalCableImageA!, 'vehicle_images')
                    : '',
            'brakesAxle1ImageUrl': _brakesAxle1ImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _brakesAxle1ImageA!, 'vehicle_images')
                : '',
            'brakesAxle2ImageUrl': _brakesAxle2ImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _brakesAxle2ImageA!, 'vehicle_images')
                : '',
            'axle1ImageUrl': _axle1ImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _axle1ImageA!, 'vehicle_images')
                : '',
            'axle2ImageUrl': _axle2ImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _axle2ImageA!, 'vehicle_images')
                : '',
            'trailerAAdditionalImages':
                await _uploadListItems(_additionalImagesListTrailerA),
          },
          'trailerB': {
            'make': _makeTrailerBController.text,
            'model': _modelTrailerBController.text,
            'year': _yearTrailerBController.text,
            'length': _lengthTrailerBController.text,
            'vin': _vinBController.text,
            'registration': _registrationBController.text,
            'axles': _axlesTrailerBController.text,
            'suspension': formData.suspensionB ??
                'air', // Changed to use FormDataProvider
            'licenseExp': _licenceDiskExpTrailerBController.text,
            'abs': formData.absB ?? 'no', // Changed to use FormDataProvider
            'natisDoc1Url': _natisTrailerBDoc1File != null
                ? await _uploadFileToFirebaseStorage(
                    _natisTrailerBDoc1File!, 'vehicle_documents')
                : '',
            'frontImageUrl': _frontImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _frontImageB!, 'vehicle_images')
                : '',
            'sideImageUrl': _sideImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _sideImageB!, 'vehicle_images')
                : '',
            'tyresImageUrl': _tyresImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _tyresImageB!, 'vehicle_images')
                : '',
            'chassisImageUrl': _chassisImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _chassisImageB!, 'vehicle_images')
                : '',
            'deckImageUrl': _deckImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _deckImageB!, 'vehicle_images')
                : '',
            'makersPlateImageUrl': _makersPlateImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _makersPlateImageB!, 'vehicle_images')
                : '',
            'hookPinImageUrl': _hookPinImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _hookPinImageB!, 'vehicle_images')
                : '',
            'roofImageUrl': _roofImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _roofImageB!, 'vehicle_images')
                : '',
            'tailBoardImageUrl': _tailBoardImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _tailBoardImageB!, 'vehicle_images')
                : '',
            'spareWheelImageUrl': _spareWheelImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _spareWheelImageB!, 'vehicle_images')
                : '',
            'landingLegImageUrl': _landingLegImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _landingLegImageB!, 'vehicle_images')
                : '',
            'hoseAndElecticalCableImageUrl':
                _hoseAndElecticalCableImageB != null
                    ? await _uploadFileToFirebaseStorage(
                        _hoseAndElecticalCableImageB!, 'vehicle_images')
                    : '',
            'brakesAxle1ImageUrl': _brakesAxle1ImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _brakesAxle1ImageB!, 'vehicle_images')
                : '',
            'brakesAxle2ImageUrl': _brakesAxle2ImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _brakesAxle2ImageB!, 'vehicle_images')
                : '',
            'axle1ImageUrl': _axle1ImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _axle1ImageB!, 'vehicle_images')
                : '',
            'axle2ImageUrl': _axle2ImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _axle2ImageB!, 'vehicle_images')
                : '',
            'trailerBAdditionalImages':
                await _uploadListItems(_additionalImagesListTrailerB),
          },
        };
      case 'Tri-Axle':
        return {
          'lengthTrailer': _lengthTrailerController.text,
          'length': _lengthTrailerController.text, // Add for compatibility
          'vin': _vinController.text,
          'registration': _registrationController.text,

          // Add these missing fields for Tri-Axle
          'make': _makeController.text,
          'model': _modelController.text,
          'year': _yearController.text,
          'licenseExp': _licenseExpController.text,
          'numbAxel': _numbAxelController.text,
          'axles':
              _axlesController.text, // For compatibility with both field names
          'suspension': formData.suspensionA ?? _suspensionTriAxle,
          'abs': formData.absA ?? _absTriAxle,

          'natisDocUrl': _natisTriAxleDocFile != null
              ? await _uploadFileToFirebaseStorage(
                  _natisTriAxleDocFile!, 'vehicle_documents')
              : '',
          'frontImageUrl': _frontImage != null
              ? await _uploadFileToFirebaseStorage(
                  _frontImage!, 'vehicle_images')
              : '',
          'sideImageUrl': _sideImage != null
              ? await _uploadFileToFirebaseStorage(
                  _sideImage!, 'vehicle_images')
              : '',
          'tyresImageUrl': _tyresImage != null
              ? await _uploadFileToFirebaseStorage(
                  _tyresImage!, 'vehicle_images')
              : '',
          'chassisImageUrl': _chassisImage != null
              ? await _uploadFileToFirebaseStorage(
                  _chassisImage!, 'vehicle_images')
              : '',
          'deckImageUrl': _deckImage != null
              ? await _uploadFileToFirebaseStorage(
                  _deckImage!, 'vehicle_images')
              : '',
          'makersPlateImageUrl': _makersPlateImage != null
              ? await _uploadFileToFirebaseStorage(
                  _makersPlateImage!, 'vehicle_images')
              : '',

          // Add all the additional Tri-Axle specific images
          'hookpinImageUrl': _hookpinImage != null
              ? await _uploadFileToFirebaseStorage(
                  _hookpinImage!, 'vehicle_images')
              : '',
          'roofImageUrl': _roofImage != null
              ? await _uploadFileToFirebaseStorage(
                  _roofImage!, 'vehicle_images')
              : '',
          'tailboardImageUrl': _tailboardImage != null
              ? await _uploadFileToFirebaseStorage(
                  _tailboardImage!, 'vehicle_images')
              : '',
          'spareWheelImageUrl': _spareWheelImage != null
              ? await _uploadFileToFirebaseStorage(
                  _spareWheelImage!, 'vehicle_images')
              : '',
          'landingLegsImageUrl': _landingLegsImage != null
              ? await _uploadFileToFirebaseStorage(
                  _landingLegsImage!, 'vehicle_images')
              : '',
          'hoseAndElectricCableImageUrl': _hoseAndElctricCableImage != null
              ? await _uploadFileToFirebaseStorage(
                  _hoseAndElctricCableImage!, 'vehicle_images')
              : '',
          'brakeAxel1ImageUrl': _brakeAxel1Image != null
              ? await _uploadFileToFirebaseStorage(
                  _brakeAxel1Image!, 'vehicle_images')
              : '',
          'brakeAxel2ImageUrl': _brakeAxel2Image != null
              ? await _uploadFileToFirebaseStorage(
                  _brakeAxel2Image!, 'vehicle_images')
              : '',
          'brakeAxel3ImageUrl': _brakeAxel3Image != null
              ? await _uploadFileToFirebaseStorage(
                  _brakeAxel3Image!, 'vehicle_images')
              : '',
          'axel1ImageUrl': _axel1Image != null
              ? await _uploadFileToFirebaseStorage(
                  _axel1Image!, 'vehicle_images')
              : '',
          'axle2ImageUrl': _axel2Image != null
              ? await _uploadFileToFirebaseStorage(
                  _axel2Image!, 'vehicle_images')
              : '',
          'axle3ImageUrl': _axel3Image != null
              ? await _uploadFileToFirebaseStorage(
                  _axel3Image!, 'vehicle_images')
              : '',
          'licenseDiskImageUrl': _licenseDiskImage != null
              ? await _uploadFileToFirebaseStorage(
                  _licenseDiskImage!, 'vehicle_images')
              : '',

          'additionalImages': await _uploadListItems(_additionalImagesList),
        };
      case 'Double Axle':
        return {
          'make': _makeDoubleAxleController.text,
          'model': _modelDoubleAxleController.text,
          'year': _yearDoubleAxleController.text,
          'lengthTrailer': _lengthDoubleAxleController.text,
          'length': _lengthDoubleAxleController.text, // Add for compatibility
          'vin': _vinController.text,
          'registration': _registrationController.text,
          'licenseExp': _licenceDiskExpDoubleAxleController.text,
          'numbAxel': _numbAxelDoubleAxleController.text,
          'axles': _numbAxelDoubleAxleController
              .text, // For compatibility with both field names
          'suspension': _suspensionDoubleAxle,
          'abs': _absDoubleAxle,

          'natisDocUrl': _natisDoubleAxleDocFile != null
              ? await _uploadFileToFirebaseStorage(
                  _natisDoubleAxleDocFile!, 'vehicle_documents')
              : '',
          'frontImageUrl': _frontImage != null
              ? await _uploadFileToFirebaseStorage(
                  _frontImage!, 'vehicle_images')
              : '',
          'sideImageUrl': _sideImage != null
              ? await _uploadFileToFirebaseStorage(
                  _sideImage!, 'vehicle_images')
              : '',
          'chassisImageUrl': _chassisImage != null
              ? await _uploadFileToFirebaseStorage(
                  _chassisImage!, 'vehicle_images')
              : '',
          'deckImageUrl': _deckImage != null
              ? await _uploadFileToFirebaseStorage(
                  _deckImage!, 'vehicle_images')
              : '',
          'makersPlateImageUrl': _makersPlateDblAxleImage != null
              ? await _uploadFileToFirebaseStorage(
                  _makersPlateDblAxleImage!, 'vehicle_images')
              : '',
          'tyresImageUrl': _tyresDoubleAxleImage != null
              ? await _uploadFileToFirebaseStorage(
                  _tyresDoubleAxleImage!, 'vehicle_images')
              : '',

          // Double Axle specific image URLs
          'hookingPinImageUrl': _hookingPinDoubleAxleImage != null
              ? await _uploadFileToFirebaseStorage(
                  _hookingPinDoubleAxleImage!, 'vehicle_images')
              : '',
          'roofImageUrl': _roofDoubleAxleImage != null
              ? await _uploadFileToFirebaseStorage(
                  _roofDoubleAxleImage!, 'vehicle_images')
              : '',
          'tailBoardImageUrl': _tailBoardDoubleAxleImage != null
              ? await _uploadFileToFirebaseStorage(
                  _tailBoardDoubleAxleImage!, 'vehicle_images')
              : '',
          'spareWheelImageUrl': _spareWheelDoubleAxleImage != null
              ? await _uploadFileToFirebaseStorage(
                  _spareWheelDoubleAxleImage!, 'vehicle_images')
              : '',
          'landingLegsImageUrl': _landingLegsDoubleAxleImage != null
              ? await _uploadFileToFirebaseStorage(
                  _landingLegsDoubleAxleImage!, 'vehicle_images')
              : '',
          'hoseAndElectricCableImageUrl':
              _hoseAndElecCableDoubleAxleImage != null
                  ? await _uploadFileToFirebaseStorage(
                      _hoseAndElecCableDoubleAxleImage!, 'vehicle_images')
                  : '',
          'brakesAxle1ImageUrl': _brakesAxle1DoubleAxleImage != null
              ? await _uploadFileToFirebaseStorage(
                  _brakesAxle1DoubleAxleImage!, 'vehicle_images')
              : '',
          'brakesAxle2ImageUrl': _brakesAxle2DoubleAxleImage != null
              ? await _uploadFileToFirebaseStorage(
                  _brakesAxle2DoubleAxleImage!, 'vehicle_images')
              : '',
          'axle1ImageUrl': _axle1DoubleAxleImage != null
              ? await _uploadFileToFirebaseStorage(
                  _axle1DoubleAxleImage!, 'vehicle_images')
              : '',
          'axle2ImageUrl': _axle2DoubleAxleImage != null
              ? await _uploadFileToFirebaseStorage(
                  _axle2DoubleAxleImage!, 'vehicle_images')
              : '',
          'licenseDiskImageUrl': _licenseDiskDoubleAxleImage != null
              ? await _uploadFileToFirebaseStorage(
                  _licenseDiskDoubleAxleImage!, 'vehicle_images')
              : '',

          'additionalImages': await _uploadListItems(_additionalImagesList),
        };
      case 'Other':
        int axleCount = 0;
        try {
          axleCount = int.parse(_numbAxelOtherController.text);
        } catch (e) {
          axleCount = 0;
        }

        // Upload brake and axle images
        List<String> brakesAxleImageUrls = [];
        List<String> axleImageUrls = [];

        for (int i = 0; i < axleCount; i++) {
          if (_brakesAxleOtherImages[i] != null) {
            String? url = await _uploadFileToFirebaseStorage(
                _brakesAxleOtherImages[i]!, 'vehicle_images');
            brakesAxleImageUrls.add(url ?? '');
          } else {
            brakesAxleImageUrls.add('');
          }

          if (_axleOtherImages[i] != null) {
            String? url = await _uploadFileToFirebaseStorage(
                _axleOtherImages[i]!, 'vehicle_images');
            axleImageUrls.add(url ?? '');
          } else {
            axleImageUrls.add('');
          }
        }

        return {
          'make': _makeOtherController.text,
          'model': _modelOtherController.text,
          'year': _yearOtherController.text,
          'length': _lengthOtherController.text,
          'vin': _vinOtherController.text,
          'registration': _registrationOtherController.text,
          'licenseExp': _licenceDiskExpOtherController.text,
          'numbAxel': _numbAxelOtherController.text,
          'axles': _numbAxelOtherController.text, // For compatibility
          'suspension': _suspensionOther,
          'abs': _absOther,

          'natisDocUrl': _natisOtherDocFile != null
              ? await _uploadFileToFirebaseStorage(
                  _natisOtherDocFile!, 'vehicle_documents')
              : '',
          'frontImageUrl': _frontOtherImage != null
              ? await _uploadFileToFirebaseStorage(
                  _frontOtherImage!, 'vehicle_images')
              : '',
          'sideImageUrl': _sideOtherImage != null
              ? await _uploadFileToFirebaseStorage(
                  _sideOtherImage!, 'vehicle_images')
              : '',
          'chassisImageUrl': _chassisOtherImage != null
              ? await _uploadFileToFirebaseStorage(
                  _chassisOtherImage!, 'vehicle_images')
              : '',
          'hookingPinImageUrl': _hookingPinOtherImage != null
              ? await _uploadFileToFirebaseStorage(
                  _hookingPinOtherImage!, 'vehicle_images')
              : '',
          'deckImageUrl': _deckOtherImage != null
              ? await _uploadFileToFirebaseStorage(
                  _deckOtherImage!, 'vehicle_images')
              : '',
          'roofImageUrl': _roofOtherImage != null
              ? await _uploadFileToFirebaseStorage(
                  _roofOtherImage!, 'vehicle_images')
              : '',
          'tyresImageUrl': _tyresOtherImage != null
              ? await _uploadFileToFirebaseStorage(
                  _tyresOtherImage!, 'vehicle_images')
              : '',
          'tailBoardImageUrl': _tailBoardOtherImage != null
              ? await _uploadFileToFirebaseStorage(
                  _tailBoardOtherImage!, 'vehicle_images')
              : '',
          'spareWheelImageUrl': _spareWheelOtherImage != null
              ? await _uploadFileToFirebaseStorage(
                  _spareWheelOtherImage!, 'vehicle_images')
              : '',
          'landingLegsImageUrl': _landingLegsOtherImage != null
              ? await _uploadFileToFirebaseStorage(
                  _landingLegsOtherImage!, 'vehicle_images')
              : '',
          'hoseAndElectricCableImageUrl': _hoseAndElecCableOtherImage != null
              ? await _uploadFileToFirebaseStorage(
                  _hoseAndElecCableOtherImage!, 'vehicle_images')
              : '',
          'licenseDiskImageUrl': _licenseDiskOtherImage != null
              ? await _uploadFileToFirebaseStorage(
                  _licenseDiskOtherImage!, 'vehicle_images')
              : '',
          'makersPlateImageUrl': _makersPlateOtherImage != null
              ? await _uploadFileToFirebaseStorage(
                  _makersPlateOtherImage!, 'vehicle_images')
              : '',

          'brakesAxleImageUrls': brakesAxleImageUrls,
          'axleImageUrls': axleImageUrls,

          'additionalImages': await _uploadListItems(_additionalImagesList),
        };

      default:
        return {};
    }
  }

  Future<Map<String, String?>> _uploadCommonFiles() async {
    Map<String, String?> urls = {};
    if (_selectedMainImage != null) {
      urls['mainImageUrl'] = await _uploadFileToFirebaseStorage(
          _selectedMainImage!, 'vehicle_images');
    }
    if (_natisRc1File != null) {
      urls['natisUrl'] = await _uploadFileToFirebaseStorage(
          _natisRc1File!, 'vehicle_documents');
    }
    if (_serviceHistoryFile != null) {
      urls['serviceHistoryUrl'] = await _uploadFileToFirebaseStorage(
          _serviceHistoryFile!, 'vehicle_documents');
    }
    return urls;
  }

  Future<List<Map<String, dynamic>>> _uploadListItems(
      List<Map<String, dynamic>> items) async {
    List<Map<String, dynamic>> uploadedItems = [];
    for (var item in items) {
      // Get description from controller first, fallback to description field
      String description = item['controller'] != null
          ? (item['controller'] as TextEditingController).text
          : (item['description'] ?? '');

      Map<String, dynamic> uploadedItem = {
        'description': description,
        'imageUrl': '',
      };
      if (item['image'] != null) {
        String? imageUrl =
            await _uploadFileToFirebaseStorage(item['image'], 'vehicle_images');
        uploadedItem['imageUrl'] = imageUrl ?? '';
      } else if (item['imageUrl'] != null &&
          (item['imageUrl'] as String).isNotEmpty) {
        uploadedItem['imageUrl'] = item['imageUrl'];
      }
      uploadedItems.add(uploadedItem);

      // String imageUrl = '';
      // // if file is present, then upload it
      // if (item['image'] != null) {
      //   imageUrl = await _uploadFileToFirebaseStorage(
      //           item['image'], 'vehicle_images') ??
      //       '';
      //   debugPrint('Uploaded additional image URL: $imageUrl');
      // } else if (item['imageUrl'] != null &&
      //     (item['imageUrl'] as String).isNotEmpty) {
      //   imageUrl = item['imageUrl'];
      // }

      // uploadedItems.add({
      //   'description': description,
      //   'imageUrl': imageUrl,
      // });
    }
    return uploadedItems;
  }

  bool _validateRequiredFields(FormDataProvider formData) {
    if (formData.selectedMainImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add a main image')));
      return false;
    }

    // Validate fields based on trailer type
    switch (_selectedTrailerType) {
      case 'Superlink':
        if (_makeTrailerAController.text.isEmpty ||
            _makeTrailerBController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please enter make for both trailers')));
          return false;
        }

        // Add specific year validation for Superlink
        if (_yearTrailerAController.text.isEmpty ||
            _yearTrailerBController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please enter year for both trailers')));
          return false;
        }

        if (_lengthTrailerAController.text.isEmpty ||
            _vinAController.text.isEmpty ||
            _registrationAController.text.isEmpty ||
            _lengthTrailerBController.text.isEmpty ||
            _vinBController.text.isEmpty ||
            _registrationBController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please complete all Superlink fields')));
          return false;
        }
        break;

      case 'Double Axle':
        // Validate Double Axle specific fields
        if (_makeDoubleAxleController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please enter the make for Double Axle')));
          return false;
        }

        if (_yearDoubleAxleController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please enter the year for Double Axle')));
          return false;
        }

        if (_lengthDoubleAxleController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please enter the length for Double Axle')));
          return false;
        }
        break;

      case 'Tri-Axle':
        // Validate Tri-Axle specific fields
        if (_makeController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please enter the make for Tri-Axle')));
          return false;
        }

        if (_yearController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please enter the year for Tri-Axle')));
          return false;
        }
        break;

      case 'Other':
        // Validate Other specific fields
        if (_makeOtherController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please enter the make for Other Trailer')));
          return false;
        }

        if (_yearOtherController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please enter the year for Other Trailer')));
          return false;
        }

        if (_lengthOtherController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please enter the length for Other Trailer')));
          return false;
        }

        if (_vinOtherController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please enter the VIN for Other Trailer')));
          return false;
        }
        break;

      default:
        // For other trailer types, check general fields
        if (formData.make == null || formData.make!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter the make')));
          return false;
        }

        if (formData.year == null || formData.year!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter the year')));
          return false;
        }
    }

    return true;
  }

  Future<String?> _uploadFileToFirebaseStorage(
      Uint8List file, String folderName) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef =
          FirebaseStorage.instance.ref().child('$folderName/$fileName');
      await storageRef.putData(file);
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint('File upload error: $e');
      return null;
    }
  }

  Future<void> _loadYearOptions() async {
    final String response =
        await rootBundle.loadString('lib/assets/updated_truck_data.json');
    final data = json.decode(response);
    setState(() {
      _yearOptions = (data as Map<String, dynamic>).keys.toList()..sort();
    });
  }

  void _updateProvinceOptions(String selectedCountry) async {
    final String response =
        await rootBundle.loadString('lib/assets/countries.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      final country = data.firstWhere(
          (country) => country['name'] == selectedCountry,
          orElse: () => {'states': []});
      _provinceOptions = (country['states'] as List<dynamic>)
          .map((state) => state['name'] as String)
          .toList();
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

  Widget _buildSalesRepField() {
    if (!widget.isAdminUpload) return const SizedBox.shrink();
    return FutureBuilder<List<Map<String, String>>>(
      future: _getSalesReps(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final salesReps = snapshot.data!;
        String? selectedSalesRepDisplay;
        if (_selectedSalesRep != null) {
          final match = salesReps.firstWhere(
              (rep) => rep['id'] == _selectedSalesRep,
              orElse: () => {});
          selectedSalesRepDisplay = match['display'];
        }
        return Column(
          children: [
            const SizedBox(height: 20),
            CustomDropdown(
              hintText: 'Select Sales Rep',
              value: selectedSalesRepDisplay,
              items: salesReps.map((rep) => rep['display']!).toList(),
              onChanged: (value) {
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
            ),
            const SizedBox(height: 15),
          ],
        );
      },
    );
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

  void _clearAllData(FormDataProvider formData) {
    formData.clearAllData();
    formData.setSelectedMainImage(null, null);
    formData.setMainImageUrl(null);
    formData.setNatisRc1Url(null);
    formData.setYear(null);
    formData.setMakeModel(null);
    formData.setMake(null);
    formData.setVinNumber(null);
    formData.setMileage(null);
    formData.setEngineNumber(null);
    formData.setRegistrationNumber(null);
    formData.setSellingPrice(null);
    formData.setVehicleType('trailer');
    formData.setWarrantyDetails(null);
    formData.setReferenceNumber(null);
    formData.setBrands([]);
    formData.setTrailerType(null);
    formData.setAxles(null);
    formData.setLength(null);

    _clearFormControllers();

    _lengthTrailerAController.clear();
    _vinAController.clear();
    _registrationAController.clear();
    _lengthTrailerBController.clear();
    _vinBController.clear();
    _registrationBController.clear();
    _lengthTrailerController.clear();
    _vinController.clear();
    _registrationController.clear();
    _axlesController.clear();
    _lengthController.clear();
    _lengthDoubleAxleController.clear();
    _scrollController.dispose();
    _makeTrailerAController.clear();
    _modelTrailerAController.clear();
    _yearTrailerAController.clear();
    _makeTrailerBController.clear();
    _modelTrailerBController.clear();
    _yearTrailerBController.clear();
    _licenceDiskExpTrailerAController.clear();
    _modelController.clear();
    _licenseExpController.clear();
    _numbAxelController.clear();
    _makeDoubleAxleController.clear();
    _modelDoubleAxleController.clear();
    _yearDoubleAxleController.clear();
    _licenceDiskExpDoubleAxleController.clear();
    _numbAxelDoubleAxleController.clear();
    _makeOtherController.clear();
    _modelOtherController.clear();
    _yearOtherController.clear();
    _lengthOtherController.clear();
    _vinOtherController.clear();
    _registrationOtherController.clear();
    _licenceDiskExpOtherController.clear();
    _numbAxelOtherController.clear();

    setState(() {
      _selectedMainImage = null;
      _selectedMainImageFileName = null;
      _natisRc1File = null;
      _natisRc1FileName = null;
      _existingNatisRc1Url = null;
      _existingNatisRc1Name = null;
      _serviceHistoryFile = null;
      _serviceHistoryFileName = null;
      _frontImageA = null;
      _sideImageA = null;
      _tyresImageA = null;
      _chassisImageA = null;
      _deckImageA = null;
      _makersPlateImageA = null;
      _additionalImagesListTrailerA.clear();
      _frontImageB = null;
      _sideImageB = null;
      _tyresImageB = null;
      _chassisImageB = null;
      _deckImageB = null;
      _makersPlateImageB = null;
      _additionalImagesListTrailerB.clear();
      _frontImage = null;
      _sideImage = null;
      _tyresImage = null;
      _chassisImage = null;
      _deckImage = null;
      _makersPlateImage = null;
      _additionalImagesList.clear();
      _damagesCondition = 'no';
      _featuresCondition = 'no';
      _damageList.clear();
      _featureList.clear();
      _selectedTrailerType = null;
      _selectedSalesRep = null;
      _selectedTransporter = null;
      _vehicleId = null;
      _isLoading = false;
      _hookPinImageA = null;
      _roofImageA = null;
      _tailBoardImageA = null;
      _spareWheelImageA = null;
      _landingLegImageA = null;
      _hoseAndElecticalCableImageA = null;
      _brakesAxle1ImageA = null;
      _brakesAxle2ImageA = null;
      _axle1ImageA = null;
      _axle2ImageA = null;

      _hookPinImageB = null;
      _roofImageB = null;
      _tailBoardImageB = null;
      _spareWheelImageB = null;
      _landingLegImageB = null;
      _hoseAndElecticalCableImageB = null;
      _brakesAxle1ImageB = null;
      _brakesAxle2ImageB = null;
      _axle1ImageB = null;
      _axle2ImageB = null;
      // Clear Double Axle specific fields
      _hookingPinDoubleAxleImage = null;
      _roofDoubleAxleImage = null;
      _tailBoardDoubleAxleImage = null;
      _spareWheelDoubleAxleImage = null;
      _landingLegsDoubleAxleImage = null;
      _hoseAndElecCableDoubleAxleImage = null;
      _brakesAxle1DoubleAxleImage = null;
      _brakesAxle2DoubleAxleImage = null;
      _axle1DoubleAxleImage = null;
      _axle2DoubleAxleImage = null;
      _licenseDiskDoubleAxleImage = null;
      _makersPlateDblAxleImage = null;
      _tyresDoubleAxleImage = null;

      // Clear Other trailer images
      _frontOtherImage = null;
      _sideOtherImage = null;
      _chassisOtherImage = null;
      _hookingPinOtherImage = null;
      _deckOtherImage = null;
      _roofOtherImage = null;
      _tyresOtherImage = null;
      _tailBoardOtherImage = null;
      _spareWheelOtherImage = null;
      _landingLegsOtherImage = null;
      _hoseAndElecCableOtherImage = null;
      _licenseDiskOtherImage = null;
      _makersPlateOtherImage = null;
      _brakesAxleOtherImages = [];
      _axleOtherImages = [];
      _natisOtherDocFile = null;
      _natisOtherDocFileName = null;
    });
  }

  void _clearFormControllers() {
    _sellingPriceController.clear();
    _vinNumberController.clear();
    _mileageController.clear();
    _engineNumberController.clear();
    _warrantyDetailsController.clear();
    _registrationNumberController.clear();
    _referenceNumberController.clear();
    _makeController.clear();
    _yearController.clear();
    _makeTrailerAController.clear();
    _makeTrailerBController.clear();
    _modelTrailerAController.clear();
    _yearTrailerAController.clear();
    _licenceDiskExpTrailerAController.clear();
    _modelTrailerBController.clear();
    _yearTrailerBController.clear();
    _licenceDiskExpTrailerBController.clear();
    _makeDoubleAxleController.clear();
    _modelDoubleAxleController.clear();
    _yearDoubleAxleController.clear();
    _licenceDiskExpDoubleAxleController.clear();
    _numbAxelDoubleAxleController.clear();
    _makeOtherController.clear();
    _modelOtherController.clear();
    _yearOtherController.clear();
    _lengthOtherController.clear();
    _vinOtherController.clear();
    _registrationOtherController.clear();
    _licenceDiskExpOtherController.clear();
    _numbAxelOtherController.clear();
  }

  void _populateVehicleData() {
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    if (widget.vehicle != null) {
      _existingNatisRc1Url = widget.vehicle!.rc1NatisFile;
      _existingNatisRc1Name = _getFileNameFromUrl(_existingNatisRc1Url);
      formData.setNatisRc1Url(widget.vehicle!.rc1NatisFile, notify: false);
      formData.setVehicleType(widget.vehicle!.vehicleType, notify: false);
      formData.setYear(widget.vehicle!.year, notify: false);
      formData.setMake(widget.vehicle!.makeModel, notify: false);
      formData.setVinNumber(widget.vehicle!.vinNumber, notify: false);
      formData.setMileage(widget.vehicle!.mileage, notify: false);
      formData.setEngineNumber(widget.vehicle!.engineNumber, notify: false);
      formData.setRegistrationNumber(widget.vehicle!.registrationNumber,
          notify: false);
      formData.setSellingPrice(widget.vehicle!.adminData.settlementAmount,
          notify: false);
      formData.setMainImageUrl(widget.vehicle!.mainImageUrl, notify: false);
      formData.setWarrantyDetails(widget.vehicle!.warrantyDetails,
          notify: false);
      formData.setReferenceNumber(widget.vehicle!.referenceNumber,
          notify: false);
      formData.setBrands(widget.vehicle!.brands ?? [], notify: false);
      _selectedTrailerType = widget.vehicle!.trailerType;

      // Separate population logic for each trailer type
      if (_selectedTrailerType == 'Superlink') {
        _populateSuperlinkData(widget.vehicle!);
      } else if (_selectedTrailerType == 'Tri-Axle') {
        _populateTriAxleData(widget.vehicle!);
      } else if (_selectedTrailerType == 'Double Axle') {
        _populateDoubleAxleData(widget.vehicle!);
      }
    }
  }

  void _populateSuperlinkData(Vehicle vehicle) {
    if (vehicle.trailer?.superlinkData != null) {
      final superlinkData = vehicle.trailer!.superlinkData!;

      // Trailer A data
      _makeTrailerAController.text = superlinkData.makeA ?? '';
      _modelTrailerAController.text = superlinkData.modelA ?? '';
      _yearTrailerAController.text = superlinkData.yearA ?? '';
      _lengthTrailerAController.text = superlinkData.lengthA ?? '';
      _vinAController.text = superlinkData.vinA ?? '';
      _registrationAController.text = superlinkData.registrationA ?? '';
      _axlesTrailerAController.text = superlinkData.axlesA ?? '';
      _licenceDiskExpTrailerAController.text =
          superlinkData.licenceDiskExpA ?? '';

      // Trailer B data
      _makeTrailerBController.text = superlinkData.makeB ?? '';
      _modelTrailerBController.text = superlinkData.modelB ?? '';
      _yearTrailerBController.text = superlinkData.yearB ?? '';
      _lengthTrailerBController.text = superlinkData.lengthB ?? '';
      _vinBController.text = superlinkData.vinB ?? '';
      _registrationBController.text = superlinkData.registrationB ?? '';
      _axlesTrailerBController.text = superlinkData.axlesB ?? '';
      _licenceDiskExpTrailerBController.text =
          superlinkData.licenceDiskExpB ?? '';

      // Clear and populate additional images lists
      _additionalImagesListTrailerA.clear();
      _additionalImagesListTrailerA.addAll(superlinkData.additionalImagesA);

      _additionalImagesListTrailerB.clear();
      _additionalImagesListTrailerB.addAll(superlinkData.additionalImagesB);
    }
  }

  void _populateTriAxleData(Vehicle vehicle) {
    if (vehicle.trailer?.triAxleData != null) {
      final triAxleData = vehicle.trailer!.triAxleData!;

      _lengthTrailerController.text = triAxleData.length ?? '';
      _vinController.text = triAxleData.vin ?? '';
      _registrationController.text = triAxleData.registration ?? '';
      _makeController.text = triAxleData.make ?? '';
      _yearController.text = triAxleData.year ?? '';

      // Clear and populate additional images
      _additionalImagesList.clear();
      _additionalImagesList.addAll(triAxleData.additionalImages ?? []);
    }
  }

  void _populateDoubleAxleData(Vehicle vehicle) {
    if (vehicle.trailer?.doubleAxleData != null) {
      final doubleAxleData = vehicle.trailer!.doubleAxleData!;

      _lengthDoubleAxleController.text = doubleAxleData.length ?? '';
      _vinController.text = doubleAxleData.vin ?? '';
      _registrationController.text = doubleAxleData.registration ?? '';
      _makeController.text = doubleAxleData.make ?? '';
      _yearController.text = doubleAxleData.year ?? '';

      // Clear and populate additional images
      _additionalImagesList.clear();
      _additionalImagesList.addAll(doubleAxleData.additionalImages ?? []);
    }
  }

  void _initializeTextControllers(FormDataProvider formData) {
    _vinNumberController.text = formData.vinNumber ?? '';
    _mileageController.text = formData.mileage ?? '';
    _engineNumberController.text = formData.engineNumber ?? '';
    _registrationNumberController.text = formData.registrationNumber ?? '';
    _sellingPriceController.text = formData.sellingPrice ?? '';
    _warrantyDetailsController.text = formData.warrantyDetails ?? '';
    _referenceNumberController.text = formData.referenceNumber ?? '';
    _makeController.text = formData.make ?? '';
    _yearController.text = formData.year ?? '';
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
    _makeController.addListener(() {
      formData.setMake(_makeController.text);
    });
    _yearController.addListener(() {
      formData.setYear(_yearController.text);
    });

    // Add listeners for Double Axle fields
    _makeDoubleAxleController.addListener(() {
      if (_selectedTrailerType == 'Double Axle') {
        formData.setMake(_makeDoubleAxleController.text);
      }
    });
    _yearDoubleAxleController.addListener(() {
      if (_selectedTrailerType == 'Double Axle') {
        formData.setYear(_yearDoubleAxleController.text);
      }
    });
  }

  void _clearTriAxleData() {
    _lengthTrailerController.clear();
    _vinController.clear();
    _registrationController.clear();
    _makeController.clear();
    Provider.of<FormDataProvider>(context, listen: false).setMake('');
  }

  String? _getFileNameFromUrl(String? url) {
    if (url == null) return null;
    try {
      return url.split('/').last.split('?').first;
    } catch (e) {
      debugPrint('Error extracting filename from URL: $e');
      return null;
    }
  }

  bool get isWebPlatform => kIsWeb;

  dynamic getWebWindow() {
    if (isWebPlatform) {
      try {
        return html.window;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Widget _buildAdditionalFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _featureList.length; i++)
          _buildItemWidget(
              i, _featureList[i], _featureList, _showFeatureImageSourceDialog),
        const SizedBox(height: 10),
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _featureList.add({'description': '', 'image': null});
              });
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.blue, size: 30.0),
                SizedBox(width: 8.0),
                Text(
                  'Add Additional Item',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Add admin user loading functions
  Future<void> _loadTransporterUsers() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userRole', whereIn: ['transporter', 'admin']).get();
      setState(() {
        _transporterUsers = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {'id': doc.id, 'email': data['email'] ?? 'No Email'};
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading transporter users: $e');
    }
  }

  Future<void> _loadSalesRepUsers() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userRole', whereIn: ['admin', 'sales representative']).get();
      setState(() {
        _salesRepUsers = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {'id': doc.id, 'email': data['email'] ?? 'No Email'};
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading sales rep users: $e');
    }
  }

  // Add transporter field widget
  Widget _buildTransporterField() {
    final List<String> ownerEmails =
        _transporterUsers.map((e) => e['email'] as String).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Transporter: ${_selectedTransporterEmail ?? 'None'}",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 15),
        CustomDropdown(
          hintText: 'Select Transporter',
          value: _selectedTransporterEmail,
          items: ownerEmails,
          onChanged: (value) {
            setState(() {
              _selectedTransporterEmail = value;
              try {
                final matching = _transporterUsers
                    .firstWhere((user) => user['email'] == value);
                _selectedTransporterId = matching['id'];
              } catch (e) {
                _selectedTransporterId = null;
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildDynamicAxleImageSection() {
    int axleCount = 0;
    try {
      axleCount = int.parse(_numbAxelOtherController.text);
    } catch (e) {
      axleCount = 0;
    }

    // Ensure arrays have correct length
    while (_brakesAxleOtherImages.length < axleCount) {
      _brakesAxleOtherImages.add(null);
    }
    while (_axleOtherImages.length < axleCount) {
      _axleOtherImages.add(null);
    }

    // Trim excess if needed
    if (_brakesAxleOtherImages.length > axleCount) {
      _brakesAxleOtherImages = _brakesAxleOtherImages.sublist(0, axleCount);
    }
    if (_axleOtherImages.length > axleCount) {
      _axleOtherImages = _axleOtherImages.sublist(0, axleCount);
    }

    List<Widget> axleWidgets = [];

    for (int i = 0; i < axleCount; i++) {
      axleWidgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSectionWithTitle(
                'Brakes Axle ${i + 1} Image',
                _brakesAxleOtherImages[i],
                (img) => setState(() => _brakesAxleOtherImages[i] = img)),
            const SizedBox(height: 15),
            _buildImageSectionWithTitle(
                'Axle ${i + 1} Image',
                _axleOtherImages[i],
                (img) => setState(() => _axleOtherImages[i] = img)),
            const SizedBox(height: 15),
          ],
        ),
      );
    }

    if (axleCount == 0) {
      return const Center(
          child: Text(
        'Enter the number of axles to upload axle images',
        style: TextStyle(color: Colors.white70),
      ));
    }

    return Column(children: axleWidgets);
  }
}
