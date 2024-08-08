import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/pages/crop_photo_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddProfilePhotoPage extends StatefulWidget {
  const AddProfilePhotoPage({super.key});

  @override
  _AddProfilePhotoPageState createState() => _AddProfilePhotoPageState();
}

class _AddProfilePhotoPageState extends State<AddProfilePhotoPage> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CropPhotoPage(imageFile: File(pickedFile.path)),
          ),
        );
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
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
                              horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              Image.asset('lib/assets/CTPLogo.png',
                                  height: 200),
                              const SizedBox(height: 50),
                              const Text(
                                'ADD A PROFILE PHOTO',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 50),
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
                                          icon: const Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Icon(Icons.camera_alt,
                                                size: 50, color: Colors.white),
                                          ),
                                          onPressed: () =>
                                              _pickImage(ImageSource.camera),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'CAMERA',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 50),
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
                                          icon: const Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: Icon(Icons.photo_library,
                                                size: 50, color: Colors.white),
                                          ),
                                          onPressed: () =>
                                              _pickImage(ImageSource.gallery),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'GALLERY',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 200),
                              CustomButton(
                                text: 'CONTINUE',
                                borderColor: blue,
                                onPressed: () {}, // No action needed
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
        ],
      ),
    );
  }
}
