// lib/pages/truckForms/external_cab_page.dart
import 'dart:io';
import 'package:ctp/utils/camera_helper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Image picker for uploading images
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart';
import 'package:universal_html/html.dart'
    as html; // Ensure this import path is correct
import 'package:auto_route/auto_route.dart';

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

@RoutePage()class ExternalCabPage extends StatefulWidget {
  final String vehicleId;
  final VoidCallback? onContinue;
  final VoidCallback onProgressUpdate;
  final bool isEditing;

  const ExternalCabPage({
    super.key,
    required this.vehicleId,
    this.onContinue,
    required this.onProgressUpdate,
    this.isEditing = false,
  });

  @override
  ExternalCabPageState createState() => ExternalCabPageState();
}

class ExternalCabPageState extends State<ExternalCabPage>
    with AutomaticKeepAliveClientMixin {
  String _selectedCondition = 'good'; // Default selected value
  String _anyDamagesType = 'no'; // Default selected value
  String _anyAdditionalFeaturesType = 'no'; // Default selected value
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

  // List to store damage images and descriptions
  List<ItemData> _damageList = [];

  // List to store additional feature images and descriptions
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
                groupValue: _selectedCondition,
                onChanged: _updateCondition,
              ),
              CustomRadioButton(
                label: 'Good',
                value: 'good',
                groupValue: _selectedCondition,
                onChanged: _updateCondition,
              ),
              CustomRadioButton(
                label: 'Excellent',
                value: 'excellent',
                groupValue: _selectedCondition,
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
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.5, // Adjust to control the shape of each block
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

  Future<Uint8List?> capturePhotoFromWeb() async {
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) return null;

      // Request the camera stream
      final mediaStream = await mediaDevices.getUserMedia({'video': true});
      final videoElement = html.VideoElement()
        ..autoplay = true
        ..srcObject = mediaStream;

      // Wait for video metadata to load
      await videoElement.onLoadedMetadata.first;

      // Create a unique view type for this capture
      String viewId = 'webcamView_${DateTime.now().millisecondsSinceEpoch}';
      // platformViewRegistry.registerViewFactory(
      //     viewId, (int viewId) => videoElement);

      Uint8List? capturedImage;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Take Photo'),
            content: SizedBox(
              width: 300,
              height: 300,
              child: HtmlElementView(viewType: viewId),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Capture the current frame
                  // final canvas = html.CanvasElement(
                  //   width: videoElement.videoWidth,
                  //   height: videoElement.videoHeight,
                  // );
                  // canvas.context2D.drawImage(videoElement, 0, 0);
                  // final dataUrl = canvas.toDataUrl('image/png');
                  // final base64Data = dataUrl.split(',')[1];
                  // capturedImage = base64.decode(base64Data);
                  // // Stop all tracks before closing
                  // mediaStream.getTracks().forEach((track) => track.stop());
                  // Navigator.of(dialogContext).pop();
                },
                child: const Text('Capture'),
              ),
              TextButton(
                onPressed: () {
                  // mediaStream.getTracks().forEach((track) => track.stop());
                  // Navigator.of(dialogContext).pop();
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
      return capturedImage;
    } catch (e) {
      print('Error capturing photo: $e');
      return null;
    }
  }

  @override
  void initializeWithData(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    setState(() {
      _selectedCondition = data['condition'] ?? 'good';
      _anyDamagesType = data['damagesCondition'] ?? 'no';
      _anyAdditionalFeaturesType = data['additionalFeaturesCondition'] ?? 'no';

      // Initialize images
      if (data['images'] != null) {
        Map<String, dynamic> images = Map<String, dynamic>.from(data['images']);
        images.forEach((key, value) {
          if (value is Map && value['path'] != null) {
            _selectedImages[key] =
                ImageData(file: File(value['path']).readAsBytesSync());
          }
        });
      }

      // Initialize damage list
      if (data['damages'] != null) {
        _damageList = (data['damages'] as List).map((damage) {
          return ItemData(
            description: damage['description'] ?? '',
            imageData: ImageData(
              file: damage['imagePath'] != null
                  ? File(damage['imagePath']).readAsBytesSync()
                  : null,
              url: damage['imageUrl'] ?? '',
            ),
          );
        }).toList();

        // Ensure at least one damage item if damages condition is yes
        if (_anyDamagesType == 'yes' && _damageList.isEmpty) {
          _damageList.add(ItemData(description: '', imageData: ImageData()));
        }
      }

      // Initialize additional features list
      if (data['additionalFeatures'] != null) {
        _additionalFeaturesList =
            (data['additionalFeatures'] as List).map((feature) {
          return ItemData(
            description: feature['description'] ?? '',
            imageData: ImageData(
              file: feature['imagePath'] != null
                  ? File(feature['imagePath']).readAsBytesSync()
                  : null,
              url: feature['imageUrl'] ?? '',
            ),
          );
        }).toList();

        // Ensure at least one feature item if additional features condition is yes
        if (_anyAdditionalFeaturesType == 'yes' &&
            _additionalFeaturesList.isEmpty) {
          _additionalFeaturesList
              .add(ItemData(description: '', imageData: ImageData()));
        }
      }
    });
  }

  @override
  Future<bool> saveData() async {
    // This method can be left empty or used for additional save logic if needed
    return true;
  }

  Future<String> _uploadImageToFirebase(
      Uint8List imageData, String section) async {
    try {
      String fileName =
          'external_cab/${widget.vehicleId}_${section}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putData(imageData);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return '';
    }
  }

  /// Returns a Map (JSON) containing all data from this page, including
  /// the newly uploaded images for main images, damages, and features.
  Future<Map<String, dynamic>> getData() async {
    Map<String, dynamic> serializedImages = {};
    for (var entry in _selectedImages.entries) {
      if (entry.value.file != null) {
        String imageUrl = await _uploadImageToFirebase(
            entry.value.file!, entry.key.replaceAll(' ', '_').toLowerCase());
        serializedImages[entry.key] = {'url': imageUrl, 'isNew': true};
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

  // Helper method to scroll to the bottom of the page
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  // Helper method to create a photo block with an "X" (delete) button
  Widget _buildPhotoBlock(String title) {
    final imageData = _selectedImages[title];

    return GestureDetector(
      onTap: () {
        if (imageData?.file != null ||
            (imageData?.url != null && imageData!.url!.isNotEmpty)) {
          // Show full screen preview
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                body: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Center(
                    child: imageData?.file != null
                        ? Image.memory(imageData!.file!)
                        : Image.network(imageData!.url!),
                  ),
                ),
              ),
            ),
          );
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
        // If no image, show the add icon and title. If there's an image, show a Stack with the image + X button.
        child: imageData?.file == null
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
            : Stack(
                children: [
                  // The image itself
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.memory(
                      imageData!.file!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  // The "X" button to remove the image
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // Prevent the parent gesture from triggering
                        // the onTap for picking a new image
                        // by stopping the event propagation
                        // and clearing the image instead.
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
  // Updated _showImageSourceDialog method:
  void _showImageSourceDialog(String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Image Source for $title'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Camera option using the shared helper:
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final imageBytes = await capturePhoto(context);
                  if (imageBytes != null) {
                    setState(() {
                      _selectedImages[title] =
                          ImageData(file: imageBytes, fileName: 'captured.png');
                    });
                  }
                  widget.onProgressUpdate();
                },
              ),
              // Gallery option remains unchanged:
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? pickedFile =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    final bytes = await pickedFile.readAsBytes();
                    setState(() {
                      _selectedImages[title] =
                          ImageData(file: bytes, fileName: pickedFile.name);
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
    return Column(
      children: [
        ...items.asMap().entries.map((entry) {
          int index = entry.key;
          ItemData item = entry.value;
          return _buildItemWidget(index, item, showImageSourceDialog);
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
                onChanged: (value) => _updateDamageDescription(index, value),
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

        // This container now shows the image in a Stack with an X button, if available
        GestureDetector(
          onTap: () async {
            final pickedFile =
                await _picker.pickImage(source: ImageSource.gallery);
            if (pickedFile != null) {
              final bytes = await pickedFile.readAsBytes();
              setState(() {
                item.imageData = ImageData(file: bytes);
              });
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
            child: item.imageData.file == null
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
                : Stack(
                    children: [
                      // Display the image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.memory(
                          item.imageData.file!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      // "X" button to remove the image
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

  // Method to show dialog for selecting image source for damages
  void _showDamageImageSourceDialog(ItemData damage) {
    _showImageSourceDialogForItem(damage);
  }

  // Method to show dialog for selecting image source for additional features
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
                    final bytes = await pickedFile.readAsBytes();
                    setState(() {
                      item.imageData = ImageData(file: bytes);
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
                    setState(() {
                      item.imageData = ImageData(file: bytes);
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
    int totalFields = 7; // Total number of sections (adjust as needed)

    // Check condition selection
    if (_selectedCondition.isNotEmpty) filledFields++;

    // Check images (FRONT, RIGHT SIDE, REAR, LEFT SIDE)
    _selectedImages.forEach((key, value) {
      if (value.file != null) filledFields++;
    });

    // Check damages section
    if (_anyDamagesType == 'no') {
      // Count as completed if no damages
      filledFields++;
    } else if (_anyDamagesType == 'yes' && _damageList.isNotEmpty) {
      bool isDamagesComplete = _damageList.every((damage) =>
          damage.description.isNotEmpty && damage.imageData.file != null);
      if (isDamagesComplete) filledFields++;
    }

    // Check additional features section
    if (_anyAdditionalFeaturesType == 'no') {
      filledFields++;
    } else if (_anyAdditionalFeaturesType == 'yes' &&
        _additionalFeaturesList.isNotEmpty) {
      bool isFeaturesComplete = _additionalFeaturesList.every((feature) =>
          feature.description.isNotEmpty && feature.imageData.file != null);
      if (isFeaturesComplete) filledFields++;
    }

    return filledFields / totalFields;
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

  Future<void> _updateImage(String title, Uint8List imageFile) async {
    _updateAndNotify(() {
      _selectedImages[title] = ImageData(file: imageFile);
    });
  }

  void _updateDamageDescription(int index, String value) {
    _updateAndNotify(() {
      _damageList[index].description = value;
    });
  }

  Future<void> _updateDamageImage(int index, Uint8List imageFile) async {
    _updateAndNotify(() {
      _damageList[index].imageData = ImageData(file: imageFile);
    });
  }
}
