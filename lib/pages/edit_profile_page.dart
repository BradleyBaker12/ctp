// lib/screens/edit_profile_page.dart

import 'dart:developer';
import 'dart:io';
import 'package:ctp/pages/profile_page.dart';
import 'package:ctp/utils/navigation.dart';
import 'package:flutter/foundation.dart';
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
  Uint8List? _profileImageFile;
  Uint8List? _bankConfirmationFile;
  Uint8List? _cipcCertificateFile;
  Uint8List? _proxyFile;
  Uint8List? _brncFile;
  String? _profileImageFileName;
  String? _bankConfirmationFileName;
  String? _cipcCertificateFileName;
  String? _proxyFileName;
  String? _brncFileName;
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
    print("_bankConfirmationUrl : $_bankConfirmationUrl");
    print("_bankConfirmationUrl1 : $_cipcCertificateUrl");
    print("_bankConfirmationUrl2 : $_proxyUrl");
    print("_bankConfirmationUrl3 : $_brncUrl");
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
    print("result: $result");

    if (result != null) {
      String selectedFileName = result.files.single.name;
      Uint8List? selectedFile = kIsWeb
          ? result.files.single.bytes
          : await File(result.files.single.path!).readAsBytes();
      // String? selectedFilePath = result.files.single.path;
      print("SelectedFileName: $selectedFileName");
      print("SelectedFile: $selectedFile");

      setState(() {
        switch (field) {
          case 'bankConfirmation':
            _bankConfirmationFile = selectedFile;
            _bankConfirmationFileName = selectedFileName;
            _bankConfirmationUrl = null; // Reset existing URL
            print("bank confirmation executed ------------------------");
            break;
          case 'cipcCertificate':
            _cipcCertificateFile = selectedFile;
            _cipcCertificateFileName = selectedFileName;
            _cipcCertificateUrl = null; // Reset existing URL
            print("cipc certificate executed ------------------------");
            break;
          case 'proxy':
            _proxyFile = selectedFile;
            _proxyFileName = selectedFileName;
            _proxyUrl = null; // Reset existing URL
            print("proxy executed ------------------------");
            break;
          case 'brnc':
            _brncFile = selectedFile;
            _brncFileName = selectedFileName;
            _brncUrl = null; // Reset existing URL
            print("brnc executed ------------------------");
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
        _profileImageFileName = pickedFile.name;
        final data = await pickedFile.readAsBytes();
        Uint8List? croppedFile = await _cropImage(File(pickedFile.path));

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
  Future<Uint8List?> _cropImage(File imageFile) async {
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
        WebUiSettings(
          context: context,
          presentStyle: WebPresentStyle.dialog,
          size: const CropperSize(width: 200, height: 200),
          initialAspectRatio: 1, // Square aspect ratio
          dragMode: WebDragMode.crop, // Set to crop mode
          center: true, // Center the image in the crop box
          highlight: true, // Highlight the crop box
          cropBoxResizable: false,
        ),
      ],
    );

    if (croppedFile != null) {
      final Uint8List croppedBytes = await croppedFile.readAsBytes();

      return croppedBytes;
    }
    return null;
  }

  /// Compresses the image file to reduce its size.
  Future<Uint8List?> _compressImageFile(Uint8List imageBytes) async {
    final Uint8List compressedBytes =
        await FlutterImageCompress.compressWithList(
      imageBytes,
      minWidth: 800,
      minHeight: 600,
      quality: 70,
      format: CompressFormat.jpeg,
    );
    return compressedBytes;
  }

  /// Determines the appropriate icon based on the file type.
  IconData _getIconForFileType(String fileName) {
    final extension =
        path.extension(fileName).toLowerCase().trim().split("?").first.trim();
    log("Extensions are ${extension}");
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
  Widget _buildUploadButton(String field, String? fileUrl, String? fileName) {
    String? displayName;
    IconData iconData = Icons.folder_open;

    if (fileName != null) {
      // displayName = path.basename(file.path);
      displayName = fileName;
      iconData = _getIconForFileType(fileName);
      log("Display name: $displayName");
    } else if (fileUrl != null && fileUrl.isNotEmpty) {
      log("File name $fileUrl");
      displayName = _getFileNameFromUrl(fileUrl);
      // displayName = _getFileNameFromUrl(fileUrl);
      iconData = _getIconForFileType(fileUrl);
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            _pickFile(field);
          },
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
                            maxLines: 2,
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
                      _bankConfirmationFileName = null;
                      _bankConfirmationUrl = null;
                      break;
                    case 'cipcCertificate':
                      _cipcCertificateFile = null;
                      _cipcCertificateFileName = null;
                      _cipcCertificateUrl = null;
                      break;
                    case 'proxy':
                      _proxyFile = null;
                      _proxyFileName = null;
                      _proxyUrl = null;
                      break;
                    case 'brnc':
                      _brncFile = null;
                      _brncFileName = null;
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
          profileImageUrl = await userProvider.uploadFile(
              _profileImageFile!, _profileImageFileName!);
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
          bankConfirmationDownloadUrl = await userProvider.uploadFile(
              _bankConfirmationFile!, _bankConfirmationFileName!);
          setState(() {});
        }

        if (_cipcCertificateFile != null) {
          cipcCertificateDownloadUrl = await userProvider.uploadFile(
              _cipcCertificateFile!, _cipcCertificateFileName!);
          setState(() {});
        }

        if (_proxyFile != null) {
          proxyDownloadUrl =
              await userProvider.uploadFile(_proxyFile!, _proxyFileName!);
          setState(() {});
        }

        if (_brncFile != null) {
          brncDownloadUrl =
              await userProvider.uploadFile(_brncFile!, _brncFileName!);
          setState(() {});
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
        await MyNavigator.pushReplacement(
          context,
          const ProfilePage(),
        );
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
                                        ? MemoryImage(_profileImageFile!)
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
                            _buildUploadButton(
                                'bankConfirmation',
                                _bankConfirmationUrl,
                                _bankConfirmationFileName),
                            const SizedBox(height: 15),
                            _buildUploadLabel('CIPC Certificate'),
                            _buildUploadButton('cipcCertificate',
                                _cipcCertificateUrl, _cipcCertificateFileName),
                            const SizedBox(height: 15),
                            _buildUploadLabel('Proxy'),
                            _buildUploadButton(
                                'proxy', _proxyUrl, _proxyFileName),
                            const SizedBox(height: 15),
                            _buildUploadLabel('BRNC'),
                            _buildUploadButton('brnc', _brncUrl, _brncFileName),
                            const SizedBox(height: 30),
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
