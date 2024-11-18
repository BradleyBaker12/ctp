import 'package:ctp/components/constants.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/pages/truckForms/custom_radio_button.dart';
import 'package:ctp/pages/truckForms/custom_text_field.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ctp/services/vehicle_form_service.dart';

class BasicInformationForm extends StatefulWidget {
  final Map<String, dynamic>? formData;

  const BasicInformationForm({super.key, this.formData});

  @override
  State<BasicInformationForm> createState() => _BasicInformationFormState();
}

class _BasicInformationFormState extends State<BasicInformationForm> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TextEditingController _brandController;
  late TextEditingController _makeModelController;
  late TextEditingController _yearController;
  late TextEditingController _mileageController;
  late TextEditingController _vinNumberController;
  late TextEditingController _engineNumberController;
  late TextEditingController _registrationNumberController;
  late TextEditingController _expectedSellingPriceController;
  late TextEditingController _warrantyDetailsController;
  late TextEditingController _referenceNumberController;

  File? _coverPhoto;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  PlatformFile? _natisRc1File;

  String? vehicleType;
  String? configuration = '6X4';
  String? suspension;
  String? transmission;
  bool hasHydraulics = false;
  bool hasMaintenance = false;
  bool hasWarranty = false;
  bool requiresSettlement = false;
  bool isSaving = false;

  final VehicleFormService _vehicleFormService = VehicleFormService();

  TextStyle get _labelStyle => GoogleFonts.montserrat(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      );

  TextStyle get _headerStyle => GoogleFonts.montserrat(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      );

  TextStyle get _bodyStyle => GoogleFonts.montserrat(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.normal,
      );

  @override
  void initState() {
    super.initState();
    // Initialize controllers with widget.formData instead of provider
    _brandController = TextEditingController(text: widget.formData?['brand']);
    _makeModelController =
        TextEditingController(text: widget.formData?['makeModel']);
    _yearController = TextEditingController(text: widget.formData?['year']);
    _mileageController =
        TextEditingController(text: widget.formData?['mileage']);
    _vinNumberController =
        TextEditingController(text: widget.formData?['vinNumber']);
    _engineNumberController =
        TextEditingController(text: widget.formData?['engineNumber']);
    _registrationNumberController =
        TextEditingController(text: widget.formData?['registrationNumber']);
    _expectedSellingPriceController =
        TextEditingController(text: widget.formData?['expectedSellingPrice']);
    _warrantyDetailsController =
        TextEditingController(text: widget.formData?['warrantyDetails']);
    _referenceNumberController =
        TextEditingController(text: widget.formData?['referenceNumber']);

    // Replace provider listeners with setState
    _brandController.addListener(() {
      setState(() {});
    });
    _makeModelController.addListener(() {
      setState(() {});
    });
    _yearController.addListener(() {
      setState(() {});
    });
    _mileageController.addListener(() {
      setState(() {});
    });
    _vinNumberController.addListener(() {
      setState(() {});
    });
    _engineNumberController.addListener(() {
      setState(() {});
    });
    _registrationNumberController.addListener(() {
      setState(() {});
    });
    _expectedSellingPriceController.addListener(() {
      setState(() {});
    });
    _warrantyDetailsController.addListener(() {
      setState(() {});
    });
    _referenceNumberController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // Dispose of controllers
    _brandController.dispose();
    _makeModelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _vinNumberController.dispose();
    _engineNumberController.dispose();
    _registrationNumberController.dispose();
    _expectedSellingPriceController.dispose();
    _warrantyDetailsController.dispose();
    _referenceNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _coverPhoto = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<String?> _uploadCoverPhoto() async {
    if (_coverPhoto == null) return null;

    final fileName =
        'cover_photos/${DateTime.now().millisecondsSinceEpoch}_${_auth.currentUser?.uid}';
    final ref = FirebaseStorage.instance.ref().child(fileName);

    try {
      final uploadTask = await ref.putFile(_coverPhoto!);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading cover photo: $e');
      return null;
    }
  }

  Future<void> _pickNatisRc1File() async {
    try {
      setState(() => _isLoading = true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          _natisRc1File = result.files.first;
        });
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildUploadedFile(PlatformFile? file) {
    if (file == null) return const SizedBox.shrink();

    IconData fileIcon;
    if (file.extension == 'pdf') {
      fileIcon = Icons.picture_as_pdf;
    } else if (file.extension == 'doc' || file.extension == 'docx') {
      fileIcon = Icons.description;
    } else {
      fileIcon = Icons.insert_drive_file;
    }

    return Column(
      children: [
        Icon(
          fileIcon,
          color: Colors.white,
          size: 50.0,
        ),
        const SizedBox(height: 10),
        Text(
          file.name,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget buildCoverPhotoSection() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera_alt, color: Colors.white),
                    title: Text('Take Photo', style: _bodyStyle),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.photo_library, color: Colors.white),
                    title: Text('Choose from Gallery', style: _bodyStyle),
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
      },
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.blue.shade900,
          image: _coverPhoto != null
              ? DecorationImage(
                  image: FileImage(_coverPhoto!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _coverPhoto == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline,
                      color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'UPLOAD COVER PHOTO',
                    style: _labelStyle,
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget buildDocumentUploadSection() {
    return InkWell(
      onTap: _isLoading ? null : _pickNatisRc1File,
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
            if (_natisRc1File == null) ...[
              const Icon(
                Icons.drive_folder_upload_outlined,
                color: Colors.white,
                size: 50.0,
                semanticLabel: 'NATIS/RC1 Upload',
              ),
              const SizedBox(height: 10),
              Text(
                'UPLOAD YOUR RC/NATIS DOCUMENTATION',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              _buildUploadedFile(_natisRc1File),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'TRUCK/TRAILER FORM',
            style: _headerStyle,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildCoverPhotoSection(),
              const SizedBox(height: 32),

              // Wrap the rest of the content in padding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Vehicle Type Selection
                    Center(
                      child: Text(
                        'VEHICLE TYPE',
                        style: _bodyStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    buildVehicleTypeRadio(),
                    const SizedBox(height: 24),
                    CustomTextField(
                      controller: _referenceNumberController,
                      hintText: 'REFERENCE NUMBER',
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 32),

                    // Document Upload
                    Text(
                      'UPLOAD YOUR RC/NATIS DOCUMENTATION',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    buildDocumentUploadSection(),
                    const SizedBox(height: 32),

                    // Vehicle Details Section
                    Center(
                      child: Text(
                        'VEHICLE DETAILS',
                        style: _labelStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    CustomTextField(
                      controller: _brandController,
                      hintText: 'BRAND',
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _makeModelController,
                            hintText: 'MAKE/MODEL',
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _yearController,
                            hintText: 'YEAR',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Specifications Section
                    Center(
                      child: Text(
                        'SPECIFICATIONS',
                        style: _labelStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Mileage Input
                    Center(
                      child: Text(
                        'MILEAGE',
                        style: _bodyStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _mileageController,
                      hintText: 'Enter mileage in KM',
                      keyboardType: TextInputType.number,
                      inputFormatter: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 32),

                    // Configuration
                    Center(
                      child: Text(
                        'CONFIGURATION',
                        style: _bodyStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        border: Border(
                          left:
                              BorderSide(color: Colors.white.withOpacity(0.3)),
                          right:
                              BorderSide(color: Colors.white.withOpacity(0.3)),
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: configuration,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        dropdownColor: const Color.fromARGB(255, 59, 59, 59),
                        style: _bodyStyle,
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: '6X4', child: Text('6X4')),
                          DropdownMenuItem(value: '6X2', child: Text('6X2')),
                          DropdownMenuItem(value: '4X2', child: Text('4X2')),
                          DropdownMenuItem(value: '10X4', child: Text('10X4')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            configuration = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Vehicle Information
                    CustomTextField(
                      controller: _vinNumberController,
                      hintText: 'VIN NUMBER',
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 24),

                    CustomTextField(
                      controller: _engineNumberController,
                      hintText: 'ENGINE NO.',
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 24),

                    CustomTextField(
                      controller: _registrationNumberController,
                      hintText: 'REGISTRATION NO.',
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 24),

                    CustomTextField(
                      controller: _expectedSellingPriceController,
                      hintText: 'EXPECTED SELLING PRICE',
                      isCurrency: true,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),

                    // Technical Specifications
                    Center(
                      child: Text(
                        'TECHNICAL SPECIFICATIONS',
                        style: _labelStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Suspension
                    Center(
                      child: Text(
                        'SUSPENSION',
                        style: _bodyStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomRadioButton(
                            label: 'SPRING',
                            value: 'SPRING',
                            groupValue: suspension ?? '',
                            onChanged: (value) {
                              setState(() {
                                suspension = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomRadioButton(
                            label: 'COIL',
                            value: 'COIL',
                            groupValue: suspension ?? '',
                            onChanged: (value) {
                              setState(() {
                                suspension = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Transmission
                    Center(
                      child: Text(
                        'TRANSMISSION',
                        style: _bodyStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomRadioButton(
                            label: 'AUTOMATIC',
                            value: 'AUTOMATIC',
                            groupValue: transmission ?? '',
                            onChanged: (value) {
                              setState(() {
                                transmission = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomRadioButton(
                            label: 'MANUAL',
                            value: 'MANUAL',
                            groupValue: transmission ?? '',
                            onChanged: (value) {
                              setState(() {
                                transmission = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Additional Features
                    Center(
                      child: Text(
                        'ADDITIONAL FEATURES',
                        style: _labelStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Hydraulics
                    Center(
                      child: Text(
                        'HYDRAULICS',
                        style: _bodyStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    buildYesNoRadio('HYDRAULICS', hasHydraulics),
                    const SizedBox(height: 24),

                    // Maintenance
                    Center(
                      child: Text(
                        'MAINTENANCE',
                        style: _bodyStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    buildYesNoRadio('MAINTENANCE', hasMaintenance),
                    const SizedBox(height: 24),

                    // Warranty
                    Center(
                      child: Text(
                        'WARRANTY',
                        style: _bodyStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    buildYesNoRadio('WARRANTY', hasWarranty),
                    const SizedBox(height: 24),

                    if (hasWarranty == true) ...[
                      CustomTextField(
                        controller: _warrantyDetailsController,
                        hintText:
                            'WHAT TYPE OF WARRANTY DOES YOUR VEHICLE HAVE',
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Settlement
                    Center(
                      child: Text(
                        'DO YOU REQUIRE THE TRUCK TO BE SETTLED BEFORE SELLING',
                        style: _bodyStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    buildYesNoRadio('SETTLEMENT', requiresSettlement),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          try {
                            setState(() => isSaving = true);

                            // Prepare the form data
                            final formData = {
                              'vehicleType': vehicleType,
                              'brand': _brandController.text,
                              'makeModel': _makeModelController.text,
                              'year': _yearController.text,
                              'mileage': _mileageController.text,
                              'configuration': configuration,
                              'vinNumber': _vinNumberController.text,
                              'engineNumber': _engineNumberController.text,
                              'registrationNumber':
                                  _registrationNumberController.text,
                              'expectedSellingPrice':
                                  _expectedSellingPriceController.text,
                              'suspension': suspension,
                              'transmission': transmission,
                              'hasHydraulics': hasHydraulics,
                              'hasMaintenance': hasMaintenance,
                              'hasWarranty': hasWarranty,
                              'warrantyDetails': hasWarranty
                                  ? _warrantyDetailsController.text
                                  : null,
                              'requiresSettlement': requiresSettlement,
                              'referenceNumber':
                                  _referenceNumberController.text,
                              'status': 'draft',
                              'createdAt': FieldValue.serverTimestamp(),
                            };

                            // Upload cover photo if exists
                            final coverPhotoUrl = await _uploadCoverPhoto();
                            if (coverPhotoUrl != null) {
                              formData['coverPhotoUrl'] = coverPhotoUrl;
                            }

                            // Upload NATIS/RC1 file if exists
                            if (_natisRc1File != null) {
                              final natisUrl =
                                  await _vehicleFormService.uploadFile(
                                File(_natisRc1File!.path!),
                                'natis_documents',
                              );
                              formData['natisDocumentUrl'] = natisUrl;
                            }

                            // Save the form data and get the vehicle ID
                            final vehicleId = await _vehicleFormService
                                .saveVehicleForm(formData);

                            if (!mounted) return;

                            // Navigate to next page with vehicle ID
                            Navigator.pushNamed(
                              context,
                              '/maintenance',
                              arguments: {'vehicleId': vehicleId},
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error saving form: $e')),
                            );
                          } finally {
                            setState(() => isSaving = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'CONTINUE',
                          style: _labelStyle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildYesNoRadio(String field, bool value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomRadioButton(
          label: 'YES',
          value: 'true',
          groupValue: value.toString(),
          onChanged: (newValue) {
            setState(() {
              switch (field.toLowerCase()) {
                case 'hydraulics':
                  hasHydraulics = newValue == 'true';
                  break;
                case 'maintenance':
                  hasMaintenance = newValue == 'true';
                  break;
                case 'warranty':
                  hasWarranty = newValue == 'true';
                  break;
                case 'settlement':
                  requiresSettlement = newValue == 'true';
                  break;
              }
            });
          },
        ),
        const SizedBox(width: 15),
        CustomRadioButton(
          label: 'NO',
          value: 'false',
          groupValue: value.toString(),
          onChanged: (newValue) {
            setState(() {
              switch (field.toLowerCase()) {
                case 'hydraulics':
                  hasHydraulics = newValue == 'true';
                  break;
                case 'maintenance':
                  hasMaintenance = newValue == 'true';
                  break;
                case 'warranty':
                  hasWarranty = newValue == 'true';
                  break;
                case 'settlement':
                  requiresSettlement = newValue == 'true';
                  break;
              }
            });
          },
        ),
      ],
    );
  }

  Row buildVehicleTypeRadio() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomRadioButton(
          label: 'Truck',
          value: 'truck',
          groupValue: vehicleType ?? '',
          onChanged: (value) {
            setState(() {
              vehicleType = value;
            });
          },
        ),
        const SizedBox(width: 15),
        CustomRadioButton(
          label: 'Trailer',
          value: 'trailer',
          groupValue: vehicleType ?? '',
          onChanged: (value) {
            setState(() {
              vehicleType = value;
            });
          },
        ),
      ],
    );
  }
}
