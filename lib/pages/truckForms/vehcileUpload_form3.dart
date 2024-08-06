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

  Future<void> _submitForm(String docId, Map<String, dynamic> args) async {
    if (!_formKey.currentState!.validate()) {
      print("Form validation failed.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final userId = Provider.of<UserProvider>(context, listen: false).userId;

      print("userId: $userId");
      print("settleBeforeSelling: $_settleBeforeSelling");
      print("settlementAmount: ${_amountController.text}");
      print("settlementLetterFile: $_settlementLetterFile");

      if (userId == null) {
        print("User ID is null. User is not logged in.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('User not logged in. Please log in and try again.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await firestore.collection('vehicles').doc(docId).update({
        'settleBeforeSelling': _settleBeforeSelling,
        'settlementAmount': _amountController.text,
        'settlementLetterFile': _settlementLetterFile ?? '', // Handle null case
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
          'docId': docId,
          'image': args['image'], // Pass along any required arguments
        },
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
    final Map<String, dynamic>? args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final File? imageFile = args?['image'] as File?;
    final String? docId = args?['docId'] as String?;

    if (args == null || docId == null) {
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
                                'Form Progress',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return Icon(
                                  Icons.star,
                                  color:
                                      index < 2 ? Colors.white : Colors.white70,
                                  size: 30,
                                );
                              }),
                            ),
                            const SizedBox(height: 20),
                            const Center(
                              child: Text(
                                'Do you require the truck to be settled before selling?',
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
                                    borderRadius: BorderRadius.circular(10.0),
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
                                'Please fill in our settlement amount',
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
                            Center(
                              child: CustomButton(
                                text: 'CONTINUE',
                                borderColor: orange,
                                onPressed: _isLoading
                                    ? () {}
                                    : () => _submitForm(docId, args),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
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
