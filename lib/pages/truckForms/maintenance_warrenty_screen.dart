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
  final String? natisRc1Url;
  final String maintenanceSelection;
  final String warrantySelection;
  final String requireToSettleType;

  const MaintenanceWarrantyScreen({
    Key? key,
    required this.vehicleId,
    this.natisRc1Url,
    required this.maintenanceSelection,
    required this.warrantySelection,
    required this.requireToSettleType,
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

  File? _adminDoc1File;
  File? _adminDoc2File;
  File? _adminDoc3File;

  bool isNewUpload = false;

  List<String> _tabTitles = [];
  List<Widget> _tabContents = [];

  @override
  void initState() {
    super.initState();

    // Determine if this is a new upload based on vehicleId
    isNewUpload = widget.vehicleId.isEmpty;

    // Build tabs dynamically based on user selections
    _buildTabs();

    // Only fetch data if we have a vehicleId and it's not a new vehicle
    if (!isNewUpload) {
      _fetchVehicleData();
    } else {
      // Clear all data for new vehicles
      _clearAllData();

      // Also clear data in child sections
      if (_maintenanceSectionKey.currentState != null) {
        _maintenanceSectionKey.currentState!.clearData();
      }
      if (_adminSectionKey.currentState != null) {
        _adminSectionKey.currentState!.clearData();
      }
    }
  }

  void _buildTabs() {
    _tabTitles = [];
    _tabContents = [];
    _selectedTabIndex = 0;

    if (widget.maintenanceSelection == 'yes' ||
        widget.warrantySelection == 'yes') {
      // Add Maintenance tab
      _tabTitles.add('MAINTENANCE');
      _tabContents.add(
        MaintenanceSection(
          key: _maintenanceSectionKey,
          vehicleId: widget.vehicleId,
          isUploading: _isUploading,
          maintenanceSelection: widget.maintenanceSelection,
          warrantySelection: widget.warrantySelection,
          onMaintenanceFileSelected: (file) {
            setState(() {
              _maintenanceDocFile = file;
            });
          },
          onWarrantyFileSelected: (file) {
            setState(() {
              _warrantyDocFile = file;
            });
          },
          oemInspectionType: _oemInspectionType,
          oemInspectionExplanation: _oemInspectionExplanationController.text,
          maintenanceDocFile: _maintenanceDocFile,
          warrantyDocFile: _warrantyDocFile,
          maintenanceDocUrl: _maintenanceDocUrl,
          warrantyDocUrl: _warrantyDocUrl,
        ),
      );
    }

    // Add Admin tab
    _tabTitles.add('ADMIN');
    _tabContents.add(
      AdminSection(
        key: _adminSectionKey,
        vehicleId: widget.vehicleId,
        natisRc1Url: widget.natisRc1Url,
        isUploading: _isUploading,
        requireToSettleType: widget.requireToSettleType,
        onAdminDoc1Selected: (File? file) {
          setState(() {
            _adminDoc1File = file;
          });
        },
        onAdminDoc2Selected: (File? file) {
          setState(() {
            _adminDoc2File = file;
          });
        },
        onAdminDoc3Selected: (File? file) {
          setState(() {
            _adminDoc3File = file;
          });
        },
      ),
    );

    // Add Truck Condition tab
    _tabTitles.add('TRUCK CONDITION');
    _tabContents.add(
      TruckConditionSection(
        vehicleId: widget.vehicleId,
      ),
    );
  }

  void _clearAllData() {
    setState(() {
      _maintenanceDocFile = null;
      _maintenanceDocUrl = null;
      _warrantyDocFile = null;
      _warrantyDocUrl = null;
      _oemInspectionType = 'yes';
      _oemInspectionExplanationController.clear();

      // Clear admin section data
      _adminDoc1File = null;
      _adminDoc2File = null;
      _adminDoc3File = null;
    });
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
          Map<String, dynamic>? maintenanceData =
              data['maintenance'] as Map<String, dynamic>?;
          Map<String, dynamic>? adminData =
              data['adminData'] as Map<String, dynamic>?;

          // Only load data if it exists
          if (maintenanceData != null) {
            setState(() {
              _oemInspectionType =
                  maintenanceData['oemInspectionType'] ?? 'yes';
              if (_oemInspectionType == 'no') {
                _oemInspectionExplanationController.text =
                    maintenanceData['oemReason'] ?? '';
              }
              _maintenanceDocUrl = maintenanceData['maintenanceDocumentUrl'];
              _warrantyDocUrl = maintenanceData['warrantyDocumentUrl'];
            });
          }

          // Pass the admin data to AdminSection only if it exists
          if (_adminSectionKey.currentState != null && adminData != null) {
            _adminSectionKey.currentState!.loadAdminData(adminData);
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
          setState(() {
            _selectedTabIndex = index;
          });
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

  Widget _buildContent() {
    return IndexedStack(
      index: _selectedTabIndex,
      children: _tabContents,
    );
  }

  // Method to handle "Continue" button press
  Future<void> _onContinuePressed() async {
    if (_selectedTabIndex < _tabContents.length - 1) {
      String currentTab = _tabTitles[_selectedTabIndex];
      bool dataSaved = false;

      if (currentTab == 'MAINTENANCE') {
        bool maintenanceSaved =
            await _maintenanceSectionKey.currentState?.saveMaintenanceData() ??
                false;
        if (maintenanceSaved) {
          dataSaved = await _saveMaintenanceWarrantyData();
        }
      } else if (currentTab == 'ADMIN') {
        dataSaved =
            await _adminSectionKey.currentState?.saveAdminData() ?? false;
      }

      if (dataSaved) {
        setState(() {
          _selectedTabIndex += 1;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are on the last tab.')),
      );
    }
  }

  // Method to handle "Done" button press
  Future<void> _onDonePressed() async {
    bool allSaved = true;

    // Save Maintenance Data if the tab exists
    if (_maintenanceSectionKey.currentState != null) {
      bool maintenanceSaved =
          await _maintenanceSectionKey.currentState?.saveMaintenanceData() ??
              false;
      if (!maintenanceSaved) {
        allSaved = false;
      }
    }

    // Save Admin Data without validation
    bool adminSaved =
        await _adminSectionKey.currentState?.saveAdminData() ?? false;

    if (allSaved) {
      bool parentSaved = await _saveMaintenanceWarrantyData();
      if (parentSaved) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving data. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            // Replace image stack with just the tab buttons
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10.0,
                left: 16.0,
                right: 16.0,
              ),
              child: Row(
                children: List.generate(_tabTitles.length, (index) {
                  return _buildCustomTabButton(_tabTitles[index], index);
                }),
              ),
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
                      onPressed: _selectedTabIndex < _tabContents.length - 1
                          ? _onContinuePressed
                          : null,
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
