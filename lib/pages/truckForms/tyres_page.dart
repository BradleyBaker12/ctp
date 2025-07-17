// lib/pages/truckForms/tyres_page.dart
import 'dart:io';
// Added for platformViewRegistry
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart';
// For web camera access
import 'package:ctp/utils/camera_helper.dart'; // Import camera helper
import 'package:auto_route/auto_route.dart';

class ImageData {
  File? file;
  Uint8List? webImage;
  String? url;

  ImageData({this.file, this.webImage, this.url});

  bool get hasImage =>
      file != null || webImage != null || (url != null && url!.isNotEmpty);
}
@RoutePage()class TyresPage extends StatefulWidget {
  final String vehicleId;
  final VoidCallback onProgressUpdate;
  final bool isEditing;
  final int numberOfTyrePositions;

  const TyresPage({
    super.key,
    required this.vehicleId,
    required this.onProgressUpdate,
    this.isEditing = false,
    required this.numberOfTyrePositions,
  });

  @override
  TyresPageState createState() => TyresPageState();
}

class TyresPageState extends State<TyresPage>
    with AutomaticKeepAliveClientMixin {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage =
      FirebaseStorage.instance; // Firebase Storage instance

  // Replace single state variables with maps to store values for each position
  final Map<int, String> _chassisConditions = {};
  final Map<int, String> _virginOrRecaps = {};
  final Map<int, String> _rimTypes = {};

  // Map to store selected image files
  final Map<String, ImageData> _selectedImages = {};

  bool _isInitialized = false; // Flag to prevent re-initialization
  bool _isSaving = false; // Flag to indicate saving state

  @override
  void initState() {
    super.initState();
    // Initialize maps without default values
    for (int i = 1; i <= widget.numberOfTyrePositions; i++) {
      _chassisConditions[i] = '';
      _virginOrRecaps[i] = '';
      _rimTypes[i] = '';
    }

    if (widget.isEditing) {
      _fetchExistingData();
    }
  }

  /// Fetch existing data from Firestore if in editing mode
  Future<void> _fetchExistingData() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('vehicles')
          .doc(widget.vehicleId)
          .collection('tyres')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Assuming one document per tyre position
        for (var doc in querySnapshot.docs) {
          String key = doc.id; // e.g., 'Tyre_Pos_1'
          if (key.startsWith('Tyre_Pos_')) {
            final pos = int.parse(key.split('_').last);
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            _chassisConditions[pos] = data['chassisCondition'] ?? '';
            _virginOrRecaps[pos] = data['virginOrRecap'] ?? '';
            _rimTypes[pos] = data['rimType'] ?? '';

            String photoKey = '$key Photo';

            // Handle image data
            if (data['imageUrl'] != null) {
              _selectedImages[photoKey] = ImageData(url: data['imageUrl']);
            }
          }
        }
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      // Handle errors appropriately
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching existing data: $e')),
      );
    }
  }

  @override
  bool get wantKeepAlive => true; // Implementing the required getter

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 16.0),
                Text(
                  'Tyres Inspection'.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 25,
                    color: Color.fromARGB(221, 255, 255, 255),
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                ...List.generate(widget.numberOfTyrePositions,
                    (index) => _buildTyrePosSection(index + 1)),
                const SizedBox(height: 16.0),
              ],
            ),
          ),
        ),
        if (_isSaving)
          Container(
            color: Colors.black54,
            child: Center(
              child: Image.asset(
                'lib/assets/Loading_Logo_CTP.gif',
                width: 100,
                height: 100,
              ),
            ),
          ),
      ],
    );
  }

  /// Builds each tyre position section dynamically
  Widget _buildTyrePosSection(int pos) {
    String tyrePosKey = 'Tyre_Pos_$pos';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),
        Center(
          child: Text(
            'Tyre Position $pos'.toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              color: Color.fromARGB(221, 255, 255, 255),
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16.0),
        _buildImageUploadBlock('Tyre_Pos_$pos Photo'),
        const SizedBox(height: 16.0),
        Center(
          child: const Text(
            'Condition of the Tyre',
            style: TextStyle(
              fontSize: 16,
              color: Color.fromARGB(221, 255, 255, 255),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CustomRadioButton(
              label: 'Poor',
              value: 'poor',
              groupValue: _chassisConditions[pos] ?? '',
              onChanged: (String? value) {
                if (value != null) {
                  _updateAndNotify(() {
                    _chassisConditions[pos] = value;
                  });
                  widget.onProgressUpdate();
                  setState(() {});
                }
              },
            ),
            CustomRadioButton(
              label: 'Good',
              value: 'good',
              groupValue: _chassisConditions[pos] ?? '',
              onChanged: (String? value) {
                if (value != null) {
                  _chassisConditions[pos] = value;
                  widget.onProgressUpdate();
                  setState(() {});
                }
              },
            ),
            CustomRadioButton(
              label: 'Excellent',
              value: 'excellent',
              groupValue: _chassisConditions[pos] ?? '',
              onChanged: (String? value) {
                if (value != null) {
                  _chassisConditions[pos] = value;
                  widget.onProgressUpdate();
                  setState(() {});
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        Center(
          child: const Text(
            'Virgin or Recap',
            style: TextStyle(
              fontSize: 16,
              color: Color.fromARGB(221, 255, 255, 255),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CustomRadioButton(
              label: 'Virgin',
              value: 'virgin',
              groupValue: _virginOrRecaps[pos] ?? '',
              onChanged: (String? value) {
                if (value != null) {
                  _virginOrRecaps[pos] = value;
                  widget.onProgressUpdate();
                  setState(() {});
                }
              },
            ),
            CustomRadioButton(
              label: 'Recap',
              value: 'recap',
              groupValue: _virginOrRecaps[pos] ?? '',
              onChanged: (String? value) {
                if (value != null) {
                  _virginOrRecaps[pos] = value;
                  widget.onProgressUpdate();
                  setState(() {});
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        Center(
          child: const Text(
            'Aluminium or Steel Rim',
            style: TextStyle(
              fontSize: 16,
              color: Color.fromARGB(221, 255, 255, 255),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CustomRadioButton(
              label: 'Aluminium',
              value: 'aluminium',
              groupValue: _rimTypes[pos] ?? '',
              onChanged: (String? value) {
                if (value != null) {
                  _rimTypes[pos] = value;
                  widget.onProgressUpdate();
                  setState(() {});
                }
              },
            ),
            CustomRadioButton(
              label: 'Steel',
              value: 'steel',
              groupValue: _rimTypes[pos] ?? '',
              onChanged: (String? value) {
                if (value != null) {
                  _rimTypes[pos] = value;
                  widget.onProgressUpdate();
                  setState(() {});
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        const Divider(thickness: 1.0),
      ],
    );
  }

  /// Builds the image upload block with preview and delete functionality
  Widget _buildImageUploadBlock(String key) {
    String title = key.replaceAll('_', ' ').replaceAll('Photo', 'Photo');

    return GestureDetector(
      onTap: () => _showImageSourceDialog(key),
      child: Stack(
        children: [
          Container(
            height: 150.0,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: AppColors.blue, width: 2.0),
            ),
            child: _buildImageDisplay(key, title),
          ),
          // Overlay hint for editing
          if (_selectedImages[key]?.hasImage == true)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Tap to modify image',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          // Delete button
          if (_selectedImages[key]?.hasImage == true)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImages.remove(key);
                  });
                  widget.onProgressUpdate();
                  setState(() {});
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Displays the appropriate image based on the current state
  Widget _buildImageDisplay(String key, String title) {
    final imageData = _selectedImages[key];

    if (imageData?.webImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.memory(
          imageData!.webImage!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (imageData?.file != null) {
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
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Text(
                'Failed to load image',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          },
        ),
      );
    } else {
      return Center(
        child: Column(
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
        ),
      );
    }
  }

  /// Shows a dialog to choose the image source (Camera or Gallery)
  void _showImageSourceDialog(String key) {
    String title = key.replaceAll('_', ' ').replaceAll('Photo', 'Photo');
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
                      _selectedImages[key] = ImageData(webImage: imageBytes);
                    });
                  }
                  widget.onProgressUpdate();
                },
              ),
              // Existing Gallery option:
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
                      _selectedImages[key] = ImageData(
                        file: File(pickedFile.path),
                        webImage: bytes,
                      );
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

  /// Validates and saves the data to Firestore
  Future<void> saveData() async {
    // Validate data before saving
    for (int pos = 1; pos <= widget.numberOfTyrePositions; pos++) {
      String photoKey = 'Tyre_Pos_$pos Photo';
      if ((_selectedImages[photoKey] == null &&
              _selectedImages[photoKey]?.url == null) ||
          (_chassisConditions[pos]?.isEmpty ?? true) ||
          (_virginOrRecaps[pos]?.isEmpty ?? true) ||
          (_rimTypes[pos]?.isEmpty ?? true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Please complete all fields for Tyre Position $pos')),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await getData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tyre data saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  /// Handles uploading images and saving data to Firestore
  Future<Map<String, dynamic>> getData() async {
    Map<String, dynamic> data = {};

    for (int pos = 1; pos <= widget.numberOfTyrePositions; pos++) {
      String posKey = 'Tyre_Pos_$pos';
      String photoKey = '$posKey Photo';

      String? imageUrl;
      final imageData = _selectedImages[photoKey];
      if (imageData != null) {
        if (imageData.webImage != null) {
          imageUrl = await _uploadWebImageToFirebase(
            imageData.webImage!,
            'position_$pos',
          );
        } else if (imageData.file != null) {
          imageUrl = await _uploadImageToFirebase(
            imageData.file!,
            'position_$pos',
          );
        }
      }

      Map<String, dynamic> tyreData = {
        'chassisCondition': _chassisConditions[pos] ?? '',
        'virginOrRecap': _virginOrRecaps[pos] ?? '',
        'rimType': _rimTypes[pos] ?? '',
        'imageUrl': imageUrl ?? imageData?.url ?? '',
      };

      await _firestore
          .collection('vehicles')
          .doc(widget.vehicleId)
          .collection('tyres')
          .doc(posKey)
          .set(tyreData);

      data[posKey] = tyreData;
    }

    return data;
  }

  /// Uploads an image file to Firebase Storage and returns the download URL
  Future<String> _uploadImageToFirebase(File imageFile, String section) async {
    String fileName =
        'tyres/${widget.vehicleId}_${section}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = storageRef.putFile(imageFile);

    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<String> _uploadWebImageToFirebase(
      Uint8List imageData, String section) async {
    try {
      String fileName =
          'tyres/${widget.vehicleId}_${section}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putData(imageData);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading web image: $e');
      return '';
    }
  }

  /// Resets all fields and clears images
  void reset() {
    setState(() {
      // Reset conditions to empty strings
      for (int i = 1; i <= widget.numberOfTyrePositions; i++) {
        _chassisConditions[i] = '';
        _virginOrRecaps[i] = '';
        _rimTypes[i] = '';
      }

      // Clear images
      _selectedImages.clear();

      _isInitialized = false;
    });
  }

  /// Calculates the completion percentage based on filled fields
  double getCompletionPercentage() {
    int totalFields = widget.numberOfTyrePositions * 4; // 4 fields per position
    int filledFields = 0;

    for (int pos = 1; pos <= widget.numberOfTyrePositions; pos++) {
      String photoKey = 'Tyre_Pos_$pos Photo';

      if (_selectedImages[photoKey]?.hasImage == true) filledFields++;
      if (_chassisConditions[pos]?.isNotEmpty == true) filledFields++;
      if (_virginOrRecaps[pos]?.isNotEmpty == true) filledFields++;
      if (_rimTypes[pos]?.isNotEmpty == true) filledFields++;
    }

    return (filledFields / totalFields).clamp(0.0, 1.0);
  }

  /// Updates the state and notifies the parent widget about progress
  void _updateAndNotify(VoidCallback updateFunction) {
    setState(() {
      updateFunction();
    });
    widget.onProgressUpdate();
  }

  /// Initializes the state with existing data (Called from external files)
  void initializeWithData(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    setState(() {
      data.forEach((key, value) {
        if (key.startsWith('Tyre_Pos_')) {
          final pos = int.parse(key.split('_').last);
          _chassisConditions[pos] = value['chassisCondition'] ?? 'good';
          _virginOrRecaps[pos] = value['virginOrRecap'] ?? 'virgin';
          _rimTypes[pos] = value['rimType'] ?? 'aluminium';

          String photoKey = '$key Photo';

          if (value['imageUrl'] != null) {
            _selectedImages[photoKey] = ImageData(url: value['imageUrl']);
          }
          if (value['imagePath'] != null) {
            _selectedImages[photoKey] =
                ImageData(file: File(value['imagePath']));
          }
        }
      });
    });
  }
}
