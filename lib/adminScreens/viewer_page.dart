// IMPORTANT: The import for 'dart:html' below is only needed on the web.
// If you experience issues when building for mobile, consider using conditional imports.
import 'dart:io';
import 'package:flutter/foundation.dart';
// import 'html_stub.dart' if (dart.library.html) 'dart:html' as html;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ViewerPage extends StatefulWidget {
  final String url;

  ViewerPage({super.key, required this.url}) {
    debugPrint('DEBUG: ViewerPage constructor called with URL: "$url"');
  }

  @override
  _ViewerPageState createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  bool _isLoading = true;
  String? _localPDFPath;
  late String _fileType; // Change from boolean flags to a string type

  @override
  void initState() {
    super.initState();
    debugPrint('DEBUG: ViewerPage initState');
    debugPrint('DEBUG: Received URL: "${widget.url}"');
    debugPrint('DEBUG: URL length: ${widget.url.length}');
    debugPrint('DEBUG: URL characters: ${widget.url.codeUnits}');

    if (widget.url.isEmpty) {
      debugPrint('ERROR: Empty URL provided to ViewerPage');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No file URL provided')),
        );
        Navigator.pop(context);
      });
      return;
    }

    _fileType = _determineFileType(widget.url);
    debugPrint('DEBUG: Determined file type: $_fileType');
    _prepareFile();
  }

  String _determineFileType(String url) {
    final lowercaseUrl = url.toLowerCase().split('?').first;
    debugPrint('DEBUG: Determining file type for URL: "$lowercaseUrl"');

    if (lowercaseUrl.endsWith('.pdf')) {
      debugPrint('DEBUG: Detected PDF file');
      return 'pdf';
    } else if (lowercaseUrl.endsWith('.jpg') ||
        lowercaseUrl.endsWith('.jpeg') ||
        lowercaseUrl.endsWith('.png') ||
        lowercaseUrl.endsWith('.gif') ||
        lowercaseUrl.endsWith('.webp') ||
        lowercaseUrl.endsWith('.bmp')) {
      debugPrint('DEBUG: Detected image file');
      return 'image';
    }
    debugPrint('DEBUG: Unknown file type');
    return 'unknown';
  }

  /// Prepares the file for viewing.
  Future<void> _prepareFile() async {
    if (kIsWeb) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final sanitizedUrl = widget.url.split('?').first.toLowerCase();
      final isPDF = sanitizedUrl.endsWith('.pdf');

      if (isPDF) {
        final response = await http.get(Uri.parse(widget.url));
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final tempDir = await getTemporaryDirectory();
          final fileName = p.basename(sanitizedUrl);
          final filePath = p.join(tempDir.path, fileName);
          final file = File(filePath);

          await file.writeAsBytes(bytes, flush: true);

          if (mounted) {
            setState(() {
              _localPDFPath = filePath;
              _isLoading = false;
            });
          }
        } else {
          throw Exception('Failed to download PDF');
        }
      } else {
        setState(() {
          _isLoading = false;
        });
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('View File'),
          backgroundColor: const Color(0xFF0E4CAF)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    debugPrint('Building content for fileType: $_fileType');
    switch (_fileType) {
      case 'image':
        return _buildImageView();
      case 'pdf':
        if (kIsWeb) {
          return SfPdfViewer.network(
            widget.url,
            onDocumentLoadFailed: (details) {
              debugPrint('PDF Error: ${details.description}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Error loading PDF: ${details.description}')),
              );
              return;
            },
          );
        } else {
          return _localPDFPath != null
              ? _buildPDFView()
              : const Center(child: Text('Failed to load PDF.'));
        }
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Unsupported file type: $_fileType\nURL: ${widget.url}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
    }
  }

  Widget _buildImageView() {
    return Center(
      child: PhotoView(
        imageProvider: NetworkImage(widget.url),
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorBuilder: (context, error, stackTrace) {
          debugPrint('ERROR: PhotoView -> $error');
          debugPrint('STACK TRACE:\n$stackTrace');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 40, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading image: ${error.toString()}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
        backgroundDecoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
      ),
    );
  }

  /// Builds the PDF viewer widget for mobile.
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
}
