// lib/screens/document_preview_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

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

  @override
  void initState() {
    super.initState();
    _prepareDocument();
  }

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
        final response = await http.get(Uri.parse(widget.url!));
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final dir = await getTemporaryDirectory();
          final fileName = widget.url!.split('/').last;
          final file = File('${dir.path}/$fileName');

          await file.writeAsBytes(bytes, flush: true);
          setState(() {
            localPath = file.path;
            isLoading = false;
          });
        } else {
          throw Exception('Failed to load document');
        }
      } catch (e) {
        debugPrint('Error downloading file: $e');
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading document: $e')),
        );
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  bool _isPDF(String path) {
    return path.toLowerCase().endsWith('.pdf');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Document Preview'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (localPath == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Document Preview'),
        ),
        body: const Center(child: Text('No document to display')),
      );
    }

    if (_isPDF(localPath!)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('PDF Preview'),
        ),
        body: PDFView(
          filePath: localPath,
          enableSwipe: true,
          swipeHorizontal: true,
          autoSpacing: false,
          pageFling: false,
        ),
      );
    } else {
      // Assume it's an image
      return Scaffold(
        appBar: AppBar(
          title: const Text('Image Preview'),
        ),
        body: Center(
          child: Image.file(
            File(localPath!),
            fit: BoxFit.contain,
          ),
        ),
      );
    }
  }
}
