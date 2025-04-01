import 'dart:typed_data';
import 'dart:convert';
import 'dart:ui_web';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

Future<Uint8List?> capturePhotoImplementation(BuildContext context) async {
  bool useFrontCamera = false;
  Uint8List? capturedImage;

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
            content: SingleChildScrollView(
              child: FutureBuilder<html.VideoElement>(
                // Use a key based on the camera mode to trigger rebuild.
                key: ValueKey(useFrontCamera),
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
                  final viewID =
                      'webcam_${DateTime.now().millisecondsSinceEpoch}';
                  // Register the video element for the HtmlElementView.
                  platformViewRegistry.registerViewFactory(
                      viewID, (int viewId) => videoElement);
                  final double feedSize =
                      MediaQuery.of(context).size.width * 0.8;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: feedSize,
                        height: feedSize,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: HtmlElementView(viewType: viewID),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              final canvas = html.CanvasElement(
                                width: videoElement.videoWidth,
                                height: videoElement.videoHeight,
                              );
                              canvas.context2D.drawImage(videoElement, 0, 0);
                              final dataUrl = canvas.toDataUrl('image/png');
                              final base64Str = dataUrl.split(',').last;
                              final bytes = base64.decode(base64Str);
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
                              // Toggle camera and force FutureBuilder rebuild.
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
            ),
          );
        },
      );
    },
  );

  return capturedImage;
}
