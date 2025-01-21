// lib/screens/edit_profile_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:path/path.dart' as path;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _companyNameController;
  late TextEditingController _tradingNameController;
  late TextEditingController _addressLine1Controller;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  String? _profileImageUrl;
  String? _bankConfirmationUrl;
  String? _cipcCertificateUrl;
  String? _proxyUrl;
  String? _brncUrl;
  File? _profileImageFile;
  File? _bankConfirmationFile;
  File? _cipcCertificateFile;
  File? _proxyFile;
  File? _brncFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _firstNameController =
        TextEditingController(text: userProvider.getFirstName);
    _middleNameController =
        TextEditingController(text: userProvider.getMiddleName);
    _lastNameController = TextEditingController(text: userProvider.getLastName);
    _emailController = TextEditingController(text: userProvider.getUserEmail);
    _phoneNumberController =
        TextEditingController(text: userProvider.getPhoneNumber);
    _companyNameController =
        TextEditingController(text: userProvider.getCompanyName);
    _tradingNameController =
        TextEditingController(text: userProvider.getTradingName);
    _addressLine1Controller =
        TextEditingController(text: userProvider.getAddressLine1);
    _addressLine2Controller =
        TextEditingController(text: userProvider.getAddressLine2);
    _cityController = TextEditingController(text: userProvider.getCity);
    _stateController = TextEditingController(text: userProvider.getState);
    _postalCodeController =
        TextEditingController(text: userProvider.getPostalCode);
    _profileImageUrl = userProvider.getProfileImageUrl;
    _bankConfirmationUrl = userProvider.getBankConfirmationUrl;
    _cipcCertificateUrl = userProvider.getCipcCertificateUrl;
    _proxyUrl = userProvider.getProxyUrl;
    _brncUrl = userProvider.getBrncUrl;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _companyNameController.dispose();
    _tradingNameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  /// Picks a document file based on the field type.
  Future<void> _pickFile(String field) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
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

    if (result != null && result.files.single.path != null) {
      File selectedFile = File(result.files.single.path!);
      setState(() {
        switch (field) {
          case 'bankConfirmation':
            _bankConfirmationFile = selectedFile;
            _bankConfirmationUrl = null; // Reset existing URL
            break;
          case 'cipcCertificate':
            _cipcCertificateFile = selectedFile;
            _cipcCertificateUrl = null; // Reset existing URL
            break;
          case 'proxy':
            _proxyFile = selectedFile;
            _proxyUrl = null; // Reset existing URL
            break;
          case 'brnc':
            _brncFile = selectedFile;
            _brncUrl = null; // Reset existing URL
            break;
        }
      });
    }
  }

  /// Picks and processes the profile image.
  Future<void> _pickProfileImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        File? croppedFile = await _cropImage(File(pickedFile.path));
        if (croppedFile != null) {
          final compressedFile = await _compressImageFile(croppedFile);
          setState(() {
            _profileImageFile = compressedFile;
            _profileImageUrl = null; // Reset existing URL
          });
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Crops the selected image to a square aspect ratio.
  Future<File?> _cropImage(File imageFile) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop and Fit',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop and Fit',
        ),
      ],
    );

    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }

  /// Compresses the image file to reduce its size.
  Future<File> _compressImageFile(File file) async {
    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      file.absolute.path.replaceAll('.jpg', '_compressed.jpg'),
      quality: 70,
    );

    return compressedFile != null ? File(compressedFile.path) : file;
  }

  /// Determines the appropriate icon based on the file type.
  IconData _getIconForFileType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.xls':
      case '.xlsx':
        return Icons.table_chart;
      case '.jpg':
      case '.jpeg':
      case '.png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Extracts the file name from a given URL or path.
  String _getFileNameFromUrl(String url) {
    try {
      Uri uri = Uri.parse(url);
      return path.basename(uri.path);
    } catch (e) {
      // If parsing fails, fall back to the original file path
      return path.basename(url);
    }
  }

  /// Builds a text form field with validation.
  Widget _buildTextField(String label, TextEditingController controller,
      {bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white),
          hintText: label,
          hintStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.black.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(color: Colors.white),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  /// Builds a label for the upload section.
  Widget _buildUploadLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  /// Builds an upload button for documents.
  Widget _buildUploadButton(String field, String? fileUrl, File? file) {
    String? displayName;
    IconData iconData = Icons.folder_open;

    if (file != null) {
      displayName = path.basename(file.path);
      iconData = _getIconForFileType(file.path);
    } else if (fileUrl != null && fileUrl.isNotEmpty) {
      displayName = _getFileNameFromUrl(fileUrl);
      iconData = _getIconForFileType(fileUrl);
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _pickFile(field),
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.white70, width: 1),
            ),
            child: Center(
              child: displayName == null
                  ? const Icon(Icons.folder_open, color: Colors.blue, size: 40)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          iconData,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 5),
                        Flexible(
                          child: Text(
                            displayName,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (displayName != null)
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  switch (field) {
                    case 'bankConfirmation':
                      _bankConfirmationFile = null;
                      _bankConfirmationUrl = null;
                      break;
                    case 'cipcCertificate':
                      _cipcCertificateFile = null;
                      _cipcCertificateUrl = null;
                      break;
                    case 'proxy':
                      _proxyFile = null;
                      _proxyUrl = null;
                      break;
                    case 'brnc':
                      _brncFile = null;
                      _brncUrl = null;
                      break;
                  }
                });
              },
              child: const Icon(
                Icons.close,
                color: Colors.red,
                size: 24,
              ),
            ),
          ),
      ],
    );
  }

  /// Saves the profile by uploading files to Firebase Storage and updating Firestore.
  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      String? profileImageUrl;

      // Upload Profile Image if a new one is selected
      if (_profileImageFile != null) {
        try {
          profileImageUrl = await userProvider.uploadFile(_profileImageFile!);
        } catch (e) {
          debugPrint('Error uploading profile image: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading profile image: $e')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      // Upload Documents and get their download URLs
      String? bankConfirmationDownloadUrl;
      String? cipcCertificateDownloadUrl;
      String? proxyDownloadUrl;
      String? brncDownloadUrl;

      try {
        if (_bankConfirmationFile != null) {
          bankConfirmationDownloadUrl =
              await userProvider.uploadFile(_bankConfirmationFile!);
        }

        if (_cipcCertificateFile != null) {
          cipcCertificateDownloadUrl =
              await userProvider.uploadFile(_cipcCertificateFile!);
        }

        if (_proxyFile != null) {
          proxyDownloadUrl = await userProvider.uploadFile(_proxyFile!);
        }

        if (_brncFile != null) {
          brncDownloadUrl = await userProvider.uploadFile(_brncFile!);
        }
      } catch (e) {
        debugPrint('Error uploading documents: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading documents: $e')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      try {
        await userProvider.updateUserProfile(
          firstName: _firstNameController.text,
          middleName: _middleNameController.text,
          lastName: _lastNameController.text,
          email: _emailController.text,
          phoneNumber: _phoneNumberController.text,
          companyName: _companyNameController.text,
          tradingName: _tradingNameController.text,
          addressLine1: _addressLine1Controller.text,
          addressLine2: _addressLine2Controller.text,
          city: _cityController.text,
          state: _stateController.text,
          postalCode: _postalCodeController.text,
          profileImageUrl: profileImageUrl ?? _profileImageUrl,
          bankConfirmationUrl:
              bankConfirmationDownloadUrl ?? _bankConfirmationUrl,
          cipcCertificateUrl: cipcCertificateDownloadUrl ?? _cipcCertificateUrl,
          proxyUrl: proxyDownloadUrl ?? _proxyUrl,
          brncUrl: brncDownloadUrl ?? _brncUrl,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error saving profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var orange = const Color(0xFFFF4E00);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String currentUserRole =
        userProvider.getUserRole.toLowerCase(); // Ensure lowercase
    // Hide document uploads for admin and sales representative roles.
    final bool hideDocumentUploads =
        currentUserRole == 'admin' || currentUserRole == 'sales representative';

    return Scaffold(
      body: Stack(
        children: [
          GradientBackground(
            child: Column(
              children: [
                const BlurryAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            Stack(
                              children: [
                                GestureDetector(
                                  onTap: _pickProfileImage,
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundImage: _profileImageFile != null
                                        ? FileImage(_profileImageFile!)
                                        : (_profileImageUrl != null
                                            ? NetworkImage(_profileImageUrl!)
                                            : null),
                                    child: _profileImageFile == null &&
                                            _profileImageUrl == null
                                        ? const Icon(Icons.camera_alt,
                                            size: 60, color: Colors.white)
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _pickProfileImage,
                                    child: const CircleAvatar(
                                      backgroundColor: Colors.white,
                                      radius: 18,
                                      child:
                                          Icon(Icons.edit, color: Colors.black),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildTextField('First Name', _firstNameController),
                            _buildTextField(
                                'Middle Name', _middleNameController,
                                isRequired: false),
                            _buildTextField('Last Name', _lastNameController),
                            _buildTextField('Email', _emailController),
                            _buildTextField(
                                'Phone Number', _phoneNumberController),
                            _buildTextField(
                                'Company Name', _companyNameController),
                            _buildTextField(
                                'Trading Name', _tradingNameController),
                            _buildTextField(
                                'Address Line 1', _addressLine1Controller),
                            _buildTextField(
                                'Address Line 2', _addressLine2Controller,
                                isRequired: false),
                            _buildTextField('City', _cityController),
                            _buildTextField(
                                'State/Province/Region', _stateController),
                            _buildTextField(
                                'Postal Code', _postalCodeController),
                            const SizedBox(height: 20),
                            // Document upload section is displayed only if hideDocumentUploads is false.
                            if (!hideDocumentUploads) ...[
                              const Text(
                                'Upload Documents',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildUploadLabel('Bank Confirmation'),
                              _buildUploadButton('bankConfirmation',
                                  _bankConfirmationUrl, _bankConfirmationFile),
                              const SizedBox(height: 15),
                              // Only show the CIPC Certificate upload if the user is not a transporter.
                              if (currentUserRole != 'transporter') ...[
                                _buildUploadLabel('CIPC Certificate'),
                                _buildUploadButton('cipcCertificate',
                                    _cipcCertificateUrl, _cipcCertificateFile),
                                const SizedBox(height: 15),
                              ],
                              _buildUploadLabel('Proxy'),
                              _buildUploadButton(
                                  'proxy', _proxyUrl, _proxyFile),
                              const SizedBox(height: 15),
                              _buildUploadLabel('BRNC'),
                              _buildUploadButton('brnc', _brncUrl, _brncFile),
                              const SizedBox(height: 30),
                            ],
                            CustomButton(
                              text: _isLoading ? 'Saving...' : 'Save',
                              borderColor: orange,
                              onPressed: _isLoading ? () {} : _saveProfile,
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            top: 40,
            left: 16,
            child: CustomBackButton(),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF4E00),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
