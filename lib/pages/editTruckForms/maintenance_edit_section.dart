// maintenance_section.dart

import 'dart:io';
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
import 'package:ctp/components/custom_back_button.dart'; // Add this import

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

    // Initialize files with existing data if available
    _maintenanceDocFile = widget.maintenanceDocFile;
    _warrantyDocFile = widget.warrantyDocFile;

    // Add listener for progress updates
    _oemReasonController.addListener(() {
      notifyProgress();
    });

    // Load maintenance data when widget initializes
    _loadMaintenanceData();
  }

  Future<void> _loadMaintenanceData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .get();

      if (doc.exists && doc.data() != null) {
        final maintenanceData = doc.data()!['maintenanceData'];
        if (maintenanceData != null) {
          setState(() {
            _oemInspectionType = maintenanceData['oemInspectionType'] ?? 'yes';
            _oemReasonController.text = maintenanceData['oemReason'] ?? '';

            // Update the state with URLs if they exist
            if (widget.maintenanceDocUrl == null &&
                maintenanceData['maintenanceDocUrl'] != null) {
              widget.onMaintenanceFileSelected(null);
            }
            if (widget.warrantyDocUrl == null &&
                maintenanceData['warrantyDocUrl'] != null) {
              widget.onWarrantyFileSelected(null);
            }
          });
        }
      }
    } catch (e) {
      print('Error loading maintenance data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading maintenance data: $e')),
        );
      }
    }
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
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        File selectedFile = File(result.files.single.path!);

        // Show loading dialog during conversion
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

        // Convert file to PDF if possible
        File? processedFile = await convertToPdf(selectedFile);

        // Dismiss loading dialog
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
      // Dismiss loading dialog if showing
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking maintenance file: $e')),
      );
    }
  }

  Future<void> _pickWarrantyDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        File selectedFile = File(result.files.single.path!);

        // Show loading dialog during conversion
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

        // Convert file to PDF if possible
        File? processedFile = await convertToPdf(selectedFile);

        // Dismiss loading dialog
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
      // Dismiss loading dialog if showing
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking warranty file: $e')),
      );
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
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    String extension = path.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }

  String getFileNameFromUrl(String url) {
    if (url.contains('maintenance_doc')) {
      return 'Maintenance Doc';
    } else if (url.contains('warranty_doc')) {
      return 'Warranty Doc';
    }
    // Fallback to original filename if pattern doesn't match
    return url.split('/').last.split('?').first;
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
      // Download and cache the PDF
      final response = await http.get(Uri.parse(url));
      final bytes = response.bodyBytes;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/temp.pdf');
      await file.writeAsBytes(bytes);

      // Dismiss loading indicator
      if (mounted) Navigator.pop(context);

      // Show PDF viewer
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
    final File? file = isMaintenance ? _maintenanceDocFile : _warrantyDocFile;
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
                  if (url != null) {
                    await _viewPdf(url, title);
                  } else if (file != null) {
                    // For local files
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
                                SnackBar(
                                    content:
                                        Text('Error on page $page: $error')),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
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

  Future<File?> convertToPdf(File file) async {
    try {
      final String extension = file.path.split('.').last.toLowerCase();
      final pdf = pw.Document();

      if (_isImageFile(file.path)) {
        // Handle image files
        final image = img.decodeImage(await file.readAsBytes());
        if (image != null) {
          final pdfImage = pw.MemoryImage(
            img.encodeJpg(image),
          );

          pdf.addPage(
            pw.Page(
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Image(pdfImage),
                );
              },
            ),
          );
        }
      } else if (extension == 'pdf') {
        // If it's already a PDF, return the original file
        return file;
      } else {
        // For other file types, create a PDF with a message
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Text(
                  'Original file: ${file.path.split('/').last}\n'
                  'File type: $extension\n'
                  'Original file is preserved as-is',
                ),
              );
            },
          ),
        );
        // Return original file for non-convertible types
        return file;
      }

      // Save the PDF
      final output = await getTemporaryDirectory();
      final pdfFile = File(
          '${output.path}/converted_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await pdfFile.writeAsBytes(await pdf.save());
      return pdfFile;
    } catch (e) {
      print('Error converting to PDF: $e');
      // Return original file if conversion fails
      return file;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final userProvider = Provider.of<UserProvider>(context);
    final String userRole = userProvider.getUserRole;
    final bool isAdmin = userRole == 'admin';
    final bool isDealer = userRole == 'dealer';
    final bool isTransporter = userRole == 'transporter';
    // NEW: handle "sales"
    final bool isSales = userRole == 'sales';

    // Determine if the user can edit (admin, sales, transporter) or view only (dealer)
    final bool canEdit = isAdmin || isSales || isTransporter;
    final bool canView = isDealer || canEdit;

    return GradientBackground(
      child: Scaffold(
        // Add Scaffold here
        backgroundColor:
            Colors.transparent, // Make scaffold background transparent
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0), // Reduced left padding
            child: Transform.scale(
              scale: 0.4, // Scales down the button to 40% of original size
              child: CustomBackButton(),
            ),
          ),
        ),
        body: Material(
          // Move existing Material widget here
          type: MaterialType.transparency,
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    if (widget.maintenanceSelection == 'yes' || canView) ...[
                      // Always show the maintenance section for dealers and other roles
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
                        onTap: canEdit
                            ? _pickMaintenanceDocument
                            : widget.maintenanceDocUrl != null
                                ? () => _viewPdf(widget.maintenanceDocUrl!,
                                    'Maintenance Document')
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
                                            _maintenanceDocFile!.path))
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: Image.file(
                                              _maintenanceDocFile!,
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
                                                    _maintenanceDocFile!.path
                                                        .split('.')
                                                        .last),
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
                                                  _maintenanceDocFile!.path
                                                      .split('/')
                                                      .last,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          )
                                      else if (widget.maintenanceDocUrl != null)
                                        if (_isImageFile(
                                            widget.maintenanceDocUrl!))
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: Image.network(
                                              widget.maintenanceDocUrl!,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        else
                                          Column(
                                            children: [
                                              Icon(
                                                _getFileIcon(widget
                                                    .maintenanceDocUrl!
                                                    .split('.')
                                                    .last),
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
                                                  getFileNameFromUrl(widget
                                                      .maintenanceDocUrl!),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                              style: TextStyle(
                                                  color: Colors.white),
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
                          style: const TextStyle(
                              fontSize: 15, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 15),
                      Center(
                        child: Text(
                          'Please note that OEM will charge you for inspection'
                              .toUpperCase(),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white),
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
                            enabled: canEdit,
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
                            enabled: canEdit,
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
                            enabled: canEdit,
                          ),
                        ),
                      const SizedBox(height: 15),
                    ],
                    if (widget.warrantySelection == 'yes' || canView) ...[
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
                        onTap: canEdit
                            ? _pickWarrantyDocument
                            : widget.warrantyDocUrl != null
                                ? () => _viewPdf(
                                    widget.warrantyDocUrl!, 'Warranty Document')
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
                                        if (_isImageFile(
                                            _warrantyDocFile!.path))
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: Image.file(
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
                                                _getFileIcon(_warrantyDocFile!
                                                    .path
                                                    .split('.')
                                                    .last),
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
                                                  _warrantyDocFile!.path
                                                      .split('/')
                                                      .last,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          )
                                      else if (widget.warrantyDocUrl != null)
                                        if (_isImageFile(
                                            widget.warrantyDocUrl!))
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
                                                _getFileIcon(widget
                                                    .warrantyDocUrl!
                                                    .split('.')
                                                    .last),
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
                                              style: TextStyle(
                                                  color: Colors.white),
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
                      if (canEdit)
                        CustomButton(
                          onPressed: () async {
                            // Show loading indicator
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                );
                              },
                            );

                            try {
                              String? maintenanceDocUrl =
                                  widget.maintenanceDocUrl;
                              String? warrantyDocUrl = widget.warrantyDocUrl;

                              // Upload maintenance file if new one is selected
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

                              // Upload warranty file if new one is selected
                              if (_warrantyDocFile != null) {
                                final storageRef = FirebaseStorage.instance
                                    .ref()
                                    .child(
                                        'vehicles/${widget.vehicleId}/maintenance')
                                    .child(
                                        'warranty_doc_${DateTime.now().millisecondsSinceEpoch}');

                                await storageRef.putFile(_warrantyDocFile!);
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
                                'warrantySelection': widget.warrantySelection,
                                'lastUpdated': FieldValue.serverTimestamp(),
                              };

                              // Update the vehicle document in Firestore
                              await FirebaseFirestore.instance
                                  .collection('vehicles')
                                  .doc(widget.vehicleId)
                                  .set({
                                'maintenanceData': maintenanceData,
                              }, SetOptions(merge: true));

                              // Dismiss loading indicator and pop back
                              Navigator.pop(
                                  context); // Dismiss loading indicator
                              Navigator.pop(
                                  context); // Return to previous screen

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
      ),
    );
  }

  @override
  bool get wantKeepAlive => true; // Ensure the state is kept alive
}
