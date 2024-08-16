import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/progress_bar.dart';
import 'package:ctp/pages/crop_photo_page.dart';
import 'package:ctp/pages/dealer_reg.dart';
import 'package:ctp/pages/transporter_reg.dart'; // Import the transporter registration page
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class AddProfilePhotoPage extends StatefulWidget {
  const AddProfilePhotoPage({super.key});

  @override
  _AddProfilePhotoPageState createState() => _AddProfilePhotoPageState();
}

class _AddProfilePhotoPageState extends State<AddProfilePhotoPage> {
  final ImagePicker _picker = ImagePicker();
  String? _selectedProfileImage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CropPhotoPage(imageFile: pickedFile), // Pass XFile directly
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

      // Update the user's profile image to the default image in Firestore
      await firestore.collection('users').doc(userId).update({
        'profileImageUrl': _selectedProfileImage,
      });

      // Fetch the user's role from Firestore
      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(userId).get();
      String userRole = userDoc['role'];

      // Navigate to the appropriate registration page based on the user's role
      if (userRole == 'dealer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DealerRegPage()),
        );
      } else if (userRole == 'transporter') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const TransporterRegistrationPage()), // Ensure this page exists
        );
      } else {
        // Handle other roles if necessary
        print("Unknown user role: $userRole");
      }
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

    double paddingValue = screenSize.width * 0.04;
    double imageHeight = screenSize.height * 0.25;
    double iconSize = screenSize.width * 0.1;
    double fontSizeTitle = screenSize.width * 0.05;
    double fontSizeButton = screenSize.width * 0.04;

    return Scaffold(
      body: Stack(
        children: [
          GradientBackground(
            child: Column(
              children: [
                const BlurryAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Stack(
                      children: [
                        Container(
                          width: screenSize.width,
                          padding: EdgeInsets.symmetric(
                              horizontal: paddingValue, vertical: 8.0),
                          child: Column(
                            children: [
                              SizedBox(height: screenSize.height * 0.03),
                              Image.asset('lib/assets/CTPLogo.png',
                                  height: imageHeight),
                              SizedBox(height: screenSize.height * 0.05),
                              const ProgressBar(progress: 0.90),
                              SizedBox(height: screenSize.height * 0.05),
                              Text(
                                'ADD A PROFILE PHOTO',
                                style: GoogleFonts.montserrat(
                                  fontSize: fontSizeTitle,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: screenSize.height * 0.06),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: blue, width: 2.0),
                                          color: blue.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        child: IconButton(
                                          icon: Padding(
                                            padding:
                                                EdgeInsets.all(iconSize * 0.32),
                                            child: Icon(Icons.camera_alt,
                                                size: iconSize,
                                                color: Colors.white),
                                          ),
                                          onPressed: () =>
                                              _pickImage(ImageSource.camera),
                                        ),
                                      ),
                                      SizedBox(
                                          height: screenSize.height * 0.02),
                                      Text(
                                        'CAMERA',
                                        style: GoogleFonts.montserrat(
                                          fontSize: fontSizeButton,
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
                                          border: Border.all(
                                              color: blue, width: 2.0),
                                          color: blue.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        child: IconButton(
                                          icon: Padding(
                                            padding:
                                                EdgeInsets.all(iconSize * 0.32),
                                            child: Icon(Icons.photo_library,
                                                size: iconSize,
                                                color: Colors.white),
                                          ),
                                          onPressed: () =>
                                              _pickImage(ImageSource.gallery),
                                        ),
                                      ),
                                      SizedBox(
                                          height: screenSize.height * 0.02),
                                      Text(
                                        'GALLERY',
                                        style: GoogleFonts.montserrat(
                                          fontSize: fontSizeButton,
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
                                    fontSize: fontSizeButton,
                                    color: Colors.white,
                                    decoration: TextDecoration.underline,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenSize.height * 0.04),
                              CustomButton(
                                text: 'CONTINUE',
                                borderColor: blue,
                                onPressed: () {}, // No action needed
                              ),
                            ],
                          ),
                        ),
                        const Positioned(
                          top: 40,
                          left: 16,
                          child: CustomBackButton(),
                        ),
                      ],
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
}
