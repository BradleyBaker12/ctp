import 'package:flutter/material.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  bool _hasResponded = false; // Flag to track if user has responded
  String _responseMessage = ''; // Message to display after response

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Initialize photos
    allPhotos = [
      if (widget.vehicle.mainImageUrl != null) widget.vehicle.mainImageUrl!,
      ...widget.vehicle.photos.where((photo) => photo != null).cast<String>(),
    ];

    // Set _hasResponded based on the current offer status
    if (widget.offer.offerStatus != 'in-progress') {
      _hasResponded = true;
      _responseMessage = widget.offer.offerStatus == 'accepted'
          ? 'You have accepted the offer'
          : 'You have rejected the offer';
    }
  }

  TextStyle customFont(double size, FontWeight weight, Color color) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Image Section with PageView and Indicators
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
                            'assets/default_vehicle_image.png', // Fallback image
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: screenSize.height * 0.3,
                          );
                        },
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _buildImageIndicators(allPhotos.length),
                  ),
                ),
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(1),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Accept and Reject Buttons with Text or Message
            if (widget.offer.offerStatus == 'in-progress' && !_hasResponded)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStyledLongButton(
                      text: 'Accept',
                      backgroundColor: Colors.blue,
                      onTap: () => _handleAccept(context),
                    ),
                    const SizedBox(width: 16),
                    _buildStyledLongButton(
                      text: 'Reject',
                      backgroundColor: const Color(0xFFFF4E00),
                      onTap: () => _handleReject(context),
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
                    style: customFont(18, FontWeight.bold, Colors.white),
                  ),
                ),
              ),

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
                  _buildInfoRow(
                      'Offer Amount', widget.offer.offerAmount.toString()),
                  const SizedBox(height: 20),

                  // Vehicle Details Section
                  Text(
                    'Vehicle Details',
                    style: customFont(20, FontWeight.bold, Colors.white),
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                      'Make/Model', widget.vehicle.makeModel),
                  _buildInfoRow('Year', widget.vehicle.year),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: customFont(16, FontWeight.w500, Colors.grey),
          ),
          Text(
            value.toUpperCase(),
            style: customFont(16, FontWeight.bold, Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildImageIndicators(int numImages) {
    var screenSize = MediaQuery.of(context).size;
    double indicatorWidth = screenSize.width * 0.1;
    double totalWidth = numImages * indicatorWidth + (numImages - 1) * 8;
    if (totalWidth > screenSize.width) {
      indicatorWidth = (screenSize.width - (numImages - 1) * 8) / numImages;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(numImages, (index) {
        return Container(
          width: indicatorWidth,
          height: screenSize.height * 0.004,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color:
                index == _currentImageIndex ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.white, width: 1),
          ),
        );
      }),
    );
  }

  Widget _buildStyledLongButton({
    required String text,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180, // Increased width for longer buttons
        height: 60,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10), // Rounded but rectangular
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: customFont(18, FontWeight.bold, Colors.black),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAccept(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offer.offerId)
          .update({'offerStatus': 'accepted'});
      setState(() {
        _hasResponded = true;
        _responseMessage = 'You have accepted the offer';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to accept the offer. Please try again.'),
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
      setState(() {
        _hasResponded = true;
        _responseMessage = 'You have rejected the offer';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to reject the offer. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
