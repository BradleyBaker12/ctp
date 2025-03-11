import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/home_page.dart';
import 'package:ctp/pages/truckForms/custom_dropdown.dart';
import 'package:ctp/components/custom_radio_button.dart';
import 'package:ctp/pages/truckForms/custom_text_field.dart';
import 'package:ctp/utils/camera_helper.dart'; // For capturePhoto
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:ctp/providers/trailer_form_provider.dart';

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
    if (newValue.text.isEmpty) return newValue;
    final String cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanText.isEmpty) return newValue.copyWith(text: '');
    final String formatted = _formatter.format(int.parse(cleanText));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class EditTrailerScreen extends StatefulWidget {
  final Vehicle vehicle;
  const EditTrailerScreen({super.key, required this.vehicle});

  @override
  _EditTrailerScreenState createState() => _EditTrailerScreenState();
}

class _EditTrailerScreenState extends State<EditTrailerScreen> {
  // === Common Controllers ===
  final TextEditingController _referenceNumberController =
      TextEditingController();
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();
  final TextEditingController _axlesController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();

  // === Tri-Axle Controllers ===
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

  // === Superlink Controllers (Trailer A) ===
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

  // === Superlink Controllers (Trailer B) ===
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

  // === Documents and Main Image ===
  Uint8List? _natisRc1File;
  String? _natisRc1FileName;
  Uint8List? _selectedMainImage;
  // Existing NATIS/RC1 document fields.
  String? _existingNatisRc1Url;
  String? _existingNatisRc1Name;

  // === UI State ===
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  double _imageHeight = 300.0;

  // Trailer type dropdown
  String? _selectedTrailerType;

  // === Image URL fields for prepopulation ===
  String? _frontImageAUrl;
  String? _sideImageAUrl;
  String? _tyresImageAUrl;
  String? _chassisImageAUrl;
  String? _deckImageAUrl;
  String? _makersPlateImageAUrl;
  String? _frontImageBUrl;
  String? _sideImageBUrl;
  String? _tyresImageBUrl;
  String? _chassisImageBUrl;
  String? _deckImageBUrl;
  String? _makersPlateImageBUrl;

  @override
  void initState() {
    super.initState();
    _selectedTrailerType = widget.vehicle.trailer?.trailerType ??
        widget.vehicle.toMap()['trailerType'] ??
        '';
    if (_selectedTrailerType == null || _selectedTrailerType!.isEmpty) {
      _selectedTrailerType = 'Superlink';
      debugPrint('DEBUG: Trailer type was empty. Defaulting to "Superlink".');
    } else {
      debugPrint('DEBUG: Loaded trailer type from DB: $_selectedTrailerType');
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final trailerFormProvider =
          Provider.of<TrailerFormProvider>(context, listen: false);
      final vehicleData = widget.vehicle.toMap();
      if (vehicleData['trailerExtraInfo'] == null ||
          (vehicleData['trailerExtraInfo'] as Map).isEmpty) {
        if (vehicleData.containsKey('trailer')) {
          vehicleData['trailerExtraInfo'] = (vehicleData['trailer']
                  as Map<String, dynamic>)['trailerExtraInfo'] ??
              {};
        }
      }
      trailerFormProvider.populateFromTrailer(vehicleData);
      _populateVehicleData();
    });
    _scrollController.addListener(() {
      double offset = _scrollController.offset;
      if (offset < 0) offset = 0;
      if (offset > 150.0) offset = 150.0;
      setState(() {
        _imageHeight = 300.0 - offset;
      });
    });
  }

  @override
  void dispose() {
    _referenceNumberController.dispose();
    _makeController.dispose();
    _yearController.dispose();
    _sellingPriceController.dispose();
    _axlesController.dispose();
    _lengthController.dispose();
    _lengthTrailerController.dispose();
    _vinController.dispose();
    _registrationController.dispose();
    _lengthTrailerAController.dispose();
    _vinAController.dispose();
    _registrationAController.dispose();
    _lengthTrailerBController.dispose();
    _vinBController.dispose();
    _registrationBController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _populateVehicleData() {
    final data = widget.vehicle.toMap();
    debugPrint('DEBUG: _populateVehicleData - Full vehicle data: $data');

    setState(() {
      _referenceNumberController.text = data['referenceNumber'] ?? '';
      _makeController.text = data['makeModel'] ?? '';
      _yearController.text = data['year'] ?? '';
      _sellingPriceController.text = data['sellingPrice'] ?? '';
      _existingNatisRc1Url = data['natisDocumentUrl'];
      _existingNatisRc1Name = _getFileNameFromUrl(_existingNatisRc1Url);
      _axlesController.text = data['axles'] ?? '';
      _lengthController.text = data['length'] ?? '';
    });

    Map<String, dynamic> trailerExtra = {};
    if (widget.vehicle.trailer != null &&
        widget.vehicle.trailer!.rawTrailerExtraInfo != null &&
        widget.vehicle.trailer!.rawTrailerExtraInfo!.isNotEmpty) {
      trailerExtra = widget.vehicle.trailer!.rawTrailerExtraInfo!;
      debugPrint(
          'DEBUG: Using rawTrailerExtraInfo from trailer object: $trailerExtra');
    } else if (data['trailerExtraInfo'] != null &&
        (data['trailerExtraInfo'] as Map).isNotEmpty) {
      trailerExtra = data['trailerExtraInfo'];
      debugPrint('DEBUG: Using trailerExtraInfo from toMap(): $trailerExtra');
    } else if (widget.vehicle.trailer != null) {
      trailerExtra = widget.vehicle.trailer!.toMap()['trailerExtraInfo'] ?? {};
      debugPrint(
          'DEBUG: Falling back to trailer.toMap()[trailerExtraInfo]: $trailerExtra');
    } else {
      debugPrint('DEBUG: No trailerExtraInfo available.');
    }

    Map<String, dynamic> trailerAMap = {};
    Map<String, dynamic> trailerBMap = {};
    if (trailerExtra.containsKey('trailerA') &&
        trailerExtra.containsKey('trailerB')) {
      trailerAMap = trailerExtra['trailerA'] as Map<String, dynamic>;
      trailerBMap = trailerExtra['trailerB'] as Map<String, dynamic>;
    } else if (trailerExtra.containsKey('lengthA')) {
      trailerAMap = {
        'length': trailerExtra['lengthA'],
        'vin': trailerExtra['vinA'],
        'registration': trailerExtra['registrationA'],
        'frontImageUrl': trailerExtra['frontImageUrlA'] ?? '',
        'sideImageUrl': trailerExtra['sideImageUrlA'] ?? '',
        'tyresImageUrl': trailerExtra['tyresImageUrlA'] ?? '',
        'chassisImageUrl': trailerExtra['chassisImageUrlA'] ?? '',
        'deckImageUrl': trailerExtra['deckImageUrlA'] ?? '',
        'makersPlateImageUrl': trailerExtra['makersPlateImageUrlA'] ?? '',
        'additionalImages': trailerExtra['additionalImagesA'] ?? [],
      };
      trailerBMap = {
        'length': trailerExtra['lengthB'],
        'vin': trailerExtra['vinB'],
        'registration': trailerExtra['registrationB'],
        'frontImageUrl': trailerExtra['frontImageUrlB'] ?? '',
        'sideImageUrl': trailerExtra['sideImageUrlB'] ?? '',
        'tyresImageUrl': trailerExtra['tyresImageUrlB'] ?? '',
        'chassisImageUrl': trailerExtra['chassisImageUrlB'] ?? '',
        'deckImageUrl': trailerExtra['deckImageUrlB'] ?? '',
        'makersPlateImageUrl': trailerExtra['makersPlateImageUrlB'] ?? '',
        'additionalImages': trailerExtra['additionalImagesB'] ?? [],
      };
    }

    setState(() {
      _lengthTrailerAController.text = trailerAMap['length']?.toString() ?? '';
      _vinAController.text = trailerAMap['vin']?.toString() ?? '';
      _registrationAController.text =
          trailerAMap['registration']?.toString() ?? '';

      _lengthTrailerBController.text = trailerBMap['length']?.toString() ?? '';
      _vinBController.text = trailerBMap['vin']?.toString() ?? '';
      _registrationBController.text =
          trailerBMap['registration']?.toString() ?? '';

      _frontImageAUrl = trailerAMap['frontImageUrl'] ?? '';
      _sideImageAUrl = trailerAMap['sideImageUrl'] ?? '';
      _tyresImageAUrl = trailerAMap['tyresImageUrl'] ?? '';
      _chassisImageAUrl = trailerAMap['chassisImageUrl'] ?? '';
      _deckImageAUrl = trailerAMap['deckImageUrl'] ?? '';
      _makersPlateImageAUrl = trailerAMap['makersPlateImageUrl'] ?? '';

      _frontImageBUrl = trailerBMap['frontImageUrl'] ?? '';
      _sideImageBUrl = trailerBMap['sideImageUrl'] ?? '';
      _tyresImageBUrl = trailerBMap['tyresImageUrl'] ?? '';
      _chassisImageBUrl = trailerBMap['chassisImageUrl'] ?? '';
      _deckImageBUrl = trailerBMap['deckImageUrl'] ?? '';
      _makersPlateImageBUrl = trailerBMap['makersPlateImageUrl'] ?? '';
    });

    // Populate Tri-Axle specific fields if applicable.
    if (_selectedTrailerType == 'Tri-Axle') {
      setState(() {
        _lengthTrailerController.text = data['lengthTrailer'] ?? '';
        _vinController.text = data['vin'] ?? '';
        _registrationController.text = data['registration'] ?? '';
      });
      debugPrint('DEBUG: Tri-Axle Fields Populated:');
      debugPrint('  Length Trailer: ${_lengthTrailerController.text}');
      debugPrint('  VIN: ${_vinController.text}');
      debugPrint('  Registration: ${_registrationController.text}');
    }

    debugPrint(
        'DEBUG: Final Common values: Ref#: ${_referenceNumberController.text}, Make: ${_makeController.text}, Year: ${_yearController.text}, Price: ${_sellingPriceController.text}');
    debugPrint(
        'DEBUG: Final Trailer A values: Length: ${_lengthTrailerAController.text}, VIN: ${_vinAController.text}, Registration: ${_registrationAController.text}');
    debugPrint(
        'DEBUG: Final Trailer B values: Length: ${_lengthTrailerBController.text}, VIN: ${_vinBController.text}, Registration: ${_registrationBController.text}');
    debugPrint('DEBUG: NATIS file: ${data['natisDocumentUrl']}');
  }

  Future<void> _pickImageOrFile({
    required String title,
    required bool pickImageOnly,
    required void Function(Uint8List?, String fileName) callback,
  }) async {
    if (pickImageOnly) {
      try {
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
                          final imageBytes = await _capturePhoto();
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
                        final XFile? pickedFile = await ImagePicker()
                            .pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          final fileName = pickedFile.name;
                          final bytes = await pickedFile.readAsBytes();
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
          final XFile? pickedFile =
              await ImagePicker().pickImage(source: ImageSource.gallery);
          if (pickedFile != null) {
            final fileName = pickedFile.name;
            final bytes = await pickedFile.readAsBytes();
            callback(bytes, fileName);
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    } else {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.isNotEmpty) {
        final fileName = result.files.first.name;
        final bytes = result.files.first.bytes;
        callback(bytes, fileName);
      }
    }
  }

  Future<Uint8List?> _capturePhoto() async {
    return null; // Replace with your camera helper if needed.
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
                    debugPrint('NATIS/RC1 file captured from camera.');
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
                    debugPrint('NATIS/RC1 file picked from gallery: $fileName');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
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

  Widget _buildFileDisplay(String? fileName, bool isExisting) {
    String displayName =
        fileName ?? (isExisting ? 'Existing Document' : 'Select Document');
    String extension = fileName != null ? fileName.split('.').last : '';
    IconData iconData = _getFileIcon(extension);
    return Column(
      children: [
        Icon(iconData, color: Colors.white, size: 50.0),
        const SizedBox(height: 8),
        Text(
          displayName,
          style: const TextStyle(
              fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
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

  Future<void> _viewDocument() async {
    final url = _natisRc1FileName == null ? _existingNatisRc1Url : null;
    if (url != null && url.isNotEmpty) {
      debugPrint('Attempting to view document at URL: $url');
      try {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          debugPrint('Document opened successfully.');
        } else {
          debugPrint('Could not open document URL.');
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open document')));
        }
      } catch (e) {
        debugPrint('Error opening document: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening document: $e')));
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

  Widget _buildNatisDocumentSection() {
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
                ? _buildFileDisplay(_natisRc1FileName?.split('/').last, false)
                : (_existingNatisRc1Url != null &&
                        _existingNatisRc1Url!.isNotEmpty)
                    ? _buildFileDisplay(
                        _getFileNameFromUrl(_existingNatisRc1Url), true)
                    : _buildFileDisplay(null, false),
          ),
        ),
      ],
    );
  }

  // Generic method for additional image dialogs
  void _showAdditionalImageSourceDialog(Map<String, dynamic> item) {
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
            child:
                const Text('Remove Image', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CustomTextField(
          controller: _referenceNumberController, hintText: 'Reference Number'),
      const SizedBox(height: 15),
      CustomDropdown(
        hintText: 'Select Trailer Type',
        value: _selectedTrailerType,
        items: const ['Superlink', 'Tri-Axle', 'Double Axle', 'Other'],
        onChanged: (value) {
          setState(() {
            _selectedTrailerType = value;
          });
          debugPrint('DEBUG: Trailer type changed to: $value');
        },
      ),
      const SizedBox(height: 15),
      if (_selectedTrailerType == 'Double Axle' ||
          _selectedTrailerType == 'Other')
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0E4CAF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF0E4CAF)),
          ),
          child: const Column(
            children: [
              Icon(Icons.construction, size: 50, color: Colors.white),
              SizedBox(height: 15),
              Text('Form Coming Soon',
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text(
                  'This form is currently under development.\nPlease check back later.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70)),
            ],
          ),
        )
      else if (_selectedTrailerType != null) ...[
        CustomTextField(controller: _makeController, hintText: 'Make'),
        const SizedBox(height: 15),
        CustomTextField(
            controller: _yearController,
            hintText: 'Year',
            keyboardType: TextInputType.number),
        const SizedBox(height: 15),
        CustomTextField(
          controller: _sellingPriceController,
          hintText: 'Expected Selling Price',
          keyboardType: TextInputType.number,
          inputFormatter: [
            FilteringTextInputFormatter.digitsOnly,
            ThousandsSeparatorInputFormatter()
          ],
        ),
        const SizedBox(height: 15),
        _buildNatisDocumentSection(),
        const SizedBox(height: 15),
        if (_selectedTrailerType != 'Tri-Axle') ...[
          CustomTextField(
              controller: _axlesController,
              hintText: 'Number of Axles',
              keyboardType: TextInputType.number),
          const SizedBox(height: 15),
          CustomTextField(
              controller: _lengthController,
              hintText: 'Overall Length',
              keyboardType: TextInputType.number),
        ],
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
              keyboardType: TextInputType.number),
          const SizedBox(height: 15),
          CustomTextField(
              controller: _vinAController,
              hintText: 'VIN A',
              inputFormatter: [UpperCaseTextFormatter()]),
          const SizedBox(height: 15),
          CustomTextField(
              controller: _registrationAController,
              hintText: 'Registration A',
              inputFormatter: [UpperCaseTextFormatter()]),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Trailer A - Front Image', _frontImageA,
              (img) {
            setState(() {
              _frontImageA = img;
            });
          }, existingUrl: _frontImageAUrl),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Trailer A - Side Image', _sideImageA,
              (img) {
            setState(() {
              _sideImageA = img;
            });
          }, existingUrl: _sideImageAUrl),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Trailer A - Tyres Image', _tyresImageA,
              (img) {
            setState(() {
              _tyresImageA = img;
            });
          }, existingUrl: _tyresImageAUrl),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle(
              'Trailer A - Chassis Image', _chassisImageA, (img) {
            setState(() {
              _chassisImageA = img;
            });
          }, existingUrl: _chassisImageAUrl),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Trailer A - Deck Image', _deckImageA,
              (img) {
            setState(() {
              _deckImageA = img;
            });
          }, existingUrl: _deckImageAUrl),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle(
              'Trailer A - Makers Plate Image', _makersPlateImageA, (img) {
            setState(() {
              _makersPlateImageA = img;
            });
          }, existingUrl: _makersPlateImageAUrl),
          const SizedBox(height: 15),
          _buildAdditionalImagesSectionForTrailerA(),
          const SizedBox(height: 15),
          const Text("Trailer B Details",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 15),
          CustomTextField(
              controller: _lengthTrailerBController,
              hintText: 'Length Trailer B',
              keyboardType: TextInputType.number),
          const SizedBox(height: 15),
          CustomTextField(
              controller: _vinBController,
              hintText: 'VIN B',
              inputFormatter: [UpperCaseTextFormatter()]),
          const SizedBox(height: 15),
          CustomTextField(
              controller: _registrationBController,
              hintText: 'Registration B',
              inputFormatter: [UpperCaseTextFormatter()]),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Trailer B - Front Image', _frontImageB,
              (img) {
            setState(() {
              _frontImageB = img;
            });
          }, existingUrl: _frontImageBUrl),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Trailer B - Side Image', _sideImageB,
              (img) {
            setState(() {
              _sideImageB = img;
            });
          }, existingUrl: _sideImageBUrl),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Trailer B - Tyres Image', _tyresImageB,
              (img) {
            setState(() {
              _tyresImageB = img;
            });
          }, existingUrl: _tyresImageBUrl),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle(
              'Trailer B - Chassis Image', _chassisImageB, (img) {
            setState(() {
              _chassisImageB = img;
            });
          }, existingUrl: _chassisImageBUrl),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Trailer B - Deck Image', _deckImageB,
              (img) {
            setState(() {
              _deckImageB = img;
            });
          }, existingUrl: _deckImageBUrl),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle(
              'Trailer B - Makers Plate Image', _makersPlateImageB, (img) {
            setState(() {
              _makersPlateImageB = img;
            });
          }, existingUrl: _makersPlateImageBUrl),
          const SizedBox(height: 15),
          _buildAdditionalImagesSectionForTrailerB(),
        ] else if (_selectedTrailerType == 'Tri-Axle') ...[
          const SizedBox(height: 15),
          CustomTextField(
              controller: _lengthTrailerController,
              hintText: 'Length Trailer',
              keyboardType: TextInputType.number),
          const SizedBox(height: 15),
          CustomTextField(
              controller: _vinController,
              hintText: 'VIN',
              inputFormatter: [UpperCaseTextFormatter()]),
          const SizedBox(height: 15),
          CustomTextField(
              controller: _registrationController,
              hintText: 'Registration',
              inputFormatter: [UpperCaseTextFormatter()]),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Front Trailer Image', _frontImage,
              (img) {
            setState(() {
              _frontImage = img;
            });
          }, existingUrl: widget.vehicle.frontImageUrl ?? ''),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Side Image', _sideImage, (img) {
            setState(() {
              _sideImage = img;
            });
          }, existingUrl: widget.vehicle.sideImageUrl ?? ''),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Tyres Image', _tyresImage, (img) {
            setState(() {
              _tyresImage = img;
            });
          }, existingUrl: widget.vehicle.tyresImageUrl ?? ''),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Chassis Image', _chassisImage, (img) {
            setState(() {
              _chassisImage = img;
            });
          }, existingUrl: widget.vehicle.chassisImageUrl ?? ''),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Deck Image', _deckImage, (img) {
            setState(() {
              _deckImage = img;
            });
          }, existingUrl: widget.vehicle.deckImageUrl ?? ''),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Makers Plate Image', _makersPlateImage,
              (img) {
            setState(() {
              _makersPlateImage = img;
            });
          }, existingUrl: widget.vehicle.makersPlateImageUrl ?? ''),
          const SizedBox(height: 15),
          _buildAdditionalImagesSection(),
        ],
        const SizedBox(height: 15),
      ],
    ]);
  }

  Widget _buildImageSectionWithTitle(
      String title, Uint8List? image, Function(Uint8List?) onImagePicked,
      {String? existingUrl}) {
    final bool hasExistingUrl =
        existingUrl != null && existingUrl.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        InkWell(
          onTap: () {
            if (image != null) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(title),
                  content:
                      const Text('What would you like to do with this image?'),
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
                        child: const Text('Cancel')),
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
          child: _buildStyledContainer(
              child: image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.memory(image,
                          fit: BoxFit.cover,
                          height: 150,
                          width: double.infinity),
                    )
                  : hasExistingUrl
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(existingUrl,
                              fit: BoxFit.cover,
                              height: 150,
                              width: double.infinity),
                        )
                      : const Column(
                          children: [
                            Icon(Icons.camera_alt,
                                color: Colors.white, size: 50.0),
                            SizedBox(height: 10),
                            Text('Tap to upload image',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white70),
                                textAlign: TextAlign.center),
                          ],
                        )),
        ),
      ],
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

  Widget _buildAdditionalImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Additional Images',
            style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        for (int i = 0; i < _additionalImagesList.length; i++)
          _buildItemWidget(i, _additionalImagesList[i], _additionalImagesList,
              _showAdditionalImageSourceDialog),
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
        const Text('Additional Images - Trailer A',
            style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        for (int i = 0; i < _additionalImagesListTrailerA.length; i++)
          _buildItemWidget(i, _additionalImagesListTrailerA[i],
              _additionalImagesListTrailerA, _showAdditionalImageSourceDialog),
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
        const Text('Additional Images - Trailer B',
            style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        for (int i = 0; i < _additionalImagesListTrailerB.length; i++)
          _buildItemWidget(i, _additionalImagesListTrailerB[i],
              _additionalImagesListTrailerB, _showAdditionalImageSourceDialog),
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
            label: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Future<void> _updateDataAndFinish() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      Map<String, dynamic> updatedData = {
        'referenceNumber': _referenceNumberController.text,
        'makeModel': _makeController.text,
        'year': _yearController.text,
        'sellingPrice': _sellingPriceController.text,
        'trailerType': _selectedTrailerType,
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': currentUser?.uid,
      };

      debugPrint('DEBUG: Updating trailer with type: $_selectedTrailerType');

      if (_selectedMainImage != null) {
        String? mainUrl = await _uploadFileToFirebaseStorage(
            _selectedMainImage!, 'vehicle_images');
        updatedData['mainImageUrl'] = mainUrl ?? widget.vehicle.mainImageUrl;
      }

      if (_natisRc1File != null) {
        String? natisUrl = await _uploadFileToFirebaseStorage(
            _natisRc1File!, 'vehicle_documents');
        updatedData['natisDocumentUrl'] =
            natisUrl ?? widget.vehicle.toMap()['natisDocumentUrl'];
      }

      Map<String, dynamic> trailerExtraInfo = {};
      if (_selectedTrailerType == 'Superlink') {
        trailerExtraInfo = {
          'trailerA': {
            'length': _lengthTrailerAController.text,
            'vin': _vinAController.text,
            'registration': _registrationAController.text,
            'frontImageUrl': _frontImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _frontImageA!, 'vehicle_images')
                : _frontImageAUrl ?? '',
            'sideImageUrl': _sideImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _sideImageA!, 'vehicle_images')
                : _sideImageAUrl ?? '',
            'tyresImageUrl': _tyresImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _tyresImageA!, 'vehicle_images')
                : _tyresImageAUrl ?? '',
            'chassisImageUrl': _chassisImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _chassisImageA!, 'vehicle_images')
                : _chassisImageAUrl ?? '',
            'deckImageUrl': _deckImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _deckImageA!, 'vehicle_images')
                : _deckImageAUrl ?? '',
            'makersPlateImageUrl': _makersPlateImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _makersPlateImageA!, 'vehicle_images')
                : _makersPlateImageAUrl ?? '',
            'additionalImages':
                await _uploadListItems(_additionalImagesListTrailerA),
          },
          'trailerB': {
            'length': _lengthTrailerBController.text,
            'vin': _vinBController.text,
            'registration': _registrationBController.text,
            'frontImageUrl': _frontImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _frontImageB!, 'vehicle_images')
                : _frontImageBUrl ?? '',
            'sideImageUrl': _sideImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _sideImageB!, 'vehicle_images')
                : _sideImageBUrl ?? '',
            'tyresImageUrl': _tyresImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _tyresImageB!, 'vehicle_images')
                : _tyresImageBUrl ?? '',
            'chassisImageUrl': _chassisImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _chassisImageB!, 'vehicle_images')
                : _chassisImageBUrl ?? '',
            'deckImageUrl': _deckImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _deckImageB!, 'vehicle_images')
                : _deckImageBUrl ?? '',
            'makersPlateImageUrl': _makersPlateImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _makersPlateImageB!, 'vehicle_images')
                : _makersPlateImageBUrl ?? '',
            'additionalImages':
                await _uploadListItems(_additionalImagesListTrailerB),
          },
        };
      } else if (_selectedTrailerType == 'Tri-Axle') {
        trailerExtraInfo = {
          'lengthTrailer': _lengthTrailerController.text,
          'vin': _vinController.text,
          'registration': _registrationController.text,
          'frontImageUrl': _frontImage != null
              ? await _uploadFileToFirebaseStorage(
                  _frontImage!, 'vehicle_images')
              : widget.vehicle.frontImageUrl ?? '',
          'sideImageUrl': _sideImage != null
              ? await _uploadFileToFirebaseStorage(
                  _sideImage!, 'vehicle_images')
              : widget.vehicle.sideImageUrl ?? '',
          'tyresImageUrl': _tyresImage != null
              ? await _uploadFileToFirebaseStorage(
                  _tyresImage!, 'vehicle_images')
              : widget.vehicle.tyresImageUrl ?? '',
          'chassisImageUrl': _chassisImage != null
              ? await _uploadFileToFirebaseStorage(
                  _chassisImage!, 'vehicle_images')
              : widget.vehicle.chassisImageUrl ?? '',
          'deckImageUrl': _deckImage != null
              ? await _uploadFileToFirebaseStorage(
                  _deckImage!, 'vehicle_images')
              : widget.vehicle.deckImageUrl ?? '',
          'makersPlateImageUrl': _makersPlateImage != null
              ? await _uploadFileToFirebaseStorage(
                  _makersPlateImage!, 'vehicle_images')
              : widget.vehicle.makersPlateImageUrl ?? '',
          'additionalImages': await _uploadListItems(_additionalImagesList),
        };
        // Debug output for tri-axle update data:
        debugPrint('DEBUG: Tri-Axle Update Data:');
        debugPrint('  Length Trailer: ${_lengthTrailerController.text}');
        debugPrint('  VIN: ${_vinController.text}');
        debugPrint('  Registration: ${_registrationController.text}');
      }
      updatedData['trailerExtraInfo'] = trailerExtraInfo;
      debugPrint('DEBUG: Updated trailerExtraInfo: $trailerExtraInfo');

      final docRef = FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicle.id);
      await docRef.update(updatedData);
      debugPrint('DEBUG: Trailer updated successfully.');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trailer updated successfully')));
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomePage()));
    } catch (e) {
      debugPrint('DEBUG: Error updating trailer: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating trailer: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _uploadListItems(
      List<Map<String, dynamic>> items) async {
    List<Map<String, dynamic>> uploadedItems = [];
    for (var item in items) {
      if (item['image'] != null) {
        String? imageUrl =
            await _uploadFileToFirebaseStorage(item['image'], 'vehicle_images');
        uploadedItems.add(
            {'description': item['description'], 'imageUrl': imageUrl ?? ''});
      } else {
        uploadedItems.add({'description': item['description'], 'imageUrl': ''});
      }
    }
    return uploadedItems;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: GradientBackground(
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            centerTitle: true,
            title: const Text('Edit Trailer'),
          ),
          body: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    children: [
                      _buildMainImageSection(),
                      const SizedBox(height: 20),
                      _buildFormSection(),
                      const SizedBox(height: 30),
                      CustomButton(
                        text: 'Update Trailer',
                        borderColor: AppColors.orange,
                        onPressed: _updateDataAndFinish,
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainImageSection() {
    return GestureDetector(
      onTap: () {
        _pickImageOrFile(
          title: 'Select Main Image',
          pickImageOnly: true,
          callback: (file, fileName) {
            if (file != null) {
              setState(() {
                _selectedMainImage = file;
              });
            }
          },
        );
      },
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
            else if (widget.vehicle.mainImageUrl != null &&
                widget.vehicle.mainImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(
                  widget.vehicle.mainImageUrl ?? '',
                  width: double.infinity,
                  height: _imageHeight,
                  fit: BoxFit.cover,
                ),
              )
            else
              _buildStyledContainer(
                child: const Center(
                    child: Text('Tap to upload main image',
                        style: TextStyle(color: Colors.white70))),
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
}
