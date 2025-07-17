import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/pages/editTruckForms/external_cab_edit_page.dart';
import 'package:ctp/pages/truckForms/admin_section.dart';
import 'package:ctp/pages/truckForms/maintenance_section.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:ctp/pages/home_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Add this import
import 'package:ctp/components/truck_info_web_nav.dart'; // Add this import

// Import the external camera helper for cross-platform photo capture

import 'package:auto_route/auto_route.dart';

@RoutePage()
class MaintenanceWarrantyScreen extends StatefulWidget {
  final String vehicleId;
  final String? natisRc1Url;
  final String maintenanceSelection;
  final String warrantySelection;
  final String requireToSettleType;
  final String vehicleRef;
  final String makeModel;
  final String mainImageUrl;

  const MaintenanceWarrantyScreen({
    super.key,
    required this.vehicleId,
    this.natisRc1Url,
    required this.maintenanceSelection,
    required this.warrantySelection,
    required this.requireToSettleType,
    required this.vehicleRef,
    required this.makeModel,
    required this.mainImageUrl,
  });

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

  // Make these late final to ensure they're only initialized once
  late final List<String> _tabTitles;
  late final List<Widget> _tabContents;

  // Store child widgets as state variables
  late MaintenanceSection _maintenanceSection;
  late AdminSection _adminSection;

  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Add this

  @override
  void initState() {
    super.initState();

    // Initialize lists
    _tabTitles = [];
    _tabContents = [];

    // Initialize sections first
    _initializeSections();

    // Build tabs once
    _buildTabs();

    // Determine if this is a new upload based on vehicleId
    isNewUpload = widget.vehicleId.isEmpty;

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

  void _initializeSections() {
    if (widget.maintenanceSelection == 'yes' ||
        widget.warrantySelection == 'yes') {
      _maintenanceSection = MaintenanceSection(
        key: _maintenanceSectionKey,
        vehicleId: widget.vehicleId,
        isUploading: _isUploading,
        maintenanceSelection: widget.maintenanceSelection,
        warrantySelection: widget.warrantySelection,
        onMaintenanceFileSelected: (file) {
          _maintenanceSectionKey.currentState?.updateMaintenanceFile(file);
        },
        onWarrantyFileSelected: (file) {
          _maintenanceSectionKey.currentState?.updateWarrantyFile(file);
        },
        onProgressUpdate: () {
          // Handle progress updates here if needed
        },
        oemInspectionType: _oemInspectionType,
        oemInspectionExplanation: _oemInspectionExplanationController.text,
        maintenanceDocFile: _maintenanceDocFile,
        warrantyDocFile: _warrantyDocFile,
        maintenanceDocUrl: _maintenanceDocUrl,
        warrantyDocUrl: _warrantyDocUrl,
      );
    }

    _adminSection = AdminSection(
      key: _adminSectionKey,
      vehicleId: widget.vehicleId,
      natisRc1Url: widget.natisRc1Url,
      isUploading: _isUploading,
      requireToSettleType: widget.requireToSettleType,
      onAdminDoc1Selected: (file) {
        _adminSectionKey.currentState?.updateAdminDoc1(file);
      },
      onAdminDoc2Selected: (file) {
        _adminSectionKey.currentState?.updateAdminDoc2(file);
      },
      onAdminDoc3Selected: (file) {
        _adminSectionKey.currentState?.updateAdminDoc3(file);
      },
    );
  }

  void _buildTabs() {
    if (_tabTitles.isNotEmpty) return; // Don't rebuild if already built

    if (widget.maintenanceSelection == 'yes' ||
        widget.warrantySelection == 'yes') {
      _tabTitles.add('MAINTENANCE');
      _tabContents.add(_maintenanceSection);
    }

    _tabTitles.add('ADMIN');
    _tabContents.add(_adminSection);
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
    double completionPercentage = 0.0;

    // Get completion percentage based on tab index
    if (index == 0 && _maintenanceSectionKey.currentState != null) {
      completionPercentage =
          _maintenanceSectionKey.currentState!.getCompletionPercentage();
    } else if (index == 1 && _adminSectionKey.currentState != null) {
      completionPercentage =
          _adminSectionKey.currentState!.getCompletionPercentage();
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          height: 45,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(
              color: Colors.blue,
              width: 1.0,
            ),
            borderRadius: BorderRadius.zero,
          ),
          child: Stack(
            children: [
              // Progress bar
              FractionallySizedBox(
                widthFactor: completionPercentage,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(1),
                  ),
                ),
              ),
              // Text
              Center(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
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
    setState(() {
      _isLoading = true;
    });

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
      dataSaved = await _adminSectionKey.currentState?.saveAdminData() ?? false;
    }

    if (dataSaved) {
      if (currentTab == 'ADMIN') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ExternalCabEditPage(
              vehicleId: widget.vehicleId,
              inTabsPage: true,
              onProgressUpdate: () {},
              isEditing: true,
            ),
          ),
        );
      } else {
        setState(() {
          _selectedTabIndex++;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving data. Please try again.')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Method to handle "Done" button press
  Future<void> _onDonePressed() async {
    setState(() {
      _isLoading = true;
    });
    try {
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
          setState(() {
            _isLoading = false;
          });
          // Navigator.of(context).pushReplacementNamed('/home');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => _adminSection),
          );
        } else {
          setState(() {
            _isLoading = false;
          });
          // Handle failure to save parent data
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving data. Please try again.')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle any errors
    }
  }

  double completionPercentage = 0.0;

  updatePercentage(index) {
    // Get completion percentage based on tab index
    if (index == 0 && _maintenanceSectionKey.currentState != null) {
      completionPercentage =
          _maintenanceSectionKey.currentState!.getCompletionPercentage();
    } else if (index == 1 && _adminSectionKey.currentState != null) {
      completionPercentage =
          _adminSectionKey.currentState!.getCompletionPercentage();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLastTab = _selectedTabIndex == _tabContents.length - 1;
    bool isTruckConditionTab =
        _tabTitles[_selectedTabIndex] == 'TRUCK CONDITION';

    const isWeb = kIsWeb;
    final screenWidth = MediaQuery.of(context).size.width;
    final useWebLayout = isWeb && screenWidth > 600;

    return WillPopScope(
      onWillPop: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
        return Future.value(true);
      },
      child: Builder(builder: (context) {
        return Stack(
          children: [
            Scaffold(
              key: _scaffoldKey,
              body: GradientBackground(
                child: Column(
                  children: [
                    TruckInfoWebNavBar(
                      onHomePressed: () => Navigator.pop(context),
                      onBasicInfoPressed: () => Navigator.pushReplacementNamed(
                        context,
                        '/basic_information',
                        arguments: widget.vehicleId,
                      ),
                      onTruckConditionsPressed: () =>
                          Navigator.pushReplacementNamed(
                        context,
                        '/external_cab',
                        arguments: widget.vehicleId,
                      ),
                      onMaintenanceWarrantyPressed: () {},
                      scaffoldKey: _scaffoldKey,
                      onExternalCabPressed: () =>
                          Navigator.pushReplacementNamed(
                        context,
                        '/external_cab',
                        arguments: widget.vehicleId,
                      ),
                      onInternalCabPressed: () =>
                          Navigator.pushReplacementNamed(
                        context,
                        '/internal_cab',
                        arguments: widget.vehicleId,
                      ),
                      onChassisPressed: () => Navigator.pushReplacementNamed(
                        context,
                        '/chassis',
                        arguments: widget.vehicleId,
                      ),
                      onDriveTrainPressed: () => Navigator.pushReplacementNamed(
                        context,
                        '/drive_train',
                        arguments: widget.vehicleId,
                      ),
                      onTyresPressed: () => Navigator.pushReplacementNamed(
                        context,
                        '/tyres',
                        arguments: widget.vehicleId,
                      ),
                      vehicleId: widget.vehicleId,
                      selectedTab: 'Maintenance and Warranty',
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildContent(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0),
                      child: Row(
                        children: [
                          if (_selectedTabIndex < _tabContents.length) ...[
                            Expanded(
                              child: CustomButton(
                                text: 'Continue',
                                onPressed: _onContinuePressed,
                                borderColor: AppColors.orange,
                              ),
                            ),
                            const SizedBox(width: 16.0),
                          ],
                          Expanded(
                            child: CustomButton(
                              text: 'Done',
                              onPressed: _onDonePressed,
                              borderColor: AppColors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Image.asset(
                      'lib/assets/Loading_Logo_CTP.gif',
                      width: 100,
                      height: 100,
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
