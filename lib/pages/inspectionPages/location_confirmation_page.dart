import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/pages/inspectionPages/confirmation_page.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:flutter/scheduler.dart';
import 'package:ctp/services/geocoding_service.dart';
import 'package:ctp/components/web_navigation_bar.dart'; // Add this import

class LocationConfirmationPage extends StatefulWidget {
  final String offerId;
  final String location;
  final String address;
  final DateTime date;
  final String time;
  final String brand; // Changed from makeModel
  final String variant; // Added new property
  final String offerAmount;
  final String vehicleId;

  const LocationConfirmationPage({
    super.key,
    required this.offerId,
    required this.location,
    required this.address,
    required this.date,
    required this.time,
    required this.brand, // Changed from makeModel
    required this.variant, // Added new parameter
    required this.offerAmount,
    required this.vehicleId,
  });

  @override
  _LocationConfirmationPageState createState() =>
      _LocationConfirmationPageState();
}

class _LocationConfirmationPageState extends State<LocationConfirmationPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String currentRoute = '/offers'; // Add this line

  // Add this getter for consistent breakpoint
  bool _isCompactNavigation(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1100;

  bool _isLoading = false;
  LatLng? _latLng;
  int _selectedIndex = 0;
  final bool _isInitialized = false;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _getCoordinatesFromAddress();
    _updateOfferStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Remove the initialization check since we're handling it in initState
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
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
      _showSnackBar('Failed to update offer status: $e');
    }
  }

  String _formatAddress(String address) {
    // Remove any special characters and format address
    return address.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> _getCoordinatesFromAddress() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Getting coordinates for address: ${widget.address}');
      final formattedAddress = _formatAddress(widget.address);
      print('Formatted address: $formattedAddress');

      final coordinates =
          await GeocodingService.getCoordinates(formattedAddress);

      if (!mounted) return;

      if (coordinates != null) {
        print(
            "Location found: lat=${coordinates.latitude}, lng=${coordinates.longitude}");
        setState(() {
          _latLng = coordinates;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar(
            'Unable to find exact location. Using approximate coordinates.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      print('Error getting coordinates: $e');
      _showSnackBar('Using approximate location for South Africa.');
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
              brand: widget.brand, // Changed from makeModel
              variant: widget.variant, // Added variant
              offerAmount: widget.offerAmount,
              vehicleId: widget.vehicleId,
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

  /// Helper function to provide different sizes for phone vs. tablet
  double _adaptiveSize(
      BuildContext context, double phoneSize, double tabletSize) {
    bool isTablet = MediaQuery.of(context).size.width >= 600;
    return isTablet ? tabletSize : phoneSize;
  }

  /// Helper function for text styles
  TextStyle _getTextStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.white,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String userRole = userProvider.getUserRole;
    final screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width >= 600;
    const bool isWeb = kIsWeb; // Change to use kIsWeb directly
    final double contentWidth =
        isTablet ? screenSize.width * 1 : screenSize.width;
    final double horizontalPadding =
        isTablet ? (screenSize.width - contentWidth) / 2 : 16;

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
      appBar: isWeb
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: WebNavigationBar(
                isCompactNavigation: _isCompactNavigation(context),
                currentRoute: '/offers',
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            )
          : null,
      drawer: _isCompactNavigation(context) && isWeb
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
                    Expanded(
                      child: ListView(
                        children: navigationItems.map((item) {
                          bool isActive = currentRoute == item.route;
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
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                // Wrap SingleChildScrollView with Column
                children: [
                  Expanded(
                    // Wrap SingleChildScrollView with Expanded
                    child: SingleChildScrollView(
                      child: Center(
                        // Center the content for web
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: isTablet ? 800 : double.infinity,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (!isWeb) // Add this condition
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: CustomBackButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                ),
                              SizedBox(height: _adaptiveSize(context, 50, 60)),
                              SizedBox(
                                width: _adaptiveSize(context, 100, 120),
                                height: _adaptiveSize(context, 100, 120),
                                child: Image.asset('lib/assets/CTPLogo.png'),
                              ),
                              SizedBox(height: _adaptiveSize(context, 32, 40)),
                              Text(
                                'LOCATION CONFIRMATION',
                                style: _getTextStyle(
                                  fontSize: _adaptiveSize(context, 24, 32),
                                  fontWeight: FontWeight.w900,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: _adaptiveSize(context, 32, 40)),
                              Text(
                                'Meeting information:',
                                style: _getTextStyle(
                                  fontSize: _adaptiveSize(context, 18, 24),
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: _adaptiveSize(context, 32, 40)),

                              // Address
                              Container(
                                width: isTablet
                                    ? contentWidth * 0.8
                                    : double.infinity,
                                padding: EdgeInsets.all(
                                    _adaptiveSize(context, 16, 24)),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  widget.address,
                                  style: _getTextStyle(
                                    fontSize: _adaptiveSize(context, 16, 20),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),

                              SizedBox(height: _adaptiveSize(context, 32, 40)),

                              // Date and Time
                              Container(
                                width: isTablet
                                    ? contentWidth * 0.6
                                    : double.infinity,
                                padding: EdgeInsets.all(
                                    _adaptiveSize(context, 16, 24)),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${widget.date.day} ${_getMonthName(widget.date.month)} ${widget.date.year}',
                                      style: _getTextStyle(
                                        fontSize:
                                            _adaptiveSize(context, 16, 20),
                                        fontWeight: FontWeight.w800,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(
                                        height: _adaptiveSize(context, 8, 12)),
                                    Text(
                                      widget.time,
                                      style: _getTextStyle(
                                        fontSize:
                                            _adaptiveSize(context, 16, 20),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: _adaptiveSize(context, 32, 40)),

                              // Map
                              if (_latLng != null)
                                Container(
                                  height: _adaptiveSize(context, 300, 400),
                                  width: isTablet
                                      ? contentWidth * 0.8
                                      : double.infinity,
                                  margin: EdgeInsets.symmetric(
                                    horizontal: _adaptiveSize(context, 16, 24),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: GoogleMap(
                                      initialCameraPosition: CameraPosition(
                                        target: _latLng ?? LatLng(0, 0),
                                        zoom: 14.0,
                                      ),
                                      markers: {
                                        Marker(
                                          markerId: MarkerId(widget.location),
                                          position: _latLng ?? LatLng(0, 0),
                                        ),
                                      },
                                    ),
                                  ),
                                ),

                              // Buttons
                              SizedBox(height: _adaptiveSize(context, 16, 24)),
                              SizedBox(
                                width: isTablet
                                    ? contentWidth * 0.4
                                    : double.infinity,
                                child: Column(
                                  children: [
                                    CustomButton(
                                      text: 'COPY ADDRESS',
                                      borderColor: Colors.blue,
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                            text: widget.address));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Address copied to clipboard')),
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
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Loading overlay
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
      bottomNavigationBar:
          (!kIsWeb && !isTablet) // Change this line to check for kIsWeb
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
