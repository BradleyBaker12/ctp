// lib/adminScreens/offer_details_page.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/adminScreens/viewer_page.dart';
import 'package:ctp/pages/setup_collection.dart';
import 'package:ctp/pages/setup_inspection.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart'; // Added for MIME type checks
import '../providers/offer_provider.dart';
import '../providers/user_provider.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';

class OfferDetailPage extends StatefulWidget {
  final Offer offer;

  const OfferDetailPage({Key? key, required this.offer}) : super(key: key);

  @override
  _OfferDetailPageState createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage> {
  late TextEditingController _offerAmountController;
  late TextEditingController _vehicleMakeModelController;
  late TextEditingController _vehicleYearController;
  late TextEditingController _vehicleMileageController;
  late TextEditingController _vehicleTransmissionController;
  bool _isLoadingVehicleDetails = false;

  @override
  void initState() {
    super.initState();
    _offerAmountController =
        TextEditingController(text: widget.offer.offerAmount?.toString() ?? '');
    _vehicleMakeModelController =
        TextEditingController(text: widget.offer.vehicleMakeModel);
    _vehicleYearController =
        TextEditingController(text: widget.offer.vehicleYear);
    _vehicleMileageController =
        TextEditingController(text: widget.offer.vehicleMileage);
    _vehicleTransmissionController =
        TextEditingController(text: widget.offer.vehicleTransmission);

    _fetchVehicleDetails();
  }

  Future<void> _fetchVehicleDetails() async {
    if (mounted) {
      setState(() => _isLoadingVehicleDetails = true);
    }

    try {
      await widget.offer.fetchVehicleDetails();
    } catch (e) {
      debugPrint('ERROR: Failed to fetch vehicle details: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingVehicleDetails = false);
      }
    }
  }

  @override
  void dispose() {
    _offerAmountController.dispose();
    _vehicleMakeModelController.dispose();
    _vehicleYearController.dispose();
    _vehicleMileageController.dispose();
    _vehicleTransmissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return GradientBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Offer Details',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await _refreshOfferDetails();
            },
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Vehicle main image
                      _buildVehicleImage(),
                      const SizedBox(height: 20),

                      /// Editable fields
                      _buildEditableDetailRow(
                        'Vehicle:',
                        _vehicleMakeModelController,
                      ),
                      _buildEditableDetailRow(
                        'Offer Amount:',
                        _offerAmountController,
                      ),

                      /// Non-editable fields
                      _buildDetailRow('Status:', widget.offer.offerStatus),
                      _buildDealerEmailRow(userProvider, widget.offer.dealerId),
                      const SizedBox(height: 20),

                      /// Conditional widgets
                      _buildConditionalWidgets(offerProvider),
                      const SizedBox(height: 20),

                      /// Invoice section
                      _buildInvoiceSection(),
                      const SizedBox(height: 20),

                      /// Save changes
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6,
                          child: CustomButton(
                            text: 'Save Changes',
                            borderColor: Colors.deepOrange,
                            onPressed: () {
                              _saveChanges(offerProvider);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Refresh offer details from Firestore
  Future<void> _refreshOfferDetails() async {
    try {
      DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offer.offerId)
          .get();

      if (offerSnapshot.exists) {
        setState(() {
          final updatedOffer = Offer.fromFirestore(offerSnapshot);
          widget.offer.offerStatus = updatedOffer.offerStatus;
          widget.offer.offerAmount = updatedOffer.offerAmount;
          widget.offer.vehicleMakeModel = updatedOffer.vehicleMakeModel;
          widget.offer.vehicleYear = updatedOffer.vehicleYear;
          widget.offer.vehicleMileage = updatedOffer.vehicleMileage;
          widget.offer.vehicleTransmission = updatedOffer.vehicleTransmission;
          widget.offer.vehicleMainImage = updatedOffer.vehicleMainImage;
          widget.offer.externalInvoice = updatedOffer.externalInvoice;
          widget.offer.needsInvoice = updatedOffer.needsInvoice;
          widget.offer.proofOfPayment = updatedOffer.proofOfPayment;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offer details refreshed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offer not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh offer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Save changes (offer amount, etc.)
  void _saveChanges(OfferProvider offerProvider) {
    final parsedAmount = double.tryParse(_offerAmountController.text) ?? 0.0;
    if (parsedAmount <= 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid offer amount.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    offerProvider.updateOfferAmount(widget.offer.offerId, parsedAmount);
    Navigator.pop(context);
  }

  /// Conditional widgets based on offer status
  Widget _buildConditionalWidgets(OfferProvider offerProvider) {
    switch (widget.offer.offerStatus.toLowerCase()) {
      case 'pending':
      case 'in-progress':
        return _buildApproveRejectRow(offerProvider);
      case 'payment pending':
        return _buildPaymentPendingSection(offerProvider);
      case 'paid':
        return Center(
          child: Text(
            'Payment verified. Offer is paid.',
            style: GoogleFonts.montserrat(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case 'accepted':
        return _buildAcceptedSection();
      case 'rejected':
        return Center(
          child: Text(
            'This offer has been rejected',
            style: GoogleFonts.montserrat(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case 'payment_rejected':
        return Center(
          child: Text(
            'Payment was rejected by admin',
            style: GoogleFonts.montserrat(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      default:
        return Center(
          child: Text(
            'Offer Status: ${widget.offer.offerStatus}',
            style: GoogleFonts.montserrat(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
    }
  }

  /// APPROVE/REJECT BUTTONS - changed from Row to Column
  Widget _buildApproveRejectRow(OfferProvider offerProvider) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomButton(
            text: 'Approve',
            borderColor: Colors.blue,
            onPressed: () async {
              await _updateOfferStatus(offerProvider, 'accepted', 'approve');
            },
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Reject',
            borderColor: const Color(0xFFFF4E00),
            onPressed: () async {
              await _updateOfferStatus(offerProvider, 'rejected', 'reject');
            },
          ),
        ],
      ),
    );
  }

  /// PAYMENT PENDING BUTTONS - changed from Row to Column
  Widget _buildPaymentPendingSection(OfferProvider offerProvider) {
    final popUrl = widget.offer.proofOfPayment;
    return Column(
      children: [
        if (popUrl != null && popUrl.isNotEmpty)
          _buildProofOfPaymentPreview(popUrl),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomButton(
                text: 'Verify Payment',
                borderColor: Colors.green,
                onPressed: () async {
                  await offerProvider.updateOfferStatus(
                    widget.offer.offerId,
                    'paid',
                  );
                  setState(() {
                    widget.offer.offerStatus = 'paid';
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment verified successfully.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Reject Payment',
                borderColor: Colors.red,
                onPressed: () async {
                  await offerProvider.updateOfferStatus(
                    widget.offer.offerId,
                    'payment_rejected',
                  );
                  setState(() {
                    widget.offer.offerStatus = 'payment_rejected';
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment has been rejected.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Proof-of-Payment preview
  Widget _buildProofOfPaymentPreview(String url) {
    final lowerUrl = url.toLowerCase();
    final isImage = lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.gif');
    final isPDF = lowerUrl.endsWith('.pdf');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isImage)
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewerPage(url: url),
              ),
            ),
            child: Container(
              height: 200,
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Text('Error loading image'));
                  },
                ),
              ),
            ),
          )
        else if (isPDF)
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewerPage(url: url),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'View Uploaded PDF Proof of Payment',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          const Text(
            'Unsupported file type',
            style: TextStyle(color: Colors.red),
          ),
        if (isImage || isPDF)
          Align(
            alignment: Alignment.centerRight,
            child: CustomButton(
              text: 'View Proof',
              borderColor: Colors.blueAccent,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewerPage(url: url),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  /// ACCEPTED SECTION: Setup Inspection/Collection
  Widget _buildAcceptedSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.offer.vehicleId)
          .snapshots(),
      builder: (context, vehicleSnapshot) {
        if (!vehicleSnapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final vehicleData =
            vehicleSnapshot.data!.data() as Map<String, dynamic>? ?? {};

        final inspectionLocations = _parseLocations(
          vehicleData['inspectionDetails']?['inspectionLocations']?['locations']
              as List<dynamic>?,
        );
        final collectionLocations = _parseLocations(
          vehicleData['collectionDetails']?['collectionLocations']?['locations']
              as List<dynamic>?,
        );

        final isInspectionComplete = inspectionLocations.isNotEmpty;
        final isCollectionComplete = collectionLocations.isNotEmpty;

        return Column(
          children: [
            const SizedBox(height: 20),
            isInspectionComplete
                ? Text(
                    'Inspection Setup Complete',
                    style: GoogleFonts.montserrat(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : CustomButton(
                    text: 'Setup Inspection',
                    borderColor: Colors.blue,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SetupInspectionPage(
                          vehicleId: widget.offer.vehicleId,
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: 16),
            isCollectionComplete
                ? Text(
                    'Collection Setup Complete',
                    style: GoogleFonts.montserrat(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : CustomButton(
                    text: 'Setup Collection',
                    borderColor: Colors.blue,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SetupCollectionPage(
                          vehicleId: widget.offer.vehicleId,
                        ),
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _parseLocations(List<dynamic>? rawList) {
    if (rawList == null || rawList.isEmpty) {
      return [];
    }
    try {
      return rawList
          .where((e) => e != null)
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error parsing locations: $e');
      return [];
    }
  }

  /// Update offer status (approve/reject, etc.)
  Future<void> _updateOfferStatus(
    OfferProvider offerProvider,
    String status,
    String action,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offer.offerId)
          .update({'offerStatus': status});

      if (status.toLowerCase() == 'accepted') {
        await FirebaseFirestore.instance
            .collection('offers')
            .doc(widget.offer.offerId)
            .update({'needsInvoice': false});
        setState(() {
          widget.offer.offerStatus = status;
          widget.offer.needsInvoice = false;
        });
      } else {
        setState(() {
          widget.offer.offerStatus = status;
        });
      }

      if (mounted) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Offer has been $action successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Exception in $action: $e');
      debugPrint('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to $action the offer. Please try again.\nError: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Non-editable row
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.montserrat(color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Editable row
  Widget _buildEditableDetailRow(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextField(
              controller: controller,
              style: GoogleFonts.montserrat(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Displays the dealer's email
  Widget _buildDealerEmailRow(UserProvider userProvider, String dealerId) {
    return FutureBuilder<String?>(
      future: userProvider.getUserEmailById(dealerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDetailRow('Dealer Email:', 'Loading...');
        } else if (snapshot.hasError) {
          return _buildDetailRow('Dealer Email:', 'Error loading email');
        } else {
          return _buildDetailRow('Dealer Email:', snapshot.data ?? 'Unknown');
        }
      },
    );
  }

  /// Invoice section (external invoice)
  Widget _buildInvoiceSection() {
    if (widget.offer.externalInvoice != null &&
        widget.offer.externalInvoice!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Invoice',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          _buildUploadedInvoice(widget.offer.externalInvoice!),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Replace Invoice',
            borderColor: Colors.orange,
            onPressed: _uploadExternalInvoice,
          ),
        ],
      );
    } else if (widget.offer.needsInvoice ?? false) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            'Upload External Invoice',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: 'Upload Invoice',
            borderColor: Colors.green,
            onPressed: _uploadExternalInvoice,
          ),
        ],
      );
    } else {
      return Container();
    }
  }

  /// Displays the uploaded invoice
  Widget _buildUploadedInvoice(String url) {
    final lowerUrl = url.toLowerCase();
    final isImage = lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.gif');
    final isPDF = lowerUrl.endsWith('.pdf');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isImage)
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewerPage(url: url),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 200,
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Text('Error loading image'));
                },
              ),
            ),
          )
        else if (isPDF)
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ViewerPage(url: url),
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'View Uploaded PDF Invoice',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: CustomButton(
            text: 'View Invoice',
            borderColor: Colors.blueAccent,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewerPage(url: url),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Upload/replace the external invoice
  Future<void> _uploadExternalInvoice() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;

        // Validate MIME type
        final mimeType = lookupMimeType(file.path);
        if (mimeType == null ||
            (!mimeType.startsWith('image/') && mimeType != 'application/pdf')) {
          throw Exception('Unsupported file type.');
        }

        // Upload path with timestamp
        String storagePath =
            'invoices/${widget.offer.offerId}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

        final storageRef = FirebaseStorage.instance.ref(storagePath);
        final uploadTask = storageRef.putFile(file);

        // Wait for upload
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('offers')
            .doc(widget.offer.offerId)
            .update({
          'externalInvoice': downloadUrl,
          'needsInvoice': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          widget.offer.externalInvoice = downloadUrl;
          widget.offer.needsInvoice = false;
        });

        // Refresh offers
        if (context.mounted) {
          Provider.of<OfferProvider>(context, listen: false).refreshOffers();
        }

        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        Navigator.pop(context); // user canceled
      }
    } catch (e) {
      debugPrint('ERROR: Failed to upload invoice: $e');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload invoice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Vehicle image at top
  Widget _buildVehicleImage() {
    debugPrint(
      'DEBUG: Building vehicle image, URL: ${widget.offer.vehicleMainImage}',
    );

    if (_isLoadingVehicleDetails) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4E00)),
        ),
      );
    }

    if (widget.offer.vehicleMainImage == null ||
        widget.offer.vehicleMainImage!.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[800],
        child: const Center(
          child: Icon(Icons.directions_car, size: 50, color: Colors.white54),
        ),
      );
    }

    return Image.network(
      widget.offer.vehicleMainImage!,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('DEBUG: Error loading image: $error');
        return Container(
          height: 200,
          color: Colors.grey[800],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.error_outline, color: Colors.red, size: 40),
                Text('Failed to load image',
                    style: TextStyle(color: Colors.white54)),
              ],
            ),
          ),
        );
      },
    );
  }
}
