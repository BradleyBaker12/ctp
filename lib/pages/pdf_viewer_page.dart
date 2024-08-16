import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart'; // Import this package

class PdfViewerPage extends StatelessWidget {
  final String pdfUrl;

  const PdfViewerPage({Key? key, required this.pdfUrl}) : super(key: key);

  Future<File> _downloadAndSaveFile(String url, String fileName) async {
    final response = await HttpClient().getUrl(Uri.parse(url));
    final bytes = await response.close().then((response) =>
        response.fold<List<int>>([], (buffer, data) => buffer..addAll(data)));
    final directory = await getTemporaryDirectory(); // Now this will work
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  @override
  Widget build(BuildContext context) {
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
            swipeHorizontal: true,
            pageFling: true,
            onRender: (_pages) {
              print("Total pages: $_pages");
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
