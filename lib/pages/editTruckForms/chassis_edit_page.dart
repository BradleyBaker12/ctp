import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/utils/camera_helper.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_radio_button.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:ctp/components/truck_info_web_nav.dart';

import 'package:auto_route/auto_route.dart';

@RoutePage()
class ChassisEditPage extends StatefulWidget {
  final String vehicleId;
  final VoidCallback onProgressUpdate;
  final bool isEditing;
  final bool inTabsPage; // For deciding if we wrap in GradientBackground

  const ChassisEditPage({
    super.key,
    required this.vehicleId,
    required this.onProgressUpdate,
    this.isEditing = false,
    this.inTabsPage = false,
  });

  @override
  ChassisEditPageState createState() => ChassisEditPageState();
}

class ChassisEditPageState extends State<ChassisEditPage>
    with AutomaticKeepAliveClientMixin {
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Condition radio buttons
  String _selectedCondition = 'good';
  String _damagesCondition = 'no';
  String _additionalFeaturesCondition = 'no';

  // Maps to store main images (key => raw bytes or existing URL).
  final Map<String, Uint8List?> _selectedImages = {
    'Right Brake': null,
    'Left Brake': null,
    'Front Axel': null,
    'Suspension': null,
    'Fuel Tank': null,
    'Fuel Tank 2': null,
    'Battery': null,
    'Battery Cover': null,
    'Battery Cover 2': null,
    'Cat Walk': null,
    'Electrical Cable Black': null,
    'Tail Board': null,
    '5th Wheel': null,
    'Left Brake Rear Axel': null,
    'Right Brake Rear Axel': null,
  };

  // Keep track of any existing URLs for these images
  final Map<String, String> _imageUrls = {};

  // Damages and additional features stored as a list of Maps
  List<Map<String, dynamic>> _damageList = [];
  List<Map<String, dynamic>> _additionalFeaturesList = [];

  bool _isInitialized = false;
  bool _isSaving = false;

  // Removed unused upload state fields; auto-save is silent

  // Fuel tanks count (1 or 2), default to 1 for legacy vehicles
  int _fuelTanksCount = 1;
  // Battery covers count (1 or 2), default to 1 for legacy vehicles
  int _batteryCoversCount = 1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!_isInitialized) {
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    try {
      final doc =
          await _firestore.collection('vehicles').doc(widget.vehicleId).get();

      final data = doc.data();
      if (data == null || data['truckConditions'] == null) return;

      final chassisData = data['truckConditions']['chassis'];
      if (chassisData == null) return;

      initializeWithData(chassisData);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Chassis: Error loading existing data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

    // Main content
    Widget content = Material(
      type: MaterialType.transparency,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16.0),
            // Main heading (mirroring ExternalCab style)
            Text(
              'Details for CHASSIS'.toUpperCase(),
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
                  onChanged: isDealer
                      ? (_) {}
                      : (value) => _updateAndNotify(() {
                            _selectedCondition = value!;
                          }),
                ),
                CustomRadioButton(
                  label: 'Good',
                  value: 'good',
                  groupValue: _selectedCondition,
                  onChanged: isDealer
                      ? (_) {}
                      : (value) => _updateAndNotify(() {
                            _selectedCondition = value!;
                          }),
                ),
                CustomRadioButton(
                  label: 'Excellent',
                  value: 'excellent',
                  groupValue: _selectedCondition,
                  onChanged: isDealer
                      ? (_) {}
                      : (value) => _updateAndNotify(() {
                            _selectedCondition = value!;
                          }),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            const Divider(thickness: 1.0),
            const SizedBox(height: 16.0),

            // --- FRONT AXLE SECTION ---
            Text(
              'FRONT AXLE'.toUpperCase(),
              style: const TextStyle(
                fontSize: 25,
                color: Color.fromARGB(221, 255, 255, 255),
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            _buildPhotoGrid([
              'Right Brake',
              'Left Brake',
              'Front Axel',
              'Suspension',
            ]),
            const SizedBox(height: 70.0),

            // --- CENTER OF CHASSIS SECTION ---
            Text(
              'CENTER OF CHASSIS'.toUpperCase(),
              style: const TextStyle(
                fontSize: 25,
                color: Color.fromARGB(221, 255, 255, 255),
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            // Fuel tanks count selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomRadioButton(
                  label: '1 Fuel Tank',
                  value: '1',
                  groupValue: _fuelTanksCount.toString(),
                  onChanged: isDealer
                      ? (_) {}
                      : (val) {
                          _updateAndNotify(() {
                            _fuelTanksCount = 1;
                            // Clear optional second tank locally
                            _selectedImages['Fuel Tank 2'] = null;
                            _imageUrls['Fuel Tank 2'] = '';
                          });
                          // Persist count and remove image from Firestore if present
                          _setChassisData({'fuelTanksCount': _fuelTanksCount});
                          _removeImageForView('Fuel Tank 2');
                        },
                ),
                const SizedBox(width: 15),
                CustomRadioButton(
                  label: '2 Fuel Tanks',
                  value: '2',
                  groupValue: _fuelTanksCount.toString(),
                  onChanged: isDealer
                      ? (_) {}
                      : (val) {
                          _updateAndNotify(() {
                            _fuelTanksCount = 2;
                          });
                          _setChassisData({'fuelTanksCount': _fuelTanksCount});
                        },
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            // Battery covers count selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomRadioButton(
                  label: '1 Battery Cover',
                  value: '1',
                  groupValue: _batteryCoversCount.toString(),
                  onChanged: isDealer
                      ? (_) {}
                      : (val) {
                          _updateAndNotify(() {
                            _batteryCoversCount = 1;
                            _selectedImages['Battery 2'] = null;
                            _imageUrls['Battery 2'] = '';
                          });
                          _setChassisData(
                              {'batteryCoversCount': _batteryCoversCount});
                          _removeImageForView('Battery 2');
                        },
                ),
                const SizedBox(width: 15),
                CustomRadioButton(
                  label: '2 Battery Covers',
                  value: '2',
                  groupValue: _batteryCoversCount.toString(),
                  onChanged: isDealer
                      ? (_) {}
                      : (val) {
                          _updateAndNotify(() {
                            _batteryCoversCount = 2;
                          });
                          _setChassisData(
                              {'batteryCoversCount': _batteryCoversCount});
                        },
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            Builder(
              builder: (context) {
                final titles = <String>['Fuel Tank'];
                if (_fuelTanksCount == 2) titles.add('Fuel Tank 2');
                titles.add('Battery');
                titles.add('Battery Cover');
                if (_batteryCoversCount == 2) titles.add('Battery Cover 2');
                titles.addAll([
                  'Cat Walk',
                  'Electrical Cable Black',
                ]);
                return _buildPhotoGrid(titles);
              },
            ),
            const SizedBox(height: 70.0),

            // --- REAR AXLE SECTION ---
            Text(
              'REAR AXLE'.toUpperCase(),
              style: const TextStyle(
                fontSize: 25,
                color: Color.fromARGB(221, 255, 255, 255),
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            _buildPhotoGrid([
              'Tail Board',
              '5th Wheel',
              'Left Brake Rear Axel',
              'Right Brake Rear Axel',
            ]),
            const SizedBox(height: 70.0),

            // --- Damages Section ---
            _buildAdditionalSection(
              title: 'Are there any damages?',
              anyItemsType: _damagesCondition,
              onChange: isDealer
                  ? null
                  : (val) => _updateAndNotify(() {
                        _damagesCondition = val!;
                        if (_damagesCondition == 'yes' && _damageList.isEmpty) {
                          _damageList.add({
                            'description': '',
                            'image': null,
                            'imageUrl': '',
                            'key': UniqueKey().toString(),
                          });
                        } else if (_damagesCondition == 'no') {
                          _damageList.clear();
                        }
                      }),
              buildItemSection: _buildDamageSection,
            ),
            const SizedBox(height: 16.0),
            const Divider(thickness: 1.0),
            const SizedBox(height: 16.0),

            // --- Additional Features Section ---
            _buildAdditionalSection(
              title: 'Are there any additional features?',
              anyItemsType: _additionalFeaturesCondition,
              onChange: isDealer
                  ? null
                  : (val) => _updateAndNotify(() {
                        _additionalFeaturesCondition = val!;
                        if (_additionalFeaturesCondition == 'yes' &&
                            _additionalFeaturesList.isEmpty) {
                          _additionalFeaturesList.add({
                            'description': '',
                            'image': null,
                            'imageUrl': '',
                            'key': UniqueKey().toString(),
                          });
                        } else if (_additionalFeaturesCondition == 'no') {
                          _additionalFeaturesList.clear();
                        }
                      }),
              buildItemSection: _buildAdditionalFeaturesSection,
            ),
            const SizedBox(height: 16.0),
            const Divider(thickness: 1.0),
            const SizedBox(height: 16.0),

            // Save Changes Button (only if not dealer)
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
                      'truckConditions.chassis': data,
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

    // If this page is not in a tab, wrap in GradientBackground
    if (!widget.inTabsPage) {
      content = GradientBackground(child: content);
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: TruckInfoWebNavBar(
          scaffoldKey: _scaffoldKey,
          selectedTab: "Chassis",
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

  // =======================
  // IMAGE GRID FOR MAIN IMAGES (Similar to ExternalCab)
  // =======================
  Widget _buildPhotoGrid(List<String> titles) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      childAspectRatio: 1.5,
      children:
          titles.map((title) => _buildPhotoBlock(title, isDealer)).toList(),
    );
  }

  Widget _buildPhotoBlock(String title, bool isDealer) {
    bool hasFile = _selectedImages[title] != null;
    bool hasUrl = _imageUrls[title] != null && _imageUrls[title]!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        // If there's an existing image, show full screen
        if (hasFile || hasUrl) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                body: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Center(
                    child: hasFile
                        ? Image.memory(_selectedImages[title]!)
                        : Image.network(
                            _imageUrls[title]!,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                              );
                            },
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
          // If no image yet and user is allowed to upload
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
            if (hasFile || hasUrl)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: hasFile
                    ? Image.memory(
                        _selectedImages[title]!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Image.network(
                        _imageUrls[title]!,
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
                          return const Icon(Icons.error_outline,
                              color: Colors.red);
                        },
                      ),
              )
            else
              // Placeholder
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                  onPressed: () async {
                    await _removeImageForView(title);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =======================
  // ADDITIONAL SECTIONS (Damages & Additional Features)
  // =======================
  Widget _buildAdditionalSection({
    required String title,
    required String anyItemsType,
    required ValueChanged<String?>? onChange,
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
        // Radio buttons "Yes" or "No"
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomRadioButton(
              label: 'Yes',
              value: 'yes',
              groupValue: anyItemsType,
              onChanged: onChange ?? (_) {},
              enabled: !isDealer,
            ),
            const SizedBox(width: 15),
            CustomRadioButton(
              label: 'No',
              value: 'no',
              groupValue: anyItemsType,
              onChanged: onChange ?? (_) {},
              enabled: !isDealer,
            ),
          ],
        ),
        const SizedBox(height: 16.0),
        if (anyItemsType == 'yes') buildItemSection(),
      ],
    );
  }

  Widget _buildDamageSection() {
    return _buildItemSection(
      items: _damageList,
      addItem: () {
        _updateAndNotify(() {
          _damageList.add({
            'description': '',
            'image': null,
            'imageUrl': '',
            'key': UniqueKey().toString(),
          });
        });
      },
      showImageSourceDialog: _showDamageImageSourceDialog,
    );
  }

  Widget _buildAdditionalFeaturesSection() {
    return _buildItemSection(
      items: _additionalFeaturesList,
      addItem: () {
        _updateAndNotify(() {
          _additionalFeaturesList.add({
            'description': '',
            'image': null,
            'imageUrl': '',
            'key': UniqueKey().toString(),
          });
        });
      },
      showImageSourceDialog: _showAdditionalFeatureImageSourceDialog,
    );
  }

  // Generic builder for item sections
  Widget _buildItemSection({
    required List<Map<String, dynamic>> items,
    required VoidCallback addItem,
    required void Function(Map<String, dynamic>) showImageSourceDialog,
  }) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.8, // A bit taller to fit text + image
          children: List.generate(items.length, (index) {
            return _buildItemWidget(
                index, items[index], showImageSourceDialog, items);
          }),
        ),
        const SizedBox(height: 35.0),
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

  Widget _buildItemWidget(
    int index,
    Map<String, dynamic> item,
    void Function(Map<String, dynamic>) showImageSourceDialog,
    List<Map<String, dynamic>> list,
  ) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isDealer = userProvider.getUserRole == 'dealer';

    bool hasFile = item['image'] != null;
    bool hasUrl =
        item['imageUrl'] != null && (item['imageUrl'] as String).isNotEmpty;

    return Column(
      children: [
        const SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: TextEditingController(text: item['description'])
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: (item['description'] ?? '').length),
                  ),
                onChanged: (value) {
                  _updateAndNotify(() {
                    item['description'] = value;
                  });
                },
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
                  _updateAndNotify(() {
                    list.removeAt(index);
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 16.0),
        GestureDetector(
          onTap: () {
            if (hasFile || hasUrl) {
              // View in fullscreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    body: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Center(
                        child: hasFile
                            ? Image.memory(item['image'])
                            : Image.network(
                                item['imageUrl'],
                                errorBuilder: (ctx, error, stack) {
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
              showImageSourceDialog(item);
            }
          },
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
                  if (hasFile)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.memory(
                        item['image'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  else if (hasUrl)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        item['imageUrl'],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (ctx, error, stackTrace) {
                          return const Icon(Icons.error_outline,
                              color: Colors.red);
                        },
                      ),
                    )
                  else
                    // Placeholder
                    const Center(
                      child: Column(
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
                            textAlign: TextAlign.center,
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
                            item['image'] = null;
                            item['imageUrl'] = '';
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

  // =======================
  // IMAGE SOURCE DIALOG HELPERS
  // =======================
  void _showImageSourceDialog(String title) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Choose Image Source for $title'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final imageBytes = await capturePhoto(context);
                  if (imageBytes != null) {
                    await _autoSaveImageForView(title, imageBytes);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final pickedFile =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    final bytes = await pickedFile.readAsBytes();
                    await _autoSaveImageForView(title, bytes);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImageSourceDialogForItem(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final imageBytes = await capturePhoto(context);
                  if (imageBytes != null) {
                    _updateAndNotify(() {
                      item['image'] = imageBytes;
                      item['imageUrl'] = '';
                    });
                    await _autoSaveForItem(item);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final pickedFile =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    final bytes = await pickedFile.readAsBytes();
                    _updateAndNotify(() {
                      item['image'] = bytes;
                      item['imageUrl'] = '';
                    });
                    await _autoSaveForItem(item);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDamageImageSourceDialog(Map<String, dynamic> damage) {
    _showImageSourceDialogForItem(damage);
  }

  void _showAdditionalFeatureImageSourceDialog(Map<String, dynamic> feature) {
    _showImageSourceDialogForItem(feature);
  }

  // =======================
  // DATA SAVE/UPLOAD
  // =======================
  Future<Map<String, dynamic>> getData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // Only these roles can upload
    final allowedRoles = ['transporter', 'oem', 'admin', 'salesRep'];
    if (!allowedRoles.contains(userProvider.getUserRole)) {
      return {};
    }

    // Upload main images
    final Map<String, dynamic> serializedImages = {};
    for (var entry in _selectedImages.entries) {
      final title = entry.key;
      final bytes = entry.value;
      if (bytes != null) {
        final url = await _uploadImageToFirebase(
          bytes,
          title.replaceAll(' ', '_').toLowerCase(),
        );
        serializedImages[title] = {
          'url': url,
          'isNew': true,
        };
      } else if (_imageUrls[title] != null && _imageUrls[title]!.isNotEmpty) {
        serializedImages[title] = {
          'url': _imageUrls[title],
          'isNew': false,
        };
      }
    }

    // Upload damages
    final List<Map<String, dynamic>> serializedDamages = [];
    for (var damage in _damageList) {
      final imageBytes = damage['image'] as Uint8List?;
      if (imageBytes != null) {
        final url = await _uploadImageToFirebase(imageBytes, 'damage');
        serializedDamages.add({
          'description': damage['description'] ?? '',
          'imageUrl': url,
          'isNew': true,
        });
      } else if (damage['imageUrl'] != null &&
          (damage['imageUrl'] as String).isNotEmpty) {
        serializedDamages.add({
          'description': damage['description'] ?? '',
          'imageUrl': damage['imageUrl'],
          'isNew': false,
        });
      }
    }

    // Upload additional features
    final List<Map<String, dynamic>> serializedFeatures = [];
    for (var feature in _additionalFeaturesList) {
      final imageBytes = feature['image'] as Uint8List?;
      if (imageBytes != null) {
        final url = await _uploadImageToFirebase(imageBytes, 'feature');
        serializedFeatures.add({
          'description': feature['description'] ?? '',
          'imageUrl': url,
          'isNew': true,
        });
      } else if (feature['imageUrl'] != null &&
          (feature['imageUrl'] as String).isNotEmpty) {
        serializedFeatures.add({
          'description': feature['description'] ?? '',
          'imageUrl': feature['imageUrl'],
          'isNew': false,
        });
      }
    }

    return {
      'condition': _selectedCondition,
      'fuelTanksCount': _fuelTanksCount,
      'batteryCoversCount': _batteryCoversCount,
      'images': serializedImages,
      'damagesCondition': _damagesCondition,
      'damages': serializedDamages,
      'additionalFeaturesCondition': _additionalFeaturesCondition,
      'additionalFeatures': serializedFeatures,
    };
  }

  Future<String> _uploadImageToFirebase(
      Uint8List imageFile, String section) async {
    try {
      final fileName =
          'chassis/${widget.vehicleId}_${section}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = _storage.ref().child(fileName);
      final snapshot = await storageRef.putData(imageFile);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload error: $e');
      return '';
    }
  }

  String _sanitizeSection(String input) =>
      input.toLowerCase().replaceAll(RegExp(r'\s+'), '_');

  Future<void> _setChassisData(Map<String, dynamic> data) async {
    await _firestore.collection('vehicles').doc(widget.vehicleId).set(
      {
        'truckConditions': {'chassis': data}
      },
      SetOptions(merge: true),
    );
  }

  Future<void> _autoSaveImageForView(String title, Uint8List bytes) async {
    setState(() {
      _selectedImages[title] = bytes;
      _imageUrls[title] = '';
    });
    try {
      final url = await _uploadImageToFirebase(bytes, _sanitizeSection(title));
      if (url.isEmpty) return;
      setState(() {
        _selectedImages[title] = null;
        _imageUrls[title] = url;
      });
      await _setChassisData({
        'images': {
          title: {'url': url}
        }
      });
      widget.onProgressUpdate();
    } catch (e) {
      debugPrint('Auto-save failed: $e');
    }
  }

  Future<void> _removeImageForView(String title) async {
    setState(() {
      _selectedImages[title] = null;
      _imageUrls[title] = '';
    });
    try {
      await _firestore.collection('vehicles').doc(widget.vehicleId).set(
        {
          'truckConditions': {
            'chassis': {
              'images': {title: FieldValue.delete()},
            }
          }
        },
        SetOptions(merge: true),
      );
      widget.onProgressUpdate();
    } catch (e) {
      debugPrint('Failed to remove image for $title: $e');
    }
  }

  Future<void> _autoSaveForItem(Map<String, dynamic> item) async {
    final imageBytes = item['image'] as Uint8List?;
    if (imageBytes == null) return;
    try {
      final section = _damageList.contains(item)
          ? 'damage'
          : _additionalFeaturesList.contains(item)
              ? 'feature'
              : 'item';
      final url = await _uploadImageToFirebase(imageBytes, section);
      if (url.isEmpty) return;
      setState(() {
        item['image'] = null;
        item['imageUrl'] = url;
      });
      if (_damageList.contains(item)) {
        await _syncDamagesListToFirestore();
      } else if (_additionalFeaturesList.contains(item)) {
        await _syncFeaturesListToFirestore();
      }
    } catch (e) {
      debugPrint('Auto-save failed: $e');
    }
  }

  Future<void> _syncDamagesListToFirestore() async {
    final serializedDamages = _damageList
        .map((d) => {
              'description': (d['description'] ?? '').toString(),
              'imageUrl': (d['imageUrl'] ?? '').toString(),
            })
        .toList();
    await _setChassisData({
      'damagesCondition': _damagesCondition,
      'damages': serializedDamages,
    });
  }

  Future<void> _syncFeaturesListToFirestore() async {
    final serializedFeatures = _additionalFeaturesList
        .map((f) => {
              'description': (f['description'] ?? '').toString(),
              'imageUrl': (f['imageUrl'] ?? '').toString(),
            })
        .toList();
    await _setChassisData({
      'additionalFeaturesCondition': _additionalFeaturesCondition,
      'additionalFeatures': serializedFeatures,
    });
  }

  // =======================
  // INITIALIZATION & HELPERS
  // =======================
  void initializeWithData(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    setState(() {
      _selectedCondition = data['condition'] ?? 'good';
      _fuelTanksCount =
          (data['fuelTanksCount'] is int) ? (data['fuelTanksCount'] as int) : 1;
      _batteryCoversCount = (data['batteryCoversCount'] is int)
          ? (data['batteryCoversCount'] as int)
          : 1;
      _damagesCondition = data['damagesCondition'] ?? 'no';
      _additionalFeaturesCondition =
          data['additionalFeaturesCondition'] ?? 'no';

      // Initialize main images
      if (data['images'] != null) {
        final images = Map<String, dynamic>.from(data['images']);
        images.forEach((key, value) {
          if (value is Map && value.containsKey('url')) {
            final url = value['url']?.toString();
            if (url != null && url.isNotEmpty) {
              _imageUrls[key] = url;
              _selectedImages[key] = null;
            }
          } else if (value is String) {
            final url = value.toString();
            if (url.isNotEmpty) {
              _imageUrls[key] = url;
              _selectedImages[key] = null;
            }
          }
        });
        // Infer tanks count for legacy entries if not set
        if (data['fuelTanksCount'] == null) {
          final second = images['Fuel Tank 2'];
          final hasSecond = second != null &&
              ((second is Map &&
                      ((second['url'] ?? '').toString().isNotEmpty)) ||
                  (second is String && second.isNotEmpty));
          _fuelTanksCount = hasSecond ? 2 : 1;
        }
        // Infer battery covers count for legacy entries if not set
        if (data['batteryCoversCount'] == null) {
          final secondBatt = images['Battery 2'];
          final hasSecondBatt = secondBatt != null &&
              ((secondBatt is Map &&
                      ((secondBatt['url'] ?? '').toString().isNotEmpty)) ||
                  (secondBatt is String && secondBatt.isNotEmpty));
          _batteryCoversCount = hasSecondBatt ? 2 : 1;
        }
      }

      // Initialize damages
      if (data['damages'] != null) {
        _damageList = (data['damages'] as List).map((damage) {
          return {
            'description': damage['description'] ?? '',
            'image': null,
            'imageUrl': damage['imageUrl'] ?? '',
            'key': UniqueKey().toString(),
          };
        }).toList();
      }

      // Initialize additional features
      if (data['additionalFeatures'] != null) {
        _additionalFeaturesList =
            (data['additionalFeatures'] as List).map((feature) {
          return {
            'description': feature['description'] ?? '',
            'image': null,
            'imageUrl': feature['imageUrl'] ?? '',
            'key': UniqueKey().toString(),
          };
        }).toList();
      }
    });
  }

  void reset() {
    setState(() {
      _selectedCondition = 'good';
      _damagesCondition = 'no';
      _additionalFeaturesCondition = 'no';

      _selectedImages.forEach((key, _) {
        _selectedImages[key] = null;
      });
      _imageUrls.clear();

      _damageList.clear();
      _additionalFeaturesList.clear();

      _isInitialized = false;
    });
  }

  double getCompletionPercentage() {
    int baseTotal = 15; // 1 condition + 12 images + 2 sections
    int totalFields = baseTotal +
        (_fuelTanksCount == 2 ? 1 : 0) +
        (_batteryCoversCount == 2 ? 1 : 0);
    int filledFields = 0;

    if (_selectedCondition.isNotEmpty) filledFields++;

    _selectedImages.forEach((key, bytes) {
      if (bytes != null ||
          (_imageUrls[key] != null && _imageUrls[key]!.isNotEmpty)) {
        filledFields++;
      }
    });

    if (_damagesCondition == 'no') {
      filledFields++;
    } else if (_damagesCondition == 'yes' && _damageList.isNotEmpty) {
      final isDamagesComplete = _damageList.every((damage) =>
          (damage['description'] ?? '').isNotEmpty &&
          (damage['image'] != null ||
              ((damage['imageUrl'] ?? '') as String).isNotEmpty));
      if (isDamagesComplete) filledFields++;
    }

    if (_additionalFeaturesCondition == 'no') {
      filledFields++;
    } else if (_additionalFeaturesCondition == 'yes' &&
        _additionalFeaturesList.isNotEmpty) {
      final isFeaturesComplete = _additionalFeaturesList.every((feature) =>
          (feature['description'] ?? '').isNotEmpty &&
          (feature['image'] != null ||
              ((feature['imageUrl'] ?? '') as String).isNotEmpty));
      if (isFeaturesComplete) filledFields++;
    }

    return (filledFields / totalFields).clamp(0.0, 1.0);
  }

  void _updateAndNotify(VoidCallback updateFunction) {
    setState(updateFunction);
    widget.onProgressUpdate();
  }
}
