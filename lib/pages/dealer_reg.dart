import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
// Import the HouseRulesPage
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class DealerRegPage extends StatefulWidget {
  const DealerRegPage({super.key});

  @override
  _DealerRegPageState createState() => _DealerRegPageState();
}

class _DealerRegPageState extends State<DealerRegPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _tradingNameController = TextEditingController();
  final TextEditingController _registrationNumberController =
      TextEditingController();
  final TextEditingController _vatNumberController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  String? _bankConfirmationFile;
  String? _cipcCertificateFile;
  String? _proxyFile;
  String? _brncFile;
  bool _isLoading = false;

  Future<void> _pickFile(String fieldName) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        setState(() {
          if (fieldName == 'bankConfirmation') {
            _bankConfirmationFile = result.files.single.path;
          } else if (fieldName == 'cipcCertificate') {
            _cipcCertificateFile = result.files.single.path;
          } else if (fieldName == 'proxy') {
            _proxyFile = result.files.single.path;
          } else if (fieldName == 'brnc') {
            _brncFile = result.files.single.path;
          }
        });
      }
    } catch (e) {
      print("Error picking file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userId!;
      final FirebaseStorage storage = FirebaseStorage.instance;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      Future<String> uploadFile(String filePath, String fileName) async {
        final ref = storage.ref().child('documents/$userId/$fileName');
        final task = ref.putFile(File(filePath));
        final snapshot = await task;
        return await snapshot.ref.getDownloadURL();
      }

      final bankConfirmationUrl = _bankConfirmationFile != null
          ? await uploadFile(_bankConfirmationFile!, 'bank_confirmation.pdf')
          : null;
      final cipcCertificateUrl = _cipcCertificateFile != null
          ? await uploadFile(_cipcCertificateFile!, 'cipc_certificate.pdf')
          : null;
      final proxyUrl = _proxyFile != null
          ? await uploadFile(_proxyFile!, 'proxy.pdf')
          : null;
      final brncUrl =
          _brncFile != null ? await uploadFile(_brncFile!, 'brnc.pdf') : null;

      await firestore.collection('users').doc(userId).update({
        'companyName': _companyNameController.text,
        'tradingName': _tradingNameController.text,
        'registrationNumber': _registrationNumberController.text,
        'vatNumber': _vatNumberController.text,
        'firstName': _firstNameController.text,
        'middleName': _middleNameController.text,
        'lastName': _lastNameController.text,
        'addressLine1': _addressLine1Controller.text,
        'addressLine2': _addressLine2Controller.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'postalCode': _postalCodeController.text,
        'bankConfirmationUrl': bankConfirmationUrl,
        'cipcCertificateUrl': cipcCertificateUrl,
        'proxyUrl': proxyUrl,
        'brncUrl': brncUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration completed successfully!')),
      );
      Navigator.pushReplacementNamed(
          context, '/houseRules'); // Navigate to the house rules page
    } catch (e) {
      print("Error submitting form: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting form: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Center(
                            child: Image.asset('lib/assets/CTPLogo.png',
                                height: 100), // Adjust the height as needed
                          ),
                          const SizedBox(height: 20),
                          const Center(
                            child: Text(
                              'DEALER REGISTRATION',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Center(
                            child: Text(
                              'Fill out the form carefully to register.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Center(
                            child: Text(
                              'CTP Offers a way for you to sell your vehicle to multiple dealers in SA.\nCTP\'s fees are R12500,00 flat fee.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'COMPANY NAME *',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 5),
                                _buildTextField(
                                    controller: _companyNameController,
                                    hintText: 'Company Name'),
                                const SizedBox(height: 15),
                                const Text(
                                  'TRADING NAME *',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 5),
                                _buildTextField(
                                    controller: _tradingNameController,
                                    hintText: 'Trading Name'),
                                const SizedBox(height: 15),
                                const Text(
                                  'REGISTRATION NUMBER *',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 5),
                                _buildTextField(
                                    controller: _registrationNumberController,
                                    hintText: 'Registration Number'),
                                const SizedBox(height: 15),
                                const Text(
                                  'VAT NUMBER *',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 5),
                                _buildTextField(
                                    controller: _vatNumberController,
                                    hintText: 'VAT Number'),
                                const SizedBox(height: 15),
                                const Text(
                                  'DEALER PERSONAL DETAILS *',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 5),
                                _buildTextField(
                                    controller: _firstNameController,
                                    hintText: 'First'),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _middleNameController,
                                    hintText: 'Middle (Optional)'),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _lastNameController,
                                    hintText: 'Last'),
                                const SizedBox(height: 15),
                                const Text(
                                  'ADDRESS',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 5),
                                _buildTextField(
                                    controller: _addressLine1Controller,
                                    hintText: 'Address Line 1'),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _addressLine2Controller,
                                    hintText: 'Address Line 2'),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _cityController,
                                    hintText: 'City'),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _stateController,
                                    hintText: 'State/Province/Region'),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _postalCodeController,
                                    hintText: 'Postal Code'),
                                const SizedBox(height: 30),
                                const Text(
                                  'DOCUMENT UPLOADS',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'BANK CONFIRMATION',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 5),
                                _buildUploadButton(
                                    'bankConfirmation', _bankConfirmationFile),
                                const SizedBox(height: 15),
                                const Text(
                                  'CIPC CERTIFICATE',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 5),
                                _buildUploadButton(
                                    'cipcCertificate', _cipcCertificateFile),
                                const SizedBox(height: 15),
                                const Text(
                                  'PROXY',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 5),
                                _buildUploadButton('proxy', _proxyFile),
                                const SizedBox(height: 15),
                                const Text(
                                  'BRNC',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 5),
                                _buildUploadButton('brnc', _brncFile),
                                const SizedBox(height: 30),
                                Center(
                                  child: CustomButton(
                                    text:
                                        _isLoading ? 'Submitting...' : 'SUBMIT',
                                    borderColor: orange,
                                    onPressed: _isLoading ? () {} : _submitForm,
                                  ),
                                ),
                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildTextField(
      {required TextEditingController controller, required String hintText}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
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
          return 'Please enter $hintText';
        }
        return null;
      },
    );
  }

  Widget _buildUploadButton(String fieldName, String? fileName) {
    return GestureDetector(
      onTap: () => _pickFile(fieldName),
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: Colors.white70, width: 1),
        ),
        child: Center(
          child: fileName == null
              ? const Icon(Icons.folder_open, color: Colors.blue, size: 40)
              : Text(
                  fileName,
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ),
    );
  }
}
