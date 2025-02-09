// maintenance_section.dart
import 'package:ctp/adminScreens/viewer_page.dart';
import 'package:ctp/pages/truck_page.dart';
import 'package:ctp/pages/vehicles_list.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

// import 'dart:html' as html; // For web
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/pages/truckForms/custom_radio_button.dart';
import 'package:ctp/pages/truckForms/custom_text_field.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';

class MaintenanceEditSection extends StatefulWidget {
  final String vehicleId;
  final bool isUploading;
  final bool isEditing;
  final String oemInspectionType;
  final String oemInspectionExplanation;
  final String? maintenanceDocUrl;
  final String? warrantyDocUrl;
  final Function(File?) onMaintenanceFileSelected;
  final Function(File?) onWarrantyFileSelected;
  final String maintenanceSelection;
  final String warrantySelection;
  final File? maintenanceDocFile;
  final File? warrantyDocFile;
  final VoidCallback onProgressUpdate;
  final bool isFromAdmin;

  const MaintenanceEditSection(
      {super.key,
      required this.vehicleId,
      required this.isUploading,
      this.isEditing = false,
      required this.onMaintenanceFileSelected,
      required this.onWarrantyFileSelected,
      required this.oemInspectionType,
      required this.oemInspectionExplanation,
      required this.onProgressUpdate,
      this.maintenanceDocUrl,
      this.warrantyDocUrl,
      required this.maintenanceSelection,
      required this.warrantySelection,
      this.maintenanceDocFile,
      this.warrantyDocFile,
      required this.isFromAdmin});

  @override
  MaintenanceEditSectionState createState() => MaintenanceEditSectionState();
}

class MaintenanceEditSectionState extends State<MaintenanceEditSection>
    with AutomaticKeepAliveClientMixin {
  late TextEditingController _oemReasonController;
  late String _oemInspectionType;
  Uint8List? _maintenanceDocFile;
  Uint8List? _warrantyDocFile;
  String? _maintenanceDocFileName;
  String? _warrantyDocFileName;

  @override
  void initState() {
    super.initState();

    _oemInspectionType = widget.oemInspectionType;
    _oemReasonController =
        TextEditingController(text: widget.oemInspectionExplanation);

    // Initialize files with existing data if available
    // _maintenanceDocFile = widget.maintenanceDocFile;
    // _warrantyDocFile = widget.warrantyDocFile;
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Add listener for progress updates
    _oemReasonController.addListener(() {
      notifyProgress();
    });
  }

  @override
  void dispose() {
    _oemReasonController.dispose();
    super.dispose();
  }

  void clearData() {
    setState(() {
      _oemInspectionType = 'yes';
      _oemReasonController.clear();
      _maintenanceDocFile = null;
      _warrantyDocFile = null;
    });
  }

  // Update method to handle existing data
  void loadMaintenanceData(Map<String, dynamic>? maintenanceData) {
    if (maintenanceData != null) {
      setState(() {
        _oemInspectionType = maintenanceData['oemInspectionType'] ?? 'yes';
        _oemReasonController.text = maintenanceData['oemReason'] ?? '';

        // Handle document URLs if they exist
        if (maintenanceData['maintenanceDocUrl'] != null) {
          widget.onMaintenanceFileSelected(null); // Clear any existing file
        }
        if (maintenanceData['warrantyDocUrl'] != null) {
          widget.onWarrantyFileSelected(null); // Clear any existing file
        }
      });
    }
  }

  // Method to save maintenance data
  Future<bool> saveMaintenanceData() async {
    String? oemReason =
        _oemInspectionType == 'no' ? _oemReasonController.text.trim() : null;

    if (_oemInspectionType == 'no' &&
        (oemReason == null || oemReason.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please explain why OEM inspection is not possible.'),
        ),
      );
      return false;
    }

    // Prepare data to send
    Map<String, dynamic> maintenanceData = {
      'vehicleId': widget.vehicleId,
      'oemInspectionType': _oemInspectionType,
      'oemReason': oemReason,
    };

    try {
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .set({'maintenanceData': maintenanceData}, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maintenance saved successfully.')),
      );

      return true;
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save maintenance: $error')),
      );
      return false;
    }
  }

  Future<void> _pickMaintenanceDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'doc',
          'docx',
          'xls',
          'xlsx'
        ],
      );

      if (result != null) {
        final bytes = await result.files.single.xFile.readAsBytes();
        _maintenanceDocFile = bytes;
        _maintenanceDocFileName = result.files.single.xFile.name;
        setState(() {});

        // // Show loading dialog during conversion
        // showDialog(
        //   context: context,
        //   barrierDismissible: false,
        //   builder: (BuildContext context) {
        //     return const Center(
        //       child: CircularProgressIndicator(
        //         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        //       ),
        //     );
        //   },
        // );

        // Convert file to PDF if possible
        // File? processedFile = await convertToPdf(selectedFile);

        // Dismiss loading dialog
        // if (mounted) Navigator.pop(context);

        // if (processedFile != null) {
        //   setState(() {
        //     _maintenanceDocFile = processedFile;
        //     widget.onMaintenanceFileSelected(processedFile);
        //   });
        //   notifyProgress();
        // }
      }
    } catch (e) {
      // Dismiss loading dialog if showing
      // if (mounted) Navigator.pop(context);

      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Error picking maintenance file: $e')),
      // );
    }
  }

  Future<void> _pickWarrantyDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'doc',
          'docx',
          'xls',
          'xlsx'
        ],
      );

      if (result != null) {
        final bytes = await result.files.single.xFile.readAsBytes();
        _warrantyDocFile = bytes;
        _warrantyDocFileName = result.files.single.xFile.name;
        setState(() {});

        // Show loading dialog during conversion
        // showDialog(
        //   context: context,
        //   barrierDismissible: false,
        //   builder: (BuildContext context) {
        //     return const Center(
        //       child: CircularProgressIndicator(
        //         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        //       ),
        //     );
        //   },
        // );

        // Convert file to PDF if possible
        // File? processedFile = await convertToPdf(selectedFile);

        // // Dismiss loading dialog
        // if (mounted) Navigator.pop(context);

        // if (processedFile != null) {
        //   setState(() {
        //     _warrantyDocFile = processedFile;
        //     widget.onWarrantyFileSelected(processedFile);
        //   });
        //   notifyProgress();
        // }
      }
    } catch (e) {
      // // Dismiss loading dialog if showing
      // if (mounted) Navigator.pop(context);

      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Error picking warranty file: $e')),
      // );
    }
  }

  IconData _getFileIcon(String fileName) {
    final extension =
        path.extension(fileName).toLowerCase().trim().split("?").first.trim();

    switch (extension) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.xls':
      case '.xlsx':
        return Icons.grid_on;
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return Icons.image;
      case '.txt':
        return Icons.text_snippet;
      case '.zip':
      case '.rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  bool _isImageFile(String path) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    String extension = path.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }

  String getFileNameFromUrl(String url) {
    // if (url.contains('maintenance_doc')) {
    //   return 'Maintenance Doc';
    // } else if (url.contains('warranty_doc')) {
    //   return 'Warranty Doc';
    // }
    // Fallback to original filename if pattern doesn't match
    return url.split('/').last.split('?').first;
  }

  void updateMaintenanceFile(Uint8List? file) {
    setState(() {
      _maintenanceDocFile = file;
    });
    notifyProgress();
  }

  void updateWarrantyFile(Uint8List? file) {
    setState(() {
      _warrantyDocFile = file;
    });
    notifyProgress();
  }

  double getCompletionPercentage() {
    int totalFields = 0;
    int filledFields = 0;

    // Check for maintenance document
    if (widget.maintenanceSelection == 'yes') {
      totalFields += 1;
      if (_maintenanceDocFile != null || widget.maintenanceDocUrl != null) {
        filledFields += 1;
      }

      // OEM Inspection fields
      totalFields += 1;
      filledFields += 1; // Always filled since it has a default value

      if (_oemInspectionType == 'no') {
        totalFields += 1;
        if (_oemReasonController.text.trim().isNotEmpty) {
          filledFields += 1;
        }
      }
    }

    // Check for warranty document
    if (widget.warrantySelection == 'yes') {
      totalFields += 1;
      if (_warrantyDocFile != null || widget.warrantyDocUrl != null) {
        filledFields += 1;
      }
    }

    if (totalFields == 0) return 1.0; // If no fields are required
    return filledFields / totalFields;
  }

  void notifyProgress() {
    widget.onProgressUpdate();
  }

  Future<void> _viewPdf(String url, String title) async {
    try {
      // Show loading indicator

      // if (kIsWeb) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => ViewerPage(url: url)));
      // html.window.open(url, "_blank");
      return;
      // }
      // showDialog(
      //   context: context,
      //   barrierDismissible: false,
      //   builder: (BuildContext context) {
      //     return const Center(
      //       child: CircularProgressIndicator(
      //         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      //       ),
      //     );
      //   },
      // );
      // Download and cache the PDF
      // final response = await http.get(Uri.parse(url));
      // final bytes = response.bodyBytes;
      // final dir = await getTemporaryDirectory();
      // final file = File('${dir.path}/temp.pdf');
      // await file.writeAsBytes(bytes);

      // Dismiss loading indicator
      // if (mounted) Navigator.pop(context);

      // Show PDF viewer
      // if (mounted) {
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //       builder: (context) => Scaffold(
      //         appBar: AppBar(
      //           title: Text(title),
      //           backgroundColor: const Color(0xFF0E4CAF),
      //         ),
      //         body: PDFView(
      //           filePath: file.path,
      //           enableSwipe: true,
      //           swipeHorizontal: false,
      //           autoSpacing: true,
      //           pageFling: true,
      //           pageSnap: true,
      //           defaultPage: 0,
      //           fitPolicy: FitPolicy.BOTH,
      //           preventLinkNavigation: false,
      //           onError: (error) {
      //             ScaffoldMessenger.of(context).showSnackBar(
      //               SnackBar(content: Text('Error: $error')),
      //             );
      //           },
      //           onPageError: (page, error) {
      //             ScaffoldMessenger.of(context).showSnackBar(
      //               SnackBar(content: Text('Error on page $page: $error')),
      //             );
      //           },
      //         ),
      //       ),
      //     ),
      //   );
      // }
    } catch (e) {
      // Dismiss loading indicator if showing
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error viewing PDF: $e')),
      );
    }
  }

  void _showDocumentOptions(bool isMaintenance) {
    final String? url =
        isMaintenance ? widget.maintenanceDocUrl : widget.warrantyDocUrl;
    final Uint8List? file =
        isMaintenance ? _maintenanceDocFile : _warrantyDocFile;
    final String title =
        isMaintenance ? 'Maintenance Document' : 'Warranty Document';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View'),
                onTap: context.read<UserProvider>().getUserRole == "dealer"
                    ? () async {
                        Navigator.pop(context);
                        if (url != null && url != "") {
                          print("URL of: $url");
                          await _viewPdf(url, title);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("No document available")));
                        }
                      }
                    : () async {
                        Navigator.pop(context);
                        if (url != null && file != null) {
                          print("URL of: $url");
                          await _viewPdf(url, title);
                        } else if (file == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Please upload first")));
                          // For local files
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder: (context) => Scaffold(
                          //       appBar: AppBar(
                          //         title: Text(title),
                          //         backgroundColor: const Color(0xFF0E4CAF),
                          //       ),
                          //       body: PDFView(
                          //         pdfData: file,
                          //         enableSwipe: true,
                          //         swipeHorizontal: false,
                          //         autoSpacing: true,
                          //         pageFling: true,
                          //         pageSnap: true,
                          //         defaultPage: 0,
                          //         fitPolicy: FitPolicy.BOTH,
                          //         preventLinkNavigation: false,
                          //         onError: (error) {
                          //           ScaffoldMessenger.of(context).showSnackBar(
                          //             SnackBar(content: Text('Error: $error')),
                          //           );
                          //         },
                          //         onPageError: (page, error) {
                          //           ScaffoldMessenger.of(context).showSnackBar(
                          //             SnackBar(
                          //                 content:
                          //                     Text('Error on page $page: $error')),
                          //           );
                          //         },
                          //       ),
                          //     ),
                          //   ),
                          // );
                        }
                      },
              ),
              if (context.read<UserProvider>().getUserRole != "dealer")
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Change'),
                  onTap: () {
                    Navigator.pop(context);
                    if (isMaintenance) {
                      _pickMaintenanceDocument();
                    } else {
                      _pickWarrantyDocument();
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  // Future<File?> convertToPdf(File file) async {
  //   try {
  //     final String extension = file.path.split('.').last.toLowerCase();
  //     final pdf = pw.Document();

  //     if (_isImageFile(file.path)) {
  //       // Handle image files
  //       final image = img.decodeImage(await file.readAsBytes());
  //       if (image != null) {
  //         final pdfImage = pw.MemoryImage(
  //           img.encodeJpg(image),
  //         );

  //         pdf.addPage(
  //           pw.Page(
  //             build: (pw.Context context) {
  //               return pw.Center(
  //                 child: pw.Image(pdfImage),
  //               );
  //             },
  //           ),
  //         );
  //       }
  //     } else if (extension == 'pdf') {
  //       // If it's already a PDF, return the original file
  //       return file;
  //     } else {
  //       // For other file types, create a PDF with a message
  //       pdf.addPage(
  //         pw.Page(
  //           build: (pw.Context context) {
  //             return pw.Center(
  //               child: pw.Text(
  //                 'Original file: ${file.path.split('/').last}\n'
  //                 'File type: $extension\n'
  //                 'Original file is preserved as-is',
  //               ),
  //             );
  //           },
  //         ),
  //       );
  //       // Return original file for non-convertible types
  //       return file;
  //     }

  //     // Save the PDF
  //     final output = await getTemporaryDirectory();
  //     final pdfFile = File(
  //         '${output.path}/converted_${DateTime.now().millisecondsSinceEpoch}.pdf');
  //     await pdfFile.writeAsBytes(await pdf.save());
  //     return pdfFile;
  //   } catch (e) {
  //     print('Error converting to PDF: $e');
  //     // Return original file if conversion fails
  //     return file;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userProvider = Provider.of<UserProvider>(context);
    final String userRole = userProvider.getUserRole;
    print("UserRole: $userRole");
    print("Maintenance Selection: ${widget.maintenanceSelection}");
    print("Warranty Selection: ${widget.warrantySelection}");
    final bool isAdmin = userRole == 'admin';
    final bool isDealer = userRole == 'dealer';
    final bool isTransporter = userRole == 'transporter';
    // NEW: handle "sales"
    final bool isSales = userRole == 'sales';

    return Scaffold(
      body: GradientBackground(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: 20,
                top: MediaQuery.of(context).size.height * 0.05,
                left: 10,
                right: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  if (widget.maintenanceSelection == 'yes' ||
                      widget.maintenanceSelection == '') ...[
                    Center(
                      child: Text(
                        'Maintenance'.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 25,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (widget.maintenanceDocUrl == null)
                      Center(
                        child: Text(
                          'PLEASE ATTACH MAINTENANCE DOCUMENTATION'
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 15),
                    InkWell(
                      // Let dealers, sales, admin, transporters pick the doc
                      onTap: (isAdmin || isSales || isTransporter)
                          ? _pickMaintenanceDocument
                          : null,
                      borderRadius: BorderRadius.circular(10.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E4CAF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                            color: const Color(0xFF0E4CAF),
                            width: 2.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (_maintenanceDocFile == null &&
                                widget.maintenanceDocUrl == null)
                              Icon(
                                Icons.drive_folder_upload_outlined,
                                color: Colors.white,
                                size: 50.0,
                                semanticLabel: 'Upload Maintenance Document',
                              ),
                            const SizedBox(height: 10),
                            if (_maintenanceDocFile != null ||
                                widget.maintenanceDocUrl != null)
                              InkWell(
                                onTap: () => _showDocumentOptions(true),
                                child: Column(
                                  children: [
                                    if (_maintenanceDocFile != null)
                                      if (_isImageFile(
                                          _maintenanceDocFileName!))
                                        Column(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              child: Image.memory(
                                                _maintenanceDocFile!,
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            SizedBox(height: 5),
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16.0),
                                              child: Text(
                                                _maintenanceDocFileName!,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Column(
                                          children: [
                                            Icon(
                                              _getFileIcon(
                                                  _maintenanceDocFileName!),
                                              color: Colors.white,
                                              size: 50.0,
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16.0),
                                              child: Text(
                                                _maintenanceDocFileName!,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        )
                                    else if (widget.maintenanceDocUrl != null)
                                      if (_isImageFile(
                                          widget.maintenanceDocUrl!))
                                        Column(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                              child: Image.network(
                                                widget.maintenanceDocUrl!,
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            SizedBox(height: 5),
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16.0),
                                              child: Text(
                                                getFileNameFromUrl(
                                                    widget.maintenanceDocUrl!),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Column(
                                          children: [
                                            Icon(
                                              _getFileIcon(
                                                  widget.maintenanceDocUrl!),
                                              color: Colors.white,
                                              size: 50.0,
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16.0),
                                              child: Text(
                                                getFileNameFromUrl(
                                                    widget.maintenanceDocUrl!),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                    const SizedBox(height: 8),
                                    if (widget.isUploading)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          CircularProgressIndicator(),
                                          SizedBox(width: 10),
                                          Text(
                                            'Uploading...',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              )
                            else if (!widget.isUploading)
                              const Text(
                                'MAINTENANCE DOC UPLOAD',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: Text(
                        'CAN YOUR VEHICLE BE SENT TO OEM FOR A FULL INSPECTION UNDER R&M CONTRACT?'
                            .toUpperCase(),
                        style:
                            const TextStyle(fontSize: 15, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: Text(
                        'Please note that OEM will charge you for inspection'
                            .toUpperCase(),
                        style:
                            const TextStyle(fontSize: 12, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomRadioButton(
                          label: 'Yes',
                          value: 'yes',
                          groupValue: _oemInspectionType,
                          onChanged: (value) {
                            setState(() {
                              _oemInspectionType = value!;
                              if (_oemInspectionType == 'yes') {
                                _oemReasonController.clear();
                              }
                            });
                            notifyProgress();
                          },
                          // Allow dealers, sales, admin, transporters to edit
                          enabled: (isAdmin || isSales || isTransporter),
                        ),
                        const SizedBox(width: 15),
                        CustomRadioButton(
                          label: 'No',
                          value: 'no',
                          groupValue: _oemInspectionType,
                          onChanged: (value) {
                            setState(() {
                              _oemInspectionType = value!;
                            });
                            notifyProgress();
                          },
                          enabled: (isAdmin || isSales || isTransporter),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // Conditional Explanation Input Field
                    if (_oemInspectionType == 'no')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: CustomTextField(
                          controller: _oemReasonController,
                          hintText: 'ENTER REASONING HERE'.toUpperCase(),
                          enabled:
                              (isAdmin || isDealer || isSales || isTransporter),
                        ),
                      ),
                    const SizedBox(height: 15),
                  ],
                  if (widget.warrantySelection == 'yes' ||
                      widget.warrantySelection == '') ...[
                    if (widget.warrantyDocUrl == null)
                      Center(
                        child: Text(
                          'PLEASE ATTACH WARRANTY DOCUMENTATION'.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 15),
                    InkWell(
                      // Let dealers, sales, admin, transporters pick the doc
                      onTap: (isAdmin || isSales || isTransporter)
                          ? _pickWarrantyDocument
                          : null,
                      borderRadius: BorderRadius.circular(10.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E4CAF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                            color: const Color(0xFF0E4CAF),
                            width: 2.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (_warrantyDocFile == null &&
                                widget.warrantyDocUrl == null)
                              Icon(
                                Icons.drive_folder_upload_outlined,
                                color: Colors.white,
                                size: 50.0,
                                semanticLabel: 'Upload Warranty Document',
                              ),
                            const SizedBox(height: 10),
                            if (_warrantyDocFile != null ||
                                widget.warrantyDocUrl != null)
                              InkWell(
                                onTap: () => _showDocumentOptions(false),
                                child: Column(
                                  children: [
                                    if (_warrantyDocFile != null)
                                      if (_isImageFile(_warrantyDocFileName!))
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: Image.memory(
                                            _warrantyDocFile!,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      else
                                        Column(
                                          children: [
                                            Icon(
                                              _getFileIcon(
                                                  _warrantyDocFileName!),
                                              color: Colors.white,
                                              size: 50.0,
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16.0),
                                              child: Text(
                                                _warrantyDocFileName!,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        )
                                    else if (widget.warrantyDocUrl != null)
                                      if (_isImageFile(widget.warrantyDocUrl!))
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: Image.network(
                                            widget.warrantyDocUrl!,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      else
                                        Column(
                                          children: [
                                            Icon(
                                              _getFileIcon(
                                                  widget.warrantyDocUrl!),
                                              color: Colors.white,
                                              size: 50.0,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              getFileNameFromUrl(
                                                  widget.warrantyDocUrl!),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                    const SizedBox(height: 8),
                                    if (widget.isUploading)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          CircularProgressIndicator(),
                                          SizedBox(width: 10),
                                          Text(
                                            'Uploading...',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              )
                            else if (!widget.isUploading)
                              const Text(
                                'WARRANTY DOC UPLOAD',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Show the DONE button for dealers, sales, admin, or transporters
                    if (isTransporter || isDealer || isSales || isAdmin)
                      CustomButton(
                        onPressed: isDealer
                            ? () {
                                Navigator.of(context).pop();
                              }
                            : () async {
                                // Show loading indicator
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                );

                                try {
                                  String? maintenanceDocUrl =
                                      widget.maintenanceDocUrl;
                                  String? warrantyDocUrl =
                                      widget.warrantyDocUrl;

                                  // Upload maintenance file if new one is selected
                                  if (_maintenanceDocFile != null) {
                                    final storageRef = FirebaseStorage.instance
                                        .ref()
                                        .child(
                                            'vehicles/${widget.vehicleId}/maintenance')
                                        .child(
                                            'maintenance_doc_${DateTime.now().millisecondsSinceEpoch}$_maintenanceDocFileName');

                                    await storageRef
                                        .putData(_maintenanceDocFile!);
                                    maintenanceDocUrl =
                                        await storageRef.getDownloadURL();
                                  }

                                  // Upload warranty file if new one is selected
                                  if (_warrantyDocFile != null) {
                                    final storageRef = FirebaseStorage.instance
                                        .ref()
                                        .child(
                                            'vehicles/${widget.vehicleId}/maintenance')
                                        .child(
                                            'warranty_doc_${DateTime.now().millisecondsSinceEpoch}$_warrantyDocFileName');

                                    await storageRef.putData(_warrantyDocFile!);
                                    warrantyDocUrl =
                                        await storageRef.getDownloadURL();
                                  }

                                  // Prepare the maintenance data
                                  Map<String, dynamic> maintenanceData = {
                                    'vehicleId': widget.vehicleId,
                                    'oemInspectionType': _oemInspectionType,
                                    'oemReason': _oemInspectionType == 'no'
                                        ? _oemReasonController.text.trim()
                                        : null,
                                    'maintenanceDocUrl': maintenanceDocUrl,
                                    'warrantyDocUrl': warrantyDocUrl,
                                    'maintenanceSelection':
                                        widget.maintenanceSelection,
                                    'warrantySelection':
                                        widget.warrantySelection,
                                    'lastUpdated': FieldValue.serverTimestamp(),
                                  };

                                  // Update the vehicle document in Firestore

                                  log("Maintenance data before save ${maintenanceData}");
                                  await FirebaseFirestore.instance
                                      .collection('vehicles')
                                      .doc(widget.vehicleId)
                                      .set(
                                          widget.isFromAdmin
                                              ? {
                                                  "maintenanceData":
                                                      maintenanceData
                                                }
                                              : {
                                                  'maintenance':
                                                      maintenanceData,
                                                },
                                          SetOptions(merge: true));

                                  // Dismiss loading indicator and pop back
                                  Navigator.pop(
                                      context); // Dismiss loading indicator
                                  Navigator.pop(
                                      context); // Return to previous screen
                                  if (widget.isFromAdmin) {
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const VehiclesListPage()));
                                  } else {
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const TruckPage()));
                                  }

                                  // Show success message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Maintenance data saved successfully')),
                                  );
                                } catch (error) {
                                  // Dismiss loading indicator
                                  Navigator.pop(context);

                                  // Show error message
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Error saving maintenance data: $error'),
                                    ),
                                  );
                                }
                              },
                        text: 'DONE',
                        borderColor: Colors.deepOrange,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true; // Ensure the state is kept alive
}
