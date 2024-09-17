import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:ctp/providers/form_data_provider.dart';

class FifthFormPage extends StatefulWidget {
  const FifthFormPage({super.key});

  @override
  _FifthFormPageState createState() => _FifthFormPageState();
}

class _FifthFormPageState extends State<FifthFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late FormDataProvider formDataProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    formDataProvider = Provider.of<FormDataProvider>(context);
  }

  Future<void> _pickImageDialog({required int index}) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera, index: index);
              },
              child: const Text('Camera'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery, index: index);
              },
              child: const Text('Gallery'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source, {required int index}) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          if (index == -1) {
            formDataProvider.setDashboardPhoto(File(pickedFile.path));
          } else if (index == -2) {
            formDataProvider.setFaultCodesPhoto(File(pickedFile.path));
          } else {
            formDataProvider.updateDamagePhoto(index, File(pickedFile.path));
          }
          formDataProvider.notifyListeners();
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _addDamageEntry() {
    setState(() {
      formDataProvider.damageEntries.add(DamageEntry());
      formDataProvider.notifyListeners();
    });
  }

  void _removeDamageEntry(int index) {
    setState(() {
      if (index < formDataProvider.damageEntries.length) {
        formDataProvider.damageEntries.removeAt(index);
        formDataProvider.notifyListeners();
      }
    });
  }

  Future<void> _submitForm() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final FirebaseStorage storage = FirebaseStorage.instance;

      // Submit damage entries (description + photos)
      List<Map<String, dynamic>> damageEntriesData = [];
      for (var entry in formDataProvider.damageEntries) {
        String? photoUrl;
        if (entry.damagePhoto != null) {
          final ref = storage.ref().child(
              'vehicles/damages/${DateTime.now().millisecondsSinceEpoch}.jpg');
          await ref.putFile(entry.damagePhoto!);
          photoUrl = await ref.getDownloadURL();
        }
        damageEntriesData.add({
          'damageDescription': entry.damageDescription,
          'damagePhoto': photoUrl,
        });
      }

      await firestore.collection('vehicles').doc('vehicleId').update({
        'damageEntries': damageEntriesData,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form submitted successfully!')),
      );
      formDataProvider.incrementFormIndex();
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
                            // Ensure the image is displayed at the top
                            if (imageFile != null)
                              Center(
                                child: Container(
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
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Center(
                              child: Text(
                                'Do you want to list damages and product faults?',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildRadioButton('Yes', 'yes',
                                    groupValue: formDataProvider.listDamages ??
                                        'yes', onChanged: (value) {
                                  setState(() {
                                    formDataProvider.setListDamages(value!);
                                  });
                                }),
                                const SizedBox(width: 20),
                                _buildRadioButton('No', 'no',
                                    groupValue: formDataProvider.listDamages ??
                                        'yes', onChanged: (value) {
                                  setState(() {
                                    formDataProvider.setListDamages(value!);
                                  });
                                }),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (formDataProvider.listDamages == 'yes') ...[
                              _buildImageUploadSection(),
                              const SizedBox(height: 20),
                              const Center(
                                child: Text(
                                  'Describe and attach images of damages',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Column(
                                children: List.generate(
                                    formDataProvider.damageEntries.length,
                                    (index) {
                                  return _buildDamageEntryField(index);
                                }),
                              ),
                              const SizedBox(height: 10),
                              Center(
                                child: TextButton.icon(
                                  onPressed: _addDamageEntry,
                                  icon:
                                      const Icon(Icons.add, color: Colors.blue),
                                  label: const Text(
                                    'ADD NEW DAMAGE',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            Center(
                              child: CustomButton(
                                text: _isLoading ? 'Submitting...' : 'CONTINUE',
                                borderColor: const Color(0xFFFF4E00),
                                onPressed: _isLoading ? null : _submitForm,
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

  Widget _buildImageUploadSection() {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: () => _pickImageDialog(index: -1),
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.white70, width: 1),
              ),
              child: Center(
                child: formDataProvider.dashboardPhoto == null
                    ? const Icon(Icons.add, color: Colors.blue, size: 40)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Image.file(
                          formDataProvider.dashboardPhoto!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Photo of Dashboard',
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
            onTap: () => _pickImageDialog(index: -2),
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.white70, width: 1),
              ),
              child: Center(
                child: formDataProvider.faultCodesPhoto == null
                    ? const Icon(Icons.add, color: Colors.blue, size: 40)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Image.file(
                          formDataProvider.faultCodesPhoto!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Clear Picture of Fault Codes',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildDamageEntryField(int index) {
    DamageEntry entry = formDataProvider.damageEntries[index];

    return Column(
      children: [
        const SizedBox(height: 10),
        _buildTextField(
          controller: TextEditingController(text: entry.damageDescription),
          hintText: 'Describe Damage',
          onChanged: (value) {
            formDataProvider.updateDamageDescription(index, value);
          },
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _pickImageDialog(index: index),
          child: Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Colors.white70, width: 1),
            ),
            child: Center(
              child: entry.damagePhoto == null
                  ? const Icon(Icons.add, color: Colors.blue, size: 40)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.file(
                        entry.damagePhoto!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => _removeDamageEntry(index),
            child: const Icon(
              Icons.remove_circle,
              color: Colors.red,
              size: 24,
            ),
          ),
        ),
        const Divider(color: Colors.white54),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
    );
  }

  Widget _buildRadioButton(String label, String value,
      {required String groupValue, required Function(String?) onChanged}) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor: const Color(0xFFFF4E00),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}
