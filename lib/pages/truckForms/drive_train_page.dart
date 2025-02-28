// lib/pages/truckForms/drive_train_page.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart';
// Added for platformViewRegistry
// For web camera access

// Import the camera helper for cross-platform photo capture
import 'package:ctp/utils/camera_helper.dart';

class ImageData {
  File? file;
  Uint8List? webImage;
  String? url;

  ImageData({this.file, this.webImage, this.url});

  bool get hasImage =>
      file != null || webImage != null || (url != null && url!.isNotEmpty);
}

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
  final Map<String, ImageData> _selectedImages = {
    'Down': ImageData(),
    'Left': ImageData(),
    'Up': ImageData(),
    'Right': ImageData(),
    'Engine Left': ImageData(),
    'Engine Right': ImageData(),
    'Gearbox Top View': ImageData(),
    'Gearbox Bottom View': ImageData(),
    'Gearbox Rear Panel': ImageData(),
    'Diffs top view of front diff': ImageData(),
    'Diffs bottom view of diff front': ImageData(),
    'Diffs top view of rear diff': ImageData(),
    'Diffs bottom view of rear diff': ImageData(),
    'Engine Oil Leak': ImageData(),
    'Engine Water Leak': ImageData(),
    'Gearbox Oil Leak': ImageData(),
  };

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
        child: !_selectedImages[title]!.hasImage
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
                  // Display the image based on available source
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: _getImageWidget(_selectedImages[title]!),
                  ),
                  // 'X' button to remove the image
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImages[title] = ImageData();
                        });
                        widget.onProgressUpdate();
                        setState(() {});
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

  // Helper method to get the appropriate image widget
  Widget _getImageWidget(ImageData imageData) {
    if (imageData.webImage != null) {
      return Image.memory(
        imageData.webImage!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (imageData.file != null) {
      return Image.file(
        imageData.file!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (imageData.url != null && imageData.url!.isNotEmpty) {
      return Image.network(
        imageData.url!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return Container(); // Fallback empty container
  }

  // Updated image source dialog that uses the external camera helper:
  void _showImageSourceDialog(String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Image Source for $title'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Camera option using the external helper:
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final imageBytes = await capturePhoto(context);
                  if (imageBytes != null) {
                    setState(() {
                      _selectedImages[title] = ImageData(webImage: imageBytes);
                    });
                  }
                  widget.onProgressUpdate();
                },
              ),
              // Existing Gallery option:
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final pickedFile =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    final bytes = await pickedFile.readAsBytes();
                    setState(() {
                      _selectedImages[title] = ImageData(webImage: bytes);
                    });
                  }
                  widget.onProgressUpdate();
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
            _selectedImages[key] = ImageData(file: File(value['path']));
          } else if (value is Map && value['url'] != null) {
            // Store URL for later use
            _selectedImages[key] = ImageData(url: value['url']);
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

    // Validate and sanitize images data
    for (var entry in _selectedImages.entries) {
      if (entry.value.hasImage) {
        String? imageUrl;
        if (entry.value.webImage != null) {
          imageUrl = await _uploadWebImageToFirebase(
            entry.value.webImage!,
            entry.key.replaceAll(' ', '_').toLowerCase(),
          );
        } else if (entry.value.file != null) {
          imageUrl = await _uploadImageToFirebase(
            entry.value.file!,
            entry.key.replaceAll(' ', '_').toLowerCase(),
          );
        } else if (entry.value.url != null && entry.value.url!.isNotEmpty) {
          imageUrl = entry.value.url;
        }

        if (imageUrl != null && imageUrl.isNotEmpty) {
          serializedImages[entry.key] = {
            'url': imageUrl,
            'isNew': entry.value.url == null || entry.value.url!.isEmpty,
          };
        }
      }
    }

    // Create a sanitized data map
    Map<String, dynamic> data = {
      'condition': _selectedCondition,
      'engineOilLeak': _oilLeakConditionEngine,
      'engineWaterLeak': _waterLeakConditionEngine,
      'blowbyCondition': _blowbyCondition,
      'gearboxOilLeak': _oilLeakConditionGearbox,
      'retarderCondition': _retarderCondition,
    };

    // Only add images if there are any
    if (serializedImages.isNotEmpty) {
      data['images'] = serializedImages;
    }

    return data;
  }

  Future<String> _uploadWebImageToFirebase(
      Uint8List imageData, String section) async {
    try {
      String fileName =
          'drive_train/${widget.vehicleId}_${section}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putData(imageData);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading web image: $e');
      return '';
    }
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
        _selectedImages[key] = ImageData();
      });

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
          if (value.file != null) filledFields++;
        }
      } else {
        if (value.file != null) filledFields++;
      }
    });

    // Check conditions (5 fields)
    // Oil leak engine
    if (_oilLeakConditionEngine == 'no' ||
        (_oilLeakConditionEngine == 'yes' &&
            _selectedImages['Engine Oil Leak']?.file != null)) {
      filledFields++;
    }

    // Water leak engine
    if (_waterLeakConditionEngine == 'no' ||
        (_waterLeakConditionEngine == 'yes' &&
            _selectedImages['Engine Water Leak']?.file != null)) {
      filledFields++;
    }

    // Blowby condition
    if (_blowbyCondition.isNotEmpty) filledFields++;

    // Gearbox oil leak
    if (_oilLeakConditionGearbox == 'no' ||
        (_oilLeakConditionGearbox == 'yes' &&
            _selectedImages['Gearbox Oil Leak']?.file != null)) {
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
          _selectedImages['Engine Oil Leak'] = ImageData();
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
          _selectedImages['Engine Water Leak'] = ImageData();
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
          _selectedImages['Gearbox Oil Leak'] = ImageData();
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
      _selectedImages[title] = ImageData(file: imageFile);
    });
  }

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
        if (groupValue == 'yes') _buildPhotoBlock(imageKey),
      ],
    );
  }

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
}
