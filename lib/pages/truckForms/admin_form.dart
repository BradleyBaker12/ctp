import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/pages/truckForms/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class AdminForm extends StatefulWidget {
  final Map<String, dynamic> formData;

  const AdminForm({super.key, required this.formData});

  @override
  State<AdminForm> createState() => _AdminFormState();
}

class _AdminFormState extends State<AdminForm> {
  final TextEditingController _amountController = TextEditingController();

  bool isUploading = false;
  File? natisFile;
  File? licenseDiskFile;
  File? settlementLetterFile;
  String? natisUrl;
  String? licenseDiskUrl;
  String? settlementLetterUrl;

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

  String getFileNameFromUrl(String url) {
    return url.split('/').last;
  }

  @override
  void initState() {
    super.initState();
    print('Form Data: ${widget.formData}'); // Debug print
    print('Reference Number: ${widget.formData['referenceNumber']}');
    print('Make Model: ${widget.formData['makeModel']}');
    print('Cover Photo URL: ${widget.formData['coverPhotoUrl']}');
  }

  Future<void> _pickFile(String type) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          switch (type) {
            case 'natis':
              natisFile = File(result.files.single.path!);
              natisUrl = null; // Clear the URL when new file is picked
              break;
            case 'licenseDisk':
              licenseDiskFile = File(result.files.single.path!);
              licenseDiskUrl = null;
              break;
            case 'settlementLetter':
              settlementLetterFile = File(result.files.single.path!);
              settlementLetterUrl = null;
              break;
          }
        });
      }
    } catch (e) {
      // Handle any errors that occur during file picking
      print('Error picking file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            // Header
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
                      widget.formData['referenceNumber']?.toString() ?? 'N/A',
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
                      widget.formData['makeModel']?.toString() ?? 'N/A',
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
                    child: widget.formData['coverPhotoUrl']?.isNotEmpty == true
                        ? CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(
                              widget.formData['coverPhotoUrl']!,
                            ),
                            onBackgroundImageError: (_, __) {
                              // Handle error silently
                            },
                            child: widget.formData['coverPhotoUrl']!.isEmpty
                                ? const Text('N/A')
                                : null,
                          )
                        : const CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey,
                            child: Text(
                              'N/A',
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
                        // Navigate to maintenance tab
                        Navigator.pushNamed(
                            context, '/maintenance'); // Update with your route
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
                        // Navigate to admin tab
                        Navigator.pushNamed(
                            context, '/admin'); // Update with your route
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
                        // Navigate to truck condition tab
                        Navigator.pushNamed(context,
                            '/truck-condition'); // Update with your route
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
              child: Container(
                color: Colors.black,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        color: Colors.transparent,
                        child: const Row(
                          children: [
                            SizedBox(width: 16),
                            // Icon(Icons.arrow_back_ios, color: Colors.white),
                            Expanded(
                              child: Text(
                                'ADMINISTRATION',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(width: 32),
                          ],
                        ),
                      ),

                      // NATIS/RC1 Documentation
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'PLEASE ATTACH NATIS/RC1 DOCUMENTATION',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),

                      // Replace old NATIS/RC1 upload container
                      _buildUploadContainer(
                        title: 'NATIS/RC1 UPLOAD',
                        file: natisFile,
                        url: natisUrl,
                        onTap: () => _pickFile('natis'),
                      ),

                      // License Disk Photo
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'PLEASE ATTACH LICENSE DISK PHOTO',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),

                      // Replace old License disk upload container
                      _buildUploadContainer(
                        title: 'LICENSE DISK UPLOAD',
                        file: licenseDiskFile,
                        url: licenseDiskUrl,
                        onTap: () => _pickFile('licenseDisk'),
                      ),

                      // Settlement Letter
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'PLEASE ATTACH SETTLEMENT LETTER',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),

                      // Replace old Settlement letter upload container
                      _buildUploadContainer(
                        title: 'SETTLEMENT LETTER UPLOAD',
                        file: settlementLetterFile,
                        url: settlementLetterUrl,
                        onTap: () => _pickFile('settlementLetter'),
                      ),

                      // Settlement Amount
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'PLEASE FILL IN OUR SETTLEMENT AMOUNT',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),

                      // Amount input field
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: CustomTextField(
                          controller: _amountController,
                          hintText: 'AMOUNT',
                          keyboardType: TextInputType.number,
                          isCurrency: true,
                          // prefixText: 'R    ',
                        ),
                      ),

                      // Continue button
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Handle form submission
                              Navigator.pushNamed(context, '/truck-condition');
                            },
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
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

                      // Cancel button
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadContainer({
    required String title,
    required File? file,
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
                  _getFileIcon(file.path.split('.').last),
                  size: 50,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  file.path.split('/').last,
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

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
