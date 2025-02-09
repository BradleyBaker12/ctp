import 'dart:typed_data';

import 'package:ctp/components/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:ctp/components/custom_radio_button.dart';
import 'package:ctp/pages/truckForms/custom_text_field.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceForm extends StatefulWidget {
  final Map<String, dynamic> formData;

  MaintenanceForm({
    super.key,
    required this.formData,
  }) : assert(formData['vehicleId'] != null, 'vehicleId is required');

  @override
  State<MaintenanceForm> createState() => _MaintenanceFormState();
}

class _MaintenanceFormState extends State<MaintenanceForm> {
  bool? canSendToOEM;
  final TextEditingController _reasonController = TextEditingController();
  String _oemInspectionType = '';
  Uint8List? maintenanceDocFile;
  Uint8List? warrantyDocFile;
  String? maintenanceDocUrl;
  String? warrantyDocUrl;
  bool isUploading = false;
  final TextEditingController _oemReasonController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  bool isSaving = false;

  bool _isImageFile(String path) {
    final ext = path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif'].contains(ext);
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _pickMaintenanceDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );

      if (result != null) {
        maintenanceDocFile =
            await File(result.files.single.path!).readAsBytes();
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _pickWarrantyDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
      );

      if (result != null) {
        warrantyDocFile = await File(result.files.single.path!).readAsBytes();
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  String getFileNameFromUrl(String url) {
    return url.split('/').last;
  }

  Widget _buildDocumentUploadContainer({
    required String title,
    required Uint8List? file,
    required String? url,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
            if (file == null && url == null) ...[
              const Icon(
                Icons.drive_folder_upload_outlined,
                color: Colors.white,
                size: 50.0,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              if (file != null) ...[
                Icon(
                  _getFileIcon(File.fromRawPath(file).path.split('.').last),
                  size: 50,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  File.fromRawPath(file).path.split('/').last,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else if (url != null) ...[
                Icon(
                  _getFileIcon(url.split('.').last),
                  size: 50,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  getFileNameFromUrl(url),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (isUploading)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadFile(Uint8List file, String folder) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${File.fromRawPath(file).path.split('/').last}';
      final ref = _storage
          .ref()
          .child('vehicles/${widget.formData['vehicleId']}/$folder/$fileName');

      final uploadTask = await ref.putData(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  Future<void> _saveMaintenanceData() async {
    try {
      setState(() => isSaving = true);

      // Upload maintenance document if exists
      String? maintenanceDocumentUrl;
      if (maintenanceDocFile != null) {
        maintenanceDocumentUrl =
            await _uploadFile(maintenanceDocFile!, 'maintenance_documents');
      }

      // Upload warranty document if exists
      String? warrantyDocumentUrl;
      if (warrantyDocFile != null) {
        warrantyDocumentUrl =
            await _uploadFile(warrantyDocFile!, 'warranty_documents');
      }

      // Prepare maintenance data
      final maintenanceData = {
        'maintenanceDocumentUrl': maintenanceDocumentUrl ?? maintenanceDocUrl,
        'warrantyDocumentUrl': warrantyDocumentUrl ?? warrantyDocUrl,
        'canSendToOEM': _oemInspectionType == 'yes',
        'oemReason':
            _oemInspectionType == 'no' ? _oemReasonController.text : null,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update the vehicle document with maintenance data
      await _firestore
          .collection('vehicles')
          .doc(widget.formData['vehicleId'])
          .update({
        'maintenance': maintenanceData,
      });

      if (!mounted) return;

      // Navigate to next page
      Navigator.pushNamed(
        context,
        '/admin',
        arguments: {
          'vehicleId': widget.formData['vehicleId'],
          'referenceNumber': widget.formData['referenceNumber'],
          'makeModel': widget.formData['makeModel'],
          'coverPhotoUrl': widget.formData['coverPhotoUrl'],
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving maintenance data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF2F7FFF),
              padding: const EdgeInsets.only(top: 50, bottom: 16),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        'BACK',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${widget.formData['referenceNumber'] ?? 'N/A'}',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${widget.formData['makeModel'] ?? 'N/A'}',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: widget.formData['coverPhotoUrl'] != null
                        ? CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(
                              widget.formData['coverPhotoUrl'],
                            ),
                          )
                        : const CircleAvatar(
                            radius: 20,
                            child: Text(
                              'NO',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Container(
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/maintenance',
                          arguments: {
                            'vehicleId': widget.formData['vehicleId'],
                            'referenceNumber':
                                widget.formData['referenceNumber'],
                            'makeModel': widget.formData['makeModel'],
                            'coverPhotoUrl': widget.formData['coverPhotoUrl'],
                          },
                        );
                      },
                      child: Container(
                        color: const Color(0xFF4CAF50),
                        alignment: Alignment.center,
                        child: Text(
                          'MAINTENANCE\nCOMPLETE',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/admin',
                          arguments: {
                            'vehicleId': widget.formData['vehicleId'],
                            'referenceNumber':
                                widget.formData['referenceNumber'],
                            'makeModel': widget.formData['makeModel'],
                            'coverPhotoUrl': widget.formData['coverPhotoUrl'],
                          },
                        );
                      },
                      child: Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: Text(
                          'ADMIN',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/truck-condition',
                          arguments: {
                            'vehicleId': widget.formData['vehicleId'],
                            'referenceNumber':
                                widget.formData['referenceNumber'],
                            'makeModel': widget.formData['makeModel'],
                            'coverPhotoUrl': widget.formData['coverPhotoUrl'],
                          },
                        );
                      },
                      child: Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: Text(
                          'TRUCK CONDITION',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      width: double.infinity,
                      color: Colors.transparent,
                      child: const Text(
                        'MAINTENANCE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 24),
                      child: Column(
                        children: [
                          const Text(
                            'PLEASE ATTACH MAINTENANCE DOCUMENTATION',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          _buildDocumentUploadContainer(
                            title: 'MAINTENANCE DOC UPLOAD',
                            file: maintenanceDocFile,
                            url: maintenanceDocUrl,
                            onTap: _pickMaintenanceDocument,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'CAN YOUR VEHICLE BE SENT TO OEM FOR A FULL\nINSPECTION UNDER R&M CONTRACT?',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const Text(
                            'Please note that OEM will charge you for inspection',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomRadioButton(
                                  label: 'YES',
                                  value: 'yes',
                                  groupValue: _oemInspectionType,
                                  onChanged: (value) => setState(() {
                                    _oemInspectionType = value!;
                                    if (_oemInspectionType == 'yes') {
                                      _oemReasonController.clear();
                                    }
                                  }),
                                ),
                                const SizedBox(
                                    width: 16), // Space between buttons
                                CustomRadioButton(
                                  label: 'NO',
                                  value: 'no',
                                  groupValue: _oemInspectionType,
                                  onChanged: (value) => setState(() {
                                    _oemInspectionType = value!;
                                    if (_oemInspectionType == 'no') {
                                      _oemReasonController.clear();
                                    }
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_oemInspectionType == 'no')
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            const Text(
                              'PLEASE EXPLAIN THE REASON WHY THE VEHICLE CAN\nNOT BE SENT THROUGH FOR OEM INSPECTION',
                              style: TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _oemReasonController,
                              hintText: 'Enter reason here...',
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ],
                        ),
                      ),
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      child: Text(
                        'PLEASE ATTACH WARRANTY DOCUMENTATION',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    _buildDocumentUploadContainer(
                      title: 'WARRANTY DOC UPLOAD',
                      file: warrantyDocFile,
                      url: warrantyDocUrl,
                      onTap: _pickWarrantyDocument,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : _saveMaintenanceData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFFF4E00).withOpacity(0.25),
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Color(0xFFFF4E00),
                              width: 2.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isSaving
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'CONTINUE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _oemReasonController.dispose();
    super.dispose();
  }
}
