// lib/pages/truckForms/external_cab_page.dart

import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/truck_info_web_nav.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Image picker for uploading images
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart';
import 'package:provider/provider.dart'; // Ensure this import path is correct

// Added for platformViewRegistry
import 'package:ctp/utils/camera_helper.dart'; // Added camera helper import

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

class ExternalCabEditPage extends StatefulWidget {
  final String vehicleId;
  final VoidCallback? onContinue;
  final VoidCallback onProgressUpdate;
  final bool isEditing;
  final bool inTabsPage; // Add this parameter

  const ExternalCabEditPage({
    super.key,
    required this.vehicleId,
    this.onContinue,
    required this.onProgressUpdate,
    this.isEditing = false,
    this.inTabsPage = false, // Default to false
  });

  @override
  ExternalCabEditPageState createState() => ExternalCabEditPageState();
}

class ExternalCabEditPageState extends State<ExternalCabEditPage>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedCondition = 'good'; // Default selected value
  String _anyDamagesType = 'no'; // Default selected value
  String _anyAdditionalFeaturesType =
      'no'; // Default selected value for additional features
  final ImagePicker _picker = ImagePicker(); // Image picker instance
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
  bool _isSaving = false; // Flag to indicate saving state

  @override
  void dispose() {
    // Dispose the scroll controller to release resources
    _scrollController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load data directly if accessed as dealer
    if (!_isInitialized) {
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    print('ExternalCab: Loading existing data for vehicle ${widget.vehicleId}');
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .get();

      if (!doc.exists) {
        print('ExternalCab: No document found for vehicle ${widget.vehicleId}');
        return;
      }

      final data = doc.data();
      if (data == null || data['truckConditions'] == null) {
        print('ExternalCab: No truck conditions data found');
        return;
      }

      final externalCabData = data['truckConditions']['externalCab'];
      if (externalCabData == null) {
        print('ExternalCab: No external cab data found');
        return;
      }

      print('ExternalCab: Found data to initialize with: $externalCabData');
      initializeWithData(externalCabData);
      _isInitialized = true;
    } catch (e) {
      print('ExternalCab: Error loading existing data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String userRole = userProvider.getUserRole;
    final bool isDealer = userRole == 'dealer';

    Widget content = Material(
      type: MaterialType.transparency,
      child: SingleChildScrollView(
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
              childAspectRatio: 1.5, // This grid remains rectangular if desired
              children: _selectedImages.keys
                  .map((title) => _buildPhotoBlock(title))
                  .toList(),
            ),
            const SizedBox(height: 70.0),
            // Damage Section (using grid view)
            _buildAdditionalSection(
              title: 'Are there any damages on the cab',
              anyItemsType: _anyDamagesType,
              onChange: _updateDamagesType,
              buildItemSection: _buildDamageSection,
            ),
            const SizedBox(height: 16.0),
            const Divider(thickness: 1.0),
            const SizedBox(height: 16.0),
            // Additional Features Section (using grid view)
            _buildAdditionalSection(
              title: 'Are there any additional features on the cab',
              anyItemsType: _anyAdditionalFeaturesType,
              onChange: _updateAdditionalFeaturesType,
              buildItemSection: _buildAdditionalFeaturesSection,
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
                    await FirebaseFirestore.instance
                        .collection('vehicles')
                        .doc(widget.vehicleId)
                        .update({
                      'truckConditions.externalCab': data,
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
    );

    // Always wrap with GradientBackground
    content = GradientBackground(child: content);

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        // Always show the TruckInfoWebNavBar
        preferredSize: const Size.fromHeight(70),
        child: TruckInfoWebNavBar(
          scaffoldKey: _scaffoldKey,
          selectedTab: "External Cab",
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
      body: content, // your existing content
    );
  }

  void initializeWithData(Map<String, dynamic> data) {
    print('ExternalCab: Initializing with data: $data');
    if (data.isEmpty) return;

    setState(() {
      _selectedCondition = data['condition'] ?? 'good';
      _anyDamagesType = data['damagesCondition'] ?? 'no';
      _anyAdditionalFeaturesType = data['additionalFeaturesCondition'] ?? 'no';

      // Initialize images
      if (data['images'] != null) {
        final images = Map<String, dynamic>.from(data['images']);
        images.forEach((key, value) {
          print('ExternalCab: Processing image for $key');
          if (value is Map && value.containsKey('url')) {
            String? imageUrl = value['url']?.toString();
            if (imageUrl != null && imageUrl.isNotEmpty) {
              print('ExternalCab: Setting URL for $key: $imageUrl');
              _selectedImages[key] = ImageData(url: imageUrl);
            }
          }
        });
      }

      // Initialize damage list
      if (data['damages'] != null) {
        _damageList = (data['damages'] as List).map((damage) {
          return ItemData(
            description: damage['description'] ?? '',
            imageData: ImageData(url: damage['imageUrl']),
          );
        }).toList();
      }

      // Initialize additional features list
      if (data['additionalFeatures'] != null) {
        _additionalFeaturesList =
            (data['additionalFeatures'] as List).map((feature) {
          return ItemData(
            description: feature['description'] ?? '',
            imageData: ImageData(url: feature['imageUrl']),
          );
        }).toList();
      }
    });
    print('ExternalCab: Initialization complete');
  }

  Widget _getImageWidget(ImageData? imageData, String title, bool isDealer) {
    if (imageData?.file != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.memory(
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
      return Center(
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
      );
    }
  }

  Future<bool> saveData() async {
    // This method can be left empty or used for additional save logic if needed
    return true;
  }

  Future<Map<String, dynamic>> getData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // Allow transporter, admin, and salesRep to upload data
    final allowedRoles = ['transporter', 'admin', 'salesRep'];
    if (!allowedRoles.contains(userProvider.getUserRole)) {
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

  Future<String> _uploadImageToFirebase(
      Uint8List imageFile, String section) async {
    try {
      final fileName =
          'external_cab/vehicleId_placeholder_${section}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child(fileName);
      final snapshot = await storageRef.putData(imageFile);
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

  // Helper method to create a photo block (with an X/delete button)
  Widget _buildPhotoBlock(String title) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

    final imageData = _selectedImages[title];

    // Debugging statements
    // print(
    //     'In _buildPhotoBlock for $title, hasFile: ${imageData?.file != null}, hasUrl: ${imageData?.url != null && imageData!.url!.isNotEmpty}, URL: ${imageData?.url}');

    return GestureDetector(
      onTap: () {
        // If there's an image, allow viewing in full screen:
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
                        ? Image.memory(imageData!.file!)
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
        }
        // Otherwise, if transporter (not a dealer), show picking options
        else if (!isDealer) {
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
            // The existing image or placeholder
            _getImageWidget(imageData, title, isDealer),

            // Show "X" button only if it's not a dealer AND an image is present
            if (!isDealer &&
                (imageData?.file != null ||
                    (imageData?.url != null && imageData!.url!.isNotEmpty)))
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      // Remove the image by resetting it
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
                  final imageBytes = await capturePhoto(context);
                  if (imageBytes != null) {
                    setState(() {
                      _selectedImages[title] = ImageData(file: imageBytes);
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
                    setState(() {
                      _selectedImages[title] =
                          ImageData(file: bytes, fileName: fileName);
                    });
                  }
                  widget.onProgressUpdate();
                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper method to build the additional section (Damages, Additional Features, etc.)
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

  // Helper method to build the damage section using a grid view
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

  // Helper method to build the additional features section using a grid view
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

  // Generic helper method to build the item section (used for damages, additional features, fault code, etc.)
  // Items are displayed in a grid view with 2 columns on larger screens and 1 column on smaller screens.
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
            // Use one column for narrow screens and two columns for wider layouts.
            int crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                // Adjust childAspectRatio as needed based on your design.
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
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Helper method to create an item widget (Damage, Additional Features, etc.)
  // Each widget includes a text field and a square image upload block.
  Widget _buildItemWidget(
      int index, ItemData item, void Function(ItemData) showImageSourceDialog) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

    // Debugging statements
    // print(
    //     'In _buildItemWidget for item ${item.description}, hasFile: ${item.imageData.file != null}, hasUrl: ${item.imageData.url != null && item.imageData.url!.isNotEmpty}, URL: ${item.imageData.url}');

    return Column(
      children: [
        const SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                enabled: !isDealer,
                initialValue: item.description,
                // Updated onChanged callback to update the item's description
                onChanged: (value) {
                  setState(() {
                    item.description = value;
                  });
                  widget.onProgressUpdate();
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
              // View image in full screen.
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
                              ),
                      ),
                    ),
                  ),
                ),
              );
            } else if (!isDealer) {
              // For transporters – show image source dialog.
              showImageSourceDialog(item);
            }
          },
          // Square image block achieved by wrapping the container in an AspectRatio widget.
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: AppColors.blue, width: 2.0),
              ),
              child: Stack(
                children: [
                  _getItemImageWidget(item.imageData, isDealer),
                  if (!isDealer &&
                      (item.imageData.file != null ||
                          (item.imageData.url != null &&
                              item.imageData.url!.isNotEmpty)))
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

  Widget _getItemImageWidget(ImageData imageData, bool isDealer) {
    if (imageData.file != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.memory(
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
          imageData.url!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.error_outline, color: Colors.red);
          },
        ),
      );
    } else {
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
  }

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

  double getCompletionPercentage() {
    int totalFields = 7; // 3 conditions + 4 required images
    int filledFields = 0;

    // Debug logging
    debugPrint("\n=== External Cab Completion Check ===");

    // Check condition selections (3 fields)
    if (_selectedCondition.isNotEmpty) {
      filledFields++;
      debugPrint("Main condition filled: $_selectedCondition");
    }

    if (_anyDamagesType == 'no') {
      filledFields++;
      debugPrint("Damages condition filled: no damages");
    } else if (_anyDamagesType == 'yes' && _damageList.isNotEmpty) {
      bool isDamagesComplete = _damageList.every((damage) =>
          damage.description.isNotEmpty &&
          (damage.imageData.file != null ||
              (damage.imageData.url != null &&
                  damage.imageData.url!.isNotEmpty)));
      if (isDamagesComplete) {
        filledFields++;
        debugPrint("Damages condition filled: has complete damages");
      }
    }

    if (_anyAdditionalFeaturesType == 'no') {
      filledFields++;
      debugPrint("Additional features condition filled: no features");
    } else if (_anyAdditionalFeaturesType == 'yes' &&
        _additionalFeaturesList.isNotEmpty) {
      bool isFeaturesComplete = _additionalFeaturesList.every((feature) =>
          feature.description.isNotEmpty &&
          (feature.imageData.file != null ||
              (feature.imageData.url != null &&
                  feature.imageData.url!.isNotEmpty)));
      if (isFeaturesComplete) {
        filledFields++;
        debugPrint(
            "Additional features condition filled: has complete features");
      }
    }

    // Check required images (4 fields)
    _selectedImages.forEach((key, imageData) {
      bool hasImage = imageData.file != null ||
          (imageData.url != null && imageData.url!.isNotEmpty);
      if (hasImage) {
        filledFields++;
        debugPrint("Image filled for: $key");
      }
    });

    double percentage = (filledFields / totalFields).clamp(0.0, 1.0);
    debugPrint("Total fields filled: $filledFields out of $totalFields");
    debugPrint("Completion percentage: ${percentage * 100}%");
    debugPrint("=== End Completion Check ===\n");

    return percentage;
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
