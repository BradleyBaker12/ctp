// lib/pages/truckForms/internal_cab_page.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Added for Firebase Storage
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart';

class InternalCabEditPage extends StatefulWidget {
  final String vehicleId;
  final VoidCallback onProgressUpdate;
  final bool isEditing;

  const InternalCabEditPage({
    super.key,
    required this.vehicleId,
    required this.onProgressUpdate,
    this.isEditing = false,
  });

  @override
  InternalCabEditPageState createState() => InternalCabEditPageState();
}

class InternalCabEditPageState extends State<InternalCabEditPage>
    with AutomaticKeepAliveClientMixin {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage =
      FirebaseStorage.instance; // Firebase Storage instance

  String _selectedCondition = 'good'; // Default selected value
  String _damagesCondition = 'no';
  String _additionalFeaturesCondition = 'no';
  String _faultCodesCondition = 'no';

  // Map to store selected images for different sections
  final Map<String, File?> _selectedImages = {
    'Center Dash': null,
    'Left Dash': null,
    'Right Dash (Vehicle On)': null,
    'Mileage': null,
    'Sun Visors': null,
    'Center Console': null,
    'Steering': null,
    'Left Door Panel': null,
    'Left Seat': null,
    'Roof': null,
    'Bunk Beds': null,
    'Rear Panel': null,
    'Right Door Panel': null,
    'Right Seat': null,
  };

  // Lists to store damages, additional features, and fault codes
  List<Map<String, dynamic>> _damageList = [];
  List<Map<String, dynamic>> _additionalFeaturesList = [];
  List<Map<String, dynamic>> _faultCodesList = [];

  bool _isInitialized = false; // Flag to prevent re-initialization

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16.0),
            Text(
              'Details for INTERNAL CAB'.toUpperCase(),
              style: const TextStyle(
                fontSize: 25,
                color: Color.fromARGB(221, 255, 255, 255),
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Condition of the Inside CAB',
              style: TextStyle(
                fontSize: 16,
                color: Color.fromARGB(221, 255, 255, 255),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomRadioButton(
                  label: 'Poor',
                  value: 'poor',
                  groupValue: _selectedCondition,
                  onChanged: (value) {
                    if (value != null) {
                      _updateAndNotify(() {
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
                      _updateAndNotify(() {
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
                      _updateAndNotify(() {
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
            // Front Side of Cab
            Text(
              'Front Side of Cab'.toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                color: Color.fromARGB(221, 255, 255, 255),
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              children: [
                ..._selectedImages.keys
                    .where((key) =>
                        key.contains('Dash') ||
                        key.contains('Mileage') ||
                        key.contains('Visors') ||
                        key.contains('Console'))
                    .map((key) => _buildPhotoBlock(key)),
                _buildPhotoBlock('Steering'),
              ],
            ),
            const SizedBox(height: 16.0),
            const Divider(thickness: 1.0),
            const SizedBox(height: 16.0),
            // Left Side of Cab
            Text(
              'Left Side of Cab'.toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                color: Color.fromARGB(221, 255, 255, 255),
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              children: _selectedImages.keys
                  .where((key) => key.startsWith('Left'))
                  .map((key) => _buildPhotoBlock(key))
                  .toList(),
            ),
            const SizedBox(height: 16.0),
            const Divider(thickness: 1.0),
            const SizedBox(height: 16.0),
            // Rear Side of Cab
            Text(
              'Rear Side of Cab'.toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                color: Color.fromARGB(221, 255, 255, 255),
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              children: [
                ..._selectedImages.keys
                    .where((key) => key == 'Roof' || key == 'Bunk Beds')
                    .map((key) => _buildPhotoBlock(key)),
                _buildPhotoBlock('Rear Panel'),
              ],
            ),
            const SizedBox(height: 16.0),
            const Divider(thickness: 1.0),
            const SizedBox(height: 16.0),
            // Right Side of Cab
            Text(
              'Right Side of Cab'.toUpperCase(),
              style: const TextStyle(
                fontSize: 20,
                color: Color.fromARGB(221, 255, 255, 255),
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              children: _selectedImages.keys
                  .where((key) => key.startsWith('Right'))
                  .map((key) => _buildPhotoBlock(key))
                  .toList(),
            ),
            const SizedBox(height: 16.0),
            const Divider(thickness: 1.0),
            const SizedBox(height: 16.0),
            // Damages Section
            _buildAdditionalSection(
              title: 'Are there any damages?',
              anyItemsType: _damagesCondition,
              onChange: (value) {
                _updateAndNotify(() {
                  _damagesCondition = value!;
                  if (_damagesCondition == 'yes' && _damageList.isEmpty) {
                    _damageList.add({'description': '', 'image': null});
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
                _updateAndNotify(() {
                  _additionalFeaturesCondition = value!;
                  if (_additionalFeaturesCondition == 'yes' &&
                      _additionalFeaturesList.isEmpty) {
                    _additionalFeaturesList
                        .add({'description': '', 'image': null});
                  } else if (_additionalFeaturesCondition == 'no') {
                    _additionalFeaturesList.clear();
                  }
                });
              },
              buildItemSection: _buildAdditionalFeaturesSection,
            ),
            const SizedBox(height: 16.0),
            const Divider(thickness: 1.0),
            const SizedBox(height: 16.0),
            // Fault Codes Section
            _buildAdditionalSection(
              title: 'Are there any fault codes?',
              anyItemsType: _faultCodesCondition,
              onChange: (value) {
                _updateAndNotify(() {
                  _faultCodesCondition = value!;
                  if (_faultCodesCondition == 'yes' &&
                      _faultCodesList.isEmpty) {
                    _faultCodesList.add({'description': '', 'image': null});
                  } else if (_faultCodesCondition == 'no') {
                    _faultCodesList.clear();
                  }
                });
              },
              buildItemSection: _buildFaultCodesSection,
            ),
          ],
        ),
      ),
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
                        fontWeight: FontWeight.w600),
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

  // Method to show the dialog for selecting image source (Camera or Gallery)
  void _showImageSourceDialog(String title) {
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

  // Helper method to build the additional section (Damages, Additional Features, Fault Codes)
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
          _damageList.add({'description': '', 'image': null, 'imageUrl': ''});
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
          _additionalFeaturesList
              .add({'description': '', 'image': null, 'imageUrl': ''});
        });
      },
      showImageSourceDialog: _showAdditionalFeatureImageSourceDialog,
    );
  }

  // Helper method to build the fault codes section
  Widget _buildFaultCodesSection() {
    return _buildItemSection(
      items: _faultCodesList,
      addItem: () {
        setState(() {
          _faultCodesList
              .add({'description': '', 'image': null, 'imageUrl': ''});
        });
      },
      showImageSourceDialog: _showFaultCodesImageSourceDialog,
    );
  }

  // Helper method to build the item section (Damages, Additional Features, Fault Codes)
  Widget _buildItemSection({
    required List<Map<String, dynamic>> items,
    required VoidCallback addItem,
    required void Function(Map<String, dynamic>) showImageSourceDialog,
  }) {
    return Column(
      children: [
        ...items.asMap().entries.map((entry) =>
            _buildItemWidget(entry.key, entry.value, showImageSourceDialog)),
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

  // Helper method to create an item widget (Damages, Additional Features, Fault Codes)
  Widget _buildItemWidget(int index, Map<String, dynamic> item,
      void Function(Map<String, dynamic>) showImageSourceDialog) {
    return Column(
      children: [
        const SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (value) {
                  _updateAndNotify(() {
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
                  _removeItem(index, item);
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
            child: item['image'] == null
                ? _buildImagePlaceholder()
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(
                      item['image'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // Placeholder widget for images
  Widget _buildImagePlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_circle_outline, color: Colors.white, size: 40.0),
        SizedBox(height: 8.0),
        Text(
          'Clear Picture of Item',
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // Method to remove an item from the appropriate list
  void _removeItem(int index, Map<String, dynamic> item) {
    if (_damageList.contains(item)) {
      _damageList.removeAt(index);
    }
    if (_additionalFeaturesList.contains(item)) {
      _additionalFeaturesList.removeAt(index);
    }
    if (_faultCodesList.contains(item)) {
      _faultCodesList.removeAt(index);
    }
  }

  // Method to show dialog for selecting image source for damages
  void _showDamageImageSourceDialog(Map<String, dynamic> damage) {
    _showImageSourceDialogForItem(damage);
  }

  // Method to show dialog for selecting image source for additional features
  void _showAdditionalFeatureImageSourceDialog(Map<String, dynamic> feature) {
    _showImageSourceDialogForItem(feature);
  }

  // Method to show dialog for selecting image source for fault codes
  void _showFaultCodesImageSourceDialog(Map<String, dynamic> faultCode) {
    _showImageSourceDialogForItem(faultCode);
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

  // Method to upload images (if required)

  Future<bool> saveData() async {
    // You can implement save logic here if needed
    return true;
  }

  void initializeWithData(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    setState(() {
      // _isInitialized = true;
      // Initialize basic fields
      _selectedCondition = data['condition'] ?? 'good';
      _damagesCondition = data['damagesCondition'] ?? 'no';
      _additionalFeaturesCondition =
          data['additionalFeaturesCondition'] ?? 'no';
      _faultCodesCondition = data['faultCodesCondition'] ?? 'no';

      // Initialize view images
      if (data['viewImages'] != null) {
        Map<String, dynamic> viewImages =
            Map<String, dynamic>.from(data['viewImages']);
        viewImages.forEach((key, value) {
          if (value is Map && value['path'] != null) {
            _selectedImages[key] = File(value['path']);
          }
        });
      }

      // Initialize damages list
      if (data['damages'] != null) {
        _damageList = (data['damages'] as List).map((damage) {
          return {
            'description': damage['description'] ?? '',
            'image':
                damage['imagePath'] != null ? File(damage['imagePath']) : null,
            'imageUrl': damage['imageUrl'] ?? '',
          };
        }).toList();
      }

      // Initialize additional features list
      if (data['additionalFeatures'] != null) {
        _additionalFeaturesList =
            (data['additionalFeatures'] as List).map((feature) {
          return {
            'description': feature['description'] ?? '',
            'image': feature['imagePath'] != null
                ? File(feature['imagePath'])
                : null,
            'imageUrl': feature['imageUrl'] ?? '',
          };
        }).toList();
      }

      // Initialize fault codes list
      if (data['faultCodes'] != null) {
        _faultCodesList = (data['faultCodes'] as List).map((faultCode) {
          return {
            'description': faultCode['description'] ?? '',
            'image': faultCode['imagePath'] != null
                ? File(faultCode['imagePath'])
                : null,
            'imageUrl': faultCode['imageUrl'] ?? '',
          };
        }).toList();
      }
    });
  }

  Future<Map<String, dynamic>> getData() async {
    // Convert File objects to paths for serialization
    Map<String, dynamic> serializedImages = {};
    _selectedImages.forEach((key, value) {
      if (value != null) {
        serializedImages[key] = {'path': value.path, 'isNew': true};
      }
    });

    // Convert damage list to serializable format
    List<Map<String, dynamic>> serializedDamages = _damageList.map((damage) {
      return {
        'description': damage['description'] ?? '',
        'imagePath': damage['image']?.path,
        'imageUrl': damage['imageUrl'] ?? '',
        'isNew': damage['image'] != null
      };
    }).toList();

    // Convert additional features list to serializable format
    List<Map<String, dynamic>> serializedFeatures =
        _additionalFeaturesList.map((feature) {
      return {
        'description': feature['description'] ?? '',
        'imagePath': feature['image']?.path,
        'imageUrl': feature['imageUrl'] ?? '',
        'isNew': feature['image'] != null
      };
    }).toList();

    // Convert fault codes list to serializable format
    List<Map<String, dynamic>> serializedFaultCodes =
        _faultCodesList.map((faultCode) {
      return {
        'description': faultCode['description'] ?? '',
        'imagePath': faultCode['image']?.path,
        'imageUrl': faultCode['imageUrl'] ?? '',
        'isNew': faultCode['image'] != null
      };
    }).toList();

    return {
      'condition': _selectedCondition,
      'damagesCondition': _damagesCondition,
      'additionalFeaturesCondition': _additionalFeaturesCondition,
      'faultCodesCondition': _faultCodesCondition,
      'viewImages': serializedImages,
      'damages': serializedDamages,
      'additionalFeatures': serializedFeatures,
      'faultCodes': serializedFaultCodes,
    };
  }

  void reset() {
    setState(() {
      _selectedCondition = 'good';
      _damagesCondition = 'no';
      _additionalFeaturesCondition = 'no';
      _faultCodesCondition = 'no';

      _selectedImages.forEach((key, _) {
        _selectedImages[key] = null;
      });

      _damageList.clear();
      _additionalFeaturesList.clear();
      _faultCodesList.clear();

      _isInitialized = false; // Allow re-initialization if needed
    });
  }

  double getCompletionPercentage() {
    int totalFields = 18; // Total number of fields to fill
    int filledFields = 0;

    // Check condition selection (1 field)
    if (_selectedCondition.isNotEmpty) filledFields++;

    // Check all images (14 fields)
    _selectedImages.forEach((key, value) {
      if (value != null) filledFields++;
    });

    // Check damages section (1 field)
    if (_damagesCondition == 'no') {
      filledFields++;
    } else if (_damagesCondition == 'yes' && _damageList.isNotEmpty) {
      bool isDamagesComplete = _damageList.every((damage) =>
          damage['description']?.isNotEmpty == true && damage['image'] != null);
      if (isDamagesComplete) filledFields++;
    }

    // Check additional features section (1 field)
    if (_additionalFeaturesCondition == 'no') {
      filledFields++;
    } else if (_additionalFeaturesCondition == 'yes' &&
        _additionalFeaturesList.isNotEmpty) {
      bool isFeaturesComplete = _additionalFeaturesList.every((feature) =>
          feature['description']?.isNotEmpty == true &&
          feature['image'] != null);
      if (isFeaturesComplete) filledFields++;
    }

    // Check fault codes section (1 field)
    if (_faultCodesCondition == 'no') {
      filledFields++;
    } else if (_faultCodesCondition == 'yes' && _faultCodesList.isNotEmpty) {
      bool isFaultCodesComplete = _faultCodesList.every((faultCode) =>
          faultCode['description']?.isNotEmpty == true &&
          faultCode['image'] != null);
      if (isFaultCodesComplete) filledFields++;
    }

    // Ensure we don't exceed 1.0 and handle potential division errors
    return (filledFields / totalFields).clamp(0.0, 1.0);
  }

  void _updateAndNotify(VoidCallback updateFunction) {
    setState(() {
      updateFunction();
    });
    widget.onProgressUpdate();
  }

  @override
  bool get wantKeepAlive => true;
}
