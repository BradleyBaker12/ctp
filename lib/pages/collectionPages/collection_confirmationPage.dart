import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/pages/payment_options_page.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/components/web_navigation_bar.dart';

import 'package:ctp/components/custom_bottom_navigation.dart'; // Ensure this import is correct

class CollectionConfirmationPage extends StatefulWidget {
  final String location;
  final String address;
  final DateTime date;
  final String time;
  final String offerId;
  final LatLng? latLng; // Add LatLng parameter

  const CollectionConfirmationPage({
    super.key,
    required this.location,
    required this.address,
    required this.date,
    required this.time,
    required this.offerId,
    this.latLng, // Add LatLng parameter
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
  String _headerText = 'COLLECTION CONFIRMATION';
  String _meetingInfoText = 'Meeting information:';
  String _doneButtonText = 'DONE';
  int _selectedIndex =
      0; // Variable to keep track of the selected bottom nav item

  // Add getter for compact navigation
  bool _isCompactNavigation(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1100;

  // Add getter for large screen
  bool get _isLargeScreen => MediaQuery.of(context).size.width > 900;

  bool _firestoreDeliveryOffer = false;

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

  Future<void> _getCoordinates() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .get();

      if (offerSnapshot.exists) {
        final data = offerSnapshot.data() as Map<String, dynamic>;
        // Store the transporter’s delivery offer flag from Firestore.
        _firestoreDeliveryOffer = data['dealerSelectedDelivery'] ?? false;

        final userRole =
            Provider.of<UserProvider>(context, listen: false).getUserRole;
        String addressToUse = widget.address;
        LatLng? latLngToUse = widget.latLng;

        // Instead of checking dealerChoice, choose delivery branch if widget.latLng is null.
        if (widget.latLng == null) {
          // Delivery branch: adjust header and meeting texts.
          setState(() {
            _headerText = 'DELIVERY CONFIRMATION';
            _meetingInfoText = 'Delivery information:';
            _doneButtonText = 'CONFIRM DELIVERY';
          });
          // Use dealer’s provided delivery address
          if (latLngToUse == null) {
            List<Location> locations =
                await locationFromAddress(widget.address);
            if (locations.isNotEmpty) {
              final location = locations.first;
              latLngToUse = LatLng(location.latitude, location.longitude);
            } else {
              throw 'No locations found for the provided dealer address';
            }
          }
        } else {
          // Collection branch
          if (latLngToUse == null) {
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
    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.getUserRole;
    final bool showBottomNav = !_isLargeScreen && !kIsWeb;

    // Moved navigationItems declaration above all references.
    List<NavigationItem> navigationItems = userRole == 'dealer'
        ? [
            NavigationItem(title: 'Home', route: '/home'),
            NavigationItem(title: 'Search Trucks', route: '/truckPage'),
            NavigationItem(title: 'Wishlist', route: '/wishlist'),
            NavigationItem(title: 'Pending Offers', route: '/offers'),
          ]
        : [
            NavigationItem(title: 'Home', route: '/home'),
            NavigationItem(title: 'Your Trucks', route: '/transporterList'),
            NavigationItem(title: 'Your Offers', route: '/offers'),
            NavigationItem(title: 'In-Progress', route: '/in-progress'),
          ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: kIsWeb
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: WebNavigationBar(
                isCompactNavigation: _isCompactNavigation(context),
                currentRoute: '/offers',
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            )
          : null,
      drawer: _isCompactNavigation(context) && kIsWeb
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
                    Expanded(
                      child: ListView(
                        children: navigationItems.map((item) {
                          bool isActive = '/offers' == item.route;
                          return ListTile(
                            title: Text(
                              item.title,
                              style: TextStyle(
                                color: isActive
                                    ? const Color(0xFFFF4E00)
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            selected: isActive,
                            selectedTileColor: Colors.black12,
                            onTap: () {
                              Navigator.pop(context);
                              if (!isActive) {
                                Navigator.pushNamed(context, item.route);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
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
      bottomNavigationBar: showBottomNav
          ? CustomBottomNavigation(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            )
          : null,
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
