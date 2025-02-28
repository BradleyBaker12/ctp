// lib/pages/truckForms/chassis_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
// Added for platformViewRegistry
// For web camera access

import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart';
import 'dart:io';

// Import the camera helper for cross-platform photo capture
import 'package:ctp/utils/camera_helper.dart';

/// Holds the image data in a cross-platform manner.
/// - [file] for in-memory bytes (works on web & mobile)
/// - [url] for any previously uploaded image
/// - [fileName] if you want to track the original name
class ImageData {
  final Uint8List? file;
  final String? url;
  final String? fileName;

  const ImageData({this.file, this.url, this.fileName});

  bool get hasImage => (file != null) || (url != null && url!.isNotEmpty);
}

/// Represents a "damage" or "additional feature" item with description + image.
class ItemData {
  String description;
  ImageData imageData;

  ItemData({
    required this.description,
    required this.imageData,
  });
}

class ChassisPage extends StatefulWidget {
  final String vehicleId;
  final VoidCallback onProgressUpdate;
  final bool isEditing;

  const ChassisPage({
    super.key,
    required this.vehicleId,
    required this.onProgressUpdate,
    this.isEditing = false,
  });

  @override
  ChassisPageState createState() => ChassisPageState();
}

class ChassisPageState extends State<ChassisPage>
    with AutomaticKeepAliveClientMixin {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Overall condition radio buttons
  String _selectedCondition = 'good';

  // Additional sections: "damages" and "additional features"
  String _damagesCondition = 'no';
  String _additionalFeaturesCondition = 'no';

  // Map to store images for each labeled section
  final Map<String, ImageData> _selectedImages = {
    'Right Brake': const ImageData(),
    'Left Brake': const ImageData(),
    'Front Axel': const ImageData(),
    'Suspension': const ImageData(),
    'Fuel Tank': const ImageData(),
    'Battery': const ImageData(),
    'Cat Walk': const ImageData(),
    'Electrical Cable Black': const ImageData(),
    'Air Cable Yellow': const ImageData(),
    'Air Cable Red': const ImageData(),
    'Tail Board': const ImageData(),
    '5th Wheel': const ImageData(),
    'Left Brake Rear Axel': const ImageData(),
    'Right Brake Rear Axel': const ImageData(),
  };

  // Lists to store "damages" and "additional features"
  List<ItemData> _damageList = [];
  List<ItemData> _additionalFeaturesList = [];

  bool _isInitialized = false; // For one-time initialization, if needed

  @override
  bool get wantKeepAlive => true; // For AutomaticKeepAliveClientMixin

  @override
  Widget build(BuildContext context) {
    super.build(context); // Must call for AutomaticKeepAliveClientMixin
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

            // Condition radio buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomRadioButton(
                  label: 'Poor',
                  value: 'poor',
                  groupValue: _selectedCondition,
                  onChanged: (val) => _updateAndNotify(() {
                    _selectedCondition = val!;
                  }),
                ),
                CustomRadioButton(
                  label: 'Good',
                  value: 'good',
                  groupValue: _selectedCondition,
                  onChanged: (val) => _updateAndNotify(() {
                    _selectedCondition = val!;
                  }),
                ),
                CustomRadioButton(
                  label: 'Excellent',
                  value: 'excellent',
                  groupValue: _selectedCondition,
                  onChanged: (val) => _updateAndNotify(() {
                    _selectedCondition = val!;
                  }),
                ),
              ],
            ),

            const SizedBox(height: 16.0),
            const Divider(thickness: 1.0),
            const SizedBox(height: 16.0),

            // Front Axel
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

            // Center of Chassis
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

            // Rear Axel
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
              onChange: (val) => _updateAndNotify(() {
                _damagesCondition = val!;
                if (_damagesCondition == 'yes' && _damageList.isEmpty) {
                  _damageList.add(ItemData(
                    description: '',
                    imageData: const ImageData(),
                  ));
                } else if (_damagesCondition == 'no') {
                  _damageList.clear();
                }
              }),
              buildItemSection: _buildDamageSection,
            ),
            const SizedBox(height: 16.0),
            const Divider(thickness: 1.0),
            const SizedBox(height: 16.0),

            // Additional Features Section
            _buildAdditionalSection(
              title: 'Are there any additional features?',
              anyItemsType: _additionalFeaturesCondition,
              onChange: (val) => _updateAndNotify(() {
                _additionalFeaturesCondition = val!;
                if (_additionalFeaturesCondition == 'yes' &&
                    _additionalFeaturesList.isEmpty) {
                  _additionalFeaturesList.add(ItemData(
                    description: '',
                    imageData: const ImageData(),
                  ));
                } else if (_additionalFeaturesCondition == 'no') {
                  _additionalFeaturesList.clear();
                }
              }),
              buildItemSection: _buildAdditionalFeaturesSection,
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  // ------------------------------
  // IMAGE GRID FOR MAIN SECTIONS
  // ------------------------------
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

  /// Builds a single "photo block" with an add icon or the image + X button.
  Widget _buildPhotoBlock(String title) {
    final imageData = _selectedImages[title];
    final hasFile = (imageData?.file != null);
    final hasUrl = (imageData?.url != null && imageData!.url!.isNotEmpty);

    return GestureDetector(
      onTap: () {
        // If there's already an image, show full-screen preview; else pick new
        if (hasFile || hasUrl) {
          _showFullScreenImage(imageData!);
        } else {
          _showImageSourceDialog(title);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.blue.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: AppColors.blue, width: 2.0),
        ),
        child: (!hasFile && !hasUrl)
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
                  // Show the image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: hasFile
                        ? Image.memory(
                            imageData!.file!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Image.network(
                            imageData!.url!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                  ),
                  // "X" button to remove
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImages[title] = const ImageData();
                        });
                        widget.onProgressUpdate();
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

  /// Full-screen preview when tapping an existing image
  void _showFullScreenImage(ImageData imageData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: (imageData.file != null)
                  ? Image.memory(imageData.file!)
                  : Image.network(imageData.url!),
            ),
          ),
        ),
      ),
    );
  }

  /// Dialog to pick an image from camera or gallery
  void _showImageSourceDialog(String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Image Source for $title'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Updated Camera option using the camera helper:
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final imageBytes = await capturePhoto(context);
                  if (imageBytes != null) {
                    setState(() {
                      _selectedImages[title] = ImageData(
                        file: imageBytes,
                        fileName: 'captured.png',
                      );
                    });
                  }
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
                      _selectedImages[title] = ImageData(
                        file: bytes,
                        fileName: pickedFile.name,
                      );
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

  // ------------------------------
  // DAMAGES & ADDITIONAL FEATURES
  // ------------------------------
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

  // Build the damage section
  Widget _buildDamageSection() {
    return _buildItemSection(
      items: _damageList,
      addItem: () {
        setState(() {
          _damageList.add(
            ItemData(description: '', imageData: const ImageData()),
          );
        });
      },
      showImageSourceDialog: _showDamageImageSourceDialog,
    );
  }

  // Build the additional features section
  Widget _buildAdditionalFeaturesSection() {
    return _buildItemSection(
      items: _additionalFeaturesList,
      addItem: () {
        setState(() {
          _additionalFeaturesList.add(
            ItemData(description: '', imageData: const ImageData()),
          );
        });
      },
      showImageSourceDialog: _showAdditionalFeatureImageSourceDialog,
    );
  }

  /// Generic builder for "damages" or "additional features" list
  Widget _buildItemSection({
    required List<ItemData> items,
    required VoidCallback addItem,
    required void Function(ItemData) showImageSourceDialog,
  }) {
    return Column(
      children: [
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildItemWidget(index, item, showImageSourceDialog, items);
        }),
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

  /// Builds each item (damage or additional feature) with text + image
  Widget _buildItemWidget(
    int index,
    ItemData item,
    void Function(ItemData) showImageSourceDialog,
    List<ItemData> list,
  ) {
    final hasFile = (item.imageData.file != null);
    final hasUrl =
        (item.imageData.url != null && item.imageData.url!.isNotEmpty);

    return Column(
      children: [
        const SizedBox(height: 16.0),
        // Row with TextField + Delete button
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController(text: item.description)
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: item.description.length),
                  ),
                onChanged: (value) {
                  setState(() {
                    item.description = value;
                  });
                  widget.onProgressUpdate();
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
                widget.onProgressUpdate();
              },
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        // Image container
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
            child: (!hasFile && !hasUrl)
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline,
                          color: Colors.white, size: 40.0),
                      SizedBox(height: 8.0),
                      Text(
                        'Add Image',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: hasFile
                            ? Image.memory(
                                item.imageData.file!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : Image.network(
                                item.imageData.url!,
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
                              item.imageData = const ImageData();
                            });
                            widget.onProgressUpdate();
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

  /// Show a camera/gallery dialog for a single damage/feature item
  void _showDamageImageSourceDialog(ItemData damage) {
    _showImageSourceDialogForItem(damage);
  }

  void _showAdditionalFeatureImageSourceDialog(ItemData feature) {
    _showImageSourceDialogForItem(feature);
  }

  // Generic method to show dialog for selecting image source for a given item.
  void _showImageSourceDialogForItem(ItemData item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Updated Camera option using capturePhoto:
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final imageBytes = await capturePhoto(context);
                  if (imageBytes != null) {
                    setState(() {
                      item.imageData = ImageData(file: imageBytes);
                    });
                    widget.onProgressUpdate();
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
                    final bytes = await File(pickedFile.path).readAsBytes();
                    setState(() {
                      item.imageData =
                          ImageData(file: bytes, fileName: pickedFile.name);
                    });
                    widget.onProgressUpdate();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------
  // SAVE & INITIALIZATION LOGIC
  // ------------------------------

  /// If you have existing data from Firestore or elsewhere, you can load it here
  void initializeWithData(Map<String, dynamic> data) {
    if (data.isEmpty) return;

    setState(() {
      _selectedCondition = data['condition'] ?? 'good';
      _damagesCondition = data['damagesCondition'] ?? 'no';
      _additionalFeaturesCondition =
          data['additionalFeaturesCondition'] ?? 'no';

      // Main images
      if (data['images'] != null) {
        final images = Map<String, dynamic>.from(data['images']);
        images.forEach((key, value) {
          if (!_selectedImages.containsKey(key)) return;
          if (value is Map && value['url'] != null) {
            _selectedImages[key] = ImageData(
              file: null, // not storing local file bytes
              url: value['url'],
            );
          }
        });
      }

      // Damages
      if (data['damages'] != null) {
        _damageList = (data['damages'] as List).map((damage) {
          return ItemData(
            description: damage['description'] ?? '',
            imageData: ImageData(
              file: null,
              url: damage['imageUrl'],
            ),
          );
        }).toList();

        if (_damagesCondition == 'yes' && _damageList.isEmpty) {
          _damageList
              .add(ItemData(description: '', imageData: const ImageData()));
        }
      }

      // Additional features
      if (data['additionalFeatures'] != null) {
        _additionalFeaturesList =
            (data['additionalFeatures'] as List).map((feature) {
          return ItemData(
            description: feature['description'] ?? '',
            imageData: ImageData(
              file: null,
              url: feature['imageUrl'],
            ),
          );
        }).toList();

        if (_additionalFeaturesCondition == 'yes' &&
            _additionalFeaturesList.isEmpty) {
          _additionalFeaturesList
              .add(ItemData(description: '', imageData: const ImageData()));
        }
      }
    });
  }

  /// Example method to "save" data. You can implement logic if needed.
  Future<bool> saveData() async {
    // Save logic, if any, goes here
    return true;
  }

  /// Upload bytes to Firebase Storage, returning the download URL
  Future<String> _uploadImageToFirebase(
      Uint8List imageData, String section) async {
    try {
      final fileName =
          'chassis/${widget.vehicleId}_${section}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = storageRef.putData(imageData);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return '';
    }
  }

  /// Collect the user-entered data, optionally uploading new images.
  Future<Map<String, dynamic>> getData() async {
    // 1) Main images
    final Map<String, dynamic> serializedImages = {};
    for (var entry in _selectedImages.entries) {
      final title = entry.key;
      final data = entry.value;
      if (data.file != null) {
        // We have bytes, upload them
        final url = await _uploadImageToFirebase(
          data.file!,
          title.replaceAll(' ', '_').toLowerCase(),
        );
        serializedImages[title] = {
          'url': url,
          'isNew': true,
        };
      } else if (data.url != null && data.url!.isNotEmpty) {
        // Already had a URL
        serializedImages[title] = {
          'url': data.url,
          'isNew': false,
        };
      }
    }

    // 2) Damages
    final List<Map<String, dynamic>> serializedDamages = [];
    for (final damage in _damageList) {
      if (damage.imageData.file != null) {
        final url =
            await _uploadImageToFirebase(damage.imageData.file!, 'damage');
        serializedDamages.add({
          'description': damage.description,
          'imageUrl': url,
          'isNew': true,
        });
      } else if (damage.imageData.url != null &&
          damage.imageData.url!.isNotEmpty) {
        serializedDamages.add({
          'description': damage.description,
          'imageUrl': damage.imageData.url,
          'isNew': false,
        });
      }
    }

    // 3) Additional features
    final List<Map<String, dynamic>> serializedFeatures = [];
    for (final feature in _additionalFeaturesList) {
      if (feature.imageData.file != null) {
        final url =
            await _uploadImageToFirebase(feature.imageData.file!, 'feature');
        serializedFeatures.add({
          'description': feature.description,
          'imageUrl': url,
          'isNew': true,
        });
      } else if (feature.imageData.url != null &&
          feature.imageData.url!.isNotEmpty) {
        serializedFeatures.add({
          'description': feature.description,
          'imageUrl': feature.imageData.url,
          'isNew': false,
        });
      }
    }

    return {
      'condition': _selectedCondition,
      'damagesCondition': _damagesCondition,
      'additionalFeaturesCondition': _additionalFeaturesCondition,
      'images': serializedImages,
      'damages': serializedDamages,
      'additionalFeatures': serializedFeatures,
    };
  }

  /// Reset all fields
  void reset() {
    setState(() {
      _selectedCondition = 'good';
      _damagesCondition = 'no';
      _additionalFeaturesCondition = 'no';

      // Clear images
      _selectedImages.forEach((key, value) {
        _selectedImages[key] = const ImageData();
      });

      // Clear lists
      _damageList.clear();
      _additionalFeaturesList.clear();

      _isInitialized = false;
    });
  }

  /// Example logic for a "completion percentage"
  double getCompletionPercentage() {
    int totalFields =
        17; // 1 condition + 14 images + 2 sections (damages & additional features)
    int filledFields = 0;

    // Condition
    if (_selectedCondition.isNotEmpty) filledFields++;

    // 14 images
    _selectedImages.forEach((_, data) {
      if (data.file != null || (data.url != null && data.url!.isNotEmpty)) {
        filledFields++;
      }
    });

    // Damages
    if (_damagesCondition == 'no') {
      filledFields++;
    } else if (_damagesCondition == 'yes' && _damageList.isNotEmpty) {
      final isDamagesComplete = _damageList.every((damage) =>
          damage.description.isNotEmpty &&
          (damage.imageData.file != null ||
              (damage.imageData.url != null &&
                  damage.imageData.url!.isNotEmpty)));
      if (isDamagesComplete) filledFields++;
    }

    // Additional features
    if (_additionalFeaturesCondition == 'no') {
      filledFields++;
    } else if (_additionalFeaturesCondition == 'yes' &&
        _additionalFeaturesList.isNotEmpty) {
      final isFeaturesComplete = _additionalFeaturesList.every((feature) =>
          feature.description.isNotEmpty &&
          (feature.imageData.file != null ||
              (feature.imageData.url != null &&
                  feature.imageData.url!.isNotEmpty)));
      if (isFeaturesComplete) filledFields++;
    }

    return (filledFields / totalFields).clamp(0.0, 1.0);
  }

  /// Helper to update and notify parent
  void _updateAndNotify(VoidCallback updateFunction) {
    setState(() {
      updateFunction();
    });
    widget.onProgressUpdate();
  }
}
