// lib/pages/truckForms/tyres_edit_page.dart

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/utils/navigation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class TyresEditPage extends StatefulWidget {
  final String vehicleId;
  final VoidCallback onProgressUpdate;
  final bool isEditing;

  const TyresEditPage({
    super.key,
    required this.vehicleId,
    required this.onProgressUpdate,
    this.isEditing = false,
  });

  @override
  TyresEditPageState createState() => TyresEditPageState();
}

class TyresEditPageState extends State<TyresEditPage>
    with AutomaticKeepAliveClientMixin {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage =
      FirebaseStorage.instance; // Firebase Storage instance

  // Replace single state variables with maps to store values for each position
  final Map<int, String> _chassisConditions = {};
  final Map<int, String> _virginOrRecaps = {};
  final Map<int, String> _rimTypes = {};

  // Map to store selected images for different tyre positions
  final Map<String, Uint8List?> _selectedImages = {};

  // Map to store image URLs
  final Map<String, String> _imageUrls = {};

  bool _isInitialized = false; // Flag to prevent re-initialization
  bool _isSaving = false; // Flag to indicate saving state

  @override
  void initState() {
    super.initState();
    // Initialize maps without default values
    for (int i = 1; i <= 6; i++) {
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
              _imageUrls[photoKey] = data['imageUrl'];
              print("ImageUrls: $_imageUrls");
            }
            // Note: imagePath is not typically stored; if needed, handle accordingly
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16.0),
            Text(
              'Details for TYRES'.toUpperCase(),
              style: const TextStyle(
                fontSize: 25,
                color: Color.fromARGB(221, 255, 255, 255),
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            // Generate Tyre Position Sections
            ...List.generate(6, (index) => _buildTyrePosSection(index + 1)),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  Widget _buildTyrePosSection(int pos) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';
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
        _buildImageUploadBlock('$tyrePosKey Photo'),
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
                }
                widget.onProgressUpdate();
                setState(() {});
              },
              enabled: !isDealer,
            ),
            CustomRadioButton(
              label: 'Good',
              value: 'good',
              groupValue: _chassisConditions[pos] ?? '',
              onChanged: (String? value) {
                if (value != null) {
                  _chassisConditions[pos] = value;
                }
                widget.onProgressUpdate();
                setState(() {});
              },
              enabled: !isDealer,
            ),
            CustomRadioButton(
              label: 'Excellent',
              value: 'excellent',
              groupValue: _chassisConditions[pos] ?? '',
              onChanged: (String? value) {
                if (value != null) {
                  _chassisConditions[pos] = value;
                }
                widget.onProgressUpdate();
                setState(() {});
              },
              enabled: !isDealer,
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
                }
                widget.onProgressUpdate();
                setState(() {});
              },
              enabled: !isDealer,
            ),
            CustomRadioButton(
              label: 'Recap',
              value: 'recap',
              groupValue: _virginOrRecaps[pos] ?? '',
              onChanged: (String? value) {
                if (value != null) {
                  _virginOrRecaps[pos] = value;
                }
                widget.onProgressUpdate();
                setState(() {});
              },
              enabled: !isDealer,
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
                }
                widget.onProgressUpdate();
                setState(() {});
              },
              enabled: !isDealer,
            ),
            CustomRadioButton(
              label: 'Steel',
              value: 'steel',
              groupValue: _rimTypes[pos] ?? '',
              onChanged: (String? value) {
                if (value != null) {
                  _rimTypes[pos] = value;
                }
                widget.onProgressUpdate();
                setState(() {});
              },
              enabled: !isDealer,
            ),
          ],
        ),
        const Divider(thickness: 1.0),
      ],
    );
  }

  Widget _buildImageUploadBlock(String key) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';
    String title = key.replaceAll('_', ' ').replaceAll('Photo', 'Photo');
    return GestureDetector(
      onTap: () async {
        if (isDealer &&
            (_selectedImages[key] != null || _imageUrls[key] != null)) {
          await MyNavigator.push(
              context,
              Scaffold(
                backgroundColor: Colors.black,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                body: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Center(
                    child: InteractiveViewer(
                      child: _selectedImages[key] != null
                          ? Image.memory(_selectedImages[key]!)
                          : Image.network(_imageUrls[key]!),
                    ),
                  ),
                ),
              ));
        } else if (!isDealer) {
          _showImageSourceDialog(key);
        }
      },
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
            child: Stack(
              children: [
                if (_selectedImages[key] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.memory(
                      _selectedImages[key]!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                else if (_imageUrls[key] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: _imageUrls[key] == null || _imageUrls[key] == ""
                        ? Center(child: Text("Invalid Image"))
                        : Image.network(
                            _imageUrls[key]!,
                            // "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSaNLiTGLsYuLJw2qP6ICVQWQJ3SSjuqQVsEQ&s",
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                  )
                else
                  Center(
                    child: Column(
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
                    ),
                  ),
                if (!isDealer &&
                    (_selectedImages[key] != null || _imageUrls[key] != null))
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
                if (!isDealer &&
                    (_selectedImages[key] != null || _imageUrls[key] != null))
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImages.remove(key);
                          _imageUrls.remove(key);
                        });
                        widget.onProgressUpdate();
                      },
                      child: Container(
                        decoration: const BoxDecoration(
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
          ),
        ],
      ),
    );
  }

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
                    _updateAndNotify(() {
                      _selectedImages[key] = bytes;
                      _imageUrls.remove(key); // Remove existing URL if any
                    });
                  }
                  widget.onProgressUpdate();
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
                    _updateAndNotify(() {
                      _selectedImages[key] = bytes;
                      _imageUrls.remove(key); // Remove existing URL if any
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
    for (int pos = 1; pos <= 6; pos++) {
      String photoKey = 'Tyre_Pos_$pos Photo';
      if ((_selectedImages[photoKey] == null && _imageUrls[photoKey] == null) ||
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isTransporter = userProvider.getUserRole == 'transporter';

    if (!isTransporter) {
      return {};
    }

    Map<String, dynamic> data = {};

    // Get data for each tyre position
    for (int pos = 1; pos <= 6; pos++) {
      String posKey = 'Tyre_Pos_$pos';
      String photoKey = '$posKey Photo';

      // Initialize tyre data
      data[posKey] = {
        'chassisCondition': _chassisConditions[pos] ?? '',
        'virginOrRecap': _virginOrRecaps[pos] ?? '',
        'rimType': _rimTypes[pos] ?? '',
      };

      // Handle image data
      if (_selectedImages[photoKey] != null) {
        String imageUrl = await _uploadImageToFirebase(
            _selectedImages[photoKey]!, 'position_$pos');
        data[posKey]['imageUrl'] = imageUrl;
      } else if (_imageUrls[photoKey] != null) {
        data[posKey]['imageUrl'] = _imageUrls[photoKey];
      }

      // Save to Firestore
      await _firestore
          .collection('vehicles')
          .doc(widget.vehicleId)
          .collection('tyres')
          .doc(posKey)
          .set(data[posKey]);
    }

    return data;
  }

  /// Uploads an image file to Firebase Storage and returns the download URL
  Future<String> _uploadImageToFirebase(
      Uint8List imageFile, String section) async {
    String fileName =
        'tyres/${widget.vehicleId}_${section}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = storageRef.putData(imageFile);

    // Optionally, you can monitor upload progress here

    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Resets all fields and clears images
  void reset() {
    setState(() {
      // Reset conditions to empty strings
      for (int i = 1; i <= 6; i++) {
        _chassisConditions[i] = '';
        _virginOrRecaps[i] = '';
        _rimTypes[i] = '';
      }

      // Clear images
      _selectedImages.clear();
      _imageUrls.clear();

      _isInitialized = false;
    });
  }

  /// Calculates the completion percentage based on filled fields
  double getCompletionPercentage() {
    int totalFields = 24; // 6 positions × (1 image + 3 selections) = 24 fields
    int filledFields = 0;

    // Check each tyre position (6 positions)
    for (int pos = 1; pos <= 6; pos++) {
      String photoKey = 'Tyre_Pos_$pos Photo';

      // Check image (1 field per position)
      if (_selectedImages[photoKey] != null || _imageUrls[photoKey] != null) {
        filledFields++;
      }

      // Check chassis condition (1 field per position)
      if (_chassisConditions[pos]?.isNotEmpty == true) {
        filledFields++;
      }

      // Check virgin/recap selection (1 field per position)
      if (_virginOrRecaps[pos]?.isNotEmpty == true) {
        filledFields++;
      }

      // Check rim type selection (1 field per position)
      if (_rimTypes[pos]?.isNotEmpty == true) {
        filledFields++;
      }
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
          // Handle image data
          if (value['imageUrl'] != null) {
            _imageUrls[photoKey] = value['imageUrl'];
            _selectedImages[photoKey] = value['imageUrl'];
          }
          if (value['imagePath'] != null) {
            _imageUrls[photoKey] = value['imagePath'];
            _selectedImages[photoKey] = value['imagePath'];
          }
          // if (value['imagePath'] != null) {
          // }
        }
      });
    });
  }
}
