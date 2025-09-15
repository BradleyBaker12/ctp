import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/pages/payment_approved.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ctp/components/web_navigation_bar.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';

import 'package:auto_route/auto_route.dart';

@RoutePage()
class CollectionConfirmationPage extends StatefulWidget {
  final String location;
  final String address;
  final DateTime date;
  final String time;
  final String offerId;
  final String? vehicleId;
  final LatLng? latLng; // Optional pre-set LatLng

  const CollectionConfirmationPage({
    super.key,
    required this.location,
    required this.address,
    required this.date,
    required this.time,
    required this.offerId,
    this.vehicleId,
    this.latLng,
  });

  @override
  _CollectionConfirmationPageState createState() =>
      _CollectionConfirmationPageState();
}

class _CollectionConfirmationPageState
    extends State<CollectionConfirmationPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  LatLng? _latLng;
  String _displayedAddress = '';
  final String _headerText = 'COLLECTION CONFIRMATION';
  final String _meetingInfoText = 'Meeting information:';
  final String _doneButtonText = 'DONE';
  int _selectedIndex = 0; // For bottom navigation
  StreamSubscription<DocumentSnapshot>? _offerSub;
  bool _redirected = false;

  @override
  void initState() {
    super.initState();
    debugPrint("initState: Starting initialization");
    _initializePage();
    _listenForCollectionReady();
  }

  void _listenForCollectionReady() {
    _offerSub = FirebaseFirestore.instance
        .collection('offers')
        .doc(widget.offerId)
        .snapshots()
        .listen((snap) {
      if (!mounted || _redirected) return;
      final data = snap.data();
      final status = (data?['offerStatus'] ?? '').toString().toLowerCase();
      if (status == 'collection ready') {
        _redirected = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentApprovedPage(offerId: widget.offerId),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _offerSub?.cancel();
    super.dispose();
  }

  Future<void> _initializePage() async {
    // First, try to pull coordinates from the offer document.
    await getAddress();
    // If coordinates are still (0, 0) or null, fall back to geocoding widget.address.
    if (_latLng == null ||
        (_latLng!.latitude == 0 && _latLng!.longitude == 0)) {
      await _getCoordinatesFromAddress();
    }
    await _updateOfferStatus();
  }

  /// Retrieves the address and coordinates from the offer document.
  Future<void> getAddress() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .get();
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>?;
        debugPrint("getAddress: Offer document data: $data");
        if (data != null &&
            data.containsKey('inspectionDetails') &&
            data['inspectionDetails'] is Map &&
            data['inspectionDetails']['inspectionLocations'] is Map &&
            data['inspectionDetails']['inspectionLocations']['locations']
                is List) {
          List locations =
              data['inspectionDetails']['inspectionLocations']['locations'];
          debugPrint("getAddress: Found locations: $locations");
          if (locations.isNotEmpty) {
            double lat = locations[0]['lat']?.toDouble() ?? 0.0;
            double lng = locations[0]['lng']?.toDouble() ?? 0.0;
            setState(() {
              _latLng = LatLng(lat, lng);
              _displayedAddress = locations[0]['address'] ?? widget.address;
            });
            debugPrint("getAddress: Retrieved _latLng: $_latLng");
          }
        } else {
          debugPrint("getAddress: Inspection details structure not found.");
        }
      } else {
        debugPrint("getAddress: Offer document does not exist.");
      }
    } catch (e) {
      debugPrint("getAddress: Error retrieving address: $e");
    }
  }

  /// If no valid coordinates were obtained from the offer, geocode widget.address.
  Future<void> _getCoordinatesFromAddress() async {
    if (_latLng != null &&
        !(_latLng!.latitude == 0 && _latLng!.longitude == 0)) {
      return;
    }
    try {
      setState(() {
        _isLoading = true;
      });
      debugPrint(
          "getCoordinatesFromAddress: Getting coordinates for: ${widget.address}");
      List<Location> locations = await locationFromAddress(widget.address);
      debugPrint("getCoordinatesFromAddress: Locations: $locations");
      if (locations.isNotEmpty) {
        final location = locations.first;
        setState(() {
          _latLng = LatLng(location.latitude, location.longitude);
          _displayedAddress = widget.address;
        });
        debugPrint("getCoordinatesFromAddress: Coordinates found: $_latLng");
      } else {
        throw 'No locations found for the provided address';
      }
    } catch (e) {
      debugPrint("getCoordinatesFromAddress: Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateOfferStatus() async {
    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({'offerStatus': 'collection location confirmation'});
      debugPrint("Offer status updated for offerId: ${widget.offerId}");
    } catch (e) {
      debugPrint("Error updating offer status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update offer status: $e')));
    }
  }

  void _openInGoogleMaps() async {
    String googleMapsUrl;
    if (_latLng != null) {
      googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=${_latLng!.latitude},${_latLng!.longitude}';
    } else {
      final query =
          _displayedAddress.isNotEmpty ? _displayedAddress : widget.address;
      googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
    }
    debugPrint("Opening Google Maps URL: $googleMapsUrl");
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      debugPrint("Could not open Google Maps with URL: $googleMapsUrl");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    debugPrint("Bottom navigation item tapped: $index");
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

  @override
  Widget build(BuildContext context) {
    debugPrint(
        "build: _latLng: $_latLng, _displayedAddress: $_displayedAddress");
    // Define isLargeScreen as a local variable.
    final bool isLargeScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      key: _scaffoldKey,
      appBar: kIsWeb
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: WebNavigationBar(
                isCompactNavigation: MediaQuery.of(context).size.width <= 1100,
                currentRoute: '/offers',
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            )
          : null,
      drawer: (MediaQuery.of(context).size.width <= 1100 && kIsWeb)
          ? Drawer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.black, Color(0xFF2F7FFD)],
                  ),
                ),
                child: Column(
                  children: [
                    DrawerHeader(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white24, width: 1),
                        ),
                      ),
                      child: Center(
                        child: Image.network(
                          'https://firebasestorage.googleapis.com/v0/b/ctp-central-database.appspot.com/o/CTPLOGOWeb.png?alt=media&token=d85ec0b5-f2ba-4772-aa08-e9ac6d4c2253',
                          height: 50,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 50,
                              width: 50,
                              color: Colors.grey[900],
                              child: const Icon(Icons.local_shipping,
                                  color: Colors.white),
                            );
                          },
                        ),
                      ),
                    ),
                    // Additional drawer items can be added here.
                  ],
                ),
              ),
            )
          : null,
      body: GradientBackground(
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (!kIsWeb)
                          Align(
                            alignment: Alignment.topLeft,
                            child: CustomBackButton(
                                onPressed: () => Navigator.of(context).pop()),
                          ),
                        const SizedBox(height: 50),
                        SizedBox(
                          width: 100,
                          height: 100,
                          child: Image.asset('lib/assets/CTPLogo.png'),
                        ),
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
                        // Google Maps widget (same as working version)
                        if (_latLng != null)
                          Container(
                            height: 300,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 16.0),
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
                                onMapCreated: (GoogleMapController controller) {
                                  debugPrint(
                                      "GoogleMap created. Animating camera to: $_latLng");
                                  if (_latLng != null) {
                                    controller.animateCamera(
                                      CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                          target: _latLng!,
                                          zoom: 14.0,
                                        ),
                                      ),
                                    );
                                  }
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
                          onPressed: () async {
                            final formatted = 'Address: ${_displayedAddress.isNotEmpty
                                    ? _displayedAddress
                                    : widget.address}\nDate: ${widget.date.day} ${_getMonthName(widget.date.month)} ${widget.date.year}\nTime: ${widget.time}';
                            await Clipboard.setData(
                                ClipboardData(text: formatted));
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Collection details copied')),
                              );
                            }
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
                          onPressed: () async {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('offers')
                                  .doc(widget.offerId)
                                  .set({'offerStatus': 'collection ready'},
                                      SetOptions(merge: true));
                            } catch (e) {
                              debugPrint(
                                  'Failed to update offer status to collection ready: $e');
                            }
                            if (!mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PaymentApprovedPage(
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
      ),
      // Use local variable isLargeScreen to determine bottom navigation visibility.
      bottomNavigationBar: !isLargeScreen && !kIsWeb
          ? CustomBottomNavigation(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            )
          : null,
    );
  }
}
