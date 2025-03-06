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
import 'package:ctp/components/custom_back_button.dart';
import 'package:intl/intl.dart';
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
  final String
      offerAmount; // Ideally, ensure this is a string even if Firestore stores a number.
  final String vehicleId;

  const ConfirmationPage({
    super.key,
    required this.offerId,
    required this.location,
    required this.address,
    required this.date,
    required this.time,
    required this.latLng,
    required this.brand,
    required this.variant,
    required this.offerAmount,
    required this.vehicleId,
  });

  @override
  _ConfirmationPageState createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Determines if we are in compact navigation mode.
  bool _isCompactNavigation(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1100;

  int _selectedIndex = 1; // Keeps track of the selected bottom navigation item
  bool _inspectionCompleteClicked = false;

  @override
  void initState() {
    super.initState();
    _updateOfferStatus();
    // Removed the one-time fetch in favor of using real-time data in StreamBuilder.
  }

  void _updateOfferStatus() {
    FirebaseFirestore.instance
        .collection('offers')
        .doc(widget.offerId)
        .update({'offerStatus': 'inspection pending'});
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
    if (_inspectionCompleteClicked) return; // Prevent multiple clicks.
    setState(() {
      _inspectionCompleteClicked = true;
    });

    String fieldToUpdate = userRole == 'dealer'
        ? 'dealerInspectionComplete'
        : 'transporterInspectionComplete';

    // Update Firestore to mark the inspection as complete for the respective role.
    await FirebaseFirestore.instance
        .collection('offers')
        .doc(widget.offerId)
        .update({fieldToUpdate: true});

    // Optionally fetch the updated document here, though the StreamBuilder below will pick up changes.
    DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
        .collection('offers')
        .doc(widget.offerId)
        .get();
    bool dealerComplete = offerSnapshot['dealerInspectionComplete'] ?? false;
    bool transporterComplete =
        offerSnapshot['transporterInspectionComplete'] ?? false;

    if (dealerComplete && transporterComplete) {
      // Update the offer status to 'inspection completed'.
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({'offerStatus': 'inspection completed'});
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

  /// Provides adaptive text size based on device width.
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
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
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('offers')
              .doc(widget.offerId)
              .snapshots(),
          builder: (context, snapshot) {
            // Show a loading indicator if no data yet.
            if (!snapshot.hasData || snapshot.data!.data() == null) {
              return Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;

            // Get inspection completion booleans.
            bool dealerComplete = data['dealerInspectionComplete'] ?? false;
            bool transporterComplete =
                data['transporterInspectionComplete'] ?? false;

            // Extract additional details from Firestore.
            final Timestamp? inspectionDateTimestamp =
                data['dealerSelectedInspectionDate'];
            final DateTime inspectionDate = inspectionDateTimestamp != null
                ? inspectionDateTimestamp.toDate()
                : widget.date;
            final String inspectionTime =
                data['dealerSelectedInspectionTime'] ?? widget.time;
            final String inspectionAddress =
                data['dealerSelectedInspectionAddress'] ?? widget.address;
            final String offerAmountFromFirestore = data['offerAmount'] != null
                ? data['offerAmount'].toString()
                : widget.offerAmount;

            // If both inspections are complete, navigate automatically.
            if (dealerComplete && transporterComplete) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FinalInspectionApprovalPage(
                      offerId: widget.offerId,
                      oldOffer: offerAmountFromFirestore,
                      vehicleName: "${widget.brand} ${widget.variant}",
                    ),
                  ),
                );
              });
            }

            return GradientBackground(
              child: SizedBox.expand(
                child: SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header section.
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
                            // Use Firestore values if available.
                            _buildInfoContainer(
                              offerAmountFromFirestore,
                              context,
                              isLarge: true,
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            _buildInfoContainer(
                              'DATE: ${DateFormat('d MMMM yyyy').format(inspectionDate)}',
                              context,
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            _buildInfoContainer(
                              'TIME: $inspectionTime',
                              context,
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            _buildInfoContainer(
                              inspectionAddress,
                              context,
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.04),
                        // Buttons section.
                        Column(
                          children: [
                            if (userRole == 'dealer' &&
                                !dealerComplete &&
                                !transporterComplete)
                              Padding(
                                padding: EdgeInsets.only(
                                    bottom: screenHeight * 0.02),
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
                                          brand: widget.brand,
                                          variant: widget.variant,
                                          offerAmount: offerAmountFromFirestore,
                                          vehicleId: widget.vehicleId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            if ((userRole == 'dealer' && !dealerComplete) ||
                                (userRole == 'transporter' &&
                                    !transporterComplete))
                              Padding(
                                padding: EdgeInsets.only(
                                    bottom: screenHeight * 0.02),
                                child: CustomButton(
                                  text: 'INSPECTION COMPLETE',
                                  borderColor: const Color(0xFFFF4E00),
                                  onPressed: () =>
                                      _completeInspection(userRole),
                                ),
                              ),
                            if ((userRole == 'dealer' && dealerComplete) ||
                                (userRole == 'transporter' &&
                                    transporterComplete))
                              Padding(
                                padding: EdgeInsets.only(
                                    bottom: screenHeight * 0.02),
                                child: Text(
                                  'Waiting for ${userRole == 'dealer' ? 'transporter' : 'dealer'} to complete the inspection',
                                  style: _getTextStyle(
                                    fontSize:
                                        _adaptiveTextSize(context, 16, 20),
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
            );
          },
        ),
        bottomNavigationBar: (!kIsWeb)
            ? CustomBottomNavigation(
                selectedIndex: _selectedIndex,
                onItemTapped: _onItemTapped,
              )
            : null,
      );
    });
  }
}
