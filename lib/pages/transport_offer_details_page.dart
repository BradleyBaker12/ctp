// transporter_offer_details_page.dart

import 'package:ctp/adminScreens/viewer_page.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/pages/setup_inspection.dart';
import 'package:ctp/pages/setup_collection.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:provider/provider.dart'; // Import CustomButton
import 'package:ctp/utils/navigation.dart';
import 'package:ctp/pages/offer_summary_page.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
// Removed unused imports for url launching and web blobs
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:ctp/utils/offer_status.dart';

// import 'package:auto_route/auto_route.dart';

// @RoutePage()
class TransporterOfferDetailsPage extends StatefulWidget {
  final Offer offer;
  final Vehicle vehicle;

  const TransporterOfferDetailsPage({
    super.key,
    required this.offer,
    required this.vehicle,
  });

  @override
  _TransporterOfferDetailsPageState createState() =>
      _TransporterOfferDetailsPageState();
}

class _TransporterOfferDetailsPageState
    extends State<TransporterOfferDetailsPage> {
  final TextEditingController _rejectReasonController = TextEditingController();
  PlatformFile? _selectedInvoice;
  String? _existingInvoiceUrl;
  int _currentImageIndex = 0;
  late List<String> allPhotos;
  late PageController _pageController;
  bool _hasResponded = false;
  String _responseMessage = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Initialize photos with null checks
    allPhotos = [];
    if (widget.vehicle.mainImageUrl != null) {
      allPhotos.add(widget.vehicle.mainImageUrl!);
    }
    if (widget.vehicle.photos.isNotEmpty) {
      allPhotos.addAll(
          widget.vehicle.photos.where((photo) => photo != null).cast<String>());
    }
    // Add a default image if no photos are available
    if (allPhotos.isEmpty) {
      allPhotos.add('assets/default_vehicle_image.png');
    }

    if (widget.offer.offerStatus == 'accepted' ||
        widget.offer.offerStatus == 'rejected') {
      _hasResponded = true;
      _responseMessage = widget.offer.offerStatus == 'accepted'
          ? 'You have accepted the offer'
          : 'You have rejected the offer';
    } else {
      _hasResponded = false;
      _responseMessage = '';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _rejectReasonController.dispose();
    super.dispose();
  }

  TextStyle customFont(double size, FontWeight weight, Color color) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  String _formatRand(num amount) {
    final formatted = NumberFormat.currency(
      locale: 'en_ZA',
      symbol: 'R',
      decimalDigits: 0,
    ).format(amount);
    final withSpaces = formatted.replaceAll(',', ' ');
    // Ensure exactly one normal space after 'R' at the start (handles cases like 'R411 000' or 'R\u00A0411 000')
    return withSpaces.replaceFirst(RegExp(r'^R\s*'), 'R ');
  }

  Widget _breakdownTable(List<MapEntry<String, String>> rows) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(),
        1: IntrinsicColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows
          .map(
            (r) => TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Text(r.key,
                      style: customFont(16, FontWeight.w500, Colors.grey)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      r.value,
                      style: customFont(16, FontWeight.bold, Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  Future<void> _pickInvoiceFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'doc', 'docx'],
      withData: true, // ensure bytes are available for web
    );
    if (result != null) {
      setState(() {
        _selectedInvoice = result.files.first;
      });
      print(
          'DEBUG: picked invoice: ${_selectedInvoice!.name}, bytes=${_selectedInvoice!.bytes != null}, path=${_selectedInvoice!.path}');
    }
  }

  void _showInvoiceOptions() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Invoice Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.remove_red_eye),
                title: const Text('View Invoice'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViewerPage(url: _existingInvoiceUrl!),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Replace Invoice'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickInvoiceFile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Invoice',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _selectedInvoice = null;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
          ],
        );
      },
    );
  }

  // Removed unused _openInvoiceUrl and _viewInvoice helpers

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

  bool _isImageFile(String path) {
    final extension = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png'].contains(extension);
  }

  Widget _buildInvoiceDisplay() {
    final name = _selectedInvoice!.name;
    final ext = name.split('.').last.toLowerCase();
    return Column(
      children: [
        if (_isImageFile(name))
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: _selectedInvoice!.bytes != null
                ? Image.memory(_selectedInvoice!.bytes!,
                    width: 100, height: 100, fit: BoxFit.cover)
                : (_selectedInvoice!.path != null
                    ? Image.file(File(_selectedInvoice!.path!),
                        width: 100, height: 100, fit: BoxFit.cover)
                    : const SizedBox(
                        width: 100,
                        height: 100,
                      )),
          )
        else
          Column(
            children: [
              Icon(_getFileIcon(ext), color: Colors.white, size: 50.0),
              const SizedBox(height: 8),
              Text(name,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
      ],
    );
  }

  Widget _buildInvoiceStatusBanner(Map<String, dynamic> offerData) {
    final statusLower =
        (offerData['offerStatus']?.toString() ?? '').toLowerCase().trim();
    final tInvoiceStatus =
        (offerData['transporterInvoiceStatus']?.toString() ?? '').toLowerCase();
    final hasTransporterInvoice =
        (offerData['transporterInvoice']?.toString() ?? '').isNotEmpty;

    // Show upload CTA when transporter invoice is needed/rejected/missing
    if (statusLower == OfferStatuses.transporterInvoicePending ||
        tInvoiceStatus == 'rejected' ||
        !hasTransporterInvoice) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: const Color(0xFF7E57C2).withOpacity(0.15),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: const Color(0xFF7E57C2), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invoice Required',
                style: customFont(16, FontWeight.w700, Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'CTP needs your transporter invoice. Upload it below so we can verify and generate the dealer invoice.',
                style: customFont(13, FontWeight.w500, Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    // Show info when admin invoice is pending
    if (statusLower == OfferStatuses.adminInvoicePending) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: const Color(0xFF26A69A).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: const Color(0xFF26A69A), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dealer Invoice In Progress',
                style: customFont(16, FontWeight.w700, Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'Thanks! Your invoice is verified. CTP is preparing the dealer invoice. You will be notified once it is ready.',
                style: customFont(13, FontWeight.w500, Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _saveInvoice() async {
    if (_selectedInvoice == null) return;
    final name = _selectedInvoice!.name;
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('invoices/${widget.vehicle.id}/$name');
    UploadTask uploadTask;
    if (_selectedInvoice!.bytes != null) {
      uploadTask = storageRef.putData(
        _selectedInvoice!.bytes!,
        SettableMetadata(contentType: _getMimeType(name)),
      );
    } else {
      uploadTask = storageRef.putFile(
        File(_selectedInvoice!.path!),
        SettableMetadata(contentType: _getMimeType(name)),
      );
    }
    final snapshot = await uploadTask;
    final url = await snapshot.ref.getDownloadURL();
    final uploadedAt = FieldValue.serverTimestamp();
    // Atomically update both vehicle and offer documents with invoice URL and metadata
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final vehicleRef = FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicle.id);
      final offerRef = FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offer.offerId);
      transaction.update(vehicleRef, {
        'transporterInvoice': url,
        'transporterInvoiceUploadedAt': uploadedAt,
      });
      transaction.update(offerRef, {
        'transporterInvoice': url,
        'transporterInvoiceUploadedAt': uploadedAt,
        'transporterInvoiceStatus': 'submitted',
      });
    });
    // Notify admins/sales reps
    try {
      final adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userRole', whereIn: ['admin', 'sales representative']).get();
      for (var doc in adminSnapshot.docs) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': doc.id,
          'offerId': widget.offer.offerId,
          'type': 'transporterInvoiceSubmitted',
          'createdAt': FieldValue.serverTimestamp(),
          'message':
              'Transporter uploaded an invoice for offer ${widget.offer.offerId}.',
        });
      }
    } catch (_) {}
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invoice saved successfully')),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: customFont(16, FontWeight.w500, Colors.grey)),
          Text(
            value.toUpperCase(),
            style: customFont(16, FontWeight.bold, Colors.white),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAccept() async {
    try {
      final offerProvider = Provider.of<OfferProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await offerProvider.acceptOffer(
        widget.offer.offerId,
        widget.vehicle.id,
        userProvider: userProvider,
      );

      if (!mounted) return;
      setState(() {
        _hasResponded = true;
        _responseMessage = 'You have accepted the offer';
      });
    } catch (e) {
      debugPrint('Error handling offer acceptance: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept offer: $e')),
      );
    }
  }

  Future<void> _handleReject(BuildContext context, String reason) async {
    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offer.offerId)
          .update({
        'offerStatus': 'rejected',
        'rejectionReason': reason,
      });

      if (mounted) {
        setState(() {
          _hasResponded = true;
          _responseMessage = 'You have rejected the offer';
        });
      }
    } catch (e, stackTrace) {
      print('Exception in _handleReject: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to reject the offer. Please try again.\nError: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Prompt the user to enter a rejection reason before rejecting
  Future<void> _promptRejectReason() async {
    _rejectReasonController.clear();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reason for Rejection'),
          content: TextField(
            controller: _rejectReasonController,
            decoration: const InputDecoration(
              hintText: 'Enter reason for rejecting this offer',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = _rejectReasonController.text.trim();
                if (text.isNotEmpty) {
                  Navigator.pop(ctx, text);
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
    if (reason != null && reason.isNotEmpty) {
      await _handleReject(context, reason);
    }
  }

  Future<void> _setupInspection() async {
    await MyNavigator.push(
      context,
      SetupInspectionPage(
        offerId: widget.offer.offerId, // Change from widget.vehicle.id
      ),
    );
  }

  Future<void> _setupCollection() async {
    await MyNavigator.push(
      context,
      SetupCollectionPage(
        offerId: widget.offer.offerId, // Change from widget.vehicle.id
      ),
    );
  }

  // Removed unused _parseLocations helper

  String _safeCapitalize(String? text) {
    if (text == null || text.isEmpty) return 'N/A';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var blue = const Color(0xFF2F7FFF);
    // Ensure userRole is available in build method
    // For demonstration, you may want to fetch or pass this in properly
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = userProvider.userRole;
    final role = userRole.toLowerCase();
    final isOemManager = userProvider.isOemManager;
    final acceptEnabled = role != 'oem' || isOemManager;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Text(
                "${widget.vehicle.brands.join("")} ${widget.vehicle.makeModel.toString().toUpperCase()}",
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: blue,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.verified, color: Color(0xFFFF4E00), size: 24),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFFFF4E00), size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.black,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('offers')
            .doc(widget.offer.offerId)
            .snapshots(),
        builder: (context, offerSnapshot) {
          if (offerSnapshot.hasError) {
            return Center(
              child: Text(
                'Error fetching offer data',
                style: customFont(18, FontWeight.bold, Colors.red),
              ),
            );
          }

          if (offerSnapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
              ),
            );
          }

          if (!offerSnapshot.hasData || !offerSnapshot.data!.exists) {
            return Center(
              child: Text(
                'Offer not found',
                style: customFont(18, FontWeight.bold, Colors.red),
              ),
            );
          }

          // Get the latest offer data
          Map<String, dynamic> offerData =
              offerSnapshot.data!.data() as Map<String, dynamic>;

          // Capture existing transporter invoice URL if present
          _existingInvoiceUrl = offerData['transporterInvoice'] as String?;
          // print('DEBUG: existingInvoiceUrl = $_existingInvoiceUrl');

          // Current offer status
          final String offerStatus =
              (offerData['offerStatus'] ?? '').toString().toLowerCase();

          // Get inspection and collection details from the offer document
          bool hasInspectionDetails = offerData['inspectionDetails'] != null;
          bool hasCollectionDetails = offerData['collectionDetails'] != null;

          // Use the latest offerStatus
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vehicle Image Section
                Stack(
                  children: [
                    SizedBox(
                      height: screenSize.height * 0.3,
                      width: double.infinity,
                      child: allPhotos.isEmpty
                          ? Image.asset(
                              'assets/default_vehicle_image.png',
                              fit: BoxFit.cover,
                            )
                          : PageView.builder(
                              controller: _pageController,
                              itemCount: allPhotos.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return allPhotos[index].startsWith('assets/')
                                    ? Image.asset(
                                        allPhotos[index],
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        allPhotos[index],
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Image.asset(
                                            'assets/default_vehicle_image.png',
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      );
                              },
                            ),
                    ),
                    // Page indicator dots
                    if (allPhotos.length > 1)
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            allPhotos.length,
                            (i) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == _currentImageIndex
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Show inspection/collection setup/status only if NOT dealer and offer is not in-progress or rejected
                if ((role == 'transporter' ||
                        role == 'oem' ||
                        role == 'admin' ||
                        role == 'sales representative') &&
                    offerStatus != 'in-progress' &&
                    offerStatus != 'rejected')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        if (!hasInspectionDetails)
                          CustomButton(
                            text: 'Setup Inspection',
                            borderColor: Colors.blue,
                            onPressed: _setupInspection,
                          ),
                        if (hasInspectionDetails)
                          Center(
                            child: Text(
                              'Inspection has been set up',
                              style:
                                  customFont(18, FontWeight.bold, Colors.green),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Show Setup Collection only when allowed:
                        // - Always allowed for admin/sales rep
                        // - For transporter, only after payment is marked as 'paid'
                        if (!hasCollectionDetails &&
                            ((role != 'transporter' && role != 'oem') ||
                                offerStatus == 'paid'))
                          CustomButton(
                            text: 'Setup Collection',
                            borderColor: Colors.blue,
                            onPressed: _setupCollection,
                          )
                        else if (hasCollectionDetails)
                          Center(
                            child: Text(
                              'Collection has been set up',
                              style:
                                  customFont(18, FontWeight.bold, Colors.green),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),

                // Add View Vehicle button for both dealer and transporter
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: CustomButton(
                    text: 'View Vehicle',
                    borderColor: Colors.blue,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              VehicleDetailsPage(vehicle: widget.vehicle),
                        ),
                      );
                    },
                  ),
                ),

                // Admins and transporters see invoice section only when offerStatus is 'paymentOptions'
                if ((role == 'transporter' ||
                        role == 'oem' ||
                        role == 'admin') &&
                    offerStatus == 'payment options') ...[
                  // Invoice addressing instructions
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload Invoice',
                          style: customFont(16, FontWeight.bold, Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please address your invoice to:',
                          style:
                              customFont(14, FontWeight.w500, Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Commercial Trader Portal (PTY) LTD',
                          style:
                              customFont(14, FontWeight.normal, Colors.white),
                        ),
                        Text(
                          '54 Rooibos Road, Highbury, Randvaal, 1962',
                          style:
                              customFont(14, FontWeight.normal, Colors.white),
                        ),
                        Text(
                          'VAT Number: 4780304798',
                          style:
                              customFont(14, FontWeight.normal, Colors.white),
                        ),
                        Text(
                          'Registration Number: 2023/642131/07',
                          style:
                              customFont(14, FontWeight.normal, Colors.white),
                        ),
                      ],
                    ),
                  ),
                  // Offer Summary button (placed directly above the upload invoice block)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: CustomButton(
                      text: 'OFFER SUMMARY',
                      borderColor: Colors.blue,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OfferSummaryPage(
                              offerId: widget.offer.offerId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Status banner for invoicing
                  if (offerSnapshot.hasData &&
                      offerSnapshot.data?.data() != null)
                    _buildInvoiceStatusBanner(
                        offerSnapshot.data!.data() as Map<String, dynamic>),

                  // Transporter invoice upload section
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: InkWell(
                      onTap: () async {
                        print(
                            'DEBUG: onTap triggered: _selectedInvoice=$_selectedInvoice, _existingInvoiceUrl=$_existingInvoiceUrl');
                        if (_selectedInvoice != null) {
                          _showInvoiceOptions();
                        } else if (_existingInvoiceUrl != null) {
                          print(
                              'DEBUG: navigating to ViewerPage with $_existingInvoiceUrl');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ViewerPage(url: _existingInvoiceUrl!),
                            ),
                          );
                        } else {
                          _pickInvoiceFile();
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
                              color: const Color(0xFF0E4CAF), width: 2.0),
                        ),
                        child: Builder(
                          builder: (_) {
                            final hasSelected = _selectedInvoice != null;
                            final hasExisting = _existingInvoiceUrl != null;
                            print(
                                'DEBUG: invoice child - selected=$hasSelected, existing=$hasExisting');
                            if (hasSelected) {
                              return _buildInvoiceDisplay();
                            }
                            if (hasExisting) {
                              // Decode filename from URL
                              final existingName = Uri.decodeComponent(
                                  Uri.parse(_existingInvoiceUrl!)
                                      .pathSegments
                                      .last);
                              return Column(
                                children: [
                                  Icon(
                                    _getFileIcon(existingName.split('.').last),
                                    color: Colors.white,
                                    size: 50.0,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    existingName,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              );
                            }
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getFileIcon('pdf'),
                                    color: Colors.white, size: 50.0),
                                const SizedBox(height: 10),
                                Text(
                                  'Select Invoice',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (_selectedInvoice != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: CustomButton(
                        text: 'SAVE INVOICE',
                        borderColor: const Color(0xFFFF4E00),
                        onPressed: _saveInvoice,
                      ),
                    ),
                  ],
                ],

                // Offer Details Section (role-based)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Offer Details',
                        style: customFont(20, FontWeight.bold, Colors.white),
                      ),
                      const SizedBox(height: 10),
                      // Financial breakdown (role-based)
                      Builder(builder: (context) {
                        // Retrieve the offer data
                        final dataMap =
                            offerSnapshot.data!.data() as Map<String, dynamic>;

                        // Get the typed offer amount (base amount user entered)
                        final typedOfferAmount =
                            (dataMap['typedOfferAmount'] as num?)?.toDouble() ??
                                0.0;

                        const double commission = 12500.0;

                        // Use "CTP Fee" wording in the UI instead of "commission".
                        // The internal variable name remains `commission` to avoid
                        // changing calculation logic.

                        if (role == 'dealer') {
                          // Dealer view: VAT applied on (base + commission); dealer pays total
                          final subtotal = typedOfferAmount + commission;
                          final vatAmountLocal = subtotal * 0.15;
                          final totalToPay = subtotal + vatAmountLocal;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _breakdownTable([
                                MapEntry('Offer (Excl. VAT & CTP Fee)',
                                    _formatRand(typedOfferAmount)),
                                MapEntry('CTP Fee', _formatRand(commission)),
                                MapEntry('Subtotal (Excl. VAT)',
                                    _formatRand(subtotal)),
                                MapEntry(
                                    'VAT (15%)', _formatRand(vatAmountLocal)),
                                MapEntry('Total To Pay (Incl. VAT)',
                                    _formatRand(totalToPay)),
                              ]),
                              const SizedBox(height: 8),
                              Text(
                                'As a dealer, you need to pay the total amount above.',
                                style: customFont(
                                    14, FontWeight.w500, Colors.white70),
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        } else {
                          // Transporter/admin/sales rep view: payout after CTP Fee, VAT on the remainder
                          final amountAfterCommission =
                              typedOfferAmount - commission;
                          final vat = amountAfterCommission * 0.15;
                          final transporterPayout = amountAfterCommission + vat;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _breakdownTable([
                                MapEntry('Typed Offer Amount (Excl. VAT)',
                                    _formatRand(typedOfferAmount)),
                                MapEntry('CTP Fee', _formatRand(commission)),
                                MapEntry('Amount After CTP Fee (Excl. VAT)',
                                    _formatRand(amountAfterCommission)),
                                MapEntry('VAT (15%)', _formatRand(vat)),
                                MapEntry('Your Payout (Incl. VAT)',
                                    _formatRand(transporterPayout)),
                              ]),
                              const SizedBox(height: 20),
                              // Transporter payout receipt confirmation UI
                              if (role == 'transporter')
                                _buildPayoutReceiptConfirmation(offerData),
                            ],
                          );
                        }
                      }),
                      // Vehicle Details Section
                      Text(
                        'Vehicle Details',
                        style: customFont(20, FontWeight.bold, Colors.white),
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                          'Brand',
                          widget.vehicle.brands.isNotEmpty
                              ? widget.vehicle.brands.join(', ').toUpperCase()
                              : 'N/A'),
                      _buildInfoRow('Year', widget.vehicle.year.toString()),
                      _buildInfoRow(
                          'Variant',
                          widget.vehicle.variant?.isNotEmpty == true
                              ? _safeCapitalize(widget.vehicle.variant!)
                              : 'N/A'),
                      _buildInfoRow(
                          'Reference Number',
                          widget.vehicle.referenceNumber.isNotEmpty
                              ? widget.vehicle.referenceNumber.toUpperCase()
                              : 'N/A'),
                    ],
                  ),
                ),

                // Accept and Reject Buttons (not shown to dealers)
                if ((role == 'transporter' ||
                        role == 'oem' ||
                        role == 'admin' ||
                        role == 'sales representative') &&
                    offerStatus == 'in-progress' &&
                    !_hasResponded)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Accept',
                            borderColor: Colors.blue,
                            onPressed: acceptEnabled ? _handleAccept : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            text: 'Reject',
                            borderColor: const Color(0xFFFF4E00),
                            onPressed: _promptRejectReason,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 16.0),
                    child: Center(
                      child: Text(
                        _responseMessage,
                        style: customFont(18, FontWeight.bold, Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper to allow extension methods to request a UI refresh.
  // Extensions cannot call `setState` directly, so expose a method here.
  void notifyStateChanged() {
    if (!mounted) return;
    setState(() {});
  }
}

/// Helper widget and actions for transporter payout receipt confirmation
extension _PayoutReceiptHelpers on _TransporterOfferDetailsPageState {
  Widget _buildPayoutReceiptConfirmation(Map<String, dynamic> offerData) {
    final String offerStatus =
        (offerData['offerStatus'] ?? '').toString().toLowerCase();
    final String payoutStatus =
        (offerData['transporterPayoutStatus'] ?? '').toString().toLowerCase();
    final String receiptStatus =
        (offerData['transporterPayoutReceiptStatus'] ?? '')
            .toString()
            .toLowerCase();

    // Determine if today is the collection day (if date provided)
    bool isCollectionDay = false;
    final dynamic colDateRaw = offerData['dealerSelectedCollectionDate'];
    if (colDateRaw != null) {
      DateTime? colDate;
      if (colDateRaw is Timestamp) {
        colDate = colDateRaw.toDate();
      } else if (colDateRaw is String) {
        colDate = DateTime.tryParse(colDateRaw);
      }
      if (colDate != null) {
        final now = DateTime.now();
        final d1 = DateTime(colDate.year, colDate.month, colDate.day);
        final d2 = DateTime(now.year, now.month, now.day);
        isCollectionDay = d1 == d2;
      }
    }

    // If transporter already confirmed payment received, show confirmation note
    if (receiptStatus == 'received') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Center(
          child: Text(
            'You have confirmed payout received.',
            style: customFont(14, FontWeight.w600, Colors.green),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // If transporter reported not received, show admin contact details panel
    if (receiptStatus == 'not_received') {
      return _buildAdminContactDetailsPanel();
    }

    // Otherwise show prompt only when it’s the right time (paid/collected/collection day)
    final bool eligibleToPrompt = (offerStatus == 'paid' ||
        offerStatus == 'collected' ||
        isCollectionDay);
    if (!eligibleToPrompt) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              payoutStatus == 'paid'
                  ? 'Please confirm if you have received your payout.'
                  : 'On collection day, confirm if you have received your payout.',
              style: customFont(14, FontWeight.w600, Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          CustomButton(
            text: 'Confirm Payout Received',
            borderColor: Colors.green,
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('offers')
                    .doc(widget.offer.offerId)
                    .update({
                  'transporterPayoutReceiptStatus': 'received',
                  'transporterPayoutReceiptConfirmedAt':
                      FieldValue.serverTimestamp(),
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Thanks. Marked as payout received.'),
                    backgroundColor: Colors.green));
                notifyStateChanged();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Failed to confirm payout: $e'),
                    backgroundColor: Colors.red));
              }
            },
          ),
          const SizedBox(height: 8),
          CustomButton(
            text: "I Haven't Received Payment",
            borderColor: Colors.red,
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('offers')
                    .doc(widget.offer.offerId)
                    .update({
                  'transporterPayoutReceiptStatus': 'not_received',
                  'transporterPayoutReceiptRejectedAt':
                      FieldValue.serverTimestamp(),
                });
                // Notify admins to investigate
                final admins = await FirebaseFirestore.instance
                    .collection('users')
                    .where('userRole',
                        whereIn: ['admin', 'sales representative']).get();
                for (final a in admins.docs) {
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .add({
                    'userId': a.id,
                    'offerId': widget.offer.offerId,
                    'type': 'payoutNotReceived',
                    'createdAt': FieldValue.serverTimestamp(),
                    'message':
                        'Transporter reports payout not received for offer ${widget.offer.offerId}.',
                  });
                }
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Reported: payout not received.'),
                    backgroundColor: Colors.orange));
                notifyStateChanged();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Failed to report: $e'),
                    backgroundColor: Colors.red));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdminContactDetailsPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              'Our team has been notified. You can also contact:',
              style: customFont(14, FontWeight.w600, Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance.collection('users').where(
                'userRole',
                whereIn: ['admin', 'sales representative']).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(color: Colors.blue),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No admin contacts found. Please try again later.',
                    style: customFont(13, FontWeight.w500, Colors.white70),
                  ),
                );
              }
              final docs = snapshot.data!.docs;
              return Column(
                children: docs.map((d) {
                  final data = d.data();
                  final first = (data['firstName'] ?? '').toString();
                  final last = (data['lastName'] ?? '').toString();
                  final company = (data['companyName'] ?? '').toString();
                  final displayName = ([first, last]
                          .where((s) => s.isNotEmpty)
                          .join(' ')
                          .trim()
                          .isNotEmpty
                      ? [first, last]
                          .where((s) => s.isNotEmpty)
                          .join(' ')
                          .trim()
                      : (company.isNotEmpty ? company : 'Admin'));
                  final email = (data['email'] ?? '').toString();
                  final phone = (data['phoneNumber'] ?? '').toString();
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 6.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName,
                            style:
                                customFont(14, FontWeight.w700, Colors.white)),
                        const SizedBox(height: 4),
                        if (email.isNotEmpty)
                          Text('Email: $email',
                              style: customFont(
                                  13, FontWeight.w500, Colors.white70)),
                        if (phone.isNotEmpty)
                          Text('Phone: $phone',
                              style: customFont(
                                  13, FontWeight.w500, Colors.white70)),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

String _getMimeType(String name) {
  final ext = name.split('.').last.toLowerCase();
  switch (ext) {
    case 'pdf':
      return 'application/pdf';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'doc':
      return 'application/msword';
    case 'docx':
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    default:
      return 'application/octet-stream';
  }
}
