// File: upload_proof_of_payment_page.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/pages/payment_pending_page.dart';

class UploadProofOfPaymentPage extends StatefulWidget {
  final String offerId;

  const UploadProofOfPaymentPage({super.key, required this.offerId});

  @override
  _UploadProofOfPaymentPageState createState() =>
      _UploadProofOfPaymentPageState();
}

class _UploadProofOfPaymentPageState extends State<UploadProofOfPaymentPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isUploaded = false;
  Uint8List? _selectedFile;
  String? _selectedFileName;
  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedFile = bytes;
          _selectedFileName = pickedFile.name;
        });
        await _uploadFile();
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null) {
        final bytes = result.files.single.bytes;
        if (bytes != null) {
          setState(() {
            _selectedFile = bytes;
            _selectedFileName = result.files.single.name;
          });
          await _uploadFile();
        }
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null || _selectedFileName == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String fileName =
          'proof_of_payment/${widget.offerId}/${DateTime.now().millisecondsSinceEpoch}_$_selectedFileName';
      Reference storageReference =
          FirebaseStorage.instance.ref().child(fileName);

      // Upload the file bytes
      UploadTask uploadTask = storageReference.putData(_selectedFile!);
      await uploadTask.whenComplete(() => null);

      String fileURL = await storageReference.getDownloadURL();

      // Save the file URL to Firestore
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({
        'proofOfPaymentUrl': fileURL,
        'proofOfPaymentFileName': _selectedFileName,
        'uploadTimestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isLoading = false;
        _isUploaded = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proof of payment uploaded successfully')),
      );

      // Navigate back to the PaymentPendingPage after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentPendingPage(offerId: widget.offerId),
          ),
        );
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error uploading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: $e')),
      );
    }
  }

  void _showPickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('Files'),
                onTap: () {
                  _pickFile();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Content
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Image.asset('lib/assets/CTPLogo.png'),
                  const SizedBox(height: 32),
                  if (_isUploaded)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.green.withOpacity(0.1),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 60),
                          SizedBox(height: 10),
                          Text(
                            'Proof of payment uploaded!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _showPickerDialog,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.blue.withOpacity(0.1),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open,
                                color: Colors.blue, size: 60),
                            SizedBox(height: 10),
                            Text(
                              'Upload Proof of Payment',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
              // Bottom Buttons
              Column(
                children: [
                  CustomButton(
                    text: 'Cancel',
                    borderColor: const Color(0xFFFF4E00),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
