// lib/pages/truckForms/drive_train_page.dart

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui_web';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart';
import 'package:provider/provider.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ctp/components/truck_info_web_nav.dart';
import 'dart:ui' as ui; // Added for platformViewRegistry
import 'package:universal_html/html.dart' as html; // For web camera access

class DriveTrainEditPage extends StatefulWidget {
  final String vehicleId;
  final VoidCallback onProgressUpdate;
  final bool isEditing;
  final bool inTabsPage; // Add this parameter

  const DriveTrainEditPage({
    super.key,
    required this.vehicleId,
    required this.onProgressUpdate,
    this.isEditing = false,
    this.inTabsPage = false, // Default to false
  });

  @override
  DriveTrainEditPageState createState() => DriveTrainEditPageState();
}

class DriveTrainEditPageState extends State<DriveTrainEditPage>
    with AutomaticKeepAliveClientMixin {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage =
      FirebaseStorage.instance; // Firebase Storage instance
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _selectedCondition = 'good'; // Default selected value
  String _oilLeakConditionEngine = 'no';
  String _waterLeakConditionEngine = 'no';
  String _blowbyCondition = 'no';
  String _oilLeakConditionGearbox = 'no';
  String _retarderCondition = 'no';

  // Map to store selected images for different sections (local file bytes)
  final Map<String, Uint8List?> _selectedImages = {
    'Down': null,
    'Left': null,
    'Up': null,
    'Right': null,
    'Engine Left': null,
    'Engine Right': null,
    'Gearbox Top View': null,
    'Gearbox Bottom View': null,
    'Gearbox Rear Panel': null,
    'Diffs top view of front diff': null,
    'Diffs bottom view of diff front': null,
    'Diffs top view of rear diff': null,
    'Diffs bottom view of rear diff': null,
    'Engine Oil Leak': null,
    'Engine Water Leak': null,
    'Gearbox Oil Leak': null,
  };

  // Map to store image URLs (for previously uploaded images)
  final Map<String, String> _imageUrls = {};

  bool _isInitialized = false; // Flag to prevent re-initialization
  bool _isSaving = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load data directly if not already initialized
    if (!_isInitialized) {
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    print('DriveTrain: Loading existing data for vehicle ${widget.vehicleId}');
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .get();

      if (!doc.exists) {
        print('DriveTrain: No document found for vehicle ${widget.vehicleId}');
        return;
      }

      final data = doc.data();
      if (data == null || data['truckConditions'] == null) {
        print('DriveTrain: No truck conditions data found');
        return;
      }

      final driveTrainData = data['truckConditions']['driveTrain'];
      if (driveTrainData == null) {
        print('DriveTrain: No drive train data found');
        return;
      }

      print('DriveTrain: Found data to initialize with: $driveTrainData');
      initializeWithData(driveTrainData);
      _isInitialized = true;
    } catch (e) {
      print('DriveTrain: Error loading existing data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
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
                'Details for DRIVE TRAIN'.toUpperCase(),
                style: const TextStyle(
                  fontSize: 25,
                  color: Color.fromARGB(221, 255, 255, 255),
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Condition of the Drive Train',
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
                    onChanged: _updateCondition,
                    enabled: !isDealer,
                  ),
                  CustomRadioButton(
                    label: 'Good',
                    value: 'good',
                    groupValue: _selectedCondition,
                    onChanged: _updateCondition,
                    enabled: !isDealer,
                  ),
                  CustomRadioButton(
                    label: 'Excellent',
                    value: 'excellent',
                    groupValue: _selectedCondition,
                    onChanged: _updateCondition,
                    enabled: !isDealer,
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              const Divider(thickness: 1.0),
              const SizedBox(height: 16.0),
              // Photos Section
              Text(
                'Photos'.toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  color: Color.fromARGB(221, 255, 255, 255),
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              // Responsive Grid for Photos (Down, Left, Up, Right)
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;
                  final keys = _selectedImages.keys
                      .where((key) =>
                          key.contains('Left') ||
                          key.contains('Right') ||
                          key.contains('Down') ||
                          key.contains('Up'))
                      .toList();
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: keys.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                    ),
                    itemBuilder: (context, index) {
                      return _buildPhotoBlock(keys[index]);
                    },
                  );
                },
              ),
              const SizedBox(height: 16.0),
              const Divider(thickness: 1.0),
              const SizedBox(height: 16.0),
              // Engine Section
              Text(
                'Engine'.toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  color: Color.fromARGB(221, 255, 255, 255),
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              // Responsive Grid for Engine Photos (keys containing 'Engine' but not 'Leak')
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;
                  final keys = _selectedImages.keys
                      .where((key) =>
                          key.contains('Engine') && !key.contains('Leak'))
                      .toList();
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: keys.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                    ),
                    itemBuilder: (context, index) {
                      return _buildPhotoBlock(keys[index]);
                    },
                  );
                },
              ),
              const SizedBox(height: 16.0),
              // Engine Oil Leak Section
              _buildYesNoSection(
                title: 'Are there any oil leaks in the engine?',
                groupValue: _oilLeakConditionEngine,
                onChanged: _updateOilLeakCondition,
                imageKey: 'Engine Oil Leak',
              ),
              const SizedBox(height: 16.0),
              // Engine Water Leak Section
              _buildYesNoSection(
                title: 'Are there any water leaks in the engine?',
                groupValue: _waterLeakConditionEngine,
                onChanged: _updateWaterLeakCondition,
                imageKey: 'Engine Water Leak',
              ),
              const SizedBox(height: 16.0),
              // Blowby Condition Section (No Image)
              _buildYesNoRadioOnlySection(
                title: 'Is there blowby/engine breathing?',
                groupValue: _blowbyCondition,
                onChanged: _updateBlowbyCondition,
              ),
              const SizedBox(height: 16.0),
              const Divider(thickness: 1.0),
              const SizedBox(height: 16.0),
              // Gearbox Section
              Text(
                'Gearbox'.toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  color: Color.fromARGB(221, 255, 255, 255),
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              // Responsive Grid for Gearbox Photos (keys containing 'Gearbox' but not 'Leak')
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;
                  final keys = _selectedImages.keys
                      .where((key) =>
                          key.contains('Gearbox') && !key.contains('Leak'))
                      .toList();
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: keys.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                    ),
                    itemBuilder: (context, index) {
                      return _buildPhotoBlock(keys[index]);
                    },
                  );
                },
              ),
              const SizedBox(height: 16.0),
              // Gearbox Oil Leak Section
              _buildYesNoSection(
                title: 'Are there any oil leaks in the gearbox?',
                groupValue: _oilLeakConditionGearbox,
                onChanged: _updateGearboxOilLeakCondition,
                imageKey: 'Gearbox Oil Leak',
              ),
              const SizedBox(height: 16.0),
              // Retarder Condition Section (No Image)
              _buildYesNoRadioOnlySection(
                title: 'Does the gearbox come with a retarder?',
                groupValue: _retarderCondition,
                onChanged: _updateRetarderCondition,
              ),
              const SizedBox(height: 16.0),
              const Divider(thickness: 1.0),
              const SizedBox(height: 16.0),
              // Diffs Section
              Text(
                'Diffs (Differentials)'.toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  color: Color.fromARGB(221, 255, 255, 255),
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              // Responsive Grid for Diffs Photos (keys containing 'Diffs')
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;
                  final keys = _selectedImages.keys
                      .where((key) => key.contains('Diffs'))
                      .toList();
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: keys.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                    ),
                    itemBuilder: (context, index) {
                      return _buildPhotoBlock(keys[index]);
                    },
                  );
                },
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
                        'truckConditions.driveTrain': data,
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
      appBar: kIsWeb
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: TruckInfoWebNavBar(
                scaffoldKey: _scaffoldKey,
                selectedTab: "Drive Train",
                vehicleId: widget.vehicleId, // Add this line
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
      body: content, // your existing content
    );
  }

  // ===========================================================================
  // 1) MAIN PHOTO BLOCK WITH X BUTTON (Modified to be square)
  // ===========================================================================
  Widget _buildPhotoBlock(String title) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

    final hasLocalFile = _selectedImages[title] != null;
    final hasUrl = _imageUrls[title] != null && _imageUrls[title]!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        // If there's an image, allow viewing in full screen
        if (hasLocalFile || hasUrl) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                body: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Center(
                    child: hasLocalFile
                        ? Image.memory(_selectedImages[title]!)
                        : Image.network(_imageUrls[title]!),
                  ),
                ),
              ),
            ),
          );
        } else if (!isDealer) {
          // For transporters - pick image
          _showImageSourceDialog(title);
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
              // Existing image or placeholder
              _getImageWidget(title, isDealer),
              // The "X" button (only if not a dealer AND an image is present)
              if (!isDealer && (hasLocalFile || hasUrl))
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _selectedImages[title] = null;
                        _imageUrls[title] = '';
                      });
                      widget.onProgressUpdate();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Returns either a local file image, a network image, or a placeholder
  Widget _getImageWidget(String title, bool isDealer) {
    final file = _selectedImages[title];
    final url = _imageUrls[title];

    if (file != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.memory(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          url,
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
      );
    }
  }

  // ===========================================================================
  // 2) IMAGE SOURCE DIALOG
  // ===========================================================================
  void _showImageSourceDialog(String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Image Source for $title'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Updated Camera option:
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  if (kIsWeb) {
                    bool cameraAvailable = false;
                    try {
                      cameraAvailable =
                          html.window.navigator.mediaDevices != null;
                    } catch (e) {
                      cameraAvailable = false;
                    }
                    if (cameraAvailable) {
                      await _takePhotoFromWeb((file, fileName) {
                        if (file != null) {
                          setState(() {
                            _selectedImages[title] = file;
                            _imageUrls[title] = '';
                          });
                        }
                      });
                    } else {
                      final pickedFile =
                          await _picker.pickImage(source: ImageSource.camera);
                      if (pickedFile != null) {
                        final bytes = await pickedFile.readAsBytes();
                        setState(() {
                          _selectedImages[title] = bytes;
                          _imageUrls[title] = '';
                        });
                      }
                    }
                  } else {
                    final pickedFile =
                        await _picker.pickImage(source: ImageSource.camera);
                    if (pickedFile != null) {
                      final bytes = await pickedFile.readAsBytes();
                      setState(() {
                        _selectedImages[title] = bytes;
                        _imageUrls[title] = '';
                      });
                    }
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
                      _selectedImages[title] = bytes;
                      _imageUrls[title] = '';
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

  // Add web camera helper method:
  Future<void> _takePhotoFromWeb(
      void Function(Uint8List?, String) callback) async {
    if (!kIsWeb) {
      callback(null, '');
      return;
    }
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        callback(null, '');
        return;
      }
      final mediaStream = await mediaDevices.getUserMedia({'video': true});
      final videoElement = html.VideoElement()
        ..autoplay = true
        ..srcObject = mediaStream;
      await videoElement.onLoadedMetadata.first;
      String viewID =
          'webcam_drivetrain_edit_${DateTime.now().millisecondsSinceEpoch}';
      platformViewRegistry.registerViewFactory(
          viewID, (int viewId) => videoElement);
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Take Photo'),
            content: SizedBox(
              width: 300,
              height: 300,
              child: HtmlElementView(viewType: viewID),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  final canvas = html.CanvasElement(
                    width: videoElement.videoWidth,
                    height: videoElement.videoHeight,
                  );
                  canvas.context2D.drawImage(videoElement, 0, 0);
                  final dataUrl = canvas.toDataUrl('image/png');
                  final base64Str = dataUrl.split(',').last;
                  final imageBytes = base64.decode(base64Str);
                  mediaStream.getTracks().forEach((track) => track.stop());
                  Navigator.of(dialogContext).pop();
                  callback(imageBytes, 'captured.png');
                },
                child: const Text('Capture'),
              ),
              TextButton(
                onPressed: () {
                  mediaStream.getTracks().forEach((track) => track.stop());
                  Navigator.of(dialogContext).pop();
                  callback(null, '');
                },
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      callback(null, '');
    }
  }

  // ===========================================================================
  // 3) YES/NO SECTIONS (WITH/WITHOUT IMAGES)
  // ===========================================================================
  Widget _buildYesNoSection({
    required String title,
    required String groupValue,
    required ValueChanged<String?> onChanged,
    required String imageKey,
  }) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

    return Column(
      children: [
        Text(
          title,
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
              enabled: !isDealer,
            ),
            const SizedBox(width: 15),
            CustomRadioButton(
              label: 'No',
              value: 'no',
              groupValue: groupValue,
              onChanged: onChanged,
              enabled: !isDealer,
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        // If the user selects "Yes", allow uploading/viewing the leak photo
        if (groupValue == 'yes') _buildPhotoBlock(imageKey),
      ],
    );
  }

  // Same yes/no but without image upload (radio buttons only)
  Widget _buildYesNoRadioOnlySection({
    required String title,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

    return Column(
      children: [
        Text(
          title,
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
              enabled: !isDealer,
            ),
            const SizedBox(width: 15),
            CustomRadioButton(
              label: 'No',
              value: 'no',
              groupValue: groupValue,
              onChanged: onChanged,
              enabled: !isDealer,
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // 4) FIREBASE UPLOAD / DATA METHODS
  // ===========================================================================
  Future<Map<String, dynamic>> getData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // Allow transporter, admin, and salesRep to upload data
    final allowedRoles = ['transporter', 'admin', 'salesRep'];
    if (!allowedRoles.contains(userProvider.getUserRole)) {
      return {};
    }

    Map<String, dynamic> serializedImages = {};

    // Validate and sanitize images data
    for (var entry in _selectedImages.entries) {
      String? imageUrl;

      if (entry.value != null) {
        // Upload new image
        imageUrl = await _uploadImageToFirebase(
          entry.value!,
          entry.key.replaceAll(' ', '_').toLowerCase(),
        );
      } else if (_imageUrls[entry.key] != null &&
          _imageUrls[entry.key]!.isNotEmpty) {
        // Use existing URL
        imageUrl = _imageUrls[entry.key];
      }

      if (imageUrl != null && imageUrl.isNotEmpty) {
        serializedImages[entry.key] = {
          'url': imageUrl,
          'isNew': entry.value != null, // true if it's a new upload
        };
      }
    }

    // Create a sanitized data map
    Map<String, dynamic> data = {
      'condition': _selectedCondition,
      'engineOilLeak': _oilLeakConditionEngine,
      'engineWaterLeak': _waterLeakConditionEngine,
      'blowbyCondition': _blowbyCondition,
      'gearboxOilLeak': _oilLeakConditionGearbox,
      'retarderCondition': _retarderCondition,
    };

    if (serializedImages.isNotEmpty) {
      data['images'] = serializedImages;
    }

    return data;
  }

  Future<String> _uploadImageToFirebase(
      Uint8List imageFile, String section) async {
    try {
      final fileName =
          'drive_train/${widget.vehicleId}_${section}_${DateTime.now().millisecondsSinceEpoch}.jpg';
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

  Future<bool> saveData() async {
    // Implement save logic if needed
    return true;
  }

  void initializeWithData(Map<String, dynamic> data) {
    print('DriveTrain: Starting initialization with data: $data');
    if (data.isEmpty) return;

    setState(() {
      _selectedCondition = data['condition'] ?? 'good';
      _oilLeakConditionEngine = data['engineOilLeak'] ?? 'no';
      _waterLeakConditionEngine = data['engineWaterLeak'] ?? 'no';
      _blowbyCondition = data['blowbyCondition'] ?? 'no';
      _oilLeakConditionGearbox = data['gearboxOilLeak'] ?? 'no';
      _retarderCondition = data['retarderCondition'] ?? 'no';

      // Initialize images
      if (data['images'] != null) {
        final images = Map<String, dynamic>.from(data['images']);
        images.forEach((key, value) {
          print('DriveTrain: Processing image for $key: $value');
          if (value is Map && value.containsKey('url')) {
            final url = value['url']?.toString();
            if (url != null && url.isNotEmpty) {
              print('DriveTrain: Setting URL for $key: $url');
              _imageUrls[key] = url;
              _selectedImages[key] = null; // Clear any existing file data
            }
          }
        });
      }
    });

    _imageUrls.forEach((key, value) {
      print('DriveTrain: Final URL for $key: $value');
    });
    print('DriveTrain: Initialization complete');
  }

  void reset() {
    setState(() {
      _selectedCondition = 'good';
      _oilLeakConditionEngine = 'no';
      _waterLeakConditionEngine = 'no';
      _blowbyCondition = 'no';
      _oilLeakConditionGearbox = 'no';
      _retarderCondition = 'no';

      _selectedImages.forEach((key, _) {
        _selectedImages[key] = null;
      });

      _imageUrls.clear();

      _isInitialized = false; // Allow re-initialization if needed
    });
  }

  double getCompletionPercentage() {
    int totalFields = 19; // Total number of fields to fill
    int filledFields = 0;

    // 1) Condition
    if (_selectedCondition.isNotEmpty) filledFields++;

    // 2) Images (16 total possible)
    _selectedImages.forEach((key, value) {
      if (key.contains('Leak')) {
        // For "Leak" images, only count if the condition is "yes"
        if ((key == 'Engine Oil Leak' &&
                _oilLeakConditionEngine == 'yes' &&
                (value != null ||
                    (_imageUrls[key] != null &&
                        _imageUrls[key]!.isNotEmpty))) ||
            (key == 'Engine Water Leak' &&
                _waterLeakConditionEngine == 'yes' &&
                (value != null ||
                    (_imageUrls[key] != null &&
                        _imageUrls[key]!.isNotEmpty))) ||
            (key == 'Gearbox Oil Leak' &&
                _oilLeakConditionGearbox == 'yes' &&
                (value != null ||
                    (_imageUrls[key] != null &&
                        _imageUrls[key]!.isNotEmpty)))) {
          filledFields++;
        }
      } else {
        // Non-leak images always count if present
        if (value != null ||
            (_imageUrls[key] != null && _imageUrls[key]!.isNotEmpty)) {
          filledFields++;
        }
      }
    });

    // 3) Conditions for leaks, blowby, retarder (5 fields)
    if (_oilLeakConditionEngine == 'no' ||
        (_oilLeakConditionEngine == 'yes' &&
            (_selectedImages['Engine Oil Leak'] != null ||
                (_imageUrls['Engine Oil Leak'] != null &&
                    _imageUrls['Engine Oil Leak']!.isNotEmpty)))) {
      filledFields++;
    }

    if (_waterLeakConditionEngine == 'no' ||
        (_waterLeakConditionEngine == 'yes' &&
            (_selectedImages['Engine Water Leak'] != null ||
                (_imageUrls['Engine Water Leak'] != null &&
                    _imageUrls['Engine Water Leak']!.isNotEmpty)))) {
      filledFields++;
    }

    if (_blowbyCondition.isNotEmpty) filledFields++;

    if (_oilLeakConditionGearbox == 'no' ||
        (_oilLeakConditionGearbox == 'yes' &&
            (_selectedImages['Gearbox Oil Leak'] != null ||
                (_imageUrls['Gearbox Oil Leak'] != null &&
                    _imageUrls['Gearbox Oil Leak']!.isNotEmpty)))) {
      filledFields++;
    }

    if (_retarderCondition.isNotEmpty) filledFields++;

    return (filledFields / totalFields).clamp(0.0, 1.0);
  }

  // Utility method to update state and notify progress
  void _updateAndNotify(VoidCallback updateFunction) {
    setState(() {
      updateFunction();
    });
    widget.onProgressUpdate();
  }

  // Condition selection
  void _updateCondition(String? value) {
    if (value != null) {
      _updateAndNotify(() {
        _selectedCondition = value;
      });
    }
  }

  // Engine oil leak
  void _updateOilLeakCondition(String? value) {
    if (value != null) {
      _updateAndNotify(() {
        _oilLeakConditionEngine = value;
        if (value == 'no') {
          _selectedImages['Engine Oil Leak'] = null;
          _imageUrls['Engine Oil Leak'] = '';
        }
      });
    }
  }

  // Engine water leak
  void _updateWaterLeakCondition(String? value) {
    if (value != null) {
      _updateAndNotify(() {
        _waterLeakConditionEngine = value;
        if (value == 'no') {
          _selectedImages['Engine Water Leak'] = null;
          _imageUrls['Engine Water Leak'] = '';
        }
      });
    }
  }

  // Blowby condition
  void _updateBlowbyCondition(String? value) {
    if (value != null) {
      _updateAndNotify(() {
        _blowbyCondition = value;
      });
    }
  }

  // Gearbox oil leak
  void _updateGearboxOilLeakCondition(String? value) {
    if (value != null) {
      _updateAndNotify(() {
        _oilLeakConditionGearbox = value;
        if (value == 'no') {
          _selectedImages['Gearbox Oil Leak'] = null;
          _imageUrls['Gearbox Oil Leak'] = '';
        }
      });
    }
  }

  // Retarder condition
  void _updateRetarderCondition(String? value) {
    if (value != null) {
      _updateAndNotify(() {
        _retarderCondition = value;
      });
    }
  }

  // For image selection
  Future<void> _updateImage(String title, Uint8List imageFile) async {
    _updateAndNotify(() {
      _selectedImages[title] = imageFile;
      _imageUrls[title] = ''; // Clear any existing URL
    });
  }
}
