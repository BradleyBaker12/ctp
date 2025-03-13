// File: upload_proof_of_payment_page.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/pages/payment_pending_page.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/utils/navigation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; // Updated import

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
  final FirebaseStorage storage = FirebaseStorage.instance;

  Future<String> uploadByte(Uint8List fileByte, String fileName) async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId!;
    final ref = storage.ref().child('documents/$userId/$fileName');
    final task = ref.putData(fileByte);
    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          await uploadByte(bytes, pickedFile.name);
        } else {
          await _uploadFile(File(pickedFile.path));
        }
      } else {
        print('No image selected.');
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
      final result = await FilePicker.platform.pickFiles();
      if (result != null) {
        if (kIsWeb) {
          await uploadByte(
              result.files.single.bytes!, result.files.single.xFile.name);
        } else {
          await _uploadFile(File(result.files.single.path!));
        }
      } else {
        print('No file selected.');
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _uploadFile(File file) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String fileExtension = file.path.split('.').last;
      String fileName =
          'proof_of_payment/${widget.offerId}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      Reference storageReference =
          FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageReference.putFile(file);

      await uploadTask.whenComplete(() => null);
      String fileURL = await storageReference.getDownloadURL();

      // Save the file URL to Firestore under the offer document
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({'proofOfPaymentUrl': fileURL});

      setState(() {
        _isLoading = false;
        _isUploaded = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Proof of payment uploaded successfully')));

      // Navigate back to the PaymentPendingPage after 2 seconds
      Future.delayed(const Duration(seconds: 2), () async {
        await MyNavigator.pushReplacement(
          context,
          PaymentPendingPage(offerId: widget.offerId),
        );
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error uploading file: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error uploading file')));
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
