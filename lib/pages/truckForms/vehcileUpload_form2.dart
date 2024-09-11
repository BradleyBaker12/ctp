import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/providers/vehicles_provider.dart'; // Import VehicleProvider
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
  bool _showCurrencySymbol = false; // To control when to show "R" symbol

  String _maintenance = 'yes';
  String _oemInspection = 'yes';
  String _warranty =
      'yes'; // Initial value 'yes' to show the textbox by default
  String _firstOwner = 'yes';
  String _accidentFree = 'yes';
  String _roadWorthy = 'yes';
  String _transmission = 'Manual'; // Default for Transmission Dropdown
  String _suspension = 'Steel'; // Default for Suspension Dropdown
  String _hydraulics = 'no'; // Default for Hydraulics
  bool _isLoading = false;

  Future<void> _submitForm(Map<String, dynamic> args) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      String? vehicleId = vehicleProvider.vehicleId;

      if (vehicleId != null) {
        // Update the existing vehicle document using vehicleId
        await firestore.collection('vehicles').doc(vehicleId).update({
          'application': _applicationController.text,
          'transmission': _transmission,
          'engineNumber': _engineNumberController.text,
          'suspension': _suspension,
          'registrationNumber': _registrationNumberController.text,
          'hydraulics': _hydraulics,
          'expectedSellingPrice': _expectedSellingPriceController.text,
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

        Navigator.pushNamed(
          context,
          '/thirdTruckForm',
          arguments: {'image': args['image'], 'docId': vehicleId},
        );
      } else {
        // Handle the case when vehicleId is null (if needed)
        print('Error: vehicleId is null');
      }
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
    final Map<String, dynamic> args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final File? imageFile = args['image'];

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
                              'Form Progress',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
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
                                    controller: _applicationController,
                                    hintText: 'Application of Use'),
                                const SizedBox(height: 15),
                                _buildDropdown(
                                  value: _transmission == 'Manual' ||
                                          _transmission == 'Automatic'
                                      ? _transmission
                                      : null,
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
                                    inputFormatter: [UpperCaseTextFormatter()]),
                                const SizedBox(height: 15),
                                _buildDropdown(
                                  value: _suspension == 'Steel' ||
                                          _suspension == 'Air'
                                      ? _suspension
                                      : null,
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
                                    inputFormatter: [UpperCaseTextFormatter()]),
                                const SizedBox(height: 15),
                                _buildSellingPriceTextField(
                                  controller: _expectedSellingPriceController,
                                  hintText: 'Expected Selling Price',
                                ),
                                const SizedBox(height: 15),
                                _buildRadioButtonHeading('Hydraulics'),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildRadioButton('Yes', 'yes',
                                        groupValue: _hydraulics,
                                        onChanged: (value) {
                                      setState(() {
                                        _hydraulics = value!;
                                      });
                                    }),
                                    SizedBox(width: screenSize.width * 0.1),
                                    _buildRadioButton('No', 'no',
                                        groupValue: _hydraulics,
                                        onChanged: (value) {
                                      setState(() {
                                        _hydraulics = value!;
                                      });
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                _buildRadioButtonHeading(
                                    'Is your vehicle under a maintenance plan'),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildRadioButton('Yes', 'yes',
                                        groupValue: _maintenance,
                                        onChanged: (value) {
                                      setState(() {
                                        _maintenance = value!;
                                      });
                                    }),
                                    SizedBox(width: screenSize.width * 0.1),
                                    _buildRadioButton('No', 'no',
                                        groupValue: _maintenance,
                                        onChanged: (value) {
                                      setState(() {
                                        _maintenance = value!;
                                      });
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                const Center(
                                  child: Text(
                                    'Can your vehicle be sent to OEM for a full inspection under R&M contract?\n\nPlease note that OEM will charge you for inspection',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildRadioButton('Yes', 'yes',
                                        groupValue: _oemInspection,
                                        onChanged: (value) {
                                      setState(() {
                                        _oemInspection = value!;
                                      });
                                    }),
                                    SizedBox(width: screenSize.width * 0.1),
                                    _buildRadioButton('No', 'no',
                                        groupValue: _oemInspection,
                                        onChanged: (value) {
                                      setState(() {
                                        _oemInspection = value!;
                                      });
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                _buildRadioButtonHeading(
                                    'Is it under any warranty'),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildRadioButton('Yes', 'yes',
                                        groupValue: _warranty,
                                        onChanged: (value) {
                                      setState(() {
                                        _warranty = value!;
                                      });
                                    }),
                                    SizedBox(width: screenSize.width * 0.1),
                                    _buildRadioButton('No', 'no',
                                        groupValue: _warranty,
                                        onChanged: (value) {
                                      setState(() {
                                        _warranty = value!;
                                      });
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                // Use the Visibility widget to toggle the warranty type text field
                                Visibility(
                                  visible: _warranty ==
                                      'yes', // Show when 'Yes' is selected
                                  child: _buildTextField(
                                    controller: _warrantyTypeController,
                                    hintText:
                                        'What type of main warranty does your vehicle have?',
                                  ),
                                ),
                                const SizedBox(height: 15),
                                _buildRadioButtonHeading(
                                    'Are you the first owner'),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildRadioButton('Yes', 'yes',
                                        groupValue: _firstOwner,
                                        onChanged: (value) {
                                      setState(() {
                                        _firstOwner = value!;
                                      });
                                    }),
                                    SizedBox(width: screenSize.width * 0.1),
                                    _buildRadioButton('No', 'no',
                                        groupValue: _firstOwner,
                                        onChanged: (value) {
                                      setState(() {
                                        _firstOwner = value!;
                                      });
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                _buildRadioButtonHeading('Accident Free'),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildRadioButton('Yes', 'yes',
                                        groupValue: _accidentFree,
                                        onChanged: (value) {
                                      setState(() {
                                        _accidentFree = value!;
                                      });
                                    }),
                                    SizedBox(width: screenSize.width * 0.1),
                                    _buildRadioButton('No', 'no',
                                        groupValue: _accidentFree,
                                        onChanged: (value) {
                                      setState(() {
                                        _accidentFree = value!;
                                      });
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                _buildRadioButtonHeading(
                                    'Is the truck roadworthy?'),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildRadioButton('Yes', 'yes',
                                        groupValue: _roadWorthy,
                                        onChanged: (value) {
                                      setState(() {
                                        _roadWorthy = value!;
                                      });
                                    }),
                                    SizedBox(width: screenSize.width * 0.1),
                                    _buildRadioButton('No', 'no',
                                        groupValue: _roadWorthy,
                                        onChanged: (value) {
                                      setState(() {
                                        _roadWorthy = value!;
                                      });
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: CustomButton(
                                    text: 'CONTINUE',
                                    borderColor: orange,
                                    onPressed: _isLoading
                                        ? () {}
                                        : () => _submitForm(args),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      // Handle cancel action
                                    },
                                    child: const Text(
                                      'CANCEL',
                                      style: TextStyle(color: Colors.white),
                                    ),
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
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    List<TextInputFormatter>? inputFormatter,
  }) {
    return TextFormField(
      controller: controller,
      cursorColor: const Color(0xFFFF4E00), // Orange cursor
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: Color(0xFFFF4E00), // Orange border when focused
            width: 2.0,
          ),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      inputFormatters:
          inputFormatter, // Uppercase formatter for specific fields
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
      cursorColor: const Color(0xFFFF4E00), // Orange cursor color
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: _showCurrencySymbol
            ? 'R '
            : '', // Show "R" only if user starts typing
        prefixStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
            color: Color(0xFFFF4E00), // Orange border when focused
            width: 2.0,
          ),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      onChanged: (value) {
        setState(() {
          _showCurrencySymbol = value.isNotEmpty;
        });

        if (value.isNotEmpty) {
          // Format number with spaces
          final formattedValue = _numberFormat
              .format(int.parse(value.replaceAll(" ", "")))
              .replaceAll(",", " ");
          controller.value = TextEditingValue(
            text: formattedValue,
            selection: TextSelection.collapsed(offset: formattedValue.length),
          );
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
    required String? value, // Nullable String so no preselected value
    required List<String> items,
    required String hintText,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value == '' || value == 'None' ? null : value,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText, // Keep the hint text
        hintStyle:
            const TextStyle(color: Colors.white70), // Keep your hint text style
        filled: true,
        fillColor: Colors.white.withOpacity(0.2), // Keep your style
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0), // Keep your border style
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: Color(0xFFFF4E00), // Orange border when focused
            width: 2.0,
          ),
        ),
      ),
      dropdownColor:
          Colors.black.withOpacity(0.7), // Keep your dropdown background color
      hint: Text(
        hintText,
        style: const TextStyle(color: Colors.white70), // Hint text color
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(
                color: Colors.white), // Maintain your style for the options
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRadioButton(String label, String value,
      {required String groupValue, required Function(String?) onChanged}) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            onChanged(value);
          },
          child: Container(
            width: 24, // Width of outer circle
            height: 24, // Height of outer circle
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white, // White outer ring
                width: 3.0, // Thickness of outer ring
              ),
            ),
            child: Center(
              child: Container(
                width: 12, // Size of inner orange dot
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value == groupValue
                      ? const Color(0xFFFF4E00)
                      : Colors.transparent, // Orange inner dot if selected
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10), // Space between radio button and label
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ), // Adjust text size if needed
        ),
      ],
    );
  }

  Widget _buildRadioButtonHeading(String heading) {
    return Column(
      children: [
        Divider(
          color: Colors.white.withOpacity(0.5),
          thickness: 1,
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            heading.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),
      ],
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
