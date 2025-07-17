import 'package:ctp/pages/admin_home_page.dart';
import 'package:ctp/utils/navigation.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/progress_bar.dart';
import 'package:ctp/pages/crop_photo_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:auto_route/auto_route.dart';

@RoutePage()
class AddProfilePhotoAdminPage extends StatefulWidget {
  const AddProfilePhotoAdminPage({super.key});

  @override
  _AddProfilePhotoAdminPageState createState() =>
      _AddProfilePhotoAdminPageState();
}

class _AddProfilePhotoAdminPageState extends State<AddProfilePhotoAdminPage> {
  final ImagePicker _picker = ImagePicker();
  String? _selectedProfileImage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        await MyNavigator.push(
          context,
          CropPhotoPage(
            imageFile: pickedFile,
            userData: const {},
          ),
        );
      } else {
        print("No image selected.");
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _useDefaultImage() async {
    setState(() {
      _selectedProfileImage =
          'https://firebasestorage.googleapis.com/v0/b/ctp-central-database.appspot.com/o/profile_images%2Fdefault-profile-photo.jpg?alt=media&token=4684aad7-dd48-413c-9661-5fc2de11bec9';
    });

    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userId!;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Update the user's profile image and set isFirstLogin to false
      await firestore.collection('users').doc(userId).update({
        'profileImageUrl': _selectedProfileImage,
        'isFirstLogin': false, // Set isFirstLogin to false
      });

      // Update local UserProvider data
      await Provider.of<UserProvider>(context, listen: false).fetchUserData();

      // Navigate to Admin Home Page
      await MyNavigator.pushReplacement(context, AdminHomePage());
    } catch (e) {
      print("Error setting default profile image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error setting default profile image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var blue = const Color(0xFF2F7FFF);

    return PopScope(
      onPopInvokedWithResult: (route, result) async => false,
      child: Scaffold(
        body: Stack(
          children: [
            const GradientBackground(child: SizedBox.expand()),
            SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenSize.width * 0.05,
                        vertical: screenSize.height * 0.02,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: screenSize.height * 0.02),
                          Image.asset(
                            'lib/assets/CTPLogo.png',
                            height: screenSize.height * 0.2,
                            width: screenSize.height * 0.2,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(height: screenSize.height * 0.04),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenSize.width * 0.1,
                            ),
                            child: const ProgressBar(progress: 1.0),
                          ),
                          SizedBox(height: screenSize.height * 0.04),
                          Text(
                            'ADD PROFILE PHOTO ADMIN PAGE',
                            style: GoogleFonts.montserrat(
                              fontSize: screenSize.height * 0.025,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: screenSize.height * 0.04),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: blue, width: 2.0),
                                      color: blue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.camera_alt,
                                          size: screenSize.height * 0.05,
                                          color: Colors.white),
                                      onPressed: () =>
                                          _pickImage(ImageSource.camera),
                                    ),
                                  ),
                                  SizedBox(height: screenSize.height * 0.02),
                                  Text(
                                    'CAMERA',
                                    style: GoogleFonts.montserrat(
                                      fontSize: screenSize.height * 0.02,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: screenSize.width * 0.1),
                              Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: blue, width: 2.0),
                                      color: blue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.photo_library,
                                          size: screenSize.height * 0.05,
                                          color: Colors.white),
                                      onPressed: () =>
                                          _pickImage(ImageSource.gallery),
                                    ),
                                  ),
                                  SizedBox(height: screenSize.height * 0.02),
                                  Text(
                                    'GALLERY',
                                    style: GoogleFonts.montserrat(
                                      fontSize: screenSize.height * 0.02,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: screenSize.height * 0.04),
                          TextButton(
                            onPressed: _useDefaultImage,
                            child: Text(
                              'UPLOAD LATER',
                              style: GoogleFonts.montserrat(
                                  fontSize: screenSize.height * 0.015,
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white,
                                  letterSpacing: 2.0,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: screenSize.height * 0.05,
                    left: screenSize.width * 0.05,
                    child: const CustomBackButton(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
