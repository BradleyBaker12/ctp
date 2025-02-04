import 'dart:io';
import 'dart:typed_data'; // Added for Uint8List
import 'package:ctp/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  File? _natisRc1File;
  File? _serviceHistoryFile;

  // Main Single Image
  // --- FIX APPLIED: Change type from File? to Uint8List? ---
  Uint8List? _selectedMainImage;

  // Other Single Images remain as File?
  File? _frontImage;
  File? _sideImage;
  File? _tyresImage;
  File? _chassisImage;
  File? _deckImage;
  File? _makersPlateImage;

  // Additional Images (multiple)
  final List<File> _additionalImages = [];

  // Damages & Additional Features
  String _damagesCondition = 'no';
  String _featuresCondition = 'no';
  final List<Map<String, dynamic>> _damageList = [];
  final List<Map<String, dynamic>> _featureList = [];

  bool _isLoading = false;
  String? _vehicleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isNewUpload) {
        Provider.of<FormDataProvider>(context, listen: false).clearAllData();
      } else if (widget.vehicle != null && !widget.isDuplicating) {
        _vehicleId = widget.vehicle!.id;
      }
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
                icon: const Icon(Icons.arrow_back),
                color: Colors.white,
                iconSize: 30,
              ),
              backgroundColor: const Color(0xFF0E4CAF),
              elevation: 0.0,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              centerTitle: true,
            ),
            body: GradientBackground(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    _buildMainImageSection(formData),
                    _buildFormSection(formData),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
  void _showSourceDialog({
    required String title,
    required bool pickImageOnly,
    required void Function(File?) callback,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1) Take Photo
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? pickedFile =
                      await ImagePicker().pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    callback(File(pickedFile.path));
                  }
                },
              ),
              // 2) Pick from Device
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('Pick from Device'),
                onTap: () async {
                  Navigator.of(context).pop();
                  if (pickImageOnly) {
                    final XFile? pickedFile = await ImagePicker()
                        .pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      callback(File(pickedFile.path));
                    }
                  } else {
                    FilePickerResult? result =
                        await FilePicker.platform.pickFiles(
                      type: FileType.any,
                    );
                    if (result != null && result.files.single.path != null) {
                      callback(File(result.files.single.path!));
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
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
                    _showSourceDialog(
                      title: 'Change Main Image',
                      pickImageOnly: true,
                      callback: (file) {
                        if (file != null) {
                          file.readAsBytes().then((bytes) {
                            setState(() {
                              _selectedMainImage = bytes;
                            });
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
        _showSourceDialog(
          title: 'Select Main Image Source',
          pickImageOnly: true,
          callback: (file) {
            if (file != null) {
              file.readAsBytes().then((bytes) {
                setState(() {
                  _selectedMainImage = bytes;
                });
              });
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'TRAILER FORM',
            style: TextStyle(
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
                          _showSourceDialog(
                            title: 'Select NATIS Document Source',
                            pickImageOnly: false,
                            callback: (file) {
                              if (file != null) {
                                setState(() => _natisRc1File = file);
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
                _showSourceDialog(
                  title: 'Select NATIS Document Source',
                  pickImageOnly: false,
                  callback: (file) {
                    if (file != null) {
                      setState(() => _natisRc1File = file);
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
                          _natisRc1File!.path.split('/').last,
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
                          _showSourceDialog(
                            title: 'Select Service History',
                            pickImageOnly: false,
                            callback: (file) {
                              if (file != null) {
                                setState(() => _serviceHistoryFile = file);
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
                _showSourceDialog(
                  title: 'Select Service History',
                  pickImageOnly: false,
                  callback: (file) {
                    if (file != null) {
                      setState(() => _serviceHistoryFile = file);
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
                          _serviceHistoryFile!.path.split('/').last,
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
    File? image,
    Function(File?) onImagePicked,
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
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(title),
                  content: Text('What would you like to do with this image?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showSourceDialog(
                          title: 'Change $title',
                          pickImageOnly: true,
                          callback: (file) {
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
              _showSourceDialog(
                title: title,
                pickImageOnly: true,
                callback: (file) {
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
                    child: Image.file(
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
          'Additional Images',
          style: TextStyle(
              fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (int i = 0; i < _additionalImages.length; i++)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(
                      _additionalImages[i],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _additionalImages.removeAt(i);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            GestureDetector(
              onTap: () {
                _showSourceDialog(
                  title: 'Additional Image',
                  pickImageOnly: true,
                  callback: (file) {
                    if (file != null) {
                      setState(() {
                        _additionalImages.add(file);
                      });
                    }
                  },
                );
              },
              child: _buildStyledContainer(
                child: const Column(
                  children: [
                    Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 50,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Add Image',
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
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              elevation: 0,
            ),
            onPressed: onAdd,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add Another',
              style: TextStyle(color: Colors.white),
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
                    child: Image.file(
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
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Damage Image'),
          content: const Text('What would you like to do with this image?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showSourceDialog(
                  title: 'Change Damage Image',
                  pickImageOnly: true,
                  callback: (file) {
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
      _showSourceDialog(
        title: 'Damage Image',
        pickImageOnly: true,
        callback: (file) {
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
                _showSourceDialog(
                  title: 'Change Feature Image',
                  pickImageOnly: true,
                  callback: (file) {
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
      _showSourceDialog(
        title: 'Feature Image',
        pickImageOnly: true,
        callback: (file) {
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
    setState(() => _isLoading = true);

    try {
      final formData = Provider.of<FormDataProvider>(context, listen: false);

      // Validate required fields
      if (!_validateRequiredFields(formData)) {
        setState(() => _isLoading = false);
        return;
      }

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
        formData.setSelectedMainImage(_selectedMainImage);
      }

      //======================
      // 1) UPLOAD SINGLE IMAGES
      //======================
      // main image: use the new upload function for Uint8List
      String? mainImageUrl;
      if (_selectedMainImage != null) {
        mainImageUrl = await _uploadDataToFirebaseStorage(
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
      List<String> additionalImagesUrls = [];
      for (File img in _additionalImages) {
        final url = await _uploadFileToFirebaseStorage(img, 'vehicle_images');
        if (url != null) {
          additionalImagesUrls.add(url);
        }
      }

      //======================
      // 3) UPLOAD DAMAGE IMAGES
      //======================
      List<Map<String, dynamic>> damagesToSave = [];
      for (Map<String, dynamic> dmg in _damageList) {
        String description = dmg['description'] ?? '';
        File? dmgFile = dmg['image'];
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
        File? featFile = feat['image'];
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
        'additionalImages': additionalImagesUrls,

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

  /// Reusable method to upload a file to Firebase Storage (for File objects)
  Future<String?> _uploadFileToFirebaseStorage(
      File file, String folderName) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef =
          FirebaseStorage.instance.ref().child('$folderName/$fileName');
      await storageRef.putFile(file);
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint('File upload error: $e');
      return null;
    }
  }

  /// New helper to upload raw data (Uint8List) to Firebase Storage
  Future<String?> _uploadDataToFirebaseStorage(
      Uint8List data, String folderName) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef =
          FirebaseStorage.instance.ref().child('$folderName/$fileName.jpg');
      await storageRef.putData(data);
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint('Data upload error: $e');
      return null;
    }
  }
}
