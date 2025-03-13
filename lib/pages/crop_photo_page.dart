import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/loading_screen.dart';
import 'package:ctp/components/progress_bar.dart';
import 'package:ctp/pages/dealer_reg.dart';
import 'package:ctp/pages/transporter_reg.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/utils/navigation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';

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
  Uint8List? _croppedBytes;
  bool _isLoading = false;
  bool _cropInitiated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_cropInitiated) {
        _cropInitiated = true;
        _cropImage();
      }
    });
  }

  Future<void> _cropImage() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: widget.imageFile.path,
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
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: CropperSize(width: 520, height: 520),
            background: true,
            movable: true,
            scalable: true,
            zoomable: true,
          ),
        ],
      );

      if (mounted && croppedFile != null) {
        if (kIsWeb) {
          final bytes = await croppedFile.readAsBytes();
          setState(() {
            _croppedBytes = bytes;
            _isLoading = false;
          });
        } else {
          setState(() {
            _croppedFile = File(croppedFile.path);
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cropping image: $e')),
        );
      }
    }
  }

  Future<void> _uploadProfileImage() async {
    // Validate before upload
    if (kIsWeb && _croppedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select and crop an image first')),
      );
      return;
    }
    if (!kIsWeb && _croppedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select and crop an image first')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${userProvider.user?.uid}');

      String imageUrl;
      if (kIsWeb) {
        final uploadTask = await storageRef.putData(
          _croppedBytes!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        imageUrl = await uploadTask.ref.getDownloadURL();
      } else {
        final uploadTask = await storageRef.putFile(File(_croppedFile!.path));
        imageUrl = await uploadTask.ref.getDownloadURL();
      }

      // Only proceed if image was uploaded successfully
      if (imageUrl.isNotEmpty) {
        final Map<String, dynamic> finalUserData = {
          ...widget.userData,
          'profileImageUrl': imageUrl,
        };
        finalUserData.remove('userType');

        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userProvider.user?.uid);
        await userRef.set(
            finalUserData, SetOptions(merge: true)); // Updated line

        // Add debug print before navigation
        print('User Role: ${finalUserData['userRole']}'); // Debug print

        if (mounted) {
          // Ensure string comparison is exact
          final userRole =
              finalUserData['userRole']?.toString().trim().toLowerCase();
          print('Processed User Role: $userRole'); // Debug print

          await MyNavigator.pushReplacement(
            context,
            finalUserData['userRole'] == 'dealer'
                ? const DealerRegPage()
                : const TransporterRegistrationPage(),
          );
        }
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
                                  backgroundImage: kIsWeb
                                      ? (_croppedBytes != null
                                          ? MemoryImage(_croppedBytes!)
                                          : const AssetImage(
                                                  'lib/assets/default-profile-photo.jpg')
                                              as ImageProvider)
                                      : (_croppedFile != null
                                          ? FileImage(_croppedFile!)
                                          : const AssetImage(
                                                  'lib/assets/default-profile-photo.jpg')
                                              as ImageProvider),
                                  child: (kIsWeb && _croppedBytes == null) ||
                                          (!kIsWeb && _croppedFile == null)
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
