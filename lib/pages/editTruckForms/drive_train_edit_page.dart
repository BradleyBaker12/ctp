// lib/pages/truckForms/drive_train_page.dart

import 'dart:io';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart';
import 'package:provider/provider.dart';

class DriveTrainEditPage extends StatefulWidget {
  final String vehicleId;
  final VoidCallback onProgressUpdate;
  final bool isEditing;

  const DriveTrainEditPage({
    super.key,
    required this.vehicleId,
    required this.onProgressUpdate,
    this.isEditing = false,
  });

  @override
  DriveTrainEditPageState createState() => DriveTrainEditPageState();
}

class DriveTrainEditPageState extends State<DriveTrainEditPage>
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

  // Map to store image URLs (for previously uploaded images)
  final Map<String, String> _imageUrls = {};

  bool _isInitialized = false; // Flag to prevent re-initialization

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

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
                  enabled: !isDealer,
                ),
                CustomRadioButton(
                  label: 'Good',
                  value: 'good',
                  groupValue: _selectedCondition,
                  onChanged: _updateCondition,
                  enabled: !isDealer,
                ),
                CustomRadioButton(
                  label: 'Excellent',
                  value: 'excellent',
                  groupValue: _selectedCondition,
                  onChanged: _updateCondition,
                  enabled: !isDealer,
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
            // Grid of Photos
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
            // Engine Photos
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
            // Gearbox Photos
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

  // ===========================================================================
  // 1) MAIN PHOTO BLOCK WITH X BUTTON
  // ===========================================================================
  Widget _buildPhotoBlock(String title) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

    final hasLocalFile = _selectedImages[title] != null;
    final hasUrl = _imageUrls[title] != null && _imageUrls[title]!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        // If there's an image, allow viewing in full screen
        if (hasLocalFile || hasUrl) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                body: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Center(
                    child: hasLocalFile
                        ? Image.file(_selectedImages[title]!)
                        : Image.network(_imageUrls[title]!),
                  ),
                ),
              ),
            ),
          );
        } else if (!isDealer) {
          // For transporters - pick image
          _showImageSourceDialog(title);
        }
      },
      child: Container(
        width: double.infinity,
        height: 130,
        decoration: BoxDecoration(
          color: AppColors.blue.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: AppColors.blue, width: 2.0),
        ),
        child: Stack(
          children: [
            // Existing image or placeholder
            _getImageWidget(title, isDealer),

            // The "X" button (only if not a dealer AND an image is present)
            if (!isDealer && (hasLocalFile || hasUrl))
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      // Reset the image/file and URL
                      _selectedImages[title] = null;
                      _imageUrls[title] = '';
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Returns either a local file image, a network image, or a placeholder
  Widget _getImageWidget(String title, bool isDealer) {
    final file = _selectedImages[title];
    final url = _imageUrls[title];

    if (file != null) {
      // Local file image
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (url != null && url.isNotEmpty) {
      // Network image
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.error_outline, color: Colors.red);
          },
        ),
      );
    } else {
      // Placeholder
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isDealer)
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
      );
    }
  }

  // ===========================================================================
  // 2) IMAGE SOURCE DIALOG
  // ===========================================================================
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
                      _imageUrls[title] = ''; // Clear any existing URL
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
                      _imageUrls[title] = ''; // Clear any existing URL
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

  // ===========================================================================
  // 3) YES/NO SECTIONS (WITH/WITHOUT IMAGES)
  // ===========================================================================
  Widget _buildYesNoSection({
    required String title,
    required String groupValue,
    required ValueChanged<String?> onChanged,
    required String imageKey,
  }) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

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
              enabled: !isDealer,
            ),
            const SizedBox(width: 15),
            CustomRadioButton(
              label: 'No',
              value: 'no',
              groupValue: groupValue,
              onChanged: onChanged,
              enabled: !isDealer,
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        // If the user selects "Yes", allow uploading/viewing the "Leak" photo
        if (groupValue == 'yes') _buildPhotoBlock(imageKey),
      ],
    );
  }

  // Same yes/no, but no images
  Widget _buildYesNoRadioOnlySection({
    required String title,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

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
              enabled: !isDealer,
            ),
            const SizedBox(width: 15),
            CustomRadioButton(
              label: 'No',
              value: 'no',
              groupValue: groupValue,
              onChanged: onChanged,
              enabled: !isDealer,
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // 4) FIREBASE UPLOAD / DATA METHODS
  // ===========================================================================
  Future<Map<String, dynamic>> getData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isTransporter = userProvider.getUserRole == 'transporter';

    if (!isTransporter) {
      return {};
    }

    Map<String, dynamic> serializedImages = {};
    for (var entry in _selectedImages.entries) {
      if (entry.value != null) {
        // We have a local file to upload
        String imageUrl = await _uploadImageToFirebase(
          entry.value!,
          entry.key.replaceAll(' ', '_').toLowerCase(),
        );
        serializedImages[entry.key] = {
          'url': imageUrl,
          'path': entry.value!.path,
          'isNew': true,
        };
      } else if (_imageUrls[entry.key] != null &&
          _imageUrls[entry.key]!.isNotEmpty) {
        // We have an existing URL
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

  Future<String> _uploadImageToFirebase(File imageFile, String section) async {
    try {
      String fileName =
          'drive_train/${widget.vehicleId}_${section}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return '';
    }
  }

  Future<bool> saveData() async {
    // Implement save logic if needed
    return true;
  }

  void initializeWithData(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    setState(() {
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
          if (value is Map) {
            // Local file path
            if (value['path'] != null) {
              _selectedImages[key] = File(value['path']);
            }
            // Existing URL
            if (value['url'] != null && value['url'].toString().isNotEmpty) {
              _imageUrls[key] = value['url'];
            }
          }
        });
      }
    });
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

    // 1) Condition
    if (_selectedCondition.isNotEmpty) filledFields++;

    // 2) Images (16 total possible)
    _selectedImages.forEach((key, value) {
      // Count only if required or generally if there's an image
      // For "Leak" images, only count if the condition is "yes"
      if (key == 'Engine Oil Leak' && _oilLeakConditionEngine == 'yes') {
        if (value != null ||
            (_imageUrls[key] != null && _imageUrls[key]!.isNotEmpty)) {
          filledFields++;
        }
      } else if (key == 'Engine Water Leak' &&
          _waterLeakConditionEngine == 'yes') {
        if (value != null ||
            (_imageUrls[key] != null && _imageUrls[key]!.isNotEmpty)) {
          filledFields++;
        }
      } else if (key == 'Gearbox Oil Leak' &&
          _oilLeakConditionGearbox == 'yes') {
        if (value != null ||
            (_imageUrls[key] != null && _imageUrls[key]!.isNotEmpty)) {
          filledFields++;
        }
      } else if (!key.contains('Leak')) {
        // Non-leak images always count if present
        if (value != null ||
            (_imageUrls[key] != null && _imageUrls[key]!.isNotEmpty)) {
          filledFields++;
        }
      }
    });

    // 3) Conditions for leak/no-leak, retarder, blowby
    //    (4 fields: engine oil leak, engine water leak, gearbox oil leak, retarder, plus blowby = 5)
    // a) Engine oil
    if (_oilLeakConditionEngine == 'no' ||
        (_oilLeakConditionEngine == 'yes' &&
            (_selectedImages['Engine Oil Leak'] != null ||
                (_imageUrls['Engine Oil Leak'] != null &&
                    _imageUrls['Engine Oil Leak']!.isNotEmpty)))) {
      filledFields++;
    }

    // b) Engine water
    if (_waterLeakConditionEngine == 'no' ||
        (_waterLeakConditionEngine == 'yes' &&
            (_selectedImages['Engine Water Leak'] != null ||
                (_imageUrls['Engine Water Leak'] != null &&
                    _imageUrls['Engine Water Leak']!.isNotEmpty)))) {
      filledFields++;
    }

    // c) Blowby
    if (_blowbyCondition.isNotEmpty) filledFields++;

    // d) Gearbox oil
    if (_oilLeakConditionGearbox == 'no' ||
        (_oilLeakConditionGearbox == 'yes' &&
            (_selectedImages['Gearbox Oil Leak'] != null ||
                (_imageUrls['Gearbox Oil Leak'] != null &&
                    _imageUrls['Gearbox Oil Leak']!.isNotEmpty)))) {
      filledFields++;
    }

    // e) Retarder
    if (_retarderCondition.isNotEmpty) filledFields++;

    // Return final ratio
    return (filledFields / totalFields).clamp(0.0, 1.0);
  }

  // Utility method to update state and notify progress
  void _updateAndNotify(VoidCallback updateFunction) {
    setState(() {
      updateFunction();
    });
    widget.onProgressUpdate();
  }

  // Condition selection
  void _updateCondition(String? value) {
    if (value != null) {
      _updateAndNotify(() {
        _selectedCondition = value;
      });
    }
  }

  // Engine oil leak
  void _updateOilLeakCondition(String? value) {
    if (value != null) {
      _updateAndNotify(() {
        _oilLeakConditionEngine = value;
        if (value == 'no') {
          _selectedImages['Engine Oil Leak'] = null;
          _imageUrls['Engine Oil Leak'] = '';
        }
      });
    }
  }

  // Engine water leak
  void _updateWaterLeakCondition(String? value) {
    if (value != null) {
      _updateAndNotify(() {
        _waterLeakConditionEngine = value;
        if (value == 'no') {
          _selectedImages['Engine Water Leak'] = null;
          _imageUrls['Engine Water Leak'] = '';
        }
      });
    }
  }

  // Blowby condition
  void _updateBlowbyCondition(String? value) {
    if (value != null) {
      _updateAndNotify(() {
        _blowbyCondition = value;
      });
    }
  }

  // Gearbox oil leak
  void _updateGearboxOilLeakCondition(String? value) {
    if (value != null) {
      _updateAndNotify(() {
        _oilLeakConditionGearbox = value;
        if (value == 'no') {
          _selectedImages['Gearbox Oil Leak'] = null;
          _imageUrls['Gearbox Oil Leak'] = '';
        }
      });
    }
  }

  // Retarder condition
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
      _imageUrls[title] = ''; // Clear any existing URL
    });
  }
}
