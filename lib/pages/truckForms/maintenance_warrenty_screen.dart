// maintenance_warrenty_screen.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/custom_text_field.dart';
import 'package:ctp/pages/truckForms/admin_section.dart';
import 'package:ctp/pages/truckForms/maintenance_section.dart';
import 'package:ctp/pages/truckForms/truck_condition_section.dart';
import 'package:ctp/pages/truckForms/truck_conditions_tabs_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class MaintenanceWarrantyScreen extends StatefulWidget {
  final String vehicleId;
  final File? mainImageFile;
  final String? mainImageUrl;

  const MaintenanceWarrantyScreen({
    Key? key,
    required this.vehicleId,
    this.mainImageFile,
    this.mainImageUrl,
  }) : super(key: key);

  @override
  _MaintenanceWarrantyScreenState createState() =>
      _MaintenanceWarrantyScreenState();
}

class _MaintenanceWarrantyScreenState extends State<MaintenanceWarrantyScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isUploading = false;

  File? _maintenanceDocFile;
  String? _maintenanceDocUrl;

  File? _warrantyDocFile;
  String? _warrantyDocUrl;

  String _oemInspectionType = 'yes';
  final TextEditingController _oemInspectionExplanationController =
      TextEditingController();

  int _selectedTabIndex = 0; // 0: Maintenance, 1: Admin, 2: Truck Condition

  // Define GlobalKeys for MaintenanceSection and AdminSection
  final GlobalKey<MaintenanceSectionState> _maintenanceSectionKey =
      GlobalKey<MaintenanceSectionState>();
  final GlobalKey<AdminSectionState> _adminSectionKey =
      GlobalKey<AdminSectionState>();

  @override
  void initState() {
    super.initState();
    _fetchVehicleData();
  }

  Future<void> _fetchVehicleData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .get();

      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          // Get maintenance data
          Map<String, dynamic>? maintenanceData =
              data['maintenance'] as Map<String, dynamic>?;

          if (maintenanceData != null) {
            setState(() {
              // Set the variables accordingly
              _oemInspectionType =
                  maintenanceData['oemInspectionType'] ?? 'yes';
              if (_oemInspectionType == 'no') {
                _oemInspectionExplanationController.text =
                    maintenanceData['oemReason'] ?? '';
              }
              // Set the URLs for the documents if they exist
              _maintenanceDocUrl = maintenanceData['maintenanceDocumentUrl'];
              _warrantyDocUrl = maintenanceData['warrantyDocumentUrl'];
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching vehicle data: $e');
    }
  }

  @override
  void dispose() {
    _oemInspectionExplanationController.dispose();
    super.dispose();
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

  // Method to save Maintenance & Warranty data
  Future<bool> _saveMaintenanceWarrantyData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Upload Maintenance Document if selected
      String? maintenanceDocUrl;
      if (_maintenanceDocFile != null) {
        maintenanceDocUrl = await _uploadMaintenanceDocument();
        if (maintenanceDocUrl == null) {
          throw Exception('Maintenance file upload failed');
        }
      } else if (_maintenanceDocUrl != null) {
        maintenanceDocUrl = _maintenanceDocUrl;
      }

      // Upload Warranty Document if selected
      String? warrantyDocUrl;
      if (_warrantyDocFile != null) {
        warrantyDocUrl = await _uploadWarrantyDocument();
        if (warrantyDocUrl == null) {
          throw Exception('Warranty file upload failed');
        }
      } else if (_warrantyDocUrl != null) {
        warrantyDocUrl = _warrantyDocUrl;
      }

      // **Prepare the Maintenance & Warranty Data**
      final maintenanceData = {
        'maintenanceDocumentUrl': maintenanceDocUrl,
        'warrantyDocumentUrl': warrantyDocUrl, // Add Warranty Document URL
        'oemInspectionType': _oemInspectionType,
        if (_oemInspectionType == 'no')
          'oemReason': _oemInspectionExplanationController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Update Firestore document
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .update({
        'maintenance': maintenanceData,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maintenance & Warranty data saved successfully'),
        ),
      );

      return true; // Indicate success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save data: $e')),
      );
      return false; // Indicate failure
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _uploadMaintenanceDocument() async {
    if (_maintenanceDocFile == null) return null;

    try {
      setState(() {
        _isUploading = true;
      });

      String extension = _maintenanceDocFile!.path.split('.').last;
      String fileName =
          'maintenance_docs/${widget.vehicleId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(_maintenanceDocFile!);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _isUploading = false;
      });

      return downloadUrl;
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading maintenance file: $e')),
      );
      return null;
    }
  }

  Future<String?> _uploadWarrantyDocument() async {
    if (_warrantyDocFile == null) return null;

    try {
      setState(() {
        _isUploading = true;
      });

      String extension = _warrantyDocFile!.path.split('.').last;
      String fileName =
          'warranty_docs/${widget.vehicleId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(_warrantyDocFile!);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _isUploading = false;
      });

      return downloadUrl;
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading warranty file: $e')),
      );
      return null;
    }
  }

  // Helper method to build custom tab buttons
  Widget _buildCustomTabButton(String title, int index) {
    bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 2) {
            _navigateToTruckConditionsTabsPage(index);
          } else {
            setState(() {
              _selectedTabIndex = index;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 0),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.blue,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: Colors.transparent,
              width: 0.0,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 350.0, // Increased height
      width: double.infinity,
      decoration: BoxDecoration(
        image: widget.mainImageFile != null
            ? DecorationImage(
                image: FileImage(widget.mainImageFile!),
                fit: BoxFit.cover,
              )
            : (widget.mainImageUrl != null && widget.mainImageUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(widget.mainImageUrl!),
                    fit: BoxFit.cover,
                  )
                : null),
        color: Colors.grey[300],
      ),
      child: widget.mainImageFile == null &&
              (widget.mainImageUrl == null || widget.mainImageUrl!.isEmpty)
          ? const Center(
              child: Text(
                'No Image Available',
                style: TextStyle(color: Colors.black54),
              ),
            )
          : null,
    );
  }

  Widget _buildContent() {
    return IndexedStack(
      index: _selectedTabIndex,
      children: [
        MaintenanceSection(
          key: _maintenanceSectionKey, // Assign the GlobalKey
          vehicleId: widget.vehicleId,
          isUploading: _isUploading,
          maintenanceDocFile: _maintenanceDocFile,
          warrantyDocFile: _warrantyDocFile,
          onMaintenanceFileSelected: (file) {
            setState(() {
              _maintenanceDocFile = file;
            });
          },
          onWarrantyFileSelected: (file) {
            setState(() {
              _warrantyDocFile = file; // Correctly setting the file
            });
          },
          oemInspectionType: _oemInspectionType,
          oemInspectionExplanation: _oemInspectionExplanationController.text,
          maintenanceDocUrl: _maintenanceDocUrl,
          warrantyDocUrl: _warrantyDocUrl,
        ),
        AdminSection(
          key: _adminSectionKey, // Assign the GlobalKey
          vehicleId: widget.vehicleId, // Pass vehicleId
          isUploading: _isUploading,
          onAdminDoc1Selected: (file) {
            setState(() {
              // Handle Admin Document 1 selection if needed
            });
          },
          onAdminDoc2Selected: (file) {
            setState(() {
              // Handle Admin Document 2 selection if needed
            });
          },
          onAdminDoc3Selected: (file) {
            setState(() {
              // Handle Admin Document 3 selection if needed
            });
          },
        ),
        TruckConditionSection(
          mainImageFile: widget.mainImageFile,
          mainImageUrl: widget.mainImageUrl,
          vehicleId: widget.vehicleId,
        ),
      ],
    );
  }

  Future<void> _navigateToTruckConditionsTabsPage(int index) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TruckConditionsTabsPage(
          initialIndex: index,
          mainImageFile: widget.mainImageFile,
          mainImageUrl: widget.mainImageUrl,
          vehicleId: widget.vehicleId,
        ),
      ),
    );
  }

  // Method to handle "Continue" button press
  Future<void> _onContinuePressed() async {
    if (_selectedTabIndex == 0) {
      // Maintenance Tab
      bool maintenanceSaved =
          await _maintenanceSectionKey.currentState?.saveMaintenanceData() ??
              false;
      if (maintenanceSaved) {
        bool parentSaved = await _saveMaintenanceWarrantyData();
        if (parentSaved) {
          setState(() {
            _selectedTabIndex = 1;
          });
        }
      }
    } else if (_selectedTabIndex == 1) {
      // Admin Tab
      bool adminSaved =
          await _adminSectionKey.currentState?.saveAdminData() ?? false;
      if (adminSaved) {
        setState(() {
          _selectedTabIndex = 2;
        });
      }
    } else if (_selectedTabIndex == 2) {
      // Truck Condition Tab
      // Typically, "Continue" is not needed on the last tab
      // You might disable the "Continue" button or hide it
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are on the last tab.')),
      );
    }
  }

  // Method to handle "Done" button press
  Future<void> _onDonePressed() async {
    bool allSaved = true;

    // Save Maintenance Data
    bool maintenanceSaved =
        await _maintenanceSectionKey.currentState?.saveMaintenanceData() ??
            false;
    if (!maintenanceSaved) {
      allSaved = false;
    }

    // Save Admin Data
    bool adminSaved =
        await _adminSectionKey.currentState?.saveAdminData() ?? false;
    if (!adminSaved) {
      allSaved = false;
    }

    // TODO: Save TruckConditionSection data if necessary

    if (allSaved) {
      bool parentSaved = await _saveMaintenanceWarrantyData();
      if (parentSaved) {
        // Navigate to Home Screen
        Navigator.of(context)
            .pushReplacementNamed('/home'); // Adjust route as needed
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix errors before proceeding.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            // Image Section with Overlayed Buttons
            Stack(
              children: [
                _buildImageSection(),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10.0,
                  left: 16.0,
                  right: 16.0,
                  child: Row(
                    children: [
                      _buildCustomTabButton('MAINTENANCE', 0),
                      _buildCustomTabButton('ADMIN', 1),
                      _buildCustomTabButton('TRUCK CONDITION', 2),
                    ],
                  ),
                ),
              ],
            ),
            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildContent(),
              ),
            ),
            // "Continue" and "Done" Buttons
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Continue',
                      onPressed:
                          _selectedTabIndex < 2 ? _onContinuePressed : null,
                      borderColor: AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: CustomButton(
                      text: 'Done',
                      onPressed: _onDonePressed,
                      borderColor: AppColors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
