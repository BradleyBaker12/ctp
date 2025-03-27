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
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
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
import 'package:ctp/providers/user_provider.dart';

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
  // final List<Map<String, dynamic>> _additionalImagesListTrailerA = [];

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
  // final List<Map<String, dynamic>> _additionalImagesListTrailerB = [];

  // === Documents and Main Image ===
  Uint8List? _natisRc1File;
  String? _natisRc1FileName;
  Uint8List? _selectedMainImage;
  // Existing NATIS/RC1 document fields.
  String? _existingNatisRc1Url;
  String? _existingNatisRc1Name;
  // NEW: Service History file (if any)
  Uint8List? _serviceHistoryFile;
  String? _serviceHistoryFileName;
  String? _existingServiceHistoryUrl;

  // For Trailer A NATIS document:
  String? _existingNatisTrailerADoc1Url;
  String? _existingNatisTrailerADoc1Name;

// For Trailer B NATIS document:
  String? _existingNatisTrailerBDoc1Url;
  String? _existingNatisTrailerBDoc1Name;

  // === Damage & Additional Features (Missing in original edit form) ===
  String _featuresCondition = 'no';
  final List<Map<String, dynamic>> _featureList = [];

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

  // For Tri-Axle NATIS document:
  Uint8List? _natisTriAxleDocFile;
  String? _natisTriAxleDocFileName;
  String? _existingNatisTriAxleDocUrl;

// For Superlink Trailer A:
  final TextEditingController _axlesTrailerAController =
      TextEditingController();
  Uint8List? _natisTrailerADoc1File;
  String? _natisTrailerADoc1FileName;
  String? _existingNatisTrailerADocUrl;

// For Superlink Trailer B:
  final TextEditingController _axlesTrailerBController =
      TextEditingController();
  Uint8List? _natisTrailerBDoc1File;
  String? _natisTrailerBDoc1FileName;
  String? _existingNatisTrailerBDocUrl;

  // Add Tri-Axle image URLs
  String? _frontImageUrl;
  String? _sideImageUrl;
  String? _tyresImageUrl;
  String? _chassisImageUrl;
  String? _deckImageUrl;
  String? _makersPlateImageUrl;

  // === Admin selection fields ===
  List<Map<String, dynamic>> _transporterUsers = [];
  List<Map<String, dynamic>> _salesRepUsers = [];
  String? _selectedTransporterId;
  String? _selectedTransporterEmail;
  String? _selectedSalesRepId;
  String? _selectedSalesRepEmail;

  // Add this near other state variables
  String _damagesCondition = 'no';
  final List<Map<String, dynamic>> _damageList = [];

  @override
  void initState() {
    super.initState();
    // Preselect trailer type from vehicle data (defaulting to Superlink if not set)
    _selectedTrailerType = widget.vehicle.trailer?.trailerType ??
        widget.vehicle.toMap()['trailerType'] ??
        'Superlink';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final trailerFormProvider =
          Provider.of<TrailerFormProvider>(context, listen: false);
      final vehicleData = widget.vehicle.toMap();
      // Ensure trailerExtraInfo is available.
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
    _axlesTrailerAController.dispose();
    _axlesTrailerBController.dispose();
    _scrollController.dispose();
    for (var item in _damageList) {
      if (item['controller'] != null) {
        (item['controller'] as TextEditingController).dispose();
      }
    }
    for (var item in _featureList) {
      if (item['controller'] != null) {
        (item['controller'] as TextEditingController).dispose();
      }
    }
    super.dispose();
  }

  String? _getFileNameFromUrl(String? url) {
    if (url == null) return null;
    try {
      String fileName = url.split('/').last.split('?').first;
      return Uri.decodeComponent(fileName);
    } catch (e) {
      debugPrint('Error extracting filename from URL: $e');
      return null;
    }
  }

  void _populateVehicleData() {
    final data = widget.vehicle.toMap();
    debugPrint("DEBUG: Raw vehicle data: $data");

    Map<String, dynamic> trailerExtra = {};

    // Get trailer data with priority order
    if (widget.vehicle.trailer?.rawTrailerExtraInfo != null) {
      trailerExtra = Map<String, dynamic>.from(
          widget.vehicle.trailer!.rawTrailerExtraInfo!);
      debugPrint("DEBUG: Using trailer.rawTrailerExtraInfo: $trailerExtra");
    } else if (data['trailerExtraInfo'] != null &&
        data['trailerExtraInfo'] is Map) {
      trailerExtra = Map<String, dynamic>.from(data['trailerExtraInfo']);
      debugPrint("DEBUG: Using data.trailerExtraInfo: $trailerExtra");
    } else if (data['trailer']?['trailerExtraInfo'] != null) {
      trailerExtra =
          Map<String, dynamic>.from(data['trailer']['trailerExtraInfo']);
      debugPrint("DEBUG: Using data.trailer.trailerExtraInfo: $trailerExtra");
    }

    setState(() {
      // Basic fields
      _referenceNumberController.text =
          data['referenceNumber']?.toString() ?? '';
      _makeController.text = data['makeModel']?.toString() ?? '';
      _yearController.text = data['year']?.toString() ?? '';
      _sellingPriceController.text = data['sellingPrice']?.toString() ?? '';
      _axlesController.text = data['axles']?.toString() ?? '';
      _lengthController.text = data['length']?.toString() ?? '';
      _sellingPriceController.text = data['sellingPrice']?.toString() ?? '';

      // Document URLs
      _existingNatisRc1Url = data['natisDocumentUrl'];
      _existingNatisRc1Name = _getFileNameFromUrl(_existingNatisRc1Url);
      _existingServiceHistoryUrl = data['serviceHistoryUrl'];

      if (_selectedTrailerType == 'Superlink') {
        final trailerA =
            Map<String, dynamic>.from(trailerExtra['trailerA'] ?? {});
        final trailerB =
            Map<String, dynamic>.from(trailerExtra['trailerB'] ?? {});

        debugPrint("DEBUG: Populating Trailer A fields with: $trailerA");
        debugPrint("DEBUG: Populating Trailer B fields with: $trailerB");

        // Trailer A
        _lengthTrailerAController.text = trailerA['length']?.toString() ?? '';
        _vinAController.text = trailerA['vin']?.toString() ?? '';
        _registrationAController.text =
            trailerA['registration']?.toString() ?? '';
        _axlesTrailerAController.text = trailerA['axles']?.toString() ?? '';

        debugPrint(
            "DEBUG: Set Trailer A - Length: ${_lengthTrailerAController.text}, VIN: ${_vinAController.text}, Reg: ${_registrationAController.text}");

        // Trailer A Image URLs
        _frontImageAUrl = trailerA['frontImageUrl'];
        _sideImageAUrl = trailerA['sideImageUrl'];
        _tyresImageAUrl = trailerA['tyresImageUrl'];
        _chassisImageAUrl = trailerA['chassisImageUrl'];
        _deckImageAUrl = trailerA['deckImageUrl'];
        _makersPlateImageAUrl = trailerA['makersPlateImageUrl'];
        _existingNatisTrailerADocUrl = trailerA['natisDocUrl'];

        _existingNatisTrailerADoc1Url =
            trailerA['natisDocUrl']?.toString() ?? '';
        _existingNatisTrailerADoc1Name =
            _getFileNameFromUrl(_existingNatisTrailerADoc1Url);
        debugPrint(
            "NATIS Trailer A Document: '$_existingNatisTrailerADoc1Url', name: '$_existingNatisTrailerADoc1Name'");

        _existingNatisTrailerBDoc1Url =
            trailerB['natisDocUrl']?.toString() ?? '';
        _existingNatisTrailerBDoc1Name =
            _getFileNameFromUrl(_existingNatisTrailerBDoc1Url);
        debugPrint(
            "NATIS Trailer B Document: '$_existingNatisTrailerBDoc1Url', name: '$_existingNatisTrailerBDoc1Name'");

        // Trailer B
        _lengthTrailerBController.text = trailerB['length']?.toString() ?? '';
        _vinBController.text = trailerB['vin']?.toString() ?? '';
        _registrationBController.text =
            trailerB['registration']?.toString() ?? '';
        _axlesTrailerBController.text = trailerA['axles']?.toString() ?? '';

        debugPrint(
            "DEBUG: Set Trailer B - Length: ${_lengthTrailerBController.text}, VIN: ${_vinBController.text}, Reg: ${_registrationBController.text}");

        // Trailer B Image URLs
        _frontImageBUrl = trailerB['frontImageUrl'];
        _sideImageBUrl = trailerB['sideImageUrl'];
        _tyresImageBUrl = trailerB['tyresImageUrl'];
        _chassisImageBUrl = trailerB['chassisImageUrl'];
        _deckImageBUrl = trailerB['deckImageUrl'];
        _makersPlateImageBUrl = trailerB['makersPlateImageUrl'];
      } else if (_selectedTrailerType == 'Tri-Axle') {
        _lengthTrailerController.text =
            trailerExtra['lengthTrailer']?.toString() ?? '';
        _vinController.text = trailerExtra['vin']?.toString() ?? '';
        _registrationController.text =
            trailerExtra['registration']?.toString() ?? '';
      }

      _featureList.clear();
      if (data['features'] != null && data['features'] is List) {
        _featureList.addAll(
            List<Map<String, dynamic>>.from(data['features']).map((feature) {
          return {
            'description': feature['description'] ?? '',
            'imageUrl': feature['imageUrl'] ?? '',
            'image': null,
            'controller':
                TextEditingController(text: feature['description'] ?? ''),
          };
        }).toList());
      }
      _featuresCondition = (_featureList.isNotEmpty) ? 'yes' : 'no';
      debugPrint("DEBUG: Features populated: ${_featureList.length} items");

      // Add damage population logic
      _damageList.clear();
      if (data['damages'] != null && data['damages'] is List) {
        _damageList.addAll(
            List<Map<String, dynamic>>.from(data['damages']).map((damage) {
          return {
            'description': damage['description'] ?? '',
            'imageUrl': damage['imageUrl'] ?? '',
            'image': null,
            'controller':
                TextEditingController(text: damage['description'] ?? ''),
          };
        }).toList());
      }
      _damagesCondition = (_damageList.isNotEmpty) ? 'yes' : 'no';
    });
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
      default:
        return Icons.insert_drive_file;
    }
  }

  void _showTrailerADocumentOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Trailer A Document Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.remove_red_eye),
                title: const Text('View Document'),
                onTap: () {
                  Navigator.pop(context);
                  _viewTrailerADocument(); // Implement _viewTrailerADocument() to open _existingNatisTrailerADoc1Url
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Replace Document'),
                onTap: () {
                  Navigator.pop(context);
                  _pickTrailerADocFile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _pickTrailerADocFile() async {
    // TODO: implement file picker logic for Trailer A document.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pick Trailer A document file')),
    );
  }

  void _showTrailerBDocumentOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Trailer B Document Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.remove_red_eye),
                title: const Text('View Document'),
                onTap: () {
                  Navigator.pop(context);
                  _viewTrailerBDocument(); // Implement _viewTrailerBDocument() to open _existingNatisTrailerBDoc1Url
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Replace Document'),
                onTap: () {
                  Navigator.pop(context);
                  _pickTrailerBDocFile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _viewTrailerADocument() async {
    if (_existingNatisTrailerADoc1Url != null &&
        _existingNatisTrailerADoc1Url!.isNotEmpty) {
      final Uri uri = Uri.parse(_existingNatisTrailerADoc1Url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _viewTrailerBDocument() async {
    if (_existingNatisTrailerBDoc1Url != null &&
        _existingNatisTrailerBDoc1Url!.isNotEmpty) {
      final Uri uri = Uri.parse(_existingNatisTrailerBDoc1Url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _pickTrailerBDocFile() async {
    // TODO: implement file picker logic for Trailer B document.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pick Trailer B document file')),
    );
  }

  Widget _buildNatisTrailerADocSection() {
    Widget buildFileDisplay(String? fileName, bool isExisting) {
      String extension = fileName?.split('.').last.toLowerCase() ?? '';
      IconData iconData = _getFileIcon(extension);
      return Column(
        children: [
          Icon(iconData, color: Colors.white, size: 50.0),
          const SizedBox(height: 10),
          Text(
            fileName ?? (isExisting ? 'Existing Document' : 'Select Document'),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
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
          child: Text('NATIS TRAILER A DOCUMENT'.toUpperCase(),
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w900),
              textAlign: TextAlign.center),
        ),
        const SizedBox(height: 15),
        InkWell(
          onTap: () {
            if (_existingNatisTrailerADoc1Url != null ||
                _natisTrailerADoc1File != null) {
              _showTrailerADocumentOptions();
            } else {
              _pickTrailerADocFile();
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
            child: _natisTrailerADoc1File != null
                ? _buildFileDisplay(
                    _natisTrailerADoc1FileName?.split('/').last, false)
                : (_existingNatisTrailerADoc1Name != null &&
                        _existingNatisTrailerADoc1Name!.isNotEmpty)
                    ? _buildFileDisplay(_existingNatisTrailerADoc1Name, true)
                    : _buildFileDisplay(null, false),
          ),
        ),
      ],
    );
  }

  Widget _buildNatisTrailerBDocSection() {
    Widget buildFileDisplay(String? fileName, bool isExisting) {
      String extension = fileName?.split('.').last.toLowerCase() ?? '';
      IconData iconData = _getFileIcon(extension);
      return Column(
        children: [
          Icon(iconData, color: Colors.white, size: 50.0),
          const SizedBox(height: 10),
          Text(
            fileName ?? (isExisting ? 'Existing Document' : 'Select Document'),
            style: const TextStyle(color: Colors.white70, fontSize: 14),
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
          child: Text('NATIS TRAILER B DOCUMENT'.toUpperCase(),
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w900),
              textAlign: TextAlign.center),
        ),
        const SizedBox(height: 15),
        InkWell(
          onTap: () {
            if (_existingNatisTrailerBDoc1Url != null ||
                _natisTrailerBDoc1File != null) {
              _showTrailerBDocumentOptions();
            } else {
              _pickTrailerBDocFile();
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
            child: _natisTrailerBDoc1File != null
                ? _buildFileDisplay(
                    _natisTrailerBDoc1FileName?.split('/').last, false)
                : (_existingNatisTrailerBDoc1Name != null &&
                        _existingNatisTrailerBDoc1Name!.isNotEmpty)
                    ? _buildFileDisplay(_existingNatisTrailerBDoc1Name, true)
                    : _buildFileDisplay(null, false),
          ),
        ),
      ],
    );
  }

  // Add this new widget below your _buildFeaturesSection() function.
  Widget _buildDamageSection() {
    return _buildItemSection(
      title: 'Damages',
      items: _damageList,
      onAdd: () {
        setState(() {
          _damageList.add({
            'description': '',
            'image': null,
            'controller': TextEditingController(),
          });
        });
      },
      showImageSourceDialog: _showDamageImageSourceDialog,
    );
  }

  // --- File and Image Pickers (similar to upload form) ---
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

  // --- Service History File Picker ---
  Future<void> _pickServiceHistoryFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if (result != null && result.files.isNotEmpty) {
      final fileName = result.files.first.name;
      final bytes = result.files.first.bytes;
      setState(() {
        _serviceHistoryFile = bytes;
        _serviceHistoryFileName = fileName;
      });
    }
  }

  // --- Document Section for NATIS/RC1 (as in upload form) ---
  // Widget _buildNatisDocumentSection() {
  //   return Column(
  //     children: [
  //       Center(
  //         child: Text(
  //           'NATIS/RC1 DOCUMENTATION'.toUpperCase(),
  //           style: const TextStyle(
  //               fontSize: 15, color: Colors.white, fontWeight: FontWeight.w900),
  //           textAlign: TextAlign.center,
  //         ),
  //       ),
  //       const SizedBox(height: 15),
  //       InkWell(
  //         onTap: () {
  //           final bool isDealer =
  //               Provider.of<UserProvider>(context, listen: false).getUserRole ==
  //                   'dealer';
  //           if (isDealer) {
  //             _viewDocument();
  //           } else {
  //             if (_existingNatisRc1Url != null || _natisRc1File != null) {
  //               _showDocumentOptions();
  //             } else {
  //               _pickNatisRc1File();
  //             }
  //           }
  //         },
  //         borderRadius: BorderRadius.circular(10.0),
  //         child: Container(
  //           width: double.infinity,
  //           padding: const EdgeInsets.all(16.0),
  //           decoration: BoxDecoration(
  //             color: const Color(0xFF0E4CAF).withOpacity(0.1),
  //             borderRadius: BorderRadius.circular(10.0),
  //             border: Border.all(color: const Color(0xFF0E4CAF), width: 2.0),
  //           ),
  //           child: _natisRc1File != null
  //               ? _buildFileDisplay(_natisRc1FileName?.split('/').last, false)
  //               : (_existingNatisRc1Url != null &&
  //                       _existingNatisRc1Url!.isNotEmpty)
  //                   ? _buildFileDisplay(
  //                       _getFileNameFromUrl(_existingNatisRc1Url), true)
  //                   : _buildFileDisplay(null, false),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // --- Service History Section ---
  Widget _buildServiceHistorySection() {
    return Column(
      children: [
        Center(
          child: Text(
            'SERVICE HISTORY (IF ANY)'.toUpperCase(),
            style: const TextStyle(
                fontSize: 15, color: Colors.white, fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 15),
        InkWell(
          onTap: () {
            final bool isDealer =
                Provider.of<UserProvider>(context, listen: false).getUserRole ==
                    'dealer';
            if (isDealer) {
              _viewServiceHistory();
            } else {
              if (_existingServiceHistoryUrl != null ||
                  _serviceHistoryFile != null) {
                _showServiceHistoryOptions();
              } else {
                _pickServiceHistoryFile();
              }
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
            child: _serviceHistoryFile != null
                ? _buildFileDisplay(
                    _serviceHistoryFileName?.split('/').last, false)
                : (_existingServiceHistoryUrl != null &&
                        _existingServiceHistoryUrl!.isNotEmpty)
                    ? _buildFileDisplay(
                        _getFileNameFromUrl(_existingServiceHistoryUrl), true)
                    : _buildFileDisplay(null, false),
          ),
        ),
      ],
    );
  }

  void _showServiceHistoryOptions() {
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
                  _viewServiceHistory();
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Replace Document'),
                onTap: () {
                  Navigator.pop(context);
                  _pickServiceHistoryFile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Document',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _serviceHistoryFile = null;
                    _existingServiceHistoryUrl = null;
                    _serviceHistoryFileName = null;
                  });
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

  Future<void> _viewServiceHistory() async {
    final String? url =
        _serviceHistoryFileName == null ? _existingServiceHistoryUrl : null;
    if (url != null && url.isNotEmpty) {
      try {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open document')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening document: $e')),
        );
      }
    } else if (_serviceHistoryFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local document viewing not implemented')),
      );
    }
  }

  Widget _buildFeaturesSection() {
    return _buildItemSection(
      title: 'Additional Features',
      items: _featureList,
      onAdd: () {
        setState(() {
          _featureList.add({
            'description': '',
            'image': null,
            'controller': TextEditingController(),
          });
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

  // --- File display helper ---
  Widget _buildFileDisplay(String? fileName, bool isExisting) {
    String displayName =
        fileName ?? (isExisting ? 'Existing Document' : 'Select Document');
    String extension = fileName != null ? fileName.split('.').last : '';
    IconData iconData;
    switch (extension.toLowerCase()) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        break;
      case 'doc':
      case 'docx':
        iconData = Icons.description;
        break;
      case 'xls':
      case 'xlsx':
        iconData = Icons.grid_on;
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
        iconData = Icons.image;
        break;
      default:
        iconData = Icons.insert_drive_file;
    }
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

  // --- Document Options for NATIS/RC1 ---
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
                  setState(() {
                    _natisRc1File = null;
                    _existingNatisRc1Url = null;
                    _existingNatisRc1Name = null;
                  });
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

  // --- Main form section ---
  Widget _buildFormSection(bool isDealer) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Admin fields: Transporter & Sales Rep
      if (Provider.of<UserProvider>(context, listen: false).getUserRole ==
          'admin') ...[
        const SizedBox(height: 15),
        _buildTransporterField(),
        const SizedBox(height: 15),
        _buildSalesRepField(),
      ],
      const SizedBox(height: 15),
      CustomTextField(
        controller: _referenceNumberController,
        hintText: 'Reference Number',
        enabled: !isDealer,
      ),
      const SizedBox(height: 15),
      CustomDropdown(
        hintText: 'Select Trailer Type',
        value: _selectedTrailerType,
        items: const ['Superlink', 'Tri-Axle', 'Double Axle', 'Other'],
        onChanged: (value) {
          if (!isDealer) {
            setState(() {
              _selectedTrailerType = value;
            });
          }
        },
        enabled: !isDealer,
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
        CustomTextField(
          controller: _makeController,
          hintText: 'Make',
          enabled: !isDealer,
        ),
        const SizedBox(height: 15),
        CustomTextField(
          controller: _yearController,
          hintText: 'Year',
          keyboardType: TextInputType.number,
          enabled: !isDealer,
        ),
        const SizedBox(height: 15),
        CustomTextField(
          controller: _sellingPriceController,
          hintText: 'Expected Selling Price',
          keyboardType: TextInputType.number,
          inputFormatter: [
            FilteringTextInputFormatter.digitsOnly,
            ThousandsSeparatorInputFormatter()
          ],
          enabled: !isDealer,
        ),
        // const SizedBox(height: 15),
        // _buildNatisDocumentSection(),
        const SizedBox(height: 15),
        // NEW: For Superlink add Number of Axles
        if (_selectedTrailerType == 'Tri-Axle') ...[
          CustomTextField(
            controller: _axlesController,
            hintText: 'Number of Axles',
            keyboardType: TextInputType.number,
            enabled: !isDealer,
          ),
          const SizedBox(height: 15),
        ],
        // Trailer type specific sections
        if (_selectedTrailerType == 'Superlink') ...[
          const Text("Trailer A Details",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 15),
          CustomTextField(
            controller: _lengthTrailerAController,
            hintText: 'Length Trailer A',
            keyboardType: TextInputType.number,
            enabled: !isDealer,
          ),
          const SizedBox(height: 15),
          CustomTextField(
            controller: _vinAController,
            hintText: 'VIN A',
            inputFormatter: [UpperCaseTextFormatter()],
            enabled: !isDealer,
          ),
          const SizedBox(height: 15),
          CustomTextField(
            controller: _registrationAController,
            hintText: 'Registration A',
            inputFormatter: [UpperCaseTextFormatter()],
            enabled: !isDealer,
          ),
          const SizedBox(height: 15),
          // Add number of axles for Trailer A:
          CustomTextField(
            controller: _axlesTrailerAController,
            hintText: 'Number of Axles Trailer A',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),
// NATIS document upload for Trailer A:
          // NATIS document upload for Trailer A:
          const Text(
            'NATIS Document for Trailer A',
            style: TextStyle(
                fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
         // Instead of inline code, add:
          const SizedBox(height: 15),
          _buildNatisTrailerADocSection(),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Trailer A - Front Image', _frontImageA,
              (img) {
            if (!isDealer) {
              setState(() {
                _frontImageA = img;
              });
            }
          }, existingUrl: _frontImageAUrl),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Trailer A - Side Image', _sideImageA,
              (img) {
            if (!isDealer) {
              setState(() {
                _sideImageA = img;
              });
            }
          }, existingUrl: _sideImageAUrl),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Trailer A - Tyres Image', _tyresImageA,
              (img) {
            if (!isDealer) {
              setState(() {
                _tyresImageA = img;
              });
            }
          }, existingUrl: _tyresImageAUrl),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle(
              'Trailer A - Chassis Image', _chassisImageA, (img) {
            if (!isDealer) {
              setState(() {
                _chassisImageA = img;
              });
            }
          }, existingUrl: _chassisImageAUrl),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Trailer A - Deck Image', _deckImageA,
              (img) {
            if (!isDealer) {
              setState(() {
                _deckImageA = img;
              });
            }
          }, existingUrl: _deckImageAUrl),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle(
              'Trailer A - Makers Plate Image', _makersPlateImageA, (img) {
            if (!isDealer) {
              setState(() {
                _makersPlateImageA = img;
              });
            }
          }, existingUrl: _makersPlateImageAUrl),
          const SizedBox(height: 15),
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
            keyboardType: TextInputType.number,
            enabled: !isDealer,
          ),
          const SizedBox(height: 15),
          CustomTextField(
            controller: _vinBController,
            hintText: 'VIN B',
            inputFormatter: [UpperCaseTextFormatter()],
            enabled: !isDealer,
          ),
          const SizedBox(height: 15),
          CustomTextField(
            controller: _registrationBController,
            hintText: 'Registration B',
            inputFormatter: [UpperCaseTextFormatter()],
            enabled: !isDealer,
          ),
          const SizedBox(height: 15),
          // Add number of axles for Trailer B:
          CustomTextField(
            controller: _axlesTrailerBController,
            hintText: 'Number of Axles Trailer B',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),
// NATIS document upload for Trailer B:
          // NATIS document upload for Trailer B:
          const Text(
            'NATIS Document 1 for Trailer B',
            style: TextStyle(
                fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
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
                            style:
                                TextStyle(fontSize: 14, color: Colors.white70),
                            textAlign: TextAlign.center),
                      ],
                    )
                  : Column(
                      children: [
                        Icon(Icons.description,
                            color: Colors.white, size: 50.0),
                        SizedBox(height: 10),
                        Text(_natisTrailerBDoc1FileName!.split('/').last,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Trailer B - Front Image', _frontImageB,
              (img) {
            if (!isDealer) {
              setState(() {
                _frontImageB = img;
              });
            }
          }, existingUrl: _frontImageBUrl),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Trailer B - Side Image', _sideImageB,
              (img) {
            if (!isDealer) {
              setState(() {
                _sideImageB = img;
              });
            }
          }, existingUrl: _sideImageBUrl),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Trailer B - Tyres Image', _tyresImageB,
              (img) {
            if (!isDealer) {
              setState(() {
                _tyresImageB = img;
              });
            }
          }, existingUrl: _tyresImageBUrl),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle(
              'Trailer B - Chassis Image', _chassisImageB, (img) {
            if (!isDealer) {
              setState(() {
                _chassisImageB = img;
              });
            }
          }, existingUrl: _chassisImageBUrl),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle('Trailer B - Deck Image', _deckImageB,
              (img) {
            if (!isDealer) {
              setState(() {
                _deckImageB = img;
              });
            }
          }, existingUrl: _deckImageBUrl),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle(
              'Trailer B - Makers Plate Image', _makersPlateImageB, (img) {
            if (!isDealer) {
              setState(() {
                _makersPlateImageB = img;
              });
            }
          }, existingUrl: _makersPlateImageBUrl),
          const SizedBox(height: 15),
        ]
        // Tri-Axle branch.
        else if (_selectedTrailerType == 'Tri-Axle') ...[
          const SizedBox(height: 15),
          CustomTextField(
            controller: _lengthTrailerController,
            hintText: 'Length Trailer',
            keyboardType: TextInputType.number,
            enabled: !isDealer,
          ),
          const SizedBox(height: 15),
          CustomTextField(
            controller: _vinController,
            hintText: 'VIN',
            inputFormatter: [UpperCaseTextFormatter()],
            enabled: !isDealer,
          ),
          const SizedBox(height: 15),
          CustomTextField(
            controller: _registrationController,
            hintText: 'Registration',
            inputFormatter: [UpperCaseTextFormatter()],
            enabled: !isDealer,
          ),
          const SizedBox(height: 15),
          const Text(
            'NATIS Document for Tri-Axle',
            style: TextStyle(
                fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
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
            },
            borderRadius: BorderRadius.circular(10.0),
            child: _buildStyledContainer(
              child: _natisTriAxleDocFile == null
                  ? const Column(
                      children: [
                        Icon(Icons.upload_file,
                            color: Colors.white, size: 50.0),
                        SizedBox(height: 10),
                        Text('Upload NATIS Document for Tri-Axle',
                            style:
                                TextStyle(fontSize: 14, color: Colors.white70),
                            textAlign: TextAlign.center),
                      ],
                    )
                  : Column(
                      children: [
                        Icon(Icons.description,
                            color: Colors.white, size: 50.0),
                        SizedBox(height: 10),
                        Text(_natisTriAxleDocFileName!.split('/').last,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle(
            'Front Trailer Image',
            _frontImage,
            (img) {
              if (!isDealer) {
                setState(() {
                  _frontImage = img;
                });
              }
            },
            existingUrl:
                widget.vehicle.trailer?.rawTrailerExtraInfo?['frontImageUrl'] ??
                    '',
          ),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle(
            'Side Image',
            _sideImage,
            (img) {
              if (!isDealer) {
                setState(() {
                  _sideImage = img;
                });
              }
            },
            existingUrl:
                widget.vehicle.trailer?.rawTrailerExtraInfo?['sideImageUrl'] ??
                    '',
          ),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle(
            'Tyres Image',
            _tyresImage,
            (img) {
              if (!isDealer) {
                setState(() {
                  _tyresImage = img;
                });
              }
            },
            existingUrl:
                widget.vehicle.trailer?.rawTrailerExtraInfo?['tyresImageUrl'] ??
                    '',
          ),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle(
            'Chassis Image',
            _chassisImage,
            (img) {
              if (!isDealer) {
                setState(() {
                  _chassisImage = img;
                });
              }
            },
            existingUrl: widget
                    .vehicle.trailer?.rawTrailerExtraInfo?['chassisImageUrl'] ??
                '',
          ),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle(
            'Deck Image',
            _deckImage,
            (img) {
              if (!isDealer) {
                setState(() {
                  _deckImage = img;
                });
              }
            },
            existingUrl:
                widget.vehicle.trailer?.rawTrailerExtraInfo?['deckImageUrl'] ??
                    '',
          ),
          const SizedBox(height: 15),
          _buildImageSectionWithTitle(
            'Makers Plate Image',
            _makersPlateImage,
            (img) {
              if (!isDealer) {
                setState(() {
                  _makersPlateImage = img;
                });
              }
            },
            existingUrl: widget.vehicle.trailer
                    ?.rawTrailerExtraInfo?['makersPlateImageUrl'] ??
                '',
          ),
          const SizedBox(height: 15),
        ],
        const SizedBox(height: 15),
        // Service History Section
        _buildServiceHistorySection(),
        const SizedBox(height: 20),
        // Damages Section
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
                  }
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (_damagesCondition == 'yes') _buildDamageSection(),
        const SizedBox(height: 20),
        // Additional Features Section
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
      ],
    ]);
  }

  // --- Main Image Section ---
  Widget _buildMainImageSection(bool isDealer) {
    return GestureDetector(
      onTap: () {
        if (!isDealer) {
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
        }
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

  // Modified _buildItemWidget.
  Widget _buildItemWidget(
      int index,
      Map<String, dynamic> item,
      List<Map<String, dynamic>> itemList,
      void Function(Map<String, dynamic>) showImageSourceDialog) {
    // Ensure controller is initialized
    if (item['controller'] == null) {
      item['controller'] =
          TextEditingController(text: item['description'] ?? '');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: item['controller'] as TextEditingController,
          hintText: 'Describe Item',
          onChanged: (val) {
            setState(() {
              item['description'] = val;
              // Ensure the controller text is also updated
              if (item['controller'].text != val) {
                item['controller'].text = val;
              }
            });
          },
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () {
            showImageSourceDialog(item);
          },
          child: _buildStyledContainer(
            child: item['image'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.memory(item['image'],
                        fit: BoxFit.cover, height: 150, width: double.infinity),
                  )
                : (item['imageUrl'] != null &&
                        (item['imageUrl'] as String).isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(item['imageUrl'],
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

  // --- Transporter & Sales Rep Fields ---
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

  Widget _buildSalesRepField() {
    final List<String> repEmails =
        _salesRepUsers.map((e) => e['email'] as String).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Sales Rep: ${_selectedSalesRepEmail ?? 'None'}",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 15),
        CustomDropdown(
          hintText: 'Select Sales Rep',
          value: _selectedSalesRepEmail,
          items: repEmails,
          onChanged: (value) {
            setState(() {
              _selectedSalesRepEmail = value;
              try {
                final matching =
                    _salesRepUsers.firstWhere((user) => user['email'] == value);
                _selectedSalesRepId = matching['id'];
              } catch (e) {
                _selectedSalesRepId = null;
              }
            });
          },
        ),
      ],
    );
  }

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

  // --- Update data ---
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

      // Update main image if replaced.
      if (_selectedMainImage != null) {
        String? mainUrl = await _uploadFileToFirebaseStorage(
          _selectedMainImage!,
          'vehicle_images',
        );
        updatedData['mainImageUrl'] = mainUrl ?? widget.vehicle.mainImageUrl;
      }

      // Update NATIS/RC1 document if replaced.
      if (_natisRc1File != null && _natisRc1FileName != null) {
        String? natisUrl = await _uploadFileToFirebaseStorage(
          _natisRc1File!,
          'vehicle_documents',
          _natisRc1FileName!,
        );
        updatedData['natisDocumentUrl'] = natisUrl;
      }

      // Update Service History if replaced.
      if (_serviceHistoryFile != null && _serviceHistoryFileName != null) {
        String? serviceUrl = await _uploadFileToFirebaseStorage(
          _serviceHistoryFile!,
          'vehicle_documents',
          _serviceHistoryFileName!,
        );
        updatedData['serviceHistoryUrl'] = serviceUrl;
      }

      // Build trailerExtraInfo
      Map<String, dynamic> trailerExtraInfo = {};
      if (_selectedTrailerType == 'Superlink') {
        trailerExtraInfo = {
          'trailerA': {
            'length': _lengthTrailerAController.text,
            'vin': _vinAController.text,
            'registration': _registrationAController.text,
            'axles': _axlesTrailerAController.text,
            'natisDocUrl': _natisTrailerADoc1File != null
                ? await _uploadFileToFirebaseStorage(_natisTrailerADoc1File!,
                    'vehicle_documents', _natisTrailerADoc1FileName)
                : _existingNatisTrailerADocUrl ?? '',
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
          },
          'trailerB': {
            'length': _lengthTrailerBController.text,
            'vin': _vinBController.text,
            'registration': _registrationBController.text,
            'axles': _axlesTrailerBController.text,
            'natisDocUrl': _natisTrailerBDoc1File != null
                ? await _uploadFileToFirebaseStorage(_natisTrailerBDoc1File!,
                    'vehicle_documents', _natisTrailerBDoc1FileName)
                : _existingNatisTrailerBDocUrl ?? '',
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
          },
        };
      } else if (_selectedTrailerType == 'Tri-Axle') {
        trailerExtraInfo = {
          'lengthTrailer': _lengthTrailerController.text,
          'vin': _vinController.text,
          'registration': _registrationController.text,
          'natisDocUrl': _natisTriAxleDocFile != null
              ? await _uploadFileToFirebaseStorage(_natisTriAxleDocFile!,
                  'vehicle_documents', _natisTriAxleDocFileName)
              : _existingNatisTriAxleDocUrl ?? '',
          'frontImageUrl': _frontImage != null
              ? await _uploadFileToFirebaseStorage(
                  _frontImage!, 'vehicle_images')
              : widget.vehicle.trailer?.rawTrailerExtraInfo?['frontImageUrl'] ??
                  '',
          'sideImageUrl': _sideImage != null
              ? await _uploadFileToFirebaseStorage(
                  _sideImage!, 'vehicle_images')
              : widget.vehicle.trailer?.rawTrailerExtraInfo?['sideImageUrl'] ??
                  '',
          'tyresImageUrl': _tyresImage != null
              ? await _uploadFileToFirebaseStorage(
                  _tyresImage!, 'vehicle_images')
              : widget.vehicle.trailer?.rawTrailerExtraInfo?['tyresImageUrl'] ??
                  '',
          'chassisImageUrl': _chassisImage != null
              ? await _uploadFileToFirebaseStorage(
                  _chassisImage!, 'vehicle_images')
              : widget.vehicle.trailer
                      ?.rawTrailerExtraInfo?['chassisImageUrl'] ??
                  '',
          'deckImageUrl': _deckImage != null
              ? await _uploadFileToFirebaseStorage(
                  _deckImage!, 'vehicle_images')
              : widget.vehicle.trailer?.rawTrailerExtraInfo?['deckImageUrl'] ??
                  '',
          'makersPlateImageUrl': _makersPlateImage != null
              ? await _uploadFileToFirebaseStorage(
                  _makersPlateImage!, 'vehicle_images')
              : widget.vehicle.trailer
                      ?.rawTrailerExtraInfo?['makersPlateImageUrl'] ??
                  '',
        };
      }

      // Add features to updated data.
      updatedData['trailerExtraInfo'] = trailerExtraInfo;
      updatedData['featuresCondition'] = _featuresCondition;
      updatedData['features'] = await _uploadListItems(_featureList);

      // Add damages to updated data
      updatedData['damagesCondition'] = _damagesCondition;
      updatedData['damages'] = await _uploadListItems(_damageList);

      // Update admin assignments.
      if (Provider.of<UserProvider>(context, listen: false).getUserRole ==
          'admin') {
        if (_selectedTransporterId != null) {
          updatedData['userId'] = _selectedTransporterId;
        }
        if (_selectedSalesRepId != null) {
          updatedData['assignedSalesRepId'] = _selectedSalesRepId;
        }
      }

      final docRef = FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicle.id);
      await docRef.update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trailer updated successfully')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating trailer: $e')),
      );
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
    }
    return uploadedItems;
  }

  Future<String?> _uploadFileToFirebaseStorage(
      Uint8List file, String folderName,
      [String? fileName, String? contentType]) async {
    try {
      final String actualFileName =
          fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String actualContentType = contentType ?? 'image/jpeg';
      final storageRef =
          FirebaseStorage.instance.ref().child('$folderName/$actualFileName');
      final metadata =
          firebase_storage.SettableMetadata(contentType: actualContentType);
      await storageRef.putData(file, metadata);
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint('File upload error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

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
                      _buildMainImageSection(isDealer),
                      const SizedBox(height: 20),
                      _buildFormSection(isDealer),
                      const SizedBox(height: 30),
                      if (!isDealer)
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

  // Opens an image in full-screen mode.
  void _openFullScreenImage({Uint8List? image, String? imageUrl}) {
    showDialog(
      context: context,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black,
          child: Center(
            child: image != null
                ? Image.memory(image, fit: BoxFit.contain)
                : imageUrl != null
                    ? Image.network(imageUrl, fit: BoxFit.contain)
                    : const SizedBox(),
          ),
        ),
      ),
    );
  }

// Displays an image upload section with title, handling new image picking and full-screen preview.
// The optional [existingUrl] is used to display an already stored image.
  Widget _buildImageSectionWithTitle(
      String title, Uint8List? image, Function(Uint8List?) onImagePicked,
      {String? existingUrl}) {
    final bool hasExistingUrl =
        existingUrl != null && existingUrl.trim().isNotEmpty;
    final bool hasImage = image != null || hasExistingUrl;
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
            if (hasImage) {
              _openFullScreenImage(
                image: image,
                imageUrl:
                    (hasExistingUrl && image == null) ? existingUrl : null,
              );
            } else {
              // Only allow image picking if user is permitted (non-dealer)
              final bool isDealer =
                  Provider.of<UserProvider>(context, listen: false)
                          .getUserRole ==
                      'dealer';
              if (!isDealer) {
                _pickImageOrFile(
                  title: title,
                  pickImageOnly: true,
                  callback: (file, fileName) {
                    if (file != null) onImagePicked(file);
                  },
                );
              }
            }
          },
          onLongPress: () {
            final bool isDealer =
                Provider.of<UserProvider>(context, listen: false).getUserRole ==
                    'dealer';
            if (!isDealer) {
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
            }
          },
          child: _buildStyledContainer(
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.memory(image,
                        fit: BoxFit.cover, height: 150, width: double.infinity),
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
                      ),
          ),
        ),
      ],
    );
  }

// Opens the NATIS/RC1 document in an external browser.
  Future<void> _viewDocument() async {
    // Use the existing document URL if available.
    final String? url = _natisRc1FileName == null ? _existingNatisRc1Url : null;
    if (url != null && url.isNotEmpty) {
      try {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open document')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening document: $e')),
        );
      }
    } else if (_natisRc1File != null) {
      // Optionally handle viewing a locally stored file.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local document viewing not implemented')),
      );
    }
  }

// Displays a dialog for selecting an action on an additional image (e.g. change or remove).
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
}
