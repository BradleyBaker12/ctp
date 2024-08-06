import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/custom_back_button.dart';

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
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _profileImageFile = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
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
                                const Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 18,
                                    child:
                                        Icon(Icons.edit, color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildTextField('First Name', _firstNameController),
                            _buildTextField(
                                'Middle Name', _middleNameController),
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
                                'Address Line 2', _addressLine2Controller),
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
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
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
          if (value == null || value.isEmpty) {
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
    return GestureDetector(
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
              : Text(
                  fileUrl,
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      String? profileImageUrl;

      if (_profileImageFile != null) {
        profileImageUrl = await userProvider.uploadFile(_profileImageFile!);
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
          bankConfirmationUrl: _bankConfirmationUrl,
          cipcCertificateUrl: _cipcCertificateUrl,
          proxyUrl: _proxyUrl,
          brncUrl: _brncUrl,
        );
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
