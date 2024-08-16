import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';

class FirstTruckForm extends StatefulWidget {
  final String vehicleType;

  const FirstTruckForm({super.key, required this.vehicleType});

  @override
  _FirstTruckFormState createState() => _FirstTruckFormState();
}

class _FirstTruckFormState extends State<FirstTruckForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _makeModelController = TextEditingController();
  final TextEditingController _bookValueController = TextEditingController();
  final TextEditingController _vinNumberController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();

  File? _selectedMainImage;
  File? _selectedLicenceDiskImage;
  late String _vehicleType;
  String _weightClass = 'heavy';
  bool _isLoading = false;
  String? _selectedMileage;

  final List<String> _mileageOptions = [
    '0+',
    '10,001+',
    '20,001+',
    '50,001+',
    '100,001+',
    '200,001+',
    '500,001+',
    '1,000,001+'
  ];

  @override
  void initState() {
    super.initState();
    _vehicleType = widget.vehicleType; // Set initial vehicle type
  }

  Future<void> _pickImage(ImageSource source,
      {required bool isLicenceDisk}) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          if (isLicenceDisk) {
            _selectedLicenceDiskImage = File(pickedFile.path);
          } else {
            _selectedMainImage = File(pickedFile.path);
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userId!;
      final FirebaseStorage storage = FirebaseStorage.instance;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      final docRef = await firestore.collection('vehicles').add({
        'year': _yearController.text,
        'makeModel': _makeModelController.text,
        'mileage': _selectedMileage,
        'bookValue': _bookValueController.text,
        'vinNumber': _vinNumberController.text,
        'vehicleType': _vehicleType,
        'weightClass': _weightClass,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(), // Add timestamp
      });

      final vehicleId = docRef.id;

      Future<String> uploadFile(String filePath, String fileName) async {
        final ref = storage.ref().child('vehicles/$vehicleId/$fileName');
        final task = ref.putFile(File(filePath));
        final snapshot = await task;
        return await snapshot.ref.getDownloadURL();
      }

      final mainImageUrl = _selectedMainImage != null
          ? await uploadFile(_selectedMainImage!.path, 'main_image.jpg')
          : null;

      final licenceDiskUrl = _selectedLicenceDiskImage != null
          ? await uploadFile(
              _selectedLicenceDiskImage!.path, 'licence_disk.jpg')
          : null;

      await docRef.update({
        'mainImageUrl': mainImageUrl,
        'licenceDiskUrl': licenceDiskUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form submitted successfully!')),
      );

      Navigator.pushNamed(
        context,
        '/secondTruckForm',
        arguments: {
          'docId': docRef.id,
          'image': _selectedMainImage,
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
                                  width: MediaQuery.of(context)
                                      .size
                                      .width, // Ensures full screen width
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: _selectedMainImage == null
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.camera_alt,
                                                      size: 40,
                                                      color: Colors.white),
                                                  onPressed: () {
                                                    _pickImage(
                                                        ImageSource.camera,
                                                        isLicenceDisk: false);
                                                  },
                                                ),
                                                const SizedBox(width: 20),
                                                IconButton(
                                                  icon: const Icon(Icons.photo,
                                                      size: 40,
                                                      color: Colors.white),
                                                  onPressed: () {
                                                    _pickImage(
                                                        ImageSource.gallery,
                                                        isLicenceDisk: false);
                                                  },
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            const Text(
                                              'NEW PHOTO OR UPLOAD FROM GALLERY',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        )
                                      : ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          child: Image.file(
                                            _selectedMainImage!,
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
                              'Please fill out the required details below\nYour trusted partner on the road.',
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
                            children: [
                              _buildRadioButton('Truck', 'truck'),
                              const SizedBox(width: 20),
                              _buildRadioButton('Trailer', 'trailer'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildRadioButton('Heavy', 'heavy',
                                  isWeight: true),
                              const SizedBox(width: 20),
                              _buildRadioButton('Medium', 'medium',
                                  isWeight: true),
                              const SizedBox(width: 20),
                              _buildRadioButton('Light', 'light',
                                  isWeight: true),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                          controller: _yearController,
                                          hintText: 'Year'),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildTextField(
                                          controller: _makeModelController,
                                          hintText: 'Make/Model'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                _buildMileageDropdown(),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _bookValueController,
                                    hintText: 'Book Value'),
                                const SizedBox(height: 15),
                                _buildTextField(
                                    controller: _vinNumberController,
                                    hintText: 'VIN Number'),
                                const SizedBox(height: 20),
                                Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      _pickImage(ImageSource.gallery,
                                          isLicenceDisk: true);
                                    },
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
                                        child: _selectedLicenceDiskImage == null
                                            ? const Icon(Icons.add,
                                                color: Colors.blue, size: 40)
                                            : ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                                child: Image.file(
                                                  _selectedLicenceDiskImage!,
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
                                    'UPLOAD LICENCE DISK',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: CustomButton(
                                    text: 'CONTINUE',
                                    borderColor: orange,
                                    onPressed: _isLoading ? () {} : _submitForm,
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
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.orange,
                ),
              ),
            ),
        ],
      ),
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

  Widget _buildMileageDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedMileage,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        hintText: 'Mileage',
        hintStyle: const TextStyle(color: Colors.white70),
      ),
      dropdownColor:
          Colors.black.withOpacity(0.7), // Background color of dropdown
      style:
          const TextStyle(color: Colors.white), // Text color of selected item
      items: _mileageOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: const TextStyle(color: Colors.white), // Text color of items
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedMileage = newValue;
          _mileageController.text = newValue!;
        });
      },
    );
  }

  Widget _buildRadioButton(String label, String value,
      {bool isWeight = false}) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: isWeight ? _weightClass : _vehicleType,
          onChanged: (String? newValue) {
            setState(() {
              if (isWeight) {
                _weightClass = newValue!;
              } else {
                _vehicleType = newValue!;
              }
            });
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
