import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_bottom_navigation.dart'; // Ensure this import is correct
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/pages/payment_options_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CollectionConfirmationPage extends StatefulWidget {
  final String location;
  final String address;
  final DateTime date;
  final String time;
  final String offerId;
  final String? vehicleId;
  final LatLng? latLng; // Add LatLng parameter

  const CollectionConfirmationPage({
    super.key,
    required this.location,
    required this.address,
    required this.date,
    required this.time,
    required this.offerId,
    this.vehicleId,
    this.latLng, // Add LatLng parameter
  });

  @override
  _CollectionConfirmationPageState createState() =>
      _CollectionConfirmationPageState();
}

class _CollectionConfirmationPageState
    extends State<CollectionConfirmationPage> {
  bool _isLoading = false;
  LatLng? _latLng;
  String _displayedAddress = '';
  String _headerText = 'COLLECTION CONFIRMATION';
  String _meetingInfoText = 'Meeting information:';
  String _doneButtonText = 'DONE';
  int _selectedIndex =
      0; // Variable to keep track of the selected bottom nav item

  @override
  void initState() {
    super.initState();
    _updateOfferStatus(); // Update offer status on page load
    _getCoordinates();
  }

  Future<void> _updateOfferStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final DocumentReference offerRef =
          FirebaseFirestore.instance.collection('offers').doc(widget.offerId);

      await offerRef.update({
        'offerStatus': 'Collection Location Confirmation',
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error has occurred')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> getAddress() async {
    if (widget.vehicleId == null) {
      return {};
    }
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(widget.vehicleId)
        .get();
    Map<String, dynamic> addressObj = {};
    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>?;
      if (data != null &&
          data.containsKey('inspectionDetails') &&
          data['inspectionDetails'] is Map &&
          data['inspectionDetails']['inspectionLocations'] is Map &&
          data['inspectionDetails']['inspectionLocations']['locations']
              is List) {
        List locations =
            data['inspectionDetails']['inspectionLocations']['locations'] ?? [];
        String address = locations[0]['address'] ?? '';

        if (locations.isNotEmpty) {
          double lat = locations[0]['lat']?.toDouble() ?? 0.0;
          double lng = locations[0]['lng']?.toDouble() ?? 0.0;
          addressObj['lat'] = lat;
          addressObj['lng'] = lng;
          addressObj['address'] = address;
          setState(() {
            // _latLng = LatLng(lat, lng);
          });
          print("Location Value: $_latLng");
          return addressObj;
        } else {
          return {};
        }
      } else {
        return {};
      }
    } else {
      return {};
    }
  }

  Future<void> _getCoordinates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .get();
      var addressObj = await getAddress();
      print("My address $addressObj");
      if (offerSnapshot.exists) {
        final data = offerSnapshot.data() as Map<String, dynamic>;
        final bool dealerSelectedDelivery =
            data['dealerSelectedDelivery'] ?? false;

        String addressToUse = widget.address;
        LatLng? latLngToUse = widget.latLng;

        if (dealerSelectedDelivery) {
          // Update text for delivery
          setState(() {
            _headerText = 'DELIVERY CONFIRMATION';
            _meetingInfoText = 'Delivery information:';
            _doneButtonText = 'CONFIRM DELIVERY';
          });

          addressToUse = data['transporterDeliveryAddress'] ??
              addressObj['address'] ??
              'Unknown';
          final deliveryLatLng = data['transporterDeliveryLatLng'] ??
              {"latitude": addressObj['lat'], "longitude": addressObj['lng']};

          if (deliveryLatLng != null) {
            latLngToUse = LatLng(
              data['latitude'],
              data['longitude'],
            );
          } else {
            // Fallback to geocoding the transporter delivery address
            List<Location> locations = await locationFromAddress(addressToUse);
            if (locations.isNotEmpty) {
              final location = locations.first;
              latLngToUse = LatLng(location.latitude, location.longitude);
            } else {
              throw 'No locations found for the provided transporter delivery address';
            }
          }
        } else {
          // Use default location if dealerSelectedDelivery is not true
          if (kIsWeb) {
            addressToUse = addressObj['address'] ?? 'Unknown';
            final deliveryLatLng =
                widget.latLng ?? LatLng(addressObj['lat'], addressObj['lng']);
            latLngToUse = deliveryLatLng;
            setState(() {
              _latLng = latLngToUse;
              _displayedAddress = addressToUse;
            });
          } else {
            List<Location> locations =
                await locationFromAddress(widget.address);
            if (locations.isNotEmpty) {
              final location = locations.first;
              latLngToUse = LatLng(location.latitude, location.longitude);
            } else {
              throw 'No locations found for the provided collection address';
            }
          }
        }

        setState(() {
          _latLng = latLngToUse;
          _displayedAddress = addressToUse;
        });
      } else {
        throw 'Offer data not found';
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
        const SnackBar(content: Text('LatLng is not available')),
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
                    Text(
                      _headerText,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _meetingInfoText,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _displayedAddress.isNotEmpty
                          ? _displayedAddress
                          : 'Loading address...',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
                                markerId: MarkerId('Location'),
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
                        Clipboard.setData(
                            ClipboardData(text: _displayedAddress));
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
                      text: _doneButtonText,
                      borderColor: const Color(0xFFFF4E00),
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
