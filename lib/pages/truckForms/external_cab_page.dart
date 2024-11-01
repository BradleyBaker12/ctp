import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Image picker for uploading images
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart'; // Ensure this import path is correct

class ExternalCabPage extends StatefulWidget {
  final String vehicleId;
  const ExternalCabPage({
    Key? key,
    required this.vehicleId,
  }) : super(key: key);

  @override
  ExternalCabPageState createState() => ExternalCabPageState();
}

class ExternalCabPageState extends State<ExternalCabPage>
    with AutomaticKeepAliveClientMixin {
  String _selectedCondition = 'good'; // Default selected value
  String _anyDamagesType = 'no'; // Default selected value
  String _anyAdditionalFeaturesType =
      'no'; // Default selected value for additional features
  final ImagePicker _picker = ImagePicker(); // Image picker instance

  // Scroll controller for managing automatic scrolling
  final ScrollController _scrollController = ScrollController();

  // Map to store selected images for each view
  Map<String, File?> _selectedImages = {
    'FRONT VIEW': null,
    'RIGHT SIDE VIEW': null,
    'REAR VIEW': null,
    'LEFT SIDE VIEW': null,
  };

  // List to store damage images and descriptions
  List<Map<String, dynamic>> _damageList = [];

  // List to store additional feature images and descriptions
  List<Map<String, dynamic>> _additionalFeaturesList = [];

  @override
  void dispose() {
    // Dispose the scroll controller to release resources
    _scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      controller: _scrollController, // Attach the scroll controller
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent, // Transparent background
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            const BoxShadow(
              color: Colors.black26,
              blurRadius: 6.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16.0),
            Text(
              'Details for EXTERNAL CAB'.toUpperCase(),
              style: const TextStyle(
                fontSize: 25,
                color: Color.fromARGB(221, 255, 255, 255),
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Condition of the Outside CAB',
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
            Text(
              'Front Side of Cab'.toUpperCase(),
              style: const TextStyle(
                fontSize: 25,
                color: Color.fromARGB(221, 255, 255, 255),
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            // Photo Blocks Section
            GridView.count(
              shrinkWrap: true, // Allows GridView to fit inside the Column
              physics:
                  const NeverScrollableScrollPhysics(), // Prevent GridView from scrolling independently
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 1.5, // Controls the aspect ratio of the blocks
              children: _selectedImages.keys
                  .map((title) => _buildPhotoBlock(title))
                  .toList(),
            ),
            const SizedBox(height: 70.0),
            // Damage Section
            _buildAdditionalSection(
              title: 'Are there any damages on the cab',
              anyItemsType: _anyDamagesType,
              onChange: (value) {
                setState(() {
                  _anyDamagesType = value!;
                  if (_anyDamagesType == 'yes' && _damageList.isEmpty) {
                    _damageList.add(
                        {'description': '', 'image': null, 'imageUrl': ''});
                    // Scroll down to damage section
                    _scrollToBottom();
                  } else if (_anyDamagesType == 'no') {
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
              title: 'Are there any additional features on the cab',
              anyItemsType: _anyAdditionalFeaturesType,
              onChange: (value) {
                setState(() {
                  _anyAdditionalFeaturesType = value!;
                  if (_anyAdditionalFeaturesType == 'yes' &&
                      _additionalFeaturesList.isEmpty) {
                    _additionalFeaturesList.add(
                        {'description': '', 'image': null, 'imageUrl': ''});
                    // Scroll down to additional features section
                    _scrollToBottom();
                  } else if (_anyAdditionalFeaturesType == 'no') {
                    _additionalFeaturesList.clear();
                  }
                });
              },
              buildItemSection: _buildAdditionalFeaturesSection,
            ),
          ],
        ),
      ),
    );
  }

  // Public method to save data, can be called from parent using GlobalKey
  Future<bool> saveData() async {
    try {
      // Preparing the data to save
      Map<String, dynamic> dataToSave = {
        'selectedCondition': _selectedCondition,
        'anyDamages': _anyDamagesType,
        'anyAdditionalFeatures': _anyAdditionalFeaturesType,
        'lastUpdated': FieldValue.serverTimestamp(),
        'damageList': [],
        'additionalFeaturesList': [],
      };

      // Upload damage images and set URLs
      for (var damage in _damageList) {
        if (damage['image'] != null) {
          String imageUrl = await _uploadImage(damage['image'], 'damage');
          damage['imageUrl'] = imageUrl;
        }
        dataToSave['damageList'].add({
          'description': damage['description'],
          'imageUrl': damage['imageUrl'] ?? '',
        });
      }

      // Upload additional feature images and set URLs
      for (var feature in _additionalFeaturesList) {
        if (feature['image'] != null) {
          String imageUrl = await _uploadImage(feature['image'], 'feature');
          feature['imageUrl'] = imageUrl;
        }
        dataToSave['additionalFeaturesList'].add({
          'description': feature['description'],
          'imageUrl': feature['imageUrl'] ?? '',
        });
      }

      // Upload selected images
      for (String key in _selectedImages.keys) {
        if (_selectedImages[key] != null) {
          String imageUrl = await _uploadImage(_selectedImages[key]!, key);
          dataToSave[key] = imageUrl;
        }
      }

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .collection('truckConditions')
          .doc('ExternalCab')
          .set(dataToSave, SetOptions(merge: true));

      // Check if the widget is still mounted before attempting to show a SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('External Cab data saved successfully')),
        );
      }

      return true;
    } catch (e) {
      // Check if the widget is still mounted before attempting to show a SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save External Cab data: $e')),
        );
      }
      return false;
    }
  }

  // Helper method to upload a single image to Firebase Storage
  Future<String> _uploadImage(File file, String key) async {
    try {
      String fileName =
          'external_cab/${widget.vehicleId}_$key${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(file);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return '';
    }
  }

  // Method to scroll to the bottom of the page
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
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

  // Helper method to build the additional section (Damages or Additional Features)
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

  // Helper method to build the item section (Damage or Additional Features)
  Widget _buildItemSection({
    required List<Map<String, dynamic>> items,
    required VoidCallback addItem,
    required void Function(Map<String, dynamic>) showImageSourceDialog,
  }) {
    return Column(
      children: [
        ...items.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, dynamic> item = entry.value;
          return _buildItemWidget(index, item, showImageSourceDialog);
        }).toList(),
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

  // Helper method to create an item widget (Damage or Additional Features)
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
                  if (_damageList.contains(item)) {
                    _damageList.removeAt(index);
                  }
                  if (_additionalFeaturesList.contains(item)) {
                    _additionalFeaturesList.removeAt(index);
                  }
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
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline,
                          color: Colors.white, size: 40.0),
                      SizedBox(height: 8.0),
                      Text(
                        'Clear Picture of Item',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  )
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
}
