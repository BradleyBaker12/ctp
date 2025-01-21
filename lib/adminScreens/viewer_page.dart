import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ViewerPage extends StatefulWidget {
  final String url;

  const ViewerPage({super.key, required this.url});

  @override
  _ViewerPageState createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  bool _isLoading = true;
  String? _localPDFPath; // For storing the local path of the downloaded PDF

  @override
  void initState() {
    super.initState();
    debugPrint('DEBUG: initState -> Widget URL: ${widget.url}');
    _prepareFile();
  }

  /// If the file is a PDF, download it to a local temp directory; otherwise skip.
  Future<void> _prepareFile() async {
    try {
      // Strip query parameters, then check if it ends with .pdf
      final sanitizedUrl = widget.url.split('?').first.toLowerCase();
      final isPDF = sanitizedUrl.endsWith('.pdf');
      debugPrint(
        'DEBUG: _prepareFile -> isPDF: $isPDF (sanitizedUrl=$sanitizedUrl)',
      );

      if (isPDF) {
        debugPrint('DEBUG: Attempting to download PDF from: ${widget.url}');
        final response = await http.get(Uri.parse(widget.url));
        debugPrint('DEBUG: HTTP GET -> status code: ${response.statusCode}');

        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final tempDir = await getTemporaryDirectory();
          final fileName = p.basename(sanitizedUrl);
          // Or just p.basename(widget.url); either is fine

          final filePath = p.join(tempDir.path, fileName);
          final file = File(filePath);

          await file.writeAsBytes(bytes, flush: true);
          debugPrint('DEBUG: PDF downloaded to local path: $filePath');

          setState(() {
            _localPDFPath = filePath;
            _isLoading = false;
          });
        } else {
          throw Exception(
            'HTTP Error: ${response.statusCode} for ${widget.url}',
          );
        }
      } else {
        // If not a PDF, just mark as finished loading
        debugPrint('DEBUG: File is not PDF, skipping download...');
        setState(() => _isLoading = false);
      }
    } catch (e, stackTrace) {
      debugPrint('ERROR: _prepareFile -> $e');
      debugPrint('STACK TRACE:\n$stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load file: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Again, strip query params in case .pdf is at the end
    final sanitizedUrl = widget.url.split('?').first.toLowerCase();
    final isPDF = sanitizedUrl.endsWith('.pdf');

    debugPrint(
      'DEBUG: build -> isPDF: $isPDF, _isLoading: $_isLoading',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('View File'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isPDF
              // ---- PDF Mode ----
              ? (_localPDFPath != null)
                  ? _buildPDFView()
                  : const Center(child: Text('Failed to load PDF.'))
              // ---- Image Mode ----
              : _buildImageView(),
    );
  }

  /// Builds the PDF viewer widget.
  Widget _buildPDFView() {
    debugPrint('DEBUG: _buildPDFView -> using PDFView with $_localPDFPath');
    return PDFView(
      filePath: _localPDFPath!,
      enableSwipe: true,
      swipeHorizontal: true,
      autoSpacing: false,
      pageFling: false,
      onError: (error) {
        debugPrint('ERROR: PDFView -> onError: $error');
      },
      onRender: (pages) {
        debugPrint('DEBUG: PDFView -> onRender, pages: $pages');
      },
      onViewCreated: (controller) {
        debugPrint('DEBUG: PDFView -> onViewCreated');
      },
    );
  }

  /// Builds the image viewer widget.
  Widget _buildImageView() {
    debugPrint(
      'DEBUG: _buildImageView -> using PhotoView with URL: ${widget.url}',
    );
    return PhotoView(
      imageProvider: NetworkImage(widget.url),
      loadingBuilder: (context, event) {
        debugPrint('DEBUG: _buildImageView -> Loading image...');
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('ERROR: PhotoView -> errorBuilder: $error');
        return const Center(
          child: Text(
            'Error loading image',
            style: TextStyle(color: Colors.red),
          ),
        );
      },
    );
  }
}
