import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/pages/truckForms/custom_radio_button.dart';
import 'package:ctp/pages/truckForms/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class MaintenanceSection extends StatefulWidget {
  final String vehicleId;
  final bool isUploading;
  final bool isEditing;
  final String oemInspectionType;
  final String oemInspectionExplanation;
  final String? maintenanceDocUrl;
  final String? warrantyDocUrl;
  final Function(Uint8List?) onMaintenanceFileSelected;
  final Function(Uint8List?) onWarrantyFileSelected;
  final String maintenanceSelection;
  final String warrantySelection;
  final File? maintenanceDocFile;
  final File? warrantyDocFile;
  final VoidCallback onProgressUpdate;

  const MaintenanceSection({
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
  MaintenanceSectionState createState() => MaintenanceSectionState();
}

class MaintenanceSectionState extends State<MaintenanceSection>
    with AutomaticKeepAliveClientMixin {
  late TextEditingController _oemReasonController;
  late String _oemInspectionType;
  Uint8List? _maintenanceDocFile;
  String? _maintenanceDocFileName;
  Uint8List? _warrantyDocFile;
  String? _warrantyDocFileName;

  // New variables to store download URLs
  String? _maintenanceDocUrl;
  String? _warrantyDocUrl;

  @override
  void initState() {
    super.initState();
    _oemInspectionType = widget.oemInspectionType;
    _oemReasonController =
        TextEditingController(text: widget.oemInspectionExplanation);

    // Initialize files to null or with existing data if needed
    _maintenanceDocFile = null;
    _warrantyDocFile = null;
    _maintenanceDocFileName = null;
    _warrantyDocFileName = null;

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
      _maintenanceDocFileName = null;
      _warrantyDocFileName = null;
    });
  }

  void loadMaintenanceData(Map<String, dynamic>? maintenanceData) {
    if (maintenanceData != null) {
      setState(() {
        _oemInspectionType = maintenanceData['oemInspectionType'] ?? 'yes';
        _oemReasonController.text = maintenanceData['oemReason'] ?? '';
      });
    } else {
      clearData();
    }
  }

  Future<String?> _uploadFile(Uint8List file, String storagePath) async {
    try {
      UploadTask uploadTask =
          FirebaseStorage.instance.ref(storagePath).putData(file);

      TaskSnapshot taskSnapshot = await uploadTask;

      String downloadURL = await taskSnapshot.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('File upload error: $e');
      return null;
    }
  }

  Future<bool> saveMaintenanceData() async {
    String? oemReason =
        _oemInspectionType == 'no' ? _oemReasonController.text.trim() : null;

    if (_oemInspectionType == 'no' && (oemReason!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please explain why OEM inspection is not possible.'),
        ),
      );
      return false;
    }

    // Upload files if they exist
    if (_maintenanceDocFile != null) {
      String? downloadURL = await _uploadFile(
          _maintenanceDocFile!, 'maintenance_docs/${widget.vehicleId}');
      if (downloadURL != null) {
        _maintenanceDocUrl = downloadURL;
      }
    }

    if (_warrantyDocFile != null) {
      String? downloadURL = await _uploadFile(
          _warrantyDocFile!, 'warranty_docs/${widget.vehicleId}');
      if (downloadURL != null) {
        _warrantyDocUrl = downloadURL;
      }
    }

    // Prepare data to send
    Map<String, dynamic> maintenanceData = {
      'vehicleId': widget.vehicleId,
      'oemInspectionType': _oemInspectionType,
      'oemReason': oemReason,
      'maintenanceDocUrl': _maintenanceDocUrl ?? widget.maintenanceDocUrl,
      'warrantyDocUrl': _warrantyDocUrl ?? widget.warrantyDocUrl,
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
        final bytes = await result.xFiles.first.readAsBytes();
        final fileName = result.xFiles.first.name;
        setState(() {
          _maintenanceDocFile = bytes;
          _maintenanceDocFileName = fileName;
          widget.onMaintenanceFileSelected(_maintenanceDocFile);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking maintenance file: $e')),
      );
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
        final bytes = await result.xFiles.first.readAsBytes();
        final fileName = result.xFiles.first.name;
        setState(() {
          _warrantyDocFile = bytes;
          _warrantyDocFileName = fileName;
          widget.onWarrantyFileSelected(_warrantyDocFile);
        });
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    print('Building MaintenanceSection');
    //print('_maintenanceDocFile: ${_maintenanceDocFile?.path}');
    print('widget.maintenanceDocUrl: ${widget.maintenanceDocUrl}');
    //print('_warrantyDocFile: ${_warrantyDocFile?.path}');
    print('widget.warrantyDocUrl: ${widget.warrantyDocUrl}');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.maintenanceSelection == 'yes') ...[
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
                'PLEASE ATTACH MAINTENANCE DOCUMENTATION'.toUpperCase(),
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
              onTap: () {
                _pickMaintenanceDocument();
              },
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
                      const Icon(
                        Icons.drive_folder_upload_outlined,
                        color: Colors.white,
                        size: 50.0,
                        semanticLabel: 'Upload Maintenance Document',
                      ),
                    const SizedBox(height: 10),
                    if (_maintenanceDocFile != null ||
                        widget.maintenanceDocUrl != null)
                      // Use a Stack so we can place a delete button on top
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Display the image or icon
                          if (_maintenanceDocFile != null)
                            if (_isImageFile(_maintenanceDocFileName!))
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.memory(
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
                                    _getFileIcon(_maintenanceDocFileName!
                                        .split('.')
                                        .last),
                                    color: Colors.white,
                                    size: 50.0,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    child: Text(
                                       _maintenanceDocFileName!.split('/').last,
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
                              Column(
                                children: [
                                  Icon(
                                    _getFileIcon(widget.maintenanceDocUrl!
                                        .split('.')
                                        .last),
                                    color: Colors.white,
                                    size: 50.0,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
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

                          // ADDED DELETE BUTTON HERE
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  // Remove both the file and the URL
                                  _maintenanceDocFile = null;
                                  _maintenanceDocUrl = null;
                                  // Also notify the parent that file is removed
                                  widget.onMaintenanceFileSelected(null);
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4.0),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                ),
              ),
            ),
            const SizedBox(height: 15),
            Center(
              child: Text(
                'CAN YOUR VEHICLE BE SENT TO OEM FOR A FULL INSPECTION UNDER R&M CONTRACT?'
                    .toUpperCase(),
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 15),
            Center(
              child: Text(
                'Please note that OEM will charge you for inspection'
                    .toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
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
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 15),
            InkWell(
              onTap: _pickWarrantyDocument,
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
                      const Icon(
                        Icons.drive_folder_upload_outlined,
                        color: Colors.white,
                        size: 50.0,
                        semanticLabel: 'Upload Warranty Document',
                      ),
                    const SizedBox(height: 10),
                    if (_warrantyDocFile != null ||
                        widget.warrantyDocUrl != null)
                      // Use a Stack so we can place a delete button on top
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_warrantyDocFile != null)
                            if (_isImageFile(_warrantyDocFileName!))
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
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
                                        _warrantyDocFileName!.split('.').last),
                                    color: Colors.white,
                                    size: 50.0,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                    ),
                                    child: Text(
                                      _warrantyDocFileName!.split('/').last,
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
                                borderRadius: BorderRadius.circular(8.0),
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
                                        widget.warrantyDocUrl!.split('.').last),
                                    color: Colors.white,
                                    size: 50.0,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    getFileNameFromUrl(widget.warrantyDocUrl!),
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

                          // ADDED DELETE BUTTON HERE
                          Positioned(
                            top: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  // Remove both the file and the URL
                                  _warrantyDocFile = null;
                                  _warrantyDocUrl = null;
                                  // Also notify the parent that file is removed
                                  widget.onWarrantyFileSelected(null);
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4.0),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true; // Ensure the state is kept alive
}
