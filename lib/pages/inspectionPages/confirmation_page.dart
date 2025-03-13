import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_back_button.dart'; // Import your custom back button
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/pages/inspectionPages/inspection_details_page.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart'; // Import the intl package
import 'package:provider/provider.dart';

import 'final_inspection_approval_page.dart';

class ConfirmationPage extends StatefulWidget {
  final String offerId;
  final String location;
  final String address;
  final DateTime date;
  final String time;
  final LatLng latLng;
  final String makeModel;
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
    required this.makeModel,
    required this.offerAmount,
    required this.vehicleId,
  });

  @override
  _ConfirmationPageState createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  int _selectedIndex =
      1; // Variable to keep track of the selected bottom nav item
  bool _inspectionCompleteClicked =
      false; // To prevent double clicks on "Inspection Complete"

  @override
  void initState() {
    super.initState();
    _updateOfferStatus();
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

    // Check if both the dealer and transporter have completed the inspection
    DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
        .collection('offers')
        .doc(widget.offerId)
        .get();
    bool dealerInspectionComplete =
        offerSnapshot['dealerInspectionComplete'] ?? false;
    bool transporterInspectionComplete =
        offerSnapshot['transporterInspectionComplete'] ?? false;

    // Transporter waits for dealer to complete the inspection
    if (userRole == 'transporter' && !dealerInspectionComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waiting for the dealer to complete the inspection.'),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (dealerInspectionComplete && transporterInspectionComplete) {
      // Navigate to Final Inspection Approval Page only if both parties have completed
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Waiting for the other party to complete the inspection.'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    setState(() {
      _inspectionCompleteClicked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    final userProvider = Provider.of<UserProvider>(context);
    final profilePictureUrl = userProvider.getProfileImageUrl.isNotEmpty
        ? userProvider.getProfileImageUrl
        : 'lib/assets/default_profile_picture.png';

    // Fetch the user role to determine whether to show the reschedule button
    final userRole = userProvider.getUserRole;

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
                          'DATE: ${DateFormat('d MMMM yyyy').format(widget.date)}',
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
                      // Only show the "Reschedule" button for dealers
                      if (userRole == 'dealer')
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
                                  vehicleId: widget.vehicleId,
                                ),
                              ),
                            );
                          },
                        ),
                      CustomButton(
                        text: 'INSPECTION COMPLETE',
                        borderColor: const Color(0xFFFF4E00),
                        onPressed: () {
                          _completeInspection(userRole);
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
