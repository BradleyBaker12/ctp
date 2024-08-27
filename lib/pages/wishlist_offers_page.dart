import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/offer_card.dart';
import 'package:ctp/pages/home_page.dart';
import 'package:ctp/pages/profile_page.dart';
import 'package:ctp/pages/truck_page.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ctp/components/wish_card.dart';
import 'vehicle_details_page.dart'; // Import the VehicleDetailsPage
import 'package:ctp/providers/vehicles_provider.dart'; // Import the VehicleProvider
import 'package:provider/provider.dart'; // Import Provider
import 'package:ctp/providers/offer_provider.dart'; // Import OfferProvider

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
      backgroundColor: Colors.black,
      appBar: const BlurryAppBar(), // Use BlurryAppBar as background
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 300, // Increased height for larger image
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                    'lib/assets/WishListImage.png'), // Add your header image path here
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center the headings
              children: [
                const Text(
                  'WHISHLIST AND OFFERS',
                  style: TextStyle(
                    color: Color(0xFFFF4E00),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'View your wish listed trucks and track your pending offers made.',
                  style: TextStyle(
                    color: Colors.white, // Adjust the color to match the design
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
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
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _selectedTab == 'Pending Offers'
                ? _buildPendingOffersSection()
                : _buildWishlistSection(size, vehicleProvider, userRole),
          ),
        ],
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
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: latestOffers.length,
            itemBuilder: (context, index) {
              Offer offer = latestOffers[index];
              return OfferCard(
                offer: offer,
              );
            },
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
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _wishlistVehicles.length,
            itemBuilder: (context, index) {
              DocumentSnapshot vehicleDoc = _wishlistVehicles[index];
              Map<String, dynamic>? data =
                  vehicleDoc.data() as Map<String, dynamic>?;
              Vehicle vehicle = vehicleProvider.vehicles.firstWhere(
                  (v) => v.id == vehicleDoc.id,
                  orElse: () => Vehicle(
                      id: 'default',
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
                      makeModel: 'Unknown',
                      mileage: 'N/A',
                      oemInspection: 'N/A',
                      photos: [],
                      registrationNumber: 'N/A',
                      roadWorthy: 'N/A',
                      settleBeforeSelling: 'N/A',
                      settlementAmount: 'N/A',
                      spareTyre: 'N/A',
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
                      createdAt: (vehicleDoc['createdAt'] as Timestamp)
                          .toDate())); // Default if not found

              String imageUrl = data != null &&
                      data.containsKey('mainImageUrl') &&
                      data['mainImageUrl'] != null
                  ? data['mainImageUrl']
                  : 'lib/assets/default_vehicle_image.png';

              // Check if an offer exists for this vehicle
              bool hasOffer = _offerProvider.offers
                  .any((offer) => offer.vehicleId == vehicle.id);

              return WishCard(
                vehicleMakeModel: data != null && data.containsKey('makeModel')
                    ? data['makeModel']
                    : 'Unknown',
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
            },
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
