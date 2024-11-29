// lib/pages/truckForms/chassis_edit_page.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';

class ChassisEditPage extends StatefulWidget {
  final String vehicleId;
  final VoidCallback onProgressUpdate;
  final bool isEditing;

  const ChassisEditPage({
    Key? key,
    required this.vehicleId,
    required this.onProgressUpdate,
    this.isEditing = false,
  }) : super(key: key);

  @override
  ChassisEditPageState createState() => ChassisEditPageState();
}

class ChassisEditPageState extends State<ChassisEditPage>
    with AutomaticKeepAliveClientMixin {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage =
      FirebaseStorage.instance; // Firebase Storage instance

  String _selectedCondition = 'good';
  String _additionalFeaturesCondition = 'no';
  String _damagesCondition = 'no';

  // Maps to store selected images and their URLs
  final Map<String, File?> _selectedImages = {
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

  final Map<String, String> _imageUrls = {};

  // Lists to store damages and additional features
  List<Map<String, dynamic>> _damageList = [];
  List<Map<String, dynamic>> _additionalFeaturesList = [];

  bool _isInitialized = false; // Flag to prevent re-initialization

  @override
  bool get wantKeepAlive => true; // Properly implementing the getter

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
                    _updateAndNotify(() {
                      _selectedCondition = value;
                    });
                  }
                },
                enabled: !isDealer,
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
                  enabled: !isDealer),
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
                  enabled: !isDealer),
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
              _updateAndNotify(() {
                _damagesCondition = value!;
                if (_damagesCondition == 'yes' && _damageList.isEmpty) {
                  _damageList.add({
                    'description': '',
                    'image': null,
                    'imageUrl': null,
                    'key': UniqueKey().toString(),
                  });
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
                  _additionalFeaturesList.add({
                    'description': '',
                    'image': null,
                    'imageUrl': null,
                    'key': UniqueKey().toString(),
                  });
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

    bool hasFile = _selectedImages[title] != null;
    bool hasUrl = _imageUrls[title] != null && _imageUrls[title]!.isNotEmpty;

    // Debugging statements
    print(
        'In _buildPhotoBlock for $title, hasFile: $hasFile, hasUrl: $hasUrl, URL: ${_imageUrls[title]}');

    return GestureDetector(
      onTap: () {
        if ((isDealer || !isDealer) && (hasFile || hasUrl)) {
          // View image
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                body: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Center(
                    child: hasFile
                        ? Image.file(_selectedImages[title]!)
                        : Image.network(
                            _imageUrls[title]!,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error_outline,
                                  color: Colors.red);
                            },
                          ),
                  ),
                ),
              ),
            ),
          );
        } else if (!isDealer) {
          // Transporter functionality - upload images
          _showImageSourceDialog(title);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.blue.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: AppColors.blue, width: 2.0),
        ),
        child: hasFile
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(
                  _selectedImages[title]!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
            : hasUrl
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      _imageUrls[title]!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error_outline,
                            color: Colors.red);
                      },
                    ),
                  )
                : Column(
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
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
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
                    _updateAndNotify(() {
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
                    _updateAndNotify(() {
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

  // Helper method to build additional sections (Damages, Additional Features)
  Widget _buildAdditionalSection({
    required String title,
    required String anyItemsType,
    required ValueChanged<String?> onChange,
    required Widget Function() buildItemSection,
  }) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';
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
                enabled: !isDealer),
            const SizedBox(width: 15),
            CustomRadioButton(
                label: 'No',
                value: 'no',
                groupValue: anyItemsType,
                onChanged: onChange,
                enabled: !isDealer),
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
        _updateAndNotify(() {
          _damageList.add({
            'description': '',
            'image': null,
            'imageUrl': null,
            'key': UniqueKey().toString(),
          });
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
        _updateAndNotify(() {
          _additionalFeaturesList.add({
            'description': '',
            'image': null,
            'imageUrl': null,
            'key': UniqueKey().toString(),
          });
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

    return Column(
      children: [
        ...items.asMap().entries.map((entry) => _buildItemWidget(
            entry.key, entry.value, showImageSourceDialog, items)),
        const SizedBox(height: 16.0),
        if (!isDealer)
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

    bool hasFile = item['image'] != null;
    bool hasUrl = item['imageUrl'] != null && item['imageUrl'].isNotEmpty;

    return Column(
      children: [
        const SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController(text: item['description'])
                  ..selection = TextSelection.fromPosition(
                      TextPosition(offset: item['description']?.length ?? 0)),
                onChanged: (value) {
                  _updateAndNotify(() {
                    item['description'] = value;
                  });
                },
                readOnly: isDealer,
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
            if (!isDealer)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _updateAndNotify(() {
                    list.removeAt(index);
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 16.0),
        GestureDetector(
          onTap: () {
            if ((isDealer || !isDealer) && (hasFile || hasUrl)) {
              // View image
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    body: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Center(
                        child: hasFile
                            ? Image.file(item['image'])
                            : Image.network(
                                item['imageUrl'],
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.error_outline,
                                      color: Colors.red);
                                },
                              ),
                      ),
                    ),
                  ),
                ),
              );
            } else if (!isDealer) {
              // Transporter functionality - upload images
              showImageSourceDialog(item);
            }
          },
          child: Container(
            height: 150.0,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: AppColors.blue, width: 2.0),
            ),
            child: hasFile
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(
                      item['image'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                : hasUrl
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
                    : _buildImagePlaceholder(),
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
          'Add Image',
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
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
                    _updateAndNotify(() {
                      item['image'] = File(pickedFile.path);
                      item['imageUrl'] = ''; // Clear any existing URL
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
                      item['image'] = File(pickedFile.path);
                      item['imageUrl'] = ''; // Clear any existing URL
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

  // Method to upload images to Firebase Storage
  Future<String> _uploadImageToFirebase(File imageFile, String section) async {
    try {
      String fileName =
          'chassis/${widget.vehicleId}_${section}_${DateTime.now().millisecondsSinceEpoch}.jpg';
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

  Future<Map<String, dynamic>> getData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isTransporter = userProvider.getUserRole == 'transporter';

    if (!isTransporter) {
      return {};
    }

    Map<String, dynamic> serializedImages = {};
    for (var entry in _selectedImages.entries) {
      if (entry.value != null) {
        String imageUrl = await _uploadImageToFirebase(
            entry.value!, entry.key.replaceAll(' ', '_').toLowerCase());
        serializedImages[entry.key] = {
          'url': imageUrl,
          'isNew': true,
        };
      } else if (_imageUrls[entry.key] != null &&
          _imageUrls[entry.key]!.isNotEmpty) {
        serializedImages[entry.key] = {
          'url': _imageUrls[entry.key],
          'isNew': false,
        };
      }
    }

    List<Map<String, dynamic>> serializedDamages = [];
    for (var damage in _damageList) {
      if (damage['image'] != null) {
        String imageUrl =
            await _uploadImageToFirebase(damage['image'], 'damage');
        serializedDamages.add({
          'description': damage['description'] ?? '',
          'imageUrl': imageUrl,
          'isNew': true,
        });
      } else if (damage['imageUrl'] != null && damage['imageUrl'].isNotEmpty) {
        serializedDamages.add({
          'description': damage['description'] ?? '',
          'imageUrl': damage['imageUrl'],
          'isNew': false,
        });
      }
    }

    List<Map<String, dynamic>> serializedFeatures = [];
    for (var feature in _additionalFeaturesList) {
      if (feature['image'] != null) {
        String imageUrl =
            await _uploadImageToFirebase(feature['image'], 'feature');
        serializedFeatures.add({
          'description': feature['description'] ?? '',
          'imageUrl': imageUrl,
          'isNew': true,
        });
      } else if (feature['imageUrl'] != null &&
          feature['imageUrl'].isNotEmpty) {
        serializedFeatures.add({
          'description': feature['description'] ?? '',
          'imageUrl': feature['imageUrl'],
          'isNew': false,
        });
      }
    }

    return {
      'condition': _selectedCondition,
      'images': serializedImages,
      'damagesCondition': _damagesCondition,
      'damages': serializedDamages,
      'additionalFeaturesCondition': _additionalFeaturesCondition,
      'additionalFeatures': serializedFeatures,
    };
  }

  // Method to initialize data
  void initializeWithData(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return;
    }

    // Use the data directly
    Map<String, dynamic> chassisData = data;

    setState(() {
      // Initialize basic fields
      _selectedCondition = chassisData['condition'] ?? 'good';
      _damagesCondition = chassisData['damagesCondition'] ?? 'no';
      _additionalFeaturesCondition =
          chassisData['additionalFeaturesCondition'] ?? 'no';

      // Initialize images
      if (chassisData['images'] != null) {
        Map<String, dynamic> images =
            Map<String, dynamic>.from(chassisData['images']);
        images.forEach((key, value) {
          if (value is Map && value.containsKey('url')) {
            String? url = value['url']?.toString();
            if (url == null || url.isEmpty) {
              url = null;
            } else {}
            _imageUrls[key] = url ?? '';
            _selectedImages[key] = null;
          } else {}
        });
      } else {}

      // Initialize damage list
      if (chassisData['damages'] != null) {
        _damageList = (chassisData['damages'] as List).map((damage) {
          return {
            'description': damage['description'] ?? '',
            'image': null,
            'imageUrl': damage['imageUrl'] ?? '',
            'key': UniqueKey().toString(),
          };
        }).toList();
      } else {}

      // Initialize additional features list
      if (chassisData['additionalFeatures'] != null) {
        _additionalFeaturesList =
            (chassisData['additionalFeatures'] as List).map((feature) {
          return {
            'description': feature['description'] ?? '',
            'image': null,
            'imageUrl': feature['imageUrl'] ?? '',
            'key': UniqueKey().toString(),
          };
        }).toList();
      } else {}
    });
  }

  // Method to reset the form
  void reset() {
    setState(() {
      _selectedCondition = 'good';
      _damagesCondition = 'no';
      _additionalFeaturesCondition = 'no';

      // Clear selected images
      _selectedImages.forEach((key, _) {
        _selectedImages[key] = null;
      });

      // Clear lists
      _damageList.clear();
      _additionalFeaturesList.clear();

      // Clear image URLs
      _imageUrls.clear();

      _isInitialized = false; // Allow re-initialization if needed
    });
  }

  double getCompletionPercentage() {
    int totalFields = 17; // Total number of fields to fill
    int filledFields = 0;

    // Check condition selection (1 field)
    if (_selectedCondition.isNotEmpty) filledFields++;

    // Check all images (14 fields)
    _selectedImages.forEach((key, value) {
      if (value != null ||
          (_imageUrls[key] != null && _imageUrls[key]!.isNotEmpty)) {
        filledFields++;
      }
    });

    // Check damages section (1 field)
    if (_damagesCondition == 'no') {
      filledFields++;
    } else if (_damagesCondition == 'yes' && _damageList.isNotEmpty) {
      bool isDamagesComplete = _damageList.every((damage) =>
          damage['description']?.isNotEmpty == true &&
          (damage['image'] != null ||
              (damage['imageUrl'] != null && damage['imageUrl'].isNotEmpty)));
      if (isDamagesComplete) filledFields++;
    }

    // Check additional features section (1 field)
    if (_additionalFeaturesCondition == 'no') {
      filledFields++;
    } else if (_additionalFeaturesCondition == 'yes' &&
        _additionalFeaturesList.isNotEmpty) {
      bool isFeaturesComplete = _additionalFeaturesList.every((feature) =>
          feature['description']?.isNotEmpty == true &&
          (feature['image'] != null ||
              (feature['imageUrl'] != null && feature['imageUrl'].isNotEmpty)));
      if (isFeaturesComplete) filledFields++;
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
