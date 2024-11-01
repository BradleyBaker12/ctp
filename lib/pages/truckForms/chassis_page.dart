// lib/pages/truckForms/chassis_page.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChassisPage extends StatefulWidget {
  final String vehicleId;
  const ChassisPage({Key? key, required this.vehicleId}) : super(key: key);

  @override
  ChassisPageState createState() => ChassisPageState();
}

class ChassisPageState extends State<ChassisPage>
    with AutomaticKeepAliveClientMixin {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage =
      FirebaseStorage.instance; // Firebase Storage instance

  String _selectedCondition = 'good';
  String _additionalFeaturesCondition = 'no';
  String _damagesCondition = 'no';

  // Maps to store selected images and their URLs
  Map<String, String?> _imageUrls = {
    'Right Brake': null,
    'Left Brake': null,
    'Front Axel': null,
    'Suspension': null,
    'Fuel Tank': null,
    'Battery': null,
    'Cat Walk': null,
    'Electrical Cable Black': null,
    'Air Cable Yellow': null,
    'Air Cable Red': null,
    'Tail Board': null,
    '5th Wheel': null,
    'Left Brake Rear Axel': null,
    'Right Brake Rear Axel': null,
  };

  Map<String, File?> _selectedImages = {
    'Right Brake': null,
    'Left Brake': null,
    'Front Axel': null,
    'Suspension': null,
    'Fuel Tank': null,
    'Battery': null,
    'Cat Walk': null,
    'Electrical Cable Black': null,
    'Air Cable Yellow': null,
    'Air Cable Red': null,
    'Tail Board': null,
    '5th Wheel': null,
    'Left Brake Rear Axel': null,
    'Right Brake Rear Axel': null,
  };

  // Lists to store damages and additional features
  List<Map<String, dynamic>> _damageList = [];
  List<Map<String, dynamic>> _additionalFeaturesList = [];

  @override
  bool get wantKeepAlive => true; // Properly implementing the getter

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  // Method to load existing data from Firestore (if any)
  Future<void> _loadExistingData() async {
    try {
      final chassisRef = _firestore
          .collection('vehicles')
          .doc(widget.vehicleId)
          .collection('truckConditions')
          .doc('Chassis');

      final snapshot = await chassisRef.get();
      if (snapshot.exists) {
        final data = snapshot.data()!;
        setState(() {
          _selectedCondition = data['condition'] ?? 'good';
          _additionalFeaturesCondition =
              data['additionalFeaturesCondition'] ?? 'no';
          _damagesCondition = data['damagesCondition'] ?? 'no';

          // Load image URLs
          _imageUrls.updateAll((key, value) => data[key] ?? null);
        });

        // Load damages
        final damagesSnapshot = await chassisRef.collection('damages').get();
        setState(() {
          _damageList = damagesSnapshot.docs
              .map((doc) => {
                    'description': doc['description'] ?? '',
                    'imageUrl': doc['imageUrl'] ?? '',
                  })
              .toList();
        });

        // Load additional features
        final featuresSnapshot =
            await chassisRef.collection('additionalFeatures').get();
        setState(() {
          _additionalFeaturesList = featuresSnapshot.docs
              .map((doc) => {
                    'description': doc['description'] ?? '',
                    'imageUrl': doc['imageUrl'] ?? '',
                  })
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading existing data: $e')),
        );
      }
    }
  }

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
            'Chassis Inspection'.toUpperCase(),
            style: const TextStyle(
              fontSize: 25,
              color: Color.fromARGB(221, 255, 255, 255),
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Condition of the Chassis',
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
          // Front Axel Section
          Text(
            'Front Axel'.toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              color: Color.fromARGB(221, 255, 255, 255),
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16.0),
          _buildImageGrid(
              ['Right Brake', 'Left Brake', 'Front Axel', 'Suspension']),
          const SizedBox(height: 16.0),
          const Divider(thickness: 1.0),
          const SizedBox(height: 16.0),
          // Center of Chassis Section
          Text(
            'Center of Chassis'.toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              color: Color.fromARGB(221, 255, 255, 255),
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16.0),
          _buildImageGrid([
            'Fuel Tank',
            'Battery',
            'Cat Walk',
            'Electrical Cable Black',
            'Air Cable Yellow',
            'Air Cable Red'
          ]),
          const SizedBox(height: 16.0),
          const Divider(thickness: 1.0),
          const SizedBox(height: 16.0),
          // Rear Axel Section
          Text(
            'Rear Axel'.toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              color: Color.fromARGB(221, 255, 255, 255),
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16.0),
          _buildImageGrid([
            'Tail Board',
            '5th Wheel',
            'Left Brake Rear Axel',
            'Right Brake Rear Axel'
          ]),
          const SizedBox(height: 16.0),
          const Divider(thickness: 1.0),
          const SizedBox(height: 16.0),
          // Damages Section
          _buildAdditionalSection(
            title: 'Are there any damages?',
            anyItemsType: _damagesCondition,
            onChange: (value) {
              setState(() {
                _damagesCondition = value!;
                if (_damagesCondition == 'yes' && _damageList.isEmpty) {
                  _damageList.add({'description': '', 'imageUrl': null});
                } else if (_damagesCondition == 'no') {
                  _damageList.clear();
                }
              });
            },
            buildItemSection: _buildDamageSection,
          ),
          const SizedBox(height: 16.0),
          const Divider(thickness: 1.0),
          const SizedBox(height: 16.0),
          // Additional Features Section
          _buildAdditionalSection(
            title: 'Are there any additional features?',
            anyItemsType: _additionalFeaturesCondition,
            onChange: (value) {
              setState(() {
                _additionalFeaturesCondition = value!;
                if (_additionalFeaturesCondition == 'yes' &&
                    _additionalFeaturesList.isEmpty) {
                  _additionalFeaturesList
                      .add({'description': '', 'imageUrl': null});
                } else if (_additionalFeaturesCondition == 'no') {
                  _additionalFeaturesList.clear();
                }
              });
            },
            buildItemSection: _buildAdditionalFeaturesSection,
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    ));
  }

  // Helper method to create an image grid
  Widget _buildImageGrid(List<String> titles) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      children: titles.map((title) => _buildPhotoBlock(title)).toList(),
    );
  }

  // Helper method to create a photo block
  Widget _buildPhotoBlock(String title) {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(title),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.blue.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: AppColors.blue, width: 2.0),
        ),
        child: _imageUrls[title] == null && _selectedImages[title] == null
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

  // Get the appropriate image widget
  Widget _getImageWidget(String title) {
    if (_imageUrls[title] != null && _imageUrls[title]!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          _imageUrls[title]!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder();
          },
        ),
      );
    } else if (_selectedImages[title] != null) {
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
                      _imageUrls[title] = null; // Reset imageUrl
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
                      _imageUrls[title] = null; // Reset imageUrl
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

  // Helper method to build additional sections (Damages, Additional Features)
  Widget _buildAdditionalSection({
    required String title,
    required String anyItemsType,
    required ValueChanged<String?> onChange,
    required Widget Function() buildItemSection,
  }) {
    return Column(
      children: [
        Text(
          title.toUpperCase(),
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
              groupValue: anyItemsType,
              onChanged: onChange,
            ),
            const SizedBox(width: 15),
            CustomRadioButton(
              label: 'No',
              value: 'no',
              groupValue: anyItemsType,
              onChanged: onChange,
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        if (anyItemsType == 'yes') buildItemSection(),
      ],
    );
  }

  // Helper method to build the damage section
  Widget _buildDamageSection() {
    return _buildItemSection(
      items: _damageList,
      addItem: () {
        setState(() {
          _damageList.add({'description': '', 'imageUrl': null});
        });
      },
      showImageSourceDialog: _showDamageImageSourceDialog,
    );
  }

  // Helper method to build the additional features section
  Widget _buildAdditionalFeaturesSection() {
    return _buildItemSection(
      items: _additionalFeaturesList,
      addItem: () {
        setState(() {
          _additionalFeaturesList.add({'description': '', 'imageUrl': null});
        });
      },
      showImageSourceDialog: _showAdditionalFeatureImageSourceDialog,
    );
  }

  // Helper method to build the item section (Damages, Additional Features)
  Widget _buildItemSection({
    required List<Map<String, dynamic>> items,
    required VoidCallback addItem,
    required void Function(Map<String, dynamic>) showImageSourceDialog,
  }) {
    return Column(
      children: [
        ...items
            .asMap()
            .entries
            .map((entry) => _buildItemWidget(
                entry.key, entry.value, showImageSourceDialog, items))
            .toList(),
        const SizedBox(height: 16.0),
        GestureDetector(
          onTap: addItem,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.blue, size: 30.0),
              SizedBox(width: 8.0),
              Text(
                'Add Additional Item',
                style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to create an item widget (Damages, Additional Features)
  Widget _buildItemWidget(
      int index,
      Map<String, dynamic> item,
      void Function(Map<String, dynamic>) showImageSourceDialog,
      List<Map<String, dynamic>> list) {
    return Column(
      children: [
        const SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    item['description'] = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Describe Item',
                  labelStyle: const TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  list.removeAt(index);
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        GestureDetector(
          onTap: () => showImageSourceDialog(item),
          child: Container(
            height: 150.0,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: AppColors.blue, width: 2.0),
            ),
            child: item['imageUrl'] != null && item['imageUrl']!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      item['imageUrl'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder();
                      },
                    ),
                  )
                : item['image'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.file(
                          item['image'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                    : _buildImagePlaceholder(),
          ),
        ),
      ],
    );
  }

  // Method to show dialog for selecting image source for damages
  void _showDamageImageSourceDialog(Map<String, dynamic> damage) {
    _showImageSourceDialogForItem(damage);
  }

  // Method to show dialog for selecting image source for additional features
  void _showAdditionalFeatureImageSourceDialog(Map<String, dynamic> feature) {
    _showImageSourceDialogForItem(feature);
  }

  // Generic method to show dialog for selecting image source for a given item
  void _showImageSourceDialogForItem(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
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
                      item['image'] = File(pickedFile.path);
                      item['imageUrl'] = null; // Reset imageUrl
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
                      item['image'] = File(pickedFile.path);
                      item['imageUrl'] = null; // Reset imageUrl
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
          title.toUpperCase(),
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
          title.toUpperCase(),
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
  Future<String?> _uploadImage(File file, String key) async {
    try {
      String fileName =
          'chassis/${widget.vehicleId}_$key${DateTime.now().millisecondsSinceEpoch}.jpg';
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
      return null;
    }
  }

  // Method to save data to Firestore
  Future<bool> saveData() async {
    try {
      final chassisRef = _firestore
          .collection('vehicles')
          .doc(widget.vehicleId)
          .collection('truckConditions')
          .doc('Chassis');

      // Preparing data to save
      Map<String, dynamic> dataToSave = {
        'condition': _selectedCondition,
        'damagesCondition': _damagesCondition,
        'additionalFeaturesCondition': _additionalFeaturesCondition,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Uploading and saving images
      for (var entry in _selectedImages.entries) {
        if (_selectedImages[entry.key] != null) {
          String? imageUrl =
              await _uploadImage(_selectedImages[entry.key]!, entry.key);
          if (imageUrl != null && imageUrl.isNotEmpty) {
            dataToSave[entry.key] = imageUrl;
            _imageUrls[entry.key] = imageUrl;
          }
        }
      }

      // Saving main chassis data
      await chassisRef.set(dataToSave, SetOptions(merge: true));

      // Saving damages
      if (_damagesCondition == 'yes') {
        for (var damage in _damageList) {
          String? imageUrl;
          if (damage['image'] != null) {
            imageUrl = await _uploadImage(damage['image']!,
                'damage_${DateTime.now().millisecondsSinceEpoch}');
          }
          await chassisRef.collection('damages').add({
            'description': damage['description'] ?? '',
            'imageUrl': imageUrl ?? '',
          });
        }
      }

      // Saving additional features
      if (_additionalFeaturesCondition == 'yes') {
        for (var feature in _additionalFeaturesList) {
          String? imageUrl;
          if (feature['image'] != null) {
            imageUrl = await _uploadImage(feature['image']!,
                'feature_${DateTime.now().millisecondsSinceEpoch}');
          }
          await chassisRef.collection('additionalFeatures').add({
            'description': feature['description'] ?? '',
            'imageUrl': imageUrl ?? '',
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chassis data saved successfully!')),
        );
      }

      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save chassis data: $e')),
        );
      }
      return false;
    }
  }
}
