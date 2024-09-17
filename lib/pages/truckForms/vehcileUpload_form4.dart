import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart'; // Import for Provider
import 'package:ctp/providers/form_data_provider.dart'; // Import FormDataProvider
import 'package:ctp/providers/vehicles_provider.dart'; // Import VehicleProvider
import 'package:path/path.dart' as path; // Import path package

class FourthFormPage extends StatefulWidget {
  const FourthFormPage({super.key});

  @override
  _FourthFormPageState createState() => _FourthFormPageState();
}

class _FourthFormPageState extends State<FourthFormPage> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  // Add FormDataProvider instance
  late FormDataProvider formDataProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    formDataProvider = Provider.of<FormDataProvider>(context);
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        setState(() {
          // Update provider
          formDataProvider.setRc1NatisFile(File(result.files.single.path!));
        });
      }
    } catch (e) {
      print("Error picking file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final FirebaseStorage storage = FirebaseStorage.instance;
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      String? vehicleId = vehicleProvider.vehicleId;

      if (vehicleId != null) {
        String? rc1NatisFileUrl;
        if (formDataProvider.rc1NatisFile != null) {
          // Upload the RC1/NATIS file to Firebase Storage
          String fileName = path.basename(formDataProvider.rc1NatisFile!.path);
          String fileExtension = fileName.split('.').last; // Get file extension

          final ref = storage
              .ref()
              .child('vehicles/$vehicleId/rc1NatisFile.$fileExtension');
          final uploadTask = ref.putFile(formDataProvider.rc1NatisFile!);
          final snapshot = await uploadTask;
          rc1NatisFileUrl = await snapshot.ref.getDownloadURL();
        }

        // Save the file URL to Firestore
        await firestore.collection('vehicles').doc(vehicleId).update({
          'rc1NatisFile': rc1NatisFileUrl,
        });

        print("Form submitted successfully!");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Form submitted successfully!')),
        );

        // Navigate to the next form
        formDataProvider.incrementFormIndex();
      } else {
        print('Error: vehicleId is null');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Vehicle ID is null.')),
        );
      }
    } catch (e) {
      print("Error submitting form: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting form: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final File? imageFile = formDataProvider.selectedMainImage;
    final File? rc1NatisFile = formDataProvider.rc1NatisFile;

    if (imageFile == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'No image selected. Please go back and select an image.',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          GradientBackground(
            child: Column(
              children: [
                const BlurryAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    height: 300,
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10.0),
                                      child: Image.file(
                                        imageFile,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Center(
                              child: Text(
                                'TRUCK/TRAILER FORM',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Center(
                              child: Text(
                                'Upload your RC1/NATIS documentation',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: GestureDetector(
                                onTap: _pickFile,
                                child: Container(
                                  height: 100,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(
                                        color: Colors.white70, width: 1),
                                  ),
                                  child: Center(
                                    child: rc1NatisFile == null
                                        ? const Icon(Icons.folder_open,
                                            color: Colors.blue, size: 40)
                                        : Text(
                                            path.basename(rc1NatisFile.path),
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Center(
                              child: Text(
                                'RC1/NATIS Documents',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: CustomButton(
                                text: _isLoading ? 'Submitting...' : 'CONTINUE',
                                borderColor: const Color(0xFFFF4E00),
                                onPressed: _isLoading ? () {} : _submitForm,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'CANCEL',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          const Positioned(
            top: 40,
            left: 16,
            child: CustomBackButton(),
          ),
        ],
      ),
    );
  }
}
