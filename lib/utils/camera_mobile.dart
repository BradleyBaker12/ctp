import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> _ensureCameraPermission(BuildContext context) async {
  var status = await Permission.camera.status;
  if (status.isGranted) return true;
  if (status.isDenied || status.isRestricted) {
    status = await Permission.camera.request();
    if (status.isGranted) return true;
  }
  if (status.isPermanentlyDenied) {
    // Ask user to open settings and retry
    if (context.mounted) {
      final open = await showDialog<bool>(
        context: context,
        builder: (dCtx) => AlertDialog(
          title: const Text('Camera Permission Needed'),
          content: const Text(
              'Camera access is blocked. Please allow access in Settings to continue.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dCtx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dCtx).pop(true);
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      if (open == true) {
        await openAppSettings();
        await Future.delayed(const Duration(milliseconds: 500));
        final post = await Permission.camera.status;
        return post.isGranted;
      }
    }
    return false;
  }
  return false;
}

Future<Uint8List?> capturePhotoImplementation(BuildContext context) async {
  // Ensure camera permission is granted or guide user to settings.
  final ok = await _ensureCameraPermission(context);
  if (!ok) return null;

  final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
  if (pickedFile != null) {
    return await pickedFile.readAsBytes();
  }
  return null;
}
