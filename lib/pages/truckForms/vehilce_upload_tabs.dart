import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/form_data_provider.dart';
import 'package:ctp/components/custom_button.dart'; // Import CustomButton
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_auth/firebase_auth.dart';

class VehicleUploadTabs extends StatefulWidget {
  const VehicleUploadTabs({super.key});

  @override
  _VehicleUploadTabsState createState() => _VehicleUploadTabsState();
}

class _VehicleUploadTabsState extends State<VehicleUploadTabs>
    with SingleTickerProviderStateMixin {
  // Add these variables for controlling the image size
  final ScrollController _scrollController = ScrollController();
  double _imageHeight = 300.0; // Initial height of the image
  double _minImageHeight = 150.0; // Minimum height when scrolled
  late TabController _tabController;
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _makeModelController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();
  final TextEditingController _vinNumberController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _applicationController = TextEditingController();
  final TextEditingController _engineNumberController = TextEditingController();
  final TextEditingController _registrationNumberController =
      TextEditingController();
  final TextEditingController _expectedSellingPriceController =
      TextEditingController();
  final TextEditingController _warrantyTypeController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String?
      _vehicleId; // To store the document ID (vehicleId) of the current vehicle

  // Form keys for each section
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(7, (index) => GlobalKey<FormState>());

  String? _selectedMileage;
  String _transmission = 'Manual';
  String _suspension = 'Steel';
  bool _isLoading = false;
  String? _listDamages =
      'yes'; // Add this field to store radio button selection

  final NumberFormat _numberFormat = NumberFormat("#,##0", "en_US");
  bool _showCurrencySymbol = false;
  String _vehicleType = 'truck';
  String _weightClass = 'heavy';
  File? _settlementLetterFile;
  String? _settleBeforeSelling;

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isSubmitting = false; // To manage loading state
  bool _isSection1Completed = false; // To check if Section 1 is completed
  // Track completed sections
  List<bool> _isSectionCompleted = List.generate(7, (index) => false);

  final List<String> _mileageOptions = [
    '0+',
    '10,001+',
    '20,001+',
    '50,001+',
    '100,001+',
    '200,001+',
    '500,001+',
    '1,000,001+'
  ];

  // Added variables for missing sections
  String _tyreType = 'virgin';
  String _treadLeft = '';
  String _spareTyre = 'yes';
  File? _rc1NatisFile;
  File? _frontRightTyreImage;
  File? _frontLeftTyreImage;
  File? _spareWheelTyreImage;
  File? _dashboardImage;
  File? _faultCodesImage;

  // For Damage Entries
  List<Map<String, dynamic>> _damageEntries = [];

  // For Photos
  List<File?> _photoFiles = List<File?>.filled(18, null);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);

    _tabController.addListener(() async {
      if (_tabController.indexIsChanging) {
        if (_tabController.index != 0) {
          if (!_formKeys[0].currentState!.validate()) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Please complete Section 1 before proceeding.')));
            _tabController.animateTo(0);
          } else {
            // Save Section 1 data
            await _saveSection1Data();
            if (_vehicleId == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Error saving Section 1. Please try again.')));
              _tabController.animateTo(0);
            }
          }
        }
      }
    });

    // Add this to listen to scroll events
    _scrollController.addListener(() {
      setState(() {
        double offset = _scrollController.offset;
        if (offset < 0) offset = 0;
        if (offset > (300.0 - 150.0)) offset = (300.0 - 150.0);
        _imageHeight = 300.0 - offset;
      });
    });
  }

  Future<String?> _uploadFile(File? file, String storagePath) async {
    if (file == null) return null;
    try {
      // Upload the file to Firebase Storage
      Reference ref = _storage.ref().child(storagePath);
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;

      // Get the download URL once the upload is complete
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: $e')),
      );
      return null;
    }
  }

  Future<void> _pickImageFromSource(
      ImageSource source, Function(File?) onImagePicked) async {
    try {
      // Pick an image from the specified source
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        onImagePicked(imageFile);
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showImageSourceDialog(Function(ImageSource) onImagePicked) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.of(context).pop();
                    onImagePicked(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    onImagePicked(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveFormData() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final formData = Provider.of<FormDataProvider>(context, listen: false);

      // Upload selectedMainImage
      String? mainImageUrl = await _uploadFile(
        formData.selectedMainImage,
        'vehicles/${DateTime.now().millisecondsSinceEpoch}_main.jpg',
      );

      // Upload selectedLicenceDiskImage
      String? licenceDiskUrl = await _uploadFile(
        formData.selectedLicenceDiskImage,
        'vehicles/${DateTime.now().millisecondsSinceEpoch}_licence_disk.jpg',
      );

      // Upload settlementLetterFile
      String? settlementLetterUrl = await _uploadFile(
        formData.settlementLetterFile,
        'vehicles/${DateTime.now().millisecondsSinceEpoch}_settlement_letter.pdf',
      );

      // Upload RC1/NATIS File (Section 4)
      String? rc1NatisUrl = await _uploadFile(
        formData.rc1NatisFile,
        'vehicles/${DateTime.now().millisecondsSinceEpoch}_rc1_natis.pdf',
      );

      // Upload Photos in Section 7
      List<String?> photoUrls = [];
      for (int i = 0; i < _photoFiles.length; i++) {
        String? url = await _uploadFile(
          _photoFiles[i],
          'vehicles/${DateTime.now().millisecondsSinceEpoch}_photo_$i.jpg',
        );
        photoUrls.add(url);
      }

      // Upload Tyre Images (Section 6)
      String? frontRightTyreUrl = await _uploadFile(
        _frontRightTyreImage,
        'vehicles/${DateTime.now().millisecondsSinceEpoch}_front_right_tyre.jpg',
      );

      String? frontLeftTyreUrl = await _uploadFile(
        _frontLeftTyreImage,
        'vehicles/${DateTime.now().millisecondsSinceEpoch}_front_left_tyre.jpg',
      );

      String? spareWheelTyreUrl = await _uploadFile(
        _spareWheelTyreImage,
        'vehicles/${DateTime.now().millisecondsSinceEpoch}_spare_wheel_tyre.jpg',
      );

      // Handle Damage Entries (Section 5)
      List<Map<String, dynamic>> damageEntries = [];
      for (var entry in _damageEntries) {
        String? damagePhotoUrl = await _uploadFile(
          entry['photo'],
          'vehicles/${DateTime.now().millisecondsSinceEpoch}_damage_${_damageEntries.indexOf(entry)}.jpg',
        );

        damageEntries.add({
          'description': entry['description'],
          'photoUrl': damagePhotoUrl,
        });
      }

      // Prepare data to save
      Map<String, dynamic> vehicleData = {
        // Section 1 - Mandatory Information
        'vehicleType': _vehicleType,
        'weightClass': _weightClass,
        'year': _yearController.text,
        'makeModel': _makeModelController.text,
        'sellingPrice': _sellingPriceController.text,
        'vinNumber': _vinNumberController.text,
        'mileage': _mileageController.text,

        // Section 2 - Additional Information
        'applicationOfUse': _applicationController.text,
        'transmission': _transmission,
        'engineNumber': _engineNumberController.text,
        'suspension': _suspension,
        'registrationNumber': _registrationNumberController.text,
        'expectedSellingPrice': _expectedSellingPriceController.text,

        // Section 3 - Settlement Details
        'settleBeforeSelling': _settleBeforeSelling,
        'settlementLetterUrl': settlementLetterUrl,
        'settlementAmount': _amountController.text,

        // Section 4 - RC1/NATIS Documents
        'rc1NatisUrl': rc1NatisUrl,

        // Section 5 - Vehicle Damage and Faults
        'damageEntries': damageEntries,

        // Section 6 - Tyres Information
        'tyreType': _tyreType,
        'spareTyre': _spareTyre,
        'frontRightTyreUrl': frontRightTyreUrl,
        'frontLeftTyreUrl': frontLeftTyreUrl,
        'spareWheelTyreUrl': spareWheelTyreUrl,
        'treadLeft': _treadLeft,

        // Section 7 - Truck Photos
        'photoUrls': photoUrls,

        // Common Fields
        'mainImageUrl': mainImageUrl,
        'licenceDiskUrl': licenceDiskUrl,

        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Check if the vehicleId exists
      if (_vehicleId == null) {
        // Create a new vehicle document if the vehicleId is not set (i.e., the first save)
        DocumentReference docRef =
            await _firestore.collection('vehicles').add(vehicleData);
        _vehicleId = docRef.id; // Store the vehicleId for subsequent saves
      } else {
        // Update the existing vehicle document if the vehicleId exists
        await _firestore
            .collection('vehicles')
            .doc(_vehicleId)
            .update(vehicleData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle data saved successfully!')),
      );

      // Optionally, reset the form or navigate to another page
      // formData.resetFormData();
      // Navigator.pop(context);
    } catch (e) {
      print("Error saving form data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _resetFormData() {
    // Reset form fields
    _yearController.clear();
    _makeModelController.clear();
    _sellingPriceController.clear();
    _vinNumberController.clear();
    _mileageController.clear();
    _applicationController.clear();
    _engineNumberController.clear();
    _registrationNumberController.clear();
    _expectedSellingPriceController.clear();
    _warrantyTypeController.clear();
    _amountController.clear();

    // Reset variables
    _vehicleId = null;
    _selectedMileage = null;
    _transmission = 'Manual';
    _suspension = 'Steel';
    _isLoading = false;
    _listDamages = 'yes';

    _vehicleType = 'truck';
    _weightClass = 'heavy';
    _settlementLetterFile = null;
    _settleBeforeSelling = null;

    // Reset section completion
    _isSection1Completed = false;
    _isSectionCompleted = List.generate(7, (index) => false);

    // Reset images and files
    _rc1NatisFile = null;
    _frontRightTyreImage = null;
    _frontLeftTyreImage = null;
    _spareWheelTyreImage = null;
    _dashboardImage = null;
    _faultCodesImage = null;

    _damageEntries = [];
    _photoFiles = List<File?>.filled(18, null);

    // Reset FormDataProvider
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    formData.setSelectedMainImage(null);
    formData.setSettlementLetterFile(null);
    formData.setSelectedLicenceDiskImage(null);
    formData.setSettleBeforeSelling('');

    // Reset TabController to the first tab
    _tabController.index = 0;
  }

  Future<void> _saveSection2Data() async {
    if (_vehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please complete Section 1 before proceeding.')),
      );
      return;
    }

    try {
      Map<String, dynamic> section2Data = {
        'applicationOfUse': _applicationController.text,
        'transmission': _transmission,
        'engineNumber': _engineNumberController.text,
        'suspension': _suspension,
        'registrationNumber': _registrationNumberController.text,
        'expectedSellingPrice': _expectedSellingPriceController.text,
      };

      await _firestore
          .collection('vehicles')
          .doc(_vehicleId)
          .update(section2Data);

      print('Section 2 data saved successfully');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving Section 2: $e')),
      );
    }
  }

  Future<void> _saveSection3Data() async {
    if (_vehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please complete Section 1 before proceeding.')),
      );
      return;
    }

    try {
      String? settlementLetterUrl;
      if (_settlementLetterFile != null) {
        settlementLetterUrl = await _uploadFile(
          _settlementLetterFile,
          'vehicles/${DateTime.now().millisecondsSinceEpoch}_settlement_letter.pdf',
        );
      }

      Map<String, dynamic> section3Data = {
        'settleBeforeSelling': _settleBeforeSelling,
        'settlementLetterUrl': settlementLetterUrl,
        'settlementAmount': _amountController.text,
      };

      await _firestore
          .collection('vehicles')
          .doc(_vehicleId)
          .update(section3Data);
      print('Section 3 data saved successfully');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving section 3: $e')),
      );
    }
  }

  Future<void> _saveSection4Data() async {
    if (_vehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please complete Section 1 before proceeding.')),
      );
      return;
    }

    try {
      String? rc1NatisUrl;
      if (_rc1NatisFile != null) {
        rc1NatisUrl = await _uploadFile(
          _rc1NatisFile,
          'vehicles/${DateTime.now().millisecondsSinceEpoch}_rc1_natis.pdf',
        );
      }

      Map<String, dynamic> section4Data = {
        'rc1NatisUrl': rc1NatisUrl,
      };

      await _firestore
          .collection('vehicles')
          .doc(_vehicleId)
          .update(section4Data);
      print('Section 4 data saved successfully');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving section 4: $e')),
      );
    }
  }

  Future<void> _saveSection5Data() async {
    if (_vehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please complete Section 1 before proceeding.')),
      );
      return;
    }

    try {
      List<Map<String, dynamic>> damageEntries = [];
      for (var entry in _damageEntries) {
        String? damagePhotoUrl = await _uploadFile(
          entry['photo'],
          'vehicles/${DateTime.now().millisecondsSinceEpoch}_damage_${_damageEntries.indexOf(entry)}.jpg',
        );
        damageEntries.add({
          'description': entry['description'],
          'photoUrl': damagePhotoUrl,
        });
      }

      Map<String, dynamic> section5Data = {
        'damageEntries': damageEntries,
      };

      await _firestore
          .collection('vehicles')
          .doc(_vehicleId)
          .update(section5Data);
      print('Section 5 data saved successfully');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving section 5: $e')),
      );
    }
  }

  Future<void> _saveSection6Data() async {
    if (_vehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please complete Section 1 before proceeding.')),
      );
      return;
    }

    try {
      // Upload Tyre Images
      String? frontRightTyreUrl = await _uploadFile(
        _frontRightTyreImage,
        'vehicles/${DateTime.now().millisecondsSinceEpoch}_front_right_tyre.jpg',
      );

      String? frontLeftTyreUrl = await _uploadFile(
        _frontLeftTyreImage,
        'vehicles/${DateTime.now().millisecondsSinceEpoch}_front_left_tyre.jpg',
      );

      String? spareWheelTyreUrl = await _uploadFile(
        _spareWheelTyreImage,
        'vehicles/${DateTime.now().millisecondsSinceEpoch}_spare_wheel_tyre.jpg',
      );

      Map<String, dynamic> section6Data = {
        'tyreType': _tyreType,
        'spareTyre': _spareTyre,
        'frontRightTyreUrl': frontRightTyreUrl,
        'frontLeftTyreUrl': frontLeftTyreUrl,
        'spareWheelTyreUrl': spareWheelTyreUrl,
        'treadLeft': _treadLeft,
      };

      await _firestore
          .collection('vehicles')
          .doc(_vehicleId)
          .update(section6Data);
      print('Section 6 data saved successfully');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving section 6: $e')),
      );
    }
  }

  Future<void> _saveSection7Data() async {
    if (_vehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please complete Section 1 before proceeding.')),
      );
      return;
    }

    try {
      // Upload Truck Photos
      List<String?> photoUrls = [];
      for (int i = 0; i < _photoFiles.length; i++) {
        String? url = await _uploadFile(
          _photoFiles[i],
          'vehicles/${DateTime.now().millisecondsSinceEpoch}_photo_$i.jpg',
        );
        photoUrls.add(url);
      }

      Map<String, dynamic> section7Data = {
        'photoUrls': photoUrls,
      };

      await _firestore
          .collection('vehicles')
          .doc(_vehicleId)
          .update(section7Data);
      print('Section 7 data saved successfully');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving section 7: $e')),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        // Save to provider
        Provider.of<FormDataProvider>(context, listen: false)
            .setSelectedMainImage(imageFile);
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _saveSection1Data() async {
    if (!_formKeys[0].currentState!.validate()) {
      return; // Return if form is not valid
    }

    setState(() {
      _isLoading = true; // Show loading spinner
    });

    try {
      // Access the selectedMainImage from the provider
      final formData = Provider.of<FormDataProvider>(context, listen: false);
      String? mainImageUrl;
      if (formData.selectedMainImage != null) {
        // Upload the main image
        mainImageUrl = await _uploadFile(
          formData.selectedMainImage,
          'vehicles/${DateTime.now().millisecondsSinceEpoch}_main.jpg',
        );
      } else {
        // If no main image is selected, you might want to prevent saving
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a main image before saving.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Get the current user's UID
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        // If the user is not signed in, show an error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user is signed in.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final String userId = currentUser.uid;

      // Prepare data for Section 1
      Map<String, dynamic> section1Data = {
        'userId': userId, // Include the userId
        'vehicleType': _vehicleType,
        'weightClass': _weightClass,
        'year': _yearController.text,
        'makeModel': _makeModelController.text,
        'vinNumber': _vinNumberController.text,
        'mileage': _mileageController.text,
        'sellingPrice': _sellingPriceController.text,
        'mainImageUrl': mainImageUrl, // Include the main image URL
        'vehicleStatus': 'Draft', // Default value for vehicle status
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Debugging code
      print('Submitting Section 1 Data:');
      print(section1Data);

      // Add new document if it's a new vehicle, otherwise update the existing document
      if (_vehicleId == null) {
        DocumentReference docRef =
            await _firestore.collection('vehicles').add(section1Data);
        _vehicleId = docRef.id; // Store vehicleId for future use

        // Debugging code
        print('New vehicle document created with ID: $_vehicleId');
      } else {
        await _firestore
            .collection('vehicles')
            .doc(_vehicleId)
            .update(section1Data);

        // Debugging code
        print('Vehicle document updated with ID: $_vehicleId');
      }

      setState(() {
        _isSection1Completed = true; // Mark Section 1 as completed
      });
      print('Section 1 saved successfully!');
    } catch (e) {
      print("Error saving section 1 data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving section 1: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading spinner
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var orange = const Color(0xFFFF4E00);
    var blue = const Color(0xFF2F7FFF);
    var green = const Color(0xFF4CAF50);

    // Access the selectedMainImage from the provider
    final formData = Provider.of<FormDataProvider>(context);
    File? _selectedMainImage = formData.selectedMainImage;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () async {
                Navigator.pop(context);
              },
              icon: Icon(Icons.arrow_left),
              color: Colors.white,
              iconSize: 40,
            ),
            backgroundColor:
                Color(0xFF0E4CAF), // Set AppBar background to transparent
            elevation: 0.0, // Remove shadow/elevation
            systemOverlayStyle:
                SystemUiOverlayStyle.light, // For status bar icons
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Material(
                color: Color(0xFF0E4CAF),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Mandatory Section'),
                    Tab(text: 'Additional Information'),
                    Tab(text: 'Settlement'),
                    Tab(text: 'RCI/NATIS'),
                    Tab(text: 'Damage & Faults'),
                    Tab(text: 'Tyres'),
                    Tab(text: 'Additional Photos'),
                  ],
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  onTap: (index) async {
                    if (index != 0) {
                      if (!_formKeys[0].currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Please complete Section 1 before proceeding.')));
                        _tabController.animateTo(0);
                      } else {
                        // Save Section 1 data
                        await _saveSection1Data();
                        if (_vehicleId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Error saving Section 1. Please try again.')),
                          );
                          _tabController.animateTo(0);
                        }
                      }
                    }
                  },
                ),
              ),
            ),
          ),
          body: GradientBackground(
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (scrollNotification.metrics.axis == Axis.vertical) {
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      double offset = scrollNotification.metrics.pixels;
                      if (offset < 0) offset = 0;
                      if (offset > (300.0 - 150.0)) offset = (300.0 - 150.0);
                      _imageHeight = 300.0 - offset;
                    });
                  });
                }
                return true;
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 1),
                        // Inside your build method or wherever this widget is placed
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 0),
                          height: _imageHeight, // Use _imageHeight here
                          width: double.infinity,
                          child: _selectedMainImage == null
                              ? GestureDetector(
                                  onTap: () {
                                    _showImageSourceDialog(
                                        (ImageSource source) {
                                      _pickImage(source);
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.camera_alt,
                                                size: 40,
                                                color: Colors.white,
                                              ),
                                              onPressed: () {
                                                _pickImage(ImageSource.camera);
                                              },
                                            ),
                                            const SizedBox(width: 20),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.photo,
                                                size: 40,
                                                color: Colors.white,
                                              ),
                                              onPressed: () {
                                                _pickImage(ImageSource.gallery);
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'NEW PHOTO OR UPLOAD FROM GALLERY',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: Image.file(
                                    _selectedMainImage!,
                                    width: double.infinity,
                                    height:
                                        _imageHeight, // Use _imageHeight here
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    // Wrap TabBarView in a Container to set its height
                    Container(
                      height: MediaQuery.of(context).size.height -
                          _imageHeight -
                          kToolbarHeight -
                          kBottomNavigationBarHeight,
                      child: TabBarView(
                        controller: _tabController,
                        physics: _isSection1Completed
                            ? null
                            : const NeverScrollableScrollPhysics(),
                        children: [
                          _buildSection1(orange, blue, green),
                          _buildSection2(orange, blue, green),
                          _buildSection3(orange, blue, green),
                          _buildSection4(orange, blue, green),
                          _buildSection5(orange, blue, green),
                          _buildSection6(orange, blue, green),
                          _buildSection7(orange, blue, green),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Visibility widget to show or hide the loading indicator
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Image.asset(
                  'lib/assets/Loading_Logo_CTP.gif', // Replace with the path to your custom loading gif
                  width: 100,
                  height: 100,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSection1(Color orange, Color blue, Color green) {
    return _buildSectionWithGradient(
      orange,
      blue,
      green,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'MANDATORY INFORMATION',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Please fill out the required details below\nYour trusted partner on the road.',
                style: TextStyle(fontSize: 14, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRadioButton('Truck', 'truck'),
                const SizedBox(width: 20),
                _buildRadioButton('Trailer', 'trailer'),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRadioButton('Heavy', 'heavy', isWeight: true),
                const SizedBox(width: 20),
                _buildRadioButton('Medium', 'medium', isWeight: true),
                const SizedBox(width: 20),
                _buildRadioButton('Light', 'light', isWeight: true),
              ],
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKeys[0],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _yearController,
                          hintText: 'Year',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the year';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          controller: _makeModelController,
                          hintText: 'Make/Model',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the make/model';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _mileageController,
                    hintText: 'Mileage',
                    keyboardType: TextInputType.number,
                    inputFormatter: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the mileage';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _sellingPriceController,
                    hintText: 'Selling Price',
                    isCurrency: true,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the selling price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _vinNumberController,
                    hintText: 'VIN Number',
                    inputFormatter: [
                      UpperCaseTextFormatter()
                    ], // Added this line
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the VIN number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            CustomButton(
              text: 'Next',
              borderColor: blue,
              onPressed: () async {
                if (!_formKeys[0].currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Please fill in all required fields in Section 1.')),
                  );
                  return;
                } else {
                  // Save Section 1 data and move to the next tab
                  await _saveSection1Data();
                  if (_vehicleId != null) {
                    _tabController.animateTo(1);
                  }
                }
              },
            ),
            if (_tabController.index == 0)
              CustomButton(
                text: 'Done',
                borderColor: orange,
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (!_formKeys[0].currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Please fill in all required fields in Section 1.')),
                          );
                          return;
                        } else {
                          await _saveAllSectionsAndNavigateHome();
                        }
                      },
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      0,
    );
  }

  Widget _buildSection2(Color orange, Color blue, Color green) {
    return _buildSectionWithGradient(
      orange,
      blue,
      green,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Form(
          key: _formKeys[1],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'TRUCK/TRAILER FORM',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextArea(
                controller: _applicationController,
                hintText: 'Application of Use',
                maxLines: 5,
              ),
              const SizedBox(height: 15),

              // Transmission Dropdown
              const Text(
                "Transmission",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              _buildDropdown(
                value: _transmission,
                items: ['Manual', 'Automatic'],
                hintText: 'Transmission',
                onChanged: (value) {
                  setState(() {
                    _transmission = value!;
                  });
                },
              ),
              const SizedBox(height: 15),

              // Engine Number Field
              _buildTextField(
                controller: _engineNumberController,
                hintText: 'Engine No.',
                inputFormatter: [UpperCaseTextFormatter()],
                // No validator
              ),
              const SizedBox(height: 15),

              // Suspension Dropdown
              const Text(
                "Suspension",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              _buildDropdown(
                value: _suspension,
                items: ['Steel', 'Air'],
                hintText: 'Suspension',
                onChanged: (value) {
                  setState(() {
                    _suspension = value!;
                  });
                },
              ),
              const SizedBox(height: 15),

              // Registration Number Field
              _buildTextField(
                controller: _registrationNumberController,
                hintText: 'Registration No.',
                inputFormatter: [UpperCaseTextFormatter()],
                // No validator
              ),
              const SizedBox(height: 15),

              // Expected Selling Price Field
              _buildSellingPriceTextField(
                controller: _expectedSellingPriceController,
                hintText: 'Expected Selling Price',
                // No validator
              ),
              const SizedBox(height: 15),

              // Add the Next and Done buttons at the bottom
              Center(
                child: Column(
                  children: [
                    CustomButton(
                      text: 'Next',
                      borderColor: blue,
                      onPressed: () async {
                        if (!_formKeys[1].currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Please fill in all required fields in Section 2.')),
                          );
                          return;
                        } else {
                          // Save Section 2 data and move to next tab
                          await _saveSection2Data();
                          if (_vehicleId != null) {
                            _tabController.animateTo(2); // move to next tab
                          }
                        }
                      },
                    ),
                    if (_tabController.index ==
                        1) // Show the Done button for section 2
                      CustomButton(
                        text: 'Done',
                        borderColor: orange,
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (!_formKeys[1].currentState!.validate()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Please fill in all required fields in Section 2.')),
                                  );
                                  return;
                                } else {
                                  await _saveAllSectionsAndNavigateHome();
                                }
                              },
                      ),
                  ],
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
      1, // Corrected number of arguments
    );
  }

  Widget _buildSection3(Color orange, Color blue, Color green) {
    return _buildSectionWithGradient(
      orange,
      blue,
      green,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Form(
          key: _formKeys[2],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'SETTLEMENT DETAILS',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Do you have a bank settlement?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRadioButton(
                    'Yes',
                    'yes',
                    groupValue: _settleBeforeSelling,
                    onChanged: (value) {
                      setState(() {
                        _settleBeforeSelling = value;
                      });
                      if (value != null) {
                        Provider.of<FormDataProvider>(context, listen: false)
                            .setSettleBeforeSelling(value);
                      }
                    },
                  ),
                  const SizedBox(width: 20),
                  _buildRadioButton(
                    'No',
                    'no',
                    groupValue: _settleBeforeSelling,
                    onChanged: (value) {
                      setState(() {
                        _settleBeforeSelling = value;
                      });
                      if (value != null) {
                        Provider.of<FormDataProvider>(context, listen: false)
                            .setSettleBeforeSelling(value);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Visibility(
                visible: _settleBeforeSelling == 'yes',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Please attach the following documents',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: GestureDetector(
                        onTap: () => _pickFile('settlementLetter'),
                        child: Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(color: Colors.white70, width: 1),
                          ),
                          child: Center(
                            child: _settlementLetterFile == null
                                ? const Icon(Icons.folder_open,
                                    color: Colors.blue, size: 40)
                                : Text(
                                    path.basename(_settlementLetterFile!.path),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        'Please attach the settlement letter',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'Settlement Amount',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: _amountController,
                      hintText: 'Amount',
                      isCurrency: true, // Ensure 'R' prefix is shown
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Add Next and Done buttons here, regardless of Yes/No selection
              Center(
                child: Column(
                  children: [
                    CustomButton(
                      text: 'Next',
                      borderColor: blue,
                      onPressed: () async {
                        if (!_formKeys[2].currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Please fill in all required fields in Section 3.')),
                          );
                          return;
                        } else {
                          // Save Section 3 data and move to next tab
                          await _saveSection3Data();
                          if (_vehicleId != null) {
                            _tabController.animateTo(3); // move to next tab
                          }
                        }
                      },
                    ),
                    if (_tabController.index ==
                        2) // Show the Done button for section 3
                      CustomButton(
                        text: 'Done',
                        borderColor: orange,
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (!_formKeys[2].currentState!.validate()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Please fill in all required fields in Section 3.')),
                                  );
                                  return;
                                } else {
                                  await _saveAllSectionsAndNavigateHome();
                                }
                              },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      2, // Corrected number of arguments
    );
  }

  Widget _buildSection4(Color orange, Color blue, Color green) {
    return _buildSectionWithGradient(
      orange,
      blue,
      green,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Form(
          key: _formKeys[3],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'RC1/NATIS DOCUMENTS',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),

              const Center(
                child: Text(
                  'Please upload your RC1/NATIS documentation',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),

              // Upload RC1/NATIS Documents
              Center(
                child: GestureDetector(
                  onTap: () => _pickFile('rc1Natis'),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: Colors.white70, width: 1),
                    ),
                    child: Center(
                      child: _rc1NatisFile == null
                          ? const Icon(Icons.folder_open,
                              color: Colors.blue, size: 40)
                          : Text(
                              path.basename(_rc1NatisFile!.path),
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Add Next and Done buttons here
              Center(
                child: Column(
                  children: [
                    CustomButton(
                      text: 'Next',
                      borderColor: blue,
                      onPressed: () async {
                        if (!_formKeys[3].currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Please fill in all required fields in Section 4.')),
                          );
                          return;
                        } else {
                          // Save Section 4 data and move to the next tab
                          await _saveSection4Data();
                          if (_vehicleId != null) {
                            _tabController.animateTo(4); // move to next tab
                          }
                        }
                      },
                    ),
                    if (_tabController.index ==
                        3) // Show the Done button for section 4
                      CustomButton(
                        text: 'Done',
                        borderColor: orange,
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (!_formKeys[3].currentState!.validate()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Please fill in all required fields in Section 4.')),
                                  );
                                  return;
                                } else {
                                  await _saveAllSectionsAndNavigateHome();
                                }
                              },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      3, // Corrected number of arguments
    );
  }

  Widget _buildSection5(Color orange, Color blue, Color green) {
    return _buildSectionWithGradient(
      orange,
      blue,
      green,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Form(
          key: _formKeys[4],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'VEHICLE DAMAGE AND FAULTS',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Would you like to list any damages or faults?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),

              // Radio buttons to select if the user wants to list damages
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRadioButton('Yes', 'yes',
                      groupValue: _listDamages ?? 'yes', onChanged: (value) {
                    setState(() {
                      _listDamages = value;
                    });
                  }),
                  const SizedBox(width: 20),
                  _buildRadioButton('No', 'no',
                      groupValue: _listDamages ?? 'yes', onChanged: (value) {
                    setState(() {
                      _listDamages = value;
                    });
                  }),
                ],
              ),
              const SizedBox(height: 20),

              // Conditionally display the damage and fault upload sections
              if (_listDamages == 'yes') ...[
                // Dashboard Photo Upload Section
                _buildDashboardUploadSection(),
                const SizedBox(height: 20),

                // Fault Codes Photo Upload Section
                _buildFaultCodesUploadSection(),
                const SizedBox(height: 20),

                // Damage Entry Section
                _buildDamageEntriesSection(),
                const SizedBox(height: 20),
              ],

              // Add Next and Done buttons here
              Center(
                child: Column(
                  children: [
                    CustomButton(
                      text: 'Next',
                      borderColor: blue,
                      onPressed: () async {
                        if (!_formKeys[4].currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Please fill in all required fields in Section 5.')),
                          );
                          return;
                        } else {
                          // Save Section 5 data and move to the next tab
                          await _saveSection5Data();
                          if (_vehicleId != null) {
                            _tabController.animateTo(5); // move to next tab
                          }
                        }
                      },
                    ),
                    if (_tabController.index ==
                        4) // Show the Done button for section 5
                      CustomButton(
                        text: 'Done',
                        borderColor: orange,
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (!_formKeys[4].currentState!.validate()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Please fill in all required fields in Section 5.')),
                                  );
                                  return;
                                } else {
                                  await _saveAllSectionsAndNavigateHome();
                                }
                              },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      4, // Corrected number of arguments
    );
  }

// Radio button widget
  // Define _buildRadioButton only once and use it across all sections.
  Widget _buildRadioButton1(
    String label,
    String value, {
    required String groupValue,
    required Function(String?) onChanged,
  }) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor:
              const Color(0xFFFF4E00), // Orange color for selected radio button
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSection6(Color orange, Color blue, Color green) {
    return _buildSectionWithGradient(
      orange,
      blue,
      green,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Form(
          key: _formKeys[5],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'TYRES INFORMATION',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Please fill in the tyre details below',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // Tyre Type (Virgin or Recaps)
              _buildTyreTypeSection(),
              const SizedBox(height: 20),

              // Tread Left (Dropdown)
              _buildTreadLeftDropdown(),
              const SizedBox(height: 20),

              // Front Right Tyre Image Upload
              _buildTyreImageUploadBlock(
                  1, 'Front Right Tyre', _frontRightTyreImage, (File? image) {
                setState(() {
                  _frontRightTyreImage = image;
                });
              }),
              const SizedBox(height: 20),

              // Front Left Tyre Image Upload
              _buildTyreImageUploadBlock(
                  2, 'Front Left Tyre', _frontLeftTyreImage, (File? image) {
                setState(() {
                  _frontLeftTyreImage = image;
                });
              }),
              const SizedBox(height: 20),

              // Spare Tyre (Yes or No) and Upload Section
              const Center(
                child: Text(
                  'Spare Tyre',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              _buildSpareTyreSection(),
              const SizedBox(height: 20),

              // Spare Wheel Tyre Image Upload
              _buildTyreImageUploadBlock(
                  3, 'Spare Wheel Tyre', _spareWheelTyreImage, (File? image) {
                setState(() {
                  _spareWheelTyreImage = image;
                });
              }),
              const SizedBox(height: 30),

              // Add Next and Done buttons here
              Center(
                child: Column(
                  children: [
                    CustomButton(
                      text: 'Next',
                      borderColor: blue,
                      onPressed: () async {
                        if (!_formKeys[5].currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Please fill in all required fields in Section 6.')),
                          );
                          return;
                        } else {
                          // Save Section 6 data and move to the next tab
                          await _saveSection6Data();
                          if (_vehicleId != null) {
                            _tabController.animateTo(6); // move to next tab
                          }
                        }
                      },
                    ),
                    if (_tabController.index ==
                        5) // Show the Done button for section 6
                      CustomButton(
                        text: 'Done',
                        borderColor: orange,
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (!_formKeys[5].currentState!.validate()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Please fill in all required fields in Section 6.')),
                                  );
                                  return;
                                } else {
                                  await _saveAllSectionsAndNavigateHome();
                                }
                              },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      5, // Corrected number of arguments
    );
  }

  Widget _buildSection7(Color orange, Color blue, Color green) {
    return _buildSectionWithGradient(
      orange,
      blue,
      green,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Form(
          key: _formKeys[6],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'TRUCK PHOTOS',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Please upload photos of the truck and its parts',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // Exterior Photos Header
              const Center(
                child: Text(
                  'Exterior Photos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),

              // Exterior Photos Grid
              _buildPhotoGrid(0, 4),
              const SizedBox(height: 20),

              // Additional Exterior Photos Header
              const Center(
                child: Text(
                  'Exterior Photos Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),

              // Additional Exterior Photos Grid
              _buildPhotoGrid(4, 12),
              const SizedBox(height: 20),

              // Interior Photos Header
              const Center(
                child: Text(
                  'Interior Photos Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),

              // Interior Photos Grid
              _buildPhotoGrid(12, 18),
              const SizedBox(height: 20),

              // Add Done button here
              Center(
                child: CustomButton(
                  text: 'Done',
                  borderColor: orange,
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (!_formKeys[6].currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Please fill in all required fields in Section 7.')),
                            );
                            return;
                          } else {
                            await _saveAllSectionsAndNavigateHome();
                          }
                        },
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      6, // Corrected number of arguments
    );
  }

  Future<void> _pickFile(String fileType) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      setState(() {
        if (fileType == 'settlementLetter') {
          _settlementLetterFile = file;
        } else if (fileType == 'rc1Natis') {
          _rc1NatisFile = file;
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
    }
  }

  Widget _buildSectionWithGradient(Color orange, Color blue, Color green,
      Widget sectionContent, int currentIndex) {
    return GradientBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: sectionContent,
            ),
          ),
          const SizedBox(height: 20),
          // if (currentIndex < 6) // Only show Next button for sections 1-6
          //   Center(
          //     child: Padding(
          //       padding: const EdgeInsets.symmetric(horizontal: 16.0),
          //       child: CustomButton(
          //         text: 'Next',
          //         borderColor: blue,
          //         onPressed: () async {
          //           if (currentIndex == 0) {
          //             // Validation for Section 1
          //             if (!_formKeys[0].currentState!.validate()) {
          //               ScaffoldMessenger.of(context).showSnackBar(
          //                 const SnackBar(
          //                     content: Text(
          //                         'Please fill in all required fields in Section 1.')),
          //               );
          //               return;
          //             } else if (!_isInspectionSetupComplete ||
          //                 !_isCollectionSetupComplete) {
          //               ScaffoldMessenger.of(context).showSnackBar(
          //                 const SnackBar(
          //                     content: Text(
          //                         'Please complete both Inspection and Collection setup before proceeding.')),
          //               );
          //               return;
          //             } else {
          //               // Save Section 1 data
          //               await _saveSection1Data();
          //             }
          //           }
          //           if (_tabController.index < _tabController.length - 1) {
          //             // Ensure vehicleId is not null
          //             if (_vehicleId != null) {
          //               _tabController.animateTo(_tabController.index + 1);
          //             } else {
          //               ScaffoldMessenger.of(context).showSnackBar(
          //                 const SnackBar(
          //                     content: Text(
          //                         'Error saving Section 1. Please try again.')),
          //               );
          //             }
          //           }
          //         },
          //       ),
          //     ),
          //   ),
          // const SizedBox(height: 10),
          // Center(
          //   child: Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 16.0),
          //     child: CustomButton(
          //       text: 'Done',
          //       borderColor: orange,
          //       onPressed: _isLoading
          //           ? null
          //           : () async {
          //               // Validation for Section 1 before saving all sections
          //               if (!_formKeys[0].currentState!.validate()) {
          //                 ScaffoldMessenger.of(context).showSnackBar(
          //                   const SnackBar(
          //                       content: Text(
          //                           'Please fill in all required fields in Section 1.')),
          //                 );
          //                 return;
          //               } else if (!_isInspectionSetupComplete ||
          //                   !_isCollectionSetupComplete) {
          //                 ScaffoldMessenger.of(context).showSnackBar(
          //                   const SnackBar(
          //                       content: Text(
          //                           'Please complete both Inspection and Collection setup before proceeding.')),
          //                 );
          //                 return;
          //               } else {
          //                 await _saveAllSectionsAndNavigateHome();
          //               }
          //             },
          //     ),
          //   ),
          // ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _saveAllSectionsAndNavigateHome() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_vehicleId == null) {
        // Ensure that the vehicleId is set by saving Section 1 data first
        await _saveSection1Data();
        if (_vehicleId == null) {
          // If vehicleId is still null, show error and return
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please complete Section 1.')),
          );
          return;
        }
      }

      // Save all sections
      await _saveSection2Data();
      await _saveSection3Data();
      await _saveSection4Data();
      await _saveSection5Data();
      await _saveSection6Data();
      await _saveSection7Data();

      // Optionally, show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data saved successfully!')),
      );

      // Reset form data before navigating back
      _resetFormData();

      // Navigate back to the home page
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildRadioButton(
    String label,
    String value, {
    String? groupValue,
    Function(String?)? onChanged,
    bool isWeight = false,
  }) {
    bool isSelected =
        (groupValue ?? (isWeight ? _weightClass : _vehicleType)) == value;

    return InkWell(
      onTap: () {
        if (onChanged != null) {
          onChanged(value);
        } else {
          setState(() {
            if (isWeight) {
              _weightClass = value;
            } else {
              _vehicleType = value;
            }
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF4E00)
              : Colors.transparent, // Orange background if selected
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF4E00)
                : Colors.white54, // Orange border if selected, white otherwise
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors
                        .white70, // White text if selected, slightly faded otherwise
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool isCurrency = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatter,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
      cursorColor: const Color(0xFFFF4E00), // Orange cursor color
      decoration: InputDecoration(
        hintText: hintText,
        prefixText: isCurrency ? 'R ' : '',
        prefixStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: Color(0xFFFF4E00), // Orange border when focused
            width: 2.0,
          ),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      inputFormatters: inputFormatter,
      validator: validator,
      onChanged: isCurrency
          ? (value) {
              if (value.isNotEmpty) {
                try {
                  final formattedValue = _numberFormat
                      .format(int.parse(value.replaceAll(" ", "")))
                      .replaceAll(",", " ");
                  controller.value = TextEditingValue(
                    text: formattedValue,
                    selection:
                        TextSelection.collapsed(offset: formattedValue.length),
                  );
                } catch (e) {
                  print("Error formatting amount: $e");
                }
              }
            }
          : null,
    );
  }

  Widget _buildSellingPriceTextField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return _buildTextField(
      controller: controller,
      hintText: hintText,
      isCurrency: true,
      keyboardType: TextInputType.number,
      inputFormatter: [
        FilteringTextInputFormatter.digitsOnly,
      ],
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 5,
  }) {
    return TextFormField(
      controller: controller,
      cursorColor: const Color(0xFFFF4E00),
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: Color(0xFFFF4E00),
            width: 2.0,
          ),
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hintText,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value == '' || value == 'None' ? null : value,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: Color(0xFFFF4E00),
            width: 2.0,
          ),
        ),
      ),
      hint: Text(
        hintText,
        style: const TextStyle(color: Colors.white70),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      dropdownColor: Colors.black.withOpacity(0.7),
    );
  }

  // Missing methods added below:

  // Tyre Type Selection (Virgin or Recaps)
  Widget _buildTyreTypeSection() {
    return Column(
      children: [
        const Center(
          child: Text(
            'Tyre Type',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRadioButton(
              'Virgin',
              'virgin',
              groupValue: _tyreType,
              onChanged: (value) {
                setState(() {
                  _tyreType = value!;
                });
              },
            ),
            const SizedBox(width: 20),
            _buildRadioButton(
              'Recaps',
              'recaps',
              groupValue: _tyreType,
              onChanged: (value) {
                setState(() {
                  _tyreType = value!;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  // Tread Left Dropdown
  Widget _buildTreadLeftDropdown() {
    final List<String> _treadOptions = ['10% - 50%', '51% - 79%', '80% - 100%'];
    return DropdownButtonFormField<String>(
      value: _treadLeft.isEmpty ? null : _treadLeft,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Colors.white70),
        hintText: 'Tread Left',
      ),
      dropdownColor: Colors.black,
      style: const TextStyle(color: Colors.white),
      items: _treadOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _treadLeft = newValue ?? '';
        });
      },
    );
  }

  // Spare Tyre (Yes/No) Section
  Widget _buildSpareTyreSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildRadioButton('Yes', 'yes', groupValue: _spareTyre,
            onChanged: (value) {
          setState(() {
            _spareTyre = value!;
          });
        }),
        const SizedBox(width: 20),
        _buildRadioButton('No', 'no', groupValue: _spareTyre,
            onChanged: (value) {
          setState(() {
            _spareTyre = value!;
          });
        }),
      ],
    );
  }

  // Tyre Image Upload Block
  Widget _buildTyreImageUploadBlock(
      int index, String label, File? tyreImage, Function(File?) onImagePicked) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (tyreImage == null) {
              _changeTyreImage(index, onImagePicked);
            } else {
              _showFullImageDialogForTyre(
                  index, label, tyreImage, onImagePicked);
            }
          },
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.white70, width: 1),
            ),
            child: tyreImage == null
                ? const Center(
                    child: Icon(Icons.add, color: Colors.blue, size: 40),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.file(
                      tyreImage,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  void _changeTyreImage(int index, Function(File?) onImagePicked) {
    _showImageSourceDialog((ImageSource source) {
      _pickImageFromSource(source, (File? image) {
        setState(() {
          onImagePicked(image);
        });
      });
    });
  }

  Future<void> _pickTyreImage(int index, Function(File?) onImagePicked) async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        onImagePicked(imageFile);
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showFullImageDialogForTyre(
      int index, String label, File tyreImage, Function(File?) onImagePicked) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(
                tyreImage,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _changeTyreImage(index, onImagePicked);
                    },
                    icon: const Icon(Icons.photo, color: Colors.blue),
                    label: const Text(
                      'Change Image',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        onImagePicked(null);
                      });
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Delete Image',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Dashboard Photo Upload Section
  Widget _buildDashboardUploadSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (_dashboardImage == null) {
              _changeDashboardImage();
            } else {
              _showFullImageDialogForDashboard();
            }
          },
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.white70, width: 1),
            ),
            child: Center(
              child: _dashboardImage == null
                  ? const Center(
                      child: Icon(Icons.add, color: Colors.blue, size: 40),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.file(
                        _dashboardImage!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Upload Dashboard Photo',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  void _changeDashboardImage() {
    _showImageSourceDialog((ImageSource source) {
      _pickImageFromSource(source, (File? image) {
        setState(() {
          _dashboardImage = image;
        });
      });
    });
  }

  void _showFullImageDialogForDashboard() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_dashboardImage != null)
                Image.file(
                  _dashboardImage!,
                  fit: BoxFit.contain,
                ),
              if (_dashboardImage == null)
                const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'No Image Selected',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _changeDashboardImage();
                    },
                    icon: const Icon(Icons.photo, color: Colors.blue),
                    label: const Text(
                      'Change Image',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _dashboardImage = null;
                      });
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Delete Image',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Fault Codes Photo Upload Section
  Widget _buildFaultCodesUploadSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (_faultCodesImage == null) {
              _changeFaultCodesImage();
            } else {
              _showFullImageDialogForFaultCodes();
            }
          },
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.white70, width: 1),
            ),
            child: Center(
              child: _faultCodesImage == null
                  ? const Center(
                      child: Icon(Icons.add, color: Colors.blue, size: 40),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.file(
                        _faultCodesImage!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Upload Fault Codes Photo',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  void _changeFaultCodesImage() {
    _showImageSourceDialog((ImageSource source) {
      _pickImageFromSource(source, (File? image) {
        setState(() {
          _faultCodesImage = image;
        });
      });
    });
  }

  void _showFullImageDialogForFaultCodes() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_faultCodesImage != null)
                Image.file(
                  _faultCodesImage!,
                  fit: BoxFit.contain,
                ),
              if (_faultCodesImage == null)
                const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'No Image Selected',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _changeFaultCodesImage();
                    },
                    icon: const Icon(Icons.photo, color: Colors.blue),
                    label: const Text(
                      'Change Image',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _faultCodesImage = null;
                      });
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Delete Image',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Damage Entry Section
  Widget _buildDamageEntriesSection() {
    return Column(
      children: [
        const Center(
          child: Text(
            'List Damages and Upload Photos',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: List.generate(
            _damageEntries.length,
            (index) => _buildDamageEntryField(index),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            onPressed: () {
              _addDamageEntry();
            },
            icon: const Icon(Icons.add, color: Colors.blue),
            label: const Text(
              'ADD DAMAGE',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }

  void _addDamageEntry() {
    setState(() {
      _damageEntries.add({'description': '', 'photo': null});
    });
  }

  Widget _buildDamageEntryField(int index) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _damageEntries[index]['description'],
                decoration: InputDecoration(
                  hintText: 'Describe Damage',
                  hintStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  _damageEntries[index]['description'] = value;
                },
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _removeDamageEntry(index);
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            if (_damageEntries[index]['photo'] == null) {
              _changeDamageEntryImage(index);
            } else {
              _showFullImageDialog(index);
            }
          },
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.white70, width: 1),
            ),
            child: Center(
              child: _damageEntries[index]['photo'] == null
                  ? const Center(
                      child: Icon(Icons.add, color: Colors.blue, size: 40),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.file(
                        _damageEntries[index]['photo'],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Divider(color: Colors.white54),
      ],
    );
  }

  void _showFullImageDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_damageEntries[index]['photo'] != null)
                Image.file(
                  _damageEntries[index]['photo'],
                  fit: BoxFit.contain,
                ),
              if (_damageEntries[index]['photo'] == null)
                const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'No Image Selected',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _changeDamageEntryImage(index);
                    },
                    icon: const Icon(Icons.photo, color: Colors.blue),
                    label: const Text(
                      'Change Image',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _damageEntries[index]['photo'] = null;
                      });
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Delete Image',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _changeDamageEntryImage(int index) {
    _showImageSourceDialog((ImageSource source) {
      _pickImageFromSource(source, (File? image) {
        setState(() {
          _damageEntries[index]['photo'] = image;
        });
      });
    });
  }

  // Method to remove a damage entry
  void _removeDamageEntry(int index) {
    setState(() {
      _damageEntries.removeAt(index);
    });
  }

  // Photo Grid for Section 7
  Widget _buildPhotoGrid(int startIndex, int endIndex) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: endIndex - startIndex,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        int actualIndex = startIndex + index;
        return GestureDetector(
          onTap: () {
            if (_photoFiles[actualIndex] == null) {
              _changePhotoImage(actualIndex);
            } else {
              _showFullImageDialogForPhoto(actualIndex);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.white70, width: 1),
            ),
            child: Center(
              child: _photoFiles[actualIndex] == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: Colors.blue, size: 40),
                        Text(
                          _getPhotoLabel(actualIndex),
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.file(
                        _photoFiles[actualIndex]!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  // Photo labels for each section
  String _getPhotoLabel(int index) {
    switch (index) {
      case 0:
        return 'Front View';
      case 1:
        return 'Right Side View';
      case 2:
        return 'Left Side View';
      case 3:
        return 'Rear View';
      case 4:
        return '45° Left Front View';
      case 5:
        return '45° Right Front View';
      case 6:
        return '45° Left Rear View';
      case 7:
        return '45° Right Rear View';
      case 8:
        return 'Front Tyres Tread';
      case 9:
        return 'Rear Tyres Tread';
      case 10:
        return 'Spare Wheel';
      case 11:
        return 'License Disk';
      case 12:
        return 'Seats';
      case 13:
        return 'Bed Bunk';
      case 14:
        return 'Roof';
      case 15:
        return 'Mileage';
      case 16:
        return 'Dashboard';
      case 17:
        return 'Door Panels';
      default:
        return 'Unknown Label';
    }
  }

  void _changePhotoImage(int index) {
    _showImageSourceDialog((ImageSource source) {
      _pickImageFromSource(source, (File? image) {
        setState(() {
          _photoFiles[index] = image;
        });
      });
    });
  }

  void _showFullImageDialogForPhoto(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_photoFiles[index] != null)
                Image.file(
                  _photoFiles[index]!,
                  fit: BoxFit.contain,
                ),
              if (_photoFiles[index] == null)
                const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'No Image Selected',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _changePhotoImage(index);
                    },
                    icon: const Icon(Icons.photo, color: Colors.blue),
                    label: const Text(
                      'Change Image',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _photoFiles[index] = null;
                      });
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Delete Image',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}

// Custom TextInputFormatter for uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
