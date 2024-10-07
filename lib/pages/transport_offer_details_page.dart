// transporter_offer_details_page.dart

import 'package:flutter/material.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/pages/setup_inspection.dart';
import 'package:ctp/pages/setup_collection.dart';
import 'package:ctp/components/custom_button.dart'; // Import CustomButton

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
  int _currentImageIndex = 0;
  late List<String> allPhotos;
  late PageController _pageController;
  bool _hasResponded = false;
  String _responseMessage = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Initialize photos
    allPhotos = [
      if (widget.vehicle.mainImageUrl != null) widget.vehicle.mainImageUrl!,
      ...widget.vehicle.photos.where((photo) => photo != null).cast<String>(),
    ];

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
    super.dispose();
  }

  TextStyle customFont(double size, FontWeight weight, Color color) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: weight,
      color: color,
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

  Future<void> _handleAccept(BuildContext context) async {
    try {
      // Update the offer status to 'accepted'
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offer.offerId)
          .update({'offerStatus': 'accepted'});

      if (mounted) {
        setState(() {
          _hasResponded = true;
          _responseMessage = 'You have accepted the offer';
        });

        // Navigate to SetupInspectionPage
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SetupInspectionPage(
              vehicleId: widget.vehicle.id,
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Exception in _handleAccept: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to accept the offer. Please try again.\nError: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleReject(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offer.offerId)
          .update({'offerStatus': 'rejected'});

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

  Future<void> _setupInspection() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetupInspectionPage(
          vehicleId: widget.vehicle.id,
        ),
      ),
    );
  }

  Future<void> _setupCollection() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetupCollectionPage(vehicleId: widget.vehicle.id),
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

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var blue = const Color(0xFF2F7FFF);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  widget.vehicle.makeModel.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: blue,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.verified, color: Color(0xFFFF4E00), size: 24),
              ],
            ),
            const Icon(Icons.arrow_drop_down,
                color: Color(0xFFFF4E00), size: 40),
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

          // Get the latest offer status
          Map<String, dynamic> offerData =
              offerSnapshot.data!.data() as Map<String, dynamic>;
          String offerStatus = offerData['offerStatus'] ?? 'in-progress';

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('vehicles')
                .doc(widget.vehicle.id)
                .snapshots(),
            builder: (context, vehicleSnapshot) {
              if (vehicleSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Error fetching vehicle data',
                    style: customFont(18, FontWeight.bold, Colors.red),
                  ),
                );
              }

              if (vehicleSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                  ),
                );
              }

              if (!vehicleSnapshot.hasData || !vehicleSnapshot.data!.exists) {
                return Center(
                  child: Text(
                    'Vehicle not found',
                    style: customFont(18, FontWeight.bold, Colors.red),
                  ),
                );
              }

              Map<String, dynamic> vehicleData =
                  vehicleSnapshot.data!.data() as Map<String, dynamic>;

              // Adjusted data parsing to match Firestore structure
              List<Map<String, dynamic>> inspectionLocations = _parseLocations(
                  vehicleData['inspectionDetails']?['inspectionLocations']
                      ?['locations'] as List<dynamic>?);

              List<Map<String, dynamic>> collectionLocations = _parseLocations(
                  vehicleData['collectionDetails']?['collectionLocations']
                      ?['locations'] as List<dynamic>?);

              // Compute local variables based on parsed data
              bool isInspectionComplete = inspectionLocations.isNotEmpty;
              bool isCollectionComplete = collectionLocations.isNotEmpty;

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
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: allPhotos.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return Image.network(
                                allPhotos[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset(
                                    'assets/default_vehicle_image.png',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: screenSize.height * 0.3,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    // Accept and Reject Buttons
                    if (offerStatus == 'in-progress' && !_hasResponded)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            CustomButton(
                              text: 'Accept',
                              borderColor: Colors.blue,
                              onPressed: () => _handleAccept(context),
                            ),
                            const SizedBox(width: 16),
                            CustomButton(
                              text: 'Reject',
                              borderColor: const Color(0xFFFF4E00),
                              onPressed: () => _handleReject(context),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(
                          child: Text(
                            _responseMessage,
                            style:
                                customFont(18, FontWeight.bold, Colors.white),
                          ),
                        ),
                      ),

                    // Setup Inspection and Collection Buttons
                    if (offerStatus == 'accepted') ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Column(
                          children: [
                            if (!isInspectionComplete)
                              CustomButton(
                                text: 'Setup Inspection',
                                borderColor: Colors.blue,
                                onPressed: _setupInspection,
                              )
                            else
                              Center(
                                child: Text(
                                  'Inspection Setup Complete',
                                  style: customFont(
                                      18, FontWeight.bold, Colors.green),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            const SizedBox(height: 16),
                            if (!isCollectionComplete)
                              CustomButton(
                                text: 'Setup Collection',
                                borderColor: Colors.blue,
                                onPressed: _setupCollection,
                              )
                            else
                              Center(
                                child: Text(
                                  'Collection Setup Complete',
                                  style: customFont(
                                      18, FontWeight.bold, Colors.green),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
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
                            style:
                                customFont(20, FontWeight.bold, Colors.white),
                          ),
                          const SizedBox(height: 10),
                          _buildInfoRow('Offer Amount',
                              'R ${widget.offer.offerAmount.toString()}'),
                          const SizedBox(height: 20),

                          // Vehicle Details Section
                          Text(
                            'Vehicle Details',
                            style:
                                customFont(20, FontWeight.bold, Colors.white),
                          ),
                          const SizedBox(height: 10),
                          _buildInfoRow('Make/Model', widget.vehicle.makeModel),
                          _buildInfoRow('Year', widget.vehicle.year),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
