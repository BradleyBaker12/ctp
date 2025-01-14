// lib/screens/document_preview_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart'; // Import share_plus
import 'package:cross_file/cross_file.dart';

class DocumentPreviewScreen extends StatefulWidget {
  final String? url; // URL of the document
  final File? file; // Local file

  const DocumentPreviewScreen({super.key, this.url, this.file});

  @override
  _DocumentPreviewScreenState createState() => _DocumentPreviewScreenState();
}

class _DocumentPreviewScreenState extends State<DocumentPreviewScreen> {
  String? localPath;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _prepareDocument();
  }

  /// Prepares the document for viewing.
  /// Downloads the document if a URL is provided, or uses the local file directly.
  Future<void> _prepareDocument() async {
    if (widget.file != null) {
      // If it's a local file, no need to download
      setState(() {
        localPath = widget.file!.path;
        isLoading = false;
      });
    } else if (widget.url != null) {
      // Download the file to a temporary directory
      try {
        final uri = Uri.parse(widget.url!);
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final dir = await getTemporaryDirectory();
          final fileName = _extractFileName(uri.path);
          final file = File('${dir.path}/$fileName');

          await file.writeAsBytes(bytes, flush: true);
          setState(() {
            localPath = file.path;
            isLoading = false;
          });
        } else {
          throw Exception(
              'Failed to load document. Status code: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Error downloading file: $e');
        setState(() {
          isLoading = false;
          errorMessage = 'Error loading document: $e';
        });
        _showErrorSnackBar('Error loading document: $e');
      }
    } else {
      setState(() {
        isLoading = false;
        errorMessage = 'No document provided.';
      });
      _showErrorSnackBar('No document to display.');
    }
  }

  /// Extracts the file name from a given path.
  String _extractFileName(String path) {
    return path.split('/').last;
  }

  /// Determines if the file is a PDF based on its extension.
  bool _isPDF(String path) {
    return path.toLowerCase().endsWith('.pdf');
  }

  /// Determines if the file is an image based on its extension.
  bool _isImage(String path) {
    return path.toLowerCase().endsWith('.jpg') ||
        path.toLowerCase().endsWith('.jpeg') ||
        path.toLowerCase().endsWith('.png');
  }

  /// Displays a SnackBar with the provided error message.
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Shares the current document using share_plus.
  Future<void> _shareDocument() async {
    if (localPath == null) {
      _showErrorSnackBar('No document available to share.');
      return;
    }

    try {
      final file = File(localPath!);
      if (!await file.exists()) {
        _showErrorSnackBar('File does not exist.');
        return;
      }
      await Share.shareXFiles([XFile(localPath!)],
          text: 'Sharing a document with you!');
    } catch (e) {
      debugPrint('Error sharing document: $e');
      _showErrorSnackBar('Error sharing document: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the AppBar title based on the document type
    String appBarTitle = 'Document Preview';

    if (isLoading) {
      // Display a loading indicator while the document is being prepared
      return Scaffold(
        appBar: AppBar(
          title: const Text('Document Preview'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareDocument,
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      // Display an error message if any issues occurred during document preparation
      return Scaffold(
        appBar: AppBar(
          title: const Text('Document Preview'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareDocument,
            ),
          ],
        ),
        body: Center(
          child: Text(
            errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (localPath == null) {
      // Inform the user if no document is available for display
      return Scaffold(
        appBar: AppBar(
          title: const Text('Document Preview'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareDocument,
            ),
          ],
        ),
        body: const Center(child: Text('No document to display')),
      );
    }

    // Determine the type of document and display accordingly
    if (_isPDF(localPath!)) {
      appBarTitle = 'PDF Preview';
      // Display PDF documents using PDFView
      return Scaffold(
        appBar: AppBar(
          title: Text(appBarTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareDocument,
            ),
          ],
        ),
        body: PDFView(
          filePath: localPath,
          enableSwipe: true,
          swipeHorizontal: true,
          autoSpacing: false,
          pageFling: false,
          onRender: (_pages) {
            debugPrint('PDF rendered with $_pages pages');
          },
          onError: (error) {
            debugPrint('Error in PDF Viewer: $error');
            _showErrorSnackBar('Error displaying the PDF.');
          },
          onPageError: (page, error) {
            debugPrint('Error on page $page: $error');
            _showErrorSnackBar('Error displaying page $page of the PDF.');
          },
        ),
      );
    } else if (_isImage(localPath!)) {
      appBarTitle = 'Image Preview';
      // Display image documents using Image.file
      return Scaffold(
        appBar: AppBar(
          title: Text(appBarTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareDocument,
            ),
          ],
        ),
        body: Center(
          child: InteractiveViewer(
            child: Image.file(
              File(localPath!),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading image: $error');
                return const Text(
                  'Error displaying the image.',
                  style: TextStyle(color: Colors.red),
                );
              },
            ),
          ),
        ),
      );
    } else {
      // Handle unsupported file types
      return Scaffold(
        appBar: AppBar(
          title: const Text('Document Preview'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareDocument,
            ),
          ],
        ),
        body: const Center(
          child: Text(
            'Unsupported document format.',
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }
  }
}
