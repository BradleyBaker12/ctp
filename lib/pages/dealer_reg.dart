import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter/services.dart'; // Import the services package for input formatters

class DealerRegPage extends StatefulWidget {
  const DealerRegPage({super.key});

  @override
  _DealerRegPageState createState() => _DealerRegPageState();
}

class _DealerRegPageState extends State<DealerRegPage> {
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
  final FocusNode _countryFocusNode = FocusNode();

  String? _selectedCountry = 'South Africa';
  List<String> _countries = [];

  String? _bankConfirmationFile;
  String? _cipcCertificateFile;
  String? _proxyFile;
  String? _brncFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    final String response =
        await rootBundle.loadString('lib/assets/country-by-name.json');
    final List<dynamic> data = await json.decode(response);
    setState(() {
      _countries = data.map((item) => item['country'].toString()).toList();
      if (_countries.contains('South Africa')) {
        _countries.remove('South Africa');
        _countries.insert(0, 'South Africa');
      }
    });
  }

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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      if (userId == null) {
        throw Exception('User ID is not available');
      }

      final FirebaseStorage storage = FirebaseStorage.instance;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      Future<String?> uploadFile(String? filePath, String fileName) async {
        try {
          if (filePath == null) return null;
          final ref = storage.ref().child('documents/$userId/$fileName');
          final task = ref.putFile(File(filePath));
          final snapshot = await task;
          return await snapshot.ref.getDownloadURL();
        } catch (e) {
          print('Error uploading $fileName: $e');
          return null;
        }
      }

      Map<String, dynamic> dealerData = {
        'companyDetails': {
          'companyName': _companyNameController.text,
          'tradingName': _tradingNameController.text,
          'registrationNumber': _registrationNumberController.text,
          'vatNumber': _vatNumberController.text,
        },
        'personalDetails': {
          'firstName': _firstNameController.text,
          'middleName': _middleNameController.text,
          'lastName': _lastNameController.text,
        },
        'address': {
          'addressLine1': _addressLine1Controller.text,
          'addressLine2': _addressLine2Controller.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'postalCode': _postalCodeController.text,
          'country': _selectedCountry,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_bankConfirmationFile != null) {
        final url =
            await uploadFile(_bankConfirmationFile, 'bank_confirmation.pdf');
        if (url != null) dealerData['documents'] = {'bankConfirmationUrl': url};
      }

      if (_cipcCertificateFile != null) {
        final url =
            await uploadFile(_cipcCertificateFile, 'cipc_certificate.pdf');
        if (url != null) {
          dealerData['documents'] = {
            ...?dealerData['documents'],
            'cipcCertificateUrl': url
          };
        }
      }

      if (_proxyFile != null) {
        final url = await uploadFile(_proxyFile, 'proxy.pdf');
        if (url != null) {
          dealerData['documents'] = {
            ...?dealerData['documents'],
            'proxyUrl': url
          };
        }
      }

      if (_brncFile != null) {
        final url = await uploadFile(_brncFile, 'brnc.pdf');
        if (url != null) {
          dealerData['documents'] = {
            ...?dealerData['documents'],
            'brncUrl': url
          };
        }
      }

      await firestore.collection('users').doc(userId).update(dealerData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration completed successfully!')),
        );
        Navigator.pushReplacementNamed(context, '/houseRules');
      }
    } catch (e) {
      print("Error submitting form: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting form: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                    controller: _scrollController,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: screenSize.height * 0.05),
                          Center(
                            child: Image.asset('lib/assets/CTPLogo.png',
                                height: screenSize.height *
                                    0.12), // Adjust the height as needed
                          ),
                          SizedBox(height: screenSize.height * 0.09),
                          Center(
                            child: Text(
                              'DEALER REGISTRATION',
                              style: GoogleFonts.montserrat(
                                fontSize: screenSize.height * 0.025,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: screenSize.height * 0.02),
                          Center(
                            child: Text(
                              'Fill out the form carefully to register.',
                              style: GoogleFonts.montserrat(
                                fontSize: screenSize.height * 0.015,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: screenSize.height * 0.02),
                          Center(
                            child: Text(
                              'CTP Offers a way for you to sell your vehicle to multiple dealers in SA.\n\nCTP\'s fees are R 12 500 flat fee.',
                              style: GoogleFonts.montserrat(
                                fontSize: screenSize.height * 0.015,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: screenSize.height * 0.05),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Company Details *'.toUpperCase(),
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _companyNameController,
                                    focusNode: _companyNameFocusNode,
                                    hintText: 'Company Name'),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _tradingNameController,
                                    focusNode: _tradingNameFocusNode,
                                    hintText: 'Trading Name',
                                    isOptional: true),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _registrationNumberController,
                                    focusNode: _registrationNumberFocusNode,
                                    hintText: 'Registration Number',
                                    validator: _validateRegistrationNumber,
                                    inputFormatters: [
                                      RegistrationNumberInputFormatter()
                                    ]), // Apply the formatter here
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _vatNumberController,
                                    focusNode: _vatNumberFocusNode,
                                    hintText: 'VAT Number',
                                    validator: _validateVATNumber),
                                const SizedBox(height: 15),
                                Text(
                                  'Dealer personal details *'.toUpperCase(),
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _firstNameController,
                                    focusNode: _firstNameFocusNode,
                                    hintText: 'First Name'),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _middleNameController,
                                    focusNode: _middleNameFocusNode,
                                    hintText: 'Middle Name (OPTIONAL)',
                                    isOptional: true),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _lastNameController,
                                    focusNode: _lastNameFocusNode,
                                    hintText: 'Last Name'),
                                const SizedBox(height: 15),
                                Text(
                                  'Address'.toUpperCase(),
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 15),
                                _buildDropdownField(),
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
                                  'Document Uploads'.toUpperCase(),
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: screenSize.height * 0.02),
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
                                  'CIPC CERTIFICATE *',
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 5),
                                _buildUploadButton(
                                    'cipcCertificate', _cipcCertificateFile),
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
          // const Positioned(
          //   top: 120,
          //   left: 16,
          //   child: CustomBackButton(),
          // ),
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

  Widget _buildDropdownField() {
    return SizedBox(
      width: double.infinity,
      child: DropdownSearch<String>(
        items: _countries,
        selectedItem: _selectedCountry,
        onChanged: (String? newValue) {
          setState(() {
            _selectedCountry = newValue;
          });
        },
        validator: (value) {
          if (value == null) {
            _scrollToFocusNode(_countryFocusNode);
            return 'Please select a country';
          }
          return null;
        },
        dropdownDecoratorProps: DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            hintText: 'Select Country',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            filled: true,
            fillColor: Colors.grey.withOpacity(0.2), // Set grey background
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(color: Colors.white), // White border
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide:
                  const BorderSide(color: Color(0xFFFF4E00)), // Orange border
            ),
          ),
        ),
        dropdownBuilder: (context, selectedItem) => selectedItem == null
            ? Text(
                'Select Country',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7)), // White hint text
              )
            : Text(
                selectedItem,
                style: const TextStyle(
                    color: Colors.white), // White text for selected item
              ),
        clearButtonProps: const ClearButtonProps(
          isVisible: true,
          icon: Icon(Icons.clear, color: Colors.white),
        ),
        popupProps: PopupProps.menu(
          showSearchBox: true, // Enable search box
          menuProps: MenuProps(
            backgroundColor:
                Colors.grey[900], // Black background for the dropdown menu
          ),
          searchFieldProps: TextFieldProps(
            style: const TextStyle(
                color: Colors.white), // White text in search field
            cursorColor: const Color(0xFFFF4E00), // Orange cursor
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey
                  .withOpacity(0.2), // Grey background for search bar
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(
                    color: Colors.grey.withOpacity(0.2)), // Black border
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(
                    color: Color(0xFFFF4E00)), // Orange border when focused
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: const BorderSide(
                    color: Colors
                        .white), // White border when enabled (not focused)
              ),
              hintText: 'Search Country',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          showSelectedItems: true,
          fit: FlexFit.loose,
          itemBuilder: (context, item, isSelected) => Container(
            color: isSelected
                ? Colors.grey[850]
                : Colors.grey[900], // Highlight selected item
            child: ListTile(
              title: Text(
                item,
                style: const TextStyle(
                    color: Colors.white), // White text for items
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required FocusNode focusNode,
    bool isOptional = false,
    var orange = const Color(0xFFFF4E00),
    String? Function(String?)? validator,
    List<TextInputFormatter>?
        inputFormatters, // Add this parameter for custom input formatters
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      cursorColor: orange,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.montserrat(color: Colors.white70),
        filled: true,
        fillColor:
            Colors.grey.withOpacity(0.2), // Set the background to a grey color
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4.0),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.4), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.6), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Color(0xFFFF4E00), width: 2),
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
      inputFormatters: inputFormatters, // Apply input formatters
    );
  }

  Widget _buildUploadButton(String fieldName, String? fileName) {
    var screenSize = MediaQuery.of(context).size;
    return Stack(
      children: [
        GestureDetector(
          onTap: () async {
            if (fileName != null) {
              final extension = path.extension(fileName).toLowerCase();
              if (extension == '.pdf') {
                // Open the PDF file using flutter_pdfview
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PDFViewerScreen(filePath: fileName),
                  ),
                );
              } else {
                // Open the file using the default file viewer
                final Uri fileUri = Uri.file(fileName);
                if (await canLaunch(fileUri.toString())) {
                  await launch(fileUri.toString());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open the file')),
                  );
                }
              }
            } else {
              _pickFile(fieldName);
            }
          },
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2), // Set grey background
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.white70, width: 1),
            ),
            child: Center(
              child: fileName == null
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.folder_outlined,
                            color: Colors.blue, size: 40),
                        Positioned(
                          bottom: screenSize.height * 0.009,
                          child: Icon(
                            Icons.arrow_upward,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getIconForFileType(fileName),
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 5),
                        Flexible(
                          child: Text(
                            path.basename(fileName),
                            style: GoogleFonts.montserrat(color: Colors.white),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        if (fileName != null)
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (fieldName == 'bankConfirmation') {
                    _bankConfirmationFile = null;
                  } else if (fieldName == 'cipcCertificate') {
                    _cipcCertificateFile = null;
                  } else if (fieldName == 'proxy') {
                    _proxyFile = null;
                  } else if (fieldName == 'brnc') {
                    _brncFile = null;
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

class RegistrationNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('/', '');

    if (text.length <= 4) {
      return newValue.copyWith(
        text: text,
        selection: TextSelection.collapsed(offset: newValue.selection.end),
      );
    } else if (text.length <= 10) {
      return newValue.copyWith(
        text: '${text.substring(0, 4)}/${text.substring(4)}',
        selection: TextSelection.collapsed(offset: newValue.selection.end + 1),
      );
    } else if (text.length <= 12) {
      return newValue.copyWith(
        text:
            '${text.substring(0, 4)}/${text.substring(4, 10)}/${text.substring(10)}',
        selection: TextSelection.collapsed(offset: newValue.selection.end + 2),
      );
    } else {
      return newValue.copyWith(
        text:
            '${text.substring(0, 4)}/${text.substring(4, 10)}/${text.substring(10, 12)}',
        selection: TextSelection.collapsed(offset: newValue.selection.end),
      );
    }
  }
}

class PDFViewerScreen extends StatelessWidget {
  final String filePath;

  const PDFViewerScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View PDF'),
      ),
      body: PDFView(
        filePath: filePath,
      ),
    );
  }
}
