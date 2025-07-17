import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:auto_route/auto_route.dart';

@RoutePage()
class LocalViewerPage extends StatelessWidget {
  final Uint8List file;
  final String title;
  const LocalViewerPage({super.key, required this.file, required this.title});

  // Updated: Check file header for '%PDF' signature.
  bool _isImage(Uint8List file) {
    debugPrint('LocalViewerPage: File length: ${file.lengthInBytes}');
    // Check for PDF header: [0x25, 0x50, 0x44, 0x46] corresponds to '%PDF'
    if (file.lengthInBytes >= 4) {
      if (file[0] == 0x25 &&
          file[1] == 0x50 &&
          file[2] == 0x44 &&
          file[3] == 0x46) {
        debugPrint('LocalViewerPage: Detected PDF header.');
        return false;
      }
    }
    try {
      final image = Image.memory(file);
      debugPrint('LocalViewerPage: Successfully created Image widget.');
      return true;
    } catch (e) {
      debugPrint('LocalViewerPage: Error decoding image: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('LocalViewerPage: Building viewer for "$title"');
    final bool isImage = _isImage(file);
    debugPrint('LocalViewerPage: _isImage returned: $isImage');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: isImage
            ? PhotoView(
                imageProvider: MemoryImage(file),
                loadingBuilder: (context, event) {
                  debugPrint(
                      'LocalViewerPage: PhotoView loading, event: $event');
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('LocalViewerPage: PhotoView error: $error');
                  debugPrint('LocalViewerPage: StackTrace: $stackTrace');
                  return const Center(
                      child: Icon(Icons.error, color: Colors.red));
                },
              )
            : SfPdfViewer.memory(
                file,
                onDocumentLoadFailed: (details) {
                  debugPrint(
                      'LocalViewerPage: PDF load failed: ${details.description}');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Error loading PDF: ${details.description}')),
                  );
                },
              ),
      ),
    );
  }
}
