import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FifthFormPage extends StatefulWidget {
  const FifthFormPage({super.key});

  @override
  _FifthFormPageState createState() => _FifthFormPageState();
}

class _FifthFormPageState extends State<FifthFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _damageDescriptionController =
      TextEditingController();

  String _listDamages = 'yes';
  File? _dashboardPhoto;
  File? _faultCodesPhoto;
  final List<File?> _damagePhotos = [null];
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source, {required int index}) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          if (index == -1) {
            _dashboardPhoto = File(pickedFile.path);
          } else if (index == -2) {
            _faultCodesPhoto = File(pickedFile.path);
          } else {
            _damagePhotos[index] = File(pickedFile.path);
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

  void _removeDamagePhoto(int index) {
    setState(() {
      _damagePhotos.removeAt(index);
    });
  }

  Future<void> _submitForm(String docId, File? imageFile) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final FirebaseStorage storage = FirebaseStorage.instance;

      // Function to upload file to Firebase Storage
      Future<String> uploadFile(File file, String fileName) async {
        final ref = storage.ref().child('vehicles/$docId/$fileName');
        final task = ref.putFile(file);
        final snapshot = await task;
        return await snapshot.ref.getDownloadURL();
      }

      // Upload images and get URLs
      String? dashboardPhotoUrl;
      if (_dashboardPhoto != null) {
        dashboardPhotoUrl =
            await uploadFile(_dashboardPhoto!, 'dashboard_photo.jpg');
      }

      String? faultCodesPhotoUrl;
      if (_faultCodesPhoto != null) {
        faultCodesPhotoUrl =
            await uploadFile(_faultCodesPhoto!, 'fault_codes_photo.jpg');
      }

      List<String?> damagePhotoUrls =
          await Future.wait(_damagePhotos.map((file) async {
        if (file != null) {
          return await uploadFile(
              file, 'damage_photo_${_damagePhotos.indexOf(file)}.jpg');
        }
        return null;
      }).toList());

      // Update Firestore with URLs
      await firestore.collection('vehicles').doc(docId).update({
        'listDamages': _listDamages,
        'damageDescription': _damageDescriptionController.text,
        'dashboardPhoto': dashboardPhotoUrl,
        'faultCodesPhoto': faultCodesPhotoUrl,
        'damagePhotos': damagePhotoUrls,
      });

      print("Form submitted successfully!");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form submitted successfully!')),
      );

      // Navigate to the SixthFormPage
      Navigator.pushNamed(
        context,
        '/sixthTruckForm',
        arguments: {
          'docId': docId,
          'image': imageFile,
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
                                'Do you want to list damages and product faults?',
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
                                    groupValue: _listDamages,
                                    onChanged: (value) {
                                  setState(() {
                                    _listDamages = value!;
                                  });
                                }),
                                const SizedBox(width: 20),
                                _buildRadioButton('No', 'no',
                                    groupValue: _listDamages,
                                    onChanged: (value) {
                                  setState(() {
                                    _listDamages = value!;
                                  });
                                }),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (_listDamages == 'yes') ...[
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
                                  onTap: () => _pickImageDialog(-1),
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
                                      child: _dashboardPhoto == null
                                          ? const Icon(Icons.add,
                                              color: Colors.blue, size: 40)
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              child: Image.file(
                                                _dashboardPhoto!,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Center(
                                child: Text(
                                  'Photo of Dashboard',
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
                                  onTap: () => _pickImageDialog(-2),
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
                                      child: _faultCodesPhoto == null
                                          ? const Icon(Icons.add,
                                              color: Colors.blue, size: 40)
                                          : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              child: Image.file(
                                                _faultCodesPhoto!,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Center(
                                child: Text(
                                  'Clear Picture of Fault Codes',
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
                                  'Please describe and attach images of all damages',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildTextField(
                                  controller: _damageDescriptionController,
                                  hintText: 'Describe Damage'),
                              const SizedBox(height: 10),
                              Column(
                                children: List.generate(_damagePhotos.length,
                                    (index) {
                                  return _buildDamagePhotoField(index);
                                }),
                              ),
                              Center(
                                child: TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _damagePhotos.add(null);
                                    });
                                  },
                                  icon:
                                      const Icon(Icons.add, color: Colors.blue),
                                  label: const Text(
                                    'ADD NEW DAMAGE',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            Center(
                              child: CustomButton(
                                text: 'CONTINUE',
                                borderColor: const Color(0xFFFF4E00),
                                onPressed: _isLoading
                                    ? () {}
                                    : () => _submitForm(docId, imageFile),
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

  Widget _buildDamagePhotoField(int index) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _pickImageDialog(index),
          child: Container(
            height: 100,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.white70, width: 1),
            ),
            child: Center(
              child: _damagePhotos[index] == null
                  ? const Icon(Icons.add, color: Colors.blue, size: 40)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.file(
                        _damagePhotos[index]!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: GestureDetector(
            onTap: () => _removeDamagePhoto(index),
            child: const Icon(
              Icons.remove_circle,
              color: Colors.red,
              size: 24,
            ),
          ),
        ),
      ],
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
