// maintenance_section.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/pages/truckForms/custom_radio_button.dart';
import 'package:ctp/pages/truckForms/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class MaintenanceSection extends StatefulWidget {
  final String vehicleId;
  final bool isUploading;
  final File? maintenanceDocFile;
  final File? warrantyDocFile;
  final Function(File?) onMaintenanceFileSelected;
  final Function(File?) onWarrantyFileSelected;
  final String oemInspectionType;
  final String oemInspectionExplanation;
  final String? maintenanceDocUrl;
  final String? warrantyDocUrl;

  const MaintenanceSection({
    Key? key,
    required this.vehicleId,
    required this.isUploading,
    this.maintenanceDocFile,
    this.warrantyDocFile,
    required this.onMaintenanceFileSelected,
    required this.onWarrantyFileSelected,
    required this.oemInspectionType,
    required this.oemInspectionExplanation,
    this.maintenanceDocUrl,
    this.warrantyDocUrl,
  }) : super(key: key);

  @override
  MaintenanceSectionState createState() => MaintenanceSectionState();
}

class MaintenanceSectionState extends State<MaintenanceSection>
    with AutomaticKeepAliveClientMixin {
  late TextEditingController _oemReasonController;
  late String _oemInspectionType;

  @override
  void initState() {
    super.initState();
    _oemInspectionType = widget.oemInspectionType;
    _oemReasonController =
        TextEditingController(text: widget.oemInspectionExplanation);
  }

  @override
  void dispose() {
    _oemReasonController.dispose();
    super.dispose();
  }

  // Method to save maintenance data
  Future<bool> saveMaintenanceData() async {
    String? oemReason =
        _oemInspectionType == 'no' ? _oemReasonController.text.trim() : null;

    if (_oemInspectionType == 'no' &&
        (oemReason == null || oemReason.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please explain why OEM inspection is not possible.')),
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
        widget.onMaintenanceFileSelected(selectedFile);
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
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        File selectedFile = File(result.files.single.path!);
        widget.onWarrantyFileSelected(selectedFile);
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return SingleChildScrollView(
      // Added to handle overflow
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          InkWell(
            onTap: _pickMaintenanceDocument,
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
                  if (widget.maintenanceDocFile == null &&
                      widget.maintenanceDocUrl == null)
                    Icon(
                      Icons.drive_folder_upload_outlined,
                      color: Colors.white,
                      size: 50.0,
                      semanticLabel: 'Upload Maintenance Document',
                    ),
                  const SizedBox(height: 10),
                  if (widget.maintenanceDocFile != null ||
                      widget.maintenanceDocUrl != null)
                    Column(
                      children: [
                        if (widget.maintenanceDocFile != null)
                          if (_isImageFile(widget.maintenanceDocFile!.path))
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.file(
                                widget.maintenanceDocFile!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Column(
                              children: [
                                Icon(
                                  _getFileIcon(widget.maintenanceDocFile!.path
                                      .split('.')
                                      .last),
                                  color: Colors.white,
                                  size: 50.0,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.maintenanceDocFile!.path
                                      .split('/')
                                      .last,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
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
                                Text(
                                  getFileNameFromUrl(widget.maintenanceDocUrl!),
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
                  setState(() {
                    _oemInspectionType = value!;
                    if (_oemInspectionType == 'yes') {
                      _oemReasonController.clear(); // Clear the explanation
                    }
                  });
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
                },
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
              ),
            ),
          const SizedBox(height: 15),
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
                  if (widget.warrantyDocFile == null &&
                      widget.warrantyDocUrl == null)
                    Icon(
                      Icons.drive_folder_upload_outlined,
                      color: Colors.white,
                      size: 50.0,
                      semanticLabel: 'Upload Warranty Document',
                    ),
                  const SizedBox(height: 10),
                  if (widget.warrantyDocFile != null ||
                      widget.warrantyDocUrl != null)
                    Column(
                      children: [
                        if (widget.warrantyDocFile != null)
                          if (_isImageFile(widget.warrantyDocFile!.path))
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.file(
                                widget.warrantyDocFile!,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Column(
                              children: [
                                Icon(
                                  _getFileIcon(widget.warrantyDocFile!.path
                                      .split('.')
                                      .last),
                                  color: Colors.white,
                                  size: 50.0,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.warrantyDocFile!.path.split('/').last,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
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
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true; // Ensure the state is kept alive
}
