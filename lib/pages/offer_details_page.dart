import 'package:flutter/material.dart';

class OfferDetailsPage extends StatefulWidget {
  final String offerId;
  final String vehicleName;
  final String offerAmount;
  final List<String> images; // List of image URLs
  final Map<String, String?> additionalInfo; // Map for additional information
  final String? year;
  final String? mileage;
  final String? transmission;
  final String offerStatus; // New field for offer status
  final Future<void> Function() onAccept; // Function to handle acceptance
  final Future<void> Function() onReject; // Function to handle rejection

  const OfferDetailsPage({
    Key? key,
    required this.offerId,
    required this.vehicleName,
    required this.offerAmount,
    required this.images,
    required this.additionalInfo,
    required this.onAccept, // Required function for accept
    required this.onReject, // Required function for reject
    required this.offerStatus, // Required offer status
    this.year,
    this.mileage,
    this.transmission,
  }) : super(key: key);

  @override
  _OfferDetailsPageState createState() => _OfferDetailsPageState();
}

class _OfferDetailsPageState extends State<OfferDetailsPage> {
  int _currentImageIndex = 0;
  String? _actionTaken;

  @override
  void initState() {
    super.initState();
    _actionTaken =
        widget.offerStatus; // Set initial action based on offer status
  }

  TextStyle _customFont(double fontSize, FontWeight fontWeight, Color color) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFamily: 'Montserrat',
    );
  }

  Widget _buildOfferDetail(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: _customFont(16, FontWeight.bold, Colors.white),
          ),
          Text(
            value,
            style: _customFont(18, FontWeight.bold, color),
          ),
        ],
      ),
    );
  }

  Widget _buildImageIndicators(
      BuildContext context, int numImages, int currentImageIndex) {
    double indicatorWidth = 50.0;
    double totalWidth = numImages * indicatorWidth + (numImages - 1) * 8;
    if (totalWidth > MediaQuery.of(context).size.width) {
      indicatorWidth =
          (MediaQuery.of(context).size.width - (numImages - 1) * 8) / numImages;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(numImages, (index) {
        return Container(
          width: indicatorWidth,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color:
                index == currentImageIndex ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.white, width: 1),
          ),
        );
      }),
    );
  }

  Widget _buildInfoContainer(String title, String? value) {
    return Flexible(
      child: Container(
        height: 90,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: _customFont(12, FontWeight.bold, Colors.grey)),
            const SizedBox(height: 4),
            Text(value ?? 'Unknown',
                style: _customFont(16, FontWeight.bold, Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    List<Widget> infoWidgets = [];

    widget.additionalInfo.forEach((title, value) {
      if (value != null && value.isNotEmpty && value != 'Unknown') {
        infoWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: _customFont(14, FontWeight.normal, Colors.white)),
                Text(value ?? 'Unknown',
                    style: _customFont(14, FontWeight.bold, Colors.white)),
              ],
            ),
          ),
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: infoWidgets,
    );
  }

  Future<void> _handleAccept() async {
    await widget.onAccept();
    setState(() {
      _actionTaken = 'accepted';
    });
  }

  Future<void> _handleReject() async {
    await widget.onReject();
    setState(() {
      _actionTaken = 'rejected';
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'OFFER DETAILS',
          style: _customFont(20, FontWeight.bold, Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: size.height * 0.3,
                      child: PageView.builder(
                        itemCount: widget.images.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Image.network(
                            widget.images[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: size.height * 0.3,
                          );
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildImageIndicators(
                            context, widget.images.length, _currentImageIndex),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.vehicleName.toUpperCase(),
                          style:
                              _customFont(24, FontWeight.bold, Colors.white)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInfoContainer('YEAR', widget.year),
                          const SizedBox(width: 8),
                          _buildInfoContainer('MILEAGE', widget.mileage),
                          const SizedBox(width: 8),
                          _buildInfoContainer(
                              'TRANSMISSION', widget.transmission),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildOfferDetail(
                          'OFFER AMOUNT', widget.offerAmount, Colors.blue),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          const Icon(Icons.play_arrow,
                              color: Color(0xFFFF4E00)),
                          Text('ADDITIONAL INFO',
                              style: _customFont(
                                  20, FontWeight.bold, Colors.blue)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildAdditionalInfo(),
                      const SizedBox(height: 30),
                      if (_actionTaken == null ||
                          _actionTaken == 'pending') ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _handleAccept,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF4E00),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text('ACCEPT OFFER',
                                    style: _customFont(
                                        18, FontWeight.bold, Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _handleReject,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text('REJECT OFFER',
                                    style: _customFont(
                                        18, FontWeight.bold, Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Center(
                          child: Text(
                            _actionTaken == 'accepted'
                                ? 'You have accepted the offer.'
                                : _actionTaken == 'rejected'
                                    ? 'You have rejected the offer.'
                                    : 'The offer is currently under review.',
                            style:
                                _customFont(18, FontWeight.bold, Colors.green),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
