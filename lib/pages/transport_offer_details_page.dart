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
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
// Web blob support (use universal_html for cross-platform compatibility)
import 'package:universal_html/html.dart' as html;
import 'package:firebase_storage/firebase_storage.dart';

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

  Future<void> _openInvoiceUrl(String url) async {
    print('DEBUG: _openInvoiceUrl called with url=$url');
    if (kIsWeb) {
      html.window.open(url, '_blank');
    } else {
      final uri = Uri.parse(url);
      // Try launching directly
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
      // Fallback: download and open as local file
      try {
        final httpClient = HttpClient();
        final request = await httpClient.getUrl(uri);
        final response = await request.close();
        final bytes = await consolidateHttpClientResponseBytes(response);
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/${uri.pathSegments.last}';
        final file = File(filePath);
        // Ensure directory exists
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes);
        print('DEBUG: downloaded invoice to ${file.path}');
        final fileUri = Uri.file(file.path);
        if (await canLaunchUrl(fileUri)) {
          await launchUrl(fileUri, mode: LaunchMode.externalApplication);
        } else {
          print('DEBUG: cannot launch file URI: $fileUri');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot open downloaded invoice')),
          );
        }
      } catch (e) {
        print('DEBUG: error downloading/opening invoice: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening invoice: $e')),
        );
      }
    }
  }

  void _viewInvoice() async {
    print('DEBUG: _viewInvoice called with _selectedInvoice=$_selectedInvoice');
    if (_selectedInvoice == null) return;
    final name = _selectedInvoice!.name;
    if (kIsWeb) {
      final bytes = _selectedInvoice!.bytes;
      if (bytes != null) {
        final blob = html.Blob([bytes], _getMimeType(name));
        final url = html.Url.createObjectUrlFromBlob(blob);
        print('DEBUG: opening URL: $url');
        html.window.open(url, '_blank');
      }
    } else {
      final path = _selectedInvoice!.path;
      if (path != null && await canLaunchUrl(Uri.file(path))) {
        await launchUrl(Uri.file(path), mode: LaunchMode.externalApplication);
      }
    }
  }

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
    // Atomically update both vehicle and offer documents with invoice URL
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final vehicleRef = FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicle.id);
      final offerRef = FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offer.offerId);
      transaction.update(vehicleRef, {'transporterInvoice': url});
      transaction.update(offerRef, {'transporterInvoice': url});
    });
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

      // Use transaction to ensure atomic updates
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Get all offers for this vehicle
        final offersQuery = await FirebaseFirestore.instance
            .collection('offers')
            .where('vehicleId', isEqualTo: widget.vehicle.id)
            .get();

        // Update the accepted offer
        transaction.update(
            FirebaseFirestore.instance
                .collection('offers')
                .doc(widget.offer.offerId),
            {'offerStatus': 'accepted'});

        // Update vehicle status
        transaction.update(
            FirebaseFirestore.instance
                .collection('vehicles')
                .doc(widget.vehicle.id),
            {
              'isAccepted': true,
              'acceptedOfferId': widget.offer.offerId,
            });

        // Update all other offers for this vehicle to rejected
        for (var doc in offersQuery.docs) {
          if (doc.id != widget.offer.offerId) {
            transaction.update(
                FirebaseFirestore.instance.collection('offers').doc(doc.id),
                {'offerStatus': 'rejected'});
          }
        }
      });

      setState(() {
        _hasResponded = true;
        _responseMessage = 'You have accepted the offer';
      });
    } catch (e) {
      print('Error handling offer acceptance: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to accept offer: $e')));
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

  // Helper method to parse List<dynamic> to List<Map<String, dynamic>> safely
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
      print('Error parsing locations: $e');
      return [];
    }
  }

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
          print('DEBUG: existingInvoiceUrl = $_existingInvoiceUrl');

          String offerStatus = offerData['offerStatus'] ?? 'in-progress';
          // Normalize offerStatus for comparison

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
                  ],
                ),

                // Show inspection/collection setup/status only if NOT dealer and offer is not in-progress or rejected
                if ((userRole == 'transporter' ||
                        userRole == 'admin' ||
                        userRole == 'sales representative') &&
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
                        if (!hasCollectionDetails)
                          CustomButton(
                            text: 'Setup Collection',
                            borderColor: Colors.blue,
                            onPressed: _setupCollection,
                          )
                        else
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
                if ((userRole == 'transporter' || userRole == 'admin') &&
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

                // Offer Details Section
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
                      // Financial breakdown
                      Builder(builder: (context) {
                        // Retrieve the offer data
                        final dataMap =
                            offerSnapshot.data!.data() as Map<String, dynamic>;

                        // Get the typed offer amount (base amount user entered)
                        final typedOfferAmount =
                            (dataMap['typedOfferAmount'] as num?)?.toDouble() ??
                                0.0;

                        // Fixed commission amount
                        const double commission = 12500.0;

                        // Calculate amount after commission is deducted
                        final amountAfterCommission =
                            typedOfferAmount - commission;

                        // Calculate VAT (15% of amount after commission)
                        final vat = amountAfterCommission * 0.15;

                        // Calculate transporter payout (amount after commission + VAT)
                        final transporterPayout = amountAfterCommission + vat;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              'Typed Offer Amount',
                              'R ${typedOfferAmount.toStringAsFixed(2)}',
                            ),
                            _buildInfoRow(
                              'Commission',
                              'R ${commission.toStringAsFixed(2)}',
                            ),
                            _buildInfoRow(
                              'Amount After Commission',
                              'R ${amountAfterCommission.toStringAsFixed(2)}',
                            ),
                            _buildInfoRow(
                              'VAT (15%)',
                              'R ${vat.toStringAsFixed(2)}',
                            ),
                            _buildInfoRow(
                              'Your Payout',
                              'R ${transporterPayout.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 20),
                          ],
                        );
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

                // Accept and Reject Buttons
                if (offerStatus == 'in-progress' && !_hasResponded)
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
                            onPressed: _handleAccept,
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
