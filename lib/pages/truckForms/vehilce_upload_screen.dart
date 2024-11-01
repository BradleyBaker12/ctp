// vehicle_upload_tabs.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/truckForms/custom_dropdown.dart';
import 'package:ctp/pages/truckForms/maintenance_warrenty_screen.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:ctp/providers/form_data_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart'; // Added for file picking
import 'custom_text_field.dart';
import 'custom_radio_button.dart';
import 'image_picker_widget.dart';

class VehicleUploadScreen extends StatefulWidget {
  final bool isDuplicating;
  final Vehicle? vehicle;

  const VehicleUploadScreen(
      {Key? key, this.vehicle, this.isDuplicating = false})
      : super(key: key);

  @override
  _VehicleUploadScreenState createState() => _VehicleUploadScreenState();
}

class _VehicleUploadScreenState extends State<VehicleUploadScreen> {
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
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(1, (index) => GlobalKey<FormState>());
  bool _isLoading = false;
  String? _vehicleId;
  DateTime? _availableDate;

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

  // Variable to hold selected RC1/NATIS file
  File? _natisRc1File;

  @override
  void initState() {
    super.initState();

    final formData = Provider.of<FormDataProvider>(context, listen: false);

    if (widget.vehicle != null) {
      _populateVehicleData();

      // Ensure that the options lists include the existing values
      if (formData.application != null &&
          !_applicationOptions.contains(formData.application)) {
        _applicationOptions.add(formData.application!);
      }
      if (formData.config != null &&
          !_configurationOptions.contains(formData.config)) {
        _configurationOptions.add(formData.config!);
      }
    } else {
      // Initialize provider variables if null (for new vehicles)
      _initializeDefaultValues(formData);
    }

    // Initialize TextEditingControllers with provider's variables
    _initializeTextControllers(formData);

    // Add listeners to update provider variables
    _addControllerListeners(formData);

    // Listen to scroll events to adjust image height
    _scrollController.addListener(() {
      setState(() {
        double offset = _scrollController.offset;
        if (offset < 0) offset = 0;
        if (offset > 150.0) offset = 150.0;
        _imageHeight = 300.0 - offset;
      });
    });

    // Notify listeners after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      formData.notifyListeners();
    });
  }

  void _initializeDefaultValues(FormDataProvider formData) {
    if (formData.vehicleType == null) {
      formData.setVehicleType('truck', notify: false);
    }
    if (formData.suspension == null) {
      formData.setSuspension('spring', notify: false);
    }
    if (formData.transmissionType == null) {
      formData.setTransmissionType('automatic', notify: false);
    }
    if (formData.hydraulics == null) {
      formData.setHydraulics('yes', notify: false);
    }
    if (formData.maintenance == null) {
      formData.setMaintenance('yes', notify: false);
    }
    if (formData.warranty == null) {
      formData.setWarranty('yes', notify: false);
    }
    if (formData.requireToSettleType == null) {
      formData.setRequireToSettleType('yes', notify: false);
    }
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
  }

  void _addControllerListeners(FormDataProvider formData) {
    _yearController.addListener(() {
      formData.setYear(_yearController.text);
    });
    _makeModelController.addListener(() {
      formData.setMakeModel(_makeModelController.text);
    });
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
  }

  void _populateVehicleData() {
    final formData = Provider.of<FormDataProvider>(context, listen: false);

    formData.setNatisRc1UrlUrl(widget.vehicle!.rc1NatisFile, notify: false);
    formData.setVehicleType(widget.vehicle!.vehicleType, notify: false);
    formData.setYear(widget.vehicle!.year, notify: false);
    formData.setMakeModel(widget.vehicle!.makeModel, notify: false);
    formData.setVinNumber(widget.vehicle!.vinNumber, notify: false);
    formData.setMileage(widget.vehicle!.mileage, notify: false);
    formData.setEngineNumber(widget.vehicle!.engineNumber, notify: false);
    formData.setRegistrationNumber(widget.vehicle!.registrationNumber,
        notify: false);
    formData.setSellingPrice(widget.vehicle!.adminData.settlementAmount,
        notify: false);
    formData.setMainImageUrl(widget.vehicle!.mainImageUrl, notify: false);

    formData.setApplication(widget.vehicle!.application, notify: false);
    formData.setConfig(widget.vehicle!.config, notify: false);
    formData.setSuspension(widget.vehicle!.suspensionType, notify: false);
    formData.setTransmissionType(widget.vehicle!.transmissionType,
        notify: false);
    formData.setHydraulics(widget.vehicle!.hydraluicType, notify: false);
    formData.setWarranty(widget.vehicle!.warrentyType, notify: false);
    formData.setWarrantyDetails(widget.vehicle!.warrantyDetails, notify: false);

    if (widget.isDuplicating) {
      _vehicleId = null;
    } else {
      _vehicleId = widget.vehicle!.id;
    }
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

    return Stack(
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
    );
  }

  Widget _buildImageSection() {
    final formData = Provider.of<FormDataProvider>(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 0),
      height: _imageHeight,
      width: double.infinity,
      child: formData.selectedMainImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Image.file(
                formData.selectedMainImage!,
                width: double.infinity,
                height: _imageHeight,
                fit: BoxFit.cover,
              ),
            )
          : (formData.mainImageUrl != null && formData.mainImageUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.network(
                    formData.mainImageUrl!,
                    width: double.infinity,
                    height: _imageHeight,
                    fit: BoxFit.cover,
                  ),
                )
              : ImagePickerWidget(
                  onImagePicked: (File? image) {
                    if (image != null) {
                      Provider.of<FormDataProvider>(context, listen: false)
                          .setSelectedMainImage(image);
                    }
                  },
                )),
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
          // RC1/NATIS File Upload Section
          Center(
            child: Text(
              'Please attach NATIS/RC1 Documentation'.toUpperCase(),
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 15),
          InkWell(
            onTap: _pickNatisRc1File,
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
              child: Column(
                children: [
                  if (_natisRc1File == null)
                    Icon(
                      Icons.drive_folder_upload_outlined,
                      color: Colors.white,
                      size: 50.0,
                      semanticLabel: 'NATIS/RC1 Upload',
                    ),
                  const SizedBox(height: 10),
                  if (_natisRc1File != null)
                    _buildUploadedFile(_natisRc1File, _isLoading)
                  else
                    const Text(
                      'NATIS/RC1 Upload',
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
                },
              ),
              const SizedBox(width: 15),
              CustomRadioButton(
                label: 'Trailer',
                value: 'trailer',
                groupValue: formData.vehicleType,
                onChanged: (value) {
                  formData.setVehicleType(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                  value: _configurationOptions.contains(formData.config)
                      ? formData.config
                      : null,
                  items: _configurationOptions,
                  onChanged: (value) {
                    formData.setConfig(value);
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
                  value: _applicationOptions.contains(formData.application)
                      ? formData.application
                      : null,
                  items: _applicationOptions,
                  onChanged: (value) {
                    formData.setApplication(value);
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
                      },
                    ),
                    const SizedBox(width: 15),
                    CustomRadioButton(
                      label: 'Coil',
                      value: 'coil',
                      groupValue: formData.suspension,
                      onChanged: (value) {
                        formData.setSuspension(value);
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
                      },
                    ),
                    const SizedBox(width: 15),
                    CustomRadioButton(
                      label: 'Manual',
                      value: 'manual',
                      groupValue: formData.transmissionType,
                      onChanged: (value) {
                        formData.setTransmissionType(value);
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
                      },
                    ),
                    const SizedBox(width: 15),
                    CustomRadioButton(
                      label: 'No',
                      value: 'no',
                      groupValue: formData.hydraulics,
                      onChanged: (value) {
                        formData.setHydraulics(value);
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
                      },
                    ),
                    const SizedBox(width: 15),
                    CustomRadioButton(
                      label: 'No',
                      value: 'no',
                      groupValue: formData.maintenance,
                      onChanged: (value) {
                        formData.setMaintenance(value);
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
                      },
                    ),
                    const SizedBox(width: 15),
                    CustomRadioButton(
                      label: 'No',
                      value: 'no',
                      groupValue: formData.warranty,
                      onChanged: (value) {
                        formData.setWarranty(value);
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
                      },
                    ),
                    const SizedBox(width: 15),
                    CustomRadioButton(
                      label: 'No',
                      value: 'no',
                      groupValue: formData.requireToSettleType,
                      onChanged: (value) {
                        formData.setRequireToSettleType(value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: CustomButton(
              text: 'Save',
              borderColor: AppColors.blue,
              onPressed: () async {
                if (_formKeys[0].currentState!.validate()) {
                  if (_natisRc1File == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please upload the RC1/NATIS file.'),
                      ),
                    );
                    return;
                  }
                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    String? vehicleId = await _saveSection1Data();
                    if (vehicleId != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vehicle saved successfully.'),
                        ),
                      );
                      // Navigate to Maintenance & Warranty Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MaintenanceWarrantyScreen(
                            vehicleId: vehicleId,
                            mainImageFile: formData.selectedMainImage,
                            mainImageUrl: formData.mainImageUrl,
                          ),
                        ),
                      );
                    } else {
                      // Vehicle ID is null, handle accordingly
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to retrieve vehicle ID.'),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error saving vehicle: $e'),
                      ),
                    );
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields.'),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Future<String?> _saveSection1Data() async {
    try {
      String? imageUrl;
      final formData = Provider.of<FormDataProvider>(context, listen: false);

      final userId = FirebaseAuth.instance.currentUser?.uid;

      // Upload main image if selected
      if (formData.selectedMainImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('vehicle_images')
            .child('${DateTime.now().toIso8601String()}.jpg');
        await ref.putFile(formData.selectedMainImage!);
        imageUrl = await ref.getDownloadURL();
      }

      // Upload RC1/NATIS file if selected
      String? natisRc1Url;
      if (_natisRc1File != null) {
        final ref = FirebaseStorage.instance.ref().child('vehicle_documents').child(
            '${DateTime.now().millisecondsSinceEpoch}_${_natisRc1File!.path.split('/').last}');
        await ref.putFile(_natisRc1File!);
        natisRc1Url = await ref.getDownloadURL();
      }

      // Prepare vehicle data
      final vehicleData = {
        'year': formData.year,
        'makeModel': formData.makeModel,
        'vinNumber': formData.vinNumber,
        'configuration': formData.config,
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
        'mainImageUrl': imageUrl ?? formData.mainImageUrl,
        'natisRc1Url': natisRc1Url, // Saving RC1/NATIS URL directly
        'userId': userId,
        'vehicleStatus': 'Draft',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Prepare admin data
      Map<String, dynamic> adminData = {};
      if (natisRc1Url != null) {
        adminData['natisRc1Url'] = natisRc1Url;
      }

      DocumentReference docRef;

      if (_vehicleId == null) {
        // Adding a new vehicle
        vehicleData['adminData'] = adminData;
        docRef = await FirebaseFirestore.instance
            .collection('vehicles')
            .add(vehicleData);
        _vehicleId = docRef.id;
      } else {
        // Updating an existing vehicle
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(_vehicleId)
            .update(vehicleData);
        // Update adminData separately
        if (adminData.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('vehicles')
              .doc(_vehicleId)
              .set({'adminData': adminData}, SetOptions(merge: true));
        }
      }

      return _vehicleId;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving vehicle: $e'),
        ),
      );
      return null;
    }
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
