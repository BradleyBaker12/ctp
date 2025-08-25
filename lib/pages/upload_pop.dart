// File: upload_proof_of_payment_page.dart

import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/pages/payment_pending_page.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:auto_route/auto_route.dart';

@RoutePage()
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
  Uint8List? _selectedFile;
  String? _selectedFileName;
  final FirebaseStorage storage = FirebaseStorage.instance;

  // Gating: only allow POP when an admin invoice exists on the offer
  StreamSubscription<DocumentSnapshot>? _offerSub;
  bool _invoiceReady = false;
  bool _checkingInvoice = true;
  String? _invoiceUrl;

  @override
  void initState() {
    super.initState();
    _offerSub = FirebaseFirestore.instance
        .collection('offers')
        .doc(widget.offerId)
        .snapshots()
        .listen((snap) {
      final data = snap.data();
      final ready = _extractInvoiceInfo(data);
      setState(() {
        _invoiceReady = ready;
        _checkingInvoice = false;
      });
    }, onError: (_) {
      setState(() {
        _invoiceReady = false;
        _checkingInvoice = false;
      });
    });
  }

  @override
  void dispose() {
    _offerSub?.cancel();
    super.dispose();
  }

  bool _extractInvoiceInfo(Map<String, dynamic>? data) {
    if (data == null) return false;
    final keys = [
      'externalInvoiceUrl',
      'externalInvoice',
      'invoiceUrl',
      'sageInvoiceUrl',
      'invoicePdfUrl',
      'invoiceDownloadUrl',
    ];
    String? url;
    for (final k in keys) {
      final v = data[k];
      if (v is String && v.trim().isNotEmpty) {
        url = v.trim();
        break;
      }
    }
    _invoiceUrl = url;
    return url != null && url.isNotEmpty;
  }

  Future<void> _openInvoice() async {
    if (_invoiceUrl == null) return;
    final uri = Uri.tryParse(_invoiceUrl!);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open invoice')),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!_invoiceReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Invoice not available yet. Please wait for admin to upload the invoice.')),
      );
      return;
    }
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedFile = bytes;
          _selectedFileName = pickedFile.name;
        });
        await _uploadFile();
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _pickFile() async {
    if (!_invoiceReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Invoice not available yet. Please wait for admin to upload the invoice.')),
      );
      return;
    }
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null) {
        final bytes = result.files.single.bytes;
        if (bytes != null) {
          setState(() {
            _selectedFile = bytes;
            _selectedFileName = result.files.single.name;
          });
          await _uploadFile();
        }
      }
    } catch (e) {
      print('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null || _selectedFileName == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Double-check invoice to avoid race conditions
      final snap = await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .get();
      final data = snap.data();
      if (!_extractInvoiceInfo(data)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Invoice not available yet. Please wait for admin to upload the invoice.')),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      String fileName =
          'proof_of_payment/${widget.offerId}/${DateTime.now().millisecondsSinceEpoch}_$_selectedFileName';
      Reference storageReference =
          FirebaseStorage.instance.ref().child(fileName);

      // Upload the file bytes
      UploadTask uploadTask = storageReference.putData(_selectedFile!);
      await uploadTask.whenComplete(() => null);

      String fileURL = await storageReference.getDownloadURL();

      // Save the file URL to Firestore
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({
        'proofOfPaymentUrl': fileURL,
        'proofOfPaymentFileName': _selectedFileName,
        'uploadTimestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isUploaded = true;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proof of payment uploaded successfully')),
      );

      // Navigate back to the PaymentPendingPage after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentPendingPage(offerId: widget.offerId),
          ),
        );
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error uploading file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: $e')),
      );
    }
  }

  void _showPickerDialog() {
    if (!_invoiceReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Invoice not available yet. Please wait for admin to upload the invoice.')),
      );
      return;
    }
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
    final isDisabled = !_invoiceReady || _checkingInvoice;
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
                  if (_checkingInvoice)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: CircularProgressIndicator(),
                    ),
                  if (!_checkingInvoice && !_invoiceReady)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.orange.withOpacity(0.1),
                      ),
                      child: const Text(
                        'Awaiting admin invoice. You can upload your proof of payment once the invoice is available.',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (_invoiceUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: CustomButton(
                        text: 'View Invoice',
                        onPressed: _openInvoice,
                        borderColor: const Color(0xFFFF4E00),
                      ),
                    ),
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
                      onTap: isDisabled
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Invoice not available yet. Please wait for admin to upload the invoice.')),
                              );
                            }
                          : _showPickerDialog,
                      child: Opacity(
                        opacity: isDisabled ? 0.5 : 1.0,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: isDisabled ? Colors.grey : Colors.blue),
                            borderRadius: BorderRadius.circular(10),
                            color: (isDisabled ? Colors.grey : Colors.blue)
                                .withOpacity(0.1),
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
