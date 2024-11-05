import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/loading_screen.dart';
import 'package:ctp/components/progress_bar.dart';
import 'package:ctp/pages/dealer_reg.dart';
import 'package:ctp/pages/transporter_reg.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class CropPhotoPage extends StatefulWidget {
  final XFile imageFile;
  final Map<String, dynamic> userData;

  const CropPhotoPage({
    super.key,
    required this.imageFile,
    required this.userData,
  });

  @override
  _CropPhotoPageState createState() => _CropPhotoPageState();
}

class _CropPhotoPageState extends State<CropPhotoPage> {
  File? _croppedFile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cropImage();
  }

  Future<void> _cropImage() async {
    try {
      final File imageFile = File(widget.imageFile.path);

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop and Fit',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop and Fit',
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _croppedFile = File(croppedFile.path);
          _isLoading = false;
        });
      } else {
        // User canceled cropping, go back to previous screen
        Navigator.pop(context);
      }
    } catch (e) {
      print("Error cropping image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cropping image: $e')),
      );
      Navigator.pop(context); // Go back on error
    }
  }

  Future<void> _uploadProfileImage() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userProvider.user?.uid);

      // Upload image
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${userProvider.user?.uid}');
      await storageRef.putFile(_croppedFile!);
      final imageUrl = await storageRef.getDownloadURL();

      // Merge all user data with profile image URL
      final Map<String, dynamic> finalUserData = {
        ...widget.userData,
        'profileImageUrl': imageUrl,
        'userRole': widget.userData['userType'],
      };
      
      // Remove userType from final data
      finalUserData.remove('userType');

      // Save all user data
      await userRef.set(finalUserData);

      if (mounted) {
        // Navigate based on user role
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => finalUserData['userRole'] == 'dealer'
                ? const DealerRegPage()
                : const TransporterRegistrationPage(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                              horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            children: [
                              SizedBox(height: screenSize.height * 0.02),
                              Image.asset(
                                'lib/assets/CTPLogo.png',
                                height: screenSize.height * 0.2,
                                width: screenSize.height * 0.2,
                                fit: BoxFit.cover,
                              ),
                              SizedBox(height: screenSize.height * 0.07),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 64.0),
                                child: const ProgressBar(progress: 1),
                              ),
                              SizedBox(height: screenSize.height * 0.06),
                              Text(
                                'PREVIEW',
                                style: GoogleFonts.montserrat(
                                  fontSize: screenSize.height * 0.025,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: screenSize.height * 0.06),
                              if (!_isLoading)
                                CircleAvatar(
                                  radius: 60,
                                  backgroundImage: _croppedFile != null
                                      ? FileImage(_croppedFile!)
                                      : const AssetImage(
                                              'lib/assets/placeholder_image.png')
                                          as ImageProvider,
                                  child: _croppedFile == null
                                      ? const Icon(Icons.person,
                                          size: 80, color: Colors.grey)
                                      : null,
                                ),
                              SizedBox(height: screenSize.height * 0.1),
                              CustomButton(
                                text: 'CONTINUE',
                                borderColor: blue,
                                onPressed: _uploadProfileImage,
                              ),
                              SizedBox(height: screenSize.height * 0.03),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) const LoadingScreen()
        ],
      ),
    );
  }
}
