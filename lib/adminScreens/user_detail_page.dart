// user_detail_page.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/adminScreens/viewer_page.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/user_provider.dart';

import 'package:auto_route/auto_route.dart';

@RoutePage()
class UserDetailPage extends StatefulWidget {
  final String userId;

  const UserDetailPage({super.key, required this.userId});

  @override
  _UserDetailPageState createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for basic details.
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _tradingNameController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  // Controllers for additional fields.
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _registrationNumberController =
      TextEditingController();
  final TextEditingController _vatNumberController = TextEditingController();
  // OEM brand controller (only used when role is 'oem')
  final TextEditingController _oemBrandController = TextEditingController();
  // OEM org fields (companyId removed)
  bool _isOemManagerFlag = false;
  String? _selectedOemManagerId;
  // Trade-In brand controller (mirror OEM)
  final TextEditingController _tradeInBrandController = TextEditingController();
  // Trade-In org fields
  bool _isTradeInManagerFlag = false;
  String? _selectedTradeInManagerId;

  // Dropdown state variables.
  String _accountStatus = 'active'; // default value.
  String _userRole =
      'dealer'; // default value; options vary by current user's role

  // Holds the selected Sales Representative (document ID)
  String? _selectedSalesRep;

  File? _profileImage;

  // Flag to check if controllers are initialized.
  bool _isControllersInitialized = false;

  // Define valid account status options
  final List<String> _accountStatusOptions = [
    'active',
    'suspended',
    'deactivated',
    'inactive',
    'archived',
  ];

  // Add loading state variables
  final Map<String, bool> _isUploading = {
    'bankConfirmationUrl': false,
    'proxyUrl': false,
    'brncUrl': false,
    'cipcCertificateUrl': false,
    'profileImage': false,
    'taxCertificateUrl': false,
  };

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _companyNameController.dispose();
    _tradingNameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _registrationNumberController.dispose();
    _vatNumberController.dispose();
    _oemBrandController.dispose();
    _tradeInBrandController.dispose();
    super.dispose();
  }

  /// Pick a new profile image from the gallery.
  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error picking image: $e', style: GoogleFonts.montserrat()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Upload the profile image to Firebase Storage.
  Future<String> _uploadProfileImage(File imageFile) async {
    String fileName =
        'profile_images/${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.png';
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = storageRef.putFile(imageFile);

    try {
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Image upload failed');
    }
  }

  /// Synchronize manager <-> employee linkage for OEM hierarchy.
  /// Maintains an array field `oemEmployeeIds` on manager documents.
  Future<void> _syncManagerEmployeeLinks({
    required String? oldManagerId,
    required String? newManagerId,
    required bool oldIsManager,
    required bool newIsManager,
  }) async {
    final usersCol = FirebaseFirestore.instance.collection('users');
    final currentUserId = widget.userId;

    WriteBatch batch = FirebaseFirestore.instance.batch();

    // If user was previously assigned to a manager (and either manager changed or user became a manager), remove from old manager list.
    if (oldManagerId != null &&
        oldManagerId.isNotEmpty &&
        (oldManagerId != newManagerId || newIsManager)) {
      batch.update(usersCol.doc(oldManagerId), {
        'oemEmployeeIds': FieldValue.arrayRemove([currentUserId])
      });
    }

    // If user is now an employee (not a manager) and has a manager, add to new manager list.
    if (!newIsManager && newManagerId != null && newManagerId.isNotEmpty) {
      batch.update(usersCol.doc(newManagerId), {
        'oemEmployeeIds': FieldValue.arrayUnion([currentUserId])
      });
    }

    // If user transitioned from manager to employee, nothing special besides above.
    // If user transitioned to manager (newIsManager) we keep their existing oemEmployeeIds array (or create empty) – ensure field exists.
    if (newIsManager && !oldIsManager) {
      batch.set(
          usersCol.doc(currentUserId),
          {
            'oemEmployeeIds': FieldValue.arrayUnion([]),
          },
          SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Save the changes in the form and update Firestore.
  Future<void> _saveChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Fetch current doc to compute diff for manager linkage before update.
        DocumentSnapshot preUpdateSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();
        final preData = preUpdateSnap.data() as Map<String, dynamic>? ?? {};
        final String? oldManagerId = preData['managerId'] as String?;
        final bool oldIsManager = preData['isOemManager'] == true;

        String? profileImageUrl;
        if (_profileImage != null) {
          profileImageUrl = await _uploadProfileImage(_profileImage!);
        }

        // Access current user details from UserProvider.
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        // If the currently logged-in user is a sales rep, then assign the current rep's id.
        if (userProvider.getUserRole == 'sales representative') {
          _selectedSalesRep = userProvider.userId;
        }

        Map<String, dynamic> updateData = {
          'accountStatus': _accountStatus,
          'firstName': _firstNameController.text,
          'middleName': _middleNameController.text,
          'lastName': _lastNameController.text,
          'email': _emailController.text,
          'phoneNumber': _phoneNumberController.text,
          'companyName': _companyNameController.text,
          'tradingName': _tradingNameController.text,
          'addressLine1': _addressLine1Controller.text,
          'addressLine2': _addressLine2Controller.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'postalCode': _postalCodeController.text,
          'country': _countryController.text,
          'registrationNumber': _registrationNumberController.text,
          'userRole': _userRole,
          'vatNumber': _vatNumberController.text,
        };

        // Only include assignedSalesRep if user is a dealer, transporter or oem
        if (_userRole == 'dealer' ||
            _userRole == 'transporter' ||
            _userRole == 'oem') {
          updateData['assignedSalesRep'] = _selectedSalesRep;
        } else {
          // Remove assignedSalesRep field for admin and sales rep roles
          updateData['assignedSalesRep'] = null;
        }

        // Persist OEM brand and org fields when applicable; clear it otherwise
        if (_userRole == 'oem') {
          updateData['oemBrand'] = _oemBrandController.text;
          updateData['isOemManager'] = _isOemManagerFlag;
          if (_isOemManagerFlag) {
            updateData['managerId'] = null;
          } else {
            updateData['managerId'] = _selectedOemManagerId;
          }
        } else {
          updateData['oemBrand'] = null;
          updateData['isOemManager'] = null;
          updateData['managerId'] = null;
        }

        // Persist Trade-In brand and org fields when applicable; clear otherwise
        if (_userRole == 'tradein' || _userRole == 'trade-in') {
          updateData['tradeInBrand'] = _tradeInBrandController.text;
          updateData['isTradeInManager'] = _isTradeInManagerFlag;
          if (_isTradeInManagerFlag) {
            updateData['tradeInManagerId'] = null;
          } else {
            updateData['tradeInManagerId'] = _selectedTradeInManagerId;
          }
        } else {
          updateData['tradeInBrand'] = null;
          updateData['isTradeInManager'] = null;
          updateData['tradeInManagerId'] = null;
        }

        if (profileImageUrl != null) {
          updateData['profileImageUrl'] = profileImageUrl;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update(updateData);

        // After user doc update, sync manager employee linkage if OEM or Trade-In role involved in either old or new state.
        if (_userRole == 'oem' || preData['userRole'] == 'oem') {
          await _syncManagerEmployeeLinks(
            oldManagerId: oldManagerId,
            newManagerId: _isOemManagerFlag ? null : _selectedOemManagerId,
            oldIsManager: oldIsManager,
            newIsManager: _isOemManagerFlag,
          );
        }

        // Trade-In manager sync: compute previous trade-in manager state
        final String? oldTradeInManagerId =
            preData['tradeInManagerId'] as String?;
        final bool oldIsTradeInManager = preData['isTradeInManager'] == true;
        if ((_userRole == 'tradein' || _userRole == 'trade-in') ||
            (preData['userRole'] == 'tradein' ||
                preData['userRole'] == 'trade-in')) {
          await _syncManagerEmployeeLinks(
            oldManagerId: oldTradeInManagerId,
            newManagerId:
                _isTradeInManagerFlag ? null : _selectedTradeInManagerId,
            oldIsManager: oldIsTradeInManager,
            newIsManager: _isTradeInManagerFlag,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User details updated successfully.',
                style: GoogleFonts.montserrat()),
          ),
        );
      } catch (e) {
        print('Error saving changes: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update user details.',
                style: GoogleFonts.montserrat()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Archive the user by setting accountStatus to 'archived'
  Future<void> _archiveUser() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'accountStatus': 'archived'});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User has been archived.',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _accountStatus = 'archived');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to archive user: $e',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// View a document using the ViewerPage.
  Future<void> _viewDocument(String url, String title) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ViewerPage(url: url)),
    );
  }

  /// Helper method to upload a document file.
  Future<String> _uploadDocument(
      Uint8List file, String fieldName, String originalFileName) async {
    String extension = originalFileName.split('.').last.toLowerCase();
    String fileName =
        'documents/${widget.userId}_${fieldName}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = storageRef.putData(file);

    try {
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading document: $e');
      throw Exception('Document upload failed');
    }
  }

  /// Pick a document using file_picker, upload it and update the Firestore field.
  Future<void> _pickAndUploadDocument(String fieldName) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'doc',
          'docx',
          'xls',
          'xlsx'
        ],
      );

      if (result != null) {
        setState(() {
          _isUploading[fieldName] = true;
        });

        final fileInfo = result.files.first;
        Uint8List bytes;
        // Check if bytes are provided (typically on web)
        if (fileInfo.bytes != null) {
          bytes = fileInfo.bytes!;
        } else if (fileInfo.path != null) {
          // On mobile, read the file from the provided path
          bytes = await File(fileInfo.path!).readAsBytes();
        } else {
          throw Exception("Cannot retrieve file data.");
        }

        final fileName = fileInfo.name;
        String docUrl = await _uploadDocument(bytes, fieldName, fileName);

        // Create document metadata
        Map<String, dynamic> documentData = {
          fieldName: docUrl,
          '${fieldName}Meta': {
            'fileName': fileName,
            'uploadDate': FieldValue.serverTimestamp(),
            'uploadedBy':
                Provider.of<UserProvider>(context, listen: false).userId,
            'fileType': fileName.split('.').last.toLowerCase(),
          }
        };

        // Update Firestore with both URL and metadata
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update(documentData);

        // Force rebuild of the widget
        setState(() {
          _isUploading[fieldName] = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fieldName updated successfully.',
                style: GoogleFonts.montserrat()),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading[fieldName] = false;
      });
      print('Error uploading document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update $fieldName.',
              style: GoogleFonts.montserrat()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Helper method to fetch Sales Representatives and Admins from Firestore.
  Future<QuerySnapshot> _fetchSalesReps() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('userRole', whereIn: ['sales representative', 'admin']).get();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String currentUserRole = userProvider.getUserRole;
    final bool isAdmin = currentUserRole == 'admin';
    final bool isSalesRep = currentUserRole == 'sales representative';

    // Determine allowed user roles based on current user's role.
    // Admin: transporter, dealer, oem, admin.
    // Sales rep: transporter, dealer. If editing an OEM account, include 'oem' to preserve value display.
    List<String> roleOptions = isAdmin
        ? ['transporter', 'dealer', 'oem', 'tradein', 'admin']
        : ['transporter', 'dealer'];

    // If logged in user is a sales rep and no sales rep is assigned, assign current rep id.
    if (isSalesRep &&
        (_selectedSalesRep == null || _selectedSalesRep!.isEmpty)) {
      _selectedSalesRep = userProvider.userId;
    }

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('User Details',
              style: GoogleFonts.montserrat(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error fetching user details.',
                    style: GoogleFonts.montserrat(color: Colors.white)),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Text('User not found.',
                    style: GoogleFonts.montserrat(color: Colors.white)),
              );
            }

            Map<String, dynamic> data =
                snapshot.data!.data() as Map<String, dynamic>;

            // Initialize controllers once.
            if (!_isControllersInitialized) {
              _firstNameController.text = data['firstName'] ?? '';
              _middleNameController.text = data['middleName'] ?? '';
              _lastNameController.text = data['lastName'] ?? '';
              _emailController.text = data['email'] ?? '';
              _phoneNumberController.text = data['phoneNumber'] ?? '';
              _companyNameController.text = data['companyName'] ?? '';
              _tradingNameController.text = data['tradingName'] ?? '';
              _addressLine1Controller.text = data['addressLine1'] ?? '';
              _addressLine2Controller.text = data['addressLine2'] ?? '';
              _cityController.text = data['city'] ?? '';
              _stateController.text = data['state'] ?? '';
              _postalCodeController.text = data['postalCode'] ?? '';

              _countryController.text = data['country'] ?? '';
              _registrationNumberController.text =
                  data['registrationNumber'] ?? '';
              _vatNumberController.text = data['vatNumber'] ?? '';

              // Initialize account status with proper validation
              String? storedStatus = data['accountStatus']?.toString();
              _accountStatus = _accountStatusOptions.contains(storedStatus)
                  ? storedStatus!
                  : _accountStatusOptions.first;

              // Initialize user role with proper null check and validation
              String? storedRole = data['userRole']?.toString();
              if (storedRole != null &&
                  [
                    'transporter',
                    'dealer',
                    'admin',
                    'sales representative',
                    'oem',
                    'tradein',
                    'trade-in'
                  ].contains(storedRole)) {
                _userRole = storedRole;
              } else {
                _userRole = 'dealer'; // Default value if invalid or null
              }

              // Initialize assigned Sales Representative with null check
              _selectedSalesRep = data['assignedSalesRep']?.toString();

              // Initialize OEM brand
              _oemBrandController.text = data['oemBrand']?.toString() ?? '';
              // Initialize OEM org fields
              _isOemManagerFlag = data['isOemManager'] == true;
              _selectedOemManagerId = data['managerId']?.toString();

              // Initialize Trade-In brand
              _tradeInBrandController.text =
                  data['tradeInBrand']?.toString() ?? '';
              // Initialize Trade-In org fields
              _isTradeInManagerFlag = data['isTradeInManager'] == true;
              _selectedTradeInManagerId = data['tradeInManagerId']?.toString();

              // Ensure role dropdown shows 'oem' for non-admins when viewing an OEM account
              if (!isAdmin &&
                  (_userRole == 'oem' ||
                      _userRole == 'tradein' ||
                      _userRole == 'trade-in') &&
                  !roleOptions.contains(_userRole)) {
                roleOptions = [...roleOptions, _userRole];
              }

              _isControllersInitialized = true;
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: constraints.maxWidth),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Image and Account Status at the Top.
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Profile Image.
                                Stack(
                                  children: [
                                    ClipOval(
                                      child: _profileImage != null
                                          ? Image.file(
                                              _profileImage!,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            )
                                          : (data['profileImageUrl'] != null &&
                                                  data['profileImageUrl']
                                                      .isNotEmpty
                                              ? FadeInImage.assetNetwork(
                                                  placeholder:
                                                      'lib/assets/default-profile-photo.jpg',
                                                  image:
                                                      data['profileImageUrl'],
                                                  width: 100,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                  imageErrorBuilder: (context,
                                                      error, stackTrace) {
                                                    return Image.asset(
                                                      'lib/assets/default-profile-photo.jpg',
                                                      width: 100,
                                                      height: 100,
                                                      fit: BoxFit.cover,
                                                    );
                                                  },
                                                )
                                              : Image.asset(
                                                  'lib/assets/default-profile-photo.jpg',
                                                  width: 100,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                )),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: InkWell(
                                        onTap: _pickImage,
                                        child: CircleAvatar(
                                          radius: 15,
                                          backgroundColor: Colors.blue,
                                          child: Icon(
                                            Icons.edit,
                                            size: 15,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 20),
                                // Account Status dropdown and Verification switch.
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Account Status',
                                        style: GoogleFonts.montserrat(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                      SizedBox(height: 5),
                                      DropdownButtonFormField<String>(
                                        initialValue: _accountStatusOptions
                                                .contains(_accountStatus)
                                            ? _accountStatus
                                            : _accountStatusOptions.first,
                                        dropdownColor: Colors.grey[800],
                                        style: GoogleFonts.montserrat(
                                            color: Colors.white),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.grey[800],
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.white70),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: AppColors.orange),
                                          ),
                                        ),
                                        items: _accountStatusOptions
                                            .map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(
                                              value.toUpperCase(),
                                              style: GoogleFonts.montserrat(
                                                  color: Colors.white),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (newValue) async {
                                          if (newValue != null) {
                                            setState(() {
                                              _accountStatus = newValue;
                                            });
                                            try {
                                              await FirebaseFirestore.instance
                                                  .collection('users')
                                                  .doc(widget.userId)
                                                  .update({
                                                'accountStatus': newValue
                                              });
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Account status updated to ${newValue.toUpperCase()}',
                                                      style: GoogleFonts
                                                          .montserrat()),
                                                ),
                                              );
                                            } catch (e) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Error updating account status: $e',
                                                      style: GoogleFonts
                                                          .montserrat()),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                      SizedBox(height: 15),
                                      Row(
                                        children: [
                                          Text(
                                            'Verification Status:',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Switch(
                                            activeThumbColor: AppColors.orange,
                                            activeTrackColor:
                                                AppColors.orange.withAlpha(150),
                                            inactiveThumbColor: Colors.grey,
                                            inactiveTrackColor:
                                                Colors.grey.shade400,
                                            value: data['isVerified'] ?? false,
                                            onChanged: (bool newValue) async {
                                              try {
                                                await FirebaseFirestore.instance
                                                    .collection('users')
                                                    .doc(widget.userId)
                                                    .update({
                                                  'isVerified': newValue,
                                                });
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      newValue
                                                          ? 'User verified successfully'
                                                          : 'User verification removed',
                                                      style: GoogleFonts
                                                          .montserrat(),
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Error updating verification status: $e',
                                                      style: GoogleFonts
                                                          .montserrat(),
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 30),
                            // User Information Section.
                            Text(
                              'User Information',
                              style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            SizedBox(height: 10),
                            _buildEditableField(
                                'First Name', _firstNameController, true),
                            _buildEditableField(
                                'Middle Name', _middleNameController, false),
                            _buildEditableField(
                                'Last Name', _lastNameController, true),
                            _buildEditableField(
                                'Email', _emailController, true),
                            _buildEditableField(
                                'Phone Number', _phoneNumberController, true),
                            _buildEditableField(
                                'Company Name', _companyNameController, false),
                            _buildEditableField(
                                'Trading Name', _tradingNameController, false),
                            _buildEditableField('Address Line 1',
                                _addressLine1Controller, false),
                            _buildEditableField('Address Line 2',
                                _addressLine2Controller, false),
                            _buildEditableField('City', _cityController, false),
                            _buildEditableField(
                                'State', _stateController, false),
                            _buildEditableField(
                                'Postal Code', _postalCodeController, false),
                            // Additional fields.
                            _buildEditableField(
                                'Country', _countryController, false),
                            _buildEditableField('Registration Number',
                                _registrationNumberController, false),
                            // User Role Dropdown with null safety
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10.0),
                              child: DropdownButtonFormField<String>(
                                initialValue: roleOptions.contains(_userRole)
                                    ? _userRole
                                    : roleOptions.first,
                                dropdownColor: Colors.grey[800],
                                style:
                                    GoogleFonts.montserrat(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'User Role',
                                  labelStyle: GoogleFonts.montserrat(
                                      color: Colors.white),
                                  filled: true,
                                  fillColor: Colors.grey[800],
                                  enabledBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white70),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: AppColors.orange),
                                  ),
                                ),
                                items: roleOptions.map((String role) {
                                  return DropdownMenuItem<String>(
                                    value: role,
                                    child: Text(
                                      role.toUpperCase(),
                                      style: GoogleFonts.montserrat(
                                          color: Colors.white),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _userRole = newValue;
                                      if (isAdmin &&
                                          !['transporter', 'dealer', 'oem']
                                              .contains(_userRole)) {
                                        _selectedSalesRep = null;
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                            // OEM Brand and Org fields (when role is 'oem')
                            if (_userRole == 'oem') ...[
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                                child: TextFormField(
                                  controller: _oemBrandController,
                                  enabled: isAdmin,
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'OEM Brand',
                                    labelStyle: GoogleFonts.montserrat(
                                        color: Colors.white),
                                    filled: true,
                                    fillColor: Colors.grey[800],
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white70),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: AppColors.orange),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (_userRole == 'oem' &&
                                        (value == null ||
                                            value.trim().isEmpty)) {
                                      return 'Please enter OEM Brand';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SwitchListTile(
                                value: _isOemManagerFlag,
                                onChanged: isAdmin
                                    ? (v) {
                                        setState(() {
                                          _isOemManagerFlag = v;
                                          if (v) _selectedOemManagerId = null;
                                        });
                                      }
                                    : null,
                                title: Text('Is OEM Manager?',
                                    style: GoogleFonts.montserrat(
                                        color: Colors.white)),
                                activeThumbColor: const Color(0xFFFF4E00),
                                contentPadding: EdgeInsets.zero,
                              ),
                              if (!_isOemManagerFlag)
                                FutureBuilder<QuerySnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .where('userRole', isEqualTo: 'oem')
                                      .where('isOemManager', isEqualTo: true)
                                      .get(),
                                  builder: (context, snap) {
                                    if (snap.connectionState ==
                                        ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    }
                                    final docs = snap.data?.docs ?? [];
                                    if (docs.isEmpty) {
                                      return Text('No OEM Managers available.',
                                          style: GoogleFonts.montserrat(
                                              color: Colors.white));
                                    }
                                    final items = docs.map((d) {
                                      final m =
                                          d.data() as Map<String, dynamic>;
                                      final name = ((m['firstName'] ?? '') +
                                              ' ' +
                                              (m['lastName'] ?? ''))
                                          .trim();
                                      return DropdownMenuItem<String>(
                                        value: d.id,
                                        child: Text(
                                          name.isEmpty ? d.id : name,
                                          style: GoogleFonts.montserrat(
                                              color: Colors.white),
                                        ),
                                      );
                                    }).toList();
                                    // Ensure the currently stored managerId actually exists in the dropdown list.
                                    // If it does not (e.g. the previously assigned manager lost manager status or was deleted),
                                    // fall back to null to satisfy DropdownButton's assertion.
                                    final safeValue =
                                        (_selectedOemManagerId != null &&
                                                items.any((item) =>
                                                    item.value ==
                                                    _selectedOemManagerId))
                                            ? _selectedOemManagerId
                                            : null;
                                    if (safeValue == null &&
                                        _selectedOemManagerId != null) {
                                      // Clear the stale selection so that a new one can be chosen without crashing.
                                      // Using setState in a post-frame callback to avoid rebuild issues during build.
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        if (mounted) {
                                          setState(() =>
                                              _selectedOemManagerId = null);
                                        }
                                      });
                                    }
                                    return DropdownButtonFormField<String>(
                                      initialValue: safeValue,
                                      dropdownColor: Colors.grey[850],
                                      style: GoogleFonts.montserrat(
                                          color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Assign OEM Manager',
                                        labelStyle: GoogleFonts.montserrat(
                                            color: Colors.white),
                                        enabledBorder:
                                            const UnderlineInputBorder(
                                          borderSide:
                                              BorderSide(color: Colors.white70),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppColors.orange),
                                        ),
                                      ),
                                      items: items,
                                      onChanged: isAdmin
                                          ? (v) => setState(
                                              () => _selectedOemManagerId = v)
                                          : null,
                                      validator: (v) {
                                        if (_userRole == 'oem' &&
                                            !_isOemManagerFlag &&
                                            (v == null || v.isEmpty)) {
                                          return 'Select OEM Manager for employee';
                                        }
                                        return null;
                                      },
                                    );
                                  },
                                ),
                            ],
                            // Trade-In Brand and Org fields (when role is 'tradein' or 'trade-in')
                            if (_userRole == 'tradein' ||
                                _userRole == 'trade-in') ...[
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                                child: TextFormField(
                                  controller: _tradeInBrandController,
                                  enabled: isAdmin,
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Trade-In Brand',
                                    labelStyle: GoogleFonts.montserrat(
                                        color: Colors.white),
                                    filled: true,
                                    fillColor: Colors.grey[800],
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.white70),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: AppColors.orange),
                                    ),
                                  ),
                                  validator: (value) {
                                    if ((_userRole == 'tradein' ||
                                            _userRole == 'trade-in') &&
                                        (value == null ||
                                            value.trim().isEmpty)) {
                                      return 'Please enter Trade-In Brand';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              SwitchListTile(
                                value: _isTradeInManagerFlag,
                                onChanged: isAdmin
                                    ? (v) {
                                        setState(() {
                                          _isTradeInManagerFlag = v;
                                          if (v) {
                                            _selectedTradeInManagerId = null;
                                          }
                                        });
                                      }
                                    : null,
                                title: Text('Is Trade-In Manager?',
                                    style: GoogleFonts.montserrat(
                                        color: Colors.white)),
                                activeThumbColor: const Color(0xFFFF4E00),
                                contentPadding: EdgeInsets.zero,
                              ),
                              if (!_isTradeInManagerFlag)
                                FutureBuilder<QuerySnapshot>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .where('userRole',
                                          whereIn: ['tradein', 'trade-in'])
                                      .where('isTradeInManager',
                                          isEqualTo: true)
                                      .get(),
                                  builder: (context, snap) {
                                    if (snap.connectionState ==
                                        ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    }
                                    final docs = snap.data?.docs ?? [];
                                    if (docs.isEmpty) {
                                      return Text(
                                          'No Trade-In Managers available.',
                                          style: GoogleFonts.montserrat(
                                              color: Colors.white));
                                    }
                                    final items = docs.map((d) {
                                      final m =
                                          d.data() as Map<String, dynamic>;
                                      final name = ((m['firstName'] ?? '') +
                                              ' ' +
                                              (m['lastName'] ?? ''))
                                          .trim();
                                      return DropdownMenuItem<String>(
                                        value: d.id,
                                        child: Text(
                                          name.isEmpty ? d.id : name,
                                          style: GoogleFonts.montserrat(
                                              color: Colors.white),
                                        ),
                                      );
                                    }).toList();
                                    final safeValue =
                                        (_selectedTradeInManagerId != null &&
                                                items.any((item) =>
                                                    item.value ==
                                                    _selectedTradeInManagerId))
                                            ? _selectedTradeInManagerId
                                            : null;
                                    if (safeValue == null &&
                                        _selectedTradeInManagerId != null) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        if (mounted) {
                                          setState(() =>
                                              _selectedTradeInManagerId = null);
                                        }
                                      });
                                    }
                                    return DropdownButtonFormField<String>(
                                      initialValue: safeValue,
                                      dropdownColor: Colors.grey[850],
                                      style: GoogleFonts.montserrat(
                                          color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Assign Trade-In Manager',
                                        labelStyle: GoogleFonts.montserrat(
                                            color: Colors.white),
                                        enabledBorder:
                                            const UnderlineInputBorder(
                                          borderSide:
                                              BorderSide(color: Colors.white70),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                              color: AppColors.orange),
                                        ),
                                      ),
                                      items: items,
                                      onChanged: isAdmin
                                          ? (v) => setState(() =>
                                              _selectedTradeInManagerId = v)
                                          : null,
                                      validator: (v) {
                                        if ((_userRole == 'tradein' ||
                                                _userRole == 'trade-in') &&
                                            !_isTradeInManagerFlag &&
                                            (v == null || v.isEmpty)) {
                                          return 'Select Trade-In Manager for employee';
                                        }
                                        return null;
                                      },
                                    );
                                  },
                                ),
                            ],
                            _buildEditableField(
                                'VAT Number', _vatNumberController, false),
                            SizedBox(height: 20),
                            // ----- Sales Representative Assignment -----
                            // Show dropdown only if the logged-in user is admin and the user being edited has transporter or dealer role.
                            if (isAdmin &&
                                (_userRole == 'transporter' ||
                                    _userRole == 'dealer' ||
                                    _userRole == 'oem'))
                              FutureBuilder<QuerySnapshot>(
                                future: _fetchSalesReps(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return Text(
                                      'No representatives or admins found.',
                                      style: GoogleFonts.montserrat(
                                          color: Colors.white),
                                    );
                                  }
                                  List<DropdownMenuItem<String>> salesRepItems =
                                      snapshot.data!.docs.map((doc) {
                                    Map<String, dynamic> repData =
                                        doc.data() as Map<String, dynamic>;
                                    String repName =
                                        repData['firstName'] ?? 'No Name';
                                    if (repData['lastName'] != null) {
                                      repName += ' ${repData['lastName']}';
                                    }
                                    // Add role indicator in brackets
                                    String role = repData['userRole'] == 'admin'
                                        ? 'Admin'
                                        : 'Sales Rep';
                                    repName += ' ($role)';

                                    return DropdownMenuItem<String>(
                                      value: doc.id,
                                      child: Text(repName,
                                          style: GoogleFonts.montserrat(
                                              color: Colors.white)),
                                    );
                                  }).toList();

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10.0),
                                    child: DropdownButtonFormField<String>(
                                      initialValue: _selectedSalesRep != null &&
                                              salesRepItems.any((item) =>
                                                  item.value ==
                                                  _selectedSalesRep)
                                          ? _selectedSalesRep
                                          : null,
                                      dropdownColor: Colors.grey[800],
                                      style: GoogleFonts.montserrat(
                                          color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText:
                                            'Assign Representative/Admin',
                                        labelStyle: GoogleFonts.montserrat(
                                            color: Colors.white),
                                        filled: true,
                                        fillColor: Colors.grey[800],
                                        border: OutlineInputBorder(),
                                      ),
                                      items: salesRepItems,
                                      onChanged: (newValue) {
                                        if (newValue != null) {
                                          setState(() {
                                            _selectedSalesRep = newValue;
                                          });
                                        }
                                      },
                                      validator: (value) {
                                        if ((_userRole == 'transporter' ||
                                                _userRole == 'dealer' ||
                                                _userRole == 'oem') &&
                                            (value == null || value.isEmpty)) {
                                          return 'Please select a representative or admin';
                                        }
                                        return null;
                                      },
                                    ),
                                  );
                                },
                              )
                            else
                              // For sales reps, no dropdown is shown; the account's assignedSalesRep is auto-assigned.
                              SizedBox.shrink(),
                            // ------------------------------------------------
                            // Documents Section.
                            Text(
                              'Documents',
                              style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            SizedBox(height: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDocumentTile(
                                    'Bank Confirmation',
                                    data['bankConfirmationUrl'],
                                    'bankConfirmationUrl'),
                                _buildDocumentTile(
                                    'Proxy', data['proxyUrl'], 'proxyUrl'),
                                _buildDocumentTile(
                                    'BRNC', data['brncUrl'], 'brncUrl'),
                                _buildDocumentTile(
                                    'CIPC Certificate',
                                    data['cipcCertificateUrl'],
                                    'cipcCertificateUrl'),
                                _buildDocumentTile(
                                    'Tax Certificate',
                                    data['taxCertificateUrl'],
                                    'taxCertificateUrl'),
                              ],
                            ),
                            if (isAdmin) ...[
                              CustomButton(
                                text: 'Archive User',
                                onPressed: _archiveUser,
                                borderColor: Colors.red,
                              ),
                              SizedBox(height: 16),
                            ],
                            CustomButton(
                              text: 'Save Changes',
                              onPressed: _saveChanges,
                              borderColor: Colors.deepOrange,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Helper method to build an editable text field.
  Widget _buildEditableField(
      String label, TextEditingController controller, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.montserrat(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.montserrat(color: Colors.white),
          filled: true,
          fillColor: Colors.grey[800],
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  /// Helper method to build a document tile.
  Widget _buildDocumentTile(
      String documentName, String? url, String fieldName) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isAdmin = userProvider.userRole == 'admin';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(documentName,
            style: GoogleFonts.montserrat(color: Colors.white)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isUploading[fieldName] == true)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  strokeWidth: 2,
                ),
              )
            else if (url != null && url.isNotEmpty)
              IconButton(
                icon: Icon(Icons.visibility, color: Colors.blue),
                onPressed: () => _viewDocument(url, documentName),
              )
            else
              Text('Not uploaded',
                  style: GoogleFonts.montserrat(color: Colors.redAccent)),
            if (isAdmin && !_isUploading[fieldName]!)
              IconButton(
                icon: Icon(Icons.upload_file, color: Colors.white),
                onPressed: () => _pickAndUploadDocument(fieldName),
              ),
          ],
        ),
      ),
    );
  }
}
