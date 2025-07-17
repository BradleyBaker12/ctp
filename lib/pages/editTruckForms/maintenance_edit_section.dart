import 'package:ctp/adminScreens/local_viewer_page.dart';
import 'package:ctp/adminScreens/viewer_page.dart';
import 'package:ctp/pages/truck_page.dart';
import 'package:ctp/pages/vehicles_list.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/pages/truckForms/custom_radio_button.dart';
import 'package:ctp/pages/truckForms/custom_text_field.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:ctp/components/truck_info_web_nav.dart';
// Import the shared camera helper
import 'package:ctp/utils/camera_helper.dart';

// import 'package:auto_route/auto_route.dart';
// @RoutePage()
class MaintenanceEditSection extends StatefulWidget {
  final String vehicleId;
  final bool isUploading;
  final bool isEditing;
  final String oemInspectionType;
  final String oemInspectionExplanation;
  final String? maintenanceDocUrl;
  final String? warrantyDocUrl;
  final Function(File?) onMaintenanceFileSelected;
  final Function(File?) onWarrantyFileSelected;
  final String maintenanceSelection;
  final String warrantySelection;
  final File? maintenanceDocFile;
  final File? warrantyDocFile;
  final VoidCallback onProgressUpdate;
  final bool isFromAdmin;
  final bool isFromTransporter;

  const MaintenanceEditSection(
      {super.key,
      required this.vehicleId,
      required this.isUploading,
      this.isEditing = false,
      required this.onMaintenanceFileSelected,
      required this.onWarrantyFileSelected,
      required this.oemInspectionType,
      required this.oemInspectionExplanation,
      required this.onProgressUpdate,
      this.maintenanceDocUrl,
      this.warrantyDocUrl,
      required this.maintenanceSelection,
      required this.warrantySelection,
      this.maintenanceDocFile,
      this.warrantyDocFile,
      required this.isFromAdmin,
      required this.isFromTransporter});

  @override
  MaintenanceEditSectionState createState() {
    debugPrint('DEBUG: Creating MaintenanceEditSection with:');
    debugPrint('maintenanceDocUrl: "$maintenanceDocUrl"');
    debugPrint('warrantyDocUrl: "$warrantyDocUrl"');
    return MaintenanceEditSectionState();
  }
}

class MaintenanceEditSectionState extends State<MaintenanceEditSection>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TextEditingController _oemReasonController;
  late String _oemInspectionType;
  Uint8List? _maintenanceDocFile;
  Uint8List? _warrantyDocFile;
  String? _maintenanceDocFileName;
  String? _warrantyDocFileName;

  // Add these state variables to track document URLs
  String? _currentMaintenanceDocUrl;
  String? _currentWarrantyDocUrl;

  @override
  void initState() {
    super.initState();
    debugPrint('DEBUG: MaintenanceEditSection initState');
    debugPrint(
        'DEBUG: Initial maintenanceDocUrl: "${widget.maintenanceDocUrl}"');
    debugPrint('DEBUG: Initial warrantyDocUrl: "${widget.warrantyDocUrl}"');

    // Initialize state variables
    _oemInspectionType = widget.oemInspectionType;
    _oemReasonController =
        TextEditingController(text: widget.oemInspectionExplanation);
    _currentMaintenanceDocUrl = widget.maintenanceDocUrl;
    _currentWarrantyDocUrl = widget.warrantyDocUrl;

    // Fetch fresh data
    _fetchMaintenanceData();

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    _oemReasonController.addListener(notifyProgress);
  }

  @override
  void didUpdateWidget(covariant MaintenanceEditSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicleId != widget.vehicleId) {
      _oemInspectionType = widget.oemInspectionType;
      _oemReasonController.text = widget.oemInspectionExplanation;
      _currentMaintenanceDocUrl = widget.maintenanceDocUrl;
      _currentWarrantyDocUrl = widget.warrantyDocUrl;
      _maintenanceDocFile = null;
      _warrantyDocFile = null;
      _fetchMaintenanceData();
    }
  }

  Future<void> _fetchMaintenanceData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .get();

      if (!doc.exists) {
        debugPrint(
            'DEBUG: Document does not exist for vehicleId: ${widget.vehicleId}');
        return;
      }

      final data = doc.data();
      debugPrint('DEBUG: Fetched document data: $data');

      // Use an if/else block to set maintenanceData instead of a nested ternary operator.
      Map<String, dynamic>? maintenanceData;
      if (data?['maintenanceData'] is Map<String, dynamic>) {
        maintenanceData = data?['maintenanceData'] as Map<String, dynamic>;
      } else if (data?['maintenance'] is Map<String, dynamic>) {
        maintenanceData = data?['maintenance'] as Map<String, dynamic>;
      } else {
        maintenanceData = null;
      }

      debugPrint('DEBUG: Fetched maintenanceData: $maintenanceData');

      if (maintenanceData != null) {
        try {
          setState(() {
            _oemInspectionType =
                maintenanceData!['oemInspectionType']?.toString() ?? 'yes';
            _oemReasonController.text =
                maintenanceData['oemReason']?.toString() ?? '';
            _currentMaintenanceDocUrl =
                maintenanceData['maintenanceDocUrl']?.toString() ??
                    maintenanceData['maintenanceDocumentUrl']?.toString();
            _currentWarrantyDocUrl =
                maintenanceData['warrantyDocUrl']?.toString() ??
                    maintenanceData['warrantyDocumentUrl']?.toString();
          });
          debugPrint(
              'DEBUG: Updated _currentMaintenanceDocUrl: $_currentMaintenanceDocUrl');
          debugPrint(
              'DEBUG: Updated _currentWarrantyDocUrl: $_currentWarrantyDocUrl');
        } catch (e) {
          debugPrint('DEBUG: Exception during conversion: $e');
        }
      } else {
        debugPrint('DEBUG: No maintenanceData found in document.');
      }
    } catch (e, stack) {
      debugPrint('DEBUG: Error fetching maintenance data: $e');
      debugPrint('DEBUG: Stack: $stack');
    }
  }

  @override
  void dispose() {
    _oemReasonController.dispose();
    super.dispose();
  }

  void clearData() {
    setState(() {
      _oemInspectionType = 'yes';
      _oemReasonController.clear();
      _maintenanceDocFile = null;
      _warrantyDocFile = null;
    });
  }

  // Update method to handle existing data
  void loadMaintenanceData(Map<String, dynamic>? maintenanceData) {
    if (maintenanceData != null) {
      setState(() {
        _oemInspectionType = maintenanceData['oemInspectionType'] ?? 'yes';
        _oemReasonController.text = maintenanceData['oemReason'] ?? '';

        // Handle document URLs if they exist
        if (maintenanceData['maintenanceDocUrl'] != null) {
          widget.onMaintenanceFileSelected(null); // Clear any existing file
        }
        if (maintenanceData['warrantyDocUrl'] != null) {
          widget.onWarrantyFileSelected(null); // Clear any existing file
        }
      });
    }
  }

  // Method to save maintenance data
  Future<bool> saveMaintenanceData() async {
    String? oemReason =
        _oemInspectionType == 'no' ? _oemReasonController.text.trim() : null;

    if (_oemInspectionType == 'no' &&
        (oemReason!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please explain why OEM inspection is not possible.'),
        ),
      );
      return false;
    }

    // Prepare data to send
    Map<String, dynamic> maintenanceData = {
      'vehicleId': widget.vehicleId,
      'oemInspectionType': _oemInspectionType,
      'oemReason': oemReason,
    };

    try {
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .set({'maintenanceData': maintenanceData}, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maintenance saved successfully.')),
      );

      return true;
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save maintenance: $error')),
      );
      return false;
    }
  }

  /// Updated method to pick a maintenance document.
  /// Presents a dialog allowing the user to choose either Camera or Gallery.
  Future<void> _pickMaintenanceDocument() async {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Choose Source for Maintenance Document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final imageBytes = await capturePhoto(context);
                  if (imageBytes != null) {
                    setState(() {
                      _maintenanceDocFile = imageBytes;
                      _maintenanceDocFileName = "captured_maintenance.png";
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: [
                      'pdf',
                      'jpg',
                      'jpeg',
                      'png',
                      'doc',
                      'docx',
                      'xls',
                      'xlsx'
                    ],
                  );
                  if (result != null) {
                    final bytes = await result.files.single.xFile.readAsBytes();
                    setState(() {
                      _maintenanceDocFile = bytes;
                      _maintenanceDocFileName = result.files.single.xFile.name;
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

  /// Updated method to pick a warranty document.
  /// Presents a dialog allowing the user to choose either Camera or Gallery.
  Future<void> _pickWarrantyDocument() async {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Choose Source for Warranty Document'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  final imageBytes = await capturePhoto(context);
                  if (imageBytes != null) {
                    setState(() {
                      _warrantyDocFile = imageBytes;
                      _warrantyDocFileName = "captured_warranty.png";
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: [
                      'pdf',
                      'jpg',
                      'jpeg',
                      'png',
                      'doc',
                      'docx',
                      'xls',
                      'xlsx'
                    ],
                  );
                  if (result != null) {
                    final bytes = await result.files.single.xFile.readAsBytes();
                    setState(() {
                      _warrantyDocFile = bytes;
                      _warrantyDocFileName = result.files.single.xFile.name;
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

  IconData _getFileIcon(String fileName) {
    final extension =
        path.extension(fileName).toLowerCase().trim().split("?").first.trim();

    switch (extension) {
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.xls':
      case '.xlsx':
        return Icons.grid_on;
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
        return Icons.image;
      case '.txt':
        return Icons.text_snippet;
      case '.zip':
      case '.rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  bool _isImageFile(String path) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    String extension = getFileExtension(path);
    print("File Extnnsion: $extension");
    return imageExtensions.contains(extension);
  }

  String getFileExtension(String url) {
    Uri uri = Uri.parse(url);
    String decodedPath = Uri.decodeFull(uri.path);
    String fileName = decodedPath.split('/').last;
    return fileName.contains('.') ? fileName.split('.').last : '';
  }

  String getFileNameFromUrl(String url) {
    // if (url.contains('maintenance_doc')) {
    //   return 'Maintenance Doc';
    // } else if (url.contains('warranty_doc')) {
    //   return 'Warranty Doc';
    // }
    // Fallback to original filename if pattern doesn't match
    Uri uri = Uri.parse(url);
    String decodedPath = Uri.decodeFull(uri.path);
    String fileName = decodedPath.split('/').last;

    return fileName;
  }

  void updateMaintenanceFile(Uint8List? file) {
    setState(() {
      _maintenanceDocFile = file;
    });
    notifyProgress();
  }

  void updateWarrantyFile(Uint8List? file) {
    setState(() {
      _warrantyDocFile = file;
    });
    notifyProgress();
  }

  double getCompletionPercentage() {
    int totalFields = 0;
    int filledFields = 0;

    // Check for maintenance document
    if (widget.maintenanceSelection == 'yes') {
      totalFields += 1;
      if (_maintenanceDocFile != null || _currentMaintenanceDocUrl != null) {
        filledFields += 1;
      }

      // OEM Inspection fields
      totalFields += 1;
      filledFields += 1; // Always filled since it has a default value

      if (_oemInspectionType == 'no') {
        totalFields += 1;
        if (_oemReasonController.text.trim().isNotEmpty) {
          filledFields += 1;
        }
      }
    }

    // Check for warranty document
    if (widget.warrantySelection == 'yes') {
      totalFields += 1;
      if (_warrantyDocFile != null || _currentWarrantyDocUrl != null) {
        filledFields += 1;
      }
    }

    if (totalFields == 0) return 1.0; // If no fields are required
    return filledFields / totalFields;
  }

  void notifyProgress() {
    widget.onProgressUpdate();
  }

  Future<void> _viewPdf(String url, String title) async {
    try {
      if (url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Document URL is empty')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewerPage(url: url),
        ),
      );
    } catch (e) {
      debugPrint('Error viewing document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error viewing document: $e')),
      );
    }
  }

  // New method to view a local document.
  Future<void> _viewLocalDocument(Uint8List file, String title) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocalViewerPage(file: file, title: title),
      ),
    );
  }

  void _showDocumentOptions(bool isMaintenance) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String userRole = userProvider.getUserRole;
    final bool isAdmin = userRole == 'admin';
    final bool isDealer = userRole == 'dealer';
    final bool isTransporter = userRole == 'transporter';
    final bool isSales = userRole == 'sales';
    final bool canEdit = isAdmin || isSales || isTransporter;

    // Use the widget URL if the local state variable is null.
    final String? url = isMaintenance
        ? (_currentMaintenanceDocUrl ?? widget.maintenanceDocUrl)
        : (_currentWarrantyDocUrl ?? widget.warrantyDocUrl);
    final Uint8List? file =
        isMaintenance ? _maintenanceDocFile : _warrantyDocFile;
    final String title =
        isMaintenance ? 'Maintenance Document' : 'Warranty Document';

    debugPrint('DEBUG: _showDocumentOptions called');
    debugPrint('DEBUG: isMaintenance: $isMaintenance');
    debugPrint(
        'DEBUG: current maintenanceDocUrl: "$_currentMaintenanceDocUrl"');
    debugPrint('DEBUG: current warrantyDocUrl: "$_currentWarrantyDocUrl"');
    debugPrint('DEBUG: selected url: "$url"');
    debugPrint('DEBUG: file exists: ${file != null}');
    debugPrint('DEBUG: title: "$title"');

    if ((url == null || url.isEmpty) && file == null) {
      debugPrint('ERROR: URL is null or empty. Widget URLs:');
      debugPrint('maintenanceDocUrl: "${widget.maintenanceDocUrl}"');
      debugPrint('warrantyDocUrl: "${widget.warrantyDocUrl}"');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document URL not available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View'),
                onTap: () async {
                  Navigator.pop(context);
                  if (file != null) {
                    await _viewLocalDocument(file, title);
                  } else {
                    await _viewPdf(url ?? '', title);
                  }
                },
              ),
              if (canEdit)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Change'),
                  onTap: () {
                    Navigator.pop(context);
                    if (isMaintenance) {
                      _pickMaintenanceDocument();
                    } else {
                      _pickWarrantyDocument();
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    debugPrint(
        'DEBUG: In build() with _currentMaintenanceDocUrl: $_currentMaintenanceDocUrl');
    debugPrint(
        'DEBUG: In build() with _currentWarrantyDocUrl: $_currentWarrantyDocUrl');
    final userProvider = Provider.of<UserProvider>(context);
    final String userRole = userProvider.getUserRole;
    print("UserRole: $userRole");
    print("Maintenance Selection: ${widget.maintenanceSelection}");
    print("Warranty Selection: ${widget.warrantySelection}");
    final bool isAdmin = userRole == 'admin';
    final bool isDealer = userRole == 'dealer';
    final bool isTransporter = userRole == 'transporter';
    final bool isSales = userRole == 'sales';
    final bool canEdit = isAdmin || isSales || isTransporter;

    // Define different text prompts for dealers vs. transporters.
    final String maintenanceTitle = isDealer ? 'Maintenance' : 'Maintenance';
    final String maintenancePrompt = isDealer
        ? 'VIEW MAINTENANCE DOCUMENTATION'
        : 'PLEASE ATTACH MAINTENANCE DOCUMENTATION';
    final String warrantyPrompt = isDealer
        ? 'VIEW WARRANTY DOCUMENTATION'
        : 'PLEASE ATTACH WARRANTY DOCUMENTATION';
    final String maintanceUploadBlock =
        isDealer ? 'MAINTENANCE DOCUMENTATION' : 'MAINTENANCE DOC UPLOAD';
    final String warrantyUploadBlock =
        isDealer ? 'WARRANTY DOCUMENTATION' : 'WARRANTY DOC UPLOAD';

    final String oemInspectionPrompt = isDealer
        ? 'AN OEM INSPECTION HAS BEEN DONE ON THIS VEHICLE'
        : 'CAN YOUR VEHICLE BE SENT TO OEM FOR A FULL INSPECTION UNDER R&M CONTRACT?';
    final String oemInspectionNote = isDealer
        ? 'OEM WILL HANDLE THE INSPECTION PROCESS'
        : 'PLEASE NOTE THAT OEM WILL CHARGE YOU FOR INSPECTION.';

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: TruckInfoWebNavBar(
          scaffoldKey: _scaffoldKey,
          selectedTab: "Maintenance and Warranty",
          vehicleId: widget.vehicleId,
          onHomePressed: () => Navigator.pushNamed(context, '/home'),
          onBasicInfoPressed: () =>
              Navigator.pushNamed(context, '/basic_information'),
          onTruckConditionsPressed: () =>
              Navigator.pushNamed(context, '/truck_conditions'),
          onMaintenanceWarrantyPressed: () =>
              Navigator.pushNamed(context, '/maintenance_warranty'),
          onExternalCabPressed: () =>
              Navigator.pushNamed(context, '/external_cab'),
          onInternalCabPressed: () =>
              Navigator.pushNamed(context, '/internal_cab'),
          onChassisPressed: () => Navigator.pushNamed(context, '/chassis'),
          onDriveTrainPressed: () =>
              Navigator.pushNamed(context, '/drive_train'),
          onTyresPressed: () => Navigator.pushNamed(context, '/tyres'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GradientBackground(
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        if (widget.maintenanceSelection == 'yes' ||
                            widget.maintenanceSelection == '') ...[
                          Center(
                            child: Text(
                              maintenanceTitle.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 25,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 15),
                          if (widget.maintenanceDocUrl == null)
                            Center(
                              child: Text(
                                maintenancePrompt.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 15),
                          InkWell(
                            onTap: canEdit ? _pickMaintenanceDocument : null,
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
                                  if (_maintenanceDocFile == null &&
                                      _currentMaintenanceDocUrl == null)
                                    Icon(
                                      Icons.drive_folder_upload_outlined,
                                      color: Colors.white,
                                      size: 50.0,
                                      semanticLabel:
                                          'Upload Maintenance Document',
                                    ),
                                  const SizedBox(height: 10),
                                  if (_maintenanceDocFile != null ||
                                      _currentMaintenanceDocUrl != null)
                                    InkWell(
                                      onTap: () => _showDocumentOptions(true),
                                      child: Column(
                                        children: [
                                          if (_maintenanceDocFile != null)
                                            _isImageFile(
                                                    _maintenanceDocFileName ??
                                                        '')
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                    child: Image.memory(
                                                      _maintenanceDocFile!,
                                                      width: 100,
                                                      height: 100,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : Column(
                                                    children: [
                                                      Icon(
                                                        _getFileIcon(
                                                            _maintenanceDocFileName ??
                                                                ''),
                                                        color: Colors.white,
                                                        size: 50.0,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Container(
                                                        width: double.infinity,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                    16.0),
                                                        child: Text(
                                                          _maintenanceDocFileName ??
                                                              '',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                          else if (_currentMaintenanceDocUrl !=
                                              null)
                                            _isImageFile(
                                                    _currentMaintenanceDocUrl!)
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                    child: Image.network(
                                                      _currentMaintenanceDocUrl!,
                                                      width: 100,
                                                      height: 100,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : Column(
                                                    children: [
                                                      Icon(
                                                        _getFileIcon(
                                                            _currentMaintenanceDocUrl!),
                                                        color: Colors.white,
                                                        size: 50.0,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Container(
                                                        width: double.infinity,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                    16.0),
                                                        child: Text(
                                                          getFileNameFromUrl(
                                                              _currentMaintenanceDocUrl!),
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          const SizedBox(height: 8),
                                          if (widget.isUploading)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                CircularProgressIndicator(),
                                                SizedBox(width: 10),
                                                Text(
                                                  'Uploading...',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    )
                                  else if (!widget.isUploading)
                                    Text(
                                      maintanceUploadBlock,
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
                          Center(
                            child: Text(
                              oemInspectionPrompt.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Center(
                            child: Text(
                              oemInspectionNote.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomRadioButton(
                                label: 'Yes',
                                value: 'yes',
                                groupValue: _oemInspectionType,
                                onChanged: canEdit
                                    ? (String? value) {
                                        if (value != null) {
                                          setState(() {
                                            _oemInspectionType = value;
                                            if (_oemInspectionType == 'yes') {
                                              _oemReasonController.clear();
                                            }
                                          });
                                          notifyProgress();
                                        }
                                      }
                                    : (String? value) {},
                                enabled: canEdit,
                              ),
                              const SizedBox(width: 15),
                              CustomRadioButton(
                                label: 'No',
                                value: 'no',
                                groupValue: _oemInspectionType,
                                onChanged: canEdit
                                    ? (String? value) {
                                        if (value != null) {
                                          setState(() {
                                            _oemInspectionType = value;
                                          });
                                          notifyProgress();
                                        }
                                      }
                                    : (String? value) {},
                                enabled: canEdit,
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          if (_oemInspectionType == 'no')
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: CustomTextField(
                                controller: _oemReasonController,
                                hintText: 'ENTER REASONING HERE'.toUpperCase(),
                                enabled: canEdit,
                              ),
                            ),
                          const SizedBox(height: 15),
                        ],
                        if (widget.warrantySelection == 'yes' ||
                            widget.warrantySelection == '') ...[
                          if (widget.warrantyDocUrl == null)
                            Center(
                              child: Text(
                                warrantyPrompt.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(height: 15),
                          InkWell(
                            onTap: canEdit ? _pickWarrantyDocument : null,
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
                                  if (_warrantyDocFile == null &&
                                      _currentWarrantyDocUrl == null)
                                    Icon(
                                      Icons.drive_folder_upload_outlined,
                                      color: Colors.white,
                                      size: 50.0,
                                      semanticLabel: 'Upload Warranty Document',
                                    ),
                                  const SizedBox(height: 10),
                                  if (_warrantyDocFile != null ||
                                      _currentWarrantyDocUrl != null)
                                    InkWell(
                                      onTap: () => _showDocumentOptions(false),
                                      child: Column(
                                        children: [
                                          if (_warrantyDocFile != null)
                                            _isImageFile(
                                                    _warrantyDocFileName ?? '')
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                    child: Image.memory(
                                                      _warrantyDocFile!,
                                                      width: 100,
                                                      height: 100,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : Column(
                                                    children: [
                                                      Icon(
                                                        _getFileIcon(
                                                            _warrantyDocFileName ??
                                                                ''),
                                                        color: Colors.white,
                                                        size: 50.0,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Container(
                                                        width: double.infinity,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                    16.0),
                                                        child: Text(
                                                          _warrantyDocFileName ??
                                                              '',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                          else if (_currentWarrantyDocUrl !=
                                              null)
                                            _isImageFile(
                                                    _currentWarrantyDocUrl!)
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                    child: Image.network(
                                                      _currentWarrantyDocUrl!,
                                                      width: 100,
                                                      height: 100,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : Column(
                                                    children: [
                                                      Icon(
                                                        _getFileIcon(
                                                            _currentWarrantyDocUrl!),
                                                        color: Colors.white,
                                                        size: 50.0,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        getFileNameFromUrl(
                                                            _currentWarrantyDocUrl!),
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ],
                                                  ),
                                          const SizedBox(height: 8),
                                          if (widget.isUploading)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                CircularProgressIndicator(),
                                                SizedBox(width: 10),
                                                Text(
                                                  'Uploading...',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    )
                                  else if (!widget.isUploading)
                                    Text(
                                      warrantyUploadBlock,
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
                          if (isTransporter || isSales || isAdmin)
                            CustomButton(
                              onPressed: () async {
                                // Show loading indicator
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                );

                                try {
                                  // Initialize empty update data
                                  Map<String, dynamic> maintenanceData = {};

                                  // Only add fields that have changed
                                  if (_oemInspectionType !=
                                      widget.oemInspectionType) {
                                    maintenanceData['oemInspectionType'] =
                                        _oemInspectionType;
                                  }

                                  // Only add OEM reason if it has changed and is needed
                                  if (_oemInspectionType == 'no' &&
                                      _oemReasonController.text.trim() !=
                                          widget.oemInspectionExplanation) {
                                    maintenanceData['oemReason'] =
                                        _oemReasonController.text.trim();
                                  }

                                  // Handle maintenance document
                                  if (_maintenanceDocFile != null) {
                                    final storageRef = FirebaseStorage.instance
                                        .ref()
                                        .child(
                                            'vehicles/${widget.vehicleId}/maintenance')
                                        .child(
                                            'maintenance_doc_${DateTime.now().millisecondsSinceEpoch}$_maintenanceDocFileName');

                                    await storageRef
                                        .putData(_maintenanceDocFile!);
                                    String newMaintenanceDocUrl =
                                        await storageRef.getDownloadURL();
                                    maintenanceData['maintenanceDocUrl'] =
                                        newMaintenanceDocUrl;
                                  }

                                  // Handle warranty document
                                  if (_warrantyDocFile != null) {
                                    final storageRef = FirebaseStorage.instance
                                        .ref()
                                        .child(
                                            'vehicles/${widget.vehicleId}/maintenance')
                                        .child(
                                            'warranty_doc_${DateTime.now().millisecondsSinceEpoch}$_warrantyDocFileName');

                                    await storageRef.putData(_warrantyDocFile!);
                                    String newWarrantyDocUrl =
                                        await storageRef.getDownloadURL();
                                    maintenanceData['warrantyDocUrl'] =
                                        newWarrantyDocUrl;
                                  }

                                  // Only add selection fields if they've been provided
                                  if (widget.maintenanceSelection != '') {
                                    maintenanceData['maintenanceSelection'] =
                                        widget.maintenanceSelection;
                                  }
                                  if (widget.warrantySelection != '') {
                                    maintenanceData['warrantySelection'] =
                                        widget.warrantySelection;
                                  }

                                  // Only update if there are changes
                                  if (maintenanceData.isNotEmpty) {
                                    maintenanceData['lastUpdated'] =
                                        FieldValue.serverTimestamp();
                                    maintenanceData['vehicleId'] =
                                        widget.vehicleId;

                                    await FirebaseFirestore.instance
                                        .collection('vehicles')
                                        .doc(widget.vehicleId)
                                        .set(
                                          widget.isFromAdmin
                                              ? {
                                                  "maintenanceData":
                                                      maintenanceData
                                                }
                                              : {
                                                  'maintenance': maintenanceData
                                                },
                                          SetOptions(merge: true),
                                        );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Maintenance data updated successfully')),
                                    );
                                  }

                                  Navigator.pop(
                                      context); // Dismiss loading indicator
                                  Navigator.pop(
                                      context); // Return to previous screen

                                  if (widget.isFromAdmin ||
                                      widget.isFromTransporter) {
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const VehiclesListPage()));
                                  } else {
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const TruckPage()));
                                  }
                                } catch (error) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Error updating maintenance data: $error')),
                                  );
                                }
                              },
                              text: 'Save Changes',
                              borderColor: Colors.deepOrange,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true; // Ensure the state is kept alive
}
