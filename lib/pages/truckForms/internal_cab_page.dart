// lib/pages/truckForms/internal_cab_page.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui; // Added for platformViewRegistry
// import 'dart:ui_web';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Added for Firebase Storage
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart';
import 'package:universal_html/html.dart' as html; // For web functionality

class ImageData {
  final Uint8List? file;
  final String? url;
  final String? fileName;

  ImageData({this.file, this.url, this.fileName});
}

class ItemData {
  String description;
  ImageData imageData;

  ItemData({required this.description, required this.imageData});
}

class InternalCabPage extends StatefulWidget {
  final String vehicleId;
  final VoidCallback onProgressUpdate;
  final bool isEditing;

  const InternalCabPage({
    super.key,
    required this.vehicleId,
    required this.onProgressUpdate,
    this.isEditing = false,
  });

  @override
  InternalCabPageState createState() => InternalCabPageState();
}

class InternalCabPageState extends State<InternalCabPage>
    with AutomaticKeepAliveClientMixin {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // Firebase Storage

  String _selectedCondition = 'good'; // Default selected value
  String _damagesCondition = 'no';
  String _additionalFeaturesCondition = 'no';
  String _faultCodesCondition = 'no';

  // Map to store selected images for different sections
  final Map<String, ImageData> _selectedImages = {
    'Center Dash': ImageData(),
    'Left Dash': ImageData(),
    'Right Dash (Vehicle On)': ImageData(),
    'Mileage': ImageData(),
    'Sun Visors': ImageData(),
    'Center Console': ImageData(),
    'Steering': ImageData(),
    'Left Door Panel': ImageData(),
    'Left Seat': ImageData(),
    'Roof': ImageData(),
    'Bunk Beds': ImageData(),
    'Rear Panel': ImageData(),
    'Right Door Panel': ImageData(),
    'Right Seat': ImageData(),
  };

  // Lists to store damages, additional features, and fault codes
  List<ItemData> _damageList = [];
  List<ItemData> _additionalFeaturesList = [];
  List<ItemData> _faultCodesList = [];

  bool _isInitialized = false; // Flag to prevent re-initialization

  @override
  Widget build(BuildContext context) {
    super.build(context); // Needed by AutomaticKeepAliveClientMixin
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
                    _damageList
                        .add(ItemData(description: '', imageData: ImageData()));
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
                        .add(ItemData(description: '', imageData: ImageData()));
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
                    _faultCodesList
                        .add(ItemData(description: '', imageData: ImageData()));
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

  // Helper method to create a photo block with an 'X' button to remove the image
  Widget _buildPhotoBlock(String title) {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(title),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.blue.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: AppColors.blue, width: 2.0),
        ),
        child: _selectedImages[title]?.file == null
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.memory(
                      _selectedImages[title]!.file!,
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
                        // Stop event propagation so tapping 'X' doesn't open the picker
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
                  if (kIsWeb) {
                    bool cameraAvailable = false;
                    try {
                      cameraAvailable =
                          html.window.navigator.mediaDevices != null;
                    } catch (e) {
                      cameraAvailable = false;
                    }
                    if (cameraAvailable) {
                      await _takePhotoFromWeb((file, fileName) {
                        if (file != null) {
                          setState(() {
                            _selectedImages[title] =
                                ImageData(file: file, fileName: fileName);
                          });
                        }
                      });
                    } else {
                      // Fallback to standard picker if needed
                      final pickedFile =
                          await _picker.pickImage(source: ImageSource.camera);
                      if (pickedFile != null) {
                        final bytes = await pickedFile.readAsBytes();
                        final fileName = pickedFile.name;
                        setState(() {
                          _selectedImages[title] =
                              ImageData(file: bytes, fileName: fileName);
                        });
                      }
                    }
                  } else {
                    final pickedFile =
                        await _picker.pickImage(source: ImageSource.camera);
                    if (pickedFile != null) {
                      final bytes = await pickedFile.readAsBytes();
                      final fileName = pickedFile.name;
                      setState(() {
                        _selectedImages[title] =
                            ImageData(file: bytes, fileName: fileName);
                      });
                    }
                  }
                  widget.onProgressUpdate();
                },
              ),
              // ...existing Gallery option ListTile...
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final pickedFile =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    final bytes = await pickedFile.readAsBytes();
                    final fileName = pickedFile.name;
                    setState(() {
                      _selectedImages[title] =
                          ImageData(file: bytes, fileName: fileName);
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

  // Helper method to build the additional sections (Damages, Additional Features, Fault Codes)
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
          _damageList.add(ItemData(description: '', imageData: ImageData()));
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
              .add(ItemData(description: '', imageData: ImageData()));
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
              .add(ItemData(description: '', imageData: ImageData()));
        });
      },
      showImageSourceDialog: _showFaultCodesImageSourceDialog,
    );
  }

  // Helper method to build an item section (Damages, Additional Features, Fault Codes)
  Widget _buildItemSection({
    required List<ItemData> items,
    required VoidCallback addItem,
    required void Function(ItemData) showImageSourceDialog,
  }) {
    return Column(
      children: [
        ...items.asMap().entries.map(
              (entry) => _buildItemWidget(
                entry.key,
                entry.value,
                showImageSourceDialog,
              ),
            ),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to create an item widget (Damages, Additional Features, Fault Codes)
  Widget _buildItemWidget(
    int index,
    ItemData item,
    void Function(ItemData) showImageSourceDialog,
  ) {
    return Column(
      children: [
        const SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (value) {
                  _updateAndNotify(() {
                    item.description = value;
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

        // Container for the item image
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
            child: item.imageData.file == null
                ? _buildImagePlaceholder()
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.memory(
                          item.imageData.file!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              item.imageData = ImageData();
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
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Method to remove an item from the appropriate list
  void _removeItem(int index, ItemData item) {
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

  // The following methods open a dialog to pick images for each item type

  void _showDamageImageSourceDialog(ItemData damage) {
    _showImageSourceDialogForItem(damage);
  }

  void _showAdditionalFeatureImageSourceDialog(ItemData feature) {
    _showImageSourceDialogForItem(feature);
  }

  void _showFaultCodesImageSourceDialog(ItemData faultCode) {
    _showImageSourceDialogForItem(faultCode);
  }

  // Generic method to show dialog for selecting image source for a given item
  void _showImageSourceDialogForItem(ItemData item) {
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
                    final bytes = await pickedFile.readAsBytes();
                    final fileName = pickedFile.name;
                    setState(() {
                      item.imageData =
                          ImageData(file: bytes, fileName: fileName);
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
                    final bytes = await pickedFile.readAsBytes();
                    final fileName = pickedFile.name;
                    setState(() {
                      item.imageData =
                          ImageData(file: bytes, fileName: fileName);
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

  // Method to upload an image to Firebase Storage
  Future<String> _uploadImageToFirebase(
      Uint8List imageFile, String section) async {
    try {
      String fileName =
          'internal_cab/${widget.vehicleId}_${section}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putData(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return '';
    }
  }

  // Method to upload all images and retrieve their URLs
  Future<Map<String, dynamic>> getData() async {
    // Serialize and upload view images
    Map<String, dynamic> serializedImages = {};
    for (var entry in _selectedImages.entries) {
      if (entry.value.file != null) {
        String section = entry.key.replaceAll(' ', '_').toLowerCase();
        String imageUrl =
            await _uploadImageToFirebase(entry.value.file!, section);
        serializedImages[entry.key] = {
          'url': imageUrl,
          'fileName': entry.value.fileName,
          'isNew': true
        };
      }
    }

    // Serialize and upload damages
    List<Map<String, dynamic>> serializedDamages = [];
    for (var damage in _damageList) {
      if (damage.imageData.file != null) {
        String imageUrl =
            await _uploadImageToFirebase(damage.imageData.file!, 'damage');
        serializedDamages.add({
          'description': damage.description,
          'imageUrl': imageUrl,
          'fileName': damage.imageData.fileName,
          'isNew': true
        });
      } else {
        serializedDamages.add({
          'description': damage.description,
          'imageUrl': damage.imageData.url,
          'fileName': damage.imageData.fileName,
          'isNew': false
        });
      }
    }

    // Serialize and upload additional features
    List<Map<String, dynamic>> serializedFeatures = [];
    for (var feature in _additionalFeaturesList) {
      if (feature.imageData.file != null) {
        String imageUrl =
            await _uploadImageToFirebase(feature.imageData.file!, 'feature');
        serializedFeatures.add({
          'description': feature.description,
          'imageUrl': imageUrl,
          'fileName': feature.imageData.fileName,
          'isNew': true
        });
      } else {
        serializedFeatures.add({
          'description': feature.description,
          'imageUrl': feature.imageData.url,
          'fileName': feature.imageData.fileName,
          'isNew': false
        });
      }
    }

    // Serialize and upload fault codes
    List<Map<String, dynamic>> serializedFaultCodes = [];
    for (var faultCode in _faultCodesList) {
      if (faultCode.imageData.file != null) {
        String imageUrl = await _uploadImageToFirebase(
            faultCode.imageData.file!, 'fault_code');
        serializedFaultCodes.add({
          'description': faultCode.description,
          'imageUrl': imageUrl,
          'fileName': faultCode.imageData.fileName,
          'isNew': true
        });
      } else {
        serializedFaultCodes.add({
          'description': faultCode.description,
          'imageUrl': faultCode.imageData.url,
          'fileName': faultCode.imageData.fileName,
          'isNew': false
        });
      }
    }

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

  // Placeholder method for saving data. Implement as needed.
  Future<bool> saveData() async {
    try {
      Map<String, dynamic> dataToSave = await getData();
      await _firestore
          .collection('vehicles')
          .doc(widget.vehicleId)
          .set({'internalCab': dataToSave}, SetOptions(merge: true));
      return true;
    } catch (e) {
      // Handle errors appropriately
      print('Error saving data: $e');
      return false;
    }
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
          if (value is Map) {
            if (value['fileName'] != null) {
              _selectedImages[key] = ImageData(
                file: File(value['fileName']).readAsBytesSync(),
                url: value['url'],
                fileName: value['fileName'],
              );
            } else if (value['url'] != null) {
              _selectedImages[key] = ImageData(url: value['url']);
            }
          }
        });
      }

      // Initialize damages list
      if (data['damages'] != null) {
        _damageList = (data['damages'] as List).map((damage) {
          return ItemData(
            description: damage['description'] ?? '',
            imageData: ImageData(
              file: damage['fileName'] != null
                  ? File(damage['fileName']).readAsBytesSync()
                  : null,
              url: damage['imageUrl'],
              fileName: damage['fileName'],
            ),
          );
        }).toList();
      }

      // Initialize additional features list
      if (data['additionalFeatures'] != null) {
        _additionalFeaturesList =
            (data['additionalFeatures'] as List).map((feature) {
          return ItemData(
            description: feature['description'] ?? '',
            imageData: ImageData(
              file: feature['fileName'] != null
                  ? File(feature['fileName']).readAsBytesSync()
                  : null,
              url: feature['imageUrl'],
              fileName: feature['fileName'],
            ),
          );
        }).toList();
      }

      // Initialize fault codes list
      if (data['faultCodes'] != null) {
        _faultCodesList = (data['faultCodes'] as List).map((faultCode) {
          return ItemData(
            description: faultCode['description'] ?? '',
            imageData: ImageData(
              file: faultCode['fileName'] != null
                  ? File(faultCode['fileName']).readAsBytesSync()
                  : null,
              url: faultCode['imageUrl'],
              fileName: faultCode['fileName'],
            ),
          );
        }).toList();
      }
    });
  }

  void reset() {
    setState(() {
      _selectedCondition = 'good';
      _damagesCondition = 'no';
      _additionalFeaturesCondition = 'no';
      _faultCodesCondition = 'no';

      _selectedImages.forEach((key, _) {
        _selectedImages[key] = ImageData();
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
      if (value.file != null) filledFields++;
    });

    // Check damages section (1 field)
    if (_damagesCondition == 'no') {
      filledFields++;
    } else if (_damagesCondition == 'yes' && _damageList.isNotEmpty) {
      bool isDamagesComplete = _damageList.every((damage) =>
          damage.description.isNotEmpty && damage.imageData.file != null);
      if (isDamagesComplete) filledFields++;
    }

    // Check additional features section (1 field)
    if (_additionalFeaturesCondition == 'no') {
      filledFields++;
    } else if (_additionalFeaturesCondition == 'yes' &&
        _additionalFeaturesList.isNotEmpty) {
      bool isFeaturesComplete = _additionalFeaturesList.every((feature) =>
          feature.description.isNotEmpty && feature.imageData.file != null);
      if (isFeaturesComplete) filledFields++;
    }

    // Check fault codes section (1 field)
    if (_faultCodesCondition == 'no') {
      filledFields++;
    } else if (_faultCodesCondition == 'yes' && _faultCodesList.isNotEmpty) {
      bool isFaultCodesComplete = _faultCodesList.every((faultCode) =>
          faultCode.description.isNotEmpty && faultCode.imageData.file != null);
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

  Future<void> _takePhotoFromWeb(
      void Function(Uint8List?, String) callback) async {
    if (!kIsWeb) {
      callback(null, '');
      return;
    }
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        callback(null, '');
        return;
      }
      final mediaStream = await mediaDevices.getUserMedia({'video': true});
      final videoElement = html.VideoElement()
        ..autoplay = true
        ..srcObject = mediaStream;
      await videoElement.onLoadedMetadata.first;
      String viewID = 'webcam_${DateTime.now().millisecondsSinceEpoch}';
      // platformViewRegistry.registerViewFactory(
      //     viewID, (int viewId) => videoElement);
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Take Photo'),
            content: SizedBox(
              width: 300,
              height: 300,
              child: HtmlElementView(viewType: viewID),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // final canvas = html.CanvasElement(
                  //   width: videoElement.videoWidth,
                  //   height: videoElement.videoHeight,
                  // );
                  // canvas.context2D.drawImage(videoElement, 0, 0);
                  // final dataUrl = canvas.toDataUrl('image/png');
                  // final base64Str = dataUrl.split(',').last;
                  // final imageBytes = base64.decode(base64Str);
                  // mediaStream.getTracks().forEach((track) => track.stop());
                  // Navigator.of(dialogContext).pop();
                  // callback(imageBytes, 'captured.png');
                },
                child: const Text('Capture'),
              ),
              TextButton(
                onPressed: () {
                  // mediaStream.getTracks().forEach((track) => track.stop());
                  // Navigator.of(dialogContext).pop();
                  // callback(null, '');
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      callback(null, '');
    }
  }

  @override
  bool get wantKeepAlive => true;
}
