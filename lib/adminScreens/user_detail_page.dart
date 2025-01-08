// lib/adminScreens/user_detail_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../providers/user_provider.dart';

class UserDetailPage extends StatefulWidget {
  final String userId;

  const UserDetailPage({super.key, required this.userId});

  @override
  _UserDetailPageState createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers to handle form fields
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

  File? _profileImage;

  @override
  void dispose() {
    // Dispose controllers when the widget is removed from the widget tree
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
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<String> _uploadProfileImage(File imageFile) async {
    String fileName =
        'profile_images/${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.png';
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = storageRef.putFile(imageFile);

    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Handle profile image upload if a new image is selected
        String? profileImageUrl;
        if (_profileImage != null) {
          profileImageUrl = await _uploadProfileImage(_profileImage!);
        }

        // Update user information in Firestore
        Map<String, dynamic> updateData = {
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
        };

        if (profileImageUrl != null) {
          updateData['profileImageUrl'] = profileImageUrl;
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .update(updateData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User details updated successfully.',
              style: GoogleFonts.montserrat(),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update user details.',
              style: GoogleFonts.montserrat(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'User Details',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .get(),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error fetching user details.',
                  style: GoogleFonts.montserrat(color: Colors.white),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Text(
                  'User not found.',
                  style: GoogleFonts.montserrat(color: Colors.white),
                ),
              );
            }

            Map<String, dynamic> data =
                snapshot.data!.data() as Map<String, dynamic>;

            // **Handling accountStatus which might be a bool or a String**
            var accountStatusField = data['accountStatus'];
            String accountStatus;

            if (accountStatusField is String) {
              accountStatus = accountStatusField;
            } else if (accountStatusField is bool) {
              accountStatus = accountStatusField
                  ? 'active'
                  : 'inactive'; // Adjust as needed
            } else {
              accountStatus = 'active'; // Default status
            }

            // Populate controllers with the fetched data
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

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Image and Account Status at the Top
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Profile Image
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundImage: _profileImage != null
                                          ? FileImage(_profileImage!)
                                          : data['profileImageUrl'] != null
                                              ? NetworkImage(
                                                      data['profileImageUrl'])
                                                  as ImageProvider
                                              : null,
                                      backgroundColor: Colors.grey,
                                      child: _profileImage == null &&
                                              data['profileImageUrl'] == null
                                          ? Icon(
                                              Icons.person,
                                              size: 50,
                                              color: Colors.white,
                                            )
                                          : null,
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
                                // Account Status
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
                                      Row(
                                        children: [
                                          Text(
                                            accountStatus
                                                .replaceAll('_', ' ')
                                                .toUpperCase(),
                                            style: GoogleFonts.montserrat(
                                              fontSize: 16,
                                              color: _getStatusColor(
                                                  accountStatus),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: CustomButton(
                                              text: _getStatusAction(
                                                  accountStatus),
                                              borderColor:
                                                  _getStatusButtonColor(
                                                      accountStatus),
                                              onPressed: () async {
                                                String newStatus;
                                                String action;

                                                switch (accountStatus
                                                    .toLowerCase()) {
                                                  case 'active':
                                                    newStatus = 'suspended';
                                                    action = 'Suspend';
                                                    break;
                                                  case 'suspended':
                                                    newStatus = 'active';
                                                    action = 'Activate';
                                                    break;
                                                  case 'deactivated':
                                                    newStatus = 'active';
                                                    action = 'Reactivate';
                                                    break;
                                                  case 'inactive':
                                                    newStatus = 'active';
                                                    action = 'Activate';
                                                    break;
                                                  default:
                                                    newStatus = 'active';
                                                    action = 'Activate';
                                                    break;
                                                }

                                                bool? confirm =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: Text(
                                                      'Confirm $action',
                                                      style: GoogleFonts
                                                          .montserrat(),
                                                    ),
                                                    content: Text(
                                                      "Are you sure you want to $action this user's account?",
                                                      style: GoogleFonts
                                                          .montserrat(),
                                                    ),
                                                    backgroundColor:
                                                        Colors.grey[800],
                                                    actions: [
                                                      TextButton(
                                                        child: Text(
                                                          'Cancel',
                                                          style: GoogleFonts
                                                              .montserrat(
                                                                  color: Colors
                                                                      .white),
                                                        ),
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(false),
                                                      ),
                                                      TextButton(
                                                        child: Text(
                                                          'Confirm',
                                                          style: GoogleFonts
                                                              .montserrat(
                                                                  color: Colors
                                                                      .red),
                                                        ),
                                                        onPressed: () =>
                                                            Navigator.of(
                                                                    context)
                                                                .pop(true),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (confirm == true) {
                                                  try {
                                                    await userProvider
                                                        .updateUserAccountStatus(
                                                            widget.userId,
                                                            newStatus);

                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'User account $action successfully.',
                                                          style: GoogleFonts
                                                              .montserrat(),
                                                        ),
                                                      ),
                                                    );

                                                    // Refresh to reflect changes
                                                    setState(() {});
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Failed to update account status.',
                                                          style: GoogleFonts
                                                              .montserrat(),
                                                        ),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 30),

                            // User Information Section
                            Text(
                              'User Information',
                              style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            SizedBox(height: 10),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildEditableField(
                                    'First Name', _firstNameController, false),
                                _buildEditableField('Middle Name',
                                    _middleNameController, false),
                                _buildEditableField(
                                    'Last Name', _lastNameController, false),
                                _buildEditableField(
                                    'Email', _emailController, false),
                                _buildEditableField('Phone Number',
                                    _phoneNumberController, false),
                                _buildEditableField('Company Name',
                                    _companyNameController, false),
                                _buildEditableField('Trading Name',
                                    _tradingNameController, false),
                                _buildEditableField('Address Line 1',
                                    _addressLine1Controller, false),
                                _buildEditableField('Address Line 2',
                                    _addressLine2Controller, false),
                                _buildEditableField(
                                    'City', _cityController, false),
                                _buildEditableField(
                                    'State', _stateController, false),
                                _buildEditableField('Postal Code',
                                    _postalCodeController, false),
                                SizedBox(height: 20),
                                CustomButton(
                                  text: 'Save Changes',
                                  onPressed: _saveChanges,
                                  borderColor: Colors.deepOrange,
                                ),
                              ],
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

  // Helper to build editable fields
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

  // Helper method to determine status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return Colors.orange;
      case 'deactivated':
        return Colors.red;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Helper method to determine status action text
  String _getStatusAction(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Suspend Account';
      case 'suspended':
        return 'Activate Account';
      case 'deactivated':
        return 'Reactivate Account';
      case 'inactive':
        return 'Activate Account';
      default:
        return 'Activate Account';
    }
  }

  // Helper method to determine status button color
  Color _getStatusButtonColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.orange;
      case 'suspended':
        return Colors.green;
      case 'deactivated':
        return Colors.blue;
      case 'inactive':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
