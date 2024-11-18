// lib/pages/truckForms/tyres_page.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart';

class TyresEditPage extends StatefulWidget {
  final String vehicleId;
  final VoidCallback onProgressUpdate;
  final bool isEditing;

  const TyresEditPage({
    super.key,
    required this.vehicleId,
    required this.onProgressUpdate,
    this.isEditing = false,
  });

  @override
  TyresEditPageState createState() => TyresEditPageState();
}

class TyresEditPageState extends State<TyresEditPage>
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

  // Map to store image URLs
  final Map<String, String> _imageUrls = {};

  bool _isInitialized = false; // Flag to prevent re-initialization

  @override
  void initState() {
    super.initState();
    // Initialize maps without default values
    for (int i = 1; i <= 6; i++) {
      _chassisConditions[i] = '';
      _virginOrRecaps[i] = '';
      _rimTypes[i] = '';
    }
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
          'Condition of the Tyre',
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
              groupValue: _chassisConditions[pos] ?? '',
              onChanged: (String? value) {
                if (value != null) {
                  _updateAndNotify(() {
                    _chassisConditions[pos] = value;
                  });
                }
              },
            ),
            CustomRadioButton(
              label: 'Good',
              value: 'good',
              groupValue: _chassisConditions[pos] ?? '',
              onChanged: (String? value) {
                if (value != null) {
                  _updateAndNotify(() {
                    _chassisConditions[pos] = value;
                  });
                }
              },
            ),
            CustomRadioButton(
              label: 'Excellent',
              value: 'excellent',
              groupValue: _chassisConditions[pos] ?? '',
              onChanged: (String? value) {
                if (value != null) {
                  _updateAndNotify(() {
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
              groupValue: _virginOrRecaps[pos] ?? '',
              onChanged: (String? value) {
                if (value != null) {
                  _updateAndNotify(() {
                    _virginOrRecaps[pos] = value;
                  });
                }
              },
            ),
            CustomRadioButton(
              label: 'Recap',
              value: 'recap',
              groupValue: _virginOrRecaps[pos] ?? '',
              onChanged: (String? value) {
                if (value != null) {
                  _updateAndNotify(() {
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
              groupValue: _rimTypes[pos] ?? '',
              onChanged: (String? value) {
                if (value != null) {
                  _updateAndNotify(() {
                    _rimTypes[pos] = value;
                  });
                }
              },
            ),
            CustomRadioButton(
              label: 'Steel',
              value: 'steel',
              groupValue: _rimTypes[pos] ?? '',
              onChanged: (String? value) {
                if (value != null) {
                  _updateAndNotify(() {
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
    bool isTyrePos3 = title == 'Tyre_Pos_3 Photo';

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
        child: Stack(
          children: [
            // Main image display
            Center(
              // Wrap with Center widget
              child: _selectedImages[title] != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(
                        _selectedImages[title]!,
                        fit: isTyrePos3 ? BoxFit.contain : BoxFit.cover,
                        width: isTyrePos3 ? null : double.infinity,
                        height: isTyrePos3 ? null : double.infinity,
                      ),
                    )
                  : _imageUrls[title] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            _imageUrls[title]!,
                            fit: isTyrePos3 ? BoxFit.contain : BoxFit.cover,
                            width: isTyrePos3 ? null : double.infinity,
                            height: isTyrePos3 ? null : double.infinity,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
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
            // Overlay hint for editing
            if (_selectedImages[title] != null || _imageUrls[title] != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Tap to modify image',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
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
                    _updateAndNotify(() {
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
                    _updateAndNotify(() {
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

  Future<bool> saveData() async {
    // You can implement save logic here if needed
    return true;
  }

  void initializeWithData(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    setState(() {
      // _isInitialized = true;
      data.forEach((key, value) {
        if (key.startsWith('Tyre_Pos_')) {
          final pos = int.parse(key.split('_').last);
          _chassisConditions[pos] = value['chassisCondition'] ?? 'good';
          _virginOrRecaps[pos] = value['virginOrRecap'] ?? 'virgin';
          _rimTypes[pos] = value['rimType'] ?? 'aluminium';

          String photoKey = '$key Photo';

          // Handle image data
          if (value['imageUrl'] != null) {
            _imageUrls[photoKey] = value['imageUrl'];
          }
          if (value['imagePath'] != null) {
            _selectedImages[photoKey] = File(value['imagePath']);
          }
        }
      });
    });
  }

  Future<Map<String, dynamic>> getData() async {
    Map<String, dynamic> data = {};

    // Get data for each tyre position
    for (int pos = 1; pos <= 6; pos++) {
      String posKey = 'Tyre_Pos_$pos';
      String photoKey = '$posKey Photo';

      data[posKey] = {
        'chassisCondition': _chassisConditions[pos] ?? '',
        'virginOrRecap': _virginOrRecaps[pos] ?? '',
        'rimType': _rimTypes[pos] ?? '',
      };

      // Handle image data
      if (_selectedImages[photoKey] != null) {
        data[posKey]['imagePath'] = _selectedImages[photoKey]!.path;
        data[posKey]['isNew'] = 'true';
      } else if (_imageUrls[photoKey] != null) {
        data[posKey]['imageUrl'] = _imageUrls[photoKey];
        data[posKey]['isNew'] = 'false';
      }
    }

    return data;
  }

  void reset() {
    setState(() {
      // Reset conditions to empty strings
      for (int i = 1; i <= 6; i++) {
        _chassisConditions[i] = '';
        _virginOrRecaps[i] = '';
        _rimTypes[i] = '';
      }

      // Clear images
      _selectedImages.clear();
      _imageUrls.clear();

      _isInitialized = false;
    });
  }

  double getCompletionPercentage() {
    int totalFields = 24; // 6 positions × (1 image + 3 selections) = 24 fields
    int filledFields = 0;

    // Check each tyre position (6 positions)
    for (int pos = 1; pos <= 6; pos++) {
      String photoKey = 'Tyre_Pos_$pos Photo';

      // Check image (1 field per position)
      if (_selectedImages[photoKey] != null || _imageUrls[photoKey] != null) {
        filledFields++;
      }

      // Check chassis condition (1 field per position)
      if (_chassisConditions[pos]?.isNotEmpty == true) {
        filledFields++;
      }

      // Check virgin/recap selection (1 field per position)
      if (_virginOrRecaps[pos]?.isNotEmpty == true) {
        filledFields++;
      }

      // Check rim type selection (1 field per position)
      if (_rimTypes[pos]?.isNotEmpty == true) {
        filledFields++;
      }
    }

    return (filledFields / totalFields).clamp(0.0, 1.0);
  }

  void _updateAndNotify(VoidCallback updateFunction) {
    setState(() {
      updateFunction();
    });
    widget.onProgressUpdate();
  }
}
