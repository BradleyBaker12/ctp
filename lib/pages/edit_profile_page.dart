import 'dart:io';
import 'dart:typed_data';
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
  File? _profileImageFile;
  Uint8List? _profileImageBytes;
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

  Future<void> _pickFile(String field) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      String? fileUrl = result.files.single.path;
      setState(() {
        switch (field) {
          case 'bankConfirmation':
            _bankConfirmationUrl = fileUrl;
            break;
          case 'cipcCertificate':
            _cipcCertificateUrl = fileUrl;
            break;
          case 'proxy':
            _proxyUrl = fileUrl;
            break;
          case 'brnc':
            _brncUrl = fileUrl;
            break;
        }
      });
    }
  }

  Future<void> _pickProfileImage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile =
          await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        CroppedFile? croppedFile = await _cropImage(File(pickedFile.path));
        if (croppedFile != null) {
          if (kIsWeb) {
            // On Web: Read bytes
            final bytes = await croppedFile.readAsBytes();
            final compressedBytes = await _compressImageBytes(bytes);
            setState(() {
              _profileImageBytes = compressedBytes;
              _profileImageFile = null; // Ensure FileImage is not used on web
            });
          } else {
            // On Mobile: Handle File
            File? compressedFile =
                await _compressImageFile(File(croppedFile.path));
            setState(() {
              _profileImageFile = compressedFile;
              _profileImageBytes =
                  null; // Ensure MemoryImage is not used on mobile
            });
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<CroppedFile?> _cropImage(File imageFile) async {
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
          size: CropperSize(width: 520, height: 520),
          background: true,
          movable: true,
          scalable: true,
          zoomable: true,
        ),
      ],
    );

    if (croppedFile != null) {
      return croppedFile;
    }
    return null;
  }

  Future<Uint8List> _compressImageBytes(Uint8List bytes) async {
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      quality: 70,
    );
    return result;
  }

  Future<File> _compressImageFile(File file) async {
    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      file.absolute.path.replaceAll('.jpg', '_compressed.jpg'),
      quality: 70,
    );

    return compressedFile != null ? File(compressedFile.path) : file;
  }

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
                                    backgroundImage: kIsWeb
                                        ? (_profileImageBytes != null
                                            ? MemoryImage(_profileImageBytes!)
                                                as ImageProvider
                                            : (_profileImageUrl != null &&
                                                    _profileImageUrl!.isNotEmpty
                                                ? NetworkImage(
                                                    _profileImageUrl!)
                                                : null))
                                        : (_profileImageFile != null
                                            ? FileImage(_profileImageFile!)
                                            : (_profileImageUrl != null &&
                                                    _profileImageUrl!.isNotEmpty
                                                ? NetworkImage(
                                                    _profileImageUrl!)
                                                : null)),
                                    backgroundColor: Colors.transparent,
                                    child: (kIsWeb
                                            ? (_profileImageBytes == null &&
                                                (_profileImageUrl == null ||
                                                    _profileImageUrl!.isEmpty))
                                            : (_profileImageFile == null &&
                                                (_profileImageUrl == null ||
                                                    _profileImageUrl!.isEmpty)))
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
                                'bankConfirmation', _bankConfirmationUrl),
                            const SizedBox(height: 15),
                            _buildUploadLabel('CIPC Certificate'),
                            _buildUploadButton(
                                'cipcCertificate', _cipcCertificateUrl),
                            const SizedBox(height: 15),
                            _buildUploadLabel('Proxy'),
                            _buildUploadButton('proxy', _proxyUrl),
                            const SizedBox(height: 15),
                            _buildUploadLabel('BRNC'),
                            _buildUploadButton('brnc', _brncUrl),
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

  Widget _buildUploadButton(String field, String? fileUrl) {
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
              child: fileUrl == null
                  ? const Icon(Icons.folder_open, color: Colors.blue, size: 40)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getIconForFileType(fileUrl),
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 5),
                        Flexible(
                          child: Text(
                            _getFileNameFromUrl(
                                fileUrl), // Extracting the file name from URL or path
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
        if (fileUrl != null)
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  switch (field) {
                    case 'bankConfirmation':
                      _bankConfirmationUrl = null;
                      break;
                    case 'cipcCertificate':
                      _cipcCertificateUrl = null;
                      break;
                    case 'proxy':
                      _proxyUrl = null;
                      break;
                    case 'brnc':
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

  String _getFileNameFromUrl(String url) {
    // Use Uri to parse the URL and get the last segment
    try {
      Uri uri = Uri.parse(url);
      return path.basename(uri.path);
    } catch (e) {
      // If parsing fails, fall back to the original fileUrl
      return path.basename(url);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      String? profileImageUrl;

      try {
        if (kIsWeb) {
          if (_profileImageBytes != null) {
            profileImageUrl =
                await userProvider.uploadBytes(_profileImageBytes!);
          }
        } else {
          if (_profileImageFile != null) {
            profileImageUrl = await userProvider.uploadFile(_profileImageFile!);
          }
        }

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
          bankConfirmationUrl: _bankConfirmationUrl,
          cipcCertificateUrl: _cipcCertificateUrl,
          proxyUrl: _proxyUrl,
          brncUrl: _brncUrl,
        );

        // Optionally update local state to reflect the new image
        if (profileImageUrl != null) {
          setState(() {
            _profileImageUrl = profileImageUrl;
            _profileImageFile = null;
            _profileImageBytes = null;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
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
}
