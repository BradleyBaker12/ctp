// lib/pages/truckForms/drive_train_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart';

class DriveTrainPage extends StatefulWidget {
  final String vehicleId;
  final VoidCallback onProgressUpdate;
  final bool isEditing;

  const DriveTrainPage({
    super.key,
    required this.vehicleId,
    required this.onProgressUpdate,
    this.isEditing = false,
  });

  @override
  DriveTrainPageState createState() => DriveTrainPageState();
}

class DriveTrainPageState extends State<DriveTrainPage>
    with AutomaticKeepAliveClientMixin {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage =
      FirebaseStorage.instance; // Firebase Storage instance

  String _selectedCondition = 'good'; // Default selected value
  String _oilLeakConditionEngine = 'no';
  String _waterLeakConditionEngine = 'no';
  String _blowbyCondition = 'no';
  String _oilLeakConditionGearbox = 'no';
  String _retarderCondition = 'no';

  // Map to store selected images for different sections
  final Map<String, File?> _selectedImages = {
    'Down': null,
    'Left': null,
    'Up': null,
    'Right': null,
    'Engine Left': null,
    'Engine Right': null,
    'Gearbox Top View': null,
    'Gearbox Bottom View': null,
    'Gearbox Rear Panel': null,
    'Diffs top view of front diff': null,
    'Diffs bottom view of diff front': null,
    'Diffs top view of rear diff': null,
    'Diffs bottom view of rear diff': null,
    'Engine Oil Leak': null,
    'Engine Water Leak': null,
    'Gearbox Oil Leak': null,
  };

  // Add a map to store image URLs
  final Map<String, String> _imageUrls = {};

  bool _isInitialized = false; // Flag to prevent re-initialization

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16.0),
            Text(
              'Details for DRIVE TRAIN'.toUpperCase(),
              style: const TextStyle(
                fontSize: 25,
                color: Color.fromARGB(221, 255, 255, 255),
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Condition of the Drive Train',
              style: TextStyle(
                fontSize: 16,
                color: Color.fromARGB(221, 255, 255, 255),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            // Condition Radio Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomRadioButton(
                  label: 'Poor',
                  value: 'poor',
                  groupValue: _selectedCondition,
                  onChanged: _updateCondition,
                ),
                CustomRadioButton(
                  label: 'Good',
                  value: 'good',
                  groupValue: _selectedCondition,
                  onChanged: _updateCondition,
                ),
                CustomRadioButton(
                  label: 'Excellent',
                  value: 'excellent',
                  groupValue: _selectedCondition,
                  onChanged: _updateCondition,
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            const Divider(thickness: 1.0),
            const SizedBox(height: 16.0),

            // Photos Section
            Text(
              'Photos'.toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                color: Color.fromARGB(221, 255, 255, 255),
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),

            // Grid of Photos (Down, Left, Up, Right)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              children: _selectedImages.keys
                  .where((key) =>
                      key.contains('Left') ||
                      key.contains('Right') ||
                      key.contains('Down') ||
                      key.contains('Up'))
                  .map((key) => _buildPhotoBlock(key))
                  .toList(),
            ),
            const SizedBox(height: 16.0),
            const Divider(thickness: 1.0),
            const SizedBox(height: 16.0),

            // Engine Section
            Text(
              'Engine'.toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                color: Color.fromARGB(221, 255, 255, 255),
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),

            // Engine Photos (Engine Left/Right but not leaks)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              children: _selectedImages.keys
                  .where(
                      (key) => key.contains('Engine') && !key.contains('Leak'))
                  .map((key) => _buildPhotoBlock(key))
                  .toList(),
            ),
            const SizedBox(height: 16.0),

            // Engine Oil Leak Section
            _buildYesNoSection(
              title: 'Are there any oil leaks in the engine?',
              groupValue: _oilLeakConditionEngine,
              onChanged: _updateOilLeakCondition,
              imageKey: 'Engine Oil Leak',
            ),
            const SizedBox(height: 16.0),

            // Engine Water Leak Section
            _buildYesNoSection(
              title: 'Are there any water leaks in the engine?',
              groupValue: _waterLeakConditionEngine,
              onChanged: _updateWaterLeakCondition,
              imageKey: 'Engine Water Leak',
            ),
            const SizedBox(height: 16.0),

            // Blowby Condition Section (No Image)
            _buildYesNoRadioOnlySection(
              title: 'Is there blowby/engine breathing?',
              groupValue: _blowbyCondition,
              onChanged: _updateBlowbyCondition,
            ),
            const SizedBox(height: 16.0),
            const Divider(thickness: 1.0),
            const SizedBox(height: 16.0),

            // Gearbox Section
            Text(
              'Gearbox'.toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                color: Color.fromARGB(221, 255, 255, 255),
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),

            // Gearbox Photos (but not leaks)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              children: _selectedImages.keys
                  .where(
                      (key) => key.contains('Gearbox') && !key.contains('Leak'))
                  .map((key) => _buildPhotoBlock(key))
                  .toList(),
            ),
            const SizedBox(height: 16.0),

            // Gearbox Oil Leak Section
            _buildYesNoSection(
              title: 'Are there any oil leaks in the gearbox?',
              groupValue: _oilLeakConditionGearbox,
              onChanged: _updateGearboxOilLeakCondition,
              imageKey: 'Gearbox Oil Leak',
            ),
            const SizedBox(height: 16.0),

            // Retarder Condition Section (No Image)
            _buildYesNoRadioOnlySection(
              title: 'Does the gearbox come with a retarder?',
              groupValue: _retarderCondition,
              onChanged: _updateRetarderCondition,
            ),
            const SizedBox(height: 16.0),
            const Divider(thickness: 1.0),
            const SizedBox(height: 16.0),

            // Diffs Section
            Text(
              'Diffs (Differentials)'.toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                color: Color.fromARGB(221, 255, 255, 255),
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),

            // Diffs Photos
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              children: _selectedImages.keys
                  .where((key) => key.contains('Diffs'))
                  .map((key) => _buildPhotoBlock(key))
                  .toList(),
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  /// Creates a photo block that includes an "X" (delete) button if an image is present.
  Widget _buildPhotoBlock(String title) {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(title),
      child: Container(
        width: double.infinity,
        height: 130,
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
            : Stack(
                children: [
                  // Display the image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(
                      _selectedImages[title]!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),

                  // 'X' button to remove the image
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // Stop the parent onTap from also firing
                        setState(() {
                          _selectedImages[title] = null;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4.0),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // Method to show the dialog for selecting image source (Camera or Gallery)
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

  // Helper method to build yes/no section with optional image upload
  Widget _buildYesNoSection({
    required String title,
    required String groupValue,
    required ValueChanged<String?> onChanged,
    required String imageKey,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            color: Color.fromARGB(221, 255, 255, 255),
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomRadioButton(
              label: 'Yes',
              value: 'yes',
              groupValue: groupValue,
              onChanged: onChanged,
            ),
            const SizedBox(width: 15),
            CustomRadioButton(
              label: 'No',
              value: 'no',
              groupValue: groupValue,
              onChanged: onChanged,
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        // If user selects yes, show the image block with an 'X' button
        if (groupValue == 'yes') _buildPhotoBlock(imageKey),
      ],
    );
  }

  // Helper method to build yes/no section without image upload
  Widget _buildYesNoRadioOnlySection({
    required String title,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            color: Color.fromARGB(221, 255, 255, 255),
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomRadioButton(
              label: 'Yes',
              value: 'yes',
              groupValue: groupValue,
              onChanged: onChanged,
            ),
            const SizedBox(width: 15),
            CustomRadioButton(
              label: 'No',
              value: 'no',
              groupValue: groupValue,
              onChanged: onChanged,
            ),
          ],
        ),
      ],
    );
  }

  // Method to upload images (if required)
  Future<bool> saveData() async {
    // You can implement save logic here if needed
    return true;
  }

  void initializeWithData(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    setState(() {
      // _isInitialized = true
      // Initialize basic fields
      _selectedCondition = data['condition'] ?? 'good';
      _oilLeakConditionEngine = data['engineOilLeak'] ?? 'no';
      _waterLeakConditionEngine = data['engineWaterLeak'] ?? 'no';
      _blowbyCondition = data['blowbyCondition'] ?? 'no';
      _oilLeakConditionGearbox = data['gearboxOilLeak'] ?? 'no';
      _retarderCondition = data['retarderCondition'] ?? 'no';

      // Initialize images
      if (data['images'] != null) {
        Map<String, dynamic> images = Map<String, dynamic>.from(data['images']);
        images.forEach((key, value) {
          if (value is Map && value['path'] != null) {
            _selectedImages[key] = File(value['path']);
          } else if (value is Map && value['url'] != null) {
            // Store URL for later use
            _imageUrls[key] = value['url'];
          }
        });
      }
    });
  }

  Future<String> _uploadImageToFirebase(File imageFile, String section) async {
    String fileName =
        'drive_train/${widget.vehicleId}_${section}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = storageRef.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<Map<String, dynamic>> getData() async {
    Map<String, dynamic> serializedImages = {};
    for (var entry in _selectedImages.entries) {
      if (entry.value != null) {
        String imageUrl = await _uploadImageToFirebase(
          entry.value!,
          entry.key.replaceAll(' ', '_').toLowerCase(),
        );
        serializedImages[entry.key] = {
          'url': imageUrl,
          'path': entry.value!.path,
          'isNew': true,
        };
      } else if (_imageUrls.containsKey(entry.key)) {
        serializedImages[entry.key] = {
          'url': _imageUrls[entry.key],
          'isNew': false,
        };
      }
    }

    return {
      'condition': _selectedCondition,
      'engineOilLeak': _oilLeakConditionEngine,
      'engineWaterLeak': _waterLeakConditionEngine,
      'blowbyCondition': _blowbyCondition,
      'gearboxOilLeak': _oilLeakConditionGearbox,
      'retarderCondition': _retarderCondition,
      'images': serializedImages,
    };
  }

  void reset() {
    setState(() {
      _selectedCondition = 'good';
      _oilLeakConditionEngine = 'no';
      _waterLeakConditionEngine = 'no';
      _blowbyCondition = 'no';
      _oilLeakConditionGearbox = 'no';
      _retarderCondition = 'no';

      // Clear selected images
      _selectedImages.forEach((key, _) {
        _selectedImages[key] = null;
      });

      // Clear image URLs
      _imageUrls.clear();

      _isInitialized = false; // Allow re-initialization if needed
    });
  }

  double getCompletionPercentage() {
    int totalFields = 19; // Total number of fields to fill
    int filledFields = 0;

    // Check condition selection (1 field)
    if (_selectedCondition.isNotEmpty) filledFields++;

    // Check all images (16 fields)
    _selectedImages.forEach((key, value) {
      // Only count non-leak images or leak images when their condition is 'yes'
      if (key.contains('Leak')) {
        if ((_oilLeakConditionEngine == 'yes' && key == 'Engine Oil Leak') ||
            (_waterLeakConditionEngine == 'yes' &&
                key == 'Engine Water Leak') ||
            (_oilLeakConditionGearbox == 'yes' && key == 'Gearbox Oil Leak')) {
          if (value != null) filledFields++;
        }
      } else {
        if (value != null) filledFields++;
      }
    });

    // Check conditions (5 fields)
    // Oil leak engine
    if (_oilLeakConditionEngine == 'no' ||
        (_oilLeakConditionEngine == 'yes' &&
            _selectedImages['Engine Oil Leak'] != null)) {
      filledFields++;
    }

    // Water leak engine
    if (_waterLeakConditionEngine == 'no' ||
        (_waterLeakConditionEngine == 'yes' &&
            _selectedImages['Engine Water Leak'] != null)) {
      filledFields++;
    }

    // Blowby condition
    if (_blowbyCondition.isNotEmpty) filledFields++;

    // Gearbox oil leak
    if (_oilLeakConditionGearbox == 'no' ||
        (_oilLeakConditionGearbox == 'yes' &&
            _selectedImages['Gearbox Oil Leak'] != null)) {
      filledFields++;
    }

    // Retarder condition
    if (_retarderCondition.isNotEmpty) filledFields++;

    // Ensure we don't exceed 1.0 and handle potential division errors
    return (filledFields / totalFields).clamp(0.0, 1.0);
  }

  // Add helper method for updates
  void _updateAndNotify(VoidCallback updateFunction) {
    setState(() {
      updateFunction();
    });
    widget.onProgressUpdate();
  }

  // For condition selection
  void _updateCondition(String? value) {
    if (value != null) {
      _updateAndNotify(() {
        _selectedCondition = value;
      });
    }
  }

  // For oil leak condition
  void _updateOilLeakCondition(String? value) {
    if (value != null) {
      _updateAndNotify(() {
        _oilLeakConditionEngine = value;
        if (value == 'no') {
          _selectedImages['Engine Oil Leak'] = null;
        }
      });
    }
  }

  // For water leak condition
  void _updateWaterLeakCondition(String? value) {
    if (value != null) {
      _updateAndNotify(() {
        _waterLeakConditionEngine = value;
        if (value == 'no') {
          _selectedImages['Engine Water Leak'] = null;
        }
      });
    }
  }

  // For blowby condition
  void _updateBlowbyCondition(String? value) {
    if (value != null) {
      _updateAndNotify(() {
        _blowbyCondition = value;
      });
    }
  }

  // For gearbox oil leak condition
  void _updateGearboxOilLeakCondition(String? value) {
    if (value != null) {
      _updateAndNotify(() {
        _oilLeakConditionGearbox = value;
        if (value == 'no') {
          _selectedImages['Gearbox Oil Leak'] = null;
        }
      });
    }
  }

  // For retarder condition
  void _updateRetarderCondition(String? value) {
    if (value != null) {
      _updateAndNotify(() {
        _retarderCondition = value;
      });
    }
  }

  // For image selection
  Future<void> _updateImage(String title, File imageFile) async {
    _updateAndNotify(() {
      _selectedImages[title] = imageFile;
    });
  }
}
