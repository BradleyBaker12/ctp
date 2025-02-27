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
import 'dart:convert';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/pages/truckForms/custom_dropdown.dart';
import 'package:universal_html/html.dart' as html;
import '../truckForms/custom_text_field.dart';
import 'package:ctp/components/custom_radio_button.dart';
// import 'dart:ui_web';
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

  // Common Controllers
  final TextEditingController _sellingPriceController = TextEditingController();
  final TextEditingController _vinNumberController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _engineNumberController = TextEditingController();
  final TextEditingController _warrantyDetailsController =
      TextEditingController();
  final TextEditingController _registrationNumberController =
      TextEditingController(); // used for Expected Selling Price
  final TextEditingController _referenceNumberController =
      TextEditingController();
  final TextEditingController _makeController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _axlesController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();

  // New: Trailer Type Dropdown (values: Superlink, Tri-Axle, Double Axle, Other)
  String? _selectedTrailerType;

  // Extra controllers for Superlink
  // Trailer A:
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
  // Trailer B:
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

  // Extra controllers for Tri-Axle
  final TextEditingController _lengthTrailerController =
      TextEditingController();
  final TextEditingController _vinController = TextEditingController();
  final TextEditingController _registrationController = TextEditingController();
  // For Tri-Axle the generic image variables (_frontImage, etc.) are reused.

  // Generic image variables
  Uint8List? _selectedMainImage;
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

  // Sales Rep field for Admin Upload
  String? _selectedSalesRep;
  String? _existingNatisRc1Name;
  String? _selectedMainImageFileName;

  // Form validations
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(1, (index) => GlobalKey<FormState>());

  // For loading JSON data
  List<String> _yearOptions = [];
  final List<String> _brandOptions = [];
  List<String> _countryOptions = [];
  List<String> _provinceOptions = [];

  @override
  void initState() {
    super.initState();
    _loadCountryOptions();
    _updateProvinceOptions('South Africa');
    _loadYearOptions();

    final formData = Provider.of<FormDataProvider>(context, listen: false);
    // Obtain trailer form provider instance:
    final trailerForm =
        Provider.of<TrailerFormProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isNewUpload) {
        _clearAllData(formData);
        trailerForm.clearAll();
      } else if (widget.vehicle != null) {
        if (widget.isDuplicating) {
          _populateDuplicatedData(formData);
          trailerForm.clearAll();
        } else {
          _vehicleId = widget.vehicle!.id;
          _fetchAndPopulateVehicleData();
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

    // Dispose extra controllers for Superlink and Tri-Axle:
    _lengthTrailerAController.dispose();
    _vinAController.dispose();
    _registrationAController.dispose();
    _lengthTrailerBController.dispose();
    _vinBController.dispose();
    _registrationBController.dispose();
    _lengthTrailerController.dispose();
    _vinController.dispose();
    _registrationController.dispose();

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
            child: Stack(children: [
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
                          maxWidth: isWebView ? 800 : double.infinity,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWebView ? 40.0 : 16.0,
                            vertical: 8.0,
                          ),
                          child: Column(
                            children: [
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth: isWebView ? 600 : double.infinity,
                                ),
                                child: _buildMainImageSection(formData),
                              ),
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
        ])));
  }

  // ---------------------------------------------------------------------------
  // Web Photo Capture
  // ---------------------------------------------------------------------------
  Future<void> _takePhotoFromWeb(
      void Function(Uint8List?, String) callback) async {
    if (!kIsWeb) {
      callback(null, '');
      return;
    }

    try {
      // final mediaDevices = html.window.navigator.mediaDevices;
      // if (mediaDevices == null) {
      //   callback(null, '');
      //   return;
      // }

      // final mediaStream = await mediaDevices.getUserMedia({'video': true});

      // final videoElement = html.VideoElement()
      //   ..autoplay = true
      //   ..srcObject = mediaStream;

      // await videoElement.onLoadedMetadata.first;

      // platformViewRegistry.registerViewFactory(
      //   'webcamVideo',
      //   (int viewId) => videoElement,
      // );

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Take Photo'),
            content: SizedBox(
              width: 300,
              height: 300,
              child: isWebPlatform
                  ? HtmlElementView(viewType: 'webcamVideo')
                  : const Center(child: Text('Camera not available')),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // final canvas = html.CanvasElement(
                  //   width: videoElement.videoWidth,
                  //   height: videoElement.videoHeight,
                  // );
                  // canvas.context2D.drawImage(videoElement, 0, 0);
                  // final dataUrl = canvas.toDataUrl('image/png');
                  // final base64Str = dataUrl.split(',').last;
                  // final imageBytes = base64.decode(base64Str);
                  // mediaStream.getTracks().forEach((track) => track.stop());
                  // Navigator.of(dialogContext).pop();
                  // callback(imageBytes, 'captured.png');
                },
                child: const Text('Capture'),
              ),
              TextButton(
                onPressed: () {
                  // mediaStream.getTracks().forEach((track) => track.stop());
                  // Navigator.of(dialogContext).pop();
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error in web photo capture: $e');
      callback(null, '');
    }
  }

  // ---------------------------------------------------------------------------
  // Helper: Pick Image or File
  // ---------------------------------------------------------------------------
  void _pickImageOrFile({
    required String title,
    required bool pickImageOnly,
    required void Function(Uint8List?, String fileName) callback,
  }) async {
    if (pickImageOnly) {
      try {
        if (kIsWeb) {
          bool cameraAvailable = false;
          try {
            // cameraAvailable = html.window.navigator.mediaDevices != null;
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
                          await _takePhotoFromWeb(callback);
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
        debugPrint('Error picking image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
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
  }

  // ---------------------------------------------------------------------------
  // MAIN IMAGE SECTION
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // FORM SECTION
  // ---------------------------------------------------------------------------
  Widget _buildFormSection(FormDataProvider formData) {
    final screenWidth = MediaQuery.of(context).size.width;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomTextField(
              controller: _referenceNumberController,
              hintText: 'Reference Number',
              inputFormatter: [UpperCaseTextFormatter()],
            ),
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

            // Show message for Double Axle or Other
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
                    Icon(
                      Icons.construction,
                      size: 50,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      '$_selectedTrailerType Form Coming Soon',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'This form is currently under development.\nPlease check back later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_selectedTrailerType != null) ...[
              // Rest of the form for Superlink and Tri-Axle
              // Essential fields moved here - Always visible
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

              // NATIS Documentation section
              const Text(
                'NATIS/RC1 DOCUMENTATION',
                style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w900),
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
                        content: const Text(
                            'What would you like to do with the file?'),
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
                            Icon(Icons.drive_folder_upload_outlined,
                                color: Colors.white, size: 50.0),
                            SizedBox(height: 10),
                            Text(
                              'Upload NATIS/RC1',
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
                              _natisRc1FileName!.split('/').last,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 15),

              // Conditional fields based on trailer type
              if (_selectedTrailerType != null &&
                  _selectedTrailerType != 'Double Axle' &&
                  _selectedTrailerType != 'Other') ...[
                if (_selectedTrailerType == 'Superlink') ...[
                  const SizedBox(height: 15),
                  // Add axles field here
                  CustomTextField(
                    controller: _axlesController,
                    hintText: 'Number of Axles',
                    keyboardType: TextInputType.number,
                  ),
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
                  _buildAdditionalImagesSectionForTrailerB(),
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
                  _buildAdditionalImagesSection(), // Generic additional images
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
                // Damages
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
                // Additional Features
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
                if (_featuresCondition == 'yes') _buildFeaturesSection(),
                const SizedBox(height: 30),
                _buildDoneButton(),
                const SizedBox(height: 30),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // IMAGE SECTIONS & Additional Items Helpers
  // ---------------------------------------------------------------------------
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
          _buildItemWidget(
            i,
            _additionalImagesList[i],
            _additionalImagesList,
            (item) => _showAdditionalImageSourceDialog(item),
          ),
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

  // Additional Images Section for Trailer A (Superlink)
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
            (item) => _showAdditionalImageSourceDialogForTrailerA(item),
          ),
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

  // Additional Images Section for Trailer B (Superlink)
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
            (item) => _showAdditionalImageSourceDialogForTrailerB(item),
          ),
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

  // ---------------------------------------------------------------------------
  // Dynamic Item Widget (for Additional Images, Damages, Features)
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // DAMAGE & FEATURE Sections
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // DONE BUTTON
  // ---------------------------------------------------------------------------
  Widget _buildDoneButton() {
    return Center(
      child: CustomButton(
        text: 'Done',
        borderColor: AppColors.orange,
        onPressed: _saveDataAndFinish,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SAVE METHOD (Uploads All Images and Saves Firestore Data)
  // ---------------------------------------------------------------------------
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
      final currentUser = FirebaseAuth.instance.currentUser;

      // Get assigned sales rep ID
      String? assignedSalesRepId;
      if (widget.isAdminUpload) {
        assignedSalesRepId = _selectedSalesRep;
      } else {
        assignedSalesRepId = currentUser?.uid;
      }

      // Commit common text fields.
      formData.setReferenceNumber(_referenceNumberController.text);
      formData.setMake(_makeController.text);
      formData.setYear(_yearController.text);
      formData.setRegistrationNumber(_registrationNumberController.text);
      formData.setTrailerType(_selectedTrailerType ?? '');
      formData.setVehicleType('trailer');
      formData.setVinNumber(_vinNumberController.text);
      formData.setSellingPrice(
          _registrationNumberController.text); // This is the selling price
      // Only set axles and length for non-Tri-Axle trailers
      if (_selectedTrailerType != 'Tri-Axle') {
        formData.setAxles(_axlesController.text);
        formData.setLength(_lengthController.text);
      }
      if (_selectedMainImage != null) {
        formData.setSelectedMainImage(_selectedMainImage, "MainImage");
      }
      // Validate required fields.
      if (!_validateRequiredFields(formData)) {
        setState(() => _isLoading = false);
        return;
      }
      // Upload images.
      Map<String, String?> commonUrls = await _uploadCommonFiles();

      // Upload type-specific images and build trailer data
      Map<String, dynamic> trailerTypeData = await _buildTrailerTypeData();

      // Build Firestore data.
      final Map<String, dynamic> trailerData = {
        'makeModel': formData.make,
        'year': formData.year,
        'sellingPrice': formData.sellingPrice,
        'trailerType': formData.trailerType,
        'vehicleType': 'trailer',
        ..._selectedTrailerType != 'Tri-Axle'
            ? {
                'axles': formData.axles,
                'length': formData.length,
              }
            : {},
        'mainImageUrl': commonUrls['mainImageUrl'] ?? '',
        'natisDocumentUrl': commonUrls['natisUrl'] ?? '',
        'serviceHistoryUrl': commonUrls['serviceHistoryUrl'] ?? '',
        'trailerExtraInfo': trailerTypeData,
        'damagesCondition': _damagesCondition,
        'damages': await _uploadListItems(_damageList),
        'featuresCondition': _featuresCondition,
        'features': await _uploadListItems(_featureList),

        // Add required system fields
        'userId': currentUser?.uid,
        'assignedSalesRepId': assignedSalesRepId,
        'vehicleStatus': 'Draft',
        'listingStatus': 'Active',
        'isApproved': false,
        'isFeatured': false,
        'isSold': false,
        'isArchived': false,
        'viewCount': 0,
        'savedCount': 0,
        'inquiryCount': 0,

        // Timestamps and metadata
        'country': formData.country,
        'province': formData.province,
        'referenceNumber': formData.referenceNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastModifiedBy': currentUser?.uid,

        // Admin data
        'adminData': {
          'settlementAmount': formData.sellingPrice,
          'requireSettlement': false,
          'isSettled': false,
          'settlementDate': null,
          'settlementBy': null,
        },
      };

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

  Future<Map<String, dynamic>> _buildTrailerTypeData() async {
    switch (_selectedTrailerType) {
      case 'Tri-Axle':
        return {
          'lengthTrailer': _lengthTrailerController.text,
          'vin': _vinController.text,
          'registration': _registrationController.text,
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

      case 'Superlink':
        return {
          'trailerA': {
            'length': _lengthTrailerAController.text,
            'vin': _vinAController.text,
            'registration': _registrationAController.text,
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
            'additionalImages':
                await _uploadListItems(_additionalImagesListTrailerB),
          },
        };

      default:
        return {};
    }
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
    // Basic validations
    if (formData.selectedMainImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a main image')),
      );
      return false;
    }
    if (_natisRc1File == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload the NATIS/RC1 document')),
      );
      return false;
    }

    // Required fields for all trailer types
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
    if (formData.referenceNumber == null || formData.referenceNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the reference number')),
      );
      return false;
    }
    if (_registrationNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the selling price')),
      );
      return false;
    }
    // Only check axles and length if not Tri-Axle and not Superlink
    if (_selectedTrailerType != 'Tri-Axle' &&
        _selectedTrailerType != 'Superlink') {
      if (_axlesController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the number of axles')),
        );
        return false;
      }
      if (_lengthController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the length')),
        );
        return false;
      }
    }

    // Trailer type specific validations
    switch (_selectedTrailerType) {
      case 'Tri-Axle':
        if (_lengthTrailerController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter the trailer length')),
          );
          return false;
        }
        if (_vinController.text.isEmpty ||
            _registrationController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please complete VIN and registration fields')),
          );
          return false;
        }
        break;

      case 'Superlink':
        // Add axles validation for Superlink
        if (_axlesController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter the number of axles')),
          );
          return false;
        }
        if (_lengthTrailerAController.text.isEmpty ||
            _vinAController.text.isEmpty ||
            _registrationAController.text.isEmpty ||
            _lengthTrailerBController.text.isEmpty ||
            _vinBController.text.isEmpty ||
            _registrationBController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please complete all Superlink fields')),
          );
          return false;
        }
        break;
    }

    return true;
  }

  /// Upload a file to Firebase Storage.
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
    // Clear form data provider
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
    formData.setTrailerType(null);
    formData.setAxles(null);
    formData.setLength(null);

    // Clear all common controllers
    _clearFormControllers();

    // Clear type specific controllers
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

    // Clear all image data and documents
    setState(() {
      // Clear main images
      _selectedMainImage = null;
      _selectedMainImageFileName = null;

      // Clear documents
      _natisRc1File = null;
      _natisRc1FileName = null;
      _existingNatisRc1Url = null;
      _existingNatisRc1Name = null;
      _serviceHistoryFile = null;
      _serviceHistoryFileName = null;

      // Clear Superlink images - Trailer A
      _frontImageA = null;
      _sideImageA = null;
      _tyresImageA = null;
      _chassisImageA = null;
      _deckImageA = null;
      _makersPlateImageA = null;
      _additionalImagesListTrailerA.clear();

      // Clear Superlink images - Trailer B
      _frontImageB = null;
      _sideImageB = null;
      _tyresImageB = null;
      _chassisImageB = null;
      _deckImageB = null;
      _makersPlateImageB = null;
      _additionalImagesListTrailerB.clear();

      // Clear Tri-Axle images
      _frontImage = null;
      _sideImage = null;
      _tyresImage = null;
      _chassisImage = null;
      _deckImage = null;
      _makersPlateImage = null;
      _additionalImagesList.clear();

      // Clear damages and features
      _damagesCondition = 'no';
      _featuresCondition = 'no';
      _damageList.clear();
      _featureList.clear();

      // Clear trailer type selection
      _selectedTrailerType = null;

      // Clear admin fields
      _selectedSalesRep = null;

      // Clear system fields
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

  // Add these helper methods at class level
  bool get isWebPlatform => kIsWeb;

  dynamic getWebWindow() {
    if (isWebPlatform) {
      try {
        // return html.window;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // New: Fetch and prepopulate vehicle data from Firestore using vehicleId.
  Future<void> _fetchAndPopulateVehicleData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(_vehicleId)
          .get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final trailerForm =
            Provider.of<TrailerFormProvider>(context, listen: false);
        setState(() {
          // Prepopulate common fields:
          _makeController.text = data['makeModel'] ?? '';
          _yearController.text = data['year'] ?? '';
          _registrationNumberController.text = data['sellingPrice'] ?? '';
          _referenceNumberController.text = data['referenceNumber'] ?? '';
          _vinNumberController.text = data['vinNumber'] ?? '';
          _selectedTrailerType = data['trailerType'];
          // Update trailerForm based on trailer type:
          if (_selectedTrailerType == 'Tri-Axle') {
            Map<String, dynamic> extra = data['trailerExtraInfo'] ?? {};
            _lengthTrailerController.text = extra['lengthTrailer'] ?? '';
            _vinController.text = extra['vin'] ?? '';
            _registrationController.text = extra['registration'] ?? '';

            trailerForm.setTriAxleLength(extra['lengthTrailer'] ?? '');
            trailerForm.setTriAxleVin(extra['vin'] ?? '');
            trailerForm.setTriAxleRegistration(extra['registration'] ?? '');
          } else if (_selectedTrailerType == 'Superlink') {
            Map<String, dynamic> extra = data['trailerExtraInfo'] ?? {};
            Map<String, dynamic> trailerA = extra['trailerA'] ?? {};
            _lengthTrailerAController.text = trailerA['length'] ?? '';
            _vinAController.text = trailerA['vin'] ?? '';
            _registrationAController.text = trailerA['registration'] ?? '';

            trailerForm.setSuperlinkALength(trailerA['length'] ?? '');
            trailerForm.setSuperlinkAVin(trailerA['vin'] ?? '');
            trailerForm
                .setSuperlinkARegistration(trailerA['registration'] ?? '');

            Map<String, dynamic> trailerB = extra['trailerB'] ?? {};
            _lengthTrailerBController.text = trailerB['length'] ?? '';
            _vinBController.text = trailerB['vin'] ?? '';
            _registrationBController.text = trailerB['registration'] ?? '';

            trailerForm.setSuperlinkBLength(trailerB['length'] ?? '');
            trailerForm.setSuperlinkBVin(trailerB['vin'] ?? '');
            trailerForm
                .setSuperlinkBRegistration(trailerB['registration'] ?? '');
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching vehicle data: $e");
    }
  }
}
