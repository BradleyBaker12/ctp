import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/offer_card.dart';
import 'package:ctp/pages/home_page.dart';
import 'package:ctp/pages/profile_page.dart';
import 'package:ctp/pages/truck_page.dart';
import 'package:ctp/pages/pending_offers_page.dart'; // Import PendingOffersPage
import 'package:ctp/pages/wish_list_page.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ctp/components/wish_card.dart';
import 'vehicle_details_page.dart'; // Import the VehicleDetailsPage
import 'package:ctp/providers/vehicles_provider.dart'; // Import the VehicleProvider
import 'package:provider/provider.dart'; // Import Provider
import 'package:ctp/providers/offer_provider.dart'; // Import OfferProvider
import 'dart:ui'; // Required for the AppBar's blur effect

class WishlistOffersPage extends StatefulWidget {
  const WishlistOffersPage({super.key});

  @override
  _WishlistOffersPageState createState() => _WishlistOffersPageState();
}

class _WishlistOffersPageState extends State<WishlistOffersPage> {
  late Future<void> _fetchOffersFuture;
  late Future<void> _fetchWishlistFuture;
  final OfferProvider _offerProvider = OfferProvider();
  final List<DocumentSnapshot> _wishlistVehicles = [];

  String _selectedTab = 'Pending Offers';

  @override
  void initState() {
    super.initState();
    _fetchOffersFuture = _fetchOffers();
    _fetchWishlistFuture = _fetchWishlist();
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

  Future<void> _fetchWishlist() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        List<String> wishlistItems =
            List<String>.from(userDoc['likedVehicles'] ?? []);
        for (String vehicleId in wishlistItems) {
          DocumentSnapshot vehicleDoc = await FirebaseFirestore.instance
              .collection('vehicles')
              .doc(vehicleId)
              .get();
          if (vehicleDoc.exists) {
            _wishlistVehicles.add(vehicleDoc);
          }
        }
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final vehicleProvider =
        Provider.of<VehicleProvider>(context); // Access VehicleProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = userProvider.getUserRole;

    return Scaffold(
      extendBodyBehindAppBar: true, // Extend the body behind the app bar
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(size.height * 0.07), // Set desired height
        child: AppBar(
          automaticallyImplyLeading: false, // This removes the back button
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: Colors.grey.withOpacity(0.1),
              ),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 35.0), // Space on the left
                child: Image.asset(
                  'lib/assets/CTPLogo.png',
                  width: 60,
                  height: 60,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(right: 25.0), // Space on the right
                child: Consumer<UserProvider>(
                  builder: (context, userProvider, _) {
                    final profileImageUrl = userProvider.getProfileImageUrl;
                    return CircleAvatar(
                      radius: 26,
                      backgroundImage: profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : const AssetImage(
                                  'lib/assets/default-profile-photo.jpg')
                              as ImageProvider,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 450, // Height for your image
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                          'lib/assets/WishListImage.png'), // Your header image path here
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 50, // Adjust the vertical alignment as necessary
                  left: 16,
                  right: 16,
                  child: const Text(
                    'WISHLIST AND OFFERS',
                    style: TextStyle(
                      color: Color(0xFFFF4E00),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Positioned(
                  bottom: 0, // Adjust the vertical alignment as necessary
                  left: 16,
                  right: 16,
                  child: const SizedBox(
                    width: 350,
                    child: Text(
                      'View your wish listed trucks and track your pending offers made.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabWithIcon(
                    'Pending Offers', 'lib/assets/shaking_hands.png'),
                const SizedBox(width: 16),
                _buildTabWithIcon('Wishlist', 'lib/assets/HeartVector.png'),
              ],
            ),
            const SizedBox(height: 16),
            _selectedTab == 'Pending Offers'
                ? _buildPendingOffersSection()
                : _buildWishlistSection(size, vehicleProvider, userRole),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: 2, // Ensure the heart icon is selected
        onItemTapped: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TruckPage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const WishlistOffersPage()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
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

  Widget _buildWishlistSection(
      Size size, VehicleProvider vehicleProvider, String userRole) {
    return FutureBuilder<void>(
      future: _fetchWishlistFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                color: Color(0xFFFF4E00),
              ), // Ensure the loading icon isn't stretched
            ),
          );
        } else if (snapshot.hasError) {
          return Text(
            'Error fetching wishlist',
            style: _customFont(16, FontWeight.normal, Colors.white),
          );
        } else {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Navigate to WishlistPage
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const WishlistPage()),
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
              ..._wishlistVehicles.map((vehicleDoc) {
                Map<String, dynamic>? data =
                    vehicleDoc.data() as Map<String, dynamic>?;

                // Ensure you check for makeModel in the Firestore document directly
                String makeModel = data != null &&
                        data.containsKey('makeModel') &&
                        data['makeModel'] != null
                    ? data['makeModel']
                    : 'Unknown';

                Vehicle vehicle = vehicleProvider.vehicles.firstWhere(
                  (v) => v.id == vehicleDoc.id,
                  orElse: () => Vehicle(
                    id: vehicleDoc.id,
                    accidentFree: 'N/A',
                    application: 'N/A',
                    bookValue: 'N/A',
                    damageDescription: '',
                    damagePhotos: [],
                    engineNumber: 'N/A',
                    expectedSellingPrice: 'N/A',
                    firstOwner: 'N/A',
                    hydraulics: 'N/A',
                    listDamages: 'N/A',
                    maintenance: 'N/A',
                    makeModel:
                        makeModel, // Use the makeModel directly from Firestore
                    mileage: 'N/A',
                    oemInspection: 'N/A',
                    mainImageUrl: null,
                    photos: [],
                    registrationNumber: 'N/A',
                    roadWorthy: 'N/A',
                    settleBeforeSelling: 'N/A',
                    settlementAmount: 'N/A',
                    suspension: 'N/A',
                    transmission: 'N/A',
                    tyreType: 'N/A',
                    userId: 'N/A',
                    vehicleType: 'N/A',
                    vinNumber: 'N/A',
                    warranty: 'N/A',
                    warrantyType: 'N/A',
                    weightClass: 'N/A',
                    year: 'N/A',
                    createdAt: (vehicleDoc['createdAt'] as Timestamp).toDate(),
                    spareTyre: 'N/A',
                  ),
                );

                String imageUrl = data != null &&
                        data.containsKey('mainImageUrl') &&
                        data['mainImageUrl'] != null
                    ? data['mainImageUrl']
                    : 'lib/assets/default_vehicle_image.png';

                // Check if an offer exists for this vehicle
                bool hasOffer = _offerProvider.offers
                    .any((offer) => offer.vehicleId == vehicle.id);

                return WishCard(
                  vehicleMakeModel: vehicle.makeModel,
                  vehicleImageUrl: imageUrl,
                  size: size,
                  customFont:
                      (double fontSize, FontWeight fontWeight, Color color) {
                    return TextStyle(
                      fontSize: fontSize,
                      fontWeight: fontWeight,
                      color: color,
                      fontFamily: 'Montserrat',
                    );
                  },
                  hasOffer: hasOffer, // Pass the hasOffer value
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VehicleDetailsPage(vehicle: vehicle),
                      ),
                    );
                  },
                );
              }).toList(),
            ],
          );
        }
      },
    );
  }

  Widget _buildTabWithIcon(String tabName, String iconPath) {
    final isSelected = _selectedTab == tabName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tabName;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Image.asset(
                iconPath,
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
              Text(
                tabName.toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.blue : Colors.white,
                ),
              ),
            ],
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 2,
              width: 40,
              color: const Color(0xFFFF4E00),
            ),
        ],
      ),
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
