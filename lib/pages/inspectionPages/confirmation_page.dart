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

class ConfirmationPage extends StatefulWidget {
  final String offerId;
  final String location;
  final String address;
  final DateTime date;
  final String time;
  final LatLng latLng;
  final String makeModel;
  final String offerAmount;
  final String vehicleId; // Add this line

  const ConfirmationPage({
    super.key,
    required this.offerId,
    required this.location,
    required this.address,
    required this.date,
    required this.time,
    required this.latLng,
    required this.makeModel,
    required this.offerAmount,
    required this.vehicleId, // Add this line
  });

  @override
  _ConfirmationPageState createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  int _selectedIndex =
      1; // Variable to keep track of the selected bottom nav item

  void _updateOfferStatus() {
    FirebaseFirestore.instance
        .collection('offers')
        .doc(widget.offerId)
        .update({'offerStatus': 'inspection pending'});
  }

  @override
  void initState() {
    super.initState();
    _updateOfferStatus();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToHomePage(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    final userProvider = Provider.of<UserProvider>(context);
    final profilePictureUrl = userProvider.getProfileImageUrl.isNotEmpty
        ? userProvider.getProfileImageUrl
        : 'lib/assets/default_profile_picture.png';

    return Scaffold(
      body: GradientBackground(
        child: SizedBox.expand(
          // Ensures the child takes up the full height
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16.0),
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
                          child: Image.asset('lib/assets/CTPLogo.png',
                              width: screenSize.width * 0.22,
                              height: screenSize.height * 0.22)),
                      Text(
                        'WAITING ON FINAL INSPECTION',
                        style: GoogleFonts.montserrat(
                          fontSize: screenSize.height * 0.023,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(profilePictureUrl),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        widget.makeModel.toUpperCase(),
                        style: GoogleFonts.montserrat(
                          fontSize: screenSize.height * 0.023,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'OFFER',
                        style: GoogleFonts.montserrat(
                            fontSize: screenSize.height * 0.02,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Offer Amount Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          widget.offerAmount,
                          style: GoogleFonts.montserrat(
                            fontSize: screenSize.height * 0.023,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Date Box
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          minHeight:
                              screenSize.height * 0.05, // Set a minimum height
                        ),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          'DATE: ${DateFormat('d MMMM yyyy').format(widget.date)}', // Format date as 25 September 2024
                          style: GoogleFonts.montserrat(
                              fontSize: screenSize.height * 0.018,
                              color: Colors.white,
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Time Box
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          minHeight:
                              screenSize.height * 0.05, // Set a minimum height
                        ),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          'TIME: ${widget.time}',
                          style: GoogleFonts.montserrat(
                              fontSize: screenSize.height * 0.018,
                              color: Colors.white,
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Location Box
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          minHeight:
                              screenSize.height * 0.05, // Set a minimum height
                        ),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          widget.address,
                          style: GoogleFonts.montserrat(
                            fontSize: screenSize.height * 0.018,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                      height: 16), // Added spacing for bottom buttons
                  Column(
                    children: [
                      CustomButton(
                        text: 'RESCHEDULE',
                        borderColor: Colors.blue,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InspectionDetailsPage(
                                offerId: widget.offerId,
                                makeModel: widget.makeModel,
                                offerAmount: widget.offerAmount,
                                vehicleId:
                                    widget.vehicleId, // Ensure this is added
                              ),
                            ),
                          );
                        },
                      ),
                      CustomButton(
                        text: 'INSPECTION COMPLETE',
                        borderColor: const Color(0xFFFF4E00),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FinalInspectionApprovalPage(
                                offerId: widget.offerId,
                                oldOffer: widget.offerAmount,
                                vehicleName: widget.makeModel,
                              ),
                            ),
                          );
                        },
                      ),
                      CustomButton(
                        text: 'BACK TO HOME',
                        borderColor: const Color(0xFFFF4E00),
                        onPressed: () {
                          _navigateToHomePage(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
