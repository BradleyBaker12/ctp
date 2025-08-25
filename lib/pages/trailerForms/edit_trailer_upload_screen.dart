// import 'package:auto_route/auto_route.dart';
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
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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

// @RoutePage()
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
  final TextEditingController _modelController = TextEditingController();
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
  // Dynamic tyres (Tri-Axle)
  List<Uint8List?> _tyreImages = [];
  List<String> _tyreImageUrls = [];
  Uint8List? _chassisImage;
  Uint8List? _deckImage;
  Uint8List? _makersPlateImage;

  // === Superlink Controllers (Trailer A) ===
  final TextEditingController _lengthTrailerAController =
      TextEditingController();
  final TextEditingController _vinAController = TextEditingController();
  final TextEditingController _registrationAController =
      TextEditingController();
  final TextEditingController _modelTrailerAController =
      TextEditingController();
  final TextEditingController _yearTrailerAController = TextEditingController();
  final TextEditingController _makeTrailerAController =
      TextEditingController(); // For symmetry, but _makeController is used for Trailer A
  Uint8List? _frontImageA;
  Uint8List? _sideImageA;
  Uint8List? _tyresImageA;
  // Dynamic tyres (Superlink Trailer A)
  List<Uint8List?> _tyreImagesA = [];
  List<String> _tyreImageUrlsA = [];
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
  final TextEditingController _makeTrailerBController = TextEditingController();
  final TextEditingController _modelTrailerBController =
      TextEditingController();
  final TextEditingController _yearTrailerBController = TextEditingController();
  Uint8List? _frontImageB;
  Uint8List? _sideImageB;
  Uint8List? _tyresImageB;
  // Dynamic tyres (Superlink Trailer B)
  List<Uint8List?> _tyreImagesB = [];
  List<String> _tyreImageUrlsB = [];
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

  // ── Double-Axle ─────────────────────────────────────────────────────────
  final TextEditingController _makeDoubleAxleController =
      TextEditingController();
  final TextEditingController _modelDoubleAxleController =
      TextEditingController();
  final TextEditingController _yearDoubleAxleController =
      TextEditingController();
  final TextEditingController _lengthDoubleAxleController =
      TextEditingController();
  final TextEditingController _vinDoubleAxleController =
      TextEditingController();
  final TextEditingController _registrationDoubleAxleController =
      TextEditingController();
  final TextEditingController _licenceDiskExpDoubleAxleController =
      TextEditingController();
  final TextEditingController _numbAxelDoubleAxleController =
      TextEditingController();
  String _suspensionDoubleAxle = 'steel';
  String _absDoubleAxle = 'no';
  // === Double-Axle Images & Doc ===
  Uint8List? _frontImageDoubleAxle;
  Uint8List? _sideImageDoubleAxle;
  Uint8List? _tyresImageDoubleAxle;
  // Dynamic tyres (Double Axle)
  List<Uint8List?> _tyreImagesDoubleAxle = [];
  List<String> _tyreImageUrlsDoubleAxle = [];
  Uint8List? _chassisImageDoubleAxle;
  Uint8List? _deckImageDoubleAxle;
  Uint8List? _makersPlateImageDoubleAxle;
  Uint8List? _natisDoubleAxleDocFile;
  String? _natisDoubleAxleDocFileName;
  String? _existingNatisDoubleAxleDocUrl;
  // Add missing fields for Double Axle
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

  // ── Other Trailer ───────────────────────────────────────────────────────
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
  String _suspensionOther = 'steel';
  String _absOther = 'no';
  // === Other Images & Doc ===
  Uint8List? _frontOtherImage;
  Uint8List? _sideOtherImage;
  Uint8List? _tyresOtherImage;
  // Dynamic tyres (Other)
  List<Uint8List?> _tyreImagesOther = [];
  List<String> _tyreImageUrlsOther = [];
  Uint8List? _chassisOtherImage;
  Uint8List? _deckOtherImage;
  Uint8List? _makersPlateOtherImage;
  Uint8List? _natisOtherDocFile;
  String? _natisOtherDocFileName;
  String? _existingNatisOtherDocUrl;
  // Add missing fields for 'Other' trailer type
  Uint8List? _hookingPinOtherImage;
  Uint8List? _roofOtherImage;
  Uint8List? _tailBoardOtherImage;
  Uint8List? _spareWheelOtherImage;
  Uint8List? _landingLegsOtherImage;
  Uint8List? _hoseAndElecCableOtherImage;
  Uint8List? _licenseDiskOtherImage;

  // === Damage & Additional Features (Missing in original edit form) ===
  String _damagesCondition = 'no';
  final List<Map<String, dynamic>> _damageList = [];

  // Add fields for Double Axle image URLs
  String? _hookingPinDoubleAxleUrl;
  String? _roofDoubleAxleUrl;
  String? _tailBoardDoubleAxleUrl;
  String? _spareWheelDoubleAxleUrl;
  String? _landingLegsDoubleAxleUrl;
  String? _hoseAndElecCableDoubleAxleUrl;
  String? _brakesAxle1DoubleAxleUrl;
  String? _brakesAxle2DoubleAxleUrl;
  String? _axle1DoubleAxleUrl;
  String? _axle2DoubleAxleUrl;
  String? _licenseDiskDoubleAxleUrl;

  // --- Superlink Suspension/ABS fields ---
  String _suspensionTrailerA = 'steel';
  String _absTrailerA = 'no';
  String _suspensionTrailerB = 'steel';
  String _absTrailerB = 'no';

  // === Superlink Trailer A missing controllers and image variables ===
  final TextEditingController _licenceDiskExpTrailerAController =
      TextEditingController();
  Uint8List? _hookPinImageA;
  Uint8List? _roofImageA;

  // === Superlink Trailer B missing controllers and image variables ===
  final TextEditingController _licenceDiskExpTrailerBController =
      TextEditingController();
  Uint8List? _hookPinImageB;
  Uint8List? _roofImageB;

  // === Superlink Trailer A additional image variables ===
  Uint8List? _tailBoardImageA;
  Uint8List? _spareWheelImageA;
  Uint8List? _landingLegImageA;
  Uint8List? _hoseAndElecticalCableImageA;
  Uint8List? _brakesAxle1ImageA;
  Uint8List? _brakesAxle2ImageA;
  Uint8List? _axle1ImageA;
  Uint8List? _axle2ImageA;

  // === Superlink Trailer B additional image variables ===
  Uint8List? _tailBoardImageB;
  Uint8List? _spareWheelImageB;
  Uint8List? _landingLegImageB;
  Uint8List? _hoseAndElecticalCableImageB;
  Uint8List? _brakesAxle1ImageB;
  Uint8List? _brakesAxle2ImageB;
  Uint8List? _axle1ImageB;
  Uint8List? _axle2ImageB;

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
    // Double-Axle
    _makeDoubleAxleController.dispose();
    _modelDoubleAxleController.dispose();
    _yearDoubleAxleController.dispose();
    _lengthDoubleAxleController.dispose();
    _vinDoubleAxleController.dispose();
    _registrationDoubleAxleController.dispose();
    _licenceDiskExpDoubleAxleController.dispose();
    _numbAxelDoubleAxleController.dispose();
// Other
    _makeOtherController.dispose();
    _modelOtherController.dispose();
    _yearOtherController.dispose();
    _lengthOtherController.dispose();
    _vinOtherController.dispose();
    _registrationOtherController.dispose();
    _licenceDiskExpOtherController.dispose();
    _numbAxelOtherController.dispose();
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
    _modelTrailerAController.dispose();
    _yearTrailerAController.dispose();
    _makeTrailerBController.dispose();
    _modelTrailerBController.dispose();
    _yearTrailerBController.dispose();
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
      _modelController.text = data['model']?.toString() ?? '';
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

        // --- Add missing fields for Trailer A ---
        _makeController.text = trailerA['make']?.toString() ?? '';
        _modelTrailerAController.text = trailerA['model']?.toString() ?? '';
        _yearTrailerAController.text = trailerA['year']?.toString() ?? '';

        // --- Add missing fields for Trailer B ---
        _makeTrailerBController.text = trailerB['make']?.toString() ?? '';
        _modelTrailerBController.text = trailerB['model']?.toString() ?? '';
        _yearTrailerBController.text = trailerB['year']?.toString() ?? '';

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

        // --- Robust Superlink image/document URL extraction ---
        String getField(Map<String, dynamic> map, List<String> keys) {
          for (final key in keys) {
            if (map[key] != null && map[key].toString().isNotEmpty) {
              return map[key].toString();
            }
          }
          return '';
        }

        // Trailer A Image URLs
        _frontImageAUrl = getField(
            trailerA, ['frontImageUrl', 'front_image_url', 'frontimageurl']);
        _sideImageAUrl = getField(
            trailerA, ['sideImageUrl', 'side_image_url', 'sideimageurl']);
        _tyresImageAUrl = getField(
            trailerA, ['tyresImageUrl', 'tyres_image_url', 'tyresimageurl']);
        // Superlink A tyre arrays
        if (trailerA['tyreImageUrls'] is List) {
          _tyreImageUrlsA = List<String>.from(
              (trailerA['tyreImageUrls'] as List)
                  .map((e) => (e ?? '').toString()));
          while (_tyreImageUrlsA.isNotEmpty && _tyreImageUrlsA.last.isEmpty) {
            _tyreImageUrlsA.removeLast();
          }
        }
        if (_tyreImageUrlsA.isEmpty && (_tyresImageAUrl?.isNotEmpty ?? false)) {
          _tyreImageUrlsA = [_tyresImageAUrl!];
        }
        _chassisImageAUrl = getField(trailerA,
            ['chassisImageUrl', 'chassis_image_url', 'chassisimageurl']);
        _deckImageAUrl = getField(
            trailerA, ['deckImageUrl', 'deck_image_url', 'deckimageurl']);
        _makersPlateImageAUrl = getField(trailerA, [
          'makersPlateImageUrl',
          'makers_plate_image_url',
          'makersplateimageurl'
        ]);
        _additionalImagesListTrailerA.clear();
        if (trailerA['trailerAAdditionalImages'] != null &&
            (trailerA['trailerAAdditionalImages'] as List).isNotEmpty) {
          _additionalImagesListTrailerA.addAll(
            List<Map<String, dynamic>>.from(
                trailerA['trailerAAdditionalImages']),
          );
        }
        // NATIS doc for Trailer A (handle possible typo: natisDoc1Url)
        _existingNatisTrailerADocUrl = getField(
            trailerA, ['natisDocUrl', 'natisDoc1Url', 'natis_document_url']);
        _existingNatisTrailerADoc1Url = _existingNatisTrailerADocUrl ?? '';
        _existingNatisTrailerADoc1Name =
            _getFileNameFromUrl(_existingNatisTrailerADoc1Url);
        debugPrint(
            "NATIS Trailer A Document: '$_existingNatisTrailerADoc1Url', name: '$_existingNatisTrailerADoc1Name'");

        // --- Trailer B ---
        _existingNatisTrailerBDoc1Url = getField(
            trailerB, ['natisDocUrl', 'natisDoc1Url', 'natis_document_url']);
        _existingNatisTrailerBDoc1Name =
            _getFileNameFromUrl(_existingNatisTrailerBDoc1Url);

        // Trailer B
        _lengthTrailerBController.text = trailerB['length']?.toString() ?? '';
        _vinBController.text = trailerB['vin']?.toString() ?? '';
        _registrationBController.text =
            trailerB['registration']?.toString() ?? '';
        _axlesTrailerBController.text = trailerB['axles']?.toString() ?? '';

        debugPrint(
            "DEBUG: Set Trailer B - Length: ${_lengthTrailerBController.text}, VIN: ${_vinBController.text}, Reg: ${_registrationBController.text}");
        debugPrint(
            "DEBUG: Trailer B additionalImages: ${trailerB['trailerBAdditionalImages']}");
        // Trailer B Image URLs
        _frontImageBUrl = getField(
            trailerB, ['frontImageUrl', 'front_image_url', 'frontimageurl']);
        _sideImageBUrl = getField(
            trailerB, ['sideImageUrl', 'side_image_url', 'sideimageurl']);
        _tyresImageBUrl = getField(
            trailerB, ['tyresImageUrl', 'tyres_image_url', 'tyresimageurl']);
        // Superlink B tyre arrays
        if (trailerB['tyreImageUrls'] is List) {
          _tyreImageUrlsB = List<String>.from(
              (trailerB['tyreImageUrls'] as List)
                  .map((e) => (e ?? '').toString()));
          while (_tyreImageUrlsB.isNotEmpty && _tyreImageUrlsB.last.isEmpty) {
            _tyreImageUrlsB.removeLast();
          }
        }
        if (_tyreImageUrlsB.isEmpty && (_tyresImageBUrl?.isNotEmpty ?? false)) {
          _tyreImageUrlsB = [_tyresImageBUrl!];
        }
        _chassisImageBUrl = getField(trailerB,
            ['chassisImageUrl', 'chassis_image_url', 'chassisimageurl']);
        _deckImageBUrl = getField(
            trailerB, ['deckImageUrl', 'deck_image_url', 'deckimageurl']);
        _makersPlateImageBUrl = getField(trailerB, [
          'makersPlateImageUrl',
          'makers_plate_image_url',
          'makersplateimageurl'
        ]);
        _additionalImagesListTrailerB.clear();
        if (trailerB['trailerBAdditionalImages'] != null &&
            (trailerB['trailerBAdditionalImages'] as List).isNotEmpty) {
          _additionalImagesListTrailerB.addAll(
            List<Map<String, dynamic>>.from(
                trailerB['trailerBAdditionalImages']),
          );
        }
      } else if (_selectedTrailerType == 'Tri-Axle') {
        // Prepopulate Tri-Axle fields from trailerExtraInfo if available, else fallback to root-level fields
        _makeController.text = trailerExtra['make']?.toString() ??
            data['makeModel']?.toString() ??
            '';
        _modelController.text = trailerExtra['model']?.toString() ??
            data['model']?.toString() ??
            '';
        _yearController.text =
            trailerExtra['year']?.toString() ?? data['year']?.toString() ?? '';
        _axlesController.text = trailerExtra['axles']?.toString() ??
            data['axles']?.toString() ??
            '';
        _lengthTrailerController.text =
            trailerExtra['lengthTrailer']?.toString() ??
                data['lengthTrailer']?.toString() ??
                '';
        _vinController.text =
            trailerExtra['vin']?.toString() ?? data['vin']?.toString() ?? '';
        _registrationController.text =
            trailerExtra['registration']?.toString() ??
                data['registration']?.toString() ??
                '';
        _existingNatisTriAxleDocUrl = trailerExtra['natisDocUrl']?.toString() ??
            data['natisDocUrl']?.toString() ??
            '';
        _frontImageUrl = trailerExtra['frontImageUrl']?.toString() ??
            data['frontImageUrl']?.toString() ??
            '';
        _sideImageUrl = trailerExtra['sideImageUrl']?.toString() ??
            data['sideImageUrl']?.toString() ??
            '';
        _tyresImageUrl = trailerExtra['tyresImageUrl']?.toString() ??
            data['tyresImageUrl']?.toString() ??
            '';
        // Tri-Axle tyre arrays
        if (trailerExtra['tyreImageUrls'] is List) {
          _tyreImageUrls = List<String>.from(
              (trailerExtra['tyreImageUrls'] as List)
                  .map((e) => (e ?? '').toString()));
        } else if (data['tyreImageUrls'] is List) {
          _tyreImageUrls = List<String>.from(
              (data['tyreImageUrls'] as List).map((e) => (e ?? '').toString()));
        }
        while (_tyreImageUrls.isNotEmpty && _tyreImageUrls.last.isEmpty) {
          _tyreImageUrls.removeLast();
        }
        if (_tyreImageUrls.isEmpty && (_tyresImageUrl?.isNotEmpty ?? false)) {
          _tyreImageUrls = [_tyresImageUrl!];
        }
        _chassisImageUrl = trailerExtra['chassisImageUrl']?.toString() ??
            data['chassisImageUrl']?.toString() ??
            '';
        _deckImageUrl = trailerExtra['deckImageUrl']?.toString() ??
            data['deckImageUrl']?.toString() ??
            '';
        _makersPlateImageUrl =
            trailerExtra['makersPlateImageUrl']?.toString() ??
                data['makersPlateImageUrl']?.toString() ??
                '';
        if (trailerExtra.containsKey('additionalImages') &&
            (trailerExtra['additionalImages'] as List).isNotEmpty) {
          _additionalImagesList.clear();
          _additionalImagesList.addAll(List<Map<String, dynamic>>.from(
              trailerExtra['additionalImages']));
        }
      } else if (_selectedTrailerType == 'Double Axle') {
        // Prepopulate Double Axle images and NATIS doc
        _frontImageDoubleAxle = null;
        _sideImageDoubleAxle = null;
        _tyresImageDoubleAxle = null;
        _chassisImageDoubleAxle = null;
        _deckImageDoubleAxle = null;
        _makersPlateImageDoubleAxle = null;
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
        _existingNatisDoubleAxleDocUrl =
            trailerExtra['natisDocUrl']?.toString() ??
                data['natisDocUrl']?.toString() ??
                '';

        // Prepopulate controllers from trailerExtra or root-level fields
        _makeDoubleAxleController.text =
            trailerExtra['make']?.toString() ?? data['make']?.toString() ?? '';
        _modelDoubleAxleController.text = trailerExtra['model']?.toString() ??
            data['model']?.toString() ??
            '';
        _yearDoubleAxleController.text =
            trailerExtra['year']?.toString() ?? data['year']?.toString() ?? '';
        _lengthDoubleAxleController.text = trailerExtra['length']?.toString() ??
            data['length']?.toString() ??
            '';
        _vinDoubleAxleController.text =
            trailerExtra['vin']?.toString() ?? data['vin']?.toString() ?? '';
        _registrationDoubleAxleController.text =
            trailerExtra['registration']?.toString() ??
                data['registration']?.toString() ??
                '';
        _licenceDiskExpDoubleAxleController.text =
            trailerExtra['licenseExp']?.toString() ??
                data['licenseExp']?.toString() ??
                '';
        _numbAxelDoubleAxleController.text =
            trailerExtra['numbAxel']?.toString() ??
                data['numbAxel']?.toString() ??
                '';
        _suspensionDoubleAxle = trailerExtra['suspension']?.toString() ??
            data['suspension']?.toString() ??
            'steel';
        _absDoubleAxle =
            trailerExtra['abs']?.toString() ?? data['abs']?.toString() ?? 'no';

        // Prepopulate image URLs for Double Axle (use trailerExtra first, fallback to root-level)
        _frontImageUrl = trailerExtra['frontImageUrl']?.toString() ??
            data['frontImageUrl']?.toString() ??
            '';
        _sideImageUrl = trailerExtra['sideImageUrl']?.toString() ??
            data['sideImageUrl']?.toString() ??
            '';
        _tyresImageUrl = trailerExtra['tyresImageUrl']?.toString() ??
            data['tyresImageUrl']?.toString() ??
            '';
        // Double Axle tyre arrays
        if (trailerExtra['tyreImageUrls'] is List) {
          _tyreImageUrlsDoubleAxle = List<String>.from(
              (trailerExtra['tyreImageUrls'] as List)
                  .map((e) => (e ?? '').toString()));
        } else if (data['tyreImageUrls'] is List) {
          _tyreImageUrlsDoubleAxle = List<String>.from(
              (data['tyreImageUrls'] as List).map((e) => (e ?? '').toString()));
        }
        while (_tyreImageUrlsDoubleAxle.isNotEmpty &&
            _tyreImageUrlsDoubleAxle.last.isEmpty) {
          _tyreImageUrlsDoubleAxle.removeLast();
        }
        if (_tyreImageUrlsDoubleAxle.isEmpty &&
            (_tyresImageUrl?.isNotEmpty ?? false)) {
          _tyreImageUrlsDoubleAxle = [_tyresImageUrl!];
        }
        _chassisImageUrl = trailerExtra['chassisImageUrl']?.toString() ??
            data['chassisImageUrl']?.toString() ??
            '';
        _deckImageUrl = trailerExtra['deckImageUrl']?.toString() ??
            data['deckImageUrl']?.toString() ??
            '';
        _makersPlateImageUrl =
            trailerExtra['makersPlateImageUrl']?.toString() ??
                data['makersPlateImageUrl']?.toString() ??
                '';

        // Additional Double Axle images
        // Hooking Pin
        final hookPinDoubleAxleUrl =
            trailerExtra['hookingPinImageUrl']?.toString() ??
                data['trailerExtraInfo']?['hookingPinImageUrl']?.toString() ??
                data['hookingPinImageUrl']?.toString() ??
                '';
        // Roof
        final roofDoubleAxleUrl = trailerExtra['roofImageUrl']?.toString() ??
            data['trailerExtraInfo']?['roofImageUrl']?.toString() ??
            data['roofImageUrl']?.toString() ??
            '';
        // Tail Board
        final tailBoardDoubleAxleUrl =
            trailerExtra['tailBoardImageUrl']?.toString() ??
                data['trailerExtraInfo']?['tailBoardImageUrl']?.toString() ??
                data['tailBoardImageUrl']?.toString() ??
                '';
        // Spare Wheel
        final spareWheelDoubleAxleUrl =
            trailerExtra['spareWheelImageUrl']?.toString() ??
                data['trailerExtraInfo']?['spareWheelImageUrl']?.toString() ??
                data['spareWheelImageUrl']?.toString() ??
                '';
        // Landing Legs
        final landingLegsDoubleAxleUrl =
            trailerExtra['landingLegsImageUrl']?.toString() ??
                data['trailerExtraInfo']?['landingLegsImageUrl']?.toString() ??
                data['landingLegsImageUrl']?.toString() ??
                '';
        // Hose and Electrical Cable
        final hoseAndElecCableDoubleAxleUrl =
            trailerExtra['hoseAndElectricCableImageUrl']?.toString() ??
                data['trailerExtraInfo']?['hoseAndElectricCableImageUrl']
                    ?.toString() ??
                data['hoseAndElectricCableImageUrl']?.toString() ??
                '';
        // Brakes Axle 1
        final brakesAxle1DoubleAxleUrl =
            trailerExtra['brakesAxle1ImageUrl']?.toString() ??
                data['trailerExtraInfo']?['brakesAxle1ImageUrl']?.toString() ??
                data['brakesAxle1ImageUrl']?.toString() ??
                '';
        // Brakes Axle 2
        final brakesAxle2DoubleAxleUrl =
            trailerExtra['brakesAxle2ImageUrl']?.toString() ??
                data['trailerExtraInfo']?['brakesAxle2ImageUrl']?.toString() ??
                data['brakesAxle2ImageUrl']?.toString() ??
                '';
        // Axle 1
        final axle1DoubleAxleUrl = trailerExtra['axle1ImageUrl']?.toString() ??
            data['trailerExtraInfo']?['axle1ImageUrl']?.toString() ??
            data['axle1ImageUrl']?.toString() ??
            '';
        // Axle 2
        final axle2DoubleAxleUrl = trailerExtra['axle2ImageUrl']?.toString() ??
            data['trailerExtraInfo']?['axle2ImageUrl']?.toString() ??
            data['axle2ImageUrl']?.toString() ??
            '';
        // Licence Disk
        final licenseDiskDoubleAxleUrl =
            trailerExtra['licenseDiskImageUrl']?.toString() ??
                data['trailerExtraInfo']?['licenseDiskImageUrl']?.toString() ??
                data['licenseDiskImageUrl']?.toString() ??
                '';

        // Assign these URLs to be used in the UI
        _hookingPinDoubleAxleUrl = hookPinDoubleAxleUrl;
        _roofDoubleAxleUrl = roofDoubleAxleUrl;
        _tailBoardDoubleAxleUrl = tailBoardDoubleAxleUrl;
        _spareWheelDoubleAxleUrl = spareWheelDoubleAxleUrl;
        _landingLegsDoubleAxleUrl = landingLegsDoubleAxleUrl;
        _hoseAndElecCableDoubleAxleUrl = hoseAndElecCableDoubleAxleUrl;
        _brakesAxle1DoubleAxleUrl = brakesAxle1DoubleAxleUrl;
        _brakesAxle2DoubleAxleUrl = brakesAxle2DoubleAxleUrl;
        _axle1DoubleAxleUrl = axle1DoubleAxleUrl;
        _axle2DoubleAxleUrl = axle2DoubleAxleUrl;
        _licenseDiskDoubleAxleUrl = licenseDiskDoubleAxleUrl;

        // Debugging: Print all Double Axle image/document fields
        debugPrint('[DEBUG][DoubleAxle] trailerExtra: $trailerExtra');
        debugPrint(
            '[DEBUG][DoubleAxle] natisDocUrl: $_existingNatisDoubleAxleDocUrl');
        debugPrint('[DEBUG][DoubleAxle] frontImageUrl: $_frontImageUrl');
        debugPrint('[DEBUG][DoubleAxle] sideImageUrl: $_sideImageUrl');
        debugPrint('[DEBUG][DoubleAxle] tyresImageUrl: $_tyresImageUrl');
        debugPrint('[DEBUG][DoubleAxle] chassisImageUrl: $_chassisImageUrl');
        debugPrint('[DEBUG][DoubleAxle] deckImageUrl: $_deckImageUrl');
        debugPrint(
            '[DEBUG][DoubleAxle] makersPlateImageUrl: $_makersPlateImageUrl');
      } else if (_selectedTrailerType == 'Other') {
        // Prepopulate Other images and NATIS doc
        // Try to get from trailerExtra first, fallback to root-level fields
        _frontOtherImage = null;
        _sideOtherImage = null;
        _tyresOtherImage = null;
        _chassisOtherImage = null;
        _deckOtherImage = null;
        _makersPlateOtherImage = null;
        _hookingPinOtherImage = null;
        _roofOtherImage = null;
        _tailBoardOtherImage = null;
        _spareWheelOtherImage = null;
        _landingLegsOtherImage = null;
        _hoseAndElecCableOtherImage = null;
        _licenseDiskOtherImage = null;
        _existingNatisOtherDocUrl = trailerExtra['natisDocUrl']?.toString() ??
            data['natisDocUrl']?.toString() ??
            '';

        // Prepopulate controllers from root-level fields if present
        _makeOtherController.text =
            trailerExtra['make']?.toString() ?? data['make']?.toString() ?? '';
        _modelOtherController.text = trailerExtra['model']?.toString() ??
            data['model']?.toString() ??
            '';
        _yearOtherController.text =
            trailerExtra['year']?.toString() ?? data['year']?.toString() ?? '';
        _lengthOtherController.text = trailerExtra['length']?.toString() ??
            data['length']?.toString() ??
            '';
        _vinOtherController.text =
            trailerExtra['vin']?.toString() ?? data['vin']?.toString() ?? '';
        _registrationOtherController.text =
            trailerExtra['registration']?.toString() ??
                data['registration']?.toString() ??
                '';
        _licenceDiskExpOtherController.text =
            trailerExtra['licenseExp']?.toString() ??
                data['licenseExp']?.toString() ??
                '';
        _numbAxelOtherController.text = trailerExtra['numbAxel']?.toString() ??
            data['numbAxel']?.toString() ??
            '';
        _suspensionOther = trailerExtra['suspension']?.toString() ??
            data['suspension']?.toString() ??
            'steel';
        _absOther =
            trailerExtra['abs']?.toString() ?? data['abs']?.toString() ?? 'no';

        // Prepopulate image URLs from root-level fields if present
        // (these are used as 'existingUrl' in _buildImageSectionWithTitle)
        _frontOtherImage = null;
        _sideOtherImage = null;
        _tyresOtherImage = null;
        _chassisOtherImage = null;
        _deckOtherImage = null;
        _makersPlateOtherImage = null;
        _hookingPinOtherImage = null;
        _roofOtherImage = null;
        _tailBoardOtherImage = null;
        _spareWheelOtherImage = null;
        _landingLegsOtherImage = null;
        _hoseAndElecCableOtherImage = null;
        _licenseDiskOtherImage = null;

        // Store URLs for use in _buildImageSectionWithTitle
        _frontImageUrl = trailerExtra['frontImageUrl']?.toString() ??
            data['frontImageUrl']?.toString() ??
            '';
        _sideImageUrl = trailerExtra['sideImageUrl']?.toString() ??
            data['sideImageUrl']?.toString() ??
            '';
        _tyresImageUrl = trailerExtra['tyresImageUrl']?.toString() ??
            data['tyresImageUrl']?.toString() ??
            '';
        // Other tyre arrays
        if (trailerExtra['tyreImageUrls'] is List) {
          _tyreImageUrlsOther = List<String>.from(
              (trailerExtra['tyreImageUrls'] as List)
                  .map((e) => (e ?? '').toString()));
          while (_tyreImageUrlsOther.isNotEmpty &&
              _tyreImageUrlsOther.last.isEmpty) {
            _tyreImageUrlsOther.removeLast();
          }
        } else if (_tyreImageUrlsOther.isEmpty &&
            (_tyresImageUrl?.isNotEmpty ?? false)) {
          _tyreImageUrlsOther = [_tyresImageUrl!];
        }
        _chassisImageUrl = trailerExtra['chassisImageUrl']?.toString() ??
            data['chassisImageUrl']?.toString() ??
            '';
        _deckImageUrl = trailerExtra['deckImageUrl']?.toString() ??
            data['deckImageUrl']?.toString() ??
            '';
        _makersPlateImageUrl =
            trailerExtra['makersPlateImageUrl']?.toString() ??
                data['makersPlateImageUrl']?.toString() ??
                '';

        // Debugging: Print all relevant fields for 'Other' trailer type
        debugPrint('DEBUG: [Other] trailerExtra: $trailerExtra');
        debugPrint('DEBUG: [Other] natisDocUrl: $_existingNatisOtherDocUrl');
        debugPrint('DEBUG: [Other] frontImageUrl: $_frontImageUrl');
        debugPrint('DEBUG: [Other] sideImageUrl: $_sideImageUrl');
        debugPrint('DEBUG: [Other] tyresImageUrl: $_tyresImageUrl');
        debugPrint('DEBUG: [Other] chassisImageUrl: $_chassisImageUrl');
        debugPrint('DEBUG: [Other] deckImageUrl: $_deckImageUrl');
        debugPrint('DEBUG: [Other] makersPlateImageUrl: $_makersPlateImageUrl');
        debugPrint(
            'DEBUG: [Other] hookingPinImageUrl: ${trailerExtra['hookingPinImageUrl']?.toString() ?? data['trailerExtraInfo']?['hookingPinImageUrl']?.toString() ?? data['hookingPinImageUrl']?.toString() ?? 'NULL'}');
        debugPrint(
            'DEBUG: [Other] roofImageUrl: ${trailerExtra['roofImageUrl']?.toString() ?? data['trailerExtraInfo']?['roofImageUrl']?.toString() ?? data['roofImageUrl']?.toString() ?? 'NULL'}');
        debugPrint(
            'DEBUG: [Other] tailBoardImageUrl: ${trailerExtra['tailBoardImageUrl']?.toString() ?? data['trailerExtraInfo']?['tailBoardImageUrl']?.toString() ?? data['tailBoardImageUrl']?.toString() ?? 'NULL'}');
        debugPrint(
            'DEBUG: [Other] spareWheelImageUrl: ${trailerExtra['spareWheelImageUrl']?.toString() ?? data['trailerExtraInfo']?['spareWheelImageUrl']?.toString() ?? data['spareWheelImageUrl']?.toString() ?? 'NULL'}');
        debugPrint(
            'DEBUG: [Other] landingLegsImageUrl: ${trailerExtra['landingLegsImageUrl']?.toString() ?? data['trailerExtraInfo']?['landingLegsImageUrl']?.toString() ?? data['landingLegsImageUrl']?.toString() ?? 'NULL'}');
        debugPrint(
            'DEBUG: [Other] hoseAndElecCableImageUrl: ${trailerExtra['hoseAndElectricCableImageUrl']?.toString() ?? data['trailerExtraInfo']?['hoseAndElectricCableImageUrl']?.toString() ?? data['hoseAndElectricCableImageUrl']?.toString() ?? 'NULL'}');
        debugPrint(
            'DEBUG: [Other] licenseDiskImageUrl: ${trailerExtra['licenseDiskImageUrl']?.toString() ?? data['trailerExtraInfo']?['licenseDiskImageUrl']?.toString() ?? data['licenseDiskImageUrl']?.toString() ?? 'NULL'}');
        debugPrint(
            'DEBUG: [Other] additionalImages: ${trailerExtra['additionalImages']?.toString() ?? data['additionalImages']?.toString() ?? 'NULL'}');

        // Additional images for 'Other' trailer type
        _additionalImagesList.clear();
        if (trailerExtra['additionalImages'] != null &&
            (trailerExtra['additionalImages'] as List).isNotEmpty) {
          _additionalImagesList.addAll(
            List<Map<String, dynamic>>.from(trailerExtra['additionalImages']),
          );
        }
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
      _damagesCondition = (_damageList.isNotEmpty) ? 'yes' : 'no';
      debugPrint("DEBUG: Damages populated: ${_damageList.length} items");

      // Add this to populate transporter and sales rep
      if (data['userId'] != null) {
        _selectedTransporterId = data['userId'];
        debugPrint("Selected Transporter ID: $_selectedTransporterId");
      }

      if (data['assignedSalesRepId'] != null) {
        _selectedSalesRepId = data['assignedSalesRepId'];
        debugPrint("Selected Sales Rep ID: $_selectedSalesRepId");
      }
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
              if (Provider.of<UserProvider>(context, listen: false)
                      .getUserRole !=
                  'dealer')
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
              if (Provider.of<UserProvider>(context, listen: false)
                      .getUserRole !=
                  'dealer')
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
            _natisTrailerADoc1File = file;
            _natisTrailerADoc1FileName = fileName;
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

  Widget _buildNatisDoubleAxleDocSection() {
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
          child: Text('NATIS DOUBLE AXLE DOCUMENT'.toUpperCase(),
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w900),
              textAlign: TextAlign.center),
        ),
        const SizedBox(height: 15),
        InkWell(
          onTap: () {
            if (_existingNatisDoubleAxleDocUrl != null ||
                _natisDoubleAxleDocFile != null) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('NATIS Document'),
                  content:
                      const Text('What would you like to do with the file?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _viewTrailerBDocument();
                      },
                      child: const Text('View Document'),
                    ),
                    TextButton(
                      onPressed: () {
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
                      child: const Text('Replace Document'),
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
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF0E4CAF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: const Color(0xFF0E4CAF), width: 2.0),
            ),
            child: _natisDoubleAxleDocFile != null
                ? _buildFileDisplay(_natisDoubleAxleDocFileName, false)
                : (_existingNatisDoubleAxleDocUrl != null)
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
                            style:
                                TextStyle(fontSize: 14, color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

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
        final bool isDealer =
            Provider.of<UserProvider>(context, listen: false).getUserRole ==
                'dealer';
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
              if (!isDealer) ...[
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
        final bool isDealer =
            Provider.of<UserProvider>(context, listen: false).getUserRole ==
                'dealer';
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
              if (!isDealer) ...[
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
    if (Provider.of<UserProvider>(context, listen: false).getUserRole ==
        'dealer') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Dealers can only view existing NATIS/RC1 document.')));
      return;
    }
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
      if (_selectedTrailerType == 'Double Axle') ...[
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
        CustomTextField(
          controller: _lengthDoubleAxleController,
          hintText: 'Length Trailer',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 15),
        CustomTextField(
          controller: _vinDoubleAxleController,
          hintText: 'VIN',
          inputFormatter: [UpperCaseTextFormatter()],
        ),
        const SizedBox(height: 15),
        CustomTextField(
          controller: _registrationDoubleAxleController,
          hintText: 'Registration',
          inputFormatter: [UpperCaseTextFormatter()],
        ),
        const SizedBox(height: 15),
        CustomTextField(
          controller: _licenceDiskExpDoubleAxleController,
          hintText: 'Licence Disk Expiry Date',
          inputFormatter: [UpperCaseTextFormatter()],
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
                  _absDoubleAxle = value ?? 'no';
                });
              },
            ),
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
        // --- FIX: Use the correct controllers for Double Axle fields ---
        _buildNatisDoubleAxleDocSection(),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Front Image',
          _frontImageDoubleAxle,
          (img) => setState(() => _frontImageDoubleAxle = img),
          existingUrl: _frontImageUrl, // <-- FIXED
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Side Image',
          _sideImageDoubleAxle,
          (img) => setState(() => _sideImageDoubleAxle = img),
          existingUrl: _sideImageUrl, // <-- FIXED
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Chassis Image',
          _chassisImageDoubleAxle,
          (img) => setState(() => _chassisImageDoubleAxle = img),
          existingUrl: _chassisImageUrl, // <-- FIXED
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Hooking Pin Image',
          _hookingPinDoubleAxleImage,
          (img) => setState(() => _hookingPinDoubleAxleImage = img),
          existingUrl: _hookingPinDoubleAxleUrl,
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Deck Image',
          _deckImageDoubleAxle,
          (img) => setState(() => _deckImageDoubleAxle = img),
          existingUrl: _deckImageUrl,
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Roof Image (if applicable)',
          _roofDoubleAxleImage,
          (img) => setState(() => _roofDoubleAxleImage = img),
          existingUrl: _roofDoubleAxleUrl,
        ),
        const SizedBox(height: 15),
        _buildTyreImagesSection(
          'Tyres',
          _tyreImagesDoubleAxle,
          _tyreImageUrlsDoubleAxle,
          (index, img) {
            setState(() {
              if (index < _tyreImagesDoubleAxle.length) {
                _tyreImagesDoubleAxle[index] = img;
              } else {
                // pad to index
                while (_tyreImagesDoubleAxle.length < index) {
                  _tyreImagesDoubleAxle.add(null);
                }
                _tyreImagesDoubleAxle.add(img);
              }
              _tyresDoubleAxleImage = _tyreImagesDoubleAxle.isNotEmpty
                  ? _tyreImagesDoubleAxle.first
                  : null;
            });
          },
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Tail Board Image',
          _tailBoardDoubleAxleImage,
          (img) => setState(() => _tailBoardDoubleAxleImage = img),
          existingUrl: _tailBoardDoubleAxleUrl,
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Spare Wheel Image',
          _spareWheelDoubleAxleImage,
          (img) => setState(() => _spareWheelDoubleAxleImage = img),
          existingUrl: _spareWheelDoubleAxleUrl,
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Landing Legs Image',
          _landingLegsDoubleAxleImage,
          (img) => setState(() => _landingLegsDoubleAxleImage = img),
          existingUrl: _landingLegsDoubleAxleUrl,
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Hose and Electrical Cable Image',
          _hoseAndElecCableDoubleAxleImage,
          (img) => setState(() => _hoseAndElecCableDoubleAxleImage = img),
          existingUrl: _hoseAndElecCableDoubleAxleUrl,
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Brakes Axle 1 Image',
          _brakesAxle1DoubleAxleImage,
          (img) => setState(() => _brakesAxle1DoubleAxleImage = img),
          existingUrl: _brakesAxle1DoubleAxleUrl,
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Brakes Axle 2 Image',
          _brakesAxle2DoubleAxleImage,
          (img) => setState(() => _brakesAxle2DoubleAxleImage = img),
          existingUrl: _brakesAxle2DoubleAxleUrl,
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Axle 1 Image',
          _axle1DoubleAxleImage,
          (img) => setState(() => _axle1DoubleAxleImage = img),
          existingUrl: _axle1DoubleAxleUrl,
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Axle 2 Image',
          _axle2DoubleAxleImage,
          (img) => setState(() => _axle2DoubleAxleImage = img),
          existingUrl: _axle2DoubleAxleUrl,
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Licence Disk Image',
          _licenseDiskDoubleAxleImage,
          (img) => setState(() => _licenseDiskDoubleAxleImage = img),
          existingUrl: _licenseDiskDoubleAxleUrl,
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Makers Plate Image',
          _makersPlateDblAxleImage,
          (img) => setState(() => _makersPlateDblAxleImage = img),
          existingUrl: _makersPlateImageUrl,
        ),
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
                  ? (_) {}
                  : (val) {
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
              enabled: !isDealer,
              onChanged: isDealer
                  ? (_) {}
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
        if (_damagesCondition == 'yes' || (_damageList.isNotEmpty && isDealer))
          _buildDamageSection(),
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
              enabled: !isDealer,
              onChanged: isDealer
                  ? (_) {}
                  : (val) {
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
              enabled: !isDealer,
              onChanged: isDealer
                  ? (_) {}
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
      // --- ADD BACK SUPERLINK FIELDS ---
      else if (_selectedTrailerType == 'Superlink') ...[
        const SizedBox(height: 15),
        // Trailer A
        const Text('Trailer A',
            style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        // --- Add missing fields for Trailer A ---
        CustomTextField(
          controller: _makeController,
          hintText: 'Make Trailer A',
          enabled: !isDealer,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _modelTrailerAController,
          hintText: 'Model Trailer A',
          enabled: !isDealer,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _yearTrailerAController,
          hintText: 'Year Trailer A',
          keyboardType: TextInputType.number,
          enabled: !isDealer,
        ),
        const SizedBox(height: 10),
        // --- Suspension for Trailer A ---
        Center(
            child: Text('Suspension (Trailer A)',
                style: const TextStyle(fontSize: 14, color: Colors.white),
                textAlign: TextAlign.center)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomRadioButton(
              label: 'Steel',
              value: 'steel',
              groupValue: _suspensionTrailerA,
              enabled: !isDealer,
              onChanged: isDealer
                  ? (_) {}
                  : (val) {
                      setState(() {
                        _suspensionTrailerA = val ?? 'steel';
                      });
                    },
            ),
            const SizedBox(width: 15),
            CustomRadioButton(
              label: 'Air',
              value: 'air',
              groupValue: _suspensionTrailerA,
              enabled: !isDealer,
              onChanged: isDealer
                  ? (_) {}
                  : (val) {
                      setState(() {
                        _suspensionTrailerA = val ?? 'air';
                      });
                    },
            ),
          ],
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _lengthTrailerAController,
          hintText: 'Length Trailer A',
          keyboardType: TextInputType.number,
          enabled: !isDealer,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _vinAController,
          hintText: 'VIN Trailer A',
          inputFormatter: [UpperCaseTextFormatter()],
          enabled: !isDealer,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _registrationAController,
          hintText: 'Registration Trailer A',
          inputFormatter: [UpperCaseTextFormatter()],
          enabled: !isDealer,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _axlesTrailerAController,
          hintText: 'Axles Trailer A',
          keyboardType: TextInputType.number,
          enabled: !isDealer,
        ),
        const SizedBox(height: 10),
        // --- ABS for Trailer A ---
        Center(
            child: Text('ABS (Trailer A)',
                style: const TextStyle(fontSize: 14, color: Colors.white),
                textAlign: TextAlign.center)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomRadioButton(
              label: 'Yes',
              value: 'yes',
              groupValue: _absTrailerA,
              enabled: !isDealer,
              onChanged: isDealer
                  ? (_) {}
                  : (val) {
                      setState(() {
                        _absTrailerA = val ?? 'yes';
                      });
                    },
            ),
            const SizedBox(width: 15),
            CustomRadioButton(
              label: 'No',
              value: 'no',
              groupValue: _absTrailerA,
              enabled: !isDealer,
              onChanged: isDealer
                  ? (_) {}
                  : (val) {
                      setState(() {
                        _absTrailerA = val ?? 'no';
                      });
                    },
            ),
          ],
        ),
        const SizedBox(height: 10),
        // --- NATIS Document for Trailer A ---
        const Text(
          'NATIS Document for Trailer A',
          style: TextStyle(
              fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
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
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Front Image (Trailer A)',
          _frontImageA,
          (img) {
            if (!isDealer) {
              setState(() {
                _frontImageA = img;
              });
            }
          },
          existingUrl: _frontImageAUrl,
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Side Image (Trailer A)',
          _sideImageA,
          (img) {
            if (!isDealer) {
              setState(() {
                _sideImageA = img;
              });
            }
          },
          existingUrl: _sideImageAUrl,
        ),
        const SizedBox(height: 15),
        _buildTyreImagesSection(
          'Trailer A - Tyres',
          _tyreImagesA,
          _tyreImageUrlsA,
          (index, img) {
            if (!isDealer) {
              setState(() {
                if (index < _tyreImagesA.length) {
                  _tyreImagesA[index] = img;
                } else {
                  while (_tyreImagesA.length < index) {
                    _tyreImagesA.add(null);
                  }
                  _tyreImagesA.add(img);
                }
                _tyresImageA =
                    _tyreImagesA.isNotEmpty ? _tyreImagesA.first : null;
              });
            }
          },
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Chassis Image (Trailer A)',
          _chassisImageA,
          (img) {
            if (!isDealer) {
              setState(() {
                _chassisImageA = img;
              });
            }
          },
          existingUrl: _chassisImageAUrl,
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Deck Image (Trailer A)',
          _deckImageA,
          (img) {
            if (!isDealer) {
              setState(() {
                _deckImageA = img;
              });
            }
          },
          existingUrl: _deckImageAUrl,
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Makers Plate Image (Trailer A)',
          _makersPlateImageA,
          (img) {
            if (!isDealer) {
              setState(() {
                _makersPlateImageA = img;
              });
            }
          },
          existingUrl: _makersPlateImageAUrl,
        ),
        const SizedBox(height: 15),
        // Additional Superlink Trailer A images
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
        const SizedBox(height: 20),
        // Trailer B
        const Text('Trailer B',
            style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        // --- Add missing fields for Trailer B ---
        CustomTextField(
          controller: _makeTrailerBController,
          hintText: 'Make Trailer B',
          enabled: !isDealer,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _modelTrailerBController,
          hintText: 'Model Trailer B',
          enabled: !isDealer,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _yearTrailerBController,
          hintText: 'Year Trailer B',
          keyboardType: TextInputType.number,
          enabled: !isDealer,
        ),
        const SizedBox(height: 10),
        // --- Suspension for Trailer B ---
        Center(
            child: Text('Suspension (Trailer B)',
                style: const TextStyle(fontSize: 14, color: Colors.white),
                textAlign: TextAlign.center)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomRadioButton(
              label: 'Steel',
              value: 'steel',
              groupValue: _suspensionTrailerB,
              enabled: !isDealer,
              onChanged: isDealer
                  ? (_) {}
                  : (val) {
                      setState(() {
                        _suspensionTrailerB = val ?? 'steel';
                      });
                    },
            ),
            const SizedBox(width: 15),
            CustomRadioButton(
              label: 'Air',
              value: 'air',
              groupValue: _suspensionTrailerB,
              enabled: !isDealer,
              onChanged: isDealer
                  ? (_) {}
                  : (val) {
                      setState(() {
                        _suspensionTrailerB = val ?? 'air';
                      });
                    },
            ),
          ],
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _lengthTrailerBController,
          hintText: 'Length Trailer B',
          keyboardType: TextInputType.number,
          enabled: !isDealer,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _vinBController,
          hintText: 'VIN Trailer B',
          inputFormatter: [UpperCaseTextFormatter()],
          enabled: !isDealer,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _registrationBController,
          hintText: 'Registration Trailer B',
          inputFormatter: [UpperCaseTextFormatter()],
          enabled: !isDealer,
        ),
        const SizedBox(height: 10),
        CustomTextField(
          controller: _axlesTrailerBController,
          hintText: 'Axles Trailer B',
          keyboardType: TextInputType.number,
          enabled: !isDealer,
        ),

        const SizedBox(height: 10),
        // --- ABS for Trailer B ---
        Center(
            child: Text('ABS (Trailer B)',
                style: const TextStyle(fontSize: 14, color: Colors.white),
                textAlign: TextAlign.center)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomRadioButton(
              label: 'Yes',
              value: 'yes',
              groupValue: _absTrailerB,
              enabled: !isDealer,
              onChanged: isDealer
                  ? (_) {}
                  : (val) {
                      setState(() {
                        _absTrailerB = val ?? 'yes';
                      });
                    },
            ),
            const SizedBox(width: 15),
            CustomRadioButton(
              label: 'No',
              value: 'no',
              groupValue: _absTrailerB,
              enabled: !isDealer,
              onChanged: isDealer
                  ? (_) {}
                  : (val) {
                      setState(() {
                        _absTrailerB = val ?? 'no';
                      });
                    },
            ),
          ],
        ),
        const SizedBox(height: 10),
        // --- NATIS Document for Trailer B ---
        const Text(
          'NATIS Document for Trailer B',
          style: TextStyle(
              fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
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
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Front Image (Trailer B)',
          _frontImageB,
          (img) {
            if (!isDealer) {
              setState(() {
                _frontImageB = img;
              });
            }
          },
          existingUrl: _frontImageBUrl,
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Side Image (Trailer B)',
          _sideImageB,
          (img) {
            if (!isDealer) {
              setState(() {
                _sideImageB = img;
              });
            }
          },
          existingUrl: _sideImageBUrl,
        ),
        const SizedBox(height: 15),
        _buildTyreImagesSection(
          'Trailer B - Tyres',
          _tyreImagesB,
          _tyreImageUrlsB,
          (index, img) {
            if (!isDealer) {
              setState(() {
                if (index < _tyreImagesB.length) {
                  _tyreImagesB[index] = img;
                } else {
                  while (_tyreImagesB.length < index) {
                    _tyreImagesB.add(null);
                  }
                  _tyreImagesB.add(img);
                }
                _tyresImageB =
                    _tyreImagesB.isNotEmpty ? _tyreImagesB.first : null;
              });
            }
          },
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Chassis Image (Trailer B)',
          _chassisImageB,
          (img) {
            if (!isDealer) {
              setState(() {
                _chassisImageB = img;
              });
            }
          },
          existingUrl: _chassisImageBUrl,
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Deck Image (Trailer B)',
          _deckImageB,
          (img) {
            if (!isDealer) {
              setState(() {
                _deckImageB = img;
              });
            }
          },
          existingUrl: _deckImageBUrl,
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Makers Plate Image (Trailer B)',
          _makersPlateImageB,
          (img) {
            if (!isDealer) {
              setState(() {
                _makersPlateImageB = img;
              });
            }
          },
          existingUrl: _makersPlateImageBUrl,
        ),
        const SizedBox(height: 15),
        // Additional Superlink Trailer B images
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
        const SizedBox(height: 20),
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
                  ? (_) {}
                  : (val) {
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
              enabled: !isDealer,
              onChanged: isDealer
                  ? (_) {}
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
        if (_damagesCondition == 'yes' || (_damageList.isNotEmpty && isDealer))
          _buildDamageSection(),
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
              enabled: !isDealer,
              onChanged: isDealer
                  ? (_) {}
                  : (val) {
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
              enabled: !isDealer,
              onChanged: isDealer
                  ? (_) {}
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
      // --- ADD BACK TRI-AXLE FIELDS ---
      else if (_selectedTrailerType == 'Tri-Axle') ...[
        const SizedBox(height: 15),
        CustomTextField(
          controller: _makeController,
          hintText: 'Make',
          enabled: !isDealer,
        ),
        const SizedBox(height: 15),
        CustomTextField(
          controller: _modelController,
          hintText: 'Model',
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
          controller: _axlesController,
          hintText: 'Number of Axles',
          keyboardType: TextInputType.number,
          enabled: !isDealer,
        ),
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
        ),
        const SizedBox(height: 15),
        CustomTextField(
          controller: _registrationController,
          hintText: 'Registration',
          inputFormatter: [UpperCaseTextFormatter()],
        ),
        const SizedBox(height: 15),
        // NATIS Document for Tri-Axle
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
                              final uri =
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
            }
          },
          child: _buildStyledContainer(
            child: _natisTriAxleDocFile != null
                ? _buildFileDisplay(_natisTriAxleDocFileName, false)
                : (_existingNatisTriAxleDocUrl != null)
                    ? _buildFileDisplay(
                        _getFileNameFromUrl(_existingNatisTriAxleDocUrl), true)
                    : const Column(
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
                      ),
          ),
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Front Trailer Image',
          _frontImage,
          (img) {
            if (!isDealer) setState(() => _frontImage = img);
          },
          existingUrl: _frontImageUrl,
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Side Image',
          _sideImage,
          (img) {
            if (!isDealer) setState(() => _sideImage = img);
          },
          existingUrl: _sideImageUrl,
        ),
        const SizedBox(height: 15),
        _buildTyreImagesSection(
          'Tyres',
          _tyreImages,
          _tyreImageUrls,
          (index, img) {
            if (!isDealer) {
              setState(() {
                if (index < _tyreImages.length) {
                  _tyreImages[index] = img;
                } else {
                  while (_tyreImages.length < index) {
                    _tyreImages.add(null);
                  }
                  _tyreImages.add(img);
                }
                _tyresImage = _tyreImages.isNotEmpty ? _tyreImages.first : null;
              });
            }
          },
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Chassis Image',
          _chassisImage,
          (img) {
            if (!isDealer) setState(() => _chassisImage = img);
          },
          existingUrl: _chassisImageUrl,
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Deck Image',
          _deckImage,
          (img) {
            if (!isDealer) setState(() => _deckImage = img);
          },
          existingUrl: _deckImageUrl,
        ),
        const SizedBox(height: 15),
        _buildImageSectionWithTitle(
          'Makers Plate Image',
          _makersPlateImage,
          (img) {
            if (!isDealer) setState(() => _makersPlateImage = img);
          },
          existingUrl: _makersPlateImageUrl,
        ),
        const SizedBox(height: 15),
        // Additional Superlink Trailer images
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
                  ? (_) {}
                  : (val) {
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
              enabled: !isDealer,
              onChanged: isDealer
                  ? (_) {}
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
        if (_damagesCondition == 'yes' || (_damageList.isNotEmpty && isDealer))
          _buildDamageSection(),
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
              enabled: !isDealer,
              onChanged: isDealer
                  ? (_) {}
                  : (val) {
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
              enabled: !isDealer,
              onChanged: isDealer
                  ? (_) {}
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
      // --- ADD 'OTHER' TYRES SECTION (dynamic, position-labeled) ---
      else if (_selectedTrailerType == 'Other') ...[
        const SizedBox(height: 15),
        _buildTyreImagesSection(
          'Tyres',
          _tyreImagesOther,
          _tyreImageUrlsOther,
          (index, img) {
            if (!isDealer) {
              setState(() {
                if (index < _tyreImagesOther.length) {
                  _tyreImagesOther[index] = img;
                } else {
                  // pad to index
                  while (_tyreImagesOther.length < index) {
                    _tyreImagesOther.add(null);
                  }
                  _tyreImagesOther.add(img);
                }
                // Keep legacy single field synced to first element
                _tyresOtherImage =
                    _tyreImagesOther.isNotEmpty ? _tyreImagesOther.first : null;
              });
            }
          },
        ),
        const SizedBox(height: 15),
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

  // Dynamic Tyres section with position labels and add/remove controls (Edit)
  Widget _buildTyreImagesSection(
    String title,
    List<Uint8List?> tyreImages,
    List<String> existingUrls,
    void Function(int index, Uint8List? image) onChanged,
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
        // Always show at least one position (Position 1) for consistency
        for (int i = 0;
            i <
                ((tyreImages.isEmpty && existingUrls.isEmpty)
                    ? 1
                    : (tyreImages.length > existingUrls.length
                        ? tyreImages.length
                        : existingUrls.length));
            i++) ...[
          Text('Position ${i + 1}',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              final bool isDealer =
                  Provider.of<UserProvider>(context, listen: false)
                          .getUserRole ==
                      'dealer';
              if (isDealer) return;
              if (i < tyreImages.length && tyreImages[i] != null) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Tyre Image'),
                    content: const Text(
                        'What would you like to do with this image?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _pickImageOrFile(
                            title: 'Change Tyre Image',
                            pickImageOnly: true,
                            callback: (file, fileName) {
                              if (file != null) onChanged(i, file);
                            },
                          );
                        },
                        child: const Text('Change Image'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onChanged(i, null);
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
                  title: 'Tyre Image (Position ${i + 1})',
                  pickImageOnly: true,
                  callback: (file, fileName) {
                    if (file != null) onChanged(i, file);
                  },
                );
              }
            },
            borderRadius: BorderRadius.circular(10.0),
            child: _buildStyledContainer(
              child: (i < tyreImages.length && tyreImages[i] != null)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.memory(tyreImages[i]!,
                          fit: BoxFit.cover,
                          height: 150,
                          width: double.infinity),
                    )
                  : (i < existingUrls.length && existingUrls[i].isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(existingUrls[i],
                              fit: BoxFit.cover,
                              height: 150,
                              width: double.infinity),
                        )
                      : const Column(
                          children: [
                            Icon(Icons.camera_alt,
                                color: Colors.white, size: 50.0),
                            SizedBox(height: 10),
                            Text('Tap to upload tyre image',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white70),
                                textAlign: TextAlign.center),
                          ],
                        ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  if (i < tyreImages.length) {
                    tyreImages.removeAt(i);
                  }
                  if (i < existingUrls.length) {
                    existingUrls.removeAt(i);
                  }
                });
              },
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              label: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: () {
              final bool isDealer =
                  Provider.of<UserProvider>(context, listen: false)
                          .getUserRole ==
                      'dealer';
              if (isDealer) return;
              setState(() {
                tyreImages.add(null);
              });
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, color: Colors.blue, size: 30.0),
                SizedBox(width: 8.0),
                Text('Add another tyre',
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

    final List<String> transporterEmails =
        _transporterUsers.map((e) => e['email'] as String).toList();

    // --- DEBUGGING ---
    debugPrint(
        '[DEBUG][Transporter] _selectedTransporterId: $_selectedTransporterId');
    debugPrint(
        '[DEBUG][Transporter] currentTransporterEmail: $currentTransporterEmail');
    debugPrint('[DEBUG][Transporter] transporterEmails: $transporterEmails');
    debugPrint('[DEBUG][Transporter] _transporterUsers: $_transporterUsers');
    // -----------------

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

    final List<String> salesRepEmails =
        _salesRepUsers.map((e) => e['email'] as String).toList();

    // --- DEBUGGING ---
    debugPrint('[DEBUG][SalesRep] _selectedSalesRepId: $_selectedSalesRepId');
    debugPrint('[DEBUG][SalesRep] currentSalesRepEmail: $currentSalesRepEmail');
    debugPrint('[DEBUG][SalesRep] salesRepEmails: $salesRepEmails');
    debugPrint('[DEBUG][SalesRep] _salesRepUsers: $_salesRepUsers');
    // -----------------

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
      if (_selectedTrailerType == 'Superlink') {
        // Compute tyre lists once (avoid double uploads) and mirror legacy first URL
        final List<String> _finalTyreUrlsA = await _uploadTyreImagesFromEdit(
          _tyreImagesA,
          _tyreImageUrlsA.isNotEmpty
              ? _tyreImageUrlsA
              : (_tyresImageAUrl?.isNotEmpty ?? false)
                  ? [_tyresImageAUrl!]
                  : [],
        );
        final List<String> _finalTyreUrlsB = await _uploadTyreImagesFromEdit(
          _tyreImagesB,
          _tyreImageUrlsB.isNotEmpty
              ? _tyreImageUrlsB
              : (_tyresImageBUrl?.isNotEmpty ?? false)
                  ? [_tyresImageBUrl!]
                  : [],
        );
        trailerExtraInfo = {
          'trailerA': {
            'make': _makeController.text,
            'model': _modelTrailerAController.text,
            'year': _yearTrailerAController.text,
            'length': _lengthTrailerAController.text,
            'vin': _vinAController.text,
            'registration': _registrationAController.text,
            'axles': _axlesTrailerAController.text,
            'suspension': _suspensionTrailerA,
            'licenseExp': _licenceDiskExpTrailerAController.text,
            'abs': _absTrailerA,
            'natisDoc1Url': _natisTrailerADoc1File != null
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
            // Tyres (Trailer A)
            'tyreImageUrls': _finalTyreUrlsA,
            'tyresImageUrl':
                _finalTyreUrlsA.isNotEmpty ? _finalTyreUrlsA.first : '',
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
            'suspension': _suspensionTrailerB,
            'licenseExp': _licenceDiskExpTrailerBController.text,
            'abs': _absTrailerB,
            'natisDoc1Url': _natisTrailerBDoc1File != null
                ? await _uploadFileToFirebaseStorage(_natisTrailerBDoc1File!,
                    'vehicle_documents', _natisTrailerBDoc1FileName)
                : _existingNatisTrailerBDoc1Url ?? '',
            'frontImageUrl': _frontImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _frontImageB!, 'vehicle_images')
                : _frontImageBUrl ?? '',
            'sideImageUrl': _sideImageB != null
                ? await _uploadFileToFirebaseStorage(
                    _sideImageB!, 'vehicle_images')
                : _sideImageBUrl ?? '',
            'tyreImageUrls': _finalTyreUrlsB,
            'tyresImageUrl':
                _finalTyreUrlsB.isNotEmpty ? _finalTyreUrlsB.first : '',
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
      } else if (_selectedTrailerType == 'Other') {
        // Persist existing Trailer A/B structure (if used) and also update flat tyres fields for 'Other'
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
            'tyreImageUrls': await _uploadTyreImagesFromEdit(
              _tyreImagesA,
              _tyreImageUrlsA.isNotEmpty
                  ? _tyreImageUrlsA
                  : (_tyresImageAUrl?.isNotEmpty ?? false)
                      ? [_tyresImageAUrl!]
                      : [],
            ),
            'tyresImageUrl': (() {
              final list = _tyreImageUrlsA.isNotEmpty
                  ? _tyreImageUrlsA
                  : (_tyresImageAUrl?.isNotEmpty ?? false)
                      ? [_tyresImageAUrl!]
                      : [];
              return list.isNotEmpty ? list.first : '';
            })(),
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
            'trailerAAdditionalImages':
                await _uploadListItems(_additionalImagesListTrailerA),
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
            'tyreImageUrls': await _uploadTyreImagesFromEdit(
              _tyreImagesB,
              _tyreImageUrlsB.isNotEmpty
                  ? _tyreImageUrlsB
                  : (_tyresImageBUrl?.isNotEmpty ?? false)
                      ? [_tyresImageBUrl!]
                      : [],
            ),
            'tyresImageUrl': (() {
              final list = _tyreImageUrlsB.isNotEmpty
                  ? _tyreImageUrlsB
                  : (_tyresImageBUrl?.isNotEmpty ?? false)
                      ? [_tyresImageBUrl!]
                      : [];
              return list.isNotEmpty ? list.first : '';
            })(),
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
            'trailerBAdditionalImages':
                await _uploadListItems(_additionalImagesListTrailerB),
          },
        };
        // Also store flat tyres array for 'Other' type to match prepopulation logic
        final List<String> _finalTyreUrlsOther =
            await _uploadTyreImagesFromEdit(
          _tyreImagesOther,
          _tyreImageUrlsOther.isNotEmpty
              ? _tyreImageUrlsOther
              : (_tyresImageUrl?.isNotEmpty ?? false)
                  ? [_tyresImageUrl!]
                  : [],
        );
        trailerExtraInfo['tyreImageUrls'] = _finalTyreUrlsOther;
        trailerExtraInfo['tyresImageUrl'] =
            _finalTyreUrlsOther.isNotEmpty ? _finalTyreUrlsOther.first : '';
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

  // Merge existing tyre URLs with newly selected images and upload as needed.
  Future<List<String>> _uploadTyreImagesFromEdit(
      List<Uint8List?> newImages, List<String> existingUrls) async {
    final int maxLen = (newImages.length > existingUrls.length)
        ? newImages.length
        : existingUrls.length;
    final List<String> result = [];
    for (int i = 0; i < maxLen; i++) {
      final Uint8List? img = i < newImages.length ? newImages[i] : null;
      final String prev = i < existingUrls.length ? existingUrls[i] : '';
      if (img != null) {
        final url = await _uploadFileToFirebaseStorage(img, 'vehicle_images');
        result.add(url ?? '');
      } else {
        result.add(prev);
      }
    }
    // Trim trailing empties
    while (result.isNotEmpty && result.last.isEmpty) {
      result.removeLast();
    }
    return result;
  }

  // --- Custom image/file picker dialog ---
  void _pickImageOrFile({
    required String title,
    required bool pickImageOnly,
    required void Function(Uint8List?, String? fileName) callback,
  }) async {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(title),
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
                    callback(imageBytes, 'captured.png');
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
                    type: pickImageOnly ? FileType.image : FileType.custom,
                    allowedExtensions: pickImageOnly
                        ? ['jpg', 'jpeg', 'png']
                        : [
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
                  if (result != null && result.files.isNotEmpty) {
                    final fileName = result.files.first.name;
                    final bytes = result.files.first.bytes;
                    callback(bytes, fileName);
                  }
                },
              ),
              if (!pickImageOnly)
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
  }

  // --- Service History file picker ---
  void _pickServiceHistoryFile() async {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Select Service History File'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('Pick from Device'),
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
                  if (result != null && result.files.isNotEmpty) {
                    setState(() {
                      _serviceHistoryFile = result.files.first.bytes;
                      _serviceHistoryFileName = result.files.first.name;
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

  // Fix the 'Uri' variable bug in Tri-Axle NATIS document section
  // Replace:
  // final Uri = Uri.parse(_existingNatisTriAxleDocUrl!);
  // if (await canLaunchUrl(Uri)) {
  //   await launchUrl(Uri, ...);
  // }
  // With:
  // final uri = Uri.parse(_existingNatisTriAxleDocUrl!);
  // if (await canLaunchUrl(uri)) {
  //   await launchUrl(uri, ...);
  // }
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

    return WillPopScope(
      onWillPop: () async => true,
      child: GradientBackground(
        child: Stack(
          children: [
            Scaffold(
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
              body: SafeArea(
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
    );
  }

  void _viewDocument() {
    // TODO: Implement document viewing logic
  }

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
            } else {
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
              if (hasImage)
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      onImagePicked(null);
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

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
}
