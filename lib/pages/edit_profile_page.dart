// lib/screens/edit_profile_page.dart

import 'dart:developer';
import 'dart:io';
import 'package:ctp/pages/profile_page.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb checks
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
import 'package:ctp/utils/navigation.dart';

import 'package:auto_route/auto_route.dart';
@RoutePage()class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers
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

  // Existing Firestore document URLs
  String? _profileImageUrl;
  String? _bankConfirmationUrl;
  String? _cipcCertificateUrl;
  String? _proxyUrl;
  String? _brncUrl;

  // In-memory files (Uint8List) + filenames for new uploads
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

    // Pre-fill text fields from existing user data
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

    // Existing file URLs (if any)
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
    // Dispose all controllers
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
    setState(() => _isLoading = true);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

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
      setState(() => _isLoading = false);
    }
  }

  /// Crops the selected image to a square aspect ratio; returns Uint8List on success.
  Future<Uint8List?> _cropImage(File imageFile) async {
    CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop and Fit',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop and Fit',
        ),
        // Web fix to ensure cropping works in browser.
        WebUiSettings(
          context: context,
          presentStyle: WebPresentStyle.dialog,
          size: const CropperSize(width: 200, height: 200),
          initialAspectRatio: 1, // square
          dragMode: WebDragMode.crop,
          center: true,
          highlight: true,
          cropBoxResizable: false,
        ),
      ],
    );

    if (cropped != null) {
      return await cropped.readAsBytes();
    }
    return null;
  }

  /// Compresses an in‑memory image's bytes, returning a smaller Uint8List.
  Future<Uint8List?> _compressImageFile(Uint8List imageBytes) async {
    return await FlutterImageCompress.compressWithList(
      imageBytes,
      minWidth: 800,
      minHeight: 600,
      quality: 70,
      format: CompressFormat.jpeg,
    );
  }

  /// Returns an icon for the file type (e.g., PDF vs. PNG).
  /// Also trims query strings from the extension if present.
  IconData _getIconForFileType(String fileName) {
    final extension =
        path.extension(fileName).toLowerCase().trim().split('?').first.trim();
    log("Extensions are $extension");

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

  /// Gets just the basename of a URL path, e.g. "myfile.pdf"
  String _getFileNameFromUrl(String url) {
    try {
      Uri uri = Uri.parse(url);
      return path.basename(uri.path);
    } catch (_) {
      return path.basename(url);
    }
  }

  /// Builds a text form field with default validation for required fields.
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: label,
          labelStyle: const TextStyle(color: Colors.white),
          hintStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.black.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  /// A smaller label heading for each file upload section.
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

  /// Renders either an "open folder" icon or an icon + the file name.
  /// On tap, user can pick a new file. A close button clears the file.
  Widget _buildUploadButton(String field, String? fileUrl, String? fileName) {
    String? displayName;
    IconData iconData = Icons.folder_open;

    if (fileName != null) {
      // We have a newly picked file in memory
      displayName = fileName;
      iconData = _getIconForFileType(fileName);
      log("Display name: $displayName");
    } else if (fileUrl != null && fileUrl.isNotEmpty) {
      // Using existing URL from Firestore
      displayName = _getFileNameFromUrl(fileUrl);
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
                  ? const Icon(
                      Icons.folder_open,
                      color: Colors.blue,
                      size: 40,
                    )
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
                            maxLines: 2, // allow wrapping
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

  /// Saves profile changes to Firestore and/or Storage.
  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // 1) Upload new profile image if selected
    String? profileImageUrl;
    if (_profileImageFile != null && _profileImageFileName != null) {
      try {
        profileImageUrl = await userProvider.uploadFile(
          _profileImageFile!,
          _profileImageFileName!,
        );
      } catch (e) {
        debugPrint('Error uploading profile image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading profile image: $e')),
        );
        setState(() => _isLoading = false);
        return;
      }
    }

    // 2) Upload documents if newly selected
    String? bankConfirmationDownloadUrl;
    String? cipcCertificateDownloadUrl;
    String? proxyDownloadUrl;
    String? brncDownloadUrl;

    try {
      if (_bankConfirmationFile != null && _bankConfirmationFileName != null) {
        bankConfirmationDownloadUrl = await userProvider.uploadFile(
          _bankConfirmationFile!,
          _bankConfirmationFileName!,
        );
        setState(() {});
      }
      if (_cipcCertificateFile != null && _cipcCertificateFileName != null) {
        cipcCertificateDownloadUrl = await userProvider.uploadFile(
          _cipcCertificateFile!,
          _cipcCertificateFileName!,
        );
        setState(() {});
      }
      if (_proxyFile != null && _proxyFileName != null) {
        proxyDownloadUrl = await userProvider.uploadFile(
          _proxyFile!,
          _proxyFileName!,
        );
        setState(() {});
      }
      if (_brncFile != null && _brncFileName != null) {
        brncDownloadUrl = await userProvider.uploadFile(
          _brncFile!,
          _brncFileName!,
        );
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error uploading documents: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading documents: $e')),
      );
      setState(() => _isLoading = false);
      return;
    }

    // 3) Update user data in Firestore
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

      // Navigate to ProfilePage instead of popping
      await MyNavigator.pushReplacement(
        context,
        ProfilePage(),
      );
    } catch (e) {
      debugPrint('Error saving profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF4E00);

    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          GradientBackground(
            child: Column(
              children: [
                const BlurryAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            // Profile pic
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
                                    child: (_profileImageFile == null &&
                                            _profileImageUrl == null)
                                        ? const Icon(
                                            Icons.camera_alt,
                                            size: 60,
                                            color: Colors.white,
                                          )
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
                                      child: Icon(
                                        Icons.edit,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildTextField('First Name', _firstNameController),
                            _buildTextField(
                              'Middle Name',
                              _middleNameController,
                              isRequired: false,
                            ),
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
                              'Address Line 2',
                              _addressLine2Controller,
                              isRequired: false,
                            ),
                            _buildTextField('City', _cityController),
                            _buildTextField(
                              'State/Province/Region',
                              _stateController,
                            ),
                            _buildTextField(
                              'Postal Code',
                              _postalCodeController,
                            ),
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
                              _bankConfirmationFileName,
                            ),
                            const SizedBox(height: 15),
                            _buildUploadLabel('CIPC Certificate'),
                            _buildUploadButton(
                              'cipcCertificate',
                              _cipcCertificateUrl,
                              _cipcCertificateFileName,
                            ),
                            const SizedBox(height: 15),
                            _buildUploadLabel('Proxy'),
                            _buildUploadButton(
                              'proxy',
                              _proxyUrl,
                              _proxyFileName,
                            ),
                            const SizedBox(height: 15),
                            _buildUploadLabel('BRNC'),
                            _buildUploadButton(
                              'brnc',
                              _brncUrl,
                              _brncFileName,
                            ),
                            const SizedBox(height: 30),
                            CustomButton(
                              text: _isLoading ? 'Saving...' : 'Save',
                              borderColor: orange,
                              onPressed: _isLoading ? null : _saveProfile,
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
          // Custom back button
          const Positioned(
            top: 40,
            left: 16,
            child: CustomBackButton(),
          ),
          // Loading overlay
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
