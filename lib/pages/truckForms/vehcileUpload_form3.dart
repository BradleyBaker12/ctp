import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/providers/vehicles_provider.dart'; // Import VehicleProvider
import 'package:intl/intl.dart'; // Import for number formatting

class ThirdFormPage extends StatefulWidget {
  const ThirdFormPage({super.key});

  @override
  _ThirdFormPageState createState() => _ThirdFormPageState();
}

class _ThirdFormPageState extends State<ThirdFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();

  String _settleBeforeSelling = 'yes';
  String? _settlementLetterFile;
  bool _isLoading = false;
  bool _showCurrencySymbol = false; // To control when to show "R" symbol

  // NumberFormat with commas, which will be replaced with spaces in the onChanged handler
  final NumberFormat _numberFormat = NumberFormat("#,##0", "en_US");

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        setState(() {
          _settlementLetterFile = result.files.single.path;
        });
      }
    } catch (e) {
      print("Error picking file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _submitForm(Map<String, dynamic> args) async {
    if (!_formKey.currentState!.validate()) {
      print("Form validation failed.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final FirebaseStorage storage = FirebaseStorage.instance;
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      String? vehicleId = vehicleProvider.vehicleId;

      if (vehicleId != null) {
        String? settlementLetterUrl;

        // Check if a settlement letter file was uploaded
        if (_settlementLetterFile != null) {
          String fileName =
              _settlementLetterFile!.split('/').last; // Get file name
          String fileExtension =
              fileName.split('.').last; // Get file extension (e.g., jpg, pdf)

          // Define the storage path based on the file extension
          final ref = storage
              .ref()
              .child('vehicles/$vehicleId/settlementLetter.$fileExtension');
          final uploadTask = ref.putFile(File(_settlementLetterFile!));
          final snapshot = await uploadTask;
          settlementLetterUrl = await snapshot.ref.getDownloadURL();
        }

        // Update the existing vehicle document using vehicleId
        await firestore.collection('vehicles').doc(vehicleId).update({
          'settleBeforeSelling': _settleBeforeSelling,
          'settlementAmount': _amountController.text
              .replaceAll(" ", ""), // Remove spaces for saving
          'settlementLetterFile': settlementLetterUrl ?? '', // Save file URL
          'userId': userId,
        });

        print("Form submitted successfully!");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Form submitted successfully!')),
        );

        // Navigate to the FourthFormPage
        Navigator.pushNamed(
          context,
          '/fourthTruckForm',
          arguments: {
            'docId': vehicleId,
            'image': args['image'], // Pass along any required arguments
          },
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
    final Map<String, dynamic>? args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final File? imageFile = args?['image'] as File?;

    if (args == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Invalid or missing arguments. Please try again.',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
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
                      child: Form(
                        key: _formKey,
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
                                'Bank Settlement Amount',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildRadioButton('Yes', 'yes',
                                    groupValue: _settleBeforeSelling,
                                    onChanged: (value) {
                                  setState(() {
                                    _settleBeforeSelling = value!;
                                  });
                                }),
                                const SizedBox(width: 20),
                                _buildRadioButton('No', 'no',
                                    groupValue: _settleBeforeSelling,
                                    onChanged: (value) {
                                  setState(() {
                                    _settleBeforeSelling = value!;
                                  });
                                }),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Visibility(
                              visible: _settleBeforeSelling == 'yes',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Center(
                                    child: Text(
                                      'Please attach the following documents',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Center(
                                    child: GestureDetector(
                                      onTap: _pickFile,
                                      child: Container(
                                        height: 100,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          border: Border.all(
                                              color: Colors.white70, width: 1),
                                        ),
                                        child: Center(
                                          child: _settlementLetterFile == null
                                              ? const Icon(Icons.folder_open,
                                                  color: Colors.blue, size: 40)
                                              : Text(
                                                  _settlementLetterFile!
                                                      .split('/')
                                                      .last,
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Center(
                                    child: Text(
                                      'Please attach physical settlement letter',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Center(
                                    child: Text(
                                      'Settlement Amount',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildTextField(
                                      controller: _amountController,
                                      hintText: 'Amount'),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
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

  // Text field with number formatting, orange cursor, and conditional currency symbol (R)
  Widget _buildTextField({
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
}
