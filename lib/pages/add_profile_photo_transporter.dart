import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/progress_bar.dart';
import 'package:ctp/pages/crop_photo_page.dart';
import 'package:ctp/pages/dealer_reg.dart';
import 'package:ctp/pages/transporter_reg.dart';
// Import the House Rules page
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class AddProfilePhotoPageTransporter extends StatefulWidget {
  const AddProfilePhotoPageTransporter({super.key});

  @override
  _AddProfilePhotoPageTransporterState createState() =>
      _AddProfilePhotoPageTransporterState();
}

class _AddProfilePhotoPageTransporterState
    extends State<AddProfilePhotoPageTransporter> {
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

      // Navigate directly to the Dealer Registration page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const TransporterRegistrationPage(), // Ensure DealerRegistrationPage exists
        ),
      );
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 8.0),
                          child: Column(
                            children: [
                              SizedBox(height: screenSize.height * 0.02),
                              Image.asset(
                                'lib/assets/CTPLogo.png',
                                height: screenSize.height * 0.2,
                                width: screenSize.height * 0.2,
                                fit: BoxFit.cover,
                              ),
                              SizedBox(height: screenSize.height * 0.09),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 64.0),
                                child: const ProgressBar(progress: 0.9),
                              ),
                              SizedBox(height: screenSize.height * 0.045),
                              Text(
                                'ADD A PROFILE PHOTO',
                                style: GoogleFonts.montserrat(
                                  fontSize: screenSize.height * 0.025,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: screenSize.height * 0.09),
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
                                            padding: EdgeInsets.all(
                                                screenSize.height * 0.008),
                                            child: Icon(Icons.camera_alt,
                                                size: screenSize.height * 0.05,
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
                                          fontSize: 24,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: screenSize.width * 0.15),
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
                                            padding: EdgeInsets.all(
                                                screenSize.height * 0.008),
                                            child: Icon(Icons.photo_library,
                                                size: screenSize.height * 0.05,
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
                                          fontSize: 24,
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