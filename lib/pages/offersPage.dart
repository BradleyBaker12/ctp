import 'package:ctp/pages/vehicles_list.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/offer_card.dart';
import 'package:ctp/pages/home_page.dart';
import 'package:ctp/pages/profile_page.dart';
import 'package:ctp/pages/truck_page.dart';
import 'package:ctp/pages/pending_offers_page.dart';
import 'package:ctp/pages/wishlist_offers_page.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ctp/components/custom_app_bar.dart'; // Import the CustomAppBar
import 'package:ctp/components/gradient_background.dart'; // Import the GradientBackground

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  _OffersPageState createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  late Future<void> _fetchOffersFuture;
  final OfferProvider _offerProvider = OfferProvider();
  int selectedIndex = 4; // Default to dealer index

  @override
  void initState() {
    super.initState();
    _fetchOffersFuture = _fetchOffers();
    _setSelectedIndex(); // Set the selected index based on user role
  }

  Future<void> _fetchOffers() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userRole = userProvider.getUserRole;

      await _offerProvider.fetchOffers(user.uid, userRole);
      setState(() {});
    }
  }

  void _setSelectedIndex() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = userProvider.getUserRole;

    // Set selectedIndex based on role
    setState(() {
      if (userRole == 'transporter') {
        selectedIndex = 2; // Transporters will have OffersPage at index 2
      } else {
        selectedIndex = 4; // Dealers will have OffersPage at index 4
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(), // Use the custom app bar here
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(
                height: 40,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'lib/assets/shaking_hands.png', // Path to the handshake image
                    width: 30,
                    height: 30,
                  ),
                  const SizedBox(width: 8), // Space between image and text
                  const Text(
                    'PENDING OFFERS',
                    style: TextStyle(
                      color: Color(0xFFFF4E00),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(
                width: 350,
                child: Text(
                  'Track your pending offers made.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              _buildPendingOffersSection(),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNavigation(
          selectedIndex: selectedIndex, // Dynamically set selectedIndex
          onItemTapped: (index) {
            final userProvider =
                Provider.of<UserProvider>(context, listen: false);
            final userRole = userProvider.getUserRole;

            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            } else if (index == 1) {
              if (userRole == 'transporter') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const VehiclesListPage()),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const TruckPage()),
                );
              }
            } else if (index == 2) {
              if (userRole == 'transporter') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const OffersPage()),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WishlistOffersPage()),
                );
              }
            } else if (index == 3) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            } else if (index == 4) {
              if (userRole != 'transporter') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const OffersPage()),
                );
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildPendingOffersSection() {
    return FutureBuilder<void>(
      future: _fetchOffersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                  color: Color(
                      0xFFFF4E00)), // Ensure the loading icon isn't stretched
            ),
          );
        } else if (snapshot.hasError) {
          return Text(
            'Error fetching offers',
            style: _customFont(16, FontWeight.normal, Colors.white),
          );
        } else {
          // Limit the offers to the 3 most recent
          final latestOffers = _offerProvider.offers.take(3).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Navigate to PendingOffersPage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PendingOffersPage()),
                        );
                      },
                      child: Row(
                        children: const [
                          Text(
                            'View All',
                            style: TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                          Icon(
                            Icons.arrow_right,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ...latestOffers.map((offer) {
                return OfferCard(
                  offer: offer,
                );
              }).toList(),
            ],
          );
        }
      },
    );
  }

  TextStyle _customFont(double fontSize, FontWeight fontWeight, Color color) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFamily: 'Montserrat',
    );
  }
}
