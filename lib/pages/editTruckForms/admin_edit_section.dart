// admin_section.dart

import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/custom_text_field.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/vehicles_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

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
    _natisRc1Url = widget.natisRc1Url;
    _licenseDiskUrl = widget.licenseDiskUrl;
    _settlementLetterUrl = widget.settlementLetterUrl;
  }

  @override
  void dispose() {
    _settlementAmountController.dispose();
    super.dispose();
  }

  // Helper function to pick files
  Future<void> _pickFile(int docNumber) async {
    // Only pick files if editing is enabled
    if (!widget.isEditing) return;

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
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

              _natisRc1Url = null; // Clear URL when a new file is selected
              widget.onAdminDoc1Selected(bytes, fileName);
              break;
            case 2:
              _licenseDiskFile = bytes;
              _licenseDiskFileName = fileName;
              _licenseDiskUrl = null; // Clear URL when a new file is selected
              widget.onAdminDoc2Selected(bytes, fileName);
              break;
            case 3:
              _settlementLetterFile = bytes;
              _settlementLetterFileName = fileName;
              _settlementLetterUrl = null; // Clear URL when a new file selected
              widget.onAdminDoc3Selected(bytes, fileName);
              break;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
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

  // Helper method to display uploaded files in a Stack with "X" to remove
  Widget _buildUploadedFile(
      {required Uint8List? file,
      required String? fileUrl,
      required bool isUploading,
      required VoidCallback onRemove, // Callback to remove this doc
      required String docName,
      required String fileName}) {
    // If no file or URL, show "No file selected"
    if (file == null && fileUrl == null) {
      return const Text(
        'No file selected',
        style: TextStyle(color: Colors.white70),
      );
    }

    // Otherwise, gather file name + extension
    // String fileName;
    // String extension;
    // if (file != null) {
    //   fileName = file.path.split('/').last;
    //   extension = fileName.split('.').last;
    // } else {
    //   fileName = getFileNameFromUrl(fileUrl!);
    //   extension = fileName.split('.').last;
    // }

    // "Main widget" is either an image or an icon
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
      // We have a URL
      if (_isImageUrl(fileUrl!)) {
        mainWidget = ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: CachedNetworkImage(
            imageUrl: fileUrl,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            placeholder: (context, url) => Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
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
          .doc(widget.vehicle.id) // Use the vehicle ID here
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // For AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        leading: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(4),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 30,
              minHeight: 30,
            ),
            icon: const Text(
              'BACK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              widget.vehicle.referenceNumber ?? 'REF',
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(width: 16),
            Text(
              widget.vehicle.makeModel.toString().toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(width: 16),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 24,
              backgroundImage: widget.vehicle.mainImageUrl != null
                  ? NetworkImage(widget.vehicle.mainImageUrl!)
                  : const AssetImage('assets/truck_image.png') as ImageProvider,
            ),
          ),
        ],
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height, // Full screen
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
                      'Please attach NATIS/RC1 Documentation'.toUpperCase(),
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
                    onTap: () => _pickFile(1),
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
                          if (_natisRc1File == null && _natisRc1Url == null)
                            const Icon(
                              Icons.drive_folder_upload_outlined,
                              color: Colors.white,
                              size: 50.0,
                              semanticLabel: 'NATIS/RC1 Upload',
                            ),
                          const SizedBox(height: 10),
                          if (_natisRc1File != null || _natisRc1Url != null)
                            _buildUploadedFile(
                              file: _natisRc1File,
                              fileUrl: _natisRc1Url,
                              isUploading: _isUploading,
                              fileName: _natisRc1FileName ?? "",
                              docName: 'NATIS/RC1',
                              onRemove: () {
                                // Remove NATIS/RC1 doc
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
                      'Please attach License Disk Photo'.toUpperCase(),
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
                    onTap: () => _pickFile(2),
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
                                // Remove License Disk doc
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
                    // Upload Settlement Letter
                    Center(
                      child: Text(
                        'Please attach Settlement Letter'.toUpperCase(),
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
                      onTap: () => _pickFile(3),
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
                                  // Remove Settlement Letter doc
                                  setState(() {
                                    _settlementLetterFile = null;
                                    _settlementLetterUrl = null;
                                    widget.onAdminDoc3Selected(null, null);
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
                        'Please fill in your settlement amount'.toUpperCase(),
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
                        hintText: 'Amount'.toUpperCase(),
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
                          ? null // Disable button if loading
                          : () async {
                              setState(() {
                                _isLoading = true; // Set loading state
                              });

                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  );
                                },
                              );

                              try {
                                bool success = await saveAdminData();
                                Navigator.pop(context); // Dismiss loading
                                if (success) {
                                  Navigator.pop(context); // pop the page
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => VehiclesListPage()));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Admin data saved successfully.',
                                      ),
                                    ),
                                  );
                                }
                              } catch (error) {
                                Navigator.pop(context); // Dismiss loading
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error saving admin data: $error',
                                    ),
                                  ),
                                );
                              } finally {
                                setState(() {
                                  _isLoading = false; // Reset loading state
                                });
                              }
                            },
                      text: 'DONE',
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
    );
  }

  @override
  bool get wantKeepAlive => true; // Ensure the state is kept alive
}
