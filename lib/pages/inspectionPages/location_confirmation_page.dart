import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/pages/inspectionPages/confirmation_page.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';

class LocationConfirmationPage extends StatefulWidget {
  final String offerId;
  final String location;
  final String address;
  final DateTime date;
  final String time;
  final String makeModel;
  final String offerAmount;
  final String vehicleId; // Add this line

  const LocationConfirmationPage({
    super.key,
    required this.offerId,
    required this.location,
    required this.address,
    required this.date,
    required this.time,
    required this.makeModel,
    required this.offerAmount,
    required this.vehicleId, // Add this line
  });

  @override
  _LocationConfirmationPageState createState() =>
      _LocationConfirmationPageState();
}

class _LocationConfirmationPageState extends State<LocationConfirmationPage> {
  bool _isLoading = false;
  LatLng? _latLng;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _updateOfferStatus();
    _getCoordinatesFromAddress();
  }

  Future<void> _updateOfferStatus() async {
    try {
      // Update the offer status to "confirm location" when the page loads
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({'offerStatus': 'confirm location'});

      print('Offer status updated to "confirm location"');
    } catch (e) {
      print('Failed to update offer status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update offer status: $e')),
      );
    }
  }

  Future<void> _getCoordinatesFromAddress() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Getting coordinates for address: ${widget.address}');
      List<Location> locations = await locationFromAddress(widget.address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        setState(() {
          _latLng = LatLng(location.latitude, location.longitude);
          print('Coordinates found: $_latLng');
        });
      } else {
        throw 'No locations found for the provided address';
      }
    } catch (e) {
      print('Error getting coordinates: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get coordinates: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveInspectionDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final DocumentReference offerRef =
          FirebaseFirestore.instance.collection('offers').doc(widget.offerId);

      // Add null safety checks
      await offerRef.set({
        'dealerSelectedInspectionDate': widget.date ?? DateTime.now(),
        'dealerSelectedInspectionTime': widget.time ?? "12:00 PM",
        'dealerSelectedInspectionLocation':
            widget.address ?? "Unknown Location",
        'latLng': _latLng != null
            ? GeoPoint(_latLng!.latitude, _latLng!.longitude)
            : null,
      }, SetOptions(merge: true));

      if (_latLng != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ConfirmationPage(
              offerId: widget.offerId,
              location: widget.location,
              address: widget.address,
              date: widget.date,
              time: widget.time,
              latLng: _latLng!,
              makeModel: widget.makeModel,
              offerAmount: widget.offerAmount,
              vehicleId: widget.vehicleId, // Add this line
            ),
          ),
        );
      } else {
        print('LatLng is null, cannot proceed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location coordinates not available')),
        );
      }
    } catch (e) {
      print('Error saving inspection details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save inspection details: $e')),
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
        print('Could not open Google Maps');
        throw 'Could not open Google Maps';
      }
    } else {
      print('Location can not be found with the provided address');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Location can not be found with the provided address')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    print(
        'Navigated to LocationConfirmationPage with offerId: ${widget.offerId}');
    print('Location: ${widget.location}, Address: ${widget.address}');
    print('Date: ${widget.date}, Time: ${widget.time}');

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
                    const SizedBox(height: 50),
                    SizedBox(
                        width: 100,
                        height: 100,
                        child: Image.asset('lib/assets/CTPLogo.png')),
                    const SizedBox(height: 32),
                    const Text(
                      'LOCATION CONFIRMATION',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Meeting information:',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      widget.address,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      '${widget.date.day} ${_getMonthName(widget.date.month)} ${widget.date.year}',
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.time,
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
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
                      const Center(child: CircularProgressIndicator())
                    else
                      const Text(
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
                      borderColor: const Color(0xFFFF4E00),
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
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
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
