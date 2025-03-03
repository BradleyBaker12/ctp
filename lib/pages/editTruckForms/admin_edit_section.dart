import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/adminScreens/local_viewer_page.dart';
import 'package:ctp/adminScreens/viewer_page.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/custom_text_field.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/truck_info_web_nav.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/vehicles_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ctp/utils/camera_helper.dart'; // Import shared camera helper

class AdminEditSection extends StatefulWidget {
  final Vehicle vehicle;
  final bool isUploading;
  final bool isEditing; // Whether user is allowed to edit/remove docs
  final Function(Uint8List?, String?) onAdminDoc1Selected;
  final Function(Uint8List?, String?) onAdminDoc2Selected;
  final Function(Uint8List?, String?) onAdminDoc3Selected;

  // Parameter to accept the user's selection
  final String requireToSettleType;

  // Parameters to accept existing data
  final String? settlementAmount;
  final String? natisRc1Url;
  final String? licenseDiskUrl;
  final String? settlementLetterUrl;

  const AdminEditSection({
    super.key,
    required this.vehicle,
    required this.isUploading,
    this.isEditing = false,
    required this.onAdminDoc1Selected,
    required this.onAdminDoc2Selected,
    required this.onAdminDoc3Selected,
    required this.requireToSettleType,
    this.settlementAmount,
    this.natisRc1Url,
    this.licenseDiskUrl,
    this.settlementLetterUrl,
  });

  @override
  AdminEditSectionState createState() => AdminEditSectionState();
}

class AdminEditSectionState extends State<AdminEditSection>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Controllers for input fields
  final TextEditingController _settlementAmountController =
      TextEditingController();

  // Variables to hold selected files
  Uint8List? _natisRc1File;
  Uint8List? _licenseDiskFile;
  Uint8List? _settlementLetterFile;
  String? _natisRc1FileName;
  String? _licenseDiskFileName;
  String? _settlementLetterFileName;

  // Variables to hold existing file URLs
  String? _natisRc1Url;
  String? _licenseDiskUrl;
  String? _settlementLetterUrl;

  bool _isUploading = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _settlementAmountController.text = widget.settlementAmount ?? '';
    _natisRc1Url =
        (widget.natisRc1Url?.isNotEmpty ?? false) ? widget.natisRc1Url : null;
    _licenseDiskUrl = (widget.licenseDiskUrl?.isNotEmpty ?? false)
        ? widget.licenseDiskUrl
        : null;
    _settlementLetterUrl = (widget.settlementLetterUrl?.isNotEmpty ?? false)
        ? widget.settlementLetterUrl
        : null;
  }

  @override
  void dispose() {
    _settlementAmountController.dispose();
    super.dispose();
  }

  /// This updated _pickFile method now shows a dialog that lets the user choose
  /// between using the Camera (via the shared camera helper) or picking a file from Gallery.
  Future<void> _pickFile(int docNumber) async {
    // Only pick files if editing is enabled
    if (!widget.isEditing) return;

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Choose Source for Document'),
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
                      switch (docNumber) {
                        case 1:
                          _natisRc1File = imageBytes;
                          _natisRc1FileName = "captured_natisRc1.png";
                          _natisRc1Url = null;
                          widget.onAdminDoc1Selected(
                              imageBytes, _natisRc1FileName);
                          break;
                        case 2:
                          _licenseDiskFile = imageBytes;
                          _licenseDiskFileName = "captured_licenseDisk.png";
                          _licenseDiskUrl = null;
                          widget.onAdminDoc2Selected(
                              imageBytes, _licenseDiskFileName);
                          break;
                        case 3:
                          _settlementLetterFile = imageBytes;
                          _settlementLetterFileName =
                              "captured_settlementLetter.png";
                          _settlementLetterUrl = null;
                          widget.onAdminDoc3Selected(
                              imageBytes, _settlementLetterFileName);
                          break;
                      }
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
                    final bytes = await result.xFiles.first.readAsBytes();
                    final fileName = result.xFiles.first.name;
                    setState(() {
                      switch (docNumber) {
                        case 1:
                          _natisRc1File = bytes;
                          _natisRc1FileName = fileName;
                          _natisRc1Url = null;
                          widget.onAdminDoc1Selected(bytes, fileName);
                          break;
                        case 2:
                          _licenseDiskFile = bytes;
                          _licenseDiskFileName = fileName;
                          _licenseDiskUrl = null;
                          widget.onAdminDoc2Selected(bytes, fileName);
                          break;
                        case 3:
                          _settlementLetterFile = bytes;
                          _settlementLetterFileName = fileName;
                          _settlementLetterUrl = null;
                          widget.onAdminDoc3Selected(bytes, fileName);
                          break;
                      }
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

  bool _isImageUrl(String url) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    String extension = url.split('.').last.toLowerCase().split('?').first;
    return imageExtensions.contains(extension);
  }

  String getFileNameFromUrl(String url) {
    return url.split('/').last.split('?').first;
  }

  // Helper method to display uploaded files.
  Widget _buildUploadedFile({
    required Uint8List? file,
    required String? fileUrl,
    required bool isUploading,
    required VoidCallback onRemove,
    required String docName,
    required String fileName,
  }) {
    // If no file or URL, show "No file selected"
    if (file == null && fileUrl == null) {
      return const Text(
        'No file selected',
        style: TextStyle(color: Colors.white70),
      );
    }

    Widget mainWidget;
    if (file != null) {
      // We have a local file
      if (_isImageFile(fileName)) {
        mainWidget = ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.memory(
            file,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        );
      } else {
        mainWidget = Column(
          children: [
            Icon(
              _getFileIcon(fileName),
              color: Colors.white,
              size: 50.0,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                docName,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      }
    } else {
      // We have a URL – use Image.network if it's an image, otherwise show icon + text
      if (_isImageUrl(fileUrl!)) {
        mainWidget = ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.network(
            fileUrl,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                        : null,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              width: 100,
              height: 100,
              color: Colors.grey,
              child: const Center(
                child: Icon(Icons.error, color: Colors.white),
              ),
            ),
          ),
        );
      } else {
        mainWidget = Column(
          children: [
            Icon(
              _getFileIcon(fileName),
              color: Colors.white,
              size: 50.0,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                docName,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      }
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // The main widget (image or icon + doc name)
        Column(
          children: [
            mainWidget,
            const SizedBox(height: 8),
            if (isUploading)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(width: 10),
                  Text(
                    'Uploading...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
          ],
        ),
        // Show "X" only if editing is allowed & we have a file/URL
        if (widget.isEditing && (file != null || fileUrl != null))
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: onRemove,
            ),
          ),
      ],
    );
  }

  void loadAdminData(Map<String, dynamic> adminData) {
    setState(() {
      _settlementAmountController.text = adminData['settlementAmount'] ?? '';
      _natisRc1Url = adminData['natisRc1Url'];
      _licenseDiskUrl = adminData['licenseDiskUrl'];
      _settlementLetterUrl = adminData['settlementLetterUrl'];
    });
  }

  void clearData() {
    setState(() {
      _settlementAmountController.clear();
      _natisRc1File = null;
      _licenseDiskFile = null;
      _settlementLetterFile = null;
      _natisRc1Url = null;
      _licenseDiskUrl = null;
      _settlementLetterUrl = null;
    });
  }

  Future<bool> saveAdminData({bool skipValidation = false}) async {
    String settlementAmount = _settlementAmountController.text.trim();

    // Validation checks
    if (!skipValidation &&
        widget.requireToSettleType == 'yes' &&
        settlementAmount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the settlement amount.')),
      );
      return false;
    }

    if (!skipValidation && _natisRc1File == null && _natisRc1Url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload the NATIS/RC1 document.')),
      );
      return false;
    }

    if (!skipValidation &&
        _licenseDiskFile == null &&
        _licenseDiskUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload the License Disk.')),
      );
      return false;
    }

    if (!skipValidation &&
        widget.requireToSettleType == 'yes' &&
        _settlementLetterFile == null &&
        _settlementLetterUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload the Settlement Letter.')),
      );
      return false;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload documents if new files are selected, otherwise use existing URLs
      String natisRc1Url;
      if (_natisRc1File != null) {
        natisRc1Url = await _uploadDocument(
            _natisRc1File!, 'NATIS_RC1', _natisRc1FileName ?? "");
      } else if (_natisRc1Url != null) {
        natisRc1Url = _natisRc1Url!;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please upload the NATIS/RC1 document.')),
        );
        return false;
      }

      String licenseDiskUrl;
      if (_licenseDiskFile != null) {
        licenseDiskUrl = await _uploadDocument(
            _licenseDiskFile!, 'LicenseDisk', _licenseDiskFileName ?? "");
      } else if (_licenseDiskUrl != null) {
        licenseDiskUrl = _licenseDiskUrl!;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload the License Disk.')),
        );
        return false;
      }

      String? settlementLetterUrl;
      if (widget.requireToSettleType == 'yes') {
        if (_settlementLetterFile != null) {
          settlementLetterUrl = await _uploadDocument(_settlementLetterFile!,
              'SettlementLetter', _settlementLetterFileName ?? "");
        } else if (_settlementLetterUrl != null) {
          settlementLetterUrl = _settlementLetterUrl!;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please upload the Settlement Letter.')),
          );
          return false;
        }
      }

      // Prepare data to save
      Map<String, dynamic> adminData = {
        'natisRc1Url': natisRc1Url,
        'licenseDiskUrl': licenseDiskUrl,
      };

      if (widget.requireToSettleType == 'yes') {
        adminData['settlementAmount'] = settlementAmount;
        adminData['settlementLetterUrl'] = settlementLetterUrl;
      }

      // Save to Firestore using the vehicle's ID
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicle.id)
          .set({'adminData': adminData}, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin data saved successfully.')),
      );

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save admin data: $e')),
      );
      return false;
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Helper method to upload a single document
  Future<String> _uploadDocument(
      Uint8List file, String docName, String filesName) async {
    String extension = filesName.split('.').last;
    String fileName =
        'admin_docs/${widget.vehicle.referenceNumber}_$docName${DateTime.now().millisecondsSinceEpoch}.$extension';
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = storageRef.putData(file);

    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  void updateAdminDoc1(Uint8List? file) {
    setState(() {
      _natisRc1File = file;
    });
  }

  void updateAdminDoc2(Uint8List? file) {
    setState(() {
      _licenseDiskFile = file;
    });
  }

  void updateAdminDoc3(Uint8List? file) {
    setState(() {
      _settlementLetterFile = file;
    });
  }

  double getCompletionPercentage() {
    int totalFields = 0;
    int filledFields = 0;

    // NATIS/RC1 Document
    totalFields++;
    if (_natisRc1File != null || _natisRc1Url != null) filledFields++;

    // License Disk
    totalFields++;
    if (_licenseDiskFile != null || _licenseDiskUrl != null) filledFields++;

    // Settlement fields if required
    if (widget.requireToSettleType == 'yes') {
      totalFields += 2; // Settlement Letter + Settlement Amount
      if (_settlementLetterFile != null || _settlementLetterUrl != null) {
        filledFields++;
      }
      if (_settlementAmountController.text.trim().isNotEmpty) filledFields++;
    }

    return totalFields == 0 ? 1.0 : filledFields / totalFields;
  }

  // New function: show view/change/cancel options for admin documents
  void _showDocumentOptionsAdmin(String docType) {
    String? url;
    Uint8List? file;
    switch (docType) {
      case 'natisRc1':
        url = _natisRc1Url;
        file = _natisRc1File;
        break;
      case 'licenseDisk':
        url = _licenseDiskUrl;
        file = _licenseDiskFile;
        break;
      case 'settlementLetter':
        url = _settlementLetterUrl;
        file = _settlementLetterFile;
        break;
    }
    String title;
    switch (docType) {
      case 'natisRc1':
        title = 'NATIS/RC1 Document';
        break;
      case 'licenseDisk':
        title = 'License Disk Document';
        break;
      case 'settlementLetter':
        title = 'Settlement Letter';
        break;
      default:
        title = 'Document';
    }
    // Updated condition: Show error only if both local file and URL are absent.
    if ((url == null || url.isEmpty) && file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document URL not available')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
                    await _viewDocument(url ?? '', title);
                  }
                },
              ),
              if (widget.isEditing)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Change'),
                  onTap: () {
                    Navigator.pop(context);
                    if (docType == 'natisRc1') {
                      _pickFile(1);
                    } else if (docType == 'licenseDisk') {
                      _pickFile(2);
                    } else if (docType == 'settlementLetter') {
                      _pickFile(3);
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

  // Updated: Rename _viewPdf to _viewDocument
  Future<void> _viewDocument(String url, String title) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewerPage(
          url: url,
        ),
      ),
    );
  }

  // New method to view a local document.
  Future<void> _viewLocalDocument(Uint8List file, String title) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocalViewerPage(
          file: file,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // For AutomaticKeepAliveClientMixin
    return Scaffold(
      body: Column(
        children: [
          PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: TruckInfoWebNavBar(
              scaffoldKey: _scaffoldKey,
              selectedTab: "Admin",
              vehicleId: widget.vehicle.id,
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
          Expanded(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: GradientBackground(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            'ADMINISTRATION'.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 25,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Upload NATIS/RC1 Document
                        Center(
                          child: Text(
                            'PLEASE ATTACH NATIS/RC1 DOCUMENTATION',
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
                          onTap: () {
                            if (_natisRc1File != null || _natisRc1Url != null) {
                              _showDocumentOptionsAdmin('natisRc1');
                            } else {
                              _pickFile(1);
                            }
                          },
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
                                if (_natisRc1File == null &&
                                    _natisRc1Url == null)
                                  const Icon(
                                    Icons.drive_folder_upload_outlined,
                                    color: Colors.white,
                                    size: 50.0,
                                    semanticLabel: 'NATIS/RC1 Upload',
                                  ),
                                const SizedBox(height: 10),
                                if (_natisRc1File != null ||
                                    _natisRc1Url != null)
                                  _buildUploadedFile(
                                    file: _natisRc1File,
                                    fileUrl: _natisRc1Url,
                                    isUploading: _isUploading,
                                    fileName: _natisRc1FileName ?? "",
                                    docName: 'NATIS/RC1',
                                    onRemove: () {
                                      setState(() {
                                        _natisRc1File = null;
                                        _natisRc1Url = null;
                                        widget.onAdminDoc1Selected(null, null);
                                      });
                                    },
                                  )
                                else
                                  const Text(
                                    'NATIS/RC1 Upload',
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
                        // Upload License Disk
                        Center(
                          child: Text(
                            'PLEASE ATTACH LICENSE DISK PHOTO',
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
                          onTap: () {
                            if (_licenseDiskFile != null ||
                                _licenseDiskUrl != null) {
                              _showDocumentOptionsAdmin('licenseDisk');
                            } else {
                              _pickFile(2);
                            }
                          },
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
                                if (_licenseDiskFile == null &&
                                    _licenseDiskUrl == null)
                                  const Icon(
                                    Icons.drive_folder_upload_outlined,
                                    color: Colors.white,
                                    size: 50.0,
                                    semanticLabel: 'License Disk Upload',
                                  ),
                                const SizedBox(height: 10),
                                if (_licenseDiskFile != null ||
                                    _licenseDiskUrl != null)
                                  _buildUploadedFile(
                                    file: _licenseDiskFile,
                                    fileUrl: _licenseDiskUrl,
                                    fileName: _licenseDiskFileName ?? "",
                                    isUploading: _isUploading,
                                    docName: 'License Disk',
                                    onRemove: () {
                                      setState(() {
                                        _licenseDiskFile = null;
                                        _licenseDiskUrl = null;
                                        widget.onAdminDoc2Selected(null, null);
                                      });
                                    },
                                  )
                                else
                                  const Text(
                                    'License Disk Upload',
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
                        // Conditionally display Settlement Letter upload and Settlement Amount field
                        if (widget.requireToSettleType == 'yes') ...[
                          Center(
                            child: Text(
                              'PLEASE ATTACH SETTLEMENT LETTER',
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
                            onTap: () {
                              if (_settlementLetterFile != null ||
                                  _settlementLetterUrl != null) {
                                _showDocumentOptionsAdmin('settlementLetter');
                              } else {
                                _pickFile(3);
                              }
                            },
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
                                  if (_settlementLetterFile == null &&
                                      _settlementLetterUrl == null)
                                    const Icon(
                                      Icons.drive_folder_upload_outlined,
                                      color: Colors.white,
                                      size: 50.0,
                                      semanticLabel: 'Settlement Letter Upload',
                                    ),
                                  const SizedBox(height: 10),
                                  if (_settlementLetterFile != null ||
                                      _settlementLetterUrl != null)
                                    _buildUploadedFile(
                                      file: _settlementLetterFile,
                                      fileName: _settlementLetterFileName ?? "",
                                      fileUrl: _settlementLetterUrl,
                                      isUploading: _isUploading,
                                      docName: 'Settlement Letter',
                                      onRemove: () {
                                        setState(() {
                                          _settlementLetterFile = null;
                                          _settlementLetterUrl = null;
                                          widget.onAdminDoc3Selected(
                                              null, null);
                                        });
                                      },
                                    )
                                  else
                                    const Text(
                                      'Settlement Letter Upload',
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
                          // Input Field for Settlement Amount
                          Center(
                            child: Text(
                              'PLEASE FILL IN YOUR SETTLEMENT AMOUNT',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            height: 60.0,
                            child: CustomTextField(
                              controller: _settlementAmountController,
                              hintText: 'AMOUNT',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        const SizedBox(height: 20),
                        // Done Button
                        Center(
                          child: CustomButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    setState(() {
                                      _isLoading = true;
                                    });

                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (BuildContext context) {
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        );
                                      },
                                    );

                                    try {
                                      bool success = await saveAdminData();
                                      Navigator.pop(context);
                                      if (success) {
                                        Navigator.pop(context);
                                        Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    VehiclesListPage()));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Admin data saved successfully.',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (error) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error saving admin data: $error',
                                          ),
                                        ),
                                      );
                                    } finally {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    }
                                  },
                            text: 'Save Changes',
                            borderColor: Colors.deepOrange,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
