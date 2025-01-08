// lib/adminScreens/invoice_viewer_page.dart

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class InvoiceViewerPage extends StatefulWidget {
  final String url;

  const InvoiceViewerPage({Key? key, required this.url}) : super(key: key);

  @override
  _InvoiceViewerPageState createState() => _InvoiceViewerPageState();
}

class _InvoiceViewerPageState extends State<InvoiceViewerPage> {
  bool _isLoading = true;
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _prepareFile();
  }

  Future<void> _prepareFile() async {
    try {
      // Check if the file is a PDF
      if (widget.url.toLowerCase().endsWith('.pdf')) {
        // Download the PDF file to a temporary directory
        final response = await http.get(Uri.parse(widget.url));
        final bytes = response.bodyBytes;
        final dir = await getTemporaryDirectory();
        final filePath = path.join(dir.path, path.basename(widget.url));
        final file = File(filePath);
        await file.writeAsBytes(bytes, flush: true);
        setState(() {
          _localPath = filePath;
          _isLoading = false;
        });
      } else {
        // For images, no need to download; use the URL directly
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error preparing file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load the invoice.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPDF = widget.url.toLowerCase().endsWith('.pdf');

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Invoice'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isPDF
              ? _localPath != null
                  ? PDFView(
                      filePath: _localPath,
                      enableSwipe: true,
                      swipeHorizontal: true,
                      autoSpacing: false,
                      pageFling: false,
                    )
                  : const Center(child: Text('Failed to load PDF.'))
              : PhotoView(
                  imageProvider: NetworkImage(widget.url),
                  loadingBuilder: (context, event) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorBuilder: (context, error, stackTrace) =>
                      const Center(child: Text('Error loading image')),
                ),
    );
  }
}
