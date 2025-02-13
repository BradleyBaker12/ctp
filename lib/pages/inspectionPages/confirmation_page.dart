import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/pages/inspectionPages/inspection_details_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'final_inspection_approval_page.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/custom_back_button.dart'; // Import your custom back button
import 'package:intl/intl.dart'; // Import the intl package
import 'package:flutter/foundation.dart';
import 'package:ctp/components/web_navigation_bar.dart';

class ConfirmationPage extends StatefulWidget {
  final String offerId;
  final String location;
  final String address;
  final DateTime date;
  final String time;
  final LatLng latLng;
  final String brand; // Changed from makeModel
  final String variant; // Added new property
  final String offerAmount;
  final String vehicleId;

  const ConfirmationPage({
    super.key,
    required this.offerId,
    required this.location,
    required this.address,
    required this.date,
    required this.time,
    required this.latLng,
    required this.brand, // Changed from makeModel
    required this.variant, // Added new parameter
    required this.offerAmount,
    required this.vehicleId,
  });

  @override
  _ConfirmationPageState createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Add this getter for consistent breakpoint
  bool _isCompactNavigation(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1100;

  int _selectedIndex =
      1; // Variable to keep track of the selected bottom nav item
  bool _inspectionCompleteClicked =
      false; // To prevent double clicks on "Inspection Complete"
  bool _dealerInspectionComplete = false;
  bool _transporterInspectionComplete = false;

  @override
  void initState() {
    super.initState();
    _updateOfferStatus();
    _fetchInspectionStatus();
  }

  void _updateOfferStatus() {
    FirebaseFirestore.instance
        .collection('offers')
        .doc(widget.offerId)
        .update({'offerStatus': 'inspection pending'});
  }

  Future<void> _fetchInspectionStatus() async {
    DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
        .collection('offers')
        .doc(widget.offerId)
        .get();

    setState(() {
      _dealerInspectionComplete =
          offerSnapshot['dealerInspectionComplete'] ?? false;
      _transporterInspectionComplete =
          offerSnapshot['transporterInspectionComplete'] ?? false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToHomePage(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  Future<void> _completeInspection(String userRole) async {
    if (_inspectionCompleteClicked) return; // Prevent multiple clicks
    setState(() {
      _inspectionCompleteClicked = true;
    });

    String fieldToUpdate = userRole == 'dealer'
        ? 'dealerInspectionComplete'
        : 'transporterInspectionComplete';

    // Update Firestore to mark the inspection as complete for the respective role
    await FirebaseFirestore.instance
        .collection('offers')
        .doc(widget.offerId)
        .update({
      fieldToUpdate: true,
    });

    await _fetchInspectionStatus();

    if (_dealerInspectionComplete && _transporterInspectionComplete) {
      // Update offer status to next stage
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({'offerStatus': 'inspection completed'});

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FinalInspectionApprovalPage(
            offerId: widget.offerId,
            oldOffer: widget.offerAmount,
            vehicleName:
                "${widget.brand} ${widget.variant}", // Updated to use brand and variant
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userRole == 'dealer'
                ? 'Waiting for the transporter to complete the inspection.'
                : 'Waiting for the dealer to complete the inspection.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }

    setState(() {
      _inspectionCompleteClicked = false;
    });
  }

  /// Helper function to provide different font sizes for phone vs. tablet.
  double _adaptiveTextSize(
      BuildContext context, double phoneSize, double tabletSize) {
    bool isTablet = MediaQuery.of(context).size.width >= 600;
    return isTablet ? tabletSize : phoneSize;
  }

  TextStyle _getTextStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.white,
  }) {
    return GoogleFonts.montserrat(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isTablet = constraints.maxWidth >= 600;
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        const bool isWeb = kIsWeb;

        final userProvider = Provider.of<UserProvider>(context);
        final profilePictureUrl = userProvider.getProfileImageUrl.isNotEmpty
            ? userProvider.getProfileImageUrl
            : 'lib/assets/default_profile_picture.png';
        final userRole = userProvider.getUserRole;

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
                    onMenuPressed: () =>
                        _scaffoldKey.currentState?.openDrawer(),
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
                              bottom:
                                  BorderSide(color: Colors.white24, width: 1),
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
            child: SizedBox.expand(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: CustomBackButton(
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          SizedBox(
                            child: Image.asset(
                              'lib/assets/CTPLogo.png',
                              width: isTablet
                                  ? screenWidth * 0.15
                                  : screenWidth * 0.22,
                              height: isTablet
                                  ? screenHeight * 0.15
                                  : screenHeight * 0.22,
                            ),
                          ),
                          Text(
                            'WAITING ON FINAL INSPECTION',
                            style: _getTextStyle(
                              fontSize: _adaptiveTextSize(context, 22, 32),
                              fontWeight: FontWeight.w900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: screenHeight * 0.04),
                          CircleAvatar(
                            radius: isTablet ? 60 : 40,
                            backgroundImage: NetworkImage(profilePictureUrl),
                          ),
                          SizedBox(height: screenHeight * 0.04),
                          Text(
                            "${widget.brand} ${widget.variant}".toUpperCase(),
                            style: _getTextStyle(
                              fontSize: _adaptiveTextSize(context, 20, 28),
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: screenHeight * 0.04),
                          Text(
                            'OFFER',
                            style: _getTextStyle(
                              fontSize: _adaptiveTextSize(context, 18, 24),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: screenHeight * 0.01),

                          // Info containers with consistent scaling
                          _buildInfoContainer(
                            widget.offerAmount,
                            context,
                            isLarge: true,
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          _buildInfoContainer(
                            'DATE: ${DateFormat('d MMMM yyyy').format(widget.date)}',
                            context,
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          _buildInfoContainer(
                            'TIME: ${widget.time}',
                            context,
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          _buildInfoContainer(
                            widget.address,
                            context,
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.04),

                      // Buttons section
                      Column(
                        children: [
                          if (userRole == 'dealer' &&
                              !_dealerInspectionComplete &&
                              !_transporterInspectionComplete)
                            Padding(
                              padding:
                                  EdgeInsets.only(bottom: screenHeight * 0.02),
                              child: CustomButton(
                                text: 'RESCHEDULE',
                                borderColor: Colors.blue,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          InspectionDetailsPage(
                                        offerId: widget.offerId,
                                        brand: widget
                                            .brand, // Changed from makeModel
                                        variant:
                                            widget.variant, // Added variant
                                        offerAmount: widget.offerAmount,
                                        vehicleId: widget.vehicleId,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          if ((userRole == 'dealer' &&
                                  !_dealerInspectionComplete) ||
                              (userRole == 'transporter' &&
                                  !_transporterInspectionComplete))
                            Padding(
                              padding:
                                  EdgeInsets.only(bottom: screenHeight * 0.02),
                              child: CustomButton(
                                text: 'INSPECTION COMPLETE',
                                borderColor: const Color(0xFFFF4E00),
                                onPressed: () => _completeInspection(userRole),
                              ),
                            ),
                          if ((userRole == 'dealer' &&
                                  _dealerInspectionComplete) ||
                              (userRole == 'transporter' &&
                                  _transporterInspectionComplete))
                            Padding(
                              padding:
                                  EdgeInsets.only(bottom: screenHeight * 0.02),
                              child: Text(
                                'Waiting for ${userRole == 'dealer' ? 'transporter' : 'dealer'} to complete the inspection',
                                style: _getTextStyle(
                                  fontSize: _adaptiveTextSize(context, 16, 20),
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          CustomButton(
                            text: 'BACK TO HOME',
                            borderColor: const Color(0xFFFF4E00),
                            onPressed: () => _navigateToHomePage(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          bottomNavigationBar: (!kIsWeb)
              ? CustomBottomNavigation(
                  selectedIndex: _selectedIndex,
                  onItemTapped: _onItemTapped,
                )
              : null,
        );
      },
    );
  }

  Widget _buildInfoContainer(String text, BuildContext context,
      {bool isLarge = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isTablet = constraints.maxWidth >= 600;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(constraints.maxWidth * 0.02),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            text,
            style: _getTextStyle(
              fontSize: _adaptiveTextSize(
                context,
                isLarge ? 20 : 16,
                isLarge ? 28 : 20,
              ),
              fontWeight: isLarge ? FontWeight.bold : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
