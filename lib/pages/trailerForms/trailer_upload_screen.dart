import 'package:ctp/pages/home_page.dart';
import 'package:ctp/utils/camera_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/providers/form_data_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/pages/truckForms/custom_dropdown.dart';
import 'package:universal_html/html.dart' as html;
import '../truckForms/custom_text_field.dart';
import 'package:ctp/components/custom_radio_button.dart';

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
    _axlesTrailerAController.dispose();
    _axlesTrailerBController.dispose();
    _scrollController.dispose();
    super.dispose();
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
                          type: FileType.any,
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
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.any,
          );
          if (result != null && result.files.isNotEmpty) {
            final fileName = result.files.first.name;
            final bytes = result.files.first.bytes;
            callback(bytes, fileName);
          }
        }
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.any,
        );
        if (result != null && result.files.isNotEmpty) {
          final fileName = result.files.first.name;
          final bytes = result.files.first.bytes;
          callback(bytes, fileName);
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error picking file: $e')));
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
            _buildSalesRepField(),
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
            if (_selectedTrailerType == 'Double Axle' ||
                _selectedTrailerType == 'Other') ...[
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E4CAF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF0E4CAF)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.construction,
                        size: 50, color: Colors.white.withOpacity(0.9)),
                    const SizedBox(height: 15),
                    Text(
                      '$_selectedTrailerType Form Coming Soon',
                      style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'This form is currently under development.\nPlease check back later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ] else if (_selectedTrailerType != null) ...[
              CustomTextField(
                controller: _makeController,
                hintText: 'Make',
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _yearController,
                hintText: 'Year',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _registrationNumberController,
                hintText: 'Expected Selling Price',
                keyboardType: TextInputType.number,
                inputFormatter: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsSeparatorInputFormatter(),
                ],
              ),
              const SizedBox(height: 15),
              if (_selectedTrailerType != null &&
                  _selectedTrailerType != 'Double Axle' &&
                  _selectedTrailerType != 'Other') ...[
                if (_selectedTrailerType == 'Superlink') ...[
                  const SizedBox(height: 15),
                  const Text("Trailer A Details",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
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
                  const SizedBox(height: 15),
                  const Text("Trailer B Details",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
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
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle('Trailer B - Deck Image',
                      _deckImageB, (img) => setState(() => _deckImageB = img)),
                  const SizedBox(height: 15),
                  _buildImageSectionWithTitle(
                      'Trailer B - Makers Plate Image',
                      _makersPlateImageB,
                      (img) => setState(() => _makersPlateImageB = img)),
                  const SizedBox(height: 15),
                  const Text('Are there additional images for Trailer B?',
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const SizedBox(height: 15),
                ] else if (_selectedTrailerType == 'Tri-Axle') ...[
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
                  _buildImageSectionWithTitle('Tyres Image', _tyresImage,
                      (img) => setState(() => _tyresImage = img)),
                  _buildImageSectionWithTitle('Chassis Image', _chassisImage,
                      (img) => setState(() => _chassisImage = img)),
                  _buildImageSectionWithTitle('Deck Image', _deckImage,
                      (img) => setState(() => _deckImage = img)),
                  _buildImageSectionWithTitle(
                      'Makers Plate Image',
                      _makersPlateImage,
                      (img) => setState(() => _makersPlateImage = img)),
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
        'makeModel': _makeController.text,
        'year': _yearController.text,
        'sellingPrice': _sellingPriceController.text,
        'trailerType': _selectedTrailerType,
        'vehicleType': 'trailer',
        'mainImageUrl': commonUrls['mainImageUrl'] ?? '',
        'natisDocumentUrl': commonUrls['natisUrl'] ?? '',
        'serviceHistoryUrl': commonUrls['serviceHistoryUrl'] ?? '',
        'trailerExtraInfo': trailerExtraInfo,
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
    switch (_selectedTrailerType) {
      case 'Superlink':
        return {
          'trailerA': {
            'length': _lengthTrailerAController.text,
            'vin': _vinAController.text,
            'registration': _registrationAController.text,
            'axles': _axlesTrailerAController.text,
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
            'trailerAAdditionalImages':
                await _uploadListItems(_additionalImagesListTrailerA),
          },
          'trailerB': {
            'length': _lengthTrailerBController.text,
            'vin': _vinBController.text,
            'registration': _registrationBController.text,
            'axles': _axlesTrailerBController.text,
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
            'trailerBAdditionalImages':
                await _uploadListItems(_additionalImagesListTrailerB),
          },
        };
      case 'Tri-Axle':
        return {
          'lengthTrailer': _lengthTrailerController.text,
          'vin': _vinController.text,
          'registration': _registrationController.text,
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
      if (item['image'] != null) {
        String? imageUrl =
            await _uploadFileToFirebaseStorage(item['image'], 'vehicle_images');
        uploadedItems.add({
          'description': item['description'],
          'imageUrl': imageUrl ?? '',
        });
      } else {
        uploadedItems.add({
          'description': item['description'],
          'imageUrl': '',
        });
      }
    }
    return uploadedItems;
  }

  bool _validateRequiredFields(FormDataProvider formData) {
    if (formData.selectedMainImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add a main image')));
      return false;
    }
    if (formData.make == null || formData.make!.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter the make')));
      return false;
    }
    if (formData.year == null || formData.year!.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter the year')));
      return false;
    }
    if (formData.referenceNumber == null || formData.referenceNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the reference number')));
      return false;
    }
    if (_registrationNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the selling price')));
      return false;
    }
    if (_selectedTrailerType != 'Tri-Axle' &&
        _selectedTrailerType != 'Superlink') {
      if (_lengthController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter the length')));
        return false;
      }
    }
    switch (_selectedTrailerType) {
      case 'Tri-Axle':
        if (_lengthTrailerController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please enter the trailer length')));
          return false;
        }
        if (_vinController.text.isEmpty ||
            _registrationController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please complete VIN and registration fields')));
          return false;
        }
        break;
      case 'Superlink':
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

    // Clear new Trailer A fields
    _axlesTrailerAController.clear();
    _natisTrailerADoc1File = null;
    _natisTrailerADoc1FileName = null;
    _natisTrailerADoc2File = null;
    _natisTrailerADoc2FileName = null;

    // Clear new Trailer B fields
    _axlesTrailerBController.clear();
    _natisTrailerBDoc1File = null;
    _natisTrailerBDoc1FileName = null;

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
      if (_selectedTrailerType == 'Superlink') {
        if (widget.vehicle!.trailer != null &&
            widget.vehicle!.trailer!.superlinkData != null) {
          _lengthTrailerAController.text =
              widget.vehicle!.trailer!.superlinkData!.lengthA ?? '';
          _vinAController.text =
              widget.vehicle!.trailer!.superlinkData!.vinA ?? '';
          _registrationAController.text =
              widget.vehicle!.trailer!.superlinkData!.registrationA ?? '';
          _lengthTrailerBController.text =
              widget.vehicle!.trailer!.superlinkData!.lengthB ?? '';
          _vinBController.text =
              widget.vehicle!.trailer!.superlinkData!.vinB ?? '';
          _registrationBController.text =
              widget.vehicle!.trailer!.superlinkData!.registrationB ?? '';
          _additionalImagesListTrailerA.clear();
          _additionalImagesListTrailerA.addAll(
              widget.vehicle!.trailer!.superlinkData!.additionalImagesA);
          _additionalImagesListTrailerB.clear();
          _additionalImagesListTrailerB.addAll(
              widget.vehicle!.trailer!.superlinkData!.additionalImagesB);
        }
      }
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
}
