// vehicle_upload_tabs.dart

import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/truckForms/custom_dropdown.dart';
import 'package:ctp/pages/truckForms/custom_radio_button.dart';
import 'package:ctp/pages/truckForms/custom_text_field.dart';
import 'package:ctp/pages/truckForms/image_picker_widget.dart';
import 'package:ctp/pages/truckForms/maintenance_warrenty_screen.dart';
import 'package:ctp/providers/form_data_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart'; // Added for file picking
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart' show rootBundle; // Import rootBundle

class BasicInformationEdit extends StatefulWidget {
  final bool isDuplicating;
  final Vehicle? vehicle;
  final bool isNewUpload;

  const BasicInformationEdit(
      {super.key,
      this.vehicle,
      this.isDuplicating = false,
      this.isNewUpload = false});

  @override
  _BasicInformationEditState createState() => _BasicInformationEditState();
}

class _BasicInformationEditState extends State<BasicInformationEdit> {
  // Controllers and Variables
  final ScrollController _scrollController = ScrollController();
  double _imageHeight = 300.0;
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _makeModelController = TextEditingController();
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
  final TextEditingController _brandsController = TextEditingController();
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(1, (index) => GlobalKey<FormState>());
  bool _isLoading = false;
  String? _vehicleId;
  DateTime? _availableDate;

  List<String> _countryOptions = []; // Define the country options list

  // Define application options
  final List<String> _applicationOptions = [
    'Tractor Units',
    'Tipper Trucks',
    'Box Trucks',
    'Curtain Side Trucks',
    'Chassis Cab Truck',
    'Flatbed Truck',
    'Refrigerated Truck',
    'Crane Truck',
    'Hook Loader Truck',
    'Concrete Truck',
    'Municipal Truck',
    'Dismantled Truck',
    'Beavertail Trucks',
    // Add any other missing application types
  ];

  // Define configuration options
  final List<String> _configurationOptions = [
    '6X4',
    '6X2',
    '4X2',
    '8X4',
    // Add any other configurations if needed
  ];

  // Define brand options
  final List<String> _brandOptions = [
    'Volvo',
    'Mercedes-Benz',
    'MAN',
    'Scania',
    'DAF',
    'Iveco',
    'Isuzu',
    'Hino',
    'Freightliner',
    'Kenworth',
    'Peterbilt',
    'Mack',
    // Add any other brands as needed
  ];

  // Variable to hold selected RC1/NATIS file
  File? _natisRc1File;

  // Add this flag at the top with other variables
  bool isNewUpload = false;

  // Add these variables
  String? _existingNatisRc1Url;
  String? _existingNatisRc1Name;

  // Add this line with other class variables
  int _currentStep = 0;

  // Add these controllers
  final TextEditingController _configController = TextEditingController();
  final TextEditingController _applicationController = TextEditingController();

  // Add this new variable to hold the vehicle status
  String? _vehicleStatus;

  @override
  void initState() {
    super.initState();
    _loadCountryOptions(); // Load country options on initialization

    final formData = Provider.of<FormDataProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // If editing an existing vehicle
      if (widget.vehicle != null && !widget.isDuplicating) {
        _vehicleId = widget.vehicle!.id;
        _populateExistingVehicleData();
      }
      // If duplicating, clear the ID but keep the data
      else if (widget.isDuplicating) {
        _vehicleId = null;
        _populateExistingVehicleData();
      }
      // If new upload
      else if (widget.isNewUpload) {
        _clearAllData(formData);
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

  // New method to load country options from JSON
  Future<void> _loadCountryOptions() async {
    final String response =
        await rootBundle.loadString('lib/assets/country-by-name.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      _countryOptions =
          data.map((country) => country['country'] as String).toList();
    });
  }

  void _clearAllData(FormDataProvider formData) {
    formData.clearAllData();
    formData.setSelectedMainImage(null);
    formData.setMainImageUrl(null);
    formData.setNatisRc1Url(null);

    formData.setYear(null);
    formData.setMakeModel(null);
    formData.setVinNumber(null);
    formData.setConfig(null);
    formData.setMileage(null);
    formData.setApplication(null);
    formData.setEngineNumber(null);
    formData.setRegistrationNumber(null);
    formData.setSellingPrice(null);
    formData.setVehicleType(null);
    formData.setSuspension(null);
    formData.setTransmissionType(null);
    formData.setHydraulics('no');
    formData.setMaintenance('no');
    formData.setWarranty('no');
    formData.setWarrantyDetails(null);
    formData.setRequireToSettleType('no');
    formData.setReferenceNumber(null);
    formData.setBrands([]);

    _clearFormControllers();

    setState(() {
      _natisRc1File = null;
      _existingNatisRc1Url = null;
      _existingNatisRc1Name = null;

      // Update the form data provider instead
      final formData = Provider.of<FormDataProvider>(context, listen: false);
      formData.setSelectedMainImage(null);
      formData.setMainImageUrl(null);
    });

    _vehicleId = null;
    _isLoading = false;
    _currentStep = 0;
  }

  // void _clearFormControllers() {
  //   _yearController.clear();
  //   _makeModelController.clear();
  //   _sellingPriceController.clear();
  //   _vinNumberController.clear();
  //   _mileageController.clear();
  //   _engineNumberController.clear();
  //   _warrantyDetailsController.clear();
  //   _registrationNumberController.clear();
  //   _referenceNumberController.clear();
  //   _brandsController.clear();
  //   _configController.clear();
  //   _applicationController.clear();

  //   setState(() {
  //     _natisRc1File = null;
  //     _existingNatisRc1Url = null;
  //     _existingNatisRc1Name = null;
  //   });
  // }

  void _initializeDefaultValues(FormDataProvider formData) {
    // Set any default values needed for new trucks
    formData.setVehicleType('truck'); // Default to truck
    formData.setSuspension('spring'); // Default suspension
    formData.setTransmissionType('automatic'); // Default transmission
    formData.setHydraulics('no'); // Default hydraulics
    formData.setMaintenance('no'); // Default maintenance
    formData.setWarranty('no'); // Default warranty
    formData.setRequireToSettleType('no'); // Default settle type
  }

  void _initializeTextControllers(FormDataProvider formData) {
    _yearController.text = formData.year ?? '';
    _makeModelController.text = formData.makeModel ?? '';
    _vinNumberController.text = formData.vinNumber ?? '';
    _mileageController.text = formData.mileage ?? '';
    _engineNumberController.text = formData.engineNumber ?? '';
    _registrationNumberController.text = formData.registrationNumber ?? '';
    _sellingPriceController.text = formData.sellingPrice ?? '';
    _warrantyDetailsController.text = formData.warrantyDetails ?? '';
    _referenceNumberController.text = formData.referenceNumber ?? '';
    _brandsController.text = (formData.brands)?.firstOrNull ?? '';
  }

  void _addControllerListeners(FormDataProvider formData) {
    // Year controller
    _yearController.addListener(() {
      formData.setYear(_yearController.text);
      formData.saveFormState();
    });

    // Make/Model controller
    _makeModelController.addListener(() {
      formData.setMakeModel(_makeModelController.text);
      formData.saveFormState();
    });

    // VIN Number controller
    _vinNumberController.addListener(() {
      formData.setVinNumber(_vinNumberController.text);
      formData.saveFormState();
    });

    // Mileage controller
    _mileageController.addListener(() {
      formData.setMileage(_mileageController.text);
      formData.saveFormState();
    });

    // Engine Number controller
    _engineNumberController.addListener(() {
      formData.setEngineNumber(_engineNumberController.text);
      formData.saveFormState();
    });

    // Registration Number controller
    _registrationNumberController.addListener(() {
      formData.setRegistrationNumber(_registrationNumberController.text);
      formData.saveFormState();
    });

    // Selling Price controller
    _sellingPriceController.addListener(() {
      formData.setSellingPrice(_sellingPriceController.text);
      formData.saveFormState();
    });

    // Warranty Details controller
    _warrantyDetailsController.addListener(() {
      formData.setWarrantyDetails(_warrantyDetailsController.text);
      formData.saveFormState();
    });

    // Reference Number controller
    _referenceNumberController.addListener(() {
      final value = _referenceNumberController.text;
      formData.setReferenceNumber(value);
      formData.saveFormState();
      // Ensure the controller text matches the new value
      if (_referenceNumberController.text != value) {
        setState(() {
          _referenceNumberController.text = value;
        });
      }
    });

    // Brands controller
    _brandsController.addListener(() {
      formData.setBrands([_brandsController.text]);
      formData.saveFormState();
    });

    // Config controller
    _configController.addListener(() {
      formData.setConfig(_configController.text);
      formData.saveFormState();
    });

    // Application controller
    _applicationController.addListener(() {
      formData.setApplication(_applicationController.text);
      formData.saveFormState();
    });
  }

  void _populateExistingVehicleData() {
    final formData = Provider.of<FormDataProvider>(context, listen: false);

    // Populate main image
    if (widget.vehicle?.mainImageUrl != null) {
      formData.setMainImageUrl(widget.vehicle!.mainImageUrl);
    }

    // Populate NATIS/RC1 file
    setState(() {
      _existingNatisRc1Url = widget.vehicle?.rc1NatisFile;
      _existingNatisRc1Name = _getFileNameFromUrl(_existingNatisRc1Url);
    });

    // Populate form fields
    _yearController.text = widget.vehicle?.year ?? '';
    _makeModelController.text = widget.vehicle?.makeModel ?? '';
    _vinNumberController.text = widget.vehicle?.vinNumber ?? '';
    _mileageController.text = widget.vehicle?.mileage ?? '';
    _engineNumberController.text = widget.vehicle?.engineNumber ?? '';
    _registrationNumberController.text =
        widget.vehicle?.registrationNumber ?? '';
    _sellingPriceController.text =
        widget.vehicle?.adminData.settlementAmount ?? '';
    _warrantyDetailsController.text = widget.vehicle?.warrantyDetails ?? '';
    _referenceNumberController.text = widget.vehicle?.referenceNumber ?? '';

    // Update brand field and form provider
    if (widget.vehicle?.brand != null) {
      _brandsController.text = widget.vehicle!.brand;
      formData.setBrands([widget.vehicle!.brand]);
    }

    // Update form provider
    formData.setYear(widget.vehicle?.year);
    formData.setMakeModel(widget.vehicle?.makeModel);
    formData.setVinNumber(widget.vehicle?.vinNumber);
    formData.setConfig(widget.vehicle?.config);
    formData.setMileage(widget.vehicle?.mileage);
    formData.setApplication(widget.vehicle?.application);
    formData.setEngineNumber(widget.vehicle?.engineNumber);
    formData.setRegistrationNumber(widget.vehicle?.registrationNumber);
    formData.setSellingPrice(widget.vehicle?.adminData.settlementAmount);
    formData.setVehicleType(widget.vehicle?.vehicleType ?? 'truck');
    formData.setSuspension(widget.vehicle?.suspensionType ?? 'spring');
    formData
        .setTransmissionType(widget.vehicle?.transmissionType ?? 'automatic');
    formData.setHydraulics(widget.vehicle?.hydraluicType ?? 'no');
    formData.setMaintenance((widget.vehicle?.maintenance as String?) ?? 'no');
    formData.setWarranty(widget.vehicle?.warrentyType ?? 'no');
    formData.setWarrantyDetails(widget.vehicle?.warrantyDetails);
    formData
        .setRequireToSettleType(widget.vehicle?.requireToSettleType ?? 'no');
    formData.setReferenceNumber(widget.vehicle?.referenceNumber);
  }

  // Helper to extract filename from URL
  String? _getFileNameFromUrl(String? url) {
    if (url == null) return null;
    return url.split('/').last.split('?').first;
  }

  // Function to pick RC1/NATIS file
  Future<void> _pickNatisRc1File() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _natisRc1File = File(result.files.single.path!);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  // Helper function to get file icon based on extension
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
      case 'gif':
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

  // Helper function to check if file is an image
  bool _isImageFile(String path) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    String extension = path.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }

  // Helper method to display uploaded files
  Widget _buildUploadedFile(File? file, bool isUploading) {
    if (file == null) {
      return const Text(
        'No file selected',
        style: TextStyle(color: Colors.white70),
      );
    } else {
      String fileName = file.path.split('/').last;
      String extension = fileName.split('.').last;
      return Column(
        children: [
          if (_isImageFile(file.path))
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.file(
                file,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            )
          else
            Column(
              children: [
                Icon(
                  _getFileIcon(extension),
                  color: Colors.white,
                  size: 50.0,
                ),
                const SizedBox(height: 8),
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          const SizedBox(height: 8),
          if (isUploading)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(width: 10),
                Text(
                  'Uploading...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formData = Provider.of<FormDataProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        if (widget.isNewUpload) {
          final formData =
              Provider.of<FormDataProvider>(context, listen: false);
          _clearAllData(formData);
        }
        return true;
      },
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_left),
                color: Colors.white,
                iconSize: 40,
              ),
              backgroundColor: Color(0xFF0E4CAF),
              elevation: 0.0,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              centerTitle: true,
            ),
            body: GradientBackground(
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification.metrics.axis == Axis.vertical) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        double offset = scrollNotification.metrics.pixels;
                        if (offset < 0) offset = 0;
                        if (offset > 150.0) offset = 150.0;
                        _imageHeight = 300.0 - offset;
                      });
                    });
                  }
                  return true;
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      _buildImageSection(),
                      _buildMandatorySection(),
                    ],
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
    );
  }

  Widget _buildImageSection() {
    final formData = Provider.of<FormDataProvider>(context);

    // Function to show image picker dialog
    void showImagePickerDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          );
        },
      );
    }

    // Function to handle image tap
    void handleImageTap() {
      if (formData.selectedMainImage != null ||
          (formData.mainImageUrl != null &&
              formData.mainImageUrl!.isNotEmpty)) {
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
                    showImagePickerDialog();
                  },
                  child: const Text('Change Image'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      formData.setSelectedMainImage(null);
                      formData.setMainImageUrl(null);
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
        showImagePickerDialog();
      }
    }

    return GestureDetector(
      onTap: handleImageTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 0),
        height: _imageHeight,
        width: double.infinity,
        child: Stack(
          children: [
            if (formData.selectedMainImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.file(
                  formData.selectedMainImage!,
                  width: double.infinity,
                  height: _imageHeight,
                  fit: BoxFit.cover,
                ),
              )
            else if (formData.mainImageUrl != null &&
                formData.mainImageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: Image.network(
                  formData.mainImageUrl!,
                  width: double.infinity,
                  height: _imageHeight,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              )
            else
              ImagePickerWidget(
                onImagePicked: (File? image) {
                  if (image != null) {
                    formData.setSelectedMainImage(image);
                  }
                },
              ),
            // Add an overlay hint
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

  Widget _buildMandatorySection() {
    final formData = Provider.of<FormDataProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Text(
              'truck/trailer form'.toUpperCase(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Please fill out the required details below.',
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Center(
            child: Text(
              'Your trusted partner on the road.',
              style: const TextStyle(fontSize: 14, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 15),
          // Vehicle Status Dropdown
          CustomDropdown(
            hintText: 'Vehicle Status',
            value: _vehicleStatus ?? 'Draft', // Default to Draft
            items: const ['Draft', 'Live'],
            onChanged: (value) {
              setState(() {
                _vehicleStatus = value;
                formData.setVehicleStatus(value); // Update form data provider
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
          // Reference Number field
          _buildReferenceNumberField(),
          const SizedBox(height: 15),
          // RC1/NATIS File Upload Section
          _buildNatisRc1Section(),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomRadioButton(
                label: 'Truck',
                value: 'truck',
                groupValue: formData.vehicleType,
                onChanged: (value) {
                  formData.setVehicleType(value);
                  formData.saveFormState();
                },
              ),
              const SizedBox(width: 15),
              CustomRadioButton(
                label: 'Trailer',
                value: 'trailer',
                groupValue: formData.vehicleType,
                onChanged: (value) {
                  formData.setVehicleType(value);
                  formData.saveFormState();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Brand field
          CustomDropdown(
            hintText: 'Brand',
            value: widget.vehicle?.brand ?? formData.brands?.firstOrNull,
            items: _brandOptions,
            onChanged: (value) {
              if (value != null) {
                formData.setBrands([value]);
                formData.saveFormState();
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select the brand';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          Form(
            key: _formKeys[0],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Year and Make/Model
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _yearController,
                        hintText: 'Year',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the year';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomTextField(
                        controller: _makeModelController,
                        hintText: 'Make/Model',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the make/model';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // Country Dropdown
                CustomDropdown(
                  hintText: 'Select Country',
                  value: formData.country?.isNotEmpty == true
                      ? formData.country
                      : null,
                  items: _countryOptions, // Assuming _countryOptions is defined
                  onChanged: (value) {
                    formData.setCountry(value); // Update form data provider
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a country';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                // Mileage
                CustomTextField(
                  controller: _mileageController,
                  hintText: 'Mileage',
                  keyboardType: TextInputType.number,
                  inputFormatter: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the mileage';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                CustomDropdown(
                  hintText: 'Configuration',
                  value: formData.config?.isNotEmpty == true
                      ? formData.config
                      : null,
                  items: _configurationOptions,
                  onChanged: (value) {
                    formData.setConfig(value);
                    formData.saveFormState();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select the configuration';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                // Application of Use
                CustomDropdown(
                  hintText: 'Application of Use',
                  value: formData.application?.isNotEmpty == true
                      ? formData.application
                      : null,
                  items: _applicationOptions,
                  onChanged: (value) {
                    formData.setApplication(value);
                    formData.saveFormState();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select the application of use';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                // VIN Number
                CustomTextField(
                  controller: _vinNumberController,
                  hintText: 'VIN Number',
                  inputFormatter: [UpperCaseTextFormatter()],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the VIN number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                // Engine Number
                CustomTextField(
                  controller: _engineNumberController,
                  hintText: 'Engine No.',
                  inputFormatter: [UpperCaseTextFormatter()],
                ),
                const SizedBox(height: 15),
                // Registration Number
                CustomTextField(
                  controller: _registrationNumberController,
                  hintText: 'Registration No.',
                  inputFormatter: [UpperCaseTextFormatter()],
                ),
                const SizedBox(height: 15),
                // Selling Price
                CustomTextField(
                  controller: _sellingPriceController,
                  hintText: 'Selling Price',
                  isCurrency: true,
                  keyboardType: TextInputType.number,
                  inputFormatter: [
                    FilteringTextInputFormatter.digitsOnly,
                    ThousandsSeparatorInputFormatter(),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the selling price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    'Suspension',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomRadioButton(
                      label: 'Spring',
                      value: 'spring',
                      groupValue: formData.suspension,
                      onChanged: (value) {
                        formData.setSuspension(value);
                        formData.saveFormState();
                      },
                    ),
                    const SizedBox(width: 15),
                    CustomRadioButton(
                      label: 'Air',
                      value: 'air',
                      groupValue: formData.suspension,
                      onChanged: (value) {
                        formData.setSuspension(value);
                        formData.saveFormState();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Divider(),
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    'Transmission',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomRadioButton(
                      label: 'Automatic',
                      value: 'automatic',
                      groupValue: formData.transmissionType,
                      onChanged: (value) {
                        formData.setTransmissionType(value);
                        formData.saveFormState();
                      },
                    ),
                    const SizedBox(width: 15),
                    CustomRadioButton(
                      label: 'Manual',
                      value: 'manual',
                      groupValue: formData.transmissionType,
                      onChanged: (value) {
                        formData.setTransmissionType(value);
                        formData.saveFormState();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Divider(),
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    'Hydraulics',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomRadioButton(
                      label: 'Yes',
                      value: 'yes',
                      groupValue: formData.hydraulics,
                      onChanged: (value) {
                        formData.setHydraulics(value);
                        formData.saveFormState();
                      },
                    ),
                    const SizedBox(width: 15),
                    CustomRadioButton(
                      label: 'No',
                      value: 'no',
                      groupValue: formData.hydraulics,
                      onChanged: (value) {
                        formData.setHydraulics(value);
                        formData.saveFormState();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Divider(),
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    'Maintenance',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomRadioButton(
                      label: 'Yes',
                      value: 'yes',
                      groupValue: formData.maintenance,
                      onChanged: (value) {
                        formData.setMaintenance(value);
                        formData.saveFormState();
                      },
                    ),
                    const SizedBox(width: 15),
                    CustomRadioButton(
                      label: 'No',
                      value: 'no',
                      groupValue: formData.maintenance,
                      onChanged: (value) {
                        formData.setMaintenance(value);
                        formData.saveFormState();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Divider(),
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    'Warranty',
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomRadioButton(
                      label: 'Yes',
                      value: 'yes',
                      groupValue: formData.warranty,
                      onChanged: (value) {
                        formData.setWarranty(value);
                        formData.saveFormState();
                      },
                    ),
                    const SizedBox(width: 15),
                    CustomRadioButton(
                      label: 'No',
                      value: 'no',
                      groupValue: formData.warranty,
                      onChanged: (value) {
                        formData.setWarranty(value);
                        formData.saveFormState();
                      },
                    ),
                  ],
                ),
                if (formData.warranty == 'yes') ...[
                  const SizedBox(height: 15),
                  CustomTextField(
                    controller: _warrantyDetailsController,
                    hintText: 'WHAT MAIN WARRANTY IS THE VEHICLE ON',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the warranty details';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 15),
                Divider(),
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    'Do you require the truck to be settled before selling'
                        .toUpperCase(),
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomRadioButton(
                      label: 'Yes',
                      value: 'yes',
                      groupValue: formData.requireToSettleType,
                      onChanged: (value) {
                        formData.setRequireToSettleType(value);
                        formData.saveFormState();
                      },
                    ),
                    const SizedBox(width: 15),
                    CustomRadioButton(
                      label: 'No',
                      value: 'no',
                      groupValue: formData.requireToSettleType,
                      onChanged: (value) {
                        formData.setRequireToSettleType(value);
                        formData.saveFormState();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildNextButton(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Future<String?> _saveSection1Data() async {
    try {
      final formData = Provider.of<FormDataProvider>(context, listen: false);

      String? imageUrl = formData.mainImageUrl;
      String? natisRc1Url = _existingNatisRc1Url;

      // Upload new main image if selected
      if (formData.selectedMainImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('vehicle_images')
            .child('${DateTime.now().toIso8601String()}.jpg');
        await ref.putFile(formData.selectedMainImage!);
        imageUrl = await ref.getDownloadURL();
      }

      // Upload new NATIS/RC1 file if selected
      if (_natisRc1File != null) {
        final ref = FirebaseStorage.instance.ref().child('vehicle_documents').child(
            '${DateTime.now().millisecondsSinceEpoch}_${_natisRc1File!.path.split('/').last}');
        await ref.putFile(_natisRc1File!);
        natisRc1Url = await ref.getDownloadURL();
      }

      final vehicleData = {
        'year': formData.year,
        'makeModel': formData.makeModel,
        'vinNumber': formData.vinNumber,
        'config': formData.config,
        'mileage': formData.mileage,
        'application': formData.application,
        'engineNumber': formData.engineNumber,
        'registrationNumber': formData.registrationNumber,
        'sellingPrice': formData.sellingPrice,
        'vehicleType': formData.vehicleType,
        'suspensionType': formData.suspension,
        'transmissionType': formData.transmissionType,
        'hydraulics': formData.hydraulics,
        'maintenance': formData.maintenance,
        'warranty': formData.warranty,
        'warrantyDetails': formData.warrantyDetails,
        'requireToSettleType': formData.requireToSettleType,
        'referenceNumber': formData.referenceNumber,
        'brands': formData.brands,
        'mainImageUrl': imageUrl,
        'rc1NatisFile': natisRc1Url,
        'country': formData.country,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'vehicleStatus': 'Draft', // Initial status for new vehicles
      };

      // Update existing document or create new one
      if (_vehicleId != null && !widget.isDuplicating) {
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(_vehicleId)
            .update(vehicleData);

        setState(() {
          formData.setReferenceNumber(_referenceNumberController.text.trim());
          if (_referenceNumberController.text != formData.referenceNumber) {
            _referenceNumberController.text = formData.referenceNumber ?? '';
          }
        });

        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Vehicle updated successfully')),
        // );
      } else {
        // Create new document for duplicating or new vehicle
        final docRef =
            await FirebaseFirestore.instance.collection('vehicles').add({
          ...vehicleData,
          'createdAt': FieldValue.serverTimestamp(),
          'userId': FirebaseAuth.instance.currentUser?.uid,
          'vehicleStatus': 'Draft',
        });
        _vehicleId = docRef.id;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle created successfully')),
        );
      }

      return _vehicleId;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving vehicle: $e')),
      );
      return null;
    }
  }

  bool _validateRequiredFields(FormDataProvider formData) {
    if (formData.selectedMainImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a main image')),
      );
      return false;
    }

    if (formData.year == null || formData.year!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the year')),
      );
      return false;
    }

    return true;
  }

// Update the Next button handler
  Widget _buildNextButton() {
    return Center(
      child: CustomButton(
        text: 'Save',
        borderColor: AppColors.blue,
        onPressed: () async {
          final formData =
              Provider.of<FormDataProvider>(context, listen: false);

          if (widget.isNewUpload && !_validateRequiredFields(formData)) {
            return;
          }

          setState(() => _isLoading = true);

          try {
            String? vehicleId = await _saveSection1Data();
            if (vehicleId != null) {
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Changes saved successfully'),
                  duration: Duration(seconds: 2),
                ),
              );

              // Navigate back to previous screen
              Navigator.pop(context);
            }
          } finally {
            setState(() => _isLoading = false);
          }
        },
      ),
    );
  }

// Add this method to clear form controllers
  void _clearFormControllers() {
    _yearController.clear();
    _makeModelController.clear();
    _sellingPriceController.clear();
    _vinNumberController.clear();
    _mileageController.clear();
    _engineNumberController.clear();
    _warrantyDetailsController.clear();
    _registrationNumberController.clear();
    _referenceNumberController.clear();
    _brandsController.clear();

    // Clear image-related data
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    formData.setSelectedMainImage(null);
    formData.setMainImageUrl(null);

    setState(() {
      _natisRc1File = null;
      _existingNatisRc1Url = null;
      _existingNatisRc1Name = null;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      formData.setSelectedMainImage(File(image.path));
    }
  }

// Add this new method to load saved form data
  Future<void> _loadSavedFormData(FormDataProvider formData) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(_vehicleId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        setState(() {
          _yearController.text = data['year'] ?? '';
          _makeModelController.text = data['makeModel'] ?? '';
          _mileageController.text = data['mileage'] ?? '';
          _vinNumberController.text = data['vinNumber'] ?? '';
          _engineNumberController.text = data['engineNumber'] ?? '';
          _registrationNumberController.text = data['registrationNumber'] ?? '';
          _sellingPriceController.text = data['sellingPrice'] ?? '';
          _warrantyDetailsController.text = data['warrantyDetails'] ?? '';
          _referenceNumberController.text = data['referenceNumber'] ?? '';
          _brandsController.text =
              (data['brands'] as List<String>?)?.firstOrNull ?? '';

          // Update FormDataProvider
          formData.setYear(data['year']);
          formData.setMakeModel(data['makeModel']);
          formData.setVinNumber(data['vinNumber']);
          formData.setConfig(data['config']);
          formData.setMileage(data['mileage']);
          formData.setApplication(data['application']);
          formData.setEngineNumber(data['engineNumber']);
          formData.setRegistrationNumber(data['registrationNumber']);
          formData.setSellingPrice(data['sellingPrice']);
          formData.setVehicleType(data['vehicleType'] ?? 'truck');
          formData.setSuspension(data['suspensionType'] ?? 'spring');
          formData.setTransmissionType(data['transmissionType'] ?? 'automatic');
          formData.setHydraulics(data['hydraulics'] ?? 'yes');
          formData.setMaintenance(data['maintenance'] ?? 'yes');
          formData.setWarranty(data['warranty'] ?? 'yes');
          formData.setWarrantyDetails(data['warrantyDetails']);
          formData.setRequireToSettleType(data['requireToSettleType'] ?? 'yes');
          formData.setMainImageUrl(data['mainImageUrl']);
          formData.setReferenceNumber(data['referenceNumber']);
          formData.setBrands(data['brands']);
        });
      }
    } catch (e) {
      print('Error loading saved form data: $e');
    }
  }

  Widget _buildNatisRc1Section() {
    Widget buildFileDisplay(String? fileName, bool isExisting) {
      String extension = fileName?.split('.').last.toLowerCase() ?? '';
      IconData iconData = _getFileIcon(extension);

      return Column(
        children: [
          Icon(
            iconData,
            color: Colors.white,
            size: 50.0,
          ),
          const SizedBox(height: 10),
          Text(
            fileName ?? (isExisting ? 'Existing Document' : 'Select Document'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
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
          child: Text(
            'NATIS/RC1 Documentation'.toUpperCase(),
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
              border: Border.all(
                color: const Color(0xFF0E4CAF),
                width: 2.0,
              ),
            ),
            child: _natisRc1File != null
                ? buildFileDisplay(_natisRc1File!.path.split('/').last, false)
                : _existingNatisRc1Url != null
                    ? buildFileDisplay(_existingNatisRc1Name, true)
                    : buildFileDisplay(null, false),
          ),
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
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _viewDocument() async {
    final url = _natisRc1File != null ? null : _existingNatisRc1Url;
    if (url != null) {
      try {
        final Uri uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open document')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening document: $e')),
          );
        }
      }
    }
  }

  void _removeDocument() {
    setState(() {
      _natisRc1File = null;
      _existingNatisRc1Url = null;
      _existingNatisRc1Name = null;
    });
  }

  Widget _buildReferenceNumberField() {
    return Consumer<FormDataProvider>(
      builder: (context, formData, child) {
        return CustomTextField(
          controller: _referenceNumberController,
          hintText: 'Reference Number',
          onChanged: (value) {
            setState(() {
              _referenceNumberController.text = value;
              formData.setReferenceNumber(value);
            });
          },
        );
      },
    );
  }
}

// UpperCaseTextFormatter remains the same
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

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Only keep digits
    final String cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Format with thousand separators
    final String formatted = NumberFormat('####').format(int.parse(cleanText));

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
