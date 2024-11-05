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
  const TyresPage({super.key, required this.vehicleId});

  @override
  TyresPageState createState() => TyresPageState();
}

class TyresPageState extends State<TyresPage>
    with AutomaticKeepAliveClientMixin {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage =
      FirebaseStorage.instance; // Firebase Storage instance

  // Replace single state variables with maps to store values for each position
  final Map<int, String> _chassisConditions = {};
  final Map<int, String> _virginOrRecaps = {};
  final Map<int, String> _rimTypes = {};

  // Map to store selected images for different tyre positions
  final Map<String, File?> _selectedImages = {};

  // Add this field to store image URLs
  final Map<String, String> _imageUrls = {};

  @override
  void initState() {
    super.initState();
    // Initialize default values
    for (int i = 1; i <= 6; i++) {
      _chassisConditions[i] = 'good';
      _virginOrRecaps[i] = 'virgin';
      _rimTypes[i] = 'aluminium';
    }
    // Load saved data
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    try {
      // First try to load from the main vehicle document's truckConditions
      final vehicleDoc =
          await _firestore.collection('vehicles').doc(widget.vehicleId).get();

      if (vehicleDoc.exists && vehicleDoc.data() != null) {
        final truckConditions = vehicleDoc.data()!['truckConditions'];
        if (truckConditions != null && truckConditions['tyres'] != null) {
          final tyresData = truckConditions['tyres'] as Map<String, dynamic>;
          _initializeFromData(tyresData);
          return;
        }
      }

      // Fallback: try to load from the legacy inspections subcollection
      final doc = await _firestore
          .collection('vehicles')
          .doc(widget.vehicleId)
          .collection('inspections')
          .doc('tyres')
          .get();

      if (doc.exists && doc.data() != null) {
        final positions = doc.data()!['positions'] as Map<String, dynamic>;
        _initializeFromData(positions);
      }
    } catch (e) {
      print('Error loading tyres data: $e');
    }
  }

  void _initializeFromData(Map<String, dynamic> data) {
    setState(() {
      data.forEach((key, value) {
        if (key.startsWith('Tyre_Pos_')) {
          final pos = int.parse(key.split('_').last);
          _chassisConditions[pos] = value['chassisCondition'] ?? 'good';
          _virginOrRecaps[pos] = value['virginOrRecap'] ?? 'virgin';
          _rimTypes[pos] = value['rimType'] ?? 'aluminium';

          // Handle image URL
          if (value['imageUrl'] != null) {
            if (value['imageUrl'] is Map) {
              var imageUrl = value['imageUrl'];
              if (imageUrl['isNew'] == true) {
                _selectedImages['$key Photo'] = File(imageUrl['path']);
              } else {
                _imageUrls['$key Photo'] = imageUrl['url'];
              }
            } else if (value['imageUrl'] is String) {
              _imageUrls['$key Photo'] = value['imageUrl'];
            }
          }
        }
      });
    });
  }

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
              groupValue: _chassisConditions[pos] ?? 'good',
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _chassisConditions[pos] = value;
                  });
                }
              },
            ),
            CustomRadioButton(
              label: 'Good',
              value: 'good',
              groupValue: _chassisConditions[pos] ?? 'good',
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _chassisConditions[pos] = value;
                  });
                }
              },
            ),
            CustomRadioButton(
              label: 'Excellent',
              value: 'excellent',
              groupValue: _chassisConditions[pos] ?? 'good',
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _chassisConditions[pos] = value;
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
              groupValue: _virginOrRecaps[pos] ?? 'virgin',
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _virginOrRecaps[pos] = value;
                  });
                }
              },
            ),
            CustomRadioButton(
              label: 'Recap',
              value: 'recap',
              groupValue: _virginOrRecaps[pos] ?? 'virgin',
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _virginOrRecaps[pos] = value;
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
              groupValue: _rimTypes[pos] ?? 'aluminium',
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _rimTypes[pos] = value;
                  });
                }
              },
            ),
            CustomRadioButton(
              label: 'Steel',
              value: 'steel',
              groupValue: _rimTypes[pos] ?? 'aluminium',
              onChanged: (String? value) {
                if (value != null) {
                  setState(() {
                    _rimTypes[pos] = value;
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
        child: _selectedImages[title] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(
                  _selectedImages[title]!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
            : _imageUrls[title] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      _imageUrls[title]!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                : Column(
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

  // Update the saveData method to save directly to the vehicle document
  Future<bool> saveData() async {
    try {
      Map<String, dynamic> tyreData = {};

      // Process each tyre position
      for (int pos = 1; pos <= 6; pos++) {
        String posKey = 'Tyre_Pos_$pos';
        String photoKey = '$posKey Photo';

        // Create base data object for this position
        tyreData[posKey] = {
          'chassisCondition': _chassisConditions[pos],
          'virginOrRecap': _virginOrRecaps[pos],
          'rimType': _rimTypes[pos],
        };

        // Handle image upload and URLs
        if (_selectedImages[photoKey] != null) {
          String imagePath =
              'vehicles/${widget.vehicleId}/tyres/positions/${posKey}_${DateTime.now().millisecondsSinceEpoch}';
          String imageUrl =
              await _uploadImage(_selectedImages[photoKey]!, imagePath);
          if (imageUrl.isNotEmpty) {
            tyreData[posKey]['imageUrl'] = imageUrl;
          }
        } else if (_imageUrls[photoKey] != null) {
          tyreData[posKey]['imageUrl'] = _imageUrls[photoKey];
        }
      }

      // Save to the main vehicle document
      await _firestore.collection('vehicles').doc(widget.vehicleId).set({
        'truckConditions': {
          'tyres': tyreData,
        },
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error saving tyres data: $e');
      return false;
    }
  }

  // Method to upload image to Firebase Storage
  // Future<String> _uploadImage(File file, String key) async {
  //   try {
  //     String fileName =
  //         'tyres/${widget.vehicleId}_$key${DateTime.now().millisecondsSinceEpoch}.jpg';
  //     Reference storageRef = _storage.ref().child(fileName);
  //     UploadTask uploadTask = storageRef.putFile(file);

  //     TaskSnapshot snapshot = await uploadTask;
  //     String downloadUrl = await snapshot.ref.getDownloadURL();

  //     return downloadUrl;
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error uploading image: $e')),
  //       );
  //     }
  //     return '';
  //   }
  // }

  void initializeWithData(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    setState(() {
      data.forEach((key, value) {
        if (key.startsWith('Tyre_Pos_')) {
          final pos = int.parse(key.split('_').last);
          _chassisConditions[pos] = value['chassisCondition'] ?? 'good';
          _virginOrRecaps[pos] = value['virginOrRecap'] ?? 'virgin';
          _rimTypes[pos] = value['rimType'] ?? 'aluminium';

          // Handle image URL
          if (value['imageUrl'] != null) {
            _imageUrls['$key Photo'] = value['imageUrl'];
          }
        }
      });
    });
  }

  // Update getData method to properly handle image data
  Future<Map<String, dynamic>> getData() async {
    try {
      Map<String, dynamic> data = {};

      // Get data for each tyre position
      for (int pos = 1; pos <= 6; pos++) {
        String posKey = 'Tyre_Pos_$pos';
        String photoKey = '$posKey Photo';

        data[posKey] = {
          'chassisCondition': _chassisConditions[pos],
          'virginOrRecap': _virginOrRecaps[pos],
          'rimType': _rimTypes[pos],
        };

        // Handle image data
        if (_selectedImages[photoKey] != null) {
          // Upload new image and get URL
          String imagePath =
              'vehicles/${widget.vehicleId}/tyres/positions/${posKey}_${DateTime.now().millisecondsSinceEpoch}';
          String imageUrl =
              await _uploadImage(_selectedImages[photoKey]!, imagePath);
          if (imageUrl.isNotEmpty) {
            data[posKey]['imageUrl'] = imageUrl;
          }
        } else if (_imageUrls[photoKey] != null) {
          // Use existing image URL
          data[posKey]['imageUrl'] = _imageUrls[photoKey];
        }
      }

      return data;
    } catch (e) {
      print('Error in getData: $e');
      return {};
    }
  }

  // Update _uploadImage method to handle errors better
  Future<String> _uploadImage(File file, String path) async {
    try {
      Reference storageRef = _storage.ref().child(path);
      UploadTask uploadTask = storageRef.putFile(file);

      // Show upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Upload progress: $progress%');
      });

      // Wait for upload to complete
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
      return '';
    }
  }
}
