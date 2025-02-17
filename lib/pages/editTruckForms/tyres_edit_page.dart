// lib/pages/truckForms/tyres_edit_page.dart

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart';
import 'package:provider/provider.dart';
import 'package:ctp/utils/navigation.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ctp/components/truck_info_web_nav.dart';

class TyresEditPage extends StatefulWidget {
  final String vehicleId;
  final VoidCallback onProgressUpdate;
  final bool isEditing;
  final bool inTabsPage; // Defaults to false

  const TyresEditPage({
    super.key,
    required this.vehicleId,
    required this.onProgressUpdate,
    this.isEditing = false,
    this.inTabsPage = false,
  });

  @override
  TyresEditPageState createState() => TyresEditPageState();
}

class TyresEditPageState extends State<TyresEditPage>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Maps for each tyre position
  final Map<int, String> _chassisConditions = {};
  final Map<int, String> _virginOrRecaps = {};
  final Map<int, String> _rimTypes = {};

  // For storing image data in memory (when user picks an image)
  final Map<String, Uint8List?> _selectedImages = {};
  // For storing network image URLs from Firestore/Firebase Storage
  final Map<String, String> _imageUrls = {};

  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize maps for tyre positions 1 to 6.
    for (int i = 1; i <= 6; i++) {
      _chassisConditions[i] = '';
      _virginOrRecaps[i] = '';
      _rimTypes[i] = '';
    }
    // Unlike before, always load existing data (if any) so the saved image shows.
    if (!_isInitialized) {
      _fetchExistingData();
    }
  }

  /// Loads existing tyre data from Firestore.
  Future<void> _fetchExistingData() async {
    try {
      print(
          "DEBUG: Fetching existing tyre data for vehicle ${widget.vehicleId}");
      final doc =
          await _firestore.collection('vehicles').doc(widget.vehicleId).get();

      if (!doc.exists) {
        print('DEBUG: No document found for vehicle ${widget.vehicleId}');
        return;
      }

      final data = doc.data();
      if (data == null || !data.containsKey('truckConditions')) {
        print('DEBUG: No truckConditions data found');
        return;
      }

      final tyresData = data['truckConditions']?['tyres'];
      if (tyresData == null) {
        print('DEBUG: No tyres data found');
        return;
      }

      print('DEBUG: Found tyres data: $tyresData');
      // For each tyre position (1 to 6) load the saved data.
      for (int pos = 1; pos <= 6; pos++) {
        String posKey = 'Tyre_Pos_$pos';
        if (tyresData[posKey] != null) {
          Map<String, dynamic> posData =
              Map<String, dynamic>.from(tyresData[posKey]);
          _chassisConditions[pos] = posData['chassisCondition'] ?? '';
          _virginOrRecaps[pos] = posData['virginOrRecap'] ?? '';
          _rimTypes[pos] = posData['rimType'] ?? '';

          if (posData['imageUrl'] != null) {
            _imageUrls['$posKey Photo'] = posData['imageUrl'];
            print(
                "DEBUG: Tyre position $pos image URL loaded: ${posData['imageUrl']}");
          }
        }
      }
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print("DEBUG: Error fetching tyre data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tyre data: $e')),
      );
    }
  }

  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

    Widget content = Material(
      type: MaterialType.transparency,
      child: SingleChildScrollView(
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
              // Generate sections for tyre positions 1 through 6.
              ...List.generate(6, (index) => _buildTyrePosSection(index + 1)),
              const SizedBox(height: 16.0),
              const Divider(thickness: 1.0),
              const SizedBox(height: 16.0),
              CustomButton(
                text: 'Save Changes',
                borderColor: Colors.deepOrange,
                isLoading: _isSaving,
                onPressed: () async {
                  print("DEBUG: Save Changes button pressed");
                  setState(() => _isSaving = true);
                  try {
                    final data = await getData();
                    print("DEBUG: Data to be saved: $data");
                    await _firestore
                        .collection('vehicles')
                        .doc(widget.vehicleId)
                        .update({
                      'truckConditions.tyres': data,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Changes saved successfully!')),
                    );
                  } catch (e) {
                    print("DEBUG: Error during save: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error saving changes: $e')),
                    );
                  } finally {
                    setState(() => _isSaving = false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );

    // Wrap with GradientBackground if not in tabs mode.
    if (!widget.inTabsPage) {
      content = GradientBackground(child: content);
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: kIsWeb
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: TruckInfoWebNavBar(
                scaffoldKey: _scaffoldKey,
                selectedTab: "Tyres",
                vehicleId: widget.vehicleId,
                onHomePressed: () => Navigator.pushNamed(context, '/home'),
                onBasicInfoPressed: () =>
                    Navigator.pushNamed(context, '/basic_information'),
                onTruckConditionsPressed: () =>
                    Navigator.pushNamed(context, '/truck_conditions'),
                onMaintenanceWarrantyPressed: () =>
                    Navigator.pushNamed(context, '/maintenance_warranty'),
                onExternalCabPressed: () =>
                    Navigator.pushNamed(context, '/external_cab'),
                onInternalCabPressed: () =>
                    Navigator.pushNamed(context, '/internal_cab'),
                onChassisPressed: () =>
                    Navigator.pushNamed(context, '/chassis'),
                onDriveTrainPressed: () =>
                    Navigator.pushNamed(context, '/drive_train'),
                onTyresPressed: () => Navigator.pushNamed(context, '/tyres'),
              ),
            )
          : null,
      body: content,
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
                    print("DEBUG: Tyre $pos chassis condition set to $value");
                  });
                }
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
                  print("DEBUG: Tyre $pos chassis condition set to $value");
                }
                _updateAndNotify(() {});
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
                  print("DEBUG: Tyre $pos chassis condition set to $value");
                }
                _updateAndNotify(() {});
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
                  print("DEBUG: Tyre $pos virgin/recap set to $value");
                }
                _updateAndNotify(() {});
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
                  print("DEBUG: Tyre $pos virgin/recap set to $value");
                }
                _updateAndNotify(() {});
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
                  print("DEBUG: Tyre $pos rim type set to $value");
                }
                _updateAndNotify(() {});
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
                  print("DEBUG: Tyre $pos rim type set to $value");
                }
                _updateAndNotify(() {});
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
        print("DEBUG: Image upload block tapped for key: $key");
        // If an image exists, allow viewing it.
        if ((_selectedImages[key] != null ||
            (_imageUrls[key] != null && _imageUrls[key]!.isNotEmpty))) {
          print("DEBUG: Viewing image for key: $key");
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
                        : (_imageUrls[key] != null &&
                                _imageUrls[key]!.isNotEmpty)
                            ? Image.network(
                                _imageUrls[key]!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  print(
                                      "DEBUG: Error loading network image: $error");
                                  return const Icon(Icons.error_outline,
                                      color: Colors.red);
                                },
                              )
                            : const Center(child: Text('No image available')),
                  ),
                ),
              ),
            ),
          );
        }
        // Otherwise, if not a dealer, allow picking a new image.
        else if (!isDealer) {
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
                    child: (_imageUrls[key] == null || _imageUrls[key] == "")
                        ? const Center(child: Text("Invalid Image"))
                        : Image.network(
                            _imageUrls[key]!,
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
                // If not a dealer and an image exists, show a modify (X) button.
                if (!isDealer &&
                    (_selectedImages[key] != null ||
                        (_imageUrls[key] != null &&
                            _imageUrls[key]!.isNotEmpty)))
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        print("DEBUG: Removing image for key: $key");
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
        print("DEBUG: Showing image source dialog for key: $key");
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
                    print("DEBUG: Selected image from camera for key: $key");
                    _updateAndNotify(() {
                      _selectedImages[key] = bytes;
                      _imageUrls.remove(key);
                    });
                  } else {
                    print("DEBUG: No image selected from camera for key: $key");
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
                    print("DEBUG: Selected image from gallery for key: $key");
                    _updateAndNotify(() {
                      _selectedImages[key] = bytes;
                      _imageUrls.remove(key);
                    });
                  } else {
                    print(
                        "DEBUG: No image selected from gallery for key: $key");
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

  /// Uploads images (if any) and returns the full tyre data map.
  Future<Map<String, dynamic>> getData() async {
    Map<String, dynamic> allTyresData = {};

    for (int pos = 1; pos <= 6; pos++) {
      String posKey = 'Tyre_Pos_$pos';
      String photoKey = '$posKey Photo';

      print("DEBUG: Processing data for $posKey");

      Map<String, dynamic> tyreData = {
        'chassisCondition': _chassisConditions[pos] ?? '',
        'virginOrRecap': _virginOrRecaps[pos] ?? '',
        'rimType': _rimTypes[pos] ?? '',
      };

      // If a new image was selected, upload it.
      if (_selectedImages[photoKey] != null) {
        print("DEBUG: Uploading image for $photoKey");
        String imageUrl = await _uploadImageToFirebase(
          _selectedImages[photoKey]!,
          'position_$pos',
        );
        tyreData['imageUrl'] = imageUrl;
        print("DEBUG: Uploaded image URL for $photoKey: $imageUrl");
        setState(() {
          _imageUrls[photoKey] = imageUrl;
          _selectedImages.remove(photoKey);
        });
      } else if (_imageUrls[photoKey] != null &&
          _imageUrls[photoKey]!.isNotEmpty) {
        tyreData['imageUrl'] = _imageUrls[photoKey];
        print(
            "DEBUG: Using existing image URL for $photoKey: ${_imageUrls[photoKey]}");
      } else {
        print("DEBUG: No image found for $photoKey");
      }

      allTyresData[posKey] = tyreData;
    }

    print("DEBUG: Final tyre data: $allTyresData");
    return allTyresData;
  }

  /// Uploads an image file to Firebase Storage and returns its download URL.
  Future<String> _uploadImageToFirebase(
      Uint8List imageFile, String section) async {
    String fileName =
        'tyres/${widget.vehicleId}_${section}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    print("DEBUG: Preparing to upload image with fileName: $fileName");
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = storageRef.putData(imageFile);

    TaskSnapshot snapshot = await uploadTask;
    String downloadURL = await snapshot.ref.getDownloadURL();
    print("DEBUG: Image uploaded. Download URL: $downloadURL");
    return downloadURL;
  }

  /// Resets all fields and clears image data.
  void reset() {
    setState(() {
      for (int i = 1; i <= 6; i++) {
        _chassisConditions[i] = '';
        _virginOrRecaps[i] = '';
        _rimTypes[i] = '';
      }
      _selectedImages.clear();
      _imageUrls.clear();
      _isInitialized = false;
      print("DEBUG: Reset all fields and cleared images");
    });
  }

  double getCompletionPercentage() {
    int totalFields = 24; // 6 positions × (1 image + 3 selections) = 24 fields
    int filledFields = 0;

    for (int pos = 1; pos <= 6; pos++) {
      String photoKey = 'Tyre_Pos_$pos Photo';
      if (_selectedImages[photoKey] != null ||
          (_imageUrls[photoKey] != null && _imageUrls[photoKey]!.isNotEmpty)) {
        filledFields++;
      }
      if (_chassisConditions[pos]?.isNotEmpty == true) {
        filledFields++;
      }
      if (_virginOrRecaps[pos]?.isNotEmpty == true) {
        filledFields++;
      }
      if (_rimTypes[pos]?.isNotEmpty == true) {
        filledFields++;
      }
    }

    double completion = (filledFields / totalFields).clamp(0.0, 1.0);
    print("DEBUG: Completion percentage calculated as $completion");
    return completion;
  }

  /// A helper to update state and notify progress.
  void _updateAndNotify(VoidCallback updateFunction) {
    setState(() {
      updateFunction();
    });
    widget.onProgressUpdate();
  }
}
