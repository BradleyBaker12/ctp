import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/providers/vehicles_provider.dart';
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

class TrailerUploadTabs extends StatefulWidget {
  final bool isDuplicating; // Add this parameter
  final Vehicle? vehicle;
  const TrailerUploadTabs(
      {super.key, this.vehicle, this.isDuplicating = false});

  @override
  _TrailerUploadTabsState createState() => _TrailerUploadTabsState();
}

class _TrailerUploadTabsState extends State<TrailerUploadTabs>
    with TickerProviderStateMixin {
  // Colors
  final Color orange = const Color(0xFFFF4E00);
  final Color blue = const Color(0xFF2F7FFF);
  final Color green = const Color(0xFF4CAF50);

  // Scroll and Tab Controllers
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  // Image height settings
  double _imageHeight = 300.0; // Initial height of the image
  final double _minImageHeight = 150.0; // Minimum height when scrolled

  // TextEditing Controllers
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _makeController = TextEditingController(); // New
  final TextEditingController _modelController = TextEditingController(); // New
  final TextEditingController _expectedSellingPriceController =
      TextEditingController();
  final TextEditingController _vinNumberController = TextEditingController();
  final TextEditingController _trailerTypeController = TextEditingController();
  final TextEditingController _axlesController = TextEditingController(); // New
  final TextEditingController _trailerLengthController =
      TextEditingController();
  final TextEditingController _registrationNumberController =
      TextEditingController();
  final TextEditingController _availableDateController =
      TextEditingController();

  // Form and state management
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(7, (index) => GlobalKey<FormState>());
  List<bool> _isSectionCompleted = List.generate(7, (index) => false);

  bool _isSubmitting = false; // Manage loading state
  bool _isSection1Completed = false; // To check if Section 1 is completed
  bool _isLoading = false; // General loading state

  // Vehicle attributes
  String? _vehicleId; // Document ID (vehicleId) of the current vehicle
  String? _selectedMileage;
  String _suspension = 'Spring';
  String? _listDamages = 'yes'; // Store radio button selection
  DateTime? _availableDate;
  final String _maintenance = 'yes';
  final String _oemInspection = 'yes';
  final String _warranty = 'yes';
  final String _firstOwner = 'yes';
  final String _accidentFree = 'yes';
  final String _roadWorthy = 'yes';
  final String? _outstandingSettlement = 'yes';
  final String? _damagesOrFaults = 'yes';
  final String? _includeTyreInfo = 'yes';
  final String? _vehicleAvailableImmediately = 'yes';
  String _vehicleType = 'trailer';
  String _weightClass = 'heavy';
  String? _settleBeforeSelling;
  String? _mainImageUrl;
  String? _hydraulics = 'yes';

  // State management for UI sections
  bool _showSettlementTab = false;
  bool _showDamagesFaultsTab = false;
  bool _showTyresTab = false;

  // Tyre and tread information
  final String _tyreType = 'virgin';
  final String _treadLeft = '';
  final String _spareTyre = 'yes';

  // Files for uploads
  File? _proxyFile;
  File? _rc1File;
  File? _brncFile;
  File? _serviceHistoryFile;

  // Multiple Images for uploads
  List<File> _frontTrailerImages = [];
  List<File> _additionalImages1 = [];
  List<File> _additionalImages2 = [];
  List<File> _additionalImages3 = [];
  List<File> _damageImages = [];

  // Damage entries
  List<Map<String, dynamic>> _damageEntries = [];

  // Firebase and formatters
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NumberFormat _numberFormat = NumberFormat("#,##0", "en_US");
  final bool _showCurrencySymbol = false;

  // Tab count calculation
  int _calculateTabCount() {
    int count =
        4; // Mandatory Section, Additional Information, RC1/NATIS, and Additional Photos are always shown
    if (_showSettlementTab) count++;
    if (_showDamagesFaultsTab) count++;
    if (_showTyresTab) count++;
    return count;
  }

  @override
  void initState() {
    super.initState();
    _showSettlementTab = _outstandingSettlement == 'yes';
    _showDamagesFaultsTab = _damagesOrFaults == 'yes';
    _showTyresTab = _includeTyreInfo == 'yes';
    _tabController = TabController(
      length: _calculateTabCount(),
      vsync: this,
    );

    // Reset selectedMainImage at the start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final formData = Provider.of<FormDataProvider>(context, listen: false);
      formData.setSelectedMainImage(null);
    });

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (_tabController.index != 0) {
            if (!_formKeys[0].currentState!.validate()) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:
                      Text('Please complete Section 1 before proceeding.')));
              _tabController.animateTo(0);
            } else {
              // Save Section 1 data
              await _saveSection1Data();
              if (_vehicleId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('Error saving Section 1. Please try again.')));
                _tabController.animateTo(0);
              }
            }
          }
        });
      }
    });

    // Prepopulate fields if vehicle data is provided (for duplication or editing)
    if (widget.vehicle != null) {
      _yearController.text = widget.vehicle!.year ?? '';
      _makeController.text = widget.vehicle!.makeModel ?? '';
      _vinNumberController.text = widget.vehicle!.vinNumber ?? '';
      _trailerTypeController.text = widget.vehicle!.trailerType ?? '';
      _axlesController.text = widget.vehicle!.axles ?? '';
      _trailerLengthController.text = widget.vehicle!.trailerLength ?? '';
      _registrationNumberController.text =
          widget.vehicle!.registrationNumber ?? '';
      _expectedSellingPriceController.text =
          widget.vehicle!.expectedSellingPrice ?? '';

      // Ensure that _suspension has a valid value
      List<String> suspensionOptions = ['Spring', 'Air'];
      _suspension = suspensionOptions.contains(widget.vehicle!.suspension)
          ? widget.vehicle!.suspension
          : 'Spring'; // Default to 'Spring' if invalid

      _hydraulics = 'yes';

      // Load main image if it's available (e.g., from URL)
      if (widget.vehicle!.mainImageUrl != null &&
          widget.vehicle!.mainImageUrl!.isNotEmpty) {
        _loadMainImageFromUrl(widget.vehicle!.mainImageUrl!);
      }

      if (widget.isDuplicating) {
        // If duplicating, do not set _vehicleId
        _vehicleId = null;
      } else {
        // If editing, set _vehicleId to the existing vehicle's ID
        _vehicleId = widget.vehicle!.id;
      }
    } else {
      // If not duplicating, reset selectedMainImage and _mainImageUrl
      final formData = Provider.of<FormDataProvider>(context, listen: false);
      formData.setSelectedMainImage(null);
      _mainImageUrl = null; // Reset the main image URL
      _vehicleId = null; // Ensure vehicleId is null for new vehicles
    }

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

  Future<void> _loadMainImageFromUrl(String url) async {
    try {
      final downloadUrl = await _storage.refFromURL(url).getDownloadURL();
      setState(() {
        _mainImageUrl = downloadUrl;
      });
    } catch (e) {
      print("Error loading image from URL: $e");
    }
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

  Future<List<String>> _uploadMultipleFiles(
      List<File> files, String storagePath) async {
    List<String> downloadUrls = [];
    for (var file in files) {
      String? url = await _uploadFile(
        file,
        '$storagePath/${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}',
      );
      if (url != null) {
        downloadUrls.add(url);
      }
    }
    return downloadUrls;
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

  Future<void> _pickMultipleImages(Function(List<File>) onImagesPicked) async {
    try {
      final List<XFile> pickedFiles = await ImagePicker().pickMultiImage();
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        List<File> images =
            pickedFiles.map((xfile) => File(xfile.path)).toList();
        onImagesPicked(images);
      }
    } catch (e) {
      print("Error picking images: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
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

      // Prepare data to save
      Map<String, dynamic> vehicleData = {
        // Trailer Information
        'vehicleType': _vehicleType,
        'year': _yearController.text,
        'make': _makeController.text,
        'model': _modelController.text,
        'vinNumber': _vinNumberController.text,
        'trailerType': _trailerTypeController.text,
        'axles': _axlesController.text,
        'trailerLength': _trailerLengthController.text,
        'registrationNumber': _registrationNumberController.text,
        'expectedSellingPrice': _expectedSellingPriceController.text,

        // Documents
        'proxyUrl': await _uploadFile(_proxyFile,
            'vehicles/${DateTime.now().millisecondsSinceEpoch}_proxy.pdf'),
        'rc1Url': await _uploadFile(_rc1File,
            'vehicles/${DateTime.now().millisecondsSinceEpoch}_rc1.pdf'),
        'brncUrl': await _uploadFile(_brncFile,
            'vehicles/${DateTime.now().millisecondsSinceEpoch}_brnc.pdf'),
        'serviceHistoryUrl': await _uploadFile(_serviceHistoryFile,
            'vehicles/${DateTime.now().millisecondsSinceEpoch}_service_history.pdf'),

        // Images
        'frontTrailerImageUrls': await _uploadMultipleFiles(
            _frontTrailerImages, 'vehicles/front_trailer_images'),
        'additionalImageUrls1': await _uploadMultipleFiles(
            _additionalImages1, 'vehicles/additional_images1'),
        'additionalImageUrls2': await _uploadMultipleFiles(
            _additionalImages2, 'vehicles/additional_images2'),
        'additionalImageUrls3': await _uploadMultipleFiles(
            _additionalImages3, 'vehicles/additional_images3'),
        'damageImageUrls':
            await _uploadMultipleFiles(_damageImages, 'vehicles/damage_images'),

        // Damage Entries
        'damageDescriptions':
            _damageEntries.map((e) => e['description']).toList(),

        // Common Fields
        'mainImageUrl': mainImageUrl,

        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Get the current user's UID
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user is signed in.')),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }
      final String userId = currentUser.uid;

      vehicleData['userId'] = userId;
      vehicleData['vehicleStatus'] = 'Draft';
      vehicleData['createdAt'] = FieldValue.serverTimestamp();

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
    _makeController.clear();
    _modelController.clear();
    _vinNumberController.clear();
    _trailerTypeController.clear();
    _axlesController.clear();
    _trailerLengthController.clear();
    _registrationNumberController.clear();
    _expectedSellingPriceController.clear();

    // Reset variables
    _vehicleId = null;
    _selectedMileage = null;
    _suspension = 'Spring';
    _isLoading = false;
    _listDamages = 'yes';

    _vehicleType = 'trailer';
    _weightClass = 'heavy';
    _settleBeforeSelling = null;

    // Reset section completion
    _isSection1Completed = false;
    _isSectionCompleted = List.generate(7, (index) => false);

    // Reset images and files
    _proxyFile = null;
    _rc1File = null;
    _brncFile = null;
    _serviceHistoryFile = null;

    _frontTrailerImages = [];
    _additionalImages1 = [];
    _additionalImages2 = [];
    _additionalImages3 = [];
    _damageImages = [];

    _damageEntries = [];

    // Reset FormDataProvider
    final formData = Provider.of<FormDataProvider>(context, listen: false);
    formData.setSelectedMainImage(null);
    formData.setSettlementLetterFile(null);
    formData.setSelectedLicenceDiskImage(null);
    formData.setSettleBeforeSelling('');

    // Reset main image URL
    _mainImageUrl = null; // Add this line

    // Reset TabController to the first tab
    _tabController.index = 0;
  }

  Future<void> _saveSection2Data() async {
    // Since "Additional Vehicle Information" section is not specified in detail,
    // you can implement this method as needed based on additional fields.
  }

  Future<void> _saveSection3Data() async {
    // If you have any data to save in Section 3, implement it here.
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
      String? proxyUrl;
      String? rc1Url;
      String? brncUrl;
      String? serviceHistoryUrl;

      if (_proxyFile != null) {
        proxyUrl = await _uploadFile(
          _proxyFile,
          'vehicles/${DateTime.now().millisecondsSinceEpoch}_proxy.pdf',
        );
      }

      if (_rc1File != null) {
        rc1Url = await _uploadFile(
          _rc1File,
          'vehicles/${DateTime.now().millisecondsSinceEpoch}_rc1.pdf',
        );
      }

      if (_brncFile != null) {
        brncUrl = await _uploadFile(
          _brncFile,
          'vehicles/${DateTime.now().millisecondsSinceEpoch}_brnc.pdf',
        );
      }

      if (_serviceHistoryFile != null) {
        serviceHistoryUrl = await _uploadFile(
          _serviceHistoryFile,
          'vehicles/${DateTime.now().millisecondsSinceEpoch}_service_history.pdf',
        );
      }

      Map<String, dynamic> section4Data = {
        'proxyUrl': proxyUrl,
        'rc1Url': rc1Url,
        'brncUrl': brncUrl,
        'serviceHistoryUrl': serviceHistoryUrl,
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
    // Implement saving of damages and faults data if necessary.
  }

  Future<void> _saveSection6Data() async {
    // Implement saving of tyre information if necessary.
  }

  Future<void> _saveSection7Data() async {
    // Implement saving of uploaded images if necessary.
  }

  Future<void> _pickFile(Function(File?) onFilePicked) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      onFilePicked(file);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
    }
  }

  Future<void> _pickFileForDamageImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );

    if (result != null) {
      List<File> files = result.paths.map((path) => File(path!)).toList();
      setState(() {
        _damageImages.addAll(files);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No files selected')),
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
      QuerySnapshot existingVIN = await _firestore
          .collection('vehicles')
          .where('vinNumber', isEqualTo: _vinNumberController.text)
          .get();

      bool vinExists = false;
      for (var doc in existingVIN.docs) {
        if (doc.id != _vehicleId) {
          vinExists = true;
          break;
        }
      }

      if (vinExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('A vehicle with this VIN number already exists.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      // Access the selectedMainImage from the provider
      final formData = Provider.of<FormDataProvider>(context, listen: false);
      print('selectedMainImage: ${formData.selectedMainImage}');
      print('_mainImageUrl: $_mainImageUrl');
      String? mainImageUrl;
      if (formData.selectedMainImage != null) {
        // Upload the main image
        mainImageUrl = await _uploadFile(
          formData.selectedMainImage,
          'vehicles/${DateTime.now().millisecondsSinceEpoch}_main.jpg',
        );
      } else if (_mainImageUrl != null) {
        // Use the existing main image URL
        mainImageUrl = _mainImageUrl;
      } else {
        // If no main image is selected or existing, prompt the user
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
        'userId': userId,
        'vehicleType': _vehicleType,
        'year': _yearController.text,
        'make': _makeController.text,
        'model': _modelController.text,
        'vinNumber': _vinNumberController.text,
        'trailerType': _trailerTypeController.text,
        'axles': _axlesController.text,
        'trailerLength': _trailerLengthController.text,
        'registrationNumber': _registrationNumberController.text,
        'expectedSellingPrice': _expectedSellingPriceController.text,
        'availableDate': _availableDate != null
            ? DateFormat('yyyy-MM-dd').format(_availableDate!)
            : null,
        'mainImageUrl': mainImageUrl,
        'vehicleStatus': 'Draft',
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

  // Function to show the date picker
  Future<void> _selectAvailableDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (pickedDate != null) {
      setState(() {
        _availableDate = pickedDate;
        // Display date as '02 October 2024'
        _availableDateController.text =
            DateFormat('dd MMMM yyyy').format(pickedDate);
      });
    }
  }

  List<Tab> _buildTabs() {
    List<Tab> tabs = [
      const Tab(text: 'Trailer Information'),
      const Tab(text: 'Additional Vehicle Information'),
      const Tab(text: 'Required Documents'),
      const Tab(text: 'Upload Images'),
      const Tab(text: 'Damages'),
    ];
    return tabs;
  }

  List<Widget> _buildTabViews() {
    List<Widget> tabViews = [
      _buildSection1(orange, blue, green),
      _buildSection2(orange, blue, green),
      _buildSection4(orange, blue, green),
      _buildSection7(orange, blue, green),
      _buildSection5(orange, blue, green),
    ];
    return tabViews;
  }

  @override
  Widget build(BuildContext context) {
    var orange = const Color(0xFFFF4E00);
    var blue = const Color(0xFF2F7FFF);
    var green = const Color(0xFF4CAF50);

    // Access the selectedMainImage from the provider
    final formData = Provider.of<FormDataProvider>(context);
    File? selectedMainImage = formData.selectedMainImage;

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
                  tabs: _buildTabs(),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  onTap: (index) {
                    if (index != 0) {
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
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
                      });
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
                          child: selectedMainImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10.0),
                                  child: Image.file(
                                    selectedMainImage,
                                    width: double.infinity,
                                    height:
                                        _imageHeight, // Use _imageHeight here
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : (_mainImageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10.0),
                                      child: Image.network(
                                        _mainImageUrl!,
                                        width: double.infinity,
                                        height: _imageHeight,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : GestureDetector(
                                      onTap: () {
                                        _showImageSourceDialog(
                                            (ImageSource source) {
                                          _pickImageFromSource(source, (image) {
                                            formData
                                                .setSelectedMainImage(image);
                                          });
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(10.0),
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
                                                    _pickImageFromSource(
                                                        ImageSource.camera,
                                                        (image) {
                                                      formData
                                                          .setSelectedMainImage(
                                                              image);
                                                    });
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
                                                    _pickImageFromSource(
                                                        ImageSource.gallery,
                                                        (image) {
                                                      formData
                                                          .setSelectedMainImage(
                                                              image);
                                                    });
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
                                    )),
                        ),
                      ],
                    ),
                    // Wrap TabBarView in a Container to set its height
                    SizedBox(
                      height: MediaQuery.of(context).size.height -
                          _imageHeight -
                          kToolbarHeight -
                          kBottomNavigationBarHeight,
                      child: TabBarView(
                        controller: _tabController,
                        physics: _isSection1Completed
                            ? null
                            : const NeverScrollableScrollPhysics(),
                        children: _buildTabViews(),
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

  void _updateTabController() {
    int tabCount = _calculateTabCount();

    int oldIndex = _tabController.index;

    // Dispose of the old TabController
    _tabController.dispose();

    // Create a new TabController
    _tabController = TabController(length: tabCount, vsync: this);

    // Set the index to the previous position if possible
    if (oldIndex >= tabCount) {
      _tabController.index = tabCount - 1;
    } else {
      _tabController.index = oldIndex;
    }

    // If you need to call setState(), ensure it's safe to do so
    if (mounted) {
      setState(() {});
    }
  }

  int _getNextTabIndex(int currentIndex) {
    int nextIndex = currentIndex + 1;

    // Skip Settlement tab if it's not shown
    if (!_showSettlementTab && currentIndex == 1) nextIndex++;
    // Skip RC1/NATIS tab if it's not shown
    if (!_showDamagesFaultsTab && currentIndex == 2) nextIndex++;
    // Skip Tyres tab if it's not shown
    if (!_showTyresTab && currentIndex == 3) nextIndex++;

    return nextIndex;
  }

  Widget _buildSection1(Color orange, Color blue, Color green) {
    return _buildSectionWithGradient(
      orange,
      blue,
      green,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKeys[0],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // Section Title
                Center(
                  child: Text(
                    'TRAILER INFORMATION',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 20),

                // Trailer Type
                _buildTextField(
                  controller: _trailerTypeController,
                  hintText: 'Trailer Type',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the Trailer Type';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // Year and Make
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
                        controller: _makeController,
                        hintText: 'Make',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the make';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Model
                _buildTextField(
                  controller: _modelController,
                  hintText: 'Model',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the model';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // Length Trailer
                _buildTextField(
                  controller: _trailerLengthController,
                  hintText: 'Length Trailer',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the trailer length';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // Registration Number
                _buildTextField(
                  controller: _registrationNumberController,
                  hintText: 'Registration Number',
                  inputFormatter: [UpperCaseTextFormatter()],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the registration number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // Axles
                _buildTextField(
                  controller: _axlesController,
                  hintText: 'Axles',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the axles';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // VIN Number
                _buildTextField(
                  controller: _vinNumberController,
                  hintText: 'VIN Number',
                  inputFormatter: [UpperCaseTextFormatter()],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the VIN number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // Expected Selling Price (Ex Vat)
                _buildTextField(
                  controller: _expectedSellingPriceController,
                  hintText: 'Expected Selling Price (Ex Vat)',
                  isCurrency: true,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the expected selling price';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Center(
                  child: Column(
                    children: [
                      CustomButton(
                        text: 'Next',
                        borderColor: blue,
                        onPressed: () async {
                          if (!_formKeys[0].currentState!.validate()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please fill in all required fields in Section 1.',
                                ),
                              ),
                            );
                            return;
                          } else {
                            await _saveSection1Data();
                            if (_vehicleId != null) {
                              int nextIndex =
                                  _getNextTabIndex(_tabController.index);
                              _tabController.animateTo(nextIndex);
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
                                          'Please fill in all required fields in Section 1.',
                                        ),
                                      ),
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
                  'ADDITIONAL VEHICLE INFORMATION',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Implement additional fields if any.
              // Since no specific fields are provided for this section,
              // you can add any additional fields you need here.

              // Action Buttons
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
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      1,
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
                  'REQUIRED DOCUMENTS',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),

              _buildFileUploadField('Upload Proxy', _proxyFile, (file) {
                setState(() {
                  _proxyFile = file;
                });
              }),

              const SizedBox(height: 10),

              _buildFileUploadField('Upload RC1', _rc1File, (file) {
                setState(() {
                  _rc1File = file;
                });
              }),

              const SizedBox(height: 10),

              _buildFileUploadField('Upload BRNC', _brncFile, (file) {
                setState(() {
                  _brncFile = file;
                });
              }),

              const SizedBox(height: 10),

              _buildFileUploadField(
                  'Upload Service History If Available', _serviceHistoryFile,
                  (file) {
                setState(() {
                  _serviceHistoryFile = file;
                });
              }),

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
                                    'Please fill in all required fields in Section 3.')),
                          );
                          return;
                        } else {
                          await _saveSection4Data();
                          if (_vehicleId != null) {
                            _tabController.animateTo(3); // move to next tab
                          }
                        }
                      },
                    ),
                    if (_tabController.index ==
                        3) // Show the Done button for section 3
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
      3,
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
                  'DAMAGES',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              _buildDamageEntriesSection(),
              const SizedBox(height: 20),
              // Add Next and Done buttons here
              Center(
                child: Column(
                  children: [
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
      4,
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
                  'UPLOAD IMAGES',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              _buildMultipleImageUploadSection(
                'Front Trailer Images',
                _frontTrailerImages,
                (images) {
                  setState(() {
                    _frontTrailerImages = images;
                  });
                },
              ),
              const SizedBox(height: 10),
              _buildMultipleImageUploadSection(
                'Additional Images 1',
                _additionalImages1,
                (images) {
                  setState(() {
                    _additionalImages1 = images;
                  });
                },
              ),
              const SizedBox(height: 10),
              _buildMultipleImageUploadSection(
                'Additional Images 2',
                _additionalImages2,
                (images) {
                  setState(() {
                    _additionalImages2 = images;
                  });
                },
              ),
              const SizedBox(height: 10),
              _buildMultipleImageUploadSection(
                'Additional Images 3',
                _additionalImages3,
                (images) {
                  setState(() {
                    _additionalImages3 = images;
                  });
                },
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
                        if (!_formKeys[6].currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Please fill in all required fields in Section 4.')),
                          );
                          return;
                        } else {
                          await _saveSection7Data();
                          if (_vehicleId != null) {
                            _tabController.animateTo(4); // move to next tab
                          }
                        }
                      },
                    ),
                    if (_tabController.index ==
                        6) // Show the Done button for section 4
                      CustomButton(
                        text: 'Done',
                        borderColor: orange,
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (!_formKeys[6].currentState!.validate()) {
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
      6,
    );
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool isCurrency = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatter,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization =
        TextCapitalization.none, // New Parameter
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
      textCapitalization: textCapitalization, // Apply Text Capitalization
      cursorColor: const Color(0xFFFF4E00), // Orange cursor color
      decoration: InputDecoration(
        hintText: _capitalizeHintText(
            hintText), // Ensure Proper Hint Text Capitalization
        prefixText: isCurrency ? 'R ' : '',
        prefixStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
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

  String _capitalizeHintText(String hint) {
    if (hint.isEmpty) return hint;
    return hint[0].toUpperCase() + hint.substring(1);
  }

  Widget _buildFileUploadField(
      String label, File? file, Function(File?) onFilePicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _pickFile(onFilePicked),
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.white70, width: 1),
            ),
            child: Center(
              child: file == null
                  ? const Icon(Icons.folder_open, color: Colors.blue, size: 40)
                  : Text(
                      path.basename(file.path),
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultipleImageUploadSection(
      String label, List<File> images, Function(List<File>) onImagesPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _pickMultipleImages(onImagesPicked),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.white70, width: 1),
            ),
            child: images.isEmpty
                ? const Center(
                    child: Icon(Icons.add_photo_alternate,
                        color: Colors.blue, size: 40),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Stack(
                          children: [
                            Image.file(
                              images[index],
                              fit: BoxFit.cover,
                              width: 100,
                              height: 100,
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    images.removeAt(index);
                                  });
                                },
                                child: Icon(Icons.remove_circle,
                                    color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildDamageEntriesSection() {
    return Column(
      children: [
        const Center(
          child: Text(
            'List Current Damages',
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
            _pickDamageImage(index);
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
                  : Image.file(
                      _damageEntries[index]['photo'],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Divider(color: Colors.white54),
      ],
    );
  }

  void _removeDamageEntry(int index) {
    setState(() {
      _damageEntries.removeAt(index);
    });
  }

  void _pickDamageImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _damageEntries[index]['photo'] = File(pickedFile.path);
      });
    }
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
