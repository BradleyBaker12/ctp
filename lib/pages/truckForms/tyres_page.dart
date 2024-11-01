// lib/pages/truckForms/tyres_page.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart';

class TyresPage extends StatefulWidget {
  final String vehicleId;
  const TyresPage({Key? key, required this.vehicleId}) : super(key: key);

  @override
  TyresPageState createState() => TyresPageState();
}

class TyresPageState extends State<TyresPage>
    with AutomaticKeepAliveClientMixin {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage =
      FirebaseStorage.instance; // Firebase Storage instance

  String _chassisCondition =
      'good'; // Default selected value for chassis condition
  String _virginOrRecap =
      'virgin'; // Default selected value for virgin or recap
  String _rimType = 'aluminium'; // Default selected value for rim type

  // Lists to store damages, additional features, and fault codes
  List<Map<String, dynamic>> _damageList = [];
  List<Map<String, dynamic>> _additionalFeaturesList = [];
  List<Map<String, dynamic>> _faultCodesList = [];

  // Map to store selected images for different tyre positions
  Map<String, File?> _selectedImages = {};

  @override
  bool get wantKeepAlive => true; // Implementing the required getter

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16.0),
            // Generate Tyre Position Sections (Assuming 6 positions)
            ...List.generate(6, (index) => _buildTyrePosSection(index + 1)),
            const SizedBox(height: 16.0),
            // Optionally, add sections for damages, additional features, and fault codes here
          ],
        ),
      ),
    );
  }

  Widget _buildTyrePosSection(int pos) {
    String tyrePosKey = 'Tyre_Pos_$pos';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),
        Text(
          'Tyre Position $pos'.toUpperCase(),
          style: const TextStyle(
            fontSize: 20,
            color: Color.fromARGB(221, 255, 255, 255),
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16.0),
        _buildImageUploadBlock('$tyrePosKey Photo'),
        const SizedBox(height: 16.0),
        const Text(
          'Condition of the Chassis',
          style: TextStyle(
            fontSize: 16,
            color: Color.fromARGB(221, 255, 255, 255),
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CustomRadioButton(
              label: 'Poor',
              value: 'poor',
              groupValue: _chassisCondition,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _chassisCondition = value;
                  });
                }
              },
            ),
            CustomRadioButton(
              label: 'Good',
              value: 'good',
              groupValue: _chassisCondition,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _chassisCondition = value;
                  });
                }
              },
            ),
            CustomRadioButton(
              label: 'Excellent',
              value: 'excellent',
              groupValue: _chassisCondition,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _chassisCondition = value;
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        const Text(
          'Virgin or Recap',
          style: TextStyle(
            fontSize: 16,
            color: Color.fromARGB(221, 255, 255, 255),
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CustomRadioButton(
              label: 'Virgin',
              value: 'virgin',
              groupValue: _virginOrRecap,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _virginOrRecap = value;
                  });
                }
              },
            ),
            CustomRadioButton(
              label: 'Recap',
              value: 'recap',
              groupValue: _virginOrRecap,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _virginOrRecap = value;
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        const Text(
          'Aluminium or Steel Rim',
          style: TextStyle(
            fontSize: 16,
            color: Color.fromARGB(221, 255, 255, 255),
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CustomRadioButton(
              label: 'Aluminium',
              value: 'aluminium',
              groupValue: _rimType,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _rimType = value;
                  });
                }
              },
            ),
            CustomRadioButton(
              label: 'Steel',
              value: 'steel',
              groupValue: _rimType,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _rimType = value;
                  });
                }
              },
            ),
          ],
        ),
        const Divider(thickness: 1.0),
      ],
    );
  }

  Widget _buildImageUploadBlock(String title) {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(title),
      child: Container(
        height: 150.0,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.blue.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: AppColors.blue, width: 2.0),
        ),
        child: _selectedImages[title] == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline,
                      color: Colors.white, size: 40.0),
                  const SizedBox(height: 8.0),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(
                  _selectedImages[title]!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
      ),
    );
  }

  void _showImageSourceDialog(String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Image Source for $title'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final pickedFile =
                      await _picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    setState(() {
                      _selectedImages[title] = File(pickedFile.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final pickedFile =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      _selectedImages[title] = File(pickedFile.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Implement the saveData method
  Future<bool> saveData() async {
    try {
      final tyresRef = _firestore
          .collection('vehicles')
          .doc(widget.vehicleId)
          .collection('truckConditions')
          .doc('Tyres');

      // Prepare data to save
      Map<String, dynamic> dataToSave = {
        'chassisCondition': _chassisCondition,
        'virginOrRecap': _virginOrRecap,
        'rimType': _rimType,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Save tyre position photos
      for (var entry in _selectedImages.entries) {
        if (entry.value != null) {
          String imageUrl = await _uploadImage(entry.value!, entry.key);
          if (imageUrl.isNotEmpty) {
            dataToSave[entry.key] = imageUrl;
          }
        }
      }

      // Save data to Firestore
      await tyresRef.set(dataToSave, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tyres data saved successfully!')),
        );
      }

      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save tyres data: $e')),
        );
      }
      return false;
    }
  }

  // Method to upload image to Firebase Storage
  Future<String> _uploadImage(File file, String key) async {
    try {
      String fileName =
          'tyres/${widget.vehicleId}_$key${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = _storage.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(file);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
      return '';
    }
  }
}
