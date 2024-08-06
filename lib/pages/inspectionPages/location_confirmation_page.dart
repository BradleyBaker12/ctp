import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/pages/inspectionPages/confirmation_page.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationConfirmationPage extends StatefulWidget {
  final String offerId;
  final String location;
  final String address;
  final DateTime date;
  final String time;
  final LatLng latLng;

  const LocationConfirmationPage({
    super.key,
    required this.offerId,
    required this.location,
    required this.address,
    required this.date,
    required this.time,
    required this.latLng,
  });

  @override
  _LocationConfirmationPageState createState() =>
      _LocationConfirmationPageState();
}

class _LocationConfirmationPageState extends State<LocationConfirmationPage> {
  bool _isLoading = false;

  Future<void> _saveInspectionDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final DocumentReference offerRef =
          FirebaseFirestore.instance.collection('offers').doc(widget.offerId);

      await offerRef.set({
        'dealerSelectedInspectionDate': widget.date,
        'dealerSelectedInspectionTime': widget.time,
        'dealerSelectedInspectionLocation': widget.address,
      }, SetOptions(merge: true));

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ConfirmationPage(
            location: widget.location,
            address: widget.address,
            date: widget.date,
            time: widget.time,
            latLng: widget.latLng,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save inspection details: $e')),
      );
    }
  }

  void _openInGoogleMaps() async {
    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=${widget.latLng.latitude},${widget.latLng.longitude}';
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not open Google Maps';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: CustomBackButton(
                          onPressed: () => Navigator.of(context).pop()),
                    ),
                    const SizedBox(height: 16),
                    Image.asset('lib/assets/CTPLogo.png'),
                    const SizedBox(height: 16),
                    const Text(
                      'LOCATION CONFIRMATION',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Meeting information:',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.address,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.date.day} ${_getMonthName(widget.date.month)} ${widget.date.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.time,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 300,
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: widget.latLng,
                            zoom: 14.0,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId(widget.location),
                              position: widget.latLng,
                            ),
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'COPY ADDRESS',
                      borderColor: Colors.blue,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.address));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Address copied to clipboard')),
                        );
                      },
                    ),
                    CustomButton(
                      text: 'OPEN IN GOOGLE MAPS',
                      borderColor: Colors.blue,
                      onPressed: _openInGoogleMaps,
                    ),
                    CustomButton(
                      text: 'DONE',
                      borderColor: Colors.orange,
                      onPressed: _saveInspectionDetails,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
