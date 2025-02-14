import 'package:ctp/pages/home_page.dart';
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
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import '../truckForms/custom_text_field.dart';
import 'package:ctp/components/custom_radio_button.dart';

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/pages/truckForms/custom_dropdown.dart';

/// Formats input text to uppercase.
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

/// Formats numbers with thousand separators.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
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

  // Trailer-specific
  final TextEditingController _trailerTypeController = TextEditingController();
  final TextEditingController _axlesController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();

  // Documents
  Uint8List? _natisRc1File;
  String? _natisRc1FileName;
  Uint8List? _serviceHistoryFile;
  String? _serviceHistoryFileName;

  // Main Single Image
  Uint8List? _selectedMainImage;

  // Other Single Images
  Uint8List? _frontImage;
  Uint8List? _sideImage;
  Uint8List? _tyresImage;
  Uint8List? _chassisImage;
  Uint8List? _deckImage;
  Uint8List? _makersPlateImage;

  // Additional Images (multiple)
  final List<Map<String, dynamic>> _additionalImagesList =
      []; // Will store {description: String, image: Uint8List}

  // Damages & Additional Features
  String _damagesCondition = 'no';
  String _featuresCondition = 'no';
  final List<Map<String, dynamic>> _damageList = [];
  final List<Map<String, dynamic>> _featureList = [];

  bool _isLoading = false;
  String? _vehicleId;

  // --- Add missing fields for Sales Rep selection ---
  String? _selectedSalesRep;
  String? _existingNatisRc1Url;
  String? _existingNatisRc1Name;
  String? _selectedMainImageFileName;

  // Form validations
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(1, (index) => GlobalKey<FormState>());

  // For loading data from JSON
  List<String> _yearOptions = [];
  List<String> _brandOptions = [];
  List<String> _countryOptions = [];
  List<String> _provinceOptions = [];

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
  }

  @override
  Widget build(BuildContext context) {
    final formData = Provider.of<FormDataProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebView = screenWidth > 600; // Add this threshold for web view

    return WillPopScope(
      onWillPop: () async {
        if (widget.isNewUpload) {
          formData.clearAllData();
        }
        return true;
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                    Icons.arrow_left), // Changed to match vehicle upload
                color: Colors.white,
                iconSize: 40, // Match vehicle upload size
              ),
              backgroundColor: const Color(0xFF0E4CAF),
              elevation: 0.0,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              centerTitle: true,
            ),
            body: GradientBackground(
              child: Center(
                // Add Center widget
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isWebView ? 800 : double.infinity,
                  ),
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
                            child: _buildMainImageSection(formData),
                          ),
                          // Constrain form section for web
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: isWebView ? 600 : double.infinity,
                            ),
                            child: _buildFormSection(formData),
                          ),
                        ],
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
                    'lib/assets/Loading_Logo_CTP.gif', // Add loading logo
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

  // -----------------------------------------------------------------------------
  //                     DIALOG HELPER: SHOW SOURCE (Camera vs. Device)
  // -----------------------------------------------------------------------------
  void _pickImageOrFile({
    required String title,
    required bool pickImageOnly,
    required void Function(Uint8List?, String fileName) callback,
  }) async {
    if (pickImageOnly) {
      // For images only, open gallery
      final XFile? pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final fileName = pickedFile.name;
        final bytes = await pickedFile.readAsBytes();
        callback(bytes, fileName);
      }
    } else {
      // For documents
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );
      if (result != null) {
        final fileName = result.xFiles.first.name;
        final bytes = await result.xFiles.first.readAsBytes();
        callback(bytes, fileName);
      }
    }
    // showDialog(
    //   context: context,
    //   builder: (BuildContext ctx) {
    //     return AlertDialog(
    //       title: Text(title),
    //       content: Column(
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           // 1) Take Photo
    //           ListTile(
    //             leading: const Icon(Icons.camera_alt),
    //             title: const Text('Take Photo'),
    //             onTap: () async {
    //               Navigator.of(context).pop();
    //               final XFile? pickedFile =
    //                   await ImagePicker().pickImage(source: ImageSource.camera);
    //               if (pickedFile != null) {
    //                 final fileName = pickedFile.name;
    //                 final bytes = await pickedFile.readAsBytes();

    //                 callback(bytes, fileName);
    //               }
    //             },
    //           ),
    //           // 2) Pick from Device
    //           ListTile(
    //             leading: const Icon(Icons.folder),
    //             title: const Text('Pick from Device'),
    //             onTap: () async {
    //               Navigator.of(context).pop();
    //               if (pickImageOnly) {
    //                 // For images only, open gallery
    //                 final XFile? pickedFile = await ImagePicker()
    //                     .pickImage(source: ImageSource.gallery);
    //                 if (pickedFile != null) {
    //                   final fileName = pickedFile.name;
    //                   final bytes = await pickedFile.readAsBytes();
    //                   callback(bytes, fileName);
    //                 }
    //               } else {
    //                 // For documents
    //                 FilePickerResult? result =
    //                     await FilePicker.platform.pickFiles(
    //                   type: FileType.any,
    //                 );
    //                 if (result != null) {
    //                   final fileName = result.xFiles.first.name;
    //                   final bytes = await result.xFiles.first.readAsBytes();
    //                   callback(bytes, fileName);
    //                 }
    //               }
    //             },
    //           ),
    //         ],
    //       ),
    //     );
    //   },
    // );
  }

  // -----------------------------------------------------------------------------
  //                             MAIN IMAGE SECTION
  // -----------------------------------------------------------------------------
  Widget _buildMainImageSection(FormDataProvider formData) {
    void onTapMainImage() {
      if (_selectedMainImage != null) {
        // If there's already an image, let the user change/remove
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
                    setState(() {
                      _selectedMainImage = null;
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
        _pickImageOrFile(
          title: 'Select Main Image Source',
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

  // -----------------------------------------------------------------------------
  //                              FORM SECTION
  // -----------------------------------------------------------------------------
  Widget _buildFormSection(FormDataProvider formData) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWebView = screenWidth > 600;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'TRAILER FORM'.toUpperCase(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Please fill out all required details below.',
            style: TextStyle(
                fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            'Your trusted partner on the road.', // Add this line to match vehicle upload
            style: const TextStyle(fontSize: 14, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Reference Number
          CustomTextField(
            controller: _referenceNumberController,
            hintText: 'Reference Number',
            inputFormatter: [UpperCaseTextFormatter()],
          ),
          const SizedBox(height: 15),

          // Make
          CustomTextField(
            controller: _makeController,
            hintText: 'Make',
          ),
          const SizedBox(height: 15),

          // Year
          CustomTextField(
            controller: _yearController,
            hintText: 'Year',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),

          // NATIS/RC1
          const Text(
            'NATIS/RC1 DOCUMENTATION',
            style: TextStyle(
                fontSize: 15, color: Colors.white, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          InkWell(
            onTap: () {
              if (_natisRc1File != null) {
                // If there's already a file, let them change or remove
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('NATIS/RC1 Document'),
                    content:
                        const Text('What would you like to do with the file?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _pickImageOrFile(
                            title: 'Select NATIS Document Source',
                            pickImageOnly: false,
                            callback: (file, fileName) {
                              if (file != null) {
                                setState(() {
                                  _natisRc1File = file;
                                  _natisRc1FileName = fileName;
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
                            _natisRc1File = null;
                          });
                        },
                        child: const Text(
                          'Remove File',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                );
              } else {
                // If no file, ask camera or device
                _pickImageOrFile(
                  title: 'Select NATIS Document Source',
                  pickImageOnly: false,
                  callback: (file, fileName) {
                    if (file != null) {
                      setState(() {
                        _natisRc1File = file;
                        _natisRc1FileName = fileName;
                      });
                    }
                  },
                );
              }
            },
            borderRadius: BorderRadius.circular(10.0),
            child: _buildStyledContainer(
              child: _natisRc1File == null
                  ? const Column(
                      children: [
                        Icon(
                          Icons.drive_folder_upload_outlined,
                          color: Colors.white,
                          size: 50.0,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Upload NATIS/RC1',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const Icon(
                          Icons.description,
                          color: Colors.white,
                          size: 50.0,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _natisRc1FileName!.split('/').last,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 15),
          CustomTextField(
            controller: _trailerTypeController,
            hintText: 'Trailer Type',
          ),
          const SizedBox(height: 15),
          CustomTextField(
            controller: _axlesController,
            hintText: 'Number of Axles',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),
          CustomTextField(
            controller: _lengthController,
            hintText: 'Length (m)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),
          CustomTextField(
            controller: _vinNumberController,
            hintText: 'VIN Number',
            inputFormatter: [UpperCaseTextFormatter()],
          ),
          const SizedBox(height: 15),
          CustomTextField(
            controller: _registrationNumberController,
            hintText: 'Registration Number',
            inputFormatter: [UpperCaseTextFormatter()],
          ),
          const SizedBox(height: 15),
          CustomTextField(
            controller: _mileageController,
            hintText: 'Mileage',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),
          CustomTextField(
            controller: _engineNumberController,
            hintText: 'Engine Number',
            inputFormatter: [UpperCaseTextFormatter()],
          ),
          const SizedBox(height: 15),
          CustomTextField(
            controller: _sellingPriceController,
            hintText: 'Expected Selling Price',
            keyboardType: TextInputType.number,
            inputFormatter: [
              FilteringTextInputFormatter.digitsOnly,
              ThousandsSeparatorInputFormatter(),
            ],
          ),
          const SizedBox(height: 15),

          // SERVICE HISTORY
          const Text(
            'SERVICE HISTORY (IF ANY)',
            style: TextStyle(
                fontSize: 15, color: Colors.white, fontWeight: FontWeight.w900),
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
                    content:
                        const Text('What would you like to do with the file?'),
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
                        child: const Text(
                          'Remove File',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                );
              } else {
                // If no file, ask camera or device
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
                        Icon(
                          Icons.drive_folder_upload_outlined,
                          color: Colors.white,
                          size: 50.0,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Upload Service History',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const Icon(
                          Icons.description,
                          color: Colors.white,
                          size: 50.0,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _serviceHistoryFileName!.split('/').last,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 15),

          // IMAGES
          _buildImageSectionWithTitle(
            'Front Trailer Image',
            _frontImage,
            (img) => setState(() => _frontImage = img),
          ),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle(
            'Side Image',
            _sideImage,
            (img) => setState(() => _sideImage = img),
          ),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle(
            'Tyres Image',
            _tyresImage,
            (img) => setState(() => _tyresImage = img),
          ),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle(
            'Chassis Image',
            _chassisImage,
            (img) => setState(() => _chassisImage = img),
          ),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle(
            'Deck Image',
            _deckImage,
            (img) => setState(() => _deckImage = img),
          ),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle(
            'Makers Plate Image',
            _makersPlateImage,
            (img) => setState(() => _makersPlateImage = img),
          ),
          const SizedBox(height: 15),
          _buildAdditionalImagesSection(),
          const SizedBox(height: 15),

          // Damages
          const Text(
            'Are there any damages?',
            style: TextStyle(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
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

          // Additional Features
          const SizedBox(height: 20),
          const Text(
            'Are there any additional features?',
            style: TextStyle(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
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
                    if (_featuresCondition == 'yes' && _featureList.isEmpty) {
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
          if (_featuresCondition == 'yes') _buildFeaturesSection(),
          const SizedBox(height: 30),

          // Done button
          _buildDoneButton(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------------
  //                             IMAGE SECTIONS
  // -----------------------------------------------------------------------------
  Widget _buildImageSectionWithTitle(
    String title,
    Uint8List? image,
    Function(Uint8List?) onImagePicked,
  ) {
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
              // Already have an image => ask to change or remove
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
                ),
              );
            } else {
              // No image => pick new
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
                    child: Image.memory(
                      image,
                      fit: BoxFit.cover,
                      height: 150,
                      width: double.infinity,
                    ),
                  )
                : const Column(
                    children: [
                      Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 50.0,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Tap to upload image',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
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
          'Additional Images with Description',
          style: TextStyle(
              fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        for (int i = 0; i < _additionalImagesList.length; i++)
          _buildItemWidget(
            i,
            _additionalImagesList[i],
            _additionalImagesList,
            (item) => _showAdditionalImageSourceDialog(item),
          ),
        const SizedBox(height: 16.0),
        // Updated Add button to match external cab style
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _additionalImagesList.add({
                  'description': '',
                  'image': null,
                });
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

  // -----------------------------------------------------------------------------
  //                DAMAGES & FEATURES (Dynamic Lists of Items)
  // -----------------------------------------------------------------------------
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
        // Updated Add button to match external cab style
        Center(
          child: GestureDetector(
            onTap: onAdd,
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

  Widget _buildItemWidget(
    int index,
    Map<String, dynamic> item,
    List<Map<String, dynamic>> itemList,
    void Function(Map<String, dynamic>) showImageSourceDialog,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: TextEditingController(text: item['description'] ?? ''),
          hintText: 'Describe the item',
          onChanged: (val) {
            setState(() {
              item['description'] = val;
            });
          },
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => showImageSourceDialog(item),
          borderRadius: BorderRadius.circular(10.0),
          child: _buildStyledContainer(
            child: item['image'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.memory(
                      item['image'],
                      fit: BoxFit.cover,
                      height: 150,
                      width: double.infinity,
                    ),
                  )
                : const Column(
                    children: [
                      Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 50.0,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Tap to upload image',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                itemList.removeAt(index);
              });
            },
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            label: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // For a damage item, we call the same `_showSourceDialog` but always pick images.
  void _showDamageImageSourceDialog(Map<String, dynamic> item) {
    if (item['image'] != null) {
      // Already has an image => change or remove
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
        ),
      );
    } else {
      // No image => pick new
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

  // For a feature item, similarly use `_showSourceDialog`
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

  // -----------------------------------------------------------------------------
  //                             DONE BUTTON
  // -----------------------------------------------------------------------------
  Widget _buildDoneButton() {
    return Center(
      child: CustomButton(
        text: 'Done',
        borderColor: AppColors.orange,
        onPressed: _saveDataAndFinish,
      ),
    );
  }

  // -----------------------------------------------------------------------------
  //                     SAVE METHOD (Uploads All Images)
  // -----------------------------------------------------------------------------
  Future<void> _saveDataAndFinish() async {
    if (widget.isAdminUpload &&
        (_selectedSalesRep == null || _selectedSalesRep!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Sales Rep')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final formData = Provider.of<FormDataProvider>(context, listen: false);

      //======================
      // 0) COMMIT TEXT FIELDS
      //======================
      formData.setReferenceNumber(_referenceNumberController.text);
      formData.setMake(_makeController.text);
      formData.setYear(_yearController.text);
      formData.setVinNumber(_vinNumberController.text);
      formData.setRegistrationNumber(_registrationNumberController.text);
      formData.setMileage(_mileageController.text);
      formData.setEngineNumber(_engineNumberController.text);
      formData.setSellingPrice(_sellingPriceController.text);
      formData.setTrailerType(_trailerTypeController.text);
      formData.setAxles(_axlesController.text);
      formData.setLength(_lengthController.text);
      formData.setWarrantyDetails(_warrantyDetailsController.text);
      formData.setVehicleType('trailer');
      if (_selectedMainImage != null) {
        formData.setSelectedMainImage(_selectedMainImage, "MainImage");
      }

      // Validate required fields
      if (!_validateRequiredFields(formData)) {
        setState(() => _isLoading = false);
        return;
      }

      //======================
      // 1) UPLOAD SINGLE IMAGES
      //======================
      // main image
      String? mainImageUrl;
      if (_selectedMainImage != null) {
        mainImageUrl = await _uploadFileToFirebaseStorage(
          _selectedMainImage!,
          'vehicle_images',
        );
      }

      // NATIS doc
      String? natisUrl;
      if (_natisRc1File != null) {
        natisUrl = await _uploadFileToFirebaseStorage(
          _natisRc1File!,
          'vehicle_documents',
        );
      }

      // service history
      String? serviceHistoryUrl;
      if (_serviceHistoryFile != null) {
        serviceHistoryUrl = await _uploadFileToFirebaseStorage(
          _serviceHistoryFile!,
          'vehicle_documents',
        );
      }

      // other single images (front, side, tyres, etc.)
      String? frontImageUrl;
      if (_frontImage != null) {
        frontImageUrl = await _uploadFileToFirebaseStorage(
          _frontImage!,
          'vehicle_images',
        );
      }

      String? sideImageUrl;
      if (_sideImage != null) {
        sideImageUrl = await _uploadFileToFirebaseStorage(
          _sideImage!,
          'vehicle_images',
        );
      }

      String? tyresImageUrl;
      if (_tyresImage != null) {
        tyresImageUrl = await _uploadFileToFirebaseStorage(
          _tyresImage!,
          'vehicle_images',
        );
      }

      String? chassisImageUrl;
      if (_chassisImage != null) {
        chassisImageUrl = await _uploadFileToFirebaseStorage(
          _chassisImage!,
          'vehicle_images',
        );
      }

      String? deckImageUrl;
      if (_deckImage != null) {
        deckImageUrl = await _uploadFileToFirebaseStorage(
          _deckImage!,
          'vehicle_images',
        );
      }

      String? makersPlateImageUrl;
      if (_makersPlateImage != null) {
        makersPlateImageUrl = await _uploadFileToFirebaseStorage(
          _makersPlateImage!,
          'vehicle_images',
        );
      }

      //======================
      // 2) UPLOAD ADDITIONAL IMAGES
      //======================
      List<Map<String, dynamic>> additionalImagesToSave = [];
      for (Map<String, dynamic> item in _additionalImagesList) {
        String description = item['description'] ?? '';
        Uint8List? imageFile = item['image'];
        String? imageUrl;
        if (imageFile != null) {
          imageUrl =
              await _uploadFileToFirebaseStorage(imageFile, 'vehicle_images');
        }
        additionalImagesToSave.add({
          'description': description,
          'imageUrl': imageUrl ?? '',
        });
      }

      //======================
      // 3) UPLOAD DAMAGE IMAGES
      //======================
      List<Map<String, dynamic>> damagesToSave = [];
      for (Map<String, dynamic> dmg in _damageList) {
        String description = dmg['description'] ?? '';
        Uint8List? dmgFile = dmg['image'];
        String? dmgUrl;
        if (dmgFile != null) {
          dmgUrl = await _uploadFileToFirebaseStorage(dmgFile, 'damage_images');
        }
        damagesToSave.add({
          'description': description,
          'imageUrl': dmgUrl ?? '',
        });
      }

      //======================
      // 4) UPLOAD FEATURE IMAGES
      //======================
      List<Map<String, dynamic>> featuresToSave = [];
      for (Map<String, dynamic> feat in _featureList) {
        String description = feat['description'] ?? '';
        Uint8List? featFile = feat['image'];
        String? featUrl;
        if (featFile != null) {
          featUrl =
              await _uploadFileToFirebaseStorage(featFile, 'feature_images');
        }
        featuresToSave.add({
          'description': description,
          'imageUrl': featUrl ?? '',
        });
      }

      //======================
      // 5) BUILD FIRESTORE DATA
      //======================
      final trailerData = {
        'makeModel': formData.make,
        'year': formData.year,
        'vinNumber': formData.vinNumber,
        'registrationNumber': formData.registrationNumber,
        'mileage': formData.mileage,
        'engineNumber': formData.engineNumber,
        'sellingPrice': formData.sellingPrice,
        'trailerType': formData.trailerType,
        'axles': formData.axles,
        'length': formData.length,
        'warrantyDetails': formData.warrantyDetails,
        'vehicleType': 'trailer',

        // single images
        'mainImageUrl': mainImageUrl ?? '',
        'natisDocumentUrl': natisUrl ?? '',
        'serviceHistoryUrl': serviceHistoryUrl ?? '',
        'frontImageUrl': frontImageUrl ?? '',
        'sideImageUrl': sideImageUrl ?? '',
        'tyresImageUrl': tyresImageUrl ?? '',
        'chassisImageUrl': chassisImageUrl ?? '',
        'deckImageUrl': deckImageUrl ?? '',
        'makersPlateImageUrl': makersPlateImageUrl ?? '',

        // multiple images
        'additionalImages': additionalImagesToSave,

        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': widget.isAdminUpload
            ? widget.transporterId
            : FirebaseAuth.instance.currentUser?.uid,
        'vehicleStatus': 'Draft',
        'country': formData.country,
        'province': formData.province,
        'referenceNumber': formData.referenceNumber,
        'brands': formData.brands,

        // Damages & Features
        'damagesCondition': _damagesCondition,
        'damages': damagesToSave,
        'featuresCondition': _featuresCondition,
        'features': featuresToSave,
        'assignedSalesRepId': widget.isAdminUpload
            ? _selectedSalesRep
            : FirebaseAuth.instance.currentUser?.uid,
      };

      //======================
      // 6) SAVE TO FIRESTORE
      //======================
      final docRef = FirebaseFirestore.instance.collection('vehicles').doc();
      await docRef.set(trailerData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trailer created successfully')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving trailer: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateRequiredFields(FormDataProvider formData) {
    // your existing validations
    if (formData.selectedMainImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a main image')),
      );
      return false;
    }
    if (formData.make == null || formData.make!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the make')),
      );
      return false;
    }
    if (formData.year == null || formData.year!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the year')),
      );
      return false;
    }
    if (formData.vinNumber == null || formData.vinNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the VIN number')),
      );
      return false;
    }
    if (formData.registrationNumber == null ||
        formData.registrationNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the registration number')),
      );
      return false;
    }
    if (_natisRc1File == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload the NATIS/RC1 document')),
      );
      return false;
    }
    if (formData.trailerType == null || formData.trailerType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the trailer type')),
      );
      return false;
    }
    if (formData.axles == null || formData.axles!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the number of axles')),
      );
      return false;
    }
    if (formData.length == null || formData.length!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the trailer length')),
      );
      return false;
    }
    return true;
  }

  /// Reusable method to upload a file to Firebase Storage
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
        orElse: () => {'states': []},
      );
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
        return Column(
          children: [
            CustomDropdown(
              hintText: 'Select Sales Rep',
              value: _selectedSalesRep,
              items: salesReps.map((rep) => rep['display']!).toList(),
              onChanged: (value) {
                final match = salesReps.firstWhere(
                  (rep) => rep['display'] == value,
                  orElse: () => {},
                );
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
    formData.setVinNumber(null);
    formData.setMileage(null);
    formData.setEngineNumber(null);
    formData.setRegistrationNumber(null);
    formData.setSellingPrice(null);
    formData.setVehicleType('trailer');
    formData.setWarrantyDetails(null);
    formData.setReferenceNumber(null);
    formData.setBrands([]);
    _clearFormControllers();
    setState(() {
      _natisRc1File = null;
      _existingNatisRc1Url = null;
      _existingNatisRc1Name = null;
      _selectedMainImage = null;
    });
    _vehicleId = null;
    _isLoading = false;
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
    _trailerTypeController.clear();
    _axlesController.clear();
    _lengthController.clear();
  }

  void _populateDuplicatedData(FormDataProvider formData) {
    if (widget.vehicle != null) {
      debugPrint('=== Populating Duplicated Data ===');
      formData.setYear(widget.vehicle!.year);
      formData.setMake(widget.vehicle!.makeModel);
      formData.setCountry(widget.vehicle!.country);
      formData.setProvince(widget.vehicle!.province);
      _updateProvinceOptions(widget.vehicle!.country);
      debugPrint('=== Duplication Data Population Complete ===');
    }
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

  String? _getFileNameFromUrl(String? url) {
    if (url == null) return null;
    try {
      return url.split('/').last.split('?').first;
    } catch (e) {
      debugPrint('Error extracting filename from URL: $e');
      return null;
    }
  }
}
