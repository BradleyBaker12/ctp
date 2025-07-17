import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:auto_route/auto_route.dart';
@RoutePage()class PdfViewerPage extends StatelessWidget {
  final String pdfUrl;

  const PdfViewerPage({super.key, required this.pdfUrl});

  Future<File> _downloadAndSaveFile(String url, String fileName) async {
    final response = await HttpClient().getUrl(Uri.parse(url));
    final bytes = await response.close().then((response) =>
        response.fold<List<int>>([], (buffer, data) => buffer..addAll(data)));
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  void _openInNewTab(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // For web, open the URL in a new browser tab
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openInNewTab(pdfUrl);
        Navigator.pop(context); // Close the current page after opening new tab
      });

      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // For iOS/Android
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<File>(
        future: _downloadAndSaveFile(pdfUrl, "document.pdf"),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Failed to load PDF"));
          }

          return PDFView(
            filePath: snapshot.data!.path,
            autoSpacing: true,
            swipeHorizontal: false,
            pageFling: true,
            onRender: (pages) {
              print("Total pages: $pages");
            },
            onError: (error) {
              print("PDF Error: $error");
            },
            onPageError: (page, error) {
              print("Page $page: Error: $error");
            },
            onPageChanged: (page, total) {
              print("Page changed: $page/$total");
            },
          );
        },
      ),
    );
  }
}
