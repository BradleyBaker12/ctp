import 'dart:typed_data';
import 'package:flutter/material.dart';
// Conditionally import the implementation:
// If dart:html is available (i.e. web), this will import camera_web.dart;
// otherwise, it imports camera_mobile.dart.
import 'camera_mobile.dart' if (dart.library.html) 'camera_web.dart';

Future<Uint8List?> capturePhoto(BuildContext context) {
  return capturePhotoImplementation(context);
}
