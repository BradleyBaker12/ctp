import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';

class SecondFormPage extends StatefulWidget {
  const SecondFormPage({super.key});

  @override
  _SecondFormPageState createState() => _SecondFormPageState();
}

class _SecondFormPageState extends State<SecondFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _applicationController = TextEditingController();
  final TextEditingController _transmissionController = TextEditingController();
  final TextEditingController _engineNumberController = TextEditingController();
  final TextEditingController _suspensionController = TextEditingController();
  final TextEditingController _registrationNumberController =
      TextEditingController();
  final TextEditingController _hydraulicsController = TextEditingController();
  final TextEditingController _expectedSellingPriceController =
      TextEditingController();
  final TextEditingController _warrantyTypeController = TextEditingController();

  String _maintenance = 'yes';
  String _oemInspection = 'yes';
  String _warranty = 'yes';
  String _firstOwner = 'yes';
  String _accidentFree = 'yes';
  String _roadWorthy = 'yes';
  bool _isLoading = false;

  Future<void> _submitForm(Map<String, dynamic> args, String docId) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final userId = Provider.of<UserProvider>(context, listen: false).userId;

      await firestore.collection('vehicles').doc(docId).update({
        'application': _applicationController.text,
        'transmission': _transmissionController.text,
        'engineNumber': _engineNumberController.text,
        'suspension': _suspensionController.text,
        'registrationNumber': _registrationNumberController.text,
        'hydraulics': _hydraulicsController.text,
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
        arguments: {'image': args['image'], 'docId': docId},
      );
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
    final String docId = args['docId'];

    var screenSize = MediaQuery.of(context).size;
    var blue = const Color(0xFF2F7FFF);
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
                                _buildTextField(
                                    controller: _transmissionController,
                                    hintText: 'Transmission'),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _engineNumberController,
                                    hintText: 'Engine No.'),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _suspensionController,
                                    hintText: 'Suspension'),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _registrationNumberController,
                                    hintText: 'Registration No.'),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _hydraulicsController,
                                    hintText: 'Hydraulics'),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _expectedSellingPriceController,
                                    hintText: 'Expected Selling Price'),
                                const SizedBox(height: 20),
                                _buildRadioButtonHeading('Maintenance'),
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
                                    const SizedBox(width: 10),
                                    _buildRadioButton('No', 'no',
                                        groupValue: _maintenance,
                                        onChanged: (value) {
                                      setState(() {
                                        _maintenance = value!;
                                      });
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildRadioButtonHeading(
                                    'Can your vehicle be sent to OEM for a full inspection under R&M contract?'),
                                const Center(
                                  child: Text(
                                    'Please note that OEM will charge you for inspection',
                                    style: TextStyle(color: Colors.white),
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
                                    const SizedBox(width: 10),
                                    _buildRadioButton('No', 'no',
                                        groupValue: _oemInspection,
                                        onChanged: (value) {
                                      setState(() {
                                        _oemInspection = value!;
                                      });
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildRadioButtonHeading('Warranty'),
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
                                    const SizedBox(width: 10),
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
                                _buildTextField(
                                    controller: _warrantyTypeController,
                                    hintText:
                                        'What main warranty does your vehicle have'),
                                const SizedBox(height: 20),
                                _buildRadioButtonHeading(
                                    'Are you the first owner?'),
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
                                    const SizedBox(width: 10),
                                    _buildRadioButton('No', 'no',
                                        groupValue: _firstOwner,
                                        onChanged: (value) {
                                      setState(() {
                                        _firstOwner = value!;
                                      });
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildRadioButtonHeading('Accident free'),
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
                                    const SizedBox(width: 10),
                                    _buildRadioButton('No', 'no',
                                        groupValue: _accidentFree,
                                        onChanged: (value) {
                                      setState(() {
                                        _accidentFree = value!;
                                      });
                                    }),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildRadioButtonHeading(
                                    'Is the truck road worthy?'),
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
                                    const SizedBox(width: 10),
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
                                        : () => _submitForm(args, docId),
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
    bool isRequired =
        false, // Add a parameter to specify if the field is required
  }) {
    return TextFormField(
      controller: controller,
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
      ),
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (isRequired && (value == null || value.isEmpty)) {
          return 'Please enter $hintText';
        }
        return null;
      },
    );
  }

  Widget _buildRadioButton(String label, String value,
      {required String groupValue, required Function(String?) onChanged}) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor: const Color(0xFFFF4E00),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white),
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
