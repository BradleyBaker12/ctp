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
import 'package:mime/mime.dart'; // Added for MIME type checks
import '../providers/offer_provider.dart';
import '../providers/user_provider.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';

/// Simple debug helper: prints with a 'DEBUG:' prefix.
void debugText(String message) {
  debugPrint('DEBUG: $message');
}

class OfferDetailPage extends StatefulWidget {
  final Offer offer;

  const OfferDetailPage({super.key, required this.offer});

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
    debugText('initState: OfferDetailPage initialized');

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
      debugText('Fetching vehicle details...');
      await widget.offer.fetchVehicleDetails();
      debugText('Vehicle details fetched successfully.');
    } catch (e) {
      debugText('ERROR: Failed to fetch vehicle details: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingVehicleDetails = false);
      }
    }
  }

  @override
  void dispose() {
    debugText('dispose: Cleaning up controllers');
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

                      /// Conditional widgets (Approve/Reject, Payment, etc.)
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
      debugText('Refreshing offer details from Firestore...');
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
          widget.offer.proofOfPaymentUrl = updatedOffer.proofOfPaymentUrl;
        });
        debugText('Offer details refreshed successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offer details refreshed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        debugText('Offer not found in Firestore.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offer not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugText('Failed to refresh offer: $e');
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
      debugText('Invalid offer amount entered. Skipping.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid offer amount.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    debugText('Saving changes: new offer amount = $parsedAmount');
    offerProvider.updateOfferAmount(widget.offer.offerId, parsedAmount);
    Navigator.pop(context);
  }

  /// Conditional widgets based on offer status
  Widget _buildConditionalWidgets(OfferProvider offerProvider) {
    final status = widget.offer.offerStatus.toLowerCase();
    debugText('_buildConditionalWidgets: current status -> $status');

    switch (status) {
      case 'pending':
      case 'in-progress':
        return _buildApproveRejectRow(offerProvider);

      case 'payment pending':
        return _buildPaymentPendingSection(offerProvider);

      case 'paid':
        return _buildPaidSection(offerProvider);

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
        return _buildPaymentRejectedSection(offerProvider);

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

  /// APPROVE/REJECT BUTTONS
  Widget _buildApproveRejectRow(OfferProvider offerProvider) {
    debugText('_buildApproveRejectRow: building Approve/Reject buttons');
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomButton(
            text: 'Approve',
            borderColor: Colors.blue,
            onPressed: () async {
              debugText('Approve button tapped.');
              await _updateOfferStatus(offerProvider, 'accepted', 'approve');
            },
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Reject',
            borderColor: const Color(0xFFFF4E00),
            onPressed: () async {
              debugText('Reject button tapped.');
              await _updateOfferStatus(offerProvider, 'rejected', 'reject');
            },
          ),
        ],
      ),
    );
  }

  /// PAYMENT PENDING SECTION (with debug logging)
  Widget _buildPaymentPendingSection(OfferProvider offerProvider) {
    debugText('Entered _buildPaymentPendingSection.');
    final popUrl = widget.offer.proofOfPaymentUrl;
    debugText('Current proofOfPaymentUrl URL -> $popUrl');

    return Column(
      children: [
        // Show a thumbnail if there's a proof URL; otherwise show placeholder text
        if (popUrl != null && popUrl.isNotEmpty)
          _buildproofOfPaymentUrlThumbnail(popUrl)
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No proof of payment has been uploaded yet.',
              style: GoogleFonts.montserrat(color: Colors.white70),
            ),
          ),

        const SizedBox(height: 8),

        // Always display the "View Proof" button; disable if no proof URL
        CustomButton(
          text: 'View Proof',
          borderColor: Colors.blueAccent,
          onPressed: (popUrl == null || popUrl.isEmpty)
              ? null // Disable button when there's no URL
              : () {
                  debugText('"View Proof" button tapped!');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewerPage(url: popUrl),
                    ),
                  );
                },
        ),

        const SizedBox(height: 20),

        /// Payment Action Buttons
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomButton(
                text: 'Verify Payment',
                borderColor: Colors.green,
                onPressed: () async {
                  debugText('"Verify Payment" button tapped!');
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
                  debugText('"Reject Payment" button tapped!');
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

  /// If you prefer a smaller thumbnail, use this helper widget
  Widget _buildproofOfPaymentUrlThumbnail(String url) {
    final lowerUrl = url.toLowerCase();
    final isImage = lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.gif');
    final isPDF = lowerUrl.endsWith('.pdf');

    if (isImage) {
      return Container(
        height: 100,
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Text('Error loading image'));
          },
        ),
      );
    } else if (isPDF) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 8),
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
                'Proof of Payment (PDF)',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return const Text(
        '',
        style: TextStyle(color: Colors.red),
      );
    }
  }

  /// SECTION WHEN PAYMENT IS MARKED "PAID"
  Widget _buildPaidSection(OfferProvider offerProvider) {
    debugText('_buildPaidSection: showing "Paid" status');
    return Column(
      children: [
        Center(
          child: Text(
            'Payment verified. Offer is paid.',
            style: GoogleFonts.montserrat(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Allow admin to revert if there's a mistake
        CustomButton(
          text: 'Change Payment Status',
          borderColor: Colors.orange,
          onPressed: () async {
            debugText('Reverting "paid" status back to "payment pending"');
            await offerProvider.updateOfferStatus(
              widget.offer.offerId,
              'payment pending',
            );
            setState(() {
              widget.offer.offerStatus = 'payment pending';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Payment status changed back to "payment pending".'),
                backgroundColor: Colors.orange,
              ),
            );
          },
        ),
      ],
    );
  }

  /// SECTION WHEN PAYMENT IS "REJECTED"
  Widget _buildPaymentRejectedSection(OfferProvider offerProvider) {
    debugText(
        '_buildPaymentRejectedSection: showing "Payment Rejected" status');
    return Column(
      children: [
        Center(
          child: Text(
            'Payment was rejected by admin.',
            style: GoogleFonts.montserrat(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Allow admin to revert if there's a mistake
        CustomButton(
          text: 'Change Payment Status',
          borderColor: Colors.orange,
          onPressed: () async {
            debugText(
                'Reverting "payment_rejected" status back to "payment pending"');
            await offerProvider.updateOfferStatus(
              widget.offer.offerId,
              'payment pending',
            );
            setState(() {
              widget.offer.offerStatus = 'payment pending';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Payment status changed back to "payment pending".'),
                backgroundColor: Colors.orange,
              ),
            );
          },
        ),
      ],
    );
  }

  /// ACCEPTED SECTION: Setup Inspection/Collection
  Widget _buildAcceptedSection() {
    debugText('_buildAcceptedSection: streaming offer data...');
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offer.offerId)
          .snapshots(),
      builder: (context, offerSnapshot) {
        if (!offerSnapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final offerData =
            offerSnapshot.data!.data() as Map<String, dynamic>? ?? {};

        final inspectionLocations = _parseLocations(
          offerData['inspectionDetails']?['inspectionLocations']?['locations']
              as List<dynamic>?,
        );
        final collectionLocations = _parseLocations(
          offerData['collectionDetails']?['collectionLocations']?['locations']
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
                          offerId: widget.offer.offerId,
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
                          offerId: widget.offer.offerId,
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
      debugText('Error parsing locations: $e');
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
      debugText(
          '_updateOfferStatus: setting status = $status, action = $action');
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offer.offerId)
          .update({'offerStatus': status});

      if (status.toLowerCase() == 'accepted') {
        debugText('Setting needsInvoice to false since offer is accepted');
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
      debugText('Exception in $action: $e');
      debugText('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to $action the offer. Please try again.\nError: $e',
          ),
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
    debugText(
        '_buildDealerEmailRow: fetching user email for dealerId=$dealerId');
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
    debugText('_buildInvoiceSection: checking if externalInvoice is set.');
    if (widget.offer.externalInvoice != null &&
        widget.offer.externalInvoice!.isNotEmpty) {
      debugText(
          'Invoice found. Showing the invoice preview and Replace button.');
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
      debugText('Offer needsInvoice = true. Prompting to upload invoice.');
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
      debugText(
          'No externalInvoice set and not needing invoice. Returning empty.');
      return Container();
    }
  }

  /// Displays the uploaded invoice
  Widget _buildUploadedInvoice(String url) {
    debugText('_buildUploadedInvoice: $url');
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
              debugText('View Invoice button tapped!');
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
    debugText('_uploadExternalInvoice: invoked');
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

        debugText('Uploading invoice: $fileName, mimeType: $mimeType');

        // Upload path with timestamp
        String storagePath =
            'invoices/${widget.offer.offerId}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

        final storageRef = FirebaseStorage.instance.ref(storagePath);
        final uploadTask = storageRef.putFile(file);

        // Wait for upload
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        debugText('Invoice uploaded. Download URL: $downloadUrl');

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
        debugText('User canceled file picker or no file selected.');
        Navigator.pop(context); // user canceled
      }
    } catch (e) {
      debugText('ERROR: Failed to upload invoice: $e');
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
    debugText(
      'Building vehicle image, URL: ${widget.offer.vehicleMainImage}',
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
        debugText('ERROR loading image: $error');
        return Container(
          height: 200,
          color: Colors.grey[800],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.error_outline, color: Colors.red, size: 40),
                Text(
                  'Failed to load image',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
