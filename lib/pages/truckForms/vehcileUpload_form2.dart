import 'package:ctp/components/form_navigation_widget.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/providers/form_data_provider.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class SecondFormPage extends StatefulWidget {
  const SecondFormPage({super.key});

  @override
  _SecondFormPageState createState() => _SecondFormPageState();
}

class _SecondFormPageState extends State<SecondFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _applicationController = TextEditingController();
  final TextEditingController _engineNumberController = TextEditingController();
  final TextEditingController _registrationNumberController =
      TextEditingController();
  final TextEditingController _expectedSellingPriceController =
      TextEditingController();
  final TextEditingController _warrantyTypeController = TextEditingController();

  final NumberFormat _numberFormat = NumberFormat("#,##0", "en_US");
  bool _showCurrencySymbol = false;

  final String _maintenance = 'yes';
  final String _oemInspection = 'yes';
  final String _warranty = 'yes';
  final String _firstOwner = 'yes';
  final String _accidentFree = 'yes';
  final String _roadWorthy = 'yes';
  String _transmission = 'Manual';
  String _suspension = 'Steel';
  final String _hydraulics = 'no';
  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      print("Form validation failed.");
      return;
    }

    print("Submitting SecondFormPage form...");

    // Save form data to the provider before submission
    final formDataProvider =
        Provider.of<FormDataProvider>(context, listen: false);

    formDataProvider.setApplication(_applicationController.text);
    formDataProvider.setTransmission(_transmission);
    formDataProvider.setEngineNumber(_engineNumberController.text);
    formDataProvider.setSuspension(_suspension);
    formDataProvider.setRegistrationNumber(_registrationNumberController.text);
    formDataProvider
        .setExpectedSellingPrice(_expectedSellingPriceController.text);
    formDataProvider.setHydraulics(_hydraulics);
    formDataProvider.setMaintenance(_maintenance);
    formDataProvider.setOemInspection(_oemInspection);
    formDataProvider.setWarranty(_warranty);
    formDataProvider.setWarrantyType(_warrantyTypeController.text);
    formDataProvider.setFirstOwner(_firstOwner);
    formDataProvider.setAccidentFree(_accidentFree);
    formDataProvider.setRoadWorthy(_roadWorthy);

    setState(() {
      _isLoading = true;
    });

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      String? vehicleId = vehicleProvider.vehicleId;

      print("User ID: $userId");
      print("Vehicle ID: $vehicleId");

      if (vehicleId != null) {
        formDataProvider.setVehicleId(vehicleId);
        print(
            'SecondFormPage: vehicleId set in FormDataProvider: ${formDataProvider.vehicleId}');

        await firestore.collection('vehicles').doc(vehicleId).update({
          'application': _applicationController.text,
          'transmission': _transmission,
          'engineNumber': _engineNumberController.text,
          'suspension': _suspension,
          'registrationNumber': _registrationNumberController.text,
          'hydraulics': _hydraulics,
          'expectedSellingPrice':
              _expectedSellingPriceController.text.replaceAll(" ", ""),
          'warrantyType': _warrantyTypeController.text,
          'maintenance': _maintenance,
          'oemInspection': _oemInspection,
          'warranty': _warranty,
          'firstOwner': _firstOwner,
          'accidentFree': _accidentFree,
          'roadWorthy': _roadWorthy,
          'userId': userId,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Form submitted successfully!')),
        );

        print("SecondFormPage form submitted successfully!");

        // Navigate to the next form or update the form index
        formDataProvider.incrementFormIndex();
      } else {
        print('Error: vehicleId is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Vehicle ID is null.')),
        );
      }
    } catch (e, stackTrace) {
      print("Error submitting form: $e");
      print("Stack trace: $stackTrace");
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
  void dispose() {
    _applicationController.dispose();
    _engineNumberController.dispose();
    _registrationNumberController.dispose();
    _expectedSellingPriceController.dispose();
    _warrantyTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("Building SecondFormPage...");

    final formDataProvider = Provider.of<FormDataProvider>(context);
    final File? imageFile = formDataProvider.selectedMainImage;

    if (imageFile != null) {
      print("Image file is provided from provider.");
    } else {
      print("Image file is null in provider.");
    }

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  height: 300,
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: imageFile == null
                                      ? const Text(
                                          'No image selected',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        )
                                      : ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          child: Image.file(
                                            imageFile,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),

                          // Form Navigation Widget placed under the image
                          const SizedBox(height: 20),
                          FormNavigationWidget(),
                          const SizedBox(height: 20),

                          const Center(
                            child: Text(
                              'TRUCK/TRAILER FORM',
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
                              'FORM PROGRESS',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Form fields continue here
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTextArea(
                                  controller: _applicationController,
                                  hintText: 'Application of Use',
                                  maxLines: 5,
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  "Transmission",
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                _buildDropdown(
                                  value: _transmission,
                                  items: ['Manual', 'Automatic'],
                                  hintText: 'Transmission',
                                  onChanged: (value) {
                                    setState(() {
                                      _transmission = value!;
                                    });
                                  },
                                ),
                                const SizedBox(height: 15),
                                _buildTextField(
                                  controller: _engineNumberController,
                                  hintText: 'Engine No.',
                                  inputFormatter: [UpperCaseTextFormatter()],
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  "Suspension",
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                _buildDropdown(
                                  value: _suspension,
                                  items: ['Steel', 'Air'],
                                  hintText: 'Suspension',
                                  onChanged: (value) {
                                    setState(() {
                                      _suspension = value!;
                                    });
                                  },
                                ),
                                const SizedBox(height: 15),
                                _buildTextField(
                                  controller: _registrationNumberController,
                                  hintText: 'Registration No.',
                                  inputFormatter: [UpperCaseTextFormatter()],
                                ),
                                const SizedBox(height: 15),
                                _buildSellingPriceTextField(
                                  controller: _expectedSellingPriceController,
                                  hintText: 'Expected Selling Price',
                                ),
                                const SizedBox(height: 15),

                                // Other form fields...
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
        ],
      ),
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 5,
  }) {
    return TextFormField(
      controller: controller,
      cursorColor: const Color(0xFFFF4E00),
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: Color(0xFFFF4E00),
            width: 2.0,
          ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    List<TextInputFormatter>? inputFormatter,
  }) {
    return TextFormField(
      controller: controller,
      cursorColor: const Color(0xFFFF4E00),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: Color(0xFFFF4E00),
            width: 2.0,
          ),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      inputFormatters: inputFormatter,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $hintText';
        }
        return null;
      },
    );
  }

  Widget _buildSellingPriceTextField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      cursorColor: const Color(0xFFFF4E00),
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: _showCurrencySymbol ? 'R ' : '',
        prefixStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: Color(0xFFFF4E00),
            width: 2.0,
          ),
        ),
      ),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
      onChanged: (value) {
        setState(() {
          _showCurrencySymbol = value.isNotEmpty;
        });

        if (value.isNotEmpty) {
          try {
            final formattedValue = _numberFormat
                .format(int.parse(value.replaceAll(" ", "")))
                .replaceAll(",", " ");
            controller.value = TextEditingValue(
              text: formattedValue,
              selection: TextSelection.collapsed(offset: formattedValue.length),
            );
          } catch (e) {
            print("Error formatting selling price: $e");
          }
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $hintText';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hintText,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value == '' || value == 'None' ? null : value,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: Color(0xFFFF4E00),
            width: 2.0,
          ),
        ),
      ),
      hint: Text(
        hintText,
        style: const TextStyle(color: Colors.white70),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      dropdownColor: Colors.black.withOpacity(0.7),
    );
  }
}

// Custom TextInputFormatter for uppercase
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
