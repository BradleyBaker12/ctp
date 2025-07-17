import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/pages/inspectionPages/confirmation_page.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/web_navigation_bar.dart';

import 'package:auto_route/auto_route.dart';
@RoutePage()class LocationConfirmationPage extends StatefulWidget {
  final String offerId;
  final String location;
  final String address;
  final DateTime date;
  final String time;
  final String brand; // Changed from makeModel
  final String variant; // New property
  final String offerAmount;
  final String vehicleId;

  const LocationConfirmationPage({
    super.key,
    required this.offerId,
    required this.location,
    required this.address,
    required this.date,
    required this.time,
    required this.brand,
    required this.variant,
    required this.offerAmount,
    required this.vehicleId,
  });

  @override
  _LocationConfirmationPageState createState() =>
      _LocationConfirmationPageState();
}

class _LocationConfirmationPageState extends State<LocationConfirmationPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;
  LatLng? _latLng;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  /// Updated getAddress() method: Pull location data from the "offers" collection
  Future<void> getAddress() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('offers')
        .doc(widget.offerId)
        .get();
    if (snapshot.exists) {
      var data = snapshot.data() as Map<String, dynamic>?;
      if (data != null &&
          data.containsKey('inspectionDetails') &&
          data['inspectionDetails'] is Map &&
          data['inspectionDetails']['inspectionLocations'] is Map &&
          data['inspectionDetails']['inspectionLocations']['locations']
              is List) {
        List locations =
            data['inspectionDetails']['inspectionLocations']['locations'];
        if (locations.isNotEmpty) {
          double lat = locations[0]['lat']?.toDouble() ?? 0.0;
          double lng = locations[0]['lng']?.toDouble() ?? 0.0;
          setState(() {
            _latLng = LatLng(lat, lng);
          });
          print("Location Value (from offer): $_latLng");
        }
      }
    }
  }

  Future<void> _initializePage() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getAddress();
      await _getCoordinatesFromAddress();
      await _updateOfferStatus();
    });
  }

  Future<void> _updateOfferStatus() async {
    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({'offerStatus': 'confirm location'});
      print('Offer status updated to "confirm location"');
    } catch (e) {
      print('Failed to update offer status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update offer status: $e')));
    }
  }

  Future<void> _getCoordinatesFromAddress() async {
    if (_latLng != null) return;
    try {
      setState(() {
        _isLoading = true;
      });
      print('Getting coordinates for address: ${widget.address}');
      List<Location> locations = await locationFromAddress(widget.address);
      print("Locations List: $locations");
      if (locations.isNotEmpty) {
        final location = locations.first;
        print("Location address: $location");
        print(
            "Latitude: ${location.latitude} and Longitude: ${location.longitude}");
        setState(() {
          _latLng = LatLng(location.latitude, location.longitude);
          print('Coordinates found: $_latLng');
        });
      } else {
        throw 'No locations found for the provided address';
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
              brand: widget.brand,
              variant: widget.variant,
              offerAmount: widget.offerAmount,
              vehicleId: widget.vehicleId,
            ),
          ),
        );
      } else {
        print('LatLng is null, cannot proceed');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location coordinates not available')));
      }
    } catch (e) {
      print('Error saving inspection details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save inspection details: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      print('Location cannot be found with the provided address');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Location cannot be found with the provided address')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String userRole = userProvider.getUserRole;
    final screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width >= 600;
    const bool isWeb = kIsWeb;
    final double contentWidth =
        isTablet ? screenSize.width * 1 : screenSize.width;
    final double horizontalPadding =
        isTablet ? (screenSize.width - contentWidth) / 2 : 16;

    // --- Working Google Maps Widget ---
    Widget googleMapWidget;
    if (_latLng != null && !_isLoading) {
      googleMapWidget = Container(
        height: 300,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: _latLng!, zoom: 14.0),
            markers: {
              Marker(
                markerId: MarkerId(widget.location),
                position: _latLng!,
              ),
            },
            onMapCreated: (GoogleMapController controller) {
              if (_latLng != null) {
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: _latLng!, zoom: 14.0),
                  ),
                );
              }
            },
          ),
        ),
      );
    } else if (_isLoading) {
      googleMapWidget = const Center(child: CircularProgressIndicator());
    } else {
      googleMapWidget = const Text(
        'No location available',
        style: TextStyle(color: Colors.red),
      );
    }
    // --- End Google Maps Widget ---

    return Scaffold(
      key: _scaffoldKey,
      appBar: isWeb
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: WebNavigationBar(
                isCompactNavigation: MediaQuery.of(context).size.width <= 1100,
                currentRoute: '/offers',
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            )
          : null,
      drawer: (MediaQuery.of(context).size.width <= 1100 && isWeb)
          ? Drawer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: const [Colors.black, Color(0xFF2F7FFD)],
                  ),
                ),
                child: Column(
                  children: [
                    DrawerHeader(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white24,
                            width: 1,
                          ),
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
                    // Additional drawer items here…
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
                  child: Container(
                    constraints: BoxConstraints(
                        maxWidth: isTablet ? 800 : double.infinity),
                    padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (!isWeb)
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
                        googleMapWidget,
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'COPY ADDRESS',
                          borderColor: Colors.blue,
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: widget.address));
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
      bottomNavigationBar: (!kIsWeb && !isTablet)
          ? CustomBottomNavigation(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            )
          : null,
    );
  }
}
