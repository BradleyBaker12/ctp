import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart';

class DriveTrainPage extends StatefulWidget {
  final String vehicleId;
  const DriveTrainPage({Key? key, required this.vehicleId}) : super(key: key);

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
  Map<String, File?> _selectedImages = {
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
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCondition = value;
                          });
                        }
                      },
                    ),
                    CustomRadioButton(
                      label: 'Good',
                      value: 'good',
                      groupValue: _selectedCondition,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCondition = value;
                          });
                        }
                      },
                    ),
                    CustomRadioButton(
                      label: 'Excellent',
                      value: 'excellent',
                      groupValue: _selectedCondition,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCondition = value;
                          });
                        }
                      },
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
                      .where((key) => key.contains('Engine'))
                      .map((key) => _buildPhotoBlock(key))
                      .toList(),
                ),
                const SizedBox(height: 16.0),
                // Engine Oil Leak Section
                _buildYesNoSection(
                  title: 'Are there any oil leaks in the engine?',
                  groupValue: _oilLeakConditionEngine,
                  onChanged: (value) {
                    setState(() {
                      _oilLeakConditionEngine = value!;
                    });
                  },
                  imageKey: 'Engine Oil Leak',
                ),
                const SizedBox(height: 16.0),
                // Engine Water Leak Section
                _buildYesNoSection(
                  title: 'Are there any water leaks in the engine?',
                  groupValue: _waterLeakConditionEngine,
                  onChanged: (value) {
                    setState(() {
                      _waterLeakConditionEngine = value!;
                    });
                  },
                  imageKey: 'Engine Water Leak',
                ),
                const SizedBox(height: 16.0),
                // Blowby Condition Section (No Image)
                _buildYesNoRadioOnlySection(
                  title: 'Is there blowby/engine breathing?',
                  groupValue: _blowbyCondition,
                  onChanged: (value) {
                    setState(() {
                      _blowbyCondition = value!;
                    });
                  },
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
                      .where((key) => key.contains('Gearbox'))
                      .map((key) => _buildPhotoBlock(key))
                      .toList(),
                ),
                const SizedBox(height: 16.0),
                // Gearbox Oil Leak Section
                _buildYesNoSection(
                  title: 'Are there any oil leaks in the gearbox?',
                  groupValue: _oilLeakConditionGearbox,
                  onChanged: (value) {
                    setState(() {
                      _oilLeakConditionGearbox = value!;
                    });
                  },
                  imageKey: 'Gearbox Oil Leak',
                ),
                const SizedBox(height: 16.0),
                // Retarder Condition Section (No Image)
                _buildYesNoRadioOnlySection(
                  title: 'Does the gearbox come with a retarder?',
                  groupValue: _retarderCondition,
                  onChanged: (value) {
                    setState(() {
                      _retarderCondition = value!;
                    });
                  },
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
            )));
  }

  // Helper method to create a photo block
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
        child: _selectedImages[title] == null && !_hasImageUrl(title)
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
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : _getImageWidget(title),
      ),
    );
  }

  // Check if there's an image URL for the given title
  bool _hasImageUrl(String title) {
    // Implement logic to check if imageUrl exists in Firestore or state
    // For simplicity, assuming no imageUrl is stored locally
    return false;
  }

  // Get the appropriate image widget
  Widget _getImageWidget(String title) {
    // Implement logic to retrieve imageUrl from Firestore if exists
    // For simplicity, displaying the local file image
    if (_selectedImages[title] != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.file(
          _selectedImages[title]!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else {
      // Placeholder if no image is selected but imageUrl exists
      return _buildImagePlaceholder();
    }
  }

  // Placeholder widget for images
  Widget _buildImagePlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.broken_image, color: Colors.white, size: 40.0),
        SizedBox(height: 8.0),
        Text(
          'Image Not Available',
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
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

  // Helper method to upload a single image to Firebase Storage and get its URL
  Future<String> _uploadImage(File file, String key) async {
    try {
      String fileName =
          'drive_train/${widget.vehicleId}_$key${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = _storage.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(file);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      return '';
    }
  }

  // Method to save data to Firestore
  Future<bool> saveData() async {
    try {
      final driveTrainRef = _firestore
          .collection('vehicles')
          .doc(widget.vehicleId)
          .collection('truckConditions')
          .doc('DriveTrain');

      // Preparing data to save
      Map<String, dynamic> dataToSave = {
        'condition': _selectedCondition,
        'oilLeakConditionEngine': _oilLeakConditionEngine,
        'waterLeakConditionEngine': _waterLeakConditionEngine,
        'blowbyCondition': _blowbyCondition,
        'oilLeakConditionGearbox': _oilLeakConditionGearbox,
        'retarderCondition': _retarderCondition,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Uploading and saving images
      for (var entry in _selectedImages.entries) {
        if (entry.value != null) {
          String imageUrl = await _uploadImage(entry.value!, entry.key);
          if (imageUrl.isNotEmpty) {
            dataToSave[entry.key] = imageUrl;
          }
        }
      }

      // Saving data to Firestore
      await driveTrainRef.set(dataToSave, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Drive Train data saved successfully!')),
        );
      }

      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save Drive Train data: $e')),
        );
      }
      return false;
    }
  }
}
