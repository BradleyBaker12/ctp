// maintenance_section.dart

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

  const MaintenanceEditSection({
    super.key,
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
  });

  @override
  MaintenanceEditSectionState createState() => MaintenanceEditSectionState();
}

class MaintenanceEditSectionState extends State<MaintenanceEditSection>
    with AutomaticKeepAliveClientMixin {
  late TextEditingController _oemReasonController;
  late String _oemInspectionType;
  File? _maintenanceDocFile;
  File? _warrantyDocFile;

  @override
  void initState() {
    super.initState();
    _oemInspectionType = widget.oemInspectionType;
    _oemReasonController =
        TextEditingController(text: widget.oemInspectionExplanation);

    _maintenanceDocFile = widget.maintenanceDocFile;
    _warrantyDocFile = widget.warrantyDocFile;

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

  void loadMaintenanceData(Map<String, dynamic>? maintenanceData) {
    if (maintenanceData != null) {
      setState(() {
        _oemInspectionType = maintenanceData['oemInspectionType'] ?? 'yes';
        _oemReasonController.text = maintenanceData['oemReason'] ?? '';

        if (maintenanceData['maintenanceDocUrl'] != null) {
          widget.onMaintenanceFileSelected(null);
        }
        if (maintenanceData['warrantyDocUrl'] != null) {
          widget.onWarrantyFileSelected(null);
        }
      });
    }
  }

  Future<bool> saveMaintenanceData() async {
    String? oemReason =
        _oemInspectionType == 'no' ? _oemReasonController.text.trim() : null;

    if (_oemInspectionType == 'no' && (oemReason!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please explain why OEM inspection is not possible.')),
      );
      return false;
    }

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

  Future<File?> convertToPdf(File file) async {
    try {
      final String extension = file.path.split('.').last.toLowerCase();
      final pdf = pw.Document();

      if (_isImageFile(file.path)) {
        final image = img.decodeImage(await file.readAsBytes());
        if (image != null) {
          final pdfImage = pw.MemoryImage(
            img.encodeJpg(image),
          );
          pdf.addPage(
            pw.Page(
              build: (pw.Context context) {
                return pw.Center(child: pw.Image(pdfImage));
              },
            ),
          );
        }
      } else if (extension == 'pdf') {
        return file;
      } else {
        // Non-image, non-pdf files will just return the original file
        return file;
      }

      final output = await getTemporaryDirectory();
      final pdfFile = File(
          '${output.path}/converted_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await pdfFile.writeAsBytes(await pdf.save());
      return pdfFile;
    } catch (e) {
      print('Error converting to PDF: $e');
      return file;
    }
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.grid_on;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  bool _isImageFile(String path) {
    final imageExtensions = ['jpg', 'jpeg', 'png'];
    String extension = path.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }

  bool isPdfFile(String path) {
    return path.toLowerCase().endsWith('.pdf');
  }

  void updateMaintenanceFile(File? file) {
    setState(() {
      _maintenanceDocFile = file;
    });
    notifyProgress();
  }

  void updateWarrantyFile(File? file) {
    setState(() {
      _warrantyDocFile = file;
    });
    notifyProgress();
  }

  double getCompletionPercentage() {
    int totalFields = 0;
    int filledFields = 0;

    if (widget.maintenanceSelection == 'yes') {
      totalFields += 1;
      if (_maintenanceDocFile != null || widget.maintenanceDocUrl != null) {
        filledFields += 1;
      }

      totalFields += 1;
      filledFields += 1;

      if (_oemInspectionType == 'no') {
        totalFields += 1;
        if (_oemReasonController.text.trim().isNotEmpty) {
          filledFields += 1;
        }
      }
    }

    if (widget.warrantySelection == 'yes') {
      totalFields += 1;
      if (_warrantyDocFile != null || widget.warrantyDocUrl != null) {
        filledFields += 1;
      }
    }

    if (totalFields == 0) return 1.0;
    return filledFields / totalFields;
  }

  void notifyProgress() {
    widget.onProgressUpdate();
  }

  Future<void> _viewPdf(String url, String title) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        },
      );
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/temp.pdf');
      await file.writeAsBytes(bytes);

      if (mounted) Navigator.pop(context);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: Text(title),
                backgroundColor: const Color(0xFF0E4CAF),
              ),
              body: PDFView(
                filePath: file.path,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: true,
                pageFling: true,
                pageSnap: true,
                defaultPage: 0,
                fitPolicy: FitPolicy.BOTH,
                preventLinkNavigation: false,
                onError: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $error')),
                  );
                },
                onPageError: (page, error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error on page $page: $error')),
                  );
                },
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error viewing PDF: $e')),
      );
    }
  }

  Future<String?> _getContentType(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      if (response.headers.containsKey('content-type')) {
        return response.headers['content-type']!;
      }
    } catch (e) {
      print('Error fetching content type: $e');
    }
    return null;
  }

  Future<String> _detectFileType(File file) async {
    final String extension = file.path.split('.').last.toLowerCase();
    if (isPdfFile(file.path)) return 'pdf';
    if (_isImageFile(file.path)) return 'image';

    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded != null) return 'image';

      if (bytes.length > 4) {
        final header = String.fromCharCodes(bytes.sublist(0, 4));
        if (header == '%PDF') return 'pdf';
      }
    } catch (e) {
      print('Error detecting file type: $e');
    }

    return 'unsupported';
  }

  Future<void> _viewDocument(bool isMaintenance) async {
    final String? url =
        isMaintenance ? widget.maintenanceDocUrl : widget.warrantyDocUrl;
    final File? file = isMaintenance ? _maintenanceDocFile : _warrantyDocFile;
    final String title =
        isMaintenance ? 'Maintenance Document' : 'Warranty Document';

    if (url != null) {
      String path = url;
      String? contentType = await _getContentType(url);
      if (contentType != null) {
        if (contentType.contains('pdf')) {
          await _viewPdf(url, title);
          return;
        } else if (contentType.contains('image')) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: Text(title),
                  backgroundColor: const Color(0xFF0E4CAF),
                ),
                body: Center(
                  child: InteractiveViewer(
                    child: Image.network(url),
                  ),
                ),
              ),
            ),
          );
          return;
        }
      }

      // Fallback to extension checks
      if (isPdfFile(path)) {
        await _viewPdf(url, title);
      } else if (_isImageFile(path)) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: Text(title),
                backgroundColor: const Color(0xFF0E4CAF),
              ),
              body: Center(
                child: InteractiveViewer(
                  child: Image.network(url),
                ),
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unsupported file format.')),
        );
      }
    } else if (file != null) {
      String fileType = await _detectFileType(file);
      if (fileType == 'pdf') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: Text(title),
                backgroundColor: const Color(0xFF0E4CAF),
              ),
              body: PDFView(
                filePath: file.path,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: true,
                pageFling: true,
                pageSnap: true,
                defaultPage: 0,
                fitPolicy: FitPolicy.BOTH,
              ),
            ),
          ),
        );
      } else if (fileType == 'image') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: Text(title),
                backgroundColor: const Color(0xFF0E4CAF),
              ),
              body: Center(
                child: InteractiveViewer(
                  child: Image.file(file),
                ),
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unsupported file format.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No document available to view.')),
      );
    }
  }

  void _showDocumentOptions(bool isMaintenance) {
    final bool isDealer =
        Provider.of<UserProvider>(context, listen: false).getUserRole ==
            'dealer';
    final bool isTransporter =
        Provider.of<UserProvider>(context, listen: false).getUserRole ==
            'transporter';

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
                onTap: () async {
                  Navigator.pop(context);
                  await _viewDocument(isMaintenance);
                },
              ),
              if (isTransporter)
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

  Future<void> _pickMaintenanceDocument() async {
    final bool isTransporter =
        Provider.of<UserProvider>(context, listen: false).getUserRole ==
            'transporter';
    if (!isTransporter) return;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        File selectedFile = File(result.files.single.path!);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          },
        );

        File? processedFile = await convertToPdf(selectedFile);

        if (mounted) Navigator.pop(context);

        if (processedFile != null) {
          setState(() {
            _maintenanceDocFile = processedFile;
            widget.onMaintenanceFileSelected(processedFile);
          });
          notifyProgress();
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking maintenance file: $e')),
      );
    }
  }

  Future<void> _pickWarrantyDocument() async {
    final bool isTransporter =
        Provider.of<UserProvider>(context, listen: false).getUserRole ==
            'transporter';
    if (!isTransporter) return;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        File selectedFile = File(result.files.single.path!);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          },
        );

        File? processedFile = await convertToPdf(selectedFile);

        if (mounted) Navigator.pop(context);

        if (processedFile != null) {
          setState(() {
            _warrantyDocFile = processedFile;
            widget.onWarrantyFileSelected(processedFile);
          });
          notifyProgress();
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking warranty file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userProvider = Provider.of<UserProvider>(context);
    final String userRole = userProvider.getUserRole;
    final bool isDealer = userRole == 'dealer';
    final bool isTransporter = userRole == 'transporter';

    return GradientBackground(
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                if (widget.maintenanceSelection == 'yes') ...[
                  Center(
                    child: Text(
                      'Maintenance'.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 25,
                          color: Colors.white,
                          fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: Text(
                      'PLEASE ATTACH MAINTENANCE DOCUMENTATION'.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
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
                    child: InkWell(
                      onTap: (isTransporter ||
                              (isDealer &&
                                  (widget.maintenanceDocUrl != null ||
                                      _maintenanceDocFile != null)))
                          ? () {
                              if (isTransporter) {
                                _showDocumentOptions(true);
                              } else if (isDealer) {
                                _viewDocument(true);
                              }
                            }
                          : null,
                      borderRadius: BorderRadius.circular(10.0),
                      child: Column(
                        children: [
                          if (_maintenanceDocFile == null &&
                              widget.maintenanceDocUrl == null)
                            if (isDealer)
                              const Text(
                                'No Maintenance Document Available',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                              )
                            else
                              const Icon(
                                Icons.drive_folder_upload_outlined,
                                color: Colors.white,
                                size: 50.0,
                                semanticLabel: 'Upload Maintenance Document',
                              ),
                          const SizedBox(height: 10),
                          if (_maintenanceDocFile != null ||
                              widget.maintenanceDocUrl != null)
                            Column(
                              children: [
                                // Always display "Maintenance Document" instead of file name
                                if (_maintenanceDocFile != null) ...[
                                  if (_isImageFile(_maintenanceDocFile!.path))
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.file(
                                        _maintenanceDocFile!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    Icon(
                                      _getFileIcon(_maintenanceDocFile!.path
                                          .split('.')
                                          .last),
                                      color: Colors.white,
                                      size: 50.0,
                                    ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Maintenance Document',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ] else if (widget.maintenanceDocUrl !=
                                    null) ...[
                                  if (_isImageFile(widget.maintenanceDocUrl!))
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        widget.maintenanceDocUrl!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    Icon(
                                      _getFileIcon(widget.maintenanceDocUrl!
                                          .split('.')
                                          .last),
                                      color: Colors.white,
                                      size: 50.0,
                                    ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Maintenance Document',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                if (widget.isUploading)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      CircularProgressIndicator(),
                                      SizedBox(width: 10),
                                      Text(
                                        'Uploading...',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                              ],
                            )
                          else if (!widget.isUploading && !isDealer)
                            const Text(
                              'MAINTENANCE DOCUMENT UPLOAD',
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
                      style: const TextStyle(fontSize: 15, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: Text(
                      'Please note that OEM will charge you for inspection'
                          .toUpperCase(),
                      style: const TextStyle(fontSize: 12, color: Colors.white),
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
                          if (isTransporter) {
                            setState(() {
                              _oemInspectionType = value!;
                              if (_oemInspectionType == 'yes') {
                                _oemReasonController.clear();
                              }
                            });
                            notifyProgress();
                          }
                        },
                        enabled: isTransporter,
                      ),
                      const SizedBox(width: 15),
                      CustomRadioButton(
                        label: 'No',
                        value: 'no',
                        groupValue: _oemInspectionType,
                        onChanged: (value) {
                          if (isTransporter) {
                            setState(() {
                              _oemInspectionType = value!;
                            });
                            notifyProgress();
                          }
                        },
                        enabled: isTransporter,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (_oemInspectionType == 'no')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: CustomTextField(
                        controller: _oemReasonController,
                        hintText: 'ENTER REASONING HERE'.toUpperCase(),
                        enabled: isTransporter,
                      ),
                    ),
                  const SizedBox(height: 15),
                ],
                if (widget.warrantySelection == 'yes') ...[
                  Center(
                    child: Text(
                      'PLEASE ATTACH WARRANTY DOCUMENTATION'.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
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
                    child: InkWell(
                      onTap: (isTransporter ||
                              (isDealer &&
                                  (widget.warrantyDocUrl != null ||
                                      _warrantyDocFile != null)))
                          ? () {
                              if (isTransporter) {
                                _showDocumentOptions(false);
                              } else if (isDealer) {
                                _viewDocument(false);
                              }
                            }
                          : null,
                      borderRadius: BorderRadius.circular(10.0),
                      child: Column(
                        children: [
                          if (_warrantyDocFile == null &&
                              widget.warrantyDocUrl == null)
                            if (isDealer)
                              const Text(
                                'No Warranty Document Available',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                              )
                            else
                              const Icon(
                                Icons.drive_folder_upload_outlined,
                                color: Colors.white,
                                size: 50.0,
                                semanticLabel: 'Upload Warranty Document',
                              ),
                          const SizedBox(height: 10),
                          if (_warrantyDocFile != null ||
                              widget.warrantyDocUrl != null)
                            Column(
                              children: [
                                // Always display "Warranty Document" instead of file name
                                if (_warrantyDocFile != null) ...[
                                  if (_isImageFile(_warrantyDocFile!.path))
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.file(
                                        _warrantyDocFile!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    Icon(
                                      _getFileIcon(_warrantyDocFile!.path
                                          .split('.')
                                          .last),
                                      color: Colors.white,
                                      size: 50.0,
                                    ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Warranty Document',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ] else if (widget.warrantyDocUrl != null) ...[
                                  if (_isImageFile(widget.warrantyDocUrl!))
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        widget.warrantyDocUrl!,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    Icon(
                                      _getFileIcon(widget.warrantyDocUrl!
                                          .split('.')
                                          .last),
                                      color: Colors.white,
                                      size: 50.0,
                                    ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Warranty Document',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                if (widget.isUploading)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      CircularProgressIndicator(),
                                      SizedBox(width: 10),
                                      Text(
                                        'Uploading...',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                              ],
                            )
                          else if (!widget.isUploading && !isDealer)
                            const Text(
                              'WARRANTY DOCUMENT UPLOAD',
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
                  if (isTransporter)
                    CustomButton(
                      onPressed: () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            );
                          },
                        );

                        try {
                          String? maintenanceDocUrl = widget.maintenanceDocUrl;
                          String? warrantyDocUrl = widget.warrantyDocUrl;

                          if (_maintenanceDocFile != null) {
                            final storageRef = FirebaseStorage.instance
                                .ref()
                                .child(
                                    'vehicles/${widget.vehicleId}/maintenance')
                                .child(
                                    'maintenance_doc_${DateTime.now().millisecondsSinceEpoch}');

                            await storageRef.putFile(_maintenanceDocFile!);
                            maintenanceDocUrl =
                                await storageRef.getDownloadURL();
                          }

                          if (_warrantyDocFile != null) {
                            final storageRef = FirebaseStorage.instance
                                .ref()
                                .child(
                                    'vehicles/${widget.vehicleId}/maintenance')
                                .child(
                                    'warranty_doc_${DateTime.now().millisecondsSinceEpoch}');

                            await storageRef.putFile(_warrantyDocFile!);
                            warrantyDocUrl = await storageRef.getDownloadURL();
                          }

                          Map<String, dynamic> maintenanceData = {
                            'vehicleId': widget.vehicleId,
                            'oemInspectionType': _oemInspectionType,
                            'oemReason': _oemInspectionType == 'no'
                                ? _oemReasonController.text.trim()
                                : null,
                            'maintenanceDocUrl': maintenanceDocUrl,
                            'warrantyDocUrl': warrantyDocUrl,
                            'maintenanceSelection': widget.maintenanceSelection,
                            'warrantySelection': widget.warrantySelection,
                            'lastUpdated': FieldValue.serverTimestamp(),
                          };

                          await FirebaseFirestore.instance
                              .collection('vehicles')
                              .doc(widget.vehicleId)
                              .set({
                            'maintenanceData': maintenanceData,
                          }, SetOptions(merge: true));

                          Navigator.pop(context);
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Maintenance data saved successfully')),
                          );
                        } catch (error) {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Error saving maintenance data: $error')),
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
    );
  }

  @override
  bool get wantKeepAlive => true;
}
