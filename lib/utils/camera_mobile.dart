import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

Future<Uint8List?> capturePhotoImplementation(BuildContext context) async {
  final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
  if (pickedFile != null) {
    return await pickedFile.readAsBytes();
  }
  return null;
}
