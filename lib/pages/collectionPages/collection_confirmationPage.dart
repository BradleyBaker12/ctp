import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/pages/payment_options_page.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';

class CollectionConfirmationPage extends StatefulWidget {
  final String location;
  final String address;
  final DateTime date;
  final String time;
  final String offerId; // Add offerId parameter

  const CollectionConfirmationPage({
    super.key,
    required this.location,
    required this.address,
    required this.date,
    required this.time,
    required this.offerId, // Add offerId parameter
  });

  @override
  _CollectionConfirmationPageState createState() =>
      _CollectionConfirmationPageState();
}

class _CollectionConfirmationPageState
    extends State<CollectionConfirmationPage> {
  bool _isLoading = false;
  LatLng? _latLng;

  @override
  void initState() {
    super.initState();
    _getCoordinatesFromAddress();
  }

  Future<void> _getCoordinatesFromAddress() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Location> locations = await locationFromAddress(widget.address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        setState(() {
          _latLng = LatLng(location.latitude, location.longitude);
        });
      } else {
        throw 'No locations found for the provided address';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get coordinates: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openInGoogleMaps() async {
    if (_latLng != null) {
      final googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=${_latLng!.latitude},${_latLng!.longitude}';
      if (await canLaunch(googleMapsUrl)) {
        await launch(googleMapsUrl);
      } else {
        throw 'Could not open Google Maps';
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('LatLng is not available')),
      );
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
                    if (_latLng != null)
                      Container(
                        height: 300,
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _latLng!,
                              zoom: 14.0,
                            ),
                            markers: {
                              Marker(
                                markerId: MarkerId(widget.location),
                                position: _latLng!,
                              ),
                            },
                          ),
                        ),
                      )
                    else if (_isLoading)
                      Center(child: CircularProgressIndicator())
                    else
                      Text(
                        'No location available',
                        style: TextStyle(color: Colors.red),
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PaymentOptionsPage(
                              offerId: widget.offerId,
                            ),
                          ),
                        );
                      },
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
