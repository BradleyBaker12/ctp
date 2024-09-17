import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart'; // Import for Provider
import 'package:ctp/providers/vehicles_provider.dart'; // Import VehicleProvider
import 'package:ctp/providers/form_data_provider.dart'; // Import FormDataProvider
// import 'package:path/path.dart' as path; // Import path package

class SixthFormPage extends StatefulWidget {
  const SixthFormPage({super.key});

  @override
  _SixthFormPageState createState() => _SixthFormPageState();
}

class _SixthFormPageState extends State<SixthFormPage> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  final List<String> _treadOptions = ['10% - 50%', '51% - 79%', '80% - 100%'];

  // Add FormDataProvider instance
  late FormDataProvider formDataProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    formDataProvider = Provider.of<FormDataProvider>(context);
  }

  Future<void> _pickImage(ImageSource source, {required int index}) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          if (index == 1) {
            formDataProvider.setFrontRightTyre(File(pickedFile.path));
          } else if (index == 2) {
            formDataProvider.setFrontLeftTyre(File(pickedFile.path));
          } else if (index == 3) {
            formDataProvider.setSpareWheelTyre(File(pickedFile.path));
          }
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final FirebaseStorage storage = FirebaseStorage.instance;
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);

      String? vehicleId = vehicleProvider.vehicleId;

      if (vehicleId != null) {
        // Function to upload file to Firebase Storage
        Future<String?> uploadFile(File? file, String fileName) async {
          if (file == null) return null;
          final ref = storage.ref().child('vehicles/$vehicleId/$fileName');
          final task = ref.putFile(file);
          final snapshot = await task;
          return await snapshot.ref.getDownloadURL();
        }

        // Upload images and get URLs
        final frontRightTyreUrl = await uploadFile(
            formDataProvider.frontRightTyre, 'front_right_tyre.jpg');
        final frontLeftTyreUrl = await uploadFile(
            formDataProvider.frontLeftTyre, 'front_left_tyre.jpg');
        final spareWheelTyreUrl = await uploadFile(
            formDataProvider.spareWheelTyre, 'spare_wheel_tyre.jpg');

        // Update Firestore with URLs
        await firestore.collection('vehicles').doc(vehicleId).update({
          'tyreType': formDataProvider.tyreType ?? '',
          'spareTyre': formDataProvider.spareTyre ?? '',
          'frontRightTyre': frontRightTyreUrl,
          'frontLeftTyre': frontLeftTyreUrl,
          'spareWheelTyre': spareWheelTyreUrl,
          'treadLeft': formDataProvider.treadLeft ?? '',
        });

        print("Form submitted successfully!");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Form submitted successfully!')),
        );

        // Navigate to the next form
        formDataProvider.incrementFormIndex();
      } else {
        print('Error: vehicleId is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Vehicle ID is null.')),
        );
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
    final File? imageFile = formDataProvider.selectedMainImage;

    if (imageFile == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No image selected. Please go back and select an image.',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

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
                                'TRUCK/TYRES',
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
                                'Tyres',
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
                                _buildRadioButton('Virgin', 'virgin',
                                    groupValue: formDataProvider.tyreType ??
                                        'virgin', onChanged: (value) {
                                  setState(() {
                                    formDataProvider.setTyreType(value!);
                                  });
                                }),
                                const SizedBox(width: 20),
                                _buildRadioButton('Recaps', 'recaps',
                                    groupValue: formDataProvider.tyreType ??
                                        'virgin', onChanged: (value) {
                                  setState(() {
                                    formDataProvider.setTyreType(value!);
                                  });
                                }),
                              ],
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              value: formDataProvider.treadLeft,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide.none,
                                ),
                                hintStyle:
                                    const TextStyle(color: Colors.white70),
                                hintText: 'Drop down of Tread Left',
                              ),
                              dropdownColor: Colors.black,
                              style: const TextStyle(color: Colors.white),
                              items: _treadOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  formDataProvider.setTreadLeft(newValue!);
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildTyreImageUploadBlock(1, 'Front Right Tyre',
                                formDataProvider.frontRightTyre),
                            const SizedBox(height: 20),
                            _buildTyreImageUploadBlock(2, 'Front Left Tyre',
                                formDataProvider.frontLeftTyre),
                            const SizedBox(height: 20),
                            const Center(
                              child: Text(
                                'Spare Tyre',
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
                                    groupValue: formDataProvider.spareTyre ??
                                        'yes', onChanged: (value) {
                                  setState(() {
                                    formDataProvider.setSpareTyre(value!);
                                  });
                                }),
                                const SizedBox(width: 20),
                                _buildRadioButton('No', 'no',
                                    groupValue: formDataProvider.spareTyre ??
                                        'yes', onChanged: (value) {
                                  setState(() {
                                    formDataProvider.setSpareTyre(value!);
                                  });
                                }),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildTyreImageUploadBlock(3, 'Spare Wheel Tyre',
                                formDataProvider.spareWheelTyre),
                            const SizedBox(height: 20),
                            Center(
                              child: CustomButton(
                                text: _isLoading ? 'Submitting...' : 'CONTINUE',
                                borderColor: const Color(0xFFFF4E00),
                                onPressed: _isLoading ? () {} : _submitForm,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: TextButton(
                                onPressed: () {
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
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
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

  Widget _buildTyreImageUploadBlock(int index, String label, File? tyreImage) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickImageDialog(index),
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.white70, width: 1),
            ),
            child: Center(
              child: tyreImage == null
                  ? const Icon(Icons.add, color: Colors.blue, size: 40)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.file(
                        tyreImage,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  void _pickImageDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera, index: index);
              },
              child: const Text('Camera'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery, index: index);
              },
              child: const Text('Gallery'),
            ),
          ],
        );
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
