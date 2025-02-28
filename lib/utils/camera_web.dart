import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui_web';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

Future<Uint8List?> capturePhotoImplementation(BuildContext context) async {
  // Default to back (environment) camera.
  bool useFrontCamera = false;
  Uint8List? capturedImage;

  // Helper to initialize the camera with the desired facing mode.
  Future<html.VideoElement> initializeCamera(bool useFront) async {
    final mediaDevices = html.window.navigator.mediaDevices;
    final constraints = {
      'video': {
        'facingMode': useFront ? 'user' : 'environment',
      }
    };
    final mediaStream = await mediaDevices?.getUserMedia(constraints);
    final videoElem = html.VideoElement()
      ..autoplay = true
      ..srcObject = mediaStream;
    await videoElem.onLoadedMetadata.first;
    return videoElem;
  }

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Take Photo'),
            content: FutureBuilder<html.VideoElement>(
              future: initializeCamera(useFrontCamera),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    width: 320,
                    height: 320,
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return const SizedBox(
                    width: 320,
                    height: 320,
                    child: Center(child: Text('Error initializing camera')),
                  );
                }
                final videoElement = snapshot.data!;
                // Create a unique view ID.
                final viewID =
                    'webcam_${DateTime.now().millisecondsSinceEpoch}';
                // Register the view factory.
                platformViewRegistry.registerViewFactory(
                    viewID, (int viewId) => videoElement);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Display the live camera feed inside a rounded container.
                    SizedBox(
                      width: 320,
                      height: 320,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: HtmlElementView(viewType: viewID),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Capture the current frame.
                            final canvas = html.CanvasElement(
                              width: videoElement.videoWidth,
                              height: videoElement.videoHeight,
                            );
                            canvas.context2D.drawImage(videoElement, 0, 0);
                            final dataUrl = canvas.toDataUrl('image/png');
                            final base64Str = dataUrl.split(',').last;
                            final bytes = base64.decode(base64Str);
                            // Stop all tracks.
                            (videoElement.srcObject as html.MediaStream)
                                .getTracks()
                                .forEach((track) => track.stop());
                            capturedImage = bytes;
                            Navigator.of(dialogContext).pop();
                          },
                          child: const Text('Capture'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Toggle camera mode.
                            setState(() {
                              useFrontCamera = !useFrontCamera;
                            });
                          },
                          child: Text(useFrontCamera
                              ? 'Switch to Back Camera'
                              : 'Switch to Front Camera'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        // Cancel and stop the stream.
                        (videoElement.srcObject as html.MediaStream)
                            .getTracks()
                            .forEach((track) => track.stop());
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
    },
  );

  return capturedImage;
}
