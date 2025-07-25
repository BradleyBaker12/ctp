// lib/pages/truckForms/internal_cab_edit_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'package:ctp/components/truck_info_web_nav.dart';
// Added for platformViewRegistry
// For web camera access
import 'package:ctp/utils/camera_helper.dart'; // Added import for camera helper

/// Class to handle both local files and network URLs for images
class ImageData {
  final Uint8List? file;
  final String? url;
  final String? fileName;

  ImageData({this.file, this.url, this.fileName});
}

/// Class to represent items with descriptions and images
class ItemData {
  String description;
  ImageData imageData;

  ItemData({required this.description, required this.imageData});
}


@RoutePage()class InternalCabEditPage extends StatefulWidget {
  final String vehicleId;
  final VoidCallback onProgressUpdate;
  final bool isEditing;
  final bool inTabsPage; // Add this parameter

  const InternalCabEditPage({
    super.key,
    required this.vehicleId,
    required this.onProgressUpdate,
    this.isEditing = false,
    this.inTabsPage = false, // Default to false
  });

  @override
  InternalCabEditPageState createState() => InternalCabEditPageState();
}

class InternalCabEditPageState extends State<InternalCabEditPage>
    with AutomaticKeepAliveClientMixin {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
  final List<ItemData> _damageList = [];
  final List<ItemData> _additionalFeaturesList = [];
  final List<ItemData> _faultCodesList = [];

  bool _isInitialized = false; // Flag to prevent re-initialization
  bool _isSaving = false; // Flag to indicate saving state

  @override
  void initState() {
    super.initState();
    // Load data directly if not already initialized
    if (!_isInitialized) {
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    print('InternalCab: Loading existing data for vehicle ${widget.vehicleId}');
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .get();

      if (!doc.exists) {
        print('InternalCab: No document found for vehicle ${widget.vehicleId}');
        return;
      }

      final data = doc.data();
      if (data == null || data['truckConditions'] == null) {
        print('InternalCab: No truck conditions data found');
        return;
      }

      final internalCabData = data['truckConditions']['internalCab'];
      if (internalCabData == null) {
        print('InternalCab: No internal cab data found');
        return;
      }

      print('InternalCab: Found data to initialize with: $internalCabData');
      initializeWithData(internalCabData);
      _isInitialized = true;
    } catch (e) {
      print('InternalCab: Error loading existing data: $e');
    }
  }

  bool _isImageFile(String path) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    String extension = getFileExtension(path);
    print("File Extnnsion: $extension");
    return imageExtensions.contains(extension);
  }

  String getFileExtension(String url) {
    Uri uri = Uri.parse(url);
    String decodedPath = Uri.decodeFull(uri.path);
    String fileName = decodedPath.split('/').last;
    return fileName.contains('.') ? fileName.split('.').last : '';
  }

  String getFileNameFromUrl(String url) {
    // if (url.contains('maintenance_doc')) {
    //   return 'Maintenance Doc';
    // } else if (url.contains('warranty_doc')) {
    //   return 'Warranty Doc';
    // }
    // Fallback to original filename if pattern doesn't match
    Uri uri = Uri.parse(url);
    String decodedPath = Uri.decodeFull(uri.path);
    String fileName = decodedPath.split('/').last;

    return fileName;
  }

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
              // Condition Selection
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
                    enabled: !isDealer,
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
                    enabled: !isDealer,
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
              // Grid of Images (for keys containing Dash, Mileage, Visors, Console)
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
                      _damageList.add(
                          ItemData(description: '', imageData: ImageData()));
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
                      _additionalFeaturesList.add(
                          ItemData(description: '', imageData: ImageData()));
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
                      _faultCodesList.add(
                          ItemData(description: '', imageData: ImageData()));
                    } else if (_faultCodesCondition == 'no') {
                      _faultCodesList.clear();
                    }
                  });
                },
                buildItemSection: _buildFaultCodesSection,
              ),
              const SizedBox(height: 16.0),
              const Divider(thickness: 1.0),
              const SizedBox(height: 16.0),
              if (!isDealer)
                CustomButton(
                  text: 'Save Changes',
                  borderColor: Colors.deepOrange,
                  isLoading: _isSaving,
                  onPressed: () async {
                    setState(() => _isSaving = true);
                    try {
                      final data = await getData();
                      await _firestore
                          .collection('vehicles')
                          .doc(widget.vehicleId)
                          .update({
                        'truckConditions.internalCab': data,
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Changes saved successfully!')),
                      );
                    } catch (e) {
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

    // If not in tabs page, wrap with GradientBackground
    if (!widget.inTabsPage) {
      content = GradientBackground(child: content);
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: TruckInfoWebNavBar(
          scaffoldKey: _scaffoldKey,
          selectedTab: "Internal Cab",
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
          onChassisPressed: () => Navigator.pushNamed(context, '/chassis'),
          onDriveTrainPressed: () =>
              Navigator.pushNamed(context, '/drive_train'),
          onTyresPressed: () => Navigator.pushNamed(context, '/tyres'),
        ),
      ),
      body: content,
    );
  }

  // =============================================================================
  // MAIN PHOTO BLOCKS
  // =============================================================================
  Widget _buildPhotoBlock(String title) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

    bool hasFile = _selectedImages[title]?.file != null;
    bool hasUrl = _selectedImages[title]?.url != null &&
        _selectedImages[title]!.url!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (hasFile || hasUrl) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                body: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Center(
                    child: hasFile
                        ? Image.memory(_selectedImages[title]!.file!)
                        : Image.network(
                            _selectedImages[title]!.url!,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error_outline,
                                  color: Colors.red);
                            },
                            loadingBuilder: (context, url, _) => Container(
                              color: Colors.white,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
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
        child: Stack(
          children: [
            if (hasFile)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.memory(
                  _selectedImages[title]!.file!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              )
            else if (hasUrl)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  _selectedImages[title]!.url!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error_outline, color: Colors.red);
                  },
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!isDealer)
                      const Icon(Icons.add_circle_outline,
                          color: Colors.white, size: 40.0),
                    const SizedBox(height: 8.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            if (!isDealer && (hasFile || hasUrl))
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _selectedImages[title] = ImageData();
                    });
                    widget.onProgressUpdate();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =============================================================================
  // ITEM WIDGETS (Damages, Features, Fault Codes)
  // =============================================================================
  Widget _buildItemWidget(
    int index,
    ItemData item,
    void Function(ItemData) showImageSourceDialog,
  ) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

    return Column(
      children: [
        const SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                enabled: !isDealer,
                initialValue: item.description,
                onChanged: (value) {
                  _updateAndNotify(() {
                    item.description = value;
                  });
                },
                readOnly: isDealer,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                  labelText: 'Describe Item',
                  labelStyle: const TextStyle(color: Colors.white),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  hintTextDirection: TextDirection.ltr,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            if (!isDealer)
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
        GestureDetector(
          onTap: () {
            if (isDealer &&
                (item.imageData.file != null || item.imageData.url != null)) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    body: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Center(
                        child: item.imageData.file != null
                            ? Image.memory(item.imageData.file!)
                            : Image.network(
                                item.imageData.url!,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.error_outline,
                                      color: Colors.red);
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                      child: CircularProgressIndicator());
                                },
                              ),
                      ),
                    ),
                  ),
                ),
              );
            } else if (!isDealer) {
              showImageSourceDialog(item);
            }
          },
          child: AspectRatio(
            aspectRatio: 1.0, // Enforce a square block
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: AppColors.blue, width: 2.0),
              ),
              child: Stack(
                children: [
                  if (item.imageData.file == null &&
                      (item.imageData.url == null ||
                          !item.imageData.url!.startsWith('http')))
                    _buildImagePlaceholder()
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: item.imageData.file != null
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
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                    child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return _buildImagePlaceholder();
                              },
                            ),
                    ),
                  if (!isDealer &&
                      (item.imageData.file != null ||
                          item.imageData.url != null))
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            item.imageData = ImageData();
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Placeholder widget for item images
  Widget _buildImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Icon(Icons.add_circle_outline, color: Colors.white, size: 40.0),
          SizedBox(height: 8.0),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Clear Picture of Item',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
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

  // Dialog to pick image source for the main images
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
                  final imageBytes = await capturePhoto(context);
                  if (imageBytes != null) {
                    setState(() {
                      _selectedImages[title] = ImageData(file: imageBytes);
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
                    final bytes = await pickedFile.readAsBytes();
                    final fileName = pickedFile.name;
                    setState(() {
                      _selectedImages[title] =
                          ImageData(file: bytes, fileName: fileName);
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

  // Dialog to pick image source for item images
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
                  final imageBytes = await capturePhoto(context);
                  if (imageBytes != null) {
                    setState(() {
                      item.imageData = ImageData(file: imageBytes);
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

  // Specialized show methods for Damages/Features/Fault Codes
  void _showDamageImageSourceDialog(ItemData damage) {
    _showImageSourceDialogForItem(damage);
  }

  void _showAdditionalFeatureImageSourceDialog(ItemData feature) {
    _showImageSourceDialogForItem(feature);
  }

  void _showFaultCodesImageSourceDialog(ItemData faultCode) {
    _showImageSourceDialogForItem(faultCode);
  }

  // Build the additional sections (Damages, Additional Features, Fault Codes)
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
              enabled: !isDealer,
            ),
            const SizedBox(width: 15),
            CustomRadioButton(
              label: 'No',
              value: 'no',
              groupValue: anyItemsType,
              onChanged: onChange,
              enabled: !isDealer,
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        if (anyItemsType == 'yes') buildItemSection(),
      ],
    );
  }

  // Build the damages section using a grid view
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

  // Build the additional features section using a grid view
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

  // Build the fault codes section using a grid view
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

  // Generic method to build the item section (for damages, features, fault codes)
  // Displays items in a grid view with 2 columns on larger screens and 1 column on smaller screens.
  Widget _buildItemSection({
    required List<ItemData> items,
    required VoidCallback addItem,
    required void Function(ItemData) showImageSourceDialog,
  }) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                return _buildItemWidget(
                    index, items[index], showImageSourceDialog);
              },
            );
          },
        ),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // =============================================================================
  // Firebase & Data Methods
  // =============================================================================
  Future<String> _uploadImageToFirebase(
      Uint8List imageFile, String section) async {
    try {
      final fileName =
          'internal_cab/vehicleId_placeholder_${section}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child(fileName);
      final snapshot = await storageRef.putData(imageFile);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      // Handle error accordingly
    }
    return '';
  }

  Future<Map<String, dynamic>> getData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // Allow transporter, admin, and salesRep to upload data
    final allowedRoles = ['transporter', 'admin', 'salesRep'];
    if (!allowedRoles.contains(userProvider.getUserRole)) {
      return {};
    }

    // ...existing serialization code...
    // Serialize main images
    Map<String, dynamic> serializedImages = {};
    for (var entry in _selectedImages.entries) {
      if (entry.value.file != null) {
        String imageUrl = await _uploadImageToFirebase(
          entry.value.file!,
          entry.key.replaceAll(' ', '_').toLowerCase(),
        );
        serializedImages[entry.key] = {
          'url': imageUrl,
          'fileName': entry.value.fileName ??
              '${entry.key}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          'isNew': true,
        };
      } else if (entry.value.url != null) {
        serializedImages[entry.key] = {
          'url': entry.value.url,
          'fileName': entry.value.fileName,
          'isNew': false,
        };
      }
    }

    // Serialize damages
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
      } else if (damage.imageData.url != null) {
        serializedDamages.add({
          'description': damage.description,
          'imageUrl': damage.imageData.url,
          'isNew': false,
        });
      }
    }

    // Serialize additional features
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
      } else if (feature.imageData.url != null) {
        serializedFeatures.add({
          'description': feature.description,
          'imageUrl': feature.imageData.url,
          'isNew': false,
        });
      }
    }

    // Serialize fault codes
    List<Map<String, dynamic>> serializedFaultCodes = [];
    for (var faultCode in _faultCodesList) {
      if (faultCode.imageData.file != null) {
        String imageUrl = await _uploadImageToFirebase(
            faultCode.imageData.file!, 'fault_code');
        serializedFaultCodes.add({
          'description': faultCode.description,
          'imageUrl': imageUrl,
          'isNew': true,
        });
      } else if (faultCode.imageData.url != null) {
        serializedFaultCodes.add({
          'description': faultCode.description,
          'imageUrl': faultCode.imageData.url,
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
      'faultCodesCondition': _faultCodesCondition,
      'faultCodes': serializedFaultCodes,
    };
  }

  void initializeWithData(Map<String, dynamic> data) {
    print('InternalCab: Starting initialization with data: $data');
    if (data.isEmpty) return;

    setState(() {
      _selectedCondition = data['condition'] ?? 'good';
      _damagesCondition = data['damagesCondition'] ?? 'no';
      _additionalFeaturesCondition =
          data['additionalFeaturesCondition'] ?? 'no';
      _faultCodesCondition = data['faultCodesCondition'] ?? 'no';

      // Initialize images – check both 'images' and 'viewImages'
      Map<String, dynamic>? images = data['images'] as Map<String, dynamic>? ??
          data['viewImages'] as Map<String, dynamic>?;

      if (images != null) {
        print('InternalCab: Found images data: $images');
        images.forEach((key, value) {
          print('InternalCab: Processing image for $key: $value');
          if (value is Map) {
            String? url = value['url']?.toString();
            if (url != null && url.isNotEmpty) {
              print('InternalCab: Setting URL for $key: $url');
              _selectedImages[key] = ImageData(
                url: url,
                fileName: value['fileName']?.toString(),
              );
            }
          }
        });
      } else {
        print('InternalCab: No images data found');
      }

      // Initialize lists
      _initializeList('damages', data['damages'], _damageList);
      _initializeList(
          'features', data['additionalFeatures'], _additionalFeaturesList);
      _initializeList('faultCodes', data['faultCodes'], _faultCodesList);
    });

    _selectedImages.forEach((key, value) {
      print(
          'InternalCab: Final image state for $key: ${value.url != null ? "Has URL" : "No URL"}');
    });
    print('InternalCab: Initialization complete');
  }

  void _initializeList(String type, dynamic data, List<ItemData> list) {
    if (data != null) {
      list.clear();
      for (var item in data) {
        if (item['imageUrl'] != null) {
          list.add(ItemData(
            description: item['description'] ?? '',
            imageData: ImageData(url: item['imageUrl']),
          ));
        }
      }
      print('InternalCab: Initialized $type list with ${list.length} items');
    }
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

      _isInitialized = false;
    });
  }

  double getCompletionPercentage() {
    int totalFields = 18; // Total number of fields to fill
    int filledFields = 0;

    if (_selectedCondition.isNotEmpty) filledFields++;

    _selectedImages.forEach((key, value) {
      if (value.file != null || (value.url != null && value.url!.isNotEmpty)) {
        filledFields++;
      }
    });

    if (_damagesCondition == 'no') {
      filledFields++;
    } else if (_damagesCondition == 'yes' && _damageList.isNotEmpty) {
      bool isDamagesComplete = _damageList.every((damage) =>
          damage.description.isNotEmpty &&
          (damage.imageData.file != null ||
              (damage.imageData.url != null &&
                  damage.imageData.url!.isNotEmpty)));
      if (isDamagesComplete) filledFields++;
    }

    if (_additionalFeaturesCondition == 'no') {
      filledFields++;
    } else if (_additionalFeaturesCondition == 'yes' &&
        _additionalFeaturesList.isNotEmpty) {
      bool isFeaturesComplete = _additionalFeaturesList.every((feature) =>
          feature.description.isNotEmpty &&
          (feature.imageData.file != null ||
              (feature.imageData.url != null &&
                  feature.imageData.url!.isNotEmpty)));
      if (isFeaturesComplete) filledFields++;
    }

    if (_faultCodesCondition == 'no') {
      filledFields++;
    } else if (_faultCodesCondition == 'yes' && _faultCodesList.isNotEmpty) {
      bool isFaultCodesComplete = _faultCodesList.every((faultCode) =>
          faultCode.description.isNotEmpty &&
          (faultCode.imageData.file != null ||
              (faultCode.imageData.url != null &&
                  faultCode.imageData.url!.isNotEmpty)));
      if (isFaultCodesComplete) filledFields++;
    }

    return (filledFields / totalFields).clamp(0.0, 1.0);
  }

  void _updateAndNotify(VoidCallback updateFunction) {
    setState(() {
      updateFunction();
    });
    widget.onProgressUpdate();
  }

  @override
  bool get wantKeepAlive => true;

  // Add the web camera helper:
  // Future<void> _takePhotoFromWeb(
  //     void Function(Uint8List?, String) callback) async {
  //   if (!kIsWeb) {
  //     callback(null, '');
  //     return;
  //   }
  //   try {
  //     final mediaDevices = html.window.navigator.mediaDevices;
  //     if (mediaDevices == null) {
  //       callback(null, '');
  //       return;
  //     }
  //     final mediaStream = await mediaDevices.getUserMedia({'video': true});
  //     final videoElement = html.VideoElement()
  //       ..autoplay = true
  //       ..srcObject = mediaStream;
  //     await videoElement.onLoadedMetadata.first;
  //     String viewID = 'webcamEdit_${DateTime.now().millisecondsSinceEpoch}';
  //     // platformViewRegistry.registerViewFactory(
  //     //     viewID, (int viewId) => videoElement);
  //     await showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (BuildContext dialogContext) {
  //         return AlertDialog(
  //           title: const Text('Take Photo'),
  //           content: SizedBox(
  //             width: 300,
  //             height: 300,
  //             child: HtmlElementView(viewType: viewID),
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () {
  //                 final canvas = html.CanvasElement(
  //                   width: videoElement.videoWidth,
  //                   height: videoElement.videoHeight,
  //                 );
  //                 canvas.context2D.drawImage(videoElement, 0, 0);
  //                 final dataUrl = canvas.toDataUrl('image/png');
  //                 final base64Str = dataUrl.split(',').last;
  //                 final imageBytes = base64.decode(base64Str);
  //                 mediaStream.getTracks().forEach((track) => track.stop());
  //                 Navigator.of(dialogContext).pop();
  //                 callback(imageBytes, 'captured.png');
  //               },
  //               child: const Text('Capture'),
  //             ),
  //             TextButton(
  //               onPressed: () {
  //                 mediaStream.getTracks().forEach((track) => track.stop());
  //                 Navigator.of(dialogContext).pop();
  //                 callback(null, '');
  //               },
  //               child: const Text('Cancel'),
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //   } catch (e) {
  //     callback(null, '');
  //   }
  // }
}
