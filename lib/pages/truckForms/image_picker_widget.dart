// image_picker_widget.dart
import 'package:ctp/components/constants.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ImagePickerWidget extends StatelessWidget {
  final Function(File?) onImagePicked;

  const ImagePickerWidget({Key? key, required this.onImagePicked})
      : super(key: key);

  Future<void> _pickImage(ImageSource source, BuildContext context) async {
    try {
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

  void _showImageSourceDialog(BuildContext context) {
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
                    _pickImage(ImageSource.camera, context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery, context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cancel),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10.0),
        ),
        height: 200.0, // You can adjust the height as needed
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circle with solid blue border and slightly transparent background
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blue
                    .withOpacity(0.5), // Slightly transparent blue
                border: Border.all(
                  color: AppColors.blue, // Solid blue border
                  width: 2.0,
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              child: const Icon(
                Icons.add,
                color: Colors.white, // White plus icon
                size: 50.0,
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'NEW PHOTO OR UPLOAD FROM GALLERY',
              style: TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.center, // Center the text
            ),
          ],
        ),
      ),
    );
  }
}
