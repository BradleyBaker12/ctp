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
import 'package:http/http.dart' as http;
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

  // Add these image fields for Tri-Axle at the class level
  Uint8List? _hookpinImage;
  Uint8List? _roofImage;
  Uint8List? _tailboardImage;
  Uint8List? _spareWheelImage;
  Uint8List? _landingLegsImage;
  Uint8List? _hoseAndElectricCableImage;
  Uint8List? _brakeAxel1Image;
  Uint8List? _brakeAxel2Image;
  Uint8List? _brakeAxel3Image;
  Uint8List? _axel1Image;
  Uint8List? _axel2Image;
  Uint8List? _axel3Image;
  Uint8List? _licenseDiskImage;

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
  String? _hookPinImageAUrl;
  String? _roofImageAUrl;
  String? _tailBoardImageAUrl;
  String? _spareWheelImageAUrl;
  String? _landingLegImageAUrl;
  String? _hoseAndElecticalCableImageAUrl;
  String? _brakesAxle1ImageAUrl;
  String? _brakesAxle2ImageAUrl;
  String? _axle1ImageAUrl;
  String? _axle2ImageAUrl;
  String? _hookPinImageBUrl;
  String? _roofImageBUrl;
  String? _tailBoardImageBUrl;
  String? _spareWheelImageBUrl;
  String? _landingLegImageBUrl;
  String? _hoseAndElecticalCableImageBUrl;
  String? _brakesAxle1ImageBUrl;
  String? _brakesAxle2ImageBUrl;
  String? _axle1ImageBUrl;
  String? _axle2ImageBUrl;

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
  final List<Map<String, dynamic>> _additionalImagesList = [];

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

  // Double Axle form variables
  final TextEditingController _makeDoubleAxleController =
      TextEditingController();
  final TextEditingController _modelDoubleAxleController =
      TextEditingController();
  final TextEditingController _yearDoubleAxleController =
      TextEditingController();
  final TextEditingController _lengthDoubleAxleController =
      TextEditingController();
  final TextEditingController _licenceDiskExpDoubleAxleController =
      TextEditingController();
  final TextEditingController _numbAxelDoubleAxleController =
      TextEditingController();
  String _suspensionDoubleAxle = 'steel';
  String _absDoubleAxle = 'no';

  // Double Axle document variables
  Uint8List? _natisDoubleAxleDocFile;
  String? _natisDoubleAxleDocFileName;
  String? _existingNatisDoubleAxleDocUrl;

  // Double Axle image fields
  Uint8List? _hookingPinDoubleAxleImage;
  Uint8List? _roofDoubleAxleImage;
  Uint8List? _tyresDoubleAxleImage;
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

  // Superlink - Trailer A image fields
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

  // Superlink - Trailer B image fields
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

  // Additional controllers for Superlink
  final TextEditingController _makeTrailerAController = TextEditingController();
  final TextEditingController _modelTrailerAController =
      TextEditingController();
  final TextEditingController _yearTrailerAController = TextEditingController();
  final TextEditingController _licenceDiskExpTrailerAController =
      TextEditingController();
  final TextEditingController _makeTrailerBController = TextEditingController();
  final TextEditingController _modelTrailerBController =
      TextEditingController();
  final TextEditingController _yearTrailerBController = TextEditingController();
  final TextEditingController _licenceDiskExpTrailerBController =
      TextEditingController();

  // Add these controllers with other controllers near the top of the class
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _licenseExpController = TextEditingController();
  final TextEditingController _numbAxelController = TextEditingController();

  // Add "Other" trailer type controllers
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

  // Add "Other" trailer type state variables
  String _suspensionOther = 'steel';
  String _absOther = 'no';
  Uint8List? _natisOtherDocFile;
  String? _natisOtherDocFileName;
  String? _existingNatisOtherDocUrl;

  // Add "Other" trailer type image variables
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

  @override
  void initState() {
    super.initState();
    _selectedTrailerType = widget.vehicle.trailer?.trailerType ??
        widget.vehicle.toMap()['trailerType'] ??
        'Superlink';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final trailerFormProvider =
          Provider.of<TrailerFormProvider>(context, listen: false);
      final vehicleData = widget.vehicle.toMap();

      // Fetch trailer data from the database
      final docSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicle.id)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        trailerFormProvider.populateFromTrailer(data);
        _populateVehicleData();
      } else {
        debugPrint('No data found for vehicle ID: ${widget.vehicle.id}');
      }
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
    _makeTrailerAController.dispose();
    _modelTrailerAController.dispose();
    _yearTrailerAController.dispose();
    _licenceDiskExpTrailerAController.dispose();
    _makeTrailerBController.dispose();
    _modelTrailerBController.dispose();
    _yearTrailerBController.dispose();
    _licenceDiskExpTrailerBController.dispose();
    _modelController.dispose();
    _licenseExpController.dispose();
    _numbAxelController.dispose();
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

  Future<void> _loadImageFromUrl(
      String? url, void Function(Uint8List) onSuccess) async {
    if (url != null && url.isNotEmpty) {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        onSuccess(response.bodyBytes);
      }
    }
  }

  void _populateVehicleData() async {
    final data = widget.vehicle.toMap();
    debugPrint("DEBUG: Raw vehicle data: $data");
    final formData = Provider.of<TrailerFormProvider>(context, listen: false);

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

      // Document URLs
      _existingNatisRc1Url = data['natisDocumentUrl'];
      _existingNatisRc1Name = _getFileNameFromUrl(_existingNatisRc1Url);
      _existingServiceHistoryUrl = data['serviceHistoryUrl'];

      if (_selectedTrailerType == 'Superlink') {
<<<<<<< HEAD
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
        debugPrint(
            "DEBUG: Trailer A additionalImages: ${trailerA['trailerAAdditionalImages']}");
        // Trailer A Image URLs
        _frontImageAUrl = trailerA['frontImageUrl'];
        _sideImageAUrl = trailerA['sideImageUrl'];
        _tyresImageAUrl = trailerA['tyresImageUrl'];
        _chassisImageAUrl = trailerA['chassisImageUrl'];
        _deckImageAUrl = trailerA['deckImageUrl'];
        _makersPlateImageAUrl = trailerA['makersPlateImageUrl'];
        _additionalImagesListTrailerA.clear();
        if (trailerA['trailerAAdditionalImages'] != null &&
            (trailerA['trailerAAdditionalImages'] as List).isNotEmpty) {
          _additionalImagesListTrailerA.addAll(
            List<Map<String, dynamic>>.from(
                trailerA['trailerAAdditionalImages']),
          );
        }
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
        debugPrint(
            "DEBUG: Trailer B additionalImages: ${trailerB['trailerBAdditionalImages']}");
        // Trailer B Image URLs
        _frontImageBUrl = trailerB['frontImageUrl'];
        _sideImageBUrl = trailerB['sideImageUrl'];
        _tyresImageBUrl = trailerB['tyresImageUrl'];
        _chassisImageBUrl = trailerB['chassisImageUrl'];
        _deckImageBUrl = trailerB['deckImageUrl'];
        _makersPlateImageBUrl = trailerB['makersPlateImageUrl'];
        _additionalImagesListTrailerB.clear();
        if (trailerB['trailerBAdditionalImages'] != null &&
            (trailerB['trailerBAdditionalImages'] as List).isNotEmpty) {
          _additionalImagesListTrailerB.addAll(
            List<Map<String, dynamic>>.from(
                trailerB['trailerBAdditionalImages']),
          );
        }
      } else if (_selectedTrailerType == 'Tri-Axle') {
        _lengthTrailerController.text =
            trailerExtra['lengthTrailer']?.toString() ?? '';
        _vinController.text = trailerExtra['vin']?.toString() ?? '';
        _registrationController.text =
            trailerExtra['registration']?.toString() ?? '';
        // Add this line to populate the NATIS document URL
        _existingNatisTriAxleDocUrl =
            trailerExtra['natisDocUrl']?.toString() ?? '';
        debugPrint("DEBUG: Tri-Axle NATIS URL: $_existingNatisTriAxleDocUrl");
        if (trailerExtra.containsKey('additionalImages') &&
            (trailerExtra['additionalImages'] as List).isNotEmpty) {
          _additionalImagesList.clear();
          _additionalImagesList.addAll(
            List<Map<String, dynamic>>.from(trailerExtra['additionalImages']),
          );
        }
=======
        _populateSuperlinkData(trailerExtra);
      } else if (_selectedTrailerType == 'Tri-Axle') {
        _populateTriAxleData(trailerExtra);
      } else if (_selectedTrailerType == 'Double Axle') {
        _populateDoubleAxleData(trailerExtra);
      } else if (_selectedTrailerType == 'Other') {
        // Call the async method with then() since setState is sync
        _populateOtherData(trailerExtra).then((_) {
          // Optional: You can add any follow-up setState if needed
        });
>>>>>>> 3aa75c9 (feat: Enhance form data providers with suspension and ABS fields)
      }

      // Populate damage and feature information regardless of trailer type
      _populateDamagesAndFeatures(data);
    });

    // Set admin data if present
    if (data['userId'] != null) {
      _selectedTransporterId = data['userId'];
      debugPrint("Selected Transporter ID: $_selectedTransporterId");
    }

    if (data['assignedSalesRepId'] != null) {
      _selectedSalesRepId = data['assignedSalesRepId'];
      debugPrint("Selected Sales Rep ID: $_selectedSalesRepId");
    }
  }

  void _populateSuperlinkData(Map<String, dynamic> trailerExtra) {
    final trailerA = Map<String, dynamic>.from(trailerExtra['trailerA'] ?? {});
    final trailerB = Map<String, dynamic>.from(trailerExtra['trailerB'] ?? {});

    final formData = Provider.of<TrailerFormProvider>(context, listen: false);

    // Trailer A Basic Info
    _makeTrailerAController.text = trailerA['make']?.toString() ?? '';
    _modelTrailerAController.text = trailerA['model']?.toString() ?? '';
    _yearTrailerAController.text = trailerA['year']?.toString() ?? '';
    _licenceDiskExpTrailerAController.text =
        trailerA['licenseExp']?.toString() ?? '';
    _lengthTrailerAController.text = trailerA['length']?.toString() ?? '';
    _vinAController.text = trailerA['vin']?.toString() ?? '';
    _registrationAController.text = trailerA['registration']?.toString() ?? '';
    _axlesTrailerAController.text = trailerA['axles']?.toString() ?? '';

    // Trailer A Options
    formData.setSuspensionA(trailerA['suspension']?.toString() ?? 'steel');
    formData.setAbsA(trailerA['abs']?.toString() ?? 'no');

    // Trailer A Images
    _frontImageAUrl = trailerA['frontImageUrl'];
    _sideImageAUrl = trailerA['sideImageUrl'];
    _tyresImageAUrl = trailerA['tyresImageUrl'];
    _chassisImageAUrl = trailerA['chassisImageUrl'];
    _deckImageAUrl = trailerA['deckImageUrl'];
    _makersPlateImageAUrl = trailerA['makersPlateImageUrl'];
    _loadImageFromUrl(trailerA['hookPinImageUrl'],
        (bytes) => setState(() => _hookPinImageA = bytes));
    _loadImageFromUrl(trailerA['roofImageUrl'],
        (bytes) => setState(() => _roofImageA = bytes));
    _loadImageFromUrl(trailerA['tailBoardImageUrl'],
        (bytes) => setState(() => _tailBoardImageA = bytes));
    _loadImageFromUrl(trailerA['spareWheelImageUrl'],
        (bytes) => setState(() => _spareWheelImageA = bytes));
    _loadImageFromUrl(trailerA['landingLegImageUrl'],
        (bytes) => setState(() => _landingLegImageA = bytes));
    _loadImageFromUrl(trailerA['hoseAndElecticalCableImageUrl'],
        (bytes) => setState(() => _hoseAndElecticalCableImageA = bytes));
    _loadImageFromUrl(trailerA['brakesAxle1ImageUrl'],
        (bytes) => setState(() => _brakesAxle1ImageA = bytes));
    _loadImageFromUrl(trailerA['brakesAxle2ImageUrl'],
        (bytes) => setState(() => _brakesAxle2ImageA = bytes));
    _loadImageFromUrl(trailerA['axle1ImageUrl'],
        (bytes) => setState(() => _axle1ImageA = bytes));
    _loadImageFromUrl(trailerA['axle2ImageUrl'],
        (bytes) => setState(() => _axle2ImageA = bytes));

    // Trailer A Additional Images
    _existingNatisTrailerADoc1Url = trailerA['natisDocUrl']?.toString() ?? '';
    _existingNatisTrailerADoc1Name =
        _getFileNameFromUrl(_existingNatisTrailerADoc1Url);

    // Trailer B Basic Info
    _makeTrailerBController.text = trailerB['make']?.toString() ?? '';
    _modelTrailerBController.text = trailerB['model']?.toString() ?? '';
    _yearTrailerBController.text = trailerB['year']?.toString() ?? '';
    _licenceDiskExpTrailerBController.text =
        trailerB['licenseExp']?.toString() ?? '';
    _lengthTrailerBController.text = trailerB['length']?.toString() ?? '';
    _vinBController.text = trailerB['vin']?.toString() ?? '';
    _registrationBController.text = trailerB['registration']?.toString() ?? '';
    _axlesTrailerBController.text = trailerB['axles']?.toString() ?? '';

    // Trailer B Options
    formData.setSuspensionB(trailerB['suspension']?.toString() ?? 'steel');
    formData.setAbsB(trailerB['abs']?.toString() ?? 'no');

    // Trailer B Documents
    _existingNatisTrailerBDoc1Url = trailerB['natisDocUrl']?.toString() ?? '';
    _existingNatisTrailerBDoc1Name =
        _getFileNameFromUrl(_existingNatisTrailerBDoc1Url);

    // Trailer B Images
    _frontImageBUrl = trailerB['frontImageUrl'];
    _sideImageBUrl = trailerB['sideImageUrl'];
    _tyresImageBUrl = trailerB['tyresImageUrl'];
    _chassisImageBUrl = trailerB['chassisImageUrl'];
    _deckImageBUrl = trailerB['deckImageUrl'];
    _makersPlateImageBUrl = trailerB['makersPlateImageUrl'];
    _loadImageFromUrl(trailerB['hookPinImageUrl'],
        (bytes) => setState(() => _hookPinImageB = bytes));
    _loadImageFromUrl(trailerB['roofImageUrl'],
        (bytes) => setState(() => _roofImageB = bytes));
    _loadImageFromUrl(trailerB['tailBoardImageUrl'],
        (bytes) => setState(() => _tailBoardImageB = bytes));
    _loadImageFromUrl(trailerB['spareWheelImageUrl'],
        (bytes) => setState(() => _spareWheelImageB = bytes));
    _loadImageFromUrl(trailerB['landingLegImageUrl'],
        (bytes) => setState(() => _landingLegImageB = bytes));
    _loadImageFromUrl(trailerB['hoseAndElecticalCableImageUrl'],
        (bytes) => setState(() => _hoseAndElecticalCableImageB = bytes));
    _loadImageFromUrl(trailerB['brakesAxle1ImageUrl'],
        (bytes) => setState(() => _brakesAxle1ImageB = bytes));
    _loadImageFromUrl(trailerB['brakesAxle2ImageUrl'],
        (bytes) => setState(() => _brakesAxle2ImageB = bytes));
    _loadImageFromUrl(trailerB['axle1ImageUrl'],
        (bytes) => setState(() => _axle1ImageB = bytes));
    _loadImageFromUrl(trailerB['axle2ImageUrl'],
        (bytes) => setState(() => _axle2ImageB = bytes));
  }

  void _populateTriAxleData(Map<String, dynamic> trailerExtra) {
    final formData = Provider.of<TrailerFormProvider>(context, listen: false);

    // Basic info - check multiple possible field names
    _makeController.text = trailerExtra['make']?.toString() ?? '';
    _modelController.text = trailerExtra['model']?.toString() ?? '';
    _yearController.text = trailerExtra['year']?.toString() ?? '';

    // Length may be stored in different fields
    _lengthTrailerController.text = trailerExtra['lengthTrailer']?.toString() ??
        trailerExtra['length']?.toString() ??
        '';

    // VIN and registration
    _vinController.text = trailerExtra['vin']?.toString() ?? '';
    _registrationController.text =
        trailerExtra['registration']?.toString() ?? '';

    // License expiry date
    _licenseExpController.text = trailerExtra['licenseExp']?.toString() ??
        trailerExtra['licenseDiskExp']?.toString() ??
        '';

    // Number of axles - check all possible field names
    _axlesController.text = trailerExtra['axles']?.toString() ?? '';
    _numbAxelController.text = trailerExtra['numbAxel']?.toString() ??
        trailerExtra['numbAxles']?.toString() ??
        trailerExtra['axles']?.toString() ??
        '';

    // Set suspension and ABS values
    formData.setSuspensionA(trailerExtra['suspension']?.toString() ?? 'steel');
    formData.setAbsA(trailerExtra['abs']?.toString() ?? 'no');

    // Documents
    _existingNatisTriAxleDocUrl = trailerExtra['natisDocUrl']?.toString() ?? '';

    // Base images
    _frontImageUrl = trailerExtra['frontImageUrl'];
    _sideImageUrl = trailerExtra['sideImageUrl'];
    _tyresImageUrl = trailerExtra['tyresImageUrl'];
    _chassisImageUrl = trailerExtra['chassisImageUrl'];
    _deckImageUrl = trailerExtra['deckImageUrl'];
    _makersPlateImageUrl = trailerExtra['makersPlateImageUrl'];

    // Additional images
    _loadAllTriAxleImages(trailerExtra);
  }

  void _loadAllTriAxleImages(Map<String, dynamic> trailerExtra) async {
    // Hook Pin Image
    if (trailerExtra['hookPinImageUrl'] != null &&
        trailerExtra['hookPinImageUrl'].toString().isNotEmpty) {
      try {
        final response =
            await http.get(Uri.parse(trailerExtra['hookPinImageUrl']));
        if (response.statusCode == 200) {
          setState(() => _hookpinImage = response.bodyBytes);
        }
      } catch (e) {
        debugPrint("Error loading hookpin image: $e");
      }
    }

    // Load other Tri-Axle images similarly
    _loadTriAxleImage(trailerExtra['roofImageUrl'],
        (bytes) => setState(() => _roofImage = bytes));
    _loadTriAxleImage(trailerExtra['tailboardImageUrl'],
        (bytes) => setState(() => _tailboardImage = bytes));
    _loadTriAxleImage(trailerExtra['spareWheelImageUrl'],
        (bytes) => setState(() => _spareWheelImage = bytes));
    _loadTriAxleImage(trailerExtra['landingLegsImageUrl'],
        (bytes) => setState(() => _landingLegsImage = bytes));
    _loadTriAxleImage(trailerExtra['hoseAndElectricCableImageUrl'],
        (bytes) => setState(() => _hoseAndElectricCableImage = bytes));
    _loadTriAxleImage(trailerExtra['brakeAxel1ImageUrl'],
        (bytes) => setState(() => _brakeAxel1Image = bytes));
    _loadTriAxleImage(trailerExtra['brakeAxel2ImageUrl'],
        (bytes) => setState(() => _brakeAxel2Image = bytes));
    _loadTriAxleImage(trailerExtra['brakeAxel3ImageUrl'],
        (bytes) => setState(() => _brakeAxel3Image = bytes));
    _loadTriAxleImage(trailerExtra['axel1ImageUrl'],
        (bytes) => setState(() => _axel1Image = bytes));
    _loadTriAxleImage(trailerExtra['axel2ImageUrl'],
        (bytes) => setState(() => _axel2Image = bytes));
    _loadTriAxleImage(trailerExtra['axel3ImageUrl'],
        (bytes) => setState(() => _axel3Image = bytes));
    _loadTriAxleImage(trailerExtra['licenseDiskImageUrl'],
        (bytes) => setState(() => _licenseDiskImage = bytes));
  }

  void _loadTriAxleImage(String? url, Function(Uint8List) onSuccess) async {
    if (url != null && url.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          onSuccess(response.bodyBytes);
        }
      } catch (e) {
        debugPrint("Error loading image $url: $e");
      }
    }
  }

  void _populateDoubleAxleData(Map<String, dynamic> trailerExtra) {
    // Basic info fields
    _makeDoubleAxleController.text = trailerExtra['make']?.toString() ?? '';
    _modelDoubleAxleController.text = trailerExtra['model']?.toString() ?? '';
    _yearDoubleAxleController.text = trailerExtra['year']?.toString() ?? '';
    _lengthDoubleAxleController.text = trailerExtra['length']?.toString() ?? '';
    _vinController.text = trailerExtra['vin']?.toString() ?? '';
    _registrationController.text =
        trailerExtra['registration']?.toString() ?? '';
    _licenceDiskExpDoubleAxleController.text =
        trailerExtra['licenseExp']?.toString() ?? '';
    _numbAxelDoubleAxleController.text = trailerExtra['numbAxel']?.toString() ??
        trailerExtra['axles']?.toString() ??
        '';

    // Set suspension and ABS values
    _suspensionDoubleAxle = trailerExtra['suspension']?.toString() ?? 'steel';
    _absDoubleAxle = trailerExtra['abs']?.toString() ?? 'no';

    // Document
    _existingNatisDoubleAxleDocUrl =
        trailerExtra['natisDocUrl']?.toString() ?? '';

    // Add this line to extract the filename from the URL
    _natisDoubleAxleDocFileName =
        _getFileNameFromUrl(_existingNatisDoubleAxleDocUrl);

    // Load images
    _loadDoubleAxleImages(trailerExtra);
  }

  void _loadDoubleAxleImages(Map<String, dynamic> trailerExtra) async {
    // Front image
    if (trailerExtra['frontImageUrl'] != null &&
        trailerExtra['frontImageUrl'].toString().isNotEmpty) {
      _loadImageFromUrl(trailerExtra['frontImageUrl'],
          (bytes) => setState(() => _frontImage = bytes));
    }

    // Side image
    if (trailerExtra['sideImageUrl'] != null &&
        trailerExtra['sideImageUrl'].toString().isNotEmpty) {
      _loadImageFromUrl(trailerExtra['sideImageUrl'],
          (bytes) => setState(() => _sideImage = bytes));
    }

    // Chassis image
    if (trailerExtra['chassisImageUrl'] != null &&
        trailerExtra['chassisImageUrl'].toString().isNotEmpty) {
      _loadImageFromUrl(trailerExtra['chassisImageUrl'],
          (bytes) => setState(() => _chassisImage = bytes));
    }

    // Additional images
    _loadImageFromUrl(trailerExtra['hookingPinImageUrl'],
        (bytes) => setState(() => _hookingPinDoubleAxleImage = bytes));

    _loadImageFromUrl(trailerExtra['deckImageUrl'],
        (bytes) => setState(() => _deckImage = bytes));

    _loadImageFromUrl(trailerExtra['roofImageUrl'],
        (bytes) => setState(() => _roofDoubleAxleImage = bytes));

    _loadImageFromUrl(trailerExtra['tyresImageUrl'],
        (bytes) => setState(() => _tyresDoubleAxleImage = bytes));

    _loadImageFromUrl(trailerExtra['tailBoardImageUrl'],
        (bytes) => setState(() => _tailBoardDoubleAxleImage = bytes));

    _loadImageFromUrl(trailerExtra['spareWheelImageUrl'],
        (bytes) => setState(() => _spareWheelDoubleAxleImage = bytes));

    _loadImageFromUrl(trailerExtra['landingLegsImageUrl'],
        (bytes) => setState(() => _landingLegsDoubleAxleImage = bytes));

    _loadImageFromUrl(trailerExtra['hoseAndElecCableImageUrl'],
        (bytes) => setState(() => _hoseAndElecCableDoubleAxleImage = bytes));

    _loadImageFromUrl(trailerExtra['brakesAxle1ImageUrl'],
        (bytes) => setState(() => _brakesAxle1DoubleAxleImage = bytes));

    _loadImageFromUrl(trailerExtra['brakesAxle2ImageUrl'],
        (bytes) => setState(() => _brakesAxle2DoubleAxleImage = bytes));

    _loadImageFromUrl(trailerExtra['axle1ImageUrl'],
        (bytes) => setState(() => _axle1DoubleAxleImage = bytes));

    _loadImageFromUrl(trailerExtra['axle2ImageUrl'],
        (bytes) => setState(() => _axle2DoubleAxleImage = bytes));

    _loadImageFromUrl(trailerExtra['licenseDiskImageUrl'],
        (bytes) => setState(() => _licenseDiskDoubleAxleImage = bytes));

    _loadImageFromUrl(trailerExtra['makersPlateImageUrl'],
        (bytes) => setState(() => _makersPlateDblAxleImage = bytes));
  }

  Future<void> _populateOtherData(Map<String, dynamic> trailerExtra) async {
    // Basic info fields
    _makeOtherController.text = trailerExtra['make']?.toString() ?? '';
    _modelOtherController.text = trailerExtra['model']?.toString() ?? '';
    _yearOtherController.text = trailerExtra['year']?.toString() ?? '';
    _lengthOtherController.text = trailerExtra['length']?.toString() ?? '';
    _vinOtherController.text = trailerExtra['vin']?.toString() ?? '';
    _registrationOtherController.text =
        trailerExtra['registration']?.toString() ?? '';
    _licenceDiskExpOtherController.text =
        trailerExtra['licenseExp']?.toString() ?? '';
    _numbAxelOtherController.text = trailerExtra['numbAxel']?.toString() ??
        trailerExtra['axles']?.toString() ??
        '';

    // Set suspension and ABS values
    _suspensionOther = trailerExtra['suspension']?.toString() ?? 'steel';
    _absOther = trailerExtra['abs']?.toString() ?? 'no';

    // Document
    _existingNatisOtherDocUrl = trailerExtra['natisDocUrl']?.toString() ?? '';
    _natisOtherDocFileName = _getFileNameFromUrl(_existingNatisOtherDocUrl);

    // Load file and images within setState to update UI
    setState(() {
      // Load images and files using Future
      _loadImageFromUrl(trailerExtra['natisDocUrl'], (bytes) {
        setState(() => _natisOtherDocFile = bytes);
            });

      // Load all "Other" trailer type images
      _loadAndSetImage(trailerExtra['frontImageUrl'],
          (bytes) => setState(() => _frontOtherImage = bytes));
      _loadAndSetImage(trailerExtra['sideImageUrl'],
          (bytes) => setState(() => _sideOtherImage = bytes));
      _loadAndSetImage(trailerExtra['chassisImageUrl'],
          (bytes) => setState(() => _chassisOtherImage = bytes));
      _loadAndSetImage(trailerExtra['hookingPinImageUrl'],
          (bytes) => setState(() => _hookingPinOtherImage = bytes));
      _loadAndSetImage(trailerExtra['deckImageUrl'],
          (bytes) => setState(() => _deckOtherImage = bytes));
      _loadAndSetImage(trailerExtra['roofImageUrl'],
          (bytes) => setState(() => _roofOtherImage = bytes));
      _loadAndSetImage(trailerExtra['tyresImageUrl'],
          (bytes) => setState(() => _tyresOtherImage = bytes));
      _loadAndSetImage(trailerExtra['tailBoardImageUrl'],
          (bytes) => setState(() => _tailBoardOtherImage = bytes));
      _loadAndSetImage(trailerExtra['spareWheelImageUrl'],
          (bytes) => setState(() => _spareWheelOtherImage = bytes));
      _loadAndSetImage(trailerExtra['landingLegsImageUrl'],
          (bytes) => setState(() => _landingLegsOtherImage = bytes));
      _loadAndSetImage(trailerExtra['hoseAndElecCableImageUrl'],
          (bytes) => setState(() => _hoseAndElecCableOtherImage = bytes));
      _loadAndSetImage(trailerExtra['licenseDiskImageUrl'],
          (bytes) => setState(() => _licenseDiskOtherImage = bytes));
      _loadAndSetImage(trailerExtra['makersPlateImageUrl'],
          (bytes) => setState(() => _makersPlateOtherImage = bytes));
    });
  }

  // Helper method to load image bytes from URL
  Future<Uint8List?> _loadImageBytesFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('Error loading image from URL: $e');
    }
    return null;
  }

  // Helper method to load and set images
  void _loadAndSetImage(String? url, Function(Uint8List) onSuccess) {
    if (url != null && url.isNotEmpty) {
      // Use the version that returns a Future<Uint8List?>
      _loadImageBytesFromUrl(url).then((bytes) {
        if (bytes != null) {
          onSuccess(bytes);
        }
      });
    }
  }

  void _populateDamagesAndFeatures(Map<String, dynamic> data) {
    // Populate damages
    _damageList.clear();
    if (data['damages'] != null && data['damages'] is List) {
      _damageList.addAll(
          List<Map<String, dynamic>>.from(data['damages']).map((damage) {
        final controller =
            TextEditingController(text: damage['description'] ?? '');
        return {
          'description': damage['description'] ?? '',
          'imageUrl': damage['imageUrl'] ?? '',
          'image': null,
          'controller': controller,
        };
      }).toList());
    }
    // Explicitly set condition based on list content AND the damagesCondition field
    _damagesCondition =
        data['damagesCondition'] == 'yes' || _damageList.isNotEmpty
            ? 'yes'
            : 'no';
    debugPrint(
        "DEBUG: Damages populated: ${_damageList.length} items, condition: $_damagesCondition");

    // Populate features
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
    // Explicitly set condition based on list content AND the featuresCondition field
    _featuresCondition =
        data['featuresCondition'] == 'yes' || _featureList.isNotEmpty
            ? 'yes'
            : 'no';
    debugPrint(
        "DEBUG: Features populated: ${_featureList.length} items, condition: $_featuresCondition");
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
    _pickImageOrFile(
      title: 'Select NATIS Document for Trailer A',
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
    _pickImageOrFile(
      title: 'Select NATIS Document for Trailer B',
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
    final formData = Provider.of<TrailerFormProvider>(context);
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Fixed bracket syntax
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
<<<<<<< HEAD
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
          _buildNatisTrailerBDocSection(),
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
          _buildAdditionalImagesSectionForTrailerB(),
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
              if (_existingNatisTriAxleDocUrl != null ||
                  _natisTriAxleDocFile != null) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('NATIS Document Options'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_existingNatisTriAxleDocUrl != null)
                          ListTile(
                            leading: const Icon(Icons.remove_red_eye),
                            title: const Text('View Document'),
                            onTap: () async {
                              Navigator.pop(context);
                              if (_existingNatisTriAxleDocUrl != null) {
                                final Uri uri =
                                    Uri.parse(_existingNatisTriAxleDocUrl!);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              }
                            },
                          ),
                        ListTile(
                          leading: const Icon(Icons.upload_file),
                          title: const Text('Replace Document'),
                          onTap: () {
                            Navigator.pop(context);
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
                        ),
                      ],
                    ),
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
=======
          CustomDropdown(
            hintText: 'Select Trailer Type',
            value: _selectedTrailerType,
            items: const ['Superlink', 'Tri-Axle', 'Double Axle', 'Other'],
            onChanged: (value) {
              if (!isDealer) {
                setState(() {
                  _selectedTrailerType = value;
                });
>>>>>>> 3aa75c9 (feat: Enhance form data providers with suspension and ABS fields)
              }
            },
            enabled: !isDealer,
          ),
          const SizedBox(height: 15),
          if (_selectedTrailerType == 'Double Axle') ...[
            const SizedBox(height: 15),
            CustomTextField(
              controller: _makeDoubleAxleController,
              hintText: 'Make of Trailer',
              enabled: !isDealer,
            ),
            const SizedBox(height: 15),
            CustomTextField(
              controller: _modelDoubleAxleController,
              hintText: 'Model of Trailer',
              enabled: !isDealer,
            ),
            const SizedBox(height: 15),
            CustomTextField(
              controller: _yearDoubleAxleController,
              hintText: 'Year of Trailer',
              keyboardType: TextInputType.number,
              enabled: !isDealer,
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
            CustomTextField(
              controller: _licenceDiskExpDoubleAxleController,
              hintText: 'Licence Disk Expiry Date',
              inputFormatter: [UpperCaseTextFormatter()],
              enabled: !isDealer,
            ),
            const SizedBox(height: 15),
            CustomTextField(
              controller: _numbAxelDoubleAxleController,
              hintText: 'Number of Axles',
              keyboardType: TextInputType.number,
              enabled: !isDealer,
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
            const SizedBox(height: 15),
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
                if (_existingNatisDoubleAxleDocUrl != null ||
                    _natisDoubleAxleDocFile != null) {
                  _showDoubleAxleDocumentOptions();
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
                child: _natisDoubleAxleDocFile != null
                    ? _buildFileDisplay(_natisDoubleAxleDocFileName, false)
                    : (_existingNatisDoubleAxleDocUrl != null &&
                            _existingNatisDoubleAxleDocUrl!.isNotEmpty)
                        ? _buildFileDisplay(
                            _getFileNameFromUrl(_existingNatisDoubleAxleDocUrl),
                            true)
                        : const Column(
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
                (img) => setState(() => _hookingPinDoubleAxleImage = img)),
            const SizedBox(height: 15),
            _buildImageSectionWithTitle('Deck Image', _deckImage,
                (img) => setState(() => _deckImage = img)),
            const SizedBox(height: 15),
            _buildImageSectionWithTitle(
                'Roof Image (if applicable)',
                _roofDoubleAxleImage,
                (img) => setState(() => _roofDoubleAxleImage = img)),
            const SizedBox(height: 15),
            _buildImageSectionWithTitle('Tyres Image', _tyresDoubleAxleImage,
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
                (img) => setState(() => _spareWheelDoubleAxleImage = img)),
            const SizedBox(height: 15),
            _buildImageSectionWithTitle(
                'Landing Legs Image',
                _landingLegsDoubleAxleImage,
                (img) => setState(() => _landingLegsDoubleAxleImage = img)),
            const SizedBox(height: 15),
            _buildImageSectionWithTitle(
                'Hose and Electrical Cable Image',
                _hoseAndElecCableDoubleAxleImage,
                (img) =>
                    setState(() => _hoseAndElecCableDoubleAxleImage = img)),
            const SizedBox(height: 15),
            _buildImageSectionWithTitle(
                'Brakes Axle 1 Image',
                _brakesAxle1DoubleAxleImage,
                (img) => setState(() => _brakesAxle1DoubleAxleImage = img)),
            const SizedBox(height: 15),
            _buildImageSectionWithTitle(
                'Brakes Axle 2 Image',
                _brakesAxle2DoubleAxleImage,
                (img) => setState(() => _brakesAxle2DoubleAxleImage = img)),
            const SizedBox(height: 15),
            _buildImageSectionWithTitle('Axle 1 Image', _axle1DoubleAxleImage,
                (img) => setState(() => _axle1DoubleAxleImage = img)),
            const SizedBox(height: 15),
            _buildImageSectionWithTitle('Axle 2 Image', _axle2DoubleAxleImage,
                (img) => setState(() => _axle2DoubleAxleImage = img)),
            const SizedBox(height: 15),
            _buildImageSectionWithTitle(
                'Licence Disk Image',
                _licenseDiskDoubleAxleImage,
                (img) => setState(() => _licenseDiskDoubleAxleImage = img)),
            const SizedBox(height: 15),
            _buildImageSectionWithTitle(
                'Makers Plate Image',
                _makersPlateDblAxleImage,
                (img) => setState(() => _makersPlateDblAxleImage = img)),
            const SizedBox(height: 15),
          ],
          if (_selectedTrailerType == 'Other') ...[
            const SizedBox(height: 15),
            CustomTextField(
              controller: _makeOtherController,
              hintText: 'Make of Trailer',
              enabled: !isDealer,
            ),
            const SizedBox(height: 15),
            CustomTextField(
              controller: _modelOtherController,
              hintText: 'Model of Trailer',
              enabled: !isDealer,
            ),
            const SizedBox(height: 15),
            CustomTextField(
              controller: _yearOtherController,
              hintText: 'Year of Trailer',
              keyboardType: TextInputType.number,
              enabled: !isDealer,
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
              enabled: !isDealer,
            ),
            const SizedBox(height: 15),
            CustomTextField(
              controller: _vinOtherController,
              hintText: 'VIN',
              inputFormatter: [UpperCaseTextFormatter()],
              enabled: !isDealer,
            ),
            const SizedBox(height: 15),
            CustomTextField(
              controller: _registrationOtherController,
              hintText: 'Registration',
              inputFormatter: [UpperCaseTextFormatter()],
              enabled: !isDealer,
            ),
            const SizedBox(height: 15),
            CustomTextField(
              controller: _licenceDiskExpOtherController,
              hintText: 'Licence Disk Expiry Date',
              inputFormatter: [UpperCaseTextFormatter()],
              enabled: !isDealer,
            ),
            const SizedBox(height: 15),
            CustomTextField(
              controller: _numbAxelOtherController,
              hintText: 'Number of Axles',
              keyboardType: TextInputType.number,
              enabled: !isDealer,
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
                  enabled: !isDealer,
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
                  enabled: !isDealer,
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
                if (_existingNatisOtherDocUrl != null &&
                        _existingNatisOtherDocUrl!.isNotEmpty ||
                    _natisOtherDocFile != null) {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('NATIS Document Options'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_existingNatisOtherDocUrl != null &&
                              _existingNatisOtherDocUrl!.isNotEmpty)
                            ListTile(
                              leading: const Icon(Icons.remove_red_eye),
                              title: const Text('View Document'),
                              onTap: () {
                                Navigator.pop(context);
                                _viewOtherDocument();
                              },
                            ),
                          ListTile(
                            leading: const Icon(Icons.upload_file),
                            title: const Text('Change File'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImageOrFile(
                                title: 'Select NATIS Document',
                                pickImageOnly: false,
                                callback: (file, fileName) {
                                  if (file != null) {
                                    setState(() {
                                      _natisOtherDocFile = file;
                                      _natisOtherDocFileName = fileName;
                                    });
                                  }
                                },
                              );
                            },
                          ),
                          if (_existingNatisOtherDocUrl != null &&
                                  _existingNatisOtherDocUrl!.isNotEmpty ||
                              _natisOtherDocFile != null)
                            ListTile(
                              leading:
                                  const Icon(Icons.delete, color: Colors.red),
                              title: const Text('Remove File',
                                  style: TextStyle(color: Colors.red)),
                              onTap: () {
                                Navigator.pop(context);
                                setState(() {
                                  _natisOtherDocFile = null;
                                  _natisOtherDocFileName = null;
                                  _existingNatisOtherDocUrl = null;
                                });
                              },
                            ),
                          ListTile(
                            leading: const Icon(Icons.cancel),
                            title: const Text('Cancel'),
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  _pickImageOrFile(
                    title: 'Select NATIS Document',
                    pickImageOnly: false,
                    callback: (file, fileName) {
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
                            style:
                                TextStyle(fontSize: 14, color: Colors.white70),
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
                            _natisOtherDocFileName!.split('/').last,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
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
          ],
          if (_selectedTrailerType != null) ...[
            // NEW: For Superlink add Number of Axles
            if (_selectedTrailerType == 'Tri-Axle') ...[
              CustomTextField(
                controller: _makeController,
                hintText: 'Make of Trailer',
                enabled: !isDealer,
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _modelController,
                hintText: 'Model of Trailer',
                enabled: !isDealer,
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _yearController,
                hintText: 'Year of Trailer',
                keyboardType: TextInputType.number,
                enabled: !isDealer,
              ),
              const SizedBox(height: 15),
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
              CustomTextField(
                controller: _licenseExpController,
                hintText: 'Licence disk expiry date',
                inputFormatter: [UpperCaseTextFormatter()],
                enabled: !isDealer,
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _numbAxelController,
                hintText: 'Number of Axles',
                keyboardType: TextInputType.number,
                enabled: !isDealer,
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
              const SizedBox(height: 15),
              const Text(
                'NATIS Document for Tri-Axle',
                style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () {
                  if (_existingNatisTriAxleDocUrl != null ||
                      _natisTriAxleDocFile != null) {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('NATIS Document Options'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_existingNatisTriAxleDocUrl != null)
                              ListTile(
                                leading: const Icon(Icons.remove_red_eye),
                                title: const Text('View Document'),
                                onTap: () async {
                                  Navigator.pop(context);
                                  if (_existingNatisTriAxleDocUrl != null) {
                                    final Uri uri =
                                        Uri.parse(_existingNatisTriAxleDocUrl!);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    }
                                  }
                                },
                              ),
                            ListTile(
                              leading: const Icon(Icons.upload_file),
                              title: const Text('Replace Document'),
                              onTap: () {
                                Navigator.pop(context);
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
                            ),
                          ],
                        ),
<<<<<<< HEAD
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
          _buildAdditionalImagesSection(),
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
              enabled: !isDealer,
              onChanged: isDealer
                  ? (_) {} // Empty function instead of null
                  : (val) {
                      setState(() {
                        _damagesCondition = val ?? 'no';
                        if (_damagesCondition == 'yes' && _damageList.isEmpty) {
                          _damageList.add({'description': '', 'image': null});
                        } else if (_damagesCondition == 'no') {
                          _damageList.clear();
=======
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
>>>>>>> 3aa75c9 (feat: Enhance form data providers with suspension and ABS fields)
                        }
                      },
                    );
                  }
                },
                child: _buildStyledContainer(
                  child: _natisTriAxleDocFile != null
                      ? _buildFileDisplay(_natisTriAxleDocFileName, false)
                      : (_existingNatisTriAxleDocUrl != null)
                          ? _buildFileDisplay(
                              _getFileNameFromUrl(_existingNatisTriAxleDocUrl),
                              true)
                          : const Column(
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
                            ),
                ),
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Front Image',
                _frontImage,
                (img) => setState(() => _frontImage = img),
                existingUrl: _frontImageUrl,
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Side Image',
                _sideImage,
                (img) => setState(() => _sideImage = img),
                existingUrl: _sideImageUrl,
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Tyres Image',
                _tyresImage,
                (img) => setState(() => _tyresImage = img),
                existingUrl: _tyresImageUrl,
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Chassis Image',
                _chassisImage,
                (img) => setState(() => _chassisImage = img),
                existingUrl: _chassisImageUrl,
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Deck Image',
                _deckImage,
                (img) => setState(() => _deckImage = img),
                existingUrl: _deckImageUrl,
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Makers Plate Image',
                _makersPlateImage,
                (img) => setState(() => _makersPlateImage = img),
                existingUrl: _makersPlateImageUrl,
              ),
              // Add these additional image fields for Tri-Axle
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Hook Pin Image',
                _hookpinImage,
                (img) => setState(() => _hookpinImage = img),
                existingUrl: widget.vehicle.trailer
                        ?.rawTrailerExtraInfo?['hookPinImageUrl'] ??
                    '',
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Roof Image',
                _roofImage,
                (img) => setState(() => _roofImage = img),
                existingUrl: widget.vehicle.trailer
                        ?.rawTrailerExtraInfo?['roofImageUrl'] ??
                    '',
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Tailboard Image',
                _tailboardImage,
                (img) => setState(() => _tailboardImage = img),
                existingUrl: widget.vehicle.trailer
                        ?.rawTrailerExtraInfo?['tailboardImageUrl'] ??
                    '',
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Spare Wheel Image',
                _spareWheelImage,
                (img) => setState(() => _spareWheelImage = img),
                existingUrl: widget.vehicle.trailer
                        ?.rawTrailerExtraInfo?['spareWheelImageUrl'] ??
                    '',
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Landing Legs Image',
                _landingLegsImage,
                (img) => setState(() => _landingLegsImage = img),
                existingUrl: widget.vehicle.trailer
                        ?.rawTrailerExtraInfo?['landingLegsImageUrl'] ??
                    '',
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Hose and Electric Cable Image',
                _hoseAndElectricCableImage,
                (img) => setState(() => _hoseAndElectricCableImage = img),
                existingUrl: widget.vehicle.trailer?.rawTrailerExtraInfo?[
                        'hoseAndElectricCableImageUrl'] ??
                    '',
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Brake Axle 1 Image',
                _brakeAxel1Image,
                (img) => setState(() => _brakeAxel1Image = img),
                existingUrl: widget.vehicle.trailer
                        ?.rawTrailerExtraInfo?['brakeAxel1ImageUrl'] ??
                    '',
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Brake Axle 2 Image',
                _brakeAxel2Image,
                (img) => setState(() => _brakeAxel2Image = img),
                existingUrl: widget.vehicle.trailer
                        ?.rawTrailerExtraInfo?['brakeAxel2ImageUrl'] ??
                    '',
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Brake Axle 3 Image',
                _brakeAxel3Image,
                (img) => setState(() => _brakeAxel3Image = img),
                existingUrl: widget.vehicle.trailer
                        ?.rawTrailerExtraInfo?['brakeAxel3ImageUrl'] ??
                    '',
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Axle 1 Image',
                _axel1Image,
                (img) => setState(() => _axel1Image = img),
                existingUrl: widget.vehicle.trailer
                        ?.rawTrailerExtraInfo?['axel1ImageUrl'] ??
                    '',
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Axle 2 Image',
                _axel2Image,
                (img) => setState(() => _axel2Image = img),
                existingUrl: widget.vehicle.trailer
                        ?.rawTrailerExtraInfo?['axel2ImageUrl'] ??
                    '',
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Axle 3 Image',
                _axel3Image,
                (img) => setState(() => _axel3Image = img),
                existingUrl: widget.vehicle.trailer
                        ?.rawTrailerExtraInfo?['axel3ImageUrl'] ??
                    '',
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'License Disk Image',
                _licenseDiskImage,
                (img) => setState(() => _licenseDiskImage = img),
                existingUrl: widget.vehicle.trailer
                        ?.rawTrailerExtraInfo?['licenseDiskImageUrl'] ??
                    '',
              ),
            ],
            // Trailer type specific sections
            if (_selectedTrailerType == 'Superlink') ...[
              const Text("Trailer A Details",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              CustomTextField(
                controller: _makeTrailerAController,
                hintText: 'Make Trailer A',
                enabled: !isDealer,
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _modelTrailerAController,
                hintText: 'Model Trailer A',
                enabled: !isDealer,
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _yearTrailerAController,
                hintText: 'Year Trailer A',
                keyboardType: TextInputType.number,
                enabled: !isDealer,
              ),
              const SizedBox(height: 15),
              Center(
                  child: Text('Suspension Trailer A',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
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
              // New fields for Trailer A
              const SizedBox(height: 15),
              CustomTextField(
                controller: _axlesTrailerAController,
                hintText: 'Number of Axles Trailer A',
                keyboardType: TextInputType.number,
                enabled: !isDealer,
              ),
              const SizedBox(height: 15),
              CustomTextField(
                  controller: _licenceDiskExpTrailerAController,
                  hintText: 'Licence Disk Expriry Date Trailer A',
                  inputFormatter: [UpperCaseTextFormatter()],
                  enabled: !isDealer),
              const SizedBox(height: 15),
              Center(
                  child: Text('ABS Trailer A',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
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
                      final formData = Provider.of<TrailerFormProvider>(context,
                          listen: false);
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
              _buildNatisTrailerADocSection(),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Trailer A - Front Image',
                _frontImageA,
                (img) => setState(() => _frontImageA = img),
                existingUrl: _frontImageAUrl,
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Trailer A - Side Image',
                _sideImageA,
                (img) => setState(() => _sideImageA = img),
                existingUrl: _sideImageAUrl,
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Trailer A - Tyres Image',
                _tyresImageA,
                (img) => setState(() => _tyresImageA = img),
                existingUrl: _tyresImageAUrl,
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Trailer A - Chassis Image',
                _chassisImageA,
                (img) => setState(() => _chassisImageA = img),
                existingUrl: _chassisImageAUrl,
              ),
              _buildImageSectionWithTitle(
                'Trailer A - Deck Image',
                _deckImageA,
                (img) => setState(() => _deckImageA = img),
                existingUrl: _deckImageAUrl,
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Trailer A - Makers Plate Image',
                _makersPlateImageA,
                (img) => setState(() => _makersPlateImageA = img),
                existingUrl: _makersPlateImageAUrl,
              ),
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
                  (img) => setState(() => _hoseAndElecticalCableImageA = img)),
              _buildImageSectionWithTitle(
                  'Trailer A - Brakes Axle 1 Image',
                  _brakesAxle1ImageA,
                  (img) => setState(() => _brakesAxle1ImageA = img)),
              _buildImageSectionWithTitle(
                  'Trailer A - Brakes Axle 2 Image',
                  _brakesAxle2ImageA,
                  (img) => setState(() => _brakesAxle2ImageA = img)),
              _buildImageSectionWithTitle('Trailer A - Axle 1 Image',
                  _axle1ImageA, (img) => setState(() => _axle1ImageA = img)),
              _buildImageSectionWithTitle('Trailer A - Axle 2 Image',
                  _axle2ImageA, (img) => setState(() => _axle2ImageA = img)),
              const SizedBox(height: 15),
              const Text("Trailer B Details",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              CustomTextField(
                controller: _makeTrailerBController,
                hintText: 'Make Trailer B',
                enabled: !isDealer,
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _modelTrailerBController,
                hintText: 'Model Trailer B',
                enabled: !isDealer,
              ),
              const SizedBox(height: 15),
              CustomTextField(
                controller: _yearTrailerBController,
                hintText: 'Year Trailer B',
                keyboardType: TextInputType.number,
                enabled: !isDealer,
              ),
              const SizedBox(height: 15),
              Center(
                  child: Text('Suspension Trailer B',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
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
              // New fields for Trailer B
              const SizedBox(height: 15),
              CustomTextField(
                controller: _axlesTrailerBController,
                hintText: 'Number of Axles Trailer B',
                keyboardType: TextInputType.number,
                enabled: !isDealer,
              ),
              const SizedBox(height: 15),
              CustomTextField(
                  controller: _licenceDiskExpTrailerBController,
                  hintText: 'Licence Disk Expriry Date Trailer B',
                  inputFormatter: [UpperCaseTextFormatter()],
                  enabled: !isDealer),
              const SizedBox(height: 15),
              Center(
                  child: Text('ABS Trailer B',
                      style: const TextStyle(fontSize: 14, color: Colors.white),
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
                      final formData = Provider.of<TrailerFormProvider>(context,
                          listen: false);
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
                'NATIS Document for Trailer B',
                style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildNatisTrailerBDocSection(),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Trailer B - Front Image',
                _frontImageB,
                (img) => setState(() => _frontImageB = img),
                existingUrl: _frontImageBUrl,
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Trailer B - Side Image',
                _sideImageB,
                (img) => setState(() => _sideImageB = img),
                existingUrl: _sideImageBUrl,
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Trailer B - Tyres Image',
                _tyresImageB,
                (img) => setState(() => _tyresImageB = img),
                existingUrl: _tyresImageBUrl,
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Trailer B - Chassis Image',
                _chassisImageB,
                (img) => setState(() => _chassisImageB = img),
                existingUrl: _chassisImageBUrl,
              ),
              _buildImageSectionWithTitle(
                'Trailer B - Deck Image',
                _deckImageB,
                (img) => setState(() => _deckImageB = img),
                existingUrl: _deckImageBUrl,
              ),
              const SizedBox(height: 15),
              _buildImageSectionWithTitle(
                'Trailer B - Makers Plate Image',
                _makersPlateImageB,
                (img) => setState(() => _makersPlateImageB = img),
                existingUrl: _makersPlateImageBUrl,
              ),
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
                  (img) => setState(() => _hoseAndElecticalCableImageB = img)),
              _buildImageSectionWithTitle(
                  'Trailer B - Brakes Axle 1 Image',
                  _brakesAxle1ImageB,
                  (img) => setState(() => _brakesAxle1ImageB = img)),
              _buildImageSectionWithTitle(
                  'Trailer B - Brakes Axle 2 Image',
                  _brakesAxle2ImageB,
                  (img) => setState(() => _brakesAxle2ImageB = img)),
              _buildImageSectionWithTitle('Trailer B - Axle 1 Image',
                  _axle1ImageB, (img) => setState(() => _axle1ImageB = img)),
              _buildImageSectionWithTitle('Trailer B - Axle 2 Image',
                  _axle2ImageB, (img) => setState(() => _axle2ImageB = img)),
              const SizedBox(height: 15),
              const Text('Are there additional images for Trailer B?',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
            ],
            // Tri-Axle branch.
            //
            // Service History Section
            _buildServiceHistorySection(),
            const SizedBox(height: 20),
            // Damages Section
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
                  enabled: !isDealer,
                  onChanged: isDealer
                      ? (_) {} // Empty function instead of null
                      : (val) {
                          setState(() {
                            _damagesCondition = val ?? 'no';
                            if (_damagesCondition == 'yes' &&
                                _damageList.isEmpty) {
                              _damageList.add({
                                'description': '',
                                'image': null,
                                'controller': TextEditingController(),
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
                  enabled: !isDealer,
                  onChanged: isDealer
                      ? (_) {} // Empty function instead of null
                      : (val) {
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
            if (_damagesCondition == 'yes' ||
                (_damageList.isNotEmpty && isDealer))
              _buildDamageSection(),
            const SizedBox(height: 20),
            // Additional Features Section
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
                  enabled: !isDealer,
                  onChanged: isDealer
                      ? (_) {} // Empty function instead of null
                      : (val) {
                          setState(() {
                            _featuresCondition = val ?? 'no';
                            if (_featuresCondition == 'yes' &&
                                _featureList.isEmpty) {
                              _featureList.add({
                                'description': '',
                                'image': null,
                                'controller': TextEditingController(),
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
                  enabled: !isDealer,
                  onChanged: isDealer
                      ? (_) {} // Empty function instead of null
                      : (val) {
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
            if (_featuresCondition == 'yes' ||
                (_featureList.isNotEmpty && isDealer))
              _buildFeaturesSection(),
            const SizedBox(height: 30),
          ]
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
    if (_transporterUsers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    String? currentTransporterEmail;
    if (_selectedTransporterId != null) {
      final transporter = _transporterUsers.firstWhere(
        (user) => user['id'] == _selectedTransporterId,
        orElse: () => {'email': null},
      );
      currentTransporterEmail = transporter['email'];
    }

    final List<String> transporterEmails = _transporterUsers
        .map((e) => e['email'] as String)
        .where((email) => email != null)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Transporter: ${currentTransporterEmail ?? 'None'}",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 15),
        CustomDropdown(
          hintText: 'Select Transporter',
          value: currentTransporterEmail,
          items: transporterEmails,
          onChanged: (value) {
            if (value != null) {
              final selected = _transporterUsers.firstWhere(
                (user) => user['email'] == value,
                orElse: () => {'id': null},
              );
              setState(() {
                _selectedTransporterId = selected['id'];
                _selectedTransporterEmail = value;
              });
              debugPrint(
                  "Selected Transporter - ID: $_selectedTransporterId, Email: $value");
            }
          },
        ),
      ],
    );
  }

  Widget _buildSalesRepField() {
    if (_salesRepUsers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    String? currentSalesRepEmail;
    if (_selectedSalesRepId != null) {
      final salesRep = _salesRepUsers.firstWhere(
        (user) => user['id'] == _selectedSalesRepId,
        orElse: () => {'email': null},
      );
      currentSalesRepEmail = salesRep['email'];
    }

    final List<String> salesRepEmails = _salesRepUsers
        .map((e) => e['email'] as String)
        .where((email) => email != null)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Sales Rep: ${currentSalesRepEmail ?? 'None'}",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 15),
        CustomDropdown(
          hintText: 'Select Sales Rep',
          value: currentSalesRepEmail,
          items: salesRepEmails,
          onChanged: (value) {
            if (value != null) {
              final selected = _salesRepUsers.firstWhere(
                (user) => user['email'] == value,
                orElse: () => {'id': null},
              );
              setState(() {
                _selectedSalesRepId = selected['id'];
                _selectedSalesRepEmail = value;
              });
              debugPrint(
                  "Selected Sales Rep - ID: $_selectedSalesRepId, Email: $value");
            }
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
          return {
            'id': doc.id,
            'email': data['email'] ?? 'No Email',
          };
        }).toList();
      });

      debugPrint("Loaded ${_transporterUsers.length} transporters");

      // Set initial value if we have a selected ID
      if (_selectedTransporterId != null) {
        final transporter = _transporterUsers.firstWhere(
          (user) => user['id'] == _selectedTransporterId,
          orElse: () => {'email': null},
        );
        _selectedTransporterEmail = transporter['email'];
        debugPrint("Set initial transporter email: $_selectedTransporterEmail");
      }
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
          return {
            'id': doc.id,
            'email': data['email'] ?? 'No Email',
          };
        }).toList();
      });

      debugPrint("Loaded ${_salesRepUsers.length} sales reps");

      // Set initial value if we have a selected ID
      if (_selectedSalesRepId != null) {
        final salesRep = _salesRepUsers.firstWhere(
          (user) => user['id'] == _selectedSalesRepId,
          orElse: () => {'email': null},
        );
        _selectedSalesRepEmail = salesRep['email'];
        debugPrint("Set initial sales rep email: $_selectedSalesRepEmail");
      }
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
        'userId': _selectedTransporterId,
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
      final formData = Provider.of<TrailerFormProvider>(context, listen: false);
      if (_selectedTrailerType == 'Superlink') {
        trailerExtraInfo = {
          'trailerA': {
            'make': _makeTrailerAController.text,
            'model': _modelTrailerAController.text,
            'year': _yearTrailerAController.text,
            'licenseExp': _licenceDiskExpTrailerAController.text,
            'length': _lengthTrailerAController.text,
            'vin': _vinAController.text,
            'registration': _registrationAController.text,
            'axles': _axlesTrailerAController.text,
            'abs': formData.absA,
            'suspension': formData.suspensionA,
            'natisDocUrl': _natisTrailerADoc1File != null
                ? await _uploadFileToFirebaseStorage(_natisTrailerADoc1File!,
                    'vehicle_documents', _natisTrailerADoc1FileName)
                : _existingNatisTrailerADocUrl ?? '',
            // Base images
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
<<<<<<< HEAD
            'trailerAAdditionalImages':
                await _uploadListItems(_additionalImagesListTrailerA),
=======
            // Additional images
            'hookPinImageUrl': _hookPinImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _hookPinImageA!, 'vehicle_images')
                : widget.vehicle.trailer?.rawTrailerExtraInfo?['trailerA']
                        ?['hookPinImageUrl'] ??
                    '',
            'roofImageUrl': _roofImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _roofImageA!, 'vehicle_images')
                : widget.vehicle.trailer?.rawTrailerExtraInfo?['trailerA']
                        ?['roofImageUrl'] ??
                    '',
            'tailBoardImageUrl': _tailBoardImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _tailBoardImageA!, 'vehicle_images')
                : widget.vehicle.trailer?.rawTrailerExtraInfo?['trailerA']
                        ?['tailBoardImageUrl'] ??
                    '',
            'spareWheelImageUrl': _spareWheelImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _spareWheelImageA!, 'vehicle_images')
                : widget.vehicle.trailer?.rawTrailerExtraInfo?['trailerA']
                        ?['spareWheelImageUrl'] ??
                    '',
            'landingLegImageUrl': _landingLegImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _landingLegImageA!, 'vehicle_images')
                : widget.vehicle.trailer?.rawTrailerExtraInfo?['trailerA']
                        ?['landingLegImageUrl'] ??
                    '',
            'hoseAndElecticalCableImageUrl':
                _hoseAndElecticalCableImageA != null
                    ? await _uploadFileToFirebaseStorage(
                        _hoseAndElecticalCableImageA!, 'vehicle_images')
                    : widget.vehicle.trailer?.rawTrailerExtraInfo?['trailerA']
                            ?['hoseAndElecticalCableImageUrl'] ??
                        '',
            'brakesAxle1ImageUrl': _brakesAxle1ImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _brakesAxle1ImageA!, 'vehicle_images')
                : widget.vehicle.trailer?.rawTrailerExtraInfo?['trailerA']
                        ?['brakesAxle1ImageUrl'] ??
                    '',
            'brakesAxle2ImageUrl': _brakesAxle2ImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _brakesAxle2ImageA!, 'vehicle_images')
                : widget.vehicle.trailer?.rawTrailerExtraInfo?['trailerA']
                        ?['brakesAxle2ImageUrl'] ??
                    '',
            'axle1ImageUrl': _axle1ImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _axle1ImageA!, 'vehicle_images')
                : widget.vehicle.trailer?.rawTrailerExtraInfo?['trailerA']
                        ?['axle1ImageUrl'] ??
                    '',
            'axle2ImageUrl': _axle2ImageA != null
                ? await _uploadFileToFirebaseStorage(
                    _axle2ImageA!, 'vehicle_images')
                : widget.vehicle.trailer?.rawTrailerExtraInfo?['trailerA']
                        ?['axle2ImageUrl'] ??
                    '',
>>>>>>> 3aa75c9 (feat: Enhance form data providers with suspension and ABS fields)
          },
          'trailerB': {
            // Similar structure for Trailer B
            'make': _makeTrailerBController.text,
            'model': _modelTrailerBController.text,
            'year': _yearTrailerBController.text,
            'licenseExp': _licenceDiskExpTrailerBController.text,
            'length': _lengthTrailerBController.text,
            'vin': _vinBController.text,
            'registration': _registrationBController.text,
            'axles': _axlesTrailerBController.text,
            'abs': formData.absB,
            'suspension': formData.suspensionB,
            'natisDocUrl': _natisTrailerBDoc1File != null
                ? await _uploadFileToFirebaseStorage(_natisTrailerBDoc1File!,
                    'vehicle_documents', _natisTrailerBDoc1FileName)
                : _existingNatisTrailerBDocUrl ?? '',
            // Base images
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
<<<<<<< HEAD
            'trailerBAdditionalImages':
                await _uploadListItems(_additionalImagesListTrailerB),
=======
            // Additional images
            'hookPinImageUrl': _hookPinImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _hookPinImageB!, 'vehicle_images')
                : widget.vehicle.trailer?.rawTrailerExtraInfo?['trailerB']
                        ?['hookPinImageUrl'] ??
                    '',
            'roofImageUrl': _roofImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _roofImageB!, 'vehicle_images')
                : widget.vehicle.trailer?.rawTrailerExtraInfo?['trailerB']
                        ?['roofImageUrl'] ??
                    '',
            'tailBoardImageUrl': _tailBoardImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _tailBoardImageB!, 'vehicle_images')
                : widget.vehicle.trailer?.rawTrailerExtraInfo?['trailerB']
                        ?['tailBoardImageUrl'] ??
                    '',
            'spareWheelImageUrl': _spareWheelImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _spareWheelImageB!, 'vehicle_images')
                : widget.vehicle.trailer?.rawTrailerExtraInfo?['trailerB']
                        ?['spareWheelImageUrl'] ??
                    '',
            'landingLegImageUrl': _landingLegImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _landingLegImageB!, 'vehicle_images')
                : widget.vehicle.trailer?.rawTrailerExtraInfo?['trailerB']
                        ?['landingLegImageUrl'] ??
                    '',
            'hoseAndElecticalCableImageUrl':
                _hoseAndElecticalCableImageB != null
                    ? await _uploadFileToFirebaseStorage(
                        _hoseAndElecticalCableImageB!, 'vehicle_images')
                    : widget.vehicle.trailer?.rawTrailerExtraInfo?['trailerB']
                            ?['hoseAndElecticalCableImageUrl'] ??
                        '',
            'brakesAxle1ImageUrl': _brakesAxle1ImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _brakesAxle1ImageB!, 'vehicle_images')
                : widget.vehicle.trailer?.rawTrailerExtraInfo?['trailerB']
                        ?['brakesAxle1ImageUrl'] ??
                    '',
            'brakesAxle2ImageUrl': _brakesAxle2ImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _brakesAxle2ImageB!, 'vehicle_images')
                : widget.vehicle.trailer?.rawTrailerExtraInfo?['trailerB']
                        ?['brakesAxle2ImageUrl'] ??
                    '',
            'axle1ImageUrl': _axle1ImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _axle1ImageB!, 'vehicle_images')
                : widget.vehicle.trailer?.rawTrailerExtraInfo?['trailerB']
                        ?['axle1ImageUrl'] ??
                    '',
            'axle2ImageUrl': _axle2ImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _axle2ImageB!, 'vehicle_images')
                : widget.vehicle.trailer?.rawTrailerExtraInfo?['trailerB']
                        ?['axle2ImageUrl'] ??
                    '',
>>>>>>> 3aa75c9 (feat: Enhance form data providers with suspension and ABS fields)
          },
        };
      } else if (_selectedTrailerType == 'Tri-Axle') {
        trailerExtraInfo = {
          'lengthTrailer': _lengthTrailerController.text,
          'length': _lengthTrailerController
              .text, // Add both field names for compatibility
          'vin': _vinController.text,
          'registration': _registrationController.text,
          'make': _makeController.text,
          'model': _modelController.text,
          'year': _yearController.text,
          'licenseExp': _licenseExpController.text,
          'numbAxel': _numbAxelController.text,
          'axles': _axlesController
              .text, // Save to both field names for compatibility
          'suspension': formData.suspensionA ?? 'steel',
          'abs': formData.absA ?? 'no',
          'natisDocUrl': _natisTriAxleDocFile != null
              ? await _uploadFileToFirebaseStorage(_natisTriAxleDocFile!,
                  'vehicle_documents', _natisTriAxleDocFileName)
              : _existingNatisTriAxleDocUrl ?? '',
          // Base images
          'frontImageUrl': _frontImage != null
              ? await _uploadFileToFirebaseStorage(
                  _frontImage!, 'vehicle_images')
              : _frontImageUrl ?? '',
          'sideImageUrl': _sideImage != null
              ? await _uploadFileToFirebaseStorage(
                  _sideImage!, 'vehicle_images')
              : _sideImageUrl ?? '',
          'tyresImageUrl': _tyresImage != null
              ? await _uploadFileToFirebaseStorage(
                  _tyresImage!, 'vehicle_images')
              : _tyresImageUrl ?? '',
          'chassisImageUrl': _chassisImage != null
              ? await _uploadFileToFirebaseStorage(
                  _chassisImage!, 'vehicle_images')
              : _chassisImageUrl ?? '',
          'deckImageUrl': _deckImage != null
              ? await _uploadFileToFirebaseStorage(
                  _deckImage!, 'vehicle_images')
              : _deckImageUrl ?? '',
          'makersPlateImageUrl': _makersPlateImage != null
              ? await _uploadFileToFirebaseStorage(
                  _makersPlateImage!, 'vehicle_images')
              : _makersPlateImageUrl ?? '',
          // Additional images
          'hookPinImageUrl': _hookpinImage != null
              ? await _uploadFileToFirebaseStorage(
                  _hookpinImage!, 'vehicle_images')
              : widget.vehicle.trailer
                      ?.rawTrailerExtraInfo?['hookPinImageUrl'] ??
                  '',
<<<<<<< HEAD
          'additionalImages': await _uploadListItems(_additionalImagesList),
=======
          'roofImageUrl': _roofImage != null
              ? await _uploadFileToFirebaseStorage(
                  _roofImage!, 'vehicle_images')
              : widget.vehicle.trailer?.rawTrailerExtraInfo?['roofImageUrl'] ??
                  '',
          'tailboardImageUrl': _tailboardImage != null
              ? await _uploadFileToFirebaseStorage(
                  _tailboardImage!, 'vehicle_images')
              : widget.vehicle.trailer
                      ?.rawTrailerExtraInfo?['tailboardImageUrl'] ??
                  '',
          'spareWheelImageUrl': _spareWheelImage != null
              ? await _uploadFileToFirebaseStorage(
                  _spareWheelImage!, 'vehicle_images')
              : widget.vehicle.trailer
                      ?.rawTrailerExtraInfo?['spareWheelImageUrl'] ??
                  '',
          'landingLegsImageUrl': _landingLegsImage != null
              ? await _uploadFileToFirebaseStorage(
                  _landingLegsImage!, 'vehicle_images')
              : widget.vehicle.trailer
                      ?.rawTrailerExtraInfo?['landingLegsImageUrl'] ??
                  '',
          'hoseAndElectricCableImageUrl': _hoseAndElectricCableImage != null
              ? await _uploadFileToFirebaseStorage(
                  _hoseAndElectricCableImage!, 'vehicle_images')
              : widget.vehicle.trailer
                      ?.rawTrailerExtraInfo?['hoseAndElectricCableImageUrl'] ??
                  '',
          'brakeAxel1ImageUrl': _brakeAxel1Image != null
              ? await _uploadFileToFirebaseStorage(
                  _brakeAxel1Image!, 'vehicle_images')
              : widget.vehicle.trailer
                      ?.rawTrailerExtraInfo?['brakeAxel1ImageUrl'] ??
                  '',
          'brakeAxel2ImageUrl': _brakeAxel2Image != null
              ? await _uploadFileToFirebaseStorage(
                  _brakeAxel2Image!, 'vehicle_images')
              : widget.vehicle.trailer
                      ?.rawTrailerExtraInfo?['brakeAxel2ImageUrl'] ??
                  '',
          'brakeAxel3ImageUrl': _brakeAxel3Image != null
              ? await _uploadFileToFirebaseStorage(
                  _brakeAxel3Image!, 'vehicle_images')
              : widget.vehicle.trailer
                      ?.rawTrailerExtraInfo?['brakeAxel3ImageUrl'] ??
                  '',
          'axel1ImageUrl': _axel1Image != null
              ? await _uploadFileToFirebaseStorage(
                  _axel1Image!, 'vehicle_images')
              : widget.vehicle.trailer?.rawTrailerExtraInfo?['axel1ImageUrl'] ??
                  '',
          'axel2ImageUrl': _axel2Image != null
              ? await _uploadFileToFirebaseStorage(
                  _axel2Image!, 'vehicle_images')
              : widget.vehicle.trailer?.rawTrailerExtraInfo?['axel2ImageUrl'] ??
                  '',
          'axel3ImageUrl': _axel3Image != null
              ? await _uploadFileToFirebaseStorage(
                  _axel3Image!, 'vehicle_images')
              : widget.vehicle.trailer?.rawTrailerExtraInfo?['axel3ImageUrl'] ??
                  '',
          'licenseDiskImageUrl': _licenseDiskImage != null
              ? await _uploadFileToFirebaseStorage(
                  _licenseDiskImage!, 'vehicle_images')
              : widget.vehicle.trailer
                      ?.rawTrailerExtraInfo?['licenseDiskImageUrl'] ??
                  '',
        };
      } else if (_selectedTrailerType == 'Double Axle') {
        trailerExtraInfo = {
          'make': _makeDoubleAxleController.text,
          'model': _modelDoubleAxleController.text,
          'year': _yearDoubleAxleController.text,
          'length': _lengthDoubleAxleController.text,
          'vin': _vinController.text,
          'registration': _registrationController.text,
          'licenseExp': _licenceDiskExpDoubleAxleController.text,
          'numbAxel': _numbAxelDoubleAxleController.text,
          'axles': _numbAxelDoubleAxleController.text, // For compatibility
          'suspension': _suspensionDoubleAxle,
          'abs': _absDoubleAxle,
          'natisDocUrl': _natisDoubleAxleDocFile != null
              ? await _uploadFileToFirebaseStorage(_natisDoubleAxleDocFile!,
                  'vehicle_documents', _natisDoubleAxleDocFileName)
              : _existingNatisDoubleAxleDocUrl ?? '',

          // Upload all images
          'frontImageUrl': _frontImage != null
              ? await _uploadFileToFirebaseStorage(
                  _frontImage!, 'vehicle_images')
              : _frontImageUrl ?? '',
          'sideImageUrl': _sideImage != null
              ? await _uploadFileToFirebaseStorage(
                  _sideImage!, 'vehicle_images')
              : _sideImageUrl ?? '',
          'chassisImageUrl': _chassisImage != null
              ? await _uploadFileToFirebaseStorage(
                  _chassisImage!, 'vehicle_images')
              : _chassisImageUrl ?? '',
          'hookingPinImageUrl': _hookingPinDoubleAxleImage != null
              ? await _uploadFileToFirebaseStorage(
                  _hookingPinDoubleAxleImage!, 'vehicle_images')
              : '',
          'deckImageUrl': _deckImage != null
              ? await _uploadFileToFirebaseStorage(
                  _deckImage!, 'vehicle_images')
              : _deckImageUrl ?? '',
          'roofImageUrl': _roofDoubleAxleImage != null
              ? await _uploadFileToFirebaseStorage(
                  _roofDoubleAxleImage!, 'vehicle_images')
              : '',
          'tyresImageUrl': _tyresDoubleAxleImage != null
              ? await _uploadFileToFirebaseStorage(
                  _tyresDoubleAxleImage!, 'vehicle_images')
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
          'hoseAndElecCableImageUrl': _hoseAndElecCableDoubleAxleImage != null
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
          'makersPlateImageUrl': _makersPlateDblAxleImage != null
              ? await _uploadFileToFirebaseStorage(
                  _makersPlateDblAxleImage!, 'vehicle_images')
              : '',
        };
      } else if (_selectedTrailerType == 'Other') {
        trailerExtraInfo = {
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
              ? await _uploadFileToFirebaseStorage(_natisOtherDocFile!,
                  'vehicle_documents', _natisOtherDocFileName)
              : _existingNatisOtherDocUrl ?? '',
          // Upload all images
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
          'hoseAndElecCableImageUrl': _hoseAndElecCableOtherImage != null
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
>>>>>>> 3aa75c9 (feat: Enhance form data providers with suspension and ABS fields)
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

    // Debug the existing URL
    if (hasExistingUrl) {
      debugPrint("Image section '$title' has existing URL: $existingUrl");
    }

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
            final bool isDealer =
                Provider.of<UserProvider>(context, listen: false).getUserRole ==
                    'dealer';
            if (hasImage) {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(title),
                    content: const Text(
                        'What would you like to do with this image?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _openFullScreenImage(
                            image: image,
                            imageUrl: (hasExistingUrl && image == null)
                                ? existingUrl
                                : null,
                          );
                        },
                        child: const Text('View'),
                      ),
                      if (!isDealer)
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
                          child: const Text('Replace'),
                        ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ],
                  );
                },
              );
            } else if (!isDealer) {
              _pickImageOrFile(
                title: title,
                pickImageOnly: true,
                callback: (file, fileName) {
                  if (file != null) onImagePicked(file);
                },
              );
            }
          },
          child: Stack(
            children: [
              _buildStyledContainer(
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
                                width: double.infinity, loadingBuilder:
                                    (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            }, errorBuilder: (context, error, stackTrace) {
                              debugPrint(
                                  "Error loading image $existingUrl: $error");
                              return const Column(
                                children: [
                                  Icon(Icons.broken_image,
                                      color: Colors.red, size: 50.0),
                                  SizedBox(height: 10),
                                  Text('Failed to load image',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.white70),
                                      textAlign: TextAlign.center),
                                ],
                              );
                            }),
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
              if (hasImage)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(hasExistingUrl ? Icons.check_circle : Icons.edit,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          hasExistingUrl ? 'Saved' : 'New',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
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

  // Add method to view Double Axle NATIS document
  void _viewDoubleAxleDocument() async {
    if (_existingNatisDoubleAxleDocUrl != null &&
        _existingNatisDoubleAxleDocUrl!.isNotEmpty) {
      final Uri uri = Uri.parse(_existingNatisDoubleAxleDocUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open document')),
        );
      }
    }
  }

  // Add method to show Double Axle document options dialog
  void _showDoubleAxleDocumentOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('NATIS Document Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_existingNatisDoubleAxleDocUrl != null &&
                  _existingNatisDoubleAxleDocUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.remove_red_eye),
                  title: const Text('View Document'),
                  onTap: () {
                    Navigator.pop(context);
                    _viewDoubleAxleDocument();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Replace Document'),
                onTap: () {
                  Navigator.pop(context);
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
                },
              ),
              if (_existingNatisDoubleAxleDocUrl != null ||
                  _natisDoubleAxleDocFile != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Document',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _natisDoubleAxleDocFile = null;
                      _natisDoubleAxleDocFileName = null;
                      _existingNatisDoubleAxleDocUrl = null;
                    });
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

  // Method to build dynamic axle image section based on number of axles
  Widget _buildDynamicAxleImageSection() {
    // Try to get the number of axles from the controller
    int numAxles = 0;
    try {
      numAxles = int.parse(_numbAxelOtherController.text.trim());
    } catch (e) {
      // Default to 2 axles if parsing fails
      numAxles = 2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Axle Images",
            style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        for (int i = 1; i <= numAxles; i++) ...[
          // Text("Axle $i Image",
          //     style: const TextStyle(fontSize: 14, color: Colors.white)),
          const SizedBox(height: 10),
          _buildImageSectionWithTitle(
            'Axle $i Image',
            null, // You would need to create dynamic variables for each axle
            (img) {
              // Handle dynamic axle image selection
              // This is a simplified version
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Axle $i image selection not implemented')),
              );
            },
          ),
          const SizedBox(height: 15),
        ],
      ],
    );
  }

  // Method to build additional images section
  Widget _buildAdditionalImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Additional Images (Optional)",
            style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Center(
          child: GestureDetector(
            onTap: () {
              // Add functionality to add additional images
              _showAdditionalImageSourceDialog(
                  {'image': null, 'description': 'Additional Image'});
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.blue, size: 30.0),
                SizedBox(width: 8.0),
                Text('Add Additional Image',
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

  // Method to build additional features section
  Widget _buildAdditionalFeaturesSection() {
    // This is similar to _buildFeaturesSection but can be customized if needed
    return _buildFeaturesSection();
  }

  // Add this method to view the NATIS document for Other trailer type
  void _viewOtherDocument() async {
    if (_existingNatisOtherDocUrl != null &&
        _existingNatisOtherDocUrl!.isNotEmpty) {
      final Uri uri = Uri.parse(_existingNatisOtherDocUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open document')),
        );
      }
    } else if (_natisOtherDocFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Local document viewing not implemented')),
      );
    }
  }
}
