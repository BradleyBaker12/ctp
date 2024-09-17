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
import 'package:ctp/providers/form_data_provider.dart'; // Import FormDataProvider
import 'package:intl/intl.dart'; // Import for number formatting
import 'package:path/path.dart' as path; // Import path package

class ThirdFormPage extends StatefulWidget {
  const ThirdFormPage({Key? key}) : super(key: key);

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

  // FormDataProvider instance
  late FormDataProvider formDataProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    formDataProvider = Provider.of<FormDataProvider>(context);
  }

  Future<void> _pickFile() async {
    print("Initiating file picker...");
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        setState(() {
          _settlementLetterFile = result.files.single.path;
          // Update provider
          formDataProvider
              .setSettlementLetterFile(File(_settlementLetterFile!));
        });
        print("File selected: $_settlementLetterFile");
      } else {
        print("No file selected.");
      }
    } catch (e) {
      print("Error picking file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
    print("Submitting form...");
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

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);

      String? userId = userProvider.userId;
      String? vehicleId = vehicleProvider.vehicleId;
      File? selectedMainImage = formDataProvider.selectedMainImage;

      print("User ID: $userId");
      print("Vehicle ID: $vehicleId");
      print("Selected Main Image: $selectedMainImage");

      if (userId == null) {
        print("Error: userId is null");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User not logged in.')),
        );
        return;
      }

      if (vehicleId != null) {
        String? settlementLetterUrl;

        // Check if a settlement letter file was uploaded
        if (formDataProvider.settlementLetterFile != null) {
          print("Uploading settlement letter file...");
          String fileName =
              path.basename(formDataProvider.settlementLetterFile!.path);
          String fileExtension = fileName.split('.').last; // Get file extension

          // Define the storage path
          final ref = storage
              .ref()
              .child('vehicles/$vehicleId/settlementLetter.$fileExtension');

          final uploadTask =
              ref.putFile(formDataProvider.settlementLetterFile!);
          final snapshot = await uploadTask;
          settlementLetterUrl = await snapshot.ref.getDownloadURL();

          print("Settlement letter uploaded. URL: $settlementLetterUrl");
        } else {
          print("No settlement letter file to upload.");
        }

        // Update the existing vehicle document using vehicleId
        print("Updating Firestore document for vehicle...");
        await firestore.collection('vehicles').doc(vehicleId).update({
          'settleBeforeSelling': formDataProvider.settleBeforeSelling ?? '',
          'settlementAmount': formDataProvider.settlementAmount ?? '',
          'settlementLetterFile': settlementLetterUrl ?? '',
          'userId': userId,
        });

        print("Form submitted successfully!");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Form submitted successfully!')),
        );

        // Update the form index or navigate to the next form
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
  Widget build(BuildContext context) {
    print("Building ThirdFormPage...");

    final File? selectedMainImage = formDataProvider.selectedMainImage;

    if (selectedMainImage != null) {
      print("Selected Main Image is provided from provider.");
    } else {
      print("Selected Main Image is null in provider.");
    }

    if (selectedMainImage == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No image selected. Please go back and select an image.',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

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
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10.0),
                                      child: Image.file(
                                        selectedMainImage,
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
                                  print(
                                      "Settle before selling changed to: $_settleBeforeSelling");
                                  // Update provider
                                  formDataProvider
                                      .setSettleBeforeSelling(value!);
                                }),
                                const SizedBox(width: 20),
                                _buildRadioButton('No', 'no',
                                    groupValue: _settleBeforeSelling,
                                    onChanged: (value) {
                                  setState(() {
                                    _settleBeforeSelling = value!;
                                  });
                                  print(
                                      "Settle before selling changed to: $_settleBeforeSelling");
                                  // Update provider
                                  formDataProvider
                                      .setSettleBeforeSelling(value!);
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
                                text: _isLoading ? 'Submitting...' : 'CONTINUE',
                                borderColor: orange,
                                onPressed: _isLoading
                                    ? () {
                                        print(
                                            "Submit button pressed while loading.");
                                      }
                                    : () {
                                        print("Submit button pressed.");
                                        _submitForm();
                                      },
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  print("Cancel button pressed.");
                                  Navigator.pop(context);
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

        print("Amount field changed: $value");

        if (value.isNotEmpty) {
          try {
            // Format number with spaces
            final formattedValue = _numberFormat
                .format(int.parse(value.replaceAll(" ", "")))
                .replaceAll(",", " ");
            controller.value = TextEditingValue(
              text: formattedValue,
              selection: TextSelection.collapsed(offset: formattedValue.length),
            );
            print("Formatted amount: $formattedValue");
            // Update provider
            formDataProvider
                .setSettlementAmount(formattedValue.replaceAll(" ", ""));
          } catch (e) {
            print("Error formatting amount: $e");
          }
        } else {
          // Update provider
          formDataProvider.setSettlementAmount('');
        }
      },
      validator: (value) {
        if (_settleBeforeSelling == 'yes') {
          if (value == null || value.isEmpty) {
            return 'Please enter $hintText';
          }
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
          onChanged: (val) {
            onChanged(val);
            // Update provider
            formDataProvider.setSettleBeforeSelling(val!);
          },
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
