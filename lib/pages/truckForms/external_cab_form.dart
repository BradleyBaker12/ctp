import 'package:ctp/components/gradient_background.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../components/custom_radio_button.dart';
import '../../components/custom_text_field.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:io';

// import 'package:auto_route/auto_route.dart';
class ExternalCabForm extends StatefulWidget {
  final Map<String, dynamic> formData;
  const ExternalCabForm({super.key, required this.formData});

  @override
  State<ExternalCabForm> createState() => _ExternalCabFormState();
}

class _ExternalCabFormState extends State<ExternalCabForm> {
  String cabCondition = 'POOR';
  bool? hasDamages;
  bool? hasAdditionalFeatures;
  final TextEditingController _damageController = TextEditingController();
  final TextEditingController _featureController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  Map<String, File?> cabImages = {
    'FRONT VIEW': null,
    'RIGHT SIDE VIEW': null,
    'REAR VIEW': null,
    'LEFT SIDE VIEW': null,
  };

  Map<String, File?> damageImages = {};
  Map<String, File?> featureImages = {};
  int damageCounter = 0;
  int featureCounter = 0;

  List<DamageEntry> damageEntries = [];
  List<FeatureEntry> featureEntries = [];

  @override
  void initState() {
    super.initState();
    if (hasDamages == true) {
      _initializeDamageEntries();
    }
    if (hasAdditionalFeatures == true) {
      _initializeFeatureEntries();
    }
  }

  void _initializeDamageEntries() {
    if (damageEntries.isEmpty) {
      damageEntries.add(DamageEntry(controller: TextEditingController()));
    }
  }

  void _initializeFeatureEntries() {
    if (featureEntries.isEmpty) {
      featureEntries.add(FeatureEntry(controller: TextEditingController()));
    }
  }

  Future<void> _pickImage(String label) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Text(
            'Select Image Source',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: Text('Camera',
                    style: GoogleFonts.montserrat(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() {
                      cabImages[label] = File(image.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: Text('Gallery',
                    style: GoogleFonts.montserrat(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      cabImages[label] = File(image.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAdditionalImage(
      String type, int index, dynamic entry) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Text(
            'Select Image Source',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: Text('Camera',
                    style: GoogleFonts.montserrat(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() {
                      entry.image = File(image.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: Text('Gallery',
                    style: GoogleFonts.montserrat(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image =
                      await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      entry.image = File(image.path);
                    });
                  }
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top navigation buttons
            Container(
              color: const Color(0xFF2F7FFF),
              padding: const EdgeInsets.only(top: 50, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                mainAxisAlignment: MainAxisAlignment.center,
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
            Container(
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/external-cab');
                      },
                      child: Container(
                        color: const Color(0xFF4CAF50),
                        alignment: Alignment.center,
                        child: Text(
                          'External Cab',
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
                        Navigator.pushNamed(context, '/internal-cab');
                      },
                      child: Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: Text(
                          'Internal Cab',
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
                        Navigator.pushNamed(context, '/drive-train');
                      },
                      child: Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: Text(
                          'Drive Train',
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
                        Navigator.pushNamed(context, '/chassis');
                      },
                      child: Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: Text(
                          'Chassis',
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
                        Navigator.pushNamed(context, '/tyres');
                      },
                      child: Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: Text(
                          'Tyres',
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
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: Text(
                        'EXTERNAL CAB',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Cab Condition
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'CONDITION OF THE OUTSIDE CAB',
                            style: GoogleFonts.montserrat(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomRadioButton(
                                label: 'POOR',
                                value: 'POOR',
                                groupValue: cabCondition,
                                onChanged: (value) => setState(
                                    () => cabCondition = value ?? 'POOR'),
                              ),
                              const SizedBox(width: 32),
                              CustomRadioButton(
                                label: 'GOOD',
                                value: 'GOOD',
                                groupValue: cabCondition,
                                onChanged: (value) => setState(
                                    () => cabCondition = value ?? 'POOR'),
                              ),
                              const SizedBox(width: 32),
                              CustomRadioButton(
                                label: 'EXCELLENT',
                                value: 'EXCELLENT',
                                groupValue: cabCondition,
                                onChanged: (value) => setState(
                                    () => cabCondition = value ?? 'POOR'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Pictures of Cab
                    Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'PICTURES OF CAB',
                        style: GoogleFonts.montserrat(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Image upload grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          _buildImageUploadBox('FRONT VIEW'),
                          _buildImageUploadBox('RIGHT SIDE VIEW'),
                          _buildImageUploadBox('REAR VIEW'),
                          _buildImageUploadBox('LEFT SIDE VIEW'),
                        ],
                      ),
                    ),

                    // Additional Info
                    Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'ADDITIONAL INFO',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Damages section
                    _buildYesNoSection(
                      'ARE THERE ANY DAMAGES ON THE CAB',
                      hasDamages,
                      (value) => setState(() => hasDamages = value),
                      'DESCRIBE DAMAGE',
                      'CLEAR PICTURE OF DAMAGE',
                      'ADD ADDITIONAL\nDAMAGE',
                      'damage',
                    ),

                    // Features section
                    _buildYesNoSection(
                      'ARE THERE ANY ADDITIONAL FEATURES ON THE CAB',
                      hasAdditionalFeatures,
                      (value) => setState(() => hasAdditionalFeatures = value),
                      'DESCRIBE FEATURE',
                      'CLEAR PICTURE OF FEATURE',
                      'ADD ADDITIONAL\nFEATURE',
                      'feature',
                    ),

                    // Buttons
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                // Handle continue
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
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'CANCEL',
                              style:
                                  GoogleFonts.montserrat(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
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

  Widget _buildImageUploadBox(String label) {
    return InkWell(
      onTap: () => _pickImage(label),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: cabImages[label] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      cabImages[label]!,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          label,
                          style: GoogleFonts.montserrat(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: GoogleFonts.montserrat(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildYesNoSection(
    String title,
    bool? value,
    Function(bool?) onChanged,
    String textFieldLabel,
    String uploadLabel,
    String addButtonLabel,
    String type,
  ) {
    List<dynamic> entries = type == 'damage' ? damageEntries : featureEntries;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomRadioButton(
                label: 'YES',
                value: true.toString(),
                groupValue: value?.toString() ?? '',
                onChanged: (val) {
                  onChanged(val == 'true');
                  if (val == 'true') {
                    setState(() {
                      if (type == 'damage') {
                        _initializeDamageEntries();
                      } else {
                        _initializeFeatureEntries();
                      }
                    });
                  }
                },
              ),
              const SizedBox(width: 32),
              CustomRadioButton(
                label: 'NO',
                value: false.toString(),
                groupValue: value?.toString() ?? '',
                onChanged: (val) {
                  onChanged(val == 'true');
                  if (val == 'false') {
                    setState(() {
                      if (type == 'damage') {
                        damageEntries.clear();
                      } else {
                        featureEntries.clear();
                      }
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (value == true)
            Column(
              children: [
                // if (entries.isEmpty) {
                //   setState(() {
                //     if (type == 'damage') {
                //       _initializeDamageEntries();
                //     } else {
                //       _initializeFeatureEntries();
                //     }
                //   });
                // },
                ...entries.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final item = entry.value;
                  return Column(
                    children: [
                      if (index > 0)
                        const Divider(color: Colors.white54, height: 32),
                      CustomTextField(
                        controller: item.controller,
                        hintText: textFieldLabel,
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => _pickAdditionalImage(type, index, item),
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
                          child: item.image != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    item.image!,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  children: [
                                    const Icon(
                                      Icons.drive_folder_upload_outlined,
                                      color: Colors.white,
                                      size: 50.0,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      uploadLabel,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      if (index > 0)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              if (type == 'damage') {
                                damageEntries.removeAt(index);
                              } else {
                                featureEntries.removeAt(index);
                              }
                            });
                          },
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                          label: Text(
                            'Remove',
                            style: GoogleFonts.montserrat(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  );
                }),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (type == 'damage') {
                        damageEntries.add(
                            DamageEntry(controller: TextEditingController()));
                      } else {
                        featureEntries.add(
                            FeatureEntry(controller: TextEditingController()));
                      }
                    });
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    addButtonLabel,
                    style: GoogleFonts.montserrat(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _damageController.dispose();
    _featureController.dispose();
    for (var entry in damageEntries) {
      entry.controller.dispose();
    }
    for (var entry in featureEntries) {
      entry.controller.dispose();
    }
    super.dispose();
  }
}

class DamageEntry {
  final TextEditingController controller;
  File? image;

  DamageEntry({required this.controller, this.image});
}

class FeatureEntry {
  final TextEditingController controller;
  File? image;

  FeatureEntry({required this.controller, this.image});
}
