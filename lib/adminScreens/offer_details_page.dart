// lib/adminScreens/offer_details_page.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/adminScreens/invoice_viewer_page.dart';
import 'package:ctp/pages/setup_collection.dart';
import 'package:ctp/pages/setup_inspection.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart'; // Added for MIME type checks
import '../providers/offer_provider.dart';
import '../providers/user_provider.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';

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
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Vehicle main image
                if (widget.offer.vehicleMainImage != null)
                  SizedBox(
                    width: double.infinity,
                    child: Image.network(
                      widget.offer.vehicleMainImage!,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Text('Error loading image'));
                      },
                    ),
                  ),
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

                /// Conditional Buttons and Information Based on Offer Status
                _buildConditionalWidgets(offerProvider),

                const SizedBox(height: 20),

                /// Upload External Invoice for 'payment options' status
                if (widget.offer.offerStatus.toLowerCase() == 'payment options')
                  Column(
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
                      widget.offer.externalInvoice != null
                          ? Column(
                              children: [
                                // Display the uploaded invoice
                                _buildUploadedInvoice(
                                    widget.offer.externalInvoice!),
                                const SizedBox(height: 10),
                                CustomButton(
                                  text: 'Replace Invoice',
                                  borderColor: Colors.orange,
                                  onPressed: _uploadExternalInvoice,
                                ),
                              ],
                            )
                          : CustomButton(
                              text: 'Upload Invoice',
                              borderColor: Colors.green,
                              onPressed: _uploadExternalInvoice,
                            ),
                    ],
                  ),

                /// Save changes
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: CustomButton(
                      text: 'Save Changes',
                      borderColor: Colors.deepOrange,
                      onPressed: () {
                        double parsedAmount =
                            double.tryParse(_offerAmountController.text) ?? 0.0;
                        if (parsedAmount <= 0.0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Please enter a valid offer amount.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        offerProvider.updateOfferAmount(
                          widget.offer.offerId,
                          parsedAmount,
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds widgets that are conditionally displayed based on the offer status
  Widget _buildConditionalWidgets(OfferProvider offerProvider) {
    switch (widget.offer.offerStatus.toLowerCase()) {
      case 'in-progress':
        return _buildInProgressButtons(offerProvider);
      case 'payment pending':
        return _buildPaymentPendingSection(offerProvider);
      case 'accepted':
        return _buildAcceptedSection();
      default:
        return Center(
          child: Text(
            widget.offer.offerStatus.toLowerCase() == 'rejected'
                ? 'This offer has been rejected'
                : 'Offer Status: ${widget.offer.offerStatus}',
            style: GoogleFonts.montserrat(
              color: widget.offer.offerStatus.toLowerCase() == 'rejected'
                  ? Colors.red
                  : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
    }
  }

  /// Builds Approve and Reject buttons for 'in-progress' status
  Widget _buildInProgressButtons(OfferProvider offerProvider) {
    return Column(
      children: [
        // Approve/Reject Row
        _buildApproveRejectRow(offerProvider),
      ],
    );
  }

  /// Reusable Approve/Reject button row
  Widget _buildApproveRejectRow(OfferProvider offerProvider) {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CustomButton(
              text: 'Approve',
              borderColor: Colors.blue,
              onPressed: () async {
                await _updateOfferStatus(offerProvider, 'accepted', 'approve');
              },
            ),
            const SizedBox(width: 16),
            CustomButton(
              text: 'Reject',
              borderColor: const Color(0xFFFF4E00),
              onPressed: () async {
                await _updateOfferStatus(offerProvider, 'rejected', 'reject');
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Updates the offer status with error handling
  Future<void> _updateOfferStatus(
      OfferProvider offerProvider, String status, String action) async {
    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offer.offerId)
          .update({'offerStatus': status});

      // Optionally, you can also update 'needsInvoice' based on status
      if (status.toLowerCase() == 'accepted') {
        await FirebaseFirestore.instance
            .collection('offers')
            .doc(widget.offer.offerId)
            .update({'needsInvoice': true});
        setState(() {
          widget.offer.offerStatus = status;
          widget.offer.needsInvoice = true;
        });
      } else {
        setState(() {
          widget.offer.offerStatus = status;
        });
      }

      if (mounted) {
        Navigator.pop(context);
      }
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

  /// Builds the payment pending section with proof of payment
  Widget _buildPaymentPendingSection(OfferProvider offerProvider) {
    return Column(
      children: [
        if (widget.offer.proofOfPayment != null)
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.offer.proofOfPayment!,
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
        const SizedBox(height: 20),

        /// Payment Verification Buttons
        SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                },
              ),
              const SizedBox(width: 16),
              CustomButton(
                text: 'Reject Payment',
                borderColor: Colors.red,
                onPressed: () async {
                  await offerProvider.updateOfferStatus(
                      widget.offer.offerId, 'payment_rejected');
                  setState(() {
                    widget.offer.offerStatus = 'payment_rejected';
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the accepted section with inspection and collection setup
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

        Map<String, dynamic> vehicleData =
            vehicleSnapshot.data!.data() as Map<String, dynamic>;

        List<Map<String, dynamic>> inspectionLocations = _parseLocations(
          vehicleData['inspectionDetails']?['inspectionLocations']?['locations']
              as List<dynamic>?,
        );

        List<Map<String, dynamic>> collectionLocations = _parseLocations(
          vehicleData['collectionDetails']?['collectionLocations']?['locations']
              as List<dynamic>?,
        );

        bool isInspectionComplete = inspectionLocations.isNotEmpty;
        bool isCollectionComplete = collectionLocations.isNotEmpty;

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

  /// Helper to parse location arrays safely
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

  /// Displays a non-editable row with a label and value
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
              style: GoogleFonts.montserrat(
                color: Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Displays an editable row with a label and a TextField
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

  /// Asynchronously fetches the Dealer's email and displays it
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

  /// Displays the uploaded invoice based on file type
  Widget _buildUploadedInvoice(String url) {
    // Determine the file type based on the URL extension
    final isImage = url.toLowerCase().endsWith('.png') ||
        url.toLowerCase().endsWith('.jpg') ||
        url.toLowerCase().endsWith('.jpeg') ||
        url.toLowerCase().endsWith('.gif');

    final isPDF = url.toLowerCase().endsWith('.pdf');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isImage)
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InvoiceViewerPage(url: url),
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
                builder: (context) => InvoiceViewerPage(url: url),
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
          )
        else
          const Text(
            '',
            style: TextStyle(color: Colors.red),
          ),
        const SizedBox(height: 10),
        // Replace ElevatedButton with CustomButton
        Align(
          alignment: Alignment.centerRight,
          child: CustomButton(
            text: 'View Invoice',
            borderColor: Colors.blueAccent,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InvoiceViewerPage(url: url),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Handles the uploading of the external invoice
  Future<void> _uploadExternalInvoice() async {
    try {
      // Pick a file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'gif'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String fileName = path.basename(file.path);
        String fileExt = path.extension(fileName).toLowerCase();

        // Debug: Print the selected file name and extension
        debugPrint('Selected file name: $fileName');
        debugPrint('Selected file extension: $fileExt');

        // Remove the dot before checking
        String fileExtWithoutDot =
            fileExt.startsWith('.') ? fileExt.substring(1) : fileExt;

        // Validate file type by extension
        if (!(['pdf', 'png', 'jpg', 'jpeg', 'gif']
            .contains(fileExtWithoutDot))) {
          debugPrint('File extension not supported.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unsupported file type selected.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Validate file type by MIME type
        final mimeType = lookupMimeType(file.path);
        debugPrint('MIME type: $mimeType');

        if (mimeType == null ||
            (!mimeType.startsWith('image/') && mimeType != 'application/pdf')) {
          debugPrint('MIME type not supported.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Unsupported file type selected based on MIME type.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Optionally, validate file size (e.g., limit to 10MB)
        final int fileSize = await file.length();
        if (fileSize > 10 * 1024 * 1024) {
          // 10MB
          debugPrint('File size exceeds 10MB limit.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File size exceeds 10MB limit.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Show a loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        // Define storage path with timestamp to prevent naming conflicts
        String storagePath =
            'invoices/${widget.offer.offerId}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

        // Upload to Firebase Storage
        UploadTask uploadTask =
            FirebaseStorage.instance.ref(storagePath).putFile(file);

        // Await completion
        TaskSnapshot snapshot = await uploadTask;

        // Get download URL
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Update Firestore with the invoice URL and set needsInvoice to false
        await FirebaseFirestore.instance
            .collection('offers')
            .doc(widget.offer.offerId)
            .update({
          'externalInvoice': downloadUrl,
          'needsInvoice': false, // Set needsInvoice to false
        });

        // Update the local state
        setState(() {
          widget.offer.externalInvoice = downloadUrl;
          widget.offer.needsInvoice = false; // Reflect the change locally
        });

        // Optionally, notify the OfferProvider about the change
        // This depends on your OfferProvider implementation
        // For example:
        // offerProvider.refreshOffers(); // To fetch updated data

        // Dismiss the loading indicator
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // User canceled the picker
        debugPrint('File picking was canceled by the user.');
      }
    } catch (e, stackTrace) {
      debugPrint('Error uploading invoice: $e');
      debugPrint('Stack trace: $stackTrace');
      // Dismiss the loading indicator if it's open
      Navigator.pop(context);
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload invoice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
