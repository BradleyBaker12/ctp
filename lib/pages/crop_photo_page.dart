import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/loading_screen.dart';
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

  const CropPhotoPage({super.key, required this.imageFile});

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
        setState(() {
          _croppedFile = imageFile;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error cropping image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cropping image: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_croppedFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userId!;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$userId.jpg');

      // Compress the file
      final compressedFile = await _compressImageFile(_croppedFile!);

      // Upload the compressed file
      await storageRef.putFile(compressedFile);
      final imageUrl = await storageRef.getDownloadURL();

      // Update user's profile image URL in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'profileImageUrl': imageUrl,
      });

      // Check user role and navigate accordingly
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final userRole = userDoc['userRole'];

      if (userRole == 'transporter') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  const TransporterRegistrationPage()), // Ensure this page exists
        );
      } else if (userRole == 'dealer') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DealerRegPage()),
        );
      } else {
        Navigator.pushReplacementNamed(
            context, '/home'); // Fallback or home page
      }
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<File> _compressImageFile(File file) async {
    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      file.absolute.path.replaceAll('.jpg', '_compressed.jpg'),
      quality: 70, // Adjust quality here (0-100)
    );

    // Convert compressedFile to File and return
    return compressedFile != null ? File(compressedFile.path) : file;
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
                              const SizedBox(height: 20),
                              Image.asset('lib/assets/CTPLogo.png',
                                  height: 200), // Adjust the height as needed
                              const SizedBox(height: 50),
                              Text(
                                'PREVIEW',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              if (!_isLoading)
                                CircleAvatar(
                                  radius: 80,
                                  backgroundImage: _croppedFile != null
                                      ? FileImage(_croppedFile!)
                                      : const AssetImage(
                                          'lib/assets/placeholder_image.png'), // Placeholder image
                                  child: _croppedFile == null
                                      ? const Icon(Icons.person,
                                          size: 80, color: Colors.grey)
                                      : null,
                                ),
                              const SizedBox(height: 50),
                              CustomButton(
                                text: 'CONTINUE',
                                borderColor: blue,
                                onPressed: _uploadProfileImage,
                              ),
                              const SizedBox(height: 30),
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
          if (_isLoading) const LoadingScreen()
        ],
      ),
    );
  }
}
