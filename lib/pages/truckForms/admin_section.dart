// admin_section.dart

import 'dart:io';
import 'package:ctp/pages/truckForms/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';


class AdminSection extends StatefulWidget {
  final String vehicleId; // Required vehicleId
  final bool isUploading;
  final bool isEditing;
  final Function(File?) onAdminDoc1Selected;
  final Function(File?) onAdminDoc2Selected;
  final Function(File?) onAdminDoc3Selected;

  // Parameter to accept the user's selection
  final String requireToSettleType;

  // Parameters to accept existing data
  final String? settlementAmount;
  final String? natisRc1Url;
  final String? licenseDiskUrl;
  final String? settlementLetterUrl;

  const AdminSection({
    super.key,
    required this.vehicleId,
    required this.isUploading,
    this.isEditing = false,
    required this.onAdminDoc1Selected,
    required this.onAdminDoc2Selected,
    required this.onAdminDoc3Selected,
    required this.requireToSettleType, // Added requireToSettleType
    this.settlementAmount,
    this.natisRc1Url,
    this.licenseDiskUrl,
    this.settlementLetterUrl,
  });

  @override
  AdminSectionState createState() => AdminSectionState();
}

class AdminSectionState extends State<AdminSection>
    with AutomaticKeepAliveClientMixin {
  // Controllers for input fields
  final TextEditingController _settlementAmountController =
      TextEditingController();

  // Variables to hold selected files
  File? _natisRc1File;
  File? _licenseDiskFile;
  File? _settlementLetterFile;

  // Variables to hold existing file URLs
  String? _natisRc1Url;
  String? _licenseDiskUrl;
  String? _settlementLetterUrl;

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _settlementAmountController.text = widget.settlementAmount ?? '';
    _natisRc1Url = widget.natisRc1Url;
    _licenseDiskUrl = widget.licenseDiskUrl;
    _settlementLetterUrl = widget.settlementLetterUrl;
  }

  @override
  void dispose() {
    _settlementAmountController.dispose();
    super.dispose();
  }

  // Helper function to pick files
  Future<void> _pickFile(int docNumber) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        File selectedFile = File(result.files.single.path!);
        setState(() {
          switch (docNumber) {
            case 1:
              _natisRc1File = selectedFile;
              _natisRc1Url = null; // Clear URL when a new file is selected
              widget.onAdminDoc1Selected(selectedFile);
              break;
            case 2:
              _licenseDiskFile = selectedFile;
              _licenseDiskUrl = null; // Clear URL when a new file is selected
              widget.onAdminDoc2Selected(selectedFile);
              break;
            case 3:
              _settlementLetterFile = selectedFile;
              _settlementLetterUrl =
                  null; // Clear URL when a new file is selected
              widget.onAdminDoc3Selected(selectedFile);
              break;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  // Helper function to get file icon based on extension
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

  // Helper function to check if file is an image
  bool _isImageFile(String path) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    String extension = path.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }

  bool _isImageUrl(String url) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    String extension = url.split('.').last.toLowerCase().split('?').first;
    return imageExtensions.contains(extension);
  }

  String getFileNameFromUrl(String url) {
    return url.split('/').last.split('?').first;
  }

  // Helper method to display uploaded files
  Widget _buildUploadedFile(File? file, String? fileUrl, bool isUploading) {
    if (file == null && fileUrl == null) {
      return const Text(
        'No file selected',
        style: TextStyle(color: Colors.white70),
      );
    } else {
      String fileName;
      String extension;
      if (file != null) {
        fileName = file.path.split('/').last;
        extension = fileName.split('.').last;
      } else if (fileUrl != null) {
        fileName = getFileNameFromUrl(fileUrl);
        extension = fileName.split('.').last;
      } else {
        fileName = 'Unknown';
        extension = '';
      }
      return Column(
        children: [
          if (file != null)
            if (_isImageFile(file.path))
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(
                  file,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              )
            else
              Column(
                children: [
                  Icon(
                    _getFileIcon(extension),
                    color: Colors.white,
                    size: 50.0,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      fileName,
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
          else if (fileUrl != null)
            if (_isImageUrl(fileUrl))
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  fileUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              )
            else
              Column(
                children: [
                  Icon(
                    _getFileIcon(extension),
                    color: Colors.white,
                    size: 50.0,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      fileName,
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
          if (isUploading)
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
      );
    }
  }

  void loadAdminData(Map<String, dynamic> adminData) {
    setState(() {
      _settlementAmountController.text = adminData['settlementAmount'] ?? '';
      _natisRc1Url = adminData['natisRc1Url'];
      _licenseDiskUrl = adminData['licenseDiskUrl'];
      _settlementLetterUrl = adminData['settlementLetterUrl'];
    });
  }

  void clearData() {
    setState(() {
      _settlementAmountController.clear();
      _natisRc1File = null;
      _licenseDiskFile = null;
      _settlementLetterFile = null;
      _natisRc1Url = null;
      _licenseDiskUrl = null;
      _settlementLetterUrl = null;
    });
  }

  Future<bool> saveAdminData({bool skipValidation = false}) async {
    String settlementAmount = _settlementAmountController.text.trim();

    // Validation checks
    if (!skipValidation &&
        widget.requireToSettleType == 'yes' &&
        settlementAmount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the settlement amount.')),
      );
      return false;
    }

    if (!skipValidation && _natisRc1File == null && _natisRc1Url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload the NATIS/RC1 document.')),
      );
      return false;
    }

    if (!skipValidation &&
        _licenseDiskFile == null &&
        _licenseDiskUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload the License Disk.')),
      );
      return false;
    }

    if (!skipValidation &&
        widget.requireToSettleType == 'yes' &&
        _settlementLetterFile == null &&
        _settlementLetterUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload the Settlement Letter.')),
      );
      return false;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload documents if new files are selected, otherwise use existing URLs
      String natisRc1Url;
      if (_natisRc1File != null) {
        natisRc1Url = await _uploadDocument(_natisRc1File!, 'NATIS_RC1');
      } else if (_natisRc1Url != null) {
        natisRc1Url = _natisRc1Url!;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please upload the NATIS/RC1 document.')),
        );
        return false;
      }

      String licenseDiskUrl;
      if (_licenseDiskFile != null) {
        licenseDiskUrl =
            await _uploadDocument(_licenseDiskFile!, 'LicenseDisk');
      } else if (_licenseDiskUrl != null) {
        licenseDiskUrl = _licenseDiskUrl!;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload the License Disk.')),
        );
        return false;
      }

      String? settlementLetterUrl;
      if (widget.requireToSettleType == 'yes') {
        if (_settlementLetterFile != null) {
          settlementLetterUrl =
              await _uploadDocument(_settlementLetterFile!, 'SettlementLetter');
        } else if (_settlementLetterUrl != null) {
          settlementLetterUrl = _settlementLetterUrl!;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please upload the Settlement Letter.')),
          );
          return false;
        }
      }

      // Prepare data to save
      Map<String, dynamic> adminData = {
        'natisRc1Url': natisRc1Url,
        'licenseDiskUrl': licenseDiskUrl,
      };

      if (widget.requireToSettleType == 'yes') {
        adminData['settlementAmount'] = settlementAmount;
        adminData['settlementLetterUrl'] = settlementLetterUrl;
      }

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .set({'adminData': adminData}, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin data saved successfully.')),
      );

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save admin data: $e')),
      );
      return false;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Helper method to upload a single document
  Future<String> _uploadDocument(File file, String docName) async {
    String extension = file.path.split('.').last;
    String fileName =
        'admin_docs/${widget.vehicleId}_$docName${DateTime.now().millisecondsSinceEpoch}.$extension';
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = storageRef.putFile(file);

    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  void updateAdminDoc1(File? file) {
    setState(() {
      _natisRc1File = file;
    });
  }

  void updateAdminDoc2(File? file) {
    setState(() {
      _licenseDiskFile = file;
    });
  }

  void updateAdminDoc3(File? file) {
    setState(() {
      _settlementLetterFile = file;
    });
  }

  double getCompletionPercentage() {
    int totalFields = 0;
    int filledFields = 0;

    // NATIS/RC1 Document
    totalFields++;
    if (_natisRc1File != null || _natisRc1Url != null) filledFields++;

    // License Disk
    totalFields++;
    if (_licenseDiskFile != null || _licenseDiskUrl != null) filledFields++;

    // Settlement fields if required
    if (widget.requireToSettleType == 'yes') {
      totalFields += 2;
      if (_settlementLetterFile != null || _settlementLetterUrl != null) {
        filledFields++;
      }
      if (_settlementAmountController.text.trim().isNotEmpty) filledFields++;
    }

    return totalFields == 0 ? 1.0 : filledFields / totalFields;
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
              'ADMINISTRATION'.toUpperCase(),
              style: const TextStyle(
                  fontSize: 25,
                  color: Colors.white,
                  fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          // Upload NATIS/RC1 Document
          Center(
            child: Text(
              'Please attach NATIS/RC1 Documentation'.toUpperCase(),
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 15),
          InkWell(
            onTap: () => _pickFile(1),
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
                  if (_natisRc1File == null && _natisRc1Url == null)
                    Icon(
                      Icons.drive_folder_upload_outlined,
                      color: Colors.white,
                      size: 50.0,
                      semanticLabel: 'NATIS/RC1 Upload',
                    ),
                  const SizedBox(height: 10),
                  if (_natisRc1File != null || _natisRc1Url != null)
                    _buildUploadedFile(
                        _natisRc1File, _natisRc1Url, _isUploading)
                  else
                    const Text(
                      'NATIS/RC1 Upload',
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
          // Upload License Disk
          Center(
            child: Text(
              'Please attach License Disk Photo'.toUpperCase(),
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 15),
          InkWell(
            onTap: () => _pickFile(2),
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
                  if (_licenseDiskFile == null && _licenseDiskUrl == null)
                    Icon(
                      Icons.drive_folder_upload_outlined,
                      color: Colors.white,
                      size: 50.0,
                      semanticLabel: 'License Disk Upload',
                    ),
                  const SizedBox(height: 10),
                  if (_licenseDiskFile != null || _licenseDiskUrl != null)
                    _buildUploadedFile(
                        _licenseDiskFile, _licenseDiskUrl, _isUploading)
                  else
                    const Text(
                      'License Disk Upload',
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
          // Conditionally display Settlement Letter upload and Settlement Amount field
          if (widget.requireToSettleType == 'yes') ...[
            // Upload Settlement Letter
            Center(
              child: Text(
                'Please attach Settlement Letter'.toUpperCase(),
                style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 15),
            InkWell(
              onTap: () => _pickFile(3),
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
                    if (_settlementLetterFile == null &&
                        _settlementLetterUrl == null)
                      Icon(
                        Icons.drive_folder_upload_outlined,
                        color: Colors.white,
                        size: 50.0,
                        semanticLabel: 'Settlement Letter Upload',
                      ),
                    const SizedBox(height: 10),
                    if (_settlementLetterFile != null ||
                        _settlementLetterUrl != null)
                      _buildUploadedFile(_settlementLetterFile,
                          _settlementLetterUrl, _isUploading)
                    else
                      const Text(
                        'Settlement Letter Upload',
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
            // Input Field for Settlement Amount
            Center(
              child: Text(
                'Please fill in your settlement amount'.toUpperCase(),
                style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w400),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 15),
            CustomTextField(
              controller: _settlementAmountController,
              hintText: 'Amount'.toUpperCase(),
              isCurrency: true,
              keyboardType: TextInputType.number,
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
