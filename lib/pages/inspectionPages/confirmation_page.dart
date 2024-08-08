import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/pages/inspectionPages/inspection_details_page.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'final_inspection_approval_page.dart';

import 'package:ctp/components/custom_bottom_navigation.dart'; // Ensure this import is correct

class ConfirmationPage extends StatefulWidget {
  final String offerId;
  final String location;
  final String address;
  final DateTime date;
  final String time;
  final LatLng latLng;
  final String makeModel;
  final String offerAmount;

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
  });

  @override
  _ConfirmationPageState createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  int _selectedIndex =
      1; // Variable to keep track of the selected bottom nav item

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore.instance
        .collection('offers')
        .doc(widget.offerId)
        .update({'offerStatus': '1/4'});
    final userProvider = Provider.of<UserProvider>(context);
    final profilePictureUrl = userProvider.getProfileImageUrl.isNotEmpty
        ? userProvider.getProfileImageUrl
        : 'lib/assets/default_profile_picture.png';

    return Scaffold(
      body: GradientBackground(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Image.asset('lib/assets/CTPLogo.png'),
                  const SizedBox(height: 16),
                  const Text(
                    'WAITING ON FINAL INSPECTION',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(profilePictureUrl),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        5,
                        (index) =>
                            const Icon(Icons.star, color: Colors.orange)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.makeModel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'OFFER',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.offerAmount,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'DATE: ${widget.date.toLocal().toString().split(' ')[0]}', // Format date as YYYY-MM-DD
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TIME: ${widget.time}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.address,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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
                          ),
                        ),
                      );
                    },
                  ),
                  CustomButton(
                    text: 'INSPECTION COMPLETE',
                    borderColor: Colors.orange,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FinalInspectionApprovalPage(
                            offerId: widget.offerId,
                          ), // Pass the offerId
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
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
