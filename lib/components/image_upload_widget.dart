// lib/components/image_upload_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';

class ImageUploadWidget extends StatelessWidget {
  final File? imageFile;
  final String label;
  final VoidCallback onTap;

  const ImageUploadWidget({
    super.key,
    required this.imageFile,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: Colors.white70, width: 1),
        ),
        child: Center(
          child: imageFile == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: Colors.blue, size: 40),
                    Text(
                      label,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Image.file(
                    imageFile!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
        ),
      ),
    );
  }
}
