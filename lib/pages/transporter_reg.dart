import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;

class TransporterRegistrationPage extends StatefulWidget {
  const TransporterRegistrationPage({super.key});

  @override
  _TransporterRegistrationPageState createState() =>
      _TransporterRegistrationPageState();
}

class _TransporterRegistrationPageState
    extends State<TransporterRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

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

  final FocusNode _companyNameFocusNode = FocusNode();
  final FocusNode _tradingNameFocusNode = FocusNode();
  final FocusNode _registrationNumberFocusNode = FocusNode();
  final FocusNode _vatNumberFocusNode = FocusNode();
  final FocusNode _firstNameFocusNode = FocusNode();
  final FocusNode _middleNameFocusNode = FocusNode();
  final FocusNode _lastNameFocusNode = FocusNode();
  final FocusNode _addressLine1FocusNode = FocusNode();
  final FocusNode _addressLine2FocusNode = FocusNode();
  final FocusNode _cityFocusNode = FocusNode();
  final FocusNode _stateFocusNode = FocusNode();
  final FocusNode _postalCodeFocusNode = FocusNode();

  String? _bankConfirmationFile;
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

    // Check if all required files are uploaded
    if (_bankConfirmationFile == null ||
        _proxyFile == null ||
        _brncFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents.')),
      );
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

      final bankConfirmationUrl =
          await uploadFile(_bankConfirmationFile!, 'bank_confirmation.pdf');
      final proxyUrl = await uploadFile(_proxyFile!, 'proxy.pdf');
      final brncUrl = await uploadFile(_brncFile!, 'brnc.pdf');

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
        'proxyUrl': proxyUrl,
        'brncUrl': brncUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration completed successfully!')),
      );
      Navigator.pushReplacementNamed(context,
          '/firstTruckForm'); // Navigate to the first truck upload form page
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
                    controller: _scrollController,
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
                          Center(
                            child: Text(
                              'TRANSPORTER REGISTRATION',
                              style: GoogleFonts.montserrat(
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
                              'Fill out the form carefully to register.',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              'CTP Offers a way for you to sell your vehicle to multiple dealers in SA.\nCTP\'s fees are R12500,00 flat fee.',
                              style: GoogleFonts.montserrat(
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
                                _buildTextField(
                                    controller: _companyNameController,
                                    focusNode: _companyNameFocusNode,
                                    hintText: 'Company Name'),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _tradingNameController,
                                    focusNode: _tradingNameFocusNode,
                                    hintText: 'Trading Name'),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _registrationNumberController,
                                    focusNode: _registrationNumberFocusNode,
                                    hintText: 'Registration Number',
                                    validator: _validateRegistrationNumber),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _vatNumberController,
                                    focusNode: _vatNumberFocusNode,
                                    hintText: 'VAT Number',
                                    validator: _validateVATNumber),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _firstNameController,
                                    focusNode: _firstNameFocusNode,
                                    hintText: 'First'),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _middleNameController,
                                    focusNode: _middleNameFocusNode,
                                    hintText: 'Middle (Optional)',
                                    isOptional: true),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _lastNameController,
                                    focusNode: _lastNameFocusNode,
                                    hintText: 'Last'),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _addressLine1Controller,
                                    focusNode: _addressLine1FocusNode,
                                    hintText: 'Address Line 1'),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _addressLine2Controller,
                                    focusNode: _addressLine2FocusNode,
                                    hintText: 'Address Line 2',
                                    isOptional: true),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _cityController,
                                    focusNode: _cityFocusNode,
                                    hintText: 'City'),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _stateController,
                                    focusNode: _stateFocusNode,
                                    hintText: 'State/Province/Region'),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _postalCodeController,
                                    focusNode: _postalCodeFocusNode,
                                    hintText: 'Postal Code'),
                                const SizedBox(height: 30),
                                Text(
                                  'DOCUMENT UPLOADS',
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'BANK CONFIRMATION *',
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 5),
                                _buildUploadButton(
                                    'bankConfirmation', _bankConfirmationFile),
                                const SizedBox(height: 15),
                                Text(
                                  'PROXY *',
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 5),
                                _buildUploadButton('proxy', _proxyFile),
                                const SizedBox(height: 15),
                                Text(
                                  'BRNC *',
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required FocusNode focusNode,
    bool isOptional = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.montserrat(color: Colors.white70),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.2), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.5), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
      style: GoogleFonts.montserrat(color: Colors.white),
      validator: (value) {
        if (validator != null) {
          final validationError = validator(value);
          if (validationError != null) {
            _scrollToFocusNode(focusNode);
            return validationError;
          }
        }
        if (!isOptional && (value == null || value.isEmpty)) {
          _scrollToFocusNode(focusNode);
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
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getIconForFileType(fileName),
                        color: Colors.white, size: 40),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        path.basename(fileName),
                        style: GoogleFonts.montserrat(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
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

  String? _validateRegistrationNumber(String? value) {
    // Regex for South African Company Registration Number YYYY/NNNNNN/NN
    final regExp = RegExp(r'^\d{4}/\d{6}/\d{2}$');
    if (value == null || value.isEmpty) {
      _scrollToFocusNode(_registrationNumberFocusNode);
      return 'Please enter Registration Number';
    } else if (!regExp.hasMatch(value)) {
      _scrollToFocusNode(_registrationNumberFocusNode);
      return 'Please enter a valid Registration Number in the format YYYY/NNNNNN/NN';
    }
    return null;
  }

  String? _validateVATNumber(String? value) {
    // VAT number should be exactly 10 digits and start with 4
    final regExp = RegExp(r'^4\d{9}$');
    if (value == null || value.isEmpty) {
      _scrollToFocusNode(_vatNumberFocusNode);
      return 'Please enter VAT Number';
    } else if (!regExp.hasMatch(value)) {
      _scrollToFocusNode(_vatNumberFocusNode);
      return 'Please enter a valid VAT Number starting with 4 and having 10 digits';
    }
    return null;
  }

  void _scrollToFocusNode(FocusNode focusNode) {
    _scrollController.animateTo(
      _scrollController.position.minScrollExtent +
          _scrollController.position.maxScrollExtent * 0.2,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    focusNode.requestFocus();
  }
}
