// lib/pages/truckForms/chassis_page.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/form_data_provider.dart';

class ChassisPage extends StatefulWidget {
  final String vehicleId;
  const ChassisPage({super.key, required this.vehicleId});

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
  final Map<String, String?> _imageUrls = {
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

  // Lists to store damages and additional features
  List<Map<String, dynamic>> _damageList = [];
  List<Map<String, dynamic>> _additionalFeaturesList = [];

  // Add a loading state tracker
  final Map<String, bool> _imageUploading = {};

  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true; // Properly implementing the getter

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  // Method to load existing data from Firestore (if any)
  Future<void> _loadExistingData() async {
    if (_isInitialized) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .collection('inspections')
          .doc('chassis')
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() ?? {};
        setState(() {
          _isInitialized = true;

          // Load basic conditions
          _selectedCondition = data['condition'] ?? 'good';
          _damagesCondition = data['damagesCondition'] ?? 'no';
          _additionalFeaturesCondition =
              data['additionalFeaturesCondition'] ?? 'no';

          // Load images and URLs
          if (data['images'] != null) {
            final images = Map<String, dynamic>.from(data['images']);
            images.forEach((key, value) {
              if (value != null) {
                _imageUrls[key] = value.toString();
              }
            });
          }

          // Load damages
          if (data['damages'] != null) {
            _damageList = (data['damages'] as List).map((damage) {
              return {
                'description': damage['description'] ?? '',
                'imageUrl': damage['imageUrl'],
                'key': damage['key'] ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
              };
            }).toList();
          }

          // Load additional features
          if (data['additionalFeatures'] != null) {
            _additionalFeaturesList =
                (data['additionalFeatures'] as List).map((feature) {
              return {
                'description': feature['description'] ?? '',
                'imageUrl': feature['imageUrl'],
                'key': feature['key'] ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
              };
            }).toList();
          }
        });
      }
    } catch (e) {
      print('Error loading chassis data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  void initializeWithData(Map<String, dynamic> data) {
    if (data.isEmpty || _isInitialized) return;

    setState(() {
      _isInitialized = true;

      // Initialize basic fields
      _selectedCondition = data['condition'] ?? 'good';
      _damagesCondition = data['damagesCondition'] ?? 'no';
      _additionalFeaturesCondition =
          data['additionalFeaturesCondition'] ?? 'no';

      // Initialize images
      if (data['images'] != null) {
        Map<String, dynamic> images = Map<String, dynamic>.from(data['images']);
        images.forEach((key, value) {
          if (value is Map) {
            if (value['path'] != null) {
              _selectedImages[key] = File(value['path']);
            } else if (value['url'] != null) {
              _imageUrls[key] = value['url'];
            }
          }
        });
      }

      // Initialize damage list
      if (data['damages'] != null) {
        _damageList = (data['damages'] as List).map((damage) {
          return {
            'description': damage['description'] ?? '',
            'image':
                damage['imagePath'] != null ? File(damage['imagePath']) : null,
            'imageUrl': damage['imageUrl'],
            'key': damage['key'] ??
                DateTime.now().millisecondsSinceEpoch.toString(),
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
            'imageUrl': feature['imageUrl'],
            'key': feature['key'] ??
                DateTime.now().millisecondsSinceEpoch.toString(),
          };
        }).toList();
      }
    });
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
        ...items.asMap().entries.map((entry) => _buildItemWidget(
            entry.key, entry.value, showImageSourceDialog, items)),
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
                controller: TextEditingController(text: item['description'])
                  ..selection = TextSelection.fromPosition(
                      TextPosition(offset: item['description']?.length ?? 0)),
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
            child: _buildImageWidget(item),
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
          title: Text('Choose Image Source for ${item['title']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => _handleImageSelection(ImageSource.camera, item),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => _handleImageSelection(ImageSource.gallery, item),
              ),
            ],
          ),
        );
      },
    );
  }

  // Optimize image selection handling
  Future<void> _handleImageSelection(
      ImageSource source, Map<String, dynamic> item) async {
    try {
      Navigator.pop(context);

      setState(() => _imageUploading[item['key']] = true);

      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Optimize image quality
        maxWidth: 1200, // Limit image dimensions
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImages[item['key']] = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    } finally {
      setState(() => _imageUploading[item['key']] = false);
    }
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

  // Optimize save method
  Future<bool> saveData() async {
    try {
      // Upload view images and get URLs
      Map<String, String> imageUrls = {};
      for (var entry in _selectedImages.entries) {
        if (entry.value != null) {
          String imagePath =
              'vehicles/${widget.vehicleId}/chassis/views/${entry.key}_${DateTime.now().millisecondsSinceEpoch}';
          String downloadUrl = await _uploadImage(entry.value!, imagePath);
          if (downloadUrl.isNotEmpty) {
            imageUrls[entry.key] = downloadUrl;
            _imageUrls[entry.key] = downloadUrl;
          }
        } else if (_imageUrls.containsKey(entry.key)) {
          imageUrls[entry.key] = _imageUrls[entry.key]!;
        }
      }

      // Upload and prepare damages data
      List<Map<String, dynamic>> damagesData = [];
      if (_damagesCondition == 'yes') {
        for (var damage in _damageList) {
          String imageUrl = damage['imageUrl'] ?? '';
          if (damage['image'] != null) {
            String imagePath =
                'vehicles/${widget.vehicleId}/chassis/damages/damage_${damage['key']}';
            imageUrl = await _uploadImage(damage['image'], imagePath);
          }
          damagesData.add({
            'description': damage['description'] ?? '',
            'imageUrl': imageUrl,
            'key': damage['key'],
          });
        }
      }

      // Upload and prepare additional features data
      List<Map<String, dynamic>> featuresData = [];
      if (_additionalFeaturesCondition == 'yes') {
        for (var feature in _additionalFeaturesList) {
          String imageUrl = feature['imageUrl'] ?? '';
          if (feature['image'] != null) {
            String imagePath =
                'vehicles/${widget.vehicleId}/chassis/features/feature_${feature['key']}';
            imageUrl = await _uploadImage(feature['image'], imagePath);
          }
          featuresData.add({
            'description': feature['description'] ?? '',
            'imageUrl': imageUrl,
            'key': feature['key'],
          });
        }
      }

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .collection('inspections')
          .doc('chassis')
          .set({
        'condition': _selectedCondition,
        'images': imageUrls,
        'damagesCondition': _damagesCondition,
        'damages': damagesData,
        'additionalFeaturesCondition': _additionalFeaturesCondition,
        'additionalFeatures': featuresData,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error saving chassis data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save chassis data: $e')),
        );
      }
      return false;
    }
  }

  Future<Map<String, dynamic>> getData() async {
    // Create a sanitized copy of the data
    Map<String, dynamic> sanitizedData = {
      'condition': _selectedCondition,
      'damagesCondition': _damagesCondition,
      'additionalFeaturesCondition': _additionalFeaturesCondition,
    };

    // Handle images
    Map<String, dynamic> imageData = {};
    for (var entry in _selectedImages.entries) {
      if (entry.value != null) {
        imageData[entry.key] = {
          'path': entry.value!.path,
          'isNew': true,
        };
      } else if (_imageUrls.containsKey(entry.key)) {
        imageData[entry.key] = {
          'url': _imageUrls[entry.key],
          'isNew': false,
        };
      }
    }

    // Handle damages
    List<Map<String, dynamic>> serializedDamages = _damageList.map((damage) {
      return {
        'description': damage['description'] ?? '',
        'imagePath': damage['image']?.path,
        'imageUrl': damage['imageUrl'],
        'key': damage['key'],
        'isNew': damage['image'] != null,
      };
    }).toList();

    // Handle additional features
    List<Map<String, dynamic>> serializedFeatures =
        _additionalFeaturesList.map((feature) {
      return {
        'description': feature['description'] ?? '',
        'imagePath': feature['image']?.path,
        'imageUrl': feature['imageUrl'],
        'key': feature['key'],
        'isNew': feature['image'] != null,
      };
    }).toList();

    sanitizedData['images'] = imageData;
    sanitizedData['damages'] = serializedDamages;
    sanitizedData['additionalFeatures'] = serializedFeatures;

    return sanitizedData;
  }

  Future<String> _uploadImage(File imageFile, String imageName) async {
    try {
      final ref =
          _storage.ref().child('chassis/${widget.vehicleId}/$imageName');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return '';
    }
  }

  // Add helper method to build image widget
  Widget _buildImageWidget(Map<String, dynamic> item) {
    if (item['image'] != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.file(
          item['image'],
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (item['imageUrl'] != null && item['imageUrl'].isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          item['imageUrl'],
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
                child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ));
          },
          errorBuilder: (context, error, stackTrace) =>
              _buildImagePlaceholder(),
        ),
      );
    } else {
      return _buildImagePlaceholder();
    }
  }

  // // Add helper method for image placeholder
  // Widget _buildImagePlaceholder() {
  //   return const Column(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       Icon(Icons.add_circle_outline, color: Colors.white, size: 40.0),
  //       SizedBox(height: 8.0),
  //       Text(
  //         'Add Image',
  //         style: TextStyle(
  //           color: Colors.white,
  //           fontSize: 16,
  //           fontWeight: FontWeight.w600
  //         ),
  //       ),
  //     ],
  //   );
  // }
}
