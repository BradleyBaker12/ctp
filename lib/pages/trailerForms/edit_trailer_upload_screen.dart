// lib/screens/edit_trailer_upload_screen.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/custom_radio_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/document_preview_screen.dart';
import 'package:ctp/pages/home_page.dart';
import 'package:ctp/pages/truckForms/custom_dropdown.dart';
import 'package:ctp/pages/truckForms/custom_text_field.dart';
import 'package:ctp/providers/form_data_provider.dart';
import 'package:ctp/providers/user_provider.dart'; // <--- for user role
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:ctp/utils/navigation.dart';

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
    // Only keep digits
    final cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final formatted = _formatter.format(int.parse(cleanText));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class EditTrailerUploadScreen extends StatefulWidget {
  final bool isDuplicating;
  final Vehicle? vehicle;
  final bool isNewUpload;
  final bool isAdminUpload;
  final String? transporterId;

  const EditTrailerUploadScreen({
    super.key,
    this.vehicle,
    this.transporterId,
    this.isAdminUpload = false,
    this.isDuplicating = false,
    this.isNewUpload = false,
  });

  @override
  _EditTrailerUploadScreenState createState() =>
      _EditTrailerUploadScreenState();
}

class _EditTrailerUploadScreenState extends State<EditTrailerUploadScreen> {
  final ScrollController _scrollController = ScrollController();
  double _imageHeight = 300.0;

  // ---------- Text Controllers ----------
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
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _makeController = TextEditingController();

  // Trailer-specific
  final TextEditingController _trailerTypeController = TextEditingController();
  final TextEditingController _axlesController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();

  // Documents
  File? _natisDocumentFile;
  String? _existingNatisDocumentUrl;

  File? _serviceHistoryFile;
  String? _existingServiceHistoryUrl;

  // Main image
  File? _selectedMainImage;
  String? _existingMainImageUrl;

  // Other single images
  File? _frontImage;
  String? _existingFrontImageUrl;

  File? _sideImage;
  String? _existingSideImageUrl;

  File? _tyresImage;
  String? _existingTyresImageUrl;

  File? _chassisImage;
  String? _existingChassisImageUrl;

  File? _deckImage;
  String? _existingDeckImageUrl;

  File? _makersPlateImage;
  String? _existingMakersPlateImageUrl;

  // Additional Images
  final List<File> _localAdditionalImages = [];
  List<String> _existingAdditionalImagesUrls = [];

  // Damages & Features
  String _damagesCondition = 'no';
  String _featuresCondition = 'no';

  /// Each item: { 'description': string, 'imageFile': File?, 'existingImageUrl': string? }
  List<Map<String, dynamic>> _damageList = [];
  List<Map<String, dynamic>> _featureList = [];

  bool _isLoading = false;
  String? _vehicleId;

  // Vehicle status
  String _vehicleStatus = 'Draft'; // default: "Draft" or "Live"

  // ---------- NEW: track user role ----------
  bool _isDealer = false;
  bool _isTransporter = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();

    // Read user role from UserProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole =
        userProvider.getUserRole; // e.g. "dealer", "admin", "transporter"
    _isDealer = userRole == 'dealer';
    _isTransporter = userRole == 'transporter';
    _isAdmin = userRole == 'admin';

    _scrollController.addListener(() {
      final offset = _scrollController.offset.clamp(0, 150);
      setState(() {
        _imageHeight = 300.0 - offset;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.isNewUpload) {
        Provider.of<FormDataProvider>(context, listen: false).clearAllData();
      } else {
        // Editing or duplicating
        if (widget.vehicle != null && !widget.isDuplicating) {
          _vehicleId = widget.vehicle!.id;
          await _populateExistingTrailerData();
        } else if (widget.isDuplicating) {
          _vehicleId = null;
          await _populateExistingTrailerData();
        }
      }
    });
  }

  /// Load data from Firestore doc (via Vehicle model) into local fields
  Future<void> _populateExistingTrailerData() async {
    final trailer = widget.vehicle;
    if (trailer == null) return;

    // Populate from Firestore => local text controllers
    _referenceNumberController.text = trailer.referenceNumber ?? '';
    _yearController.text = trailer.year ?? '';
    _vinNumberController.text = trailer.vinNumber ?? '';
    _registrationNumberController.text = trailer.registrationNumber ?? '';
    _mileageController.text = trailer.mileage ?? '';
    _engineNumberController.text = trailer.engineNumber ?? '';
    _trailerTypeController.text = trailer.trailerType ?? '';
    _axlesController.text = trailer.axles ?? '';
    _lengthController.text = trailer.length ?? '';
    _warrantyDetailsController.text = trailer.warrantyDetails ?? '';

    _makeController.text = trailer.makeModel ?? '';
    // If your doc calls it "sellingPrice" or "expectedSellingPrice":
    _sellingPriceController.text = trailer.expectedSellingPrice ?? '';

    // NATIS doc
    if ((trailer.natisDocumentUrl?.isNotEmpty ?? false)) {
      _existingNatisDocumentUrl = trailer.natisDocumentUrl;
    }

    // Service History
    if ((trailer.serviceHistoryUrl?.isNotEmpty ?? false)) {
      _existingServiceHistoryUrl = trailer.serviceHistoryUrl;
    }

    // Main image
    if ((trailer.mainImageUrl?.isNotEmpty ?? false)) {
      _existingMainImageUrl = trailer.mainImageUrl;
    }

    // Single images
    if ((trailer.frontImageUrl?.isNotEmpty ?? false)) {
      _existingFrontImageUrl = trailer.frontImageUrl;
    }
    if ((trailer.sideImageUrl?.isNotEmpty ?? false)) {
      _existingSideImageUrl = trailer.sideImageUrl;
    }
    if ((trailer.tyresImageUrl?.isNotEmpty ?? false)) {
      _existingTyresImageUrl = trailer.tyresImageUrl;
    }
    if ((trailer.chassisImageUrl?.isNotEmpty ?? false)) {
      _existingChassisImageUrl = trailer.chassisImageUrl;
    }
    if ((trailer.deckImageUrl?.isNotEmpty ?? false)) {
      _existingDeckImageUrl = trailer.deckImageUrl;
    }
    if ((trailer.makersPlateImageUrl?.isNotEmpty ?? false)) {
      _existingMakersPlateImageUrl = trailer.makersPlateImageUrl;
    }

    // Additional images
    if (trailer.additionalImages != null &&
        trailer.additionalImages!.isNotEmpty) {
      _existingAdditionalImagesUrls = trailer.additionalImages!;
    }

    // Damages
    if (trailer.damagesCondition == 'yes' && trailer.damages != null) {
      _damageList = trailer.damages!
          .map((d) => {
                'description': d['description'] ?? '',
                'imageFile': null,
                'existingImageUrl': d['imageUrl'] ?? '',
              })
          .toList();
      _damagesCondition = 'yes';
    } else {
      _damagesCondition = 'no';
    }

    // Features
    if (trailer.featuresCondition == 'yes' && trailer.features != null) {
      _featureList = trailer.features!
          .map((f) => {
                'description': f['description'] ?? '',
                'imageFile': null,
                'existingImageUrl': f['imageUrl'] ?? '',
              })
          .toList();
      _featuresCondition = 'yes';
    } else {
      _featuresCondition = 'no';
    }

    // Vehicle status
    _vehicleStatus = trailer.vehicleStatus ?? 'Draft';

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (widget.isNewUpload) {
          Provider.of<FormDataProvider>(context, listen: false).clearAllData();
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
              title: const Text('Edit Trailer',
                  style: TextStyle(color: Colors.white)),
            ),
            body: GradientBackground(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    _buildMainImageSection(),
                    _buildFormSection(),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // MAIN IMAGE
  // -----------------------------------------------------------------------------
  Widget _buildMainImageSection() {
    // If dealer => can only view/expand
    void onTapMainImage() {
      if (_isDealer) {
        // Just show a large preview
        _showImagePreview(
          file: _selectedMainImage,
          url: _existingMainImageUrl,
          title: 'Trailer Main Image',
        );
        return;
      }

      // Admin/Transporter => can edit
      if (_selectedMainImage != null ||
          (_existingMainImageUrl != null &&
              _existingMainImageUrl!.isNotEmpty)) {
        _showMainImageOptionsDialog();
      } else {
        _pickMainImage();
      }
    }

    Widget imageWidget;
    if (_selectedMainImage != null) {
      imageWidget = Image.file(_selectedMainImage!,
          fit: BoxFit.cover, width: double.infinity, height: _imageHeight);
    } else if ((_existingMainImageUrl?.isNotEmpty ?? false)) {
      imageWidget = Image.network(_existingMainImageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: _imageHeight, errorBuilder: (ctx, error, stack) {
        return Container(
          color: Colors.grey,
          child: const Center(
              child: Icon(Icons.broken_image, color: Colors.white)),
        );
      });
    } else {
      imageWidget = Container(
        color: Colors.grey[800],
        child: const Center(
          child: Text(
            'Tap here to upload main image',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTapMainImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 0),
        height: _imageHeight,
        width: double.infinity,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: imageWidget,
            ),
            if (!_isDealer) // only show "Tap to modify" for Admin/Transporter
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.black54,
                  child: const Text(
                    'Tap to modify image',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showMainImageOptionsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Main Image'),
        content: const Text('Choose an option'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickMainImage();
            },
            child: const Text('Change Image'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedMainImage = null;
                _existingMainImageUrl = null;
              });
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _pickMainImage() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Main Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile =
                    await ImagePicker().pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  setState(() {
                    _selectedMainImage = File(pickedFile.path);
                    _existingMainImageUrl = null;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile =
                    await ImagePicker().pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    _selectedMainImage = File(pickedFile.path);
                    _existingMainImageUrl = null;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(
      {File? file, String? url, required String title}) async {
    await MyNavigator.push(
        context,
        DocumentPreviewScreen(
          file: file,
          url: url,
        ));
  }

  // -----------------------------------------------------------------------------
  // FORM SECTION
  // -----------------------------------------------------------------------------
  Widget _buildFormSection() {
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

          // Vehicle Status
          if (!_isDealer) ...[
            // Only show vehicle status dropdown if not dealer
            CustomDropdown(
              hintText: 'Vehicle Status',
              value: _vehicleStatus,
              items: const ['Draft', 'Live'],
              onChanged: (value) {
                setState(() {
                  _vehicleStatus = value ?? 'Draft';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select the vehicle status';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
          ],

          if (_isDealer)
            const Text(
              'Make',
              style: TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.start,
            ),

          // Make
          CustomTextField(
            controller: _makeController,
            hintText: 'Make',
            enabled: !_isDealer, // read-only if dealer
          ),
          const SizedBox(height: 15),

          // Reference Number
          if (_isAdmin || _isTransporter)
            CustomTextField(
              controller: _referenceNumberController,
              hintText: 'Reference Number',
              inputFormatter: [UpperCaseTextFormatter()],
              enabled: !_isDealer,
            ),
          if (_isAdmin || _isTransporter) const SizedBox(height: 15),

          if (_isDealer)
            const Text(
              'Year',
              style: TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.start,
            ),
          // Year
          CustomTextField(
            controller: _yearController,
            hintText: 'Year',
            keyboardType: TextInputType.number,
            enabled: !_isDealer,
          ),
          const SizedBox(height: 15),

          // NATIS Document
          if (_isAdmin || _isTransporter)
            const Text(
              'NATIS DOCUMENT',
              style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
          if (_isAdmin || _isTransporter) const SizedBox(height: 15),
          if (_isAdmin || _isTransporter) _buildNatisDocSection(),
          if (_isAdmin || _isTransporter) const SizedBox(height: 15),

          if (_isDealer)
            const Text(
              'Trailer Type',
              style: TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.start,
            ),
          // Trailer Type
          CustomTextField(
            controller: _trailerTypeController,
            hintText: 'Trailer Type',
            enabled: !_isDealer,
          ),
          const SizedBox(height: 15),

          if (_isDealer)
            const Text(
              'Number of Axels',
              style: TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.start,
            ),
          // Axles
          CustomTextField(
            controller: _axlesController,
            hintText: 'Number of Axles',
            keyboardType: TextInputType.number,
            enabled: !_isDealer,
          ),
          const SizedBox(height: 15),

          if (_isDealer)
            const Text(
              'Length (m)',
              style: TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.start,
            ),
          // Length
          CustomTextField(
            controller: _lengthController,
            hintText: 'Length (m)',
            keyboardType: TextInputType.number,
            enabled: !_isDealer,
          ),
          const SizedBox(height: 15),

          // VIN Number
          if (_isAdmin || _isTransporter)
            CustomTextField(
              controller: _vinNumberController,
              hintText: 'VIN Number',
              inputFormatter: [UpperCaseTextFormatter()],
              enabled: !_isDealer,
            ),
          if (_isAdmin || _isTransporter) const SizedBox(height: 15),

          // Registration Number
          if (_isAdmin || _isTransporter)
            CustomTextField(
              controller: _registrationNumberController,
              hintText: 'Registration Number',
              inputFormatter: [UpperCaseTextFormatter()],
              enabled: !_isDealer,
            ),
          if (_isAdmin || _isTransporter) const SizedBox(height: 15),

          // Mileage
          if (_isDealer)
            const Text(
              'Mileage',
              style: TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.start,
            ),
          CustomTextField(
            controller: _mileageController,
            hintText: 'Mileage',
            keyboardType: TextInputType.number,
            enabled: !_isDealer,
          ),
          const SizedBox(height: 15),

          // Engine Number
          if (_isAdmin || _isTransporter)
            CustomTextField(
              controller: _engineNumberController,
              hintText: 'Engine Number',
              inputFormatter: [UpperCaseTextFormatter()],
              enabled: !_isDealer,
            ),
          if (_isAdmin || _isTransporter) const SizedBox(height: 15),

          // Selling Price
          if (_isAdmin || _isTransporter)
            CustomTextField(
              controller: _sellingPriceController,
              hintText: 'Selling Price',
              keyboardType: TextInputType.number,
              inputFormatter: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorInputFormatter(),
              ],
              enabled: !_isDealer,
            ),
          if (_isAdmin || _isTransporter) const SizedBox(height: 15),

          // SERVICE HISTORY
          const Text(
            'SERVICE HISTORY (IF ANY)',
            style: TextStyle(
                fontSize: 15, color: Colors.white, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          _buildServiceHistorySection(),
          const SizedBox(height: 15),

          // Single images
          _buildSingleImageSection(
            'Front Trailer Image',
            _frontImage,
            _existingFrontImageUrl,
            (file) {
              setState(() {
                _frontImage = file;
                _existingFrontImageUrl = null;
              });
            },
          ),
          const SizedBox(height: 15),

          _buildSingleImageSection(
            'Side Image',
            _sideImage,
            _existingSideImageUrl,
            (file) {
              setState(() {
                _sideImage = file;
                _existingSideImageUrl = null;
              });
            },
          ),
          const SizedBox(height: 15),

          _buildSingleImageSection(
            'Tyres Image',
            _tyresImage,
            _existingTyresImageUrl,
            (file) {
              setState(() {
                _tyresImage = file;
                _existingTyresImageUrl = null;
              });
            },
          ),
          const SizedBox(height: 15),

          _buildSingleImageSection(
            'Chassis Image',
            _chassisImage,
            _existingChassisImageUrl,
            (file) {
              setState(() {
                _chassisImage = file;
                _existingChassisImageUrl = null;
              });
            },
          ),
          const SizedBox(height: 15),

          _buildSingleImageSection(
            'Deck Image',
            _deckImage,
            _existingDeckImageUrl,
            (file) {
              setState(() {
                _deckImage = file;
                _existingDeckImageUrl = null;
              });
            },
          ),
          const SizedBox(height: 15),

          _buildSingleImageSection(
            'Makers Plate Image',
            _makersPlateImage,
            _existingMakersPlateImageUrl,
            (file) {
              setState(() {
                _makersPlateImage = file;
                _existingMakersPlateImageUrl = null;
              });
            },
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
          if (!_isDealer) ...[
            // Only show radio if not dealer
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
                        _damageList.add({
                          'description': '',
                          'imageFile': null,
                          'existingImageUrl': null,
                        });
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
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 15),
          ] else ...[
            // Dealer => read-only text
            Text(
              'Damages: ${_damagesCondition == 'yes' ? 'Yes' : 'No'}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 5),
          ],
          if (_damagesCondition == 'yes') _buildDamageSection(),

          // Features
          const SizedBox(height: 20),
          const Text(
            'Are there any additional features?',
            style: TextStyle(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (!_isDealer) ...[
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
                        _featureList.add({
                          'description': '',
                          'imageFile': null,
                          'existingImageUrl': null,
                        });
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
          ] else ...[
            Text(
              'Features: ${_featuresCondition == 'yes' ? 'Yes' : 'No'}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 5),
          ],
          if (_featuresCondition == 'yes') _buildFeaturesSection(),

          const SizedBox(height: 30),
          if (!_isDealer) _buildDoneButton(), // only show button if not dealer
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // NATIS doc display
  // -----------------------------------------------------------------------------
  Widget _buildNatisDocSection() {
    // If dealer => they can only view
    void onTap() {
      if (_isDealer) {
        _showDocumentPreview(
          file: _natisDocumentFile,
          url: _existingNatisDocumentUrl,
          title: 'NATIS Document',
        );
        return;
      }
      // Admin/Transporter => normal logic
      _handleNatisTap();
    }

    Widget child;
    if (_natisDocumentFile == null) {
      if ((_existingNatisDocumentUrl?.isNotEmpty ?? false)) {
        child = const Column(
          children: [
            Icon(Icons.description, color: Colors.white, size: 50.0),
            SizedBox(height: 10),
            Text(
              'Existing NATIS Document',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        );
      } else {
        child = const Column(
          children: [
            Icon(Icons.drive_folder_upload_outlined,
                color: Colors.white, size: 50.0),
            SizedBox(height: 10),
            Text(
              'Upload NATIS Document',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }
    } else {
      child = Column(
        children: [
          const Icon(Icons.description, color: Colors.white, size: 50.0),
          const SizedBox(height: 10),
          Text(
            _natisDocumentFile!.path.split('/').last,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.0),
      child: _buildStyledContainer(child: child),
    );
  }

  void _handleNatisTap() {
    if (_natisDocumentFile != null ||
        (_existingNatisDocumentUrl != null &&
            _existingNatisDocumentUrl!.isNotEmpty)) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('NATIS Document'),
          content: const Text('What would you like to do with the file?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // View the document
                _showDocumentPreview(
                  file: _natisDocumentFile,
                  url: _existingNatisDocumentUrl,
                  title: 'NATIS Document',
                );
              },
              child: const Text('View'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showSourceDialog(
                  title: 'Select NATIS Document',
                  pickImageOnly: false,
                  callback: (file) {
                    if (file != null) {
                      setState(() {
                        _natisDocumentFile = file;
                        _existingNatisDocumentUrl = null;
                      });
                    }
                  },
                );
              },
              child: const Text('Replace File'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _natisDocumentFile = null;
                  _existingNatisDocumentUrl = null;
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
      _showSourceDialog(
        title: 'Select NATIS Document',
        pickImageOnly: false,
        callback: (file) {
          if (file != null) {
            setState(() => _natisDocumentFile = file);
          }
        },
      );
    }
  }

  // -----------------------------------------------------------------------------
  // SERVICE HISTORY
  // -----------------------------------------------------------------------------
  Widget _buildServiceHistorySection() {
    // If dealer => can only view
    void onTap() {
      if (_isDealer) {
        _showDocumentPreview(
          file: _serviceHistoryFile,
          url: _existingServiceHistoryUrl,
          title: 'Service History',
        );
        return;
      }
      // Admin/Transporter => normal logic
      _handleServiceHistoryTap();
    }

    Widget child;
    if (_serviceHistoryFile == null) {
      if ((_existingServiceHistoryUrl?.isNotEmpty ?? false)) {
        child = const Column(
          children: [
            Icon(Icons.description, color: Colors.white, size: 50.0),
            SizedBox(height: 10),
            Text('Existing Service History',
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        );
      } else {
        child = const Column(
          children: [
            Icon(Icons.drive_folder_upload_outlined,
                color: Colors.white, size: 50.0),
            SizedBox(height: 10),
            Text(
              'Upload Service History',
              style: TextStyle(fontSize: 14, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }
    } else {
      child = Column(
        children: [
          const Icon(Icons.description, color: Colors.white, size: 50.0),
          const SizedBox(height: 10),
          Text(
            _serviceHistoryFile!.path.split('/').last,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.0),
      child: _buildStyledContainer(child: child),
    );
  }

  void _handleServiceHistoryTap() {
    if (_serviceHistoryFile != null ||
        (_existingServiceHistoryUrl != null &&
            _existingServiceHistoryUrl!.isNotEmpty)) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Service History'),
          content: const Text('What would you like to do with the file?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // View the document
                _showDocumentPreview(
                  file: _serviceHistoryFile,
                  url: _existingServiceHistoryUrl,
                  title: 'Service History',
                );
              },
              child: const Text('View'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showSourceDialog(
                  title: 'Select Service History',
                  pickImageOnly: false,
                  callback: (file) {
                    if (file != null) {
                      setState(() {
                        _serviceHistoryFile = file;
                        _existingServiceHistoryUrl = null;
                      });
                    }
                  },
                );
              },
              child: const Text('Replace File'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _serviceHistoryFile = null;
                  _existingServiceHistoryUrl = null;
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
  }

  // -----------------------------------------------------------------------------
  // SINGLE IMAGES
  // -----------------------------------------------------------------------------
  Widget _buildSingleImageSection(
    String label,
    File? localFile,
    String? existingUrl,
    ValueChanged<File?> onFilePicked,
  ) {
    // If dealer => tapping the image only shows a preview
    void onTap() {
      if (_isDealer) {
        _showImagePreview(
          file: localFile,
          url: existingUrl,
          title: label,
        );
        return;
      }

      // if Transporter/Admin => can replace/remove
      if (localFile != null || (existingUrl?.isNotEmpty ?? false)) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(label),
            content: Text('Choose an option for $label'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showSourceDialog(
                    title: label,
                    pickImageOnly: true,
                    callback: (file) {
                      if (file != null) onFilePicked(file);
                    },
                  );
                },
                child: const Text('Change'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    onFilePicked(null);
                  });
                },
                child:
                    const Text('Remove', style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      } else {
        // pick new
        _showSourceDialog(
          title: label,
          pickImageOnly: true,
          callback: (file) {
            if (file != null) onFilePicked(file);
          },
        );
      }
    }

    Widget child;
    if (localFile != null) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.file(
          localFile,
          fit: BoxFit.cover,
          height: 150,
          width: double.infinity,
        ),
      );
    } else if (existingUrl?.isNotEmpty ?? false) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          existingUrl!,
          fit: BoxFit.cover,
          height: 150,
          width: double.infinity,
          errorBuilder: (ctx, err, stack) => Container(color: Colors.grey),
        ),
      );
    } else {
      child = const Column(
        children: [
          Icon(Icons.camera_alt, color: Colors.white, size: 50.0),
          SizedBox(height: 10),
          Text(
            'Tap to upload image',
            style: TextStyle(fontSize: 14, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.0),
          child: _buildStyledContainer(child: child),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------------------
  // ADDITIONAL IMAGES
  // -----------------------------------------------------------------------------
  Widget _buildAdditionalImagesSection() {
    // If dealer => can't add or remove
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
            // existing additional images
            for (int i = 0; i < _existingAdditionalImagesUrls.length; i++)
              Stack(
                children: [
                  InkWell(
                    onTap: () {
                      if (_isDealer) {
                        // Show large preview
                        _showImagePreview(
                          file: null,
                          url: _existingAdditionalImagesUrls[i],
                          title: 'Additional Image',
                        );
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        _existingAdditionalImagesUrls[i],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) =>
                            Container(color: Colors.grey),
                      ),
                    ),
                  ),
                  if (!_isDealer) // remove button only if not dealer
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _existingAdditionalImagesUrls.removeAt(i);
                          });
                        },
                        child: Container(
                          color: Colors.black54,
                          child: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            // local new images
            for (int i = 0; i < _localAdditionalImages.length; i++)
              Stack(
                children: [
                  InkWell(
                    onTap: () {
                      if (_isDealer) {
                        _showImagePreview(
                          file: _localAdditionalImages[i],
                          url: null,
                          title: 'Additional Image',
                        );
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(
                        _localAdditionalImages[i],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (!_isDealer)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _localAdditionalImages.removeAt(i);
                          });
                        },
                        child: Container(
                          color: Colors.black54,
                          child: const Icon(Icons.close, color: Colors.white),
                        ),
                      ),
                    )
                ],
              ),

            if (!_isDealer)
              // add image button for admin/transporter
              GestureDetector(
                onTap: () {
                  _showSourceDialog(
                    title: 'Additional Image',
                    pickImageOnly: true,
                    callback: (file) {
                      if (file != null) {
                        setState(() {
                          _localAdditionalImages.add(file);
                        });
                      }
                    },
                  );
                },
                child: _buildStyledContainer(
                  child: const Column(
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 50),
                      SizedBox(height: 10),
                      Text(
                        'Add Image',
                        style: TextStyle(color: Colors.white70),
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
  // DAMAGES
  // -----------------------------------------------------------------------------
  Widget _buildDamageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _damageList.length; i++)
          _buildItemWidget(
            i,
            _damageList[i],
            _damageList,
            _showDamageItemSourceDialog,
          ),
      ],
    );
  }

  // -----------------------------------------------------------------------------
  // FEATURES
  // -----------------------------------------------------------------------------
  Widget _buildFeaturesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _featureList.length; i++)
          _buildItemWidget(
            i,
            _featureList[i],
            _featureList,
            _showFeatureItemSourceDialog,
          ),
      ],
    );
  }

  Widget _buildItemWidget(
    int index,
    Map<String, dynamic> item,
    List<Map<String, dynamic>> itemList,
    void Function(Map<String, dynamic>) showSourceDialogForItem,
  ) {
    final description = item['description'] as String? ?? '';
    final File? imageFile = item['imageFile'] as File?;
    final String? existingUrl = item['existingImageUrl'] as String?;

    // If dealer => tapping only shows preview, can't remove
    void onTapImage() {
      if (_isDealer) {
        _showImagePreview(
          file: imageFile,
          url: existingUrl,
          title: 'Damage/Feature Image',
        );
        return;
      }
      // normal logic
      showSourceDialogForItem(item);
    }

    Widget child;
    if (imageFile != null) {
      child = Image.file(
        imageFile,
        fit: BoxFit.cover,
        height: 150,
        width: double.infinity,
      );
    } else if (existingUrl?.isNotEmpty ?? false) {
      child = Image.network(
        existingUrl!,
        fit: BoxFit.cover,
        height: 150,
        width: double.infinity,
        errorBuilder: (ctx, err, stack) => Container(color: Colors.grey),
      );
    } else {
      child = const Column(
        children: [
          Icon(Icons.camera_alt, color: Colors.white, size: 50),
          SizedBox(height: 8),
          Text('Tap to upload image', style: TextStyle(color: Colors.white70)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: TextEditingController(text: description),
          hintText: 'Describe the item',
          enabled: !_isDealer,
          onChanged: (val) {
            setState(() {
              item['description'] = val;
            });
          },
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTapImage,
          child: _buildStyledContainer(child: child),
        ),
        const SizedBox(height: 8),
        if (!_isDealer)
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
        const SizedBox(height: 16),
      ],
    );
  }

  void _showDamageItemSourceDialog(Map<String, dynamic> item) {
    final imageFile = item['imageFile'] as File?;
    final existingUrl = item['existingImageUrl'] as String?;
    if (imageFile != null || (existingUrl?.isNotEmpty ?? false)) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Damage Image'),
          content: const Text('Choose an option'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showSourceDialog(
                  title: 'Damage Image',
                  pickImageOnly: true,
                  callback: (file) {
                    if (file != null) {
                      setState(() {
                        item['imageFile'] = file;
                        item['existingImageUrl'] = null;
                      });
                    }
                  },
                );
              },
              child: const Text('Change'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  item['imageFile'] = null;
                  item['existingImageUrl'] = null;
                });
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
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
              item['imageFile'] = file;
              item['existingImageUrl'] = null;
            });
          }
        },
      );
    }
  }

  void _showFeatureItemSourceDialog(Map<String, dynamic> item) {
    final imageFile = item['imageFile'] as File?;
    final existingUrl = item['existingImageUrl'] as String?;
    if (imageFile != null || (existingUrl?.isNotEmpty ?? false)) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Feature Image'),
          content: const Text('Choose an option'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showSourceDialog(
                  title: 'Feature Image',
                  pickImageOnly: true,
                  callback: (file) {
                    if (file != null) {
                      setState(() {
                        item['imageFile'] = file;
                        item['existingImageUrl'] = null;
                      });
                    }
                  },
                );
              },
              child: const Text('Change'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  item['imageFile'] = null;
                  item['existingImageUrl'] = null;
                });
              },
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
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
              item['imageFile'] = file;
              item['existingImageUrl'] = null;
            });
          }
        },
      );
    }
  }

  // -----------------------------------------------------------------------------
  // DONE BUTTON
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
  // SAVE LOGIC
  // -----------------------------------------------------------------------------
  Future<void> _saveDataAndFinish() async {
    setState(() => _isLoading = true);
    try {
      if (!_validateRequiredFields()) {
        setState(() => _isLoading = false);
        return;
      }

      // 1) Main image
      String? finalMainImageUrl = _existingMainImageUrl;
      if (_selectedMainImage != null) {
        finalMainImageUrl =
            await _uploadFile(_selectedMainImage!, 'vehicle_images');
      }

      // 2) NATIS doc
      String? finalNatisUrl = _existingNatisDocumentUrl;
      if (_natisDocumentFile != null) {
        finalNatisUrl =
            await _uploadFile(_natisDocumentFile!, 'vehicle_documents');
      }

      // 3) Service History
      String? finalServiceUrl = _existingServiceHistoryUrl;
      if (_serviceHistoryFile != null) {
        finalServiceUrl =
            await _uploadFile(_serviceHistoryFile!, 'vehicle_documents');
      }

      // 4) Single images
      String? finalFrontImageUrl = _existingFrontImageUrl;
      if (_frontImage != null) {
        finalFrontImageUrl = await _uploadFile(_frontImage!, 'vehicle_images');
      }

      String? finalSideImageUrl = _existingSideImageUrl;
      if (_sideImage != null) {
        finalSideImageUrl = await _uploadFile(_sideImage!, 'vehicle_images');
      }

      String? finalTyresImageUrl = _existingTyresImageUrl;
      if (_tyresImage != null) {
        finalTyresImageUrl = await _uploadFile(_tyresImage!, 'vehicle_images');
      }

      String? finalChassisImageUrl = _existingChassisImageUrl;
      if (_chassisImage != null) {
        finalChassisImageUrl =
            await _uploadFile(_chassisImage!, 'vehicle_images');
      }

      String? finalDeckImageUrl = _existingDeckImageUrl;
      if (_deckImage != null) {
        finalDeckImageUrl = await _uploadFile(_deckImage!, 'vehicle_images');
      }

      String? finalMakersPlateImageUrl = _existingMakersPlateImageUrl;
      if (_makersPlateImage != null) {
        finalMakersPlateImageUrl =
            await _uploadFile(_makersPlateImage!, 'vehicle_images');
      }

      // 5) Additional images
      List<String> finalAdditionalImages =
          List.from(_existingAdditionalImagesUrls);
      for (File localImg in _localAdditionalImages) {
        final url = await _uploadFile(localImg, 'vehicle_images');
        if (url != null) {
          finalAdditionalImages.add(url);
        }
      }

      // 6) Damages
      List<Map<String, dynamic>> finalDamages = [];
      for (var d in _damageList) {
        String desc = d['description'] ?? '';
        File? imageFile = d['imageFile'];
        String? existingUrl = d['existingImageUrl'];
        String? finalUrl = existingUrl;
        if (imageFile != null) {
          finalUrl = await _uploadFile(imageFile, 'damage_images');
        }
        finalDamages.add({
          'description': desc,
          'imageUrl': finalUrl ?? '',
        });
      }

      // 7) Features
      List<Map<String, dynamic>> finalFeatures = [];
      for (var f in _featureList) {
        String desc = f['description'] ?? '';
        File? imageFile = f['imageFile'];
        String? existingUrl = f['existingImageUrl'];
        String? finalUrl = existingUrl;
        if (imageFile != null) {
          finalUrl = await _uploadFile(imageFile, 'feature_images');
        }
        finalFeatures.add({
          'description': desc,
          'imageUrl': finalUrl ?? '',
        });
      }

      // 8) Build doc data for Firestore
      final docData = {
        'referenceNumber': _referenceNumberController.text.trim(),
        'year': _yearController.text.trim(),
        'vinNumber': _vinNumberController.text.trim(),
        'registrationNumber': _registrationNumberController.text.trim(),
        'mileage': _mileageController.text.trim(),
        'engineNumber': _engineNumberController.text.trim(),
        'sellingPrice': _sellingPriceController.text.trim(),
        'makeModel': _makeController.text.trim(),
        'trailerType': _trailerTypeController.text.trim(),
        'axles': _axlesController.text.trim(),
        'length': _lengthController.text.trim(),
        'warrantyDetails': _warrantyDetailsController.text.trim(),
        'vehicleType': 'trailer',

        // NATIS & Service
        'natisDocumentUrl': finalNatisUrl ?? '',
        'serviceHistoryUrl': finalServiceUrl ?? '',

        // main image
        'mainImageUrl': finalMainImageUrl ?? '',

        // single images
        'frontImageUrl': finalFrontImageUrl ?? '',
        'sideImageUrl': finalSideImageUrl ?? '',
        'tyresImageUrl': finalTyresImageUrl ?? '',
        'chassisImageUrl': finalChassisImageUrl ?? '',
        'deckImageUrl': finalDeckImageUrl ?? '',
        'makersPlateImageUrl': finalMakersPlateImageUrl ?? '',

        // additional
        'additionalImages': finalAdditionalImages,

        // damages/features
        'damagesCondition': _damagesCondition,
        'damages': finalDamages,
        'featuresCondition': _featuresCondition,
        'features': finalFeatures,

        'vehicleStatus': _vehicleStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // If new => create doc
      if (_vehicleId == null) {
        final docRef =
            await FirebaseFirestore.instance.collection('vehicles').add({
          ...docData,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': widget.isAdminUpload
              ? widget.transporterId
              : FirebaseAuth.instance.currentUser?.uid,
        });
        _vehicleId = docRef.id;
      } else {
        // Update existing
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(_vehicleId)
            .update(docData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trailer saved successfully!')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (ctx) => const HomePage()),
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

  bool _validateRequiredFields() {
    if (_selectedMainImage == null &&
        (_existingMainImageUrl == null || _existingMainImageUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a main image')),
      );
      return false;
    }
    if (_yearController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the year')),
      );
      return false;
    }
    if (_natisDocumentFile == null &&
        (_existingNatisDocumentUrl == null ||
            _existingNatisDocumentUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload NATIS Document')),
      );
      return false;
    }
    if (_trailerTypeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the trailer type')),
      );
      return false;
    }
    if (_axlesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the number of axles')),
      );
      return false;
    }
    if (_lengthController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the trailer length')),
      );
      return false;
    }
    return true;
  }

  Future<String?> _uploadFile(File file, String folder) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final storageRef =
          FirebaseStorage.instance.ref().child('$folder/$fileName');
      await storageRef.putFile(file);
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint('File upload error: $e');
      return null;
    }
  }

  // -----------------------------------------------------------------------------
  // REUSABLE UI HELPERS
  // -----------------------------------------------------------------------------
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

  void _showSourceDialog({
    required String title,
    required bool pickImageOnly,
    required void Function(File?) callback,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final pickedFile =
                    await ImagePicker().pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  callback(File(pickedFile.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Pick from Device'),
              onTap: () async {
                Navigator.pop(context);
                if (pickImageOnly) {
                  // images only
                  final pickedFile = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    callback(File(pickedFile.path));
                  }
                } else {
                  // any file
                  final result = await FilePicker.platform.pickFiles(
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
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // SHOW DOCUMENT PREVIEW
  // -----------------------------------------------------------------------------
  void _showDocumentPreview({File? file, String? url, required String title}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentPreviewScreen(
          file: file,
          url: url,
        ),
      ),
    );
  }
}

// The rest of your existing code remains unchanged, including other methods and widgets.
// Make sure to include the new `DocumentPreviewScreen` import at the top of the file.
