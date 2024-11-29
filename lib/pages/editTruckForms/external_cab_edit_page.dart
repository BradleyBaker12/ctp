// lib/pages/truckForms/external_cab_page.dart

import 'dart:io';
import 'package:ctp/providers/user_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Image picker for uploading images
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart';
import 'package:provider/provider.dart'; // Ensure this import path is correct

/// Class to handle both local files and network URLs for images
class ImageData {
  final File? file;
  final String? url;

  ImageData({this.file, this.url});
}

/// Class to represent items with descriptions and images
class ItemData {
  String description;
  ImageData imageData;

  ItemData({required this.description, required this.imageData});
}

class ExternalCabEditPage extends StatefulWidget {
  final String vehicleId;
  final VoidCallback? onContinue;
  final VoidCallback onProgressUpdate;
  final bool isEditing;

  const ExternalCabEditPage({
    Key? key,
    required this.vehicleId,
    this.onContinue,
    required this.onProgressUpdate,
    this.isEditing = false,
  }) : super(key: key);

  @override
  ExternalCabEditPageState createState() => ExternalCabEditPageState();
}

class ExternalCabEditPageState extends State<ExternalCabEditPage>
    with AutomaticKeepAliveClientMixin {
  String _selectedCondition = 'good'; // Default selected value
  String _anyDamagesType = 'no'; // Default selected value
  String _anyAdditionalFeaturesType =
      'no'; // Default selected value for additional features
  final ImagePicker _picker = ImagePicker(); // Image picker instance

  // Scroll controller for managing automatic scrolling
  final ScrollController _scrollController = ScrollController();

  // Map to store selected images for each view
  final Map<String, ImageData> _selectedImages = {
    'FRONT VIEW': ImageData(),
    'RIGHT SIDE VIEW': ImageData(),
    'REAR VIEW': ImageData(),
    'LEFT SIDE VIEW': ImageData(),
  };

  // List to store damage items
  List<ItemData> _damageList = [];

  // List to store additional feature items
  List<ItemData> _additionalFeaturesList = [];

  bool _isInitialized = false; // Flag to prevent re-initialization

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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String userRole = userProvider.getUserRole;
    final bool isDealer = userRole == 'dealer';

    return SingleChildScrollView(
      controller: _scrollController, // Attach the scroll controller
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
                enabled: !isDealer,
                groupValue: _selectedCondition,
                onChanged: _updateCondition,
              ),
              CustomRadioButton(
                label: 'Good',
                value: 'good',
                groupValue: _selectedCondition,
                enabled: !isDealer,
                onChanged: _updateCondition,
              ),
              CustomRadioButton(
                label: 'Excellent',
                value: 'excellent',
                groupValue: _selectedCondition,
                enabled: !isDealer,
                onChanged: _updateCondition,
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
            onChange: _updateDamagesType,
            buildItemSection: _buildDamageSection,
          ),
          const SizedBox(height: 16.0),
          const Divider(thickness: 1.0),
          const SizedBox(height: 16.0),
          // Additional Features Section
          _buildAdditionalSection(
            title: 'Are there any additional features on the cab',
            anyItemsType: _anyAdditionalFeaturesType,
            onChange: _updateAdditionalFeaturesType,
            buildItemSection: _buildAdditionalFeaturesSection,
          ),
        ],
      ),
    );
  }

  void initializeWithData(Map<String, dynamic> data) {
    print('initializeWithData called with data: $data');

    if (data.isEmpty) {
      print('Data is empty, returning from initializeWithData.');
      return;
    }

    setState(() {
      _selectedCondition = data['condition'] ?? 'good';
      _anyDamagesType = data['damagesCondition'] ?? 'no';
      _anyAdditionalFeaturesType = data['additionalFeaturesCondition'] ?? 'no';

      // Initialize images
      if (data['images'] != null) {
        Map<String, dynamic> images = Map<String, dynamic>.from(data['images']);
        images.forEach((key, value) {
          print('Initializing image for key $key with value: $value');
          if (value is Map && value.containsKey('url')) {
            String? imageUrl = value['url']?.toString();
            if (imageUrl == null || imageUrl.isEmpty) {
              print(
                  'URL for key $key is null or empty, setting imageUrl to null');
              imageUrl = null;
            } else {
              print('Setting image URL for $key: $imageUrl');
            }
            _selectedImages[key] = ImageData(file: null, url: imageUrl);
          } else {
            print(
                'Value for key $key is not a Map or does not contain "url" key.');
          }
        });
      } else {
        print('No "images" found in data.');
      }

      // Initialize damage list
      if (data['damages'] != null) {
        _damageList = (data['damages'] as List).map((damage) {
          print('Processing damage: $damage');
          String? imageUrl = damage['imageUrl']?.toString();
          if (imageUrl == null || imageUrl.isEmpty) {
            print('Image URL for damage is null or empty.');
            imageUrl = null;
          }
          return ItemData(
            description: damage['description'] ?? '',
            imageData: ImageData(file: null, url: imageUrl),
          );
        }).toList();
      } else {
        print('No "damages" found in data.');
      }

      // Initialize additional features list
      if (data['additionalFeatures'] != null) {
        _additionalFeaturesList =
            (data['additionalFeatures'] as List).map((feature) {
          print('Processing additional feature: $feature');
          String? imageUrl = feature['imageUrl']?.toString();
          if (imageUrl == null || imageUrl.isEmpty) {
            print('Image URL for feature is null or empty.');
            imageUrl = null;
          }
          return ItemData(
            description: feature['description'] ?? '',
            imageData: ImageData(file: null, url: imageUrl),
          );
        }).toList();
      } else {
        print('No "additionalFeatures" found in data.');
      }
    });
  }

  Widget _getImageWidget(ImageData? imageData, String title, bool isDealer) {
    if (imageData?.file != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.file(
          imageData!.file!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (imageData?.url != null && imageData!.url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          imageData.url!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.error_outline, color: Colors.red, size: 40),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        ),
      );
    } else {
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

  Future<bool> saveData() async {
    // This method can be left empty or used for additional save logic if needed
    return true;
  }

  Future<Map<String, dynamic>> getData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isTransporter = userProvider.getUserRole == 'transporter';

    if (!isTransporter) {
      return {};
    }

    Map<String, dynamic> serializedImages = {};
    for (var entry in _selectedImages.entries) {
      if (entry.value.file != null) {
        String imageUrl = await _uploadImageToFirebase(
            entry.value.file!, entry.key.replaceAll(' ', '_').toLowerCase());
        serializedImages[entry.key] = {'url': imageUrl, 'isNew': true};
      } else if (entry.value.url != null && entry.value.url!.isNotEmpty) {
        serializedImages[entry.key] = {
          'url': entry.value.url,
          'isNew': false,
        };
      }
    }

    List<Map<String, dynamic>> serializedDamages = [];
    for (var damage in _damageList) {
      if (damage.imageData.file != null) {
        String imageUrl =
            await _uploadImageToFirebase(damage.imageData.file!, 'damage');
        serializedDamages.add({
          'description': damage.description,
          'imageUrl': imageUrl,
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

    List<Map<String, dynamic>> serializedFeatures = [];
    for (var feature in _additionalFeaturesList) {
      if (feature.imageData.file != null) {
        String imageUrl =
            await _uploadImageToFirebase(feature.imageData.file!, 'feature');
        serializedFeatures.add({
          'description': feature.description,
          'imageUrl': imageUrl,
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
      'images': serializedImages,
      'damagesCondition': _anyDamagesType,
      'damages': serializedDamages,
      'additionalFeaturesCondition': _anyAdditionalFeaturesType,
      'additionalFeatures': serializedFeatures,
    };
  }

  // Method to reset the form fields
  void reset() {
    setState(() {
      _selectedCondition = 'good';
      _anyDamagesType = 'no';
      _anyAdditionalFeaturesType = 'no';
      _selectedImages.forEach((key, _) {
        _selectedImages[key] = ImageData();
      });
      _damageList.clear();
      _additionalFeaturesList.clear();
      _isInitialized = false; // Allow re-initialization if needed
    });
  }

  Future<String> _uploadImageToFirebase(File imageFile, String section) async {
    try {
      String fileName =
          'external_cab/${widget.vehicleId}_${section}_${DateTime.now().millisecondsSinceEpoch}.jpg';
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

    final imageData = _selectedImages[title];

    // Debugging statements
    print(
        'In _buildPhotoBlock for $title, hasFile: ${imageData?.file != null}, hasUrl: ${imageData?.url != null && imageData!.url!.isNotEmpty}, URL: ${imageData?.url}');

    return GestureDetector(
      onTap: () {
        if (imageData?.file != null ||
            (imageData?.url != null && imageData!.url!.isNotEmpty)) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                body: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Center(
                    child: imageData?.file != null
                        ? Image.file(imageData!.file!)
                        : Image.network(
                            imageData!.url!,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error_outline,
                                    color: Colors.red),
                          ),
                  ),
                ),
              ),
            ),
          );
        } else if (!isDealer) {
          _showImageSourceDialog(title);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.blue.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: AppColors.blue, width: 2.0),
        ),
        child: _getImageWidget(_selectedImages[title], title, isDealer),
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
                    setState(() {
                      _selectedImages[title] =
                          ImageData(file: File(pickedFile.path), url: null);
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
                      _selectedImages[title] =
                          ImageData(file: File(pickedFile.path), url: null);
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

  // Helper method to build the item section (Damage or Additional Features)
  Widget _buildItemSection({
    required List<ItemData> items,
    required VoidCallback addItem,
    required void Function(ItemData) showImageSourceDialog,
  }) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

    return Column(
      children: [
        ...items.asMap().entries.map((entry) {
          int index = entry.key;
          ItemData item = entry.value;
          return _buildItemWidget(index, item, showImageSourceDialog);
        }),
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

  // Helper method to create an item widget (Damage or Additional Features)
  Widget _buildItemWidget(
      int index, ItemData item, void Function(ItemData) showImageSourceDialog) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

    // Debugging statements
    print(
        'In _buildItemWidget for item ${item.description}, hasFile: ${item.imageData.file != null}, hasUrl: ${item.imageData.url != null && item.imageData.url!.isNotEmpty}, URL: ${item.imageData.url}');

    return Column(
      children: [
        const SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController(text: item.description),
                onChanged: (value) => _updateDamageDescription(index, value),
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
          onTap: () {
            if ((item.imageData.file != null) ||
                (item.imageData.url != null &&
                    item.imageData.url!.isNotEmpty)) {
              // View image
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    body: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Center(
                        child: item.imageData.file != null
                            ? Image.file(item.imageData.file!)
                            : Image.network(
                                item.imageData.url!,
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
              // For transporters - show image source dialog
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
            child: _getItemImageWidget(item.imageData, isDealer),
          ),
        ),
      ],
    );
  }

  Widget _getItemImageWidget(ImageData imageData, bool isDealer) {
    if (imageData.file != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.file(
          imageData.file!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (imageData.url != null && imageData.url!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          imageData.url!, // Uses the url field to load the image
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.error_outline, color: Colors.red);
          },
        ),
      );
    } else {
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
  }

  // Methods to show image source dialogs for different sections
  void _showDamageImageSourceDialog(ItemData damage) {
    _showImageSourceDialogForItem(damage);
  }

  void _showAdditionalFeatureImageSourceDialog(ItemData feature) {
    _showImageSourceDialogForItem(feature);
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
                    setState(() {
                      item.imageData =
                          ImageData(file: File(pickedFile.path), url: null);
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
                      item.imageData =
                          ImageData(file: File(pickedFile.path), url: null);
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

  double getCompletionPercentage() {
    int filledFields = 0;
    int totalFields = 7; // Total number of sections

    // Check condition selection
    if (_selectedCondition.isNotEmpty) filledFields++;

    // Check images
    _selectedImages.forEach((key, value) {
      if (value.file != null || (value.url != null && value.url!.isNotEmpty))
        filledFields++;
    });

    // Check damages section
    if (_anyDamagesType == 'no') {
      filledFields++; // Count as completed if no damages
    } else if (_anyDamagesType == 'yes' && _damageList.isNotEmpty) {
      bool isDamagesComplete = _damageList.every((damage) =>
          damage.description.isNotEmpty &&
          (damage.imageData.file != null ||
              (damage.imageData.url != null &&
                  damage.imageData.url!.isNotEmpty)));
      if (isDamagesComplete) filledFields++;
    }

    // Check additional features section
    if (_anyAdditionalFeaturesType == 'no') {
      filledFields++; // Count as completed if no additional features
    } else if (_anyAdditionalFeaturesType == 'yes' &&
        _additionalFeaturesList.isNotEmpty) {
      bool isFeaturesComplete = _additionalFeaturesList.every((feature) =>
          feature.description.isNotEmpty &&
          (feature.imageData.file != null ||
              (feature.imageData.url != null &&
                  feature.imageData.url!.isNotEmpty)));
      if (isFeaturesComplete) filledFields++;
    }

    // Calculate and return percentage
    return (filledFields / totalFields).clamp(0.0, 1.0);
  }

  void _updateAndNotify(VoidCallback updateFunction) {
    setState(() {
      updateFunction();
    });
    widget.onProgressUpdate();
  }

  void _updateCondition(String? value) {
    if (value != null) {
      _updateAndNotify(() {
        _selectedCondition = value;
      });
    }
  }

  void _updateDamagesType(String? value) {
    if (value != null) {
      _updateAndNotify(() {
        _anyDamagesType = value;
        if (_anyDamagesType == 'yes' && _damageList.isEmpty) {
          _damageList.add(ItemData(description: '', imageData: ImageData()));
        } else if (_anyDamagesType == 'no') {
          _damageList.clear();
        }
      });
    }
  }

  void _updateAdditionalFeaturesType(String? value) {
    if (value != null) {
      _updateAndNotify(() {
        _anyAdditionalFeaturesType = value;
        if (_anyAdditionalFeaturesType == 'yes' &&
            _additionalFeaturesList.isEmpty) {
          _additionalFeaturesList
              .add(ItemData(description: '', imageData: ImageData()));
        } else if (_anyAdditionalFeaturesType == 'no') {
          _additionalFeaturesList.clear();
        }
      });
    }
  }

  void _updateDamageDescription(int index, String value) {
    _updateAndNotify(() {
      if (index < _damageList.length) {
        _damageList[index].description = value;
      } else if (index < _additionalFeaturesList.length) {
        _additionalFeaturesList[index].description = value;
      }
    });
  }
}
