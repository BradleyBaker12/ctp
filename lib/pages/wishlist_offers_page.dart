import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/pages/pending_offers_page.dart';
import 'package:ctp/pages/wish_list_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/offer_card.dart';
import 'package:ctp/components/wish_card.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

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

  @override
  void initState() {
    super.initState();
    _fetchOffersFuture = _fetchOffers();
    _fetchWishlistFuture = _fetchWishlist();
  }

  Future<void> _fetchOffers() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _offerProvider.fetchOffers(user.uid);
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
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: BlurryAppBar(
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('lib/assets/CTPLogo.png'),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundImage: userProvider.getProfileImageUrl.isNotEmpty
                      ? NetworkImage(userProvider.getProfileImageUrl)
                      : const AssetImage('lib/assets/default_profile_photo.jpg')
                          as ImageProvider,
                  onBackgroundImageError: (_, __) =>
                      Image.asset('lib/assets/default_profile_photo.jpg'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Center the content
          children: [
            Container(
              width: double.infinity,
              height: 300, // Increased height for larger image
              decoration: BoxDecoration(
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
                    'Wishlist and Offers',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'View your wish listed trucks and track your pending offers made.',
                    style: TextStyle(
                      color:
                          Colors.white, // Adjust the color to match the design
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(
                      'Pending Offers', 'lib/assets/shaking_hands.png'),
                  const SizedBox(height: 8),
                  _buildViewAllLink(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PendingOffersPage()),
                    );
                  }),
                  FutureBuilder<void>(
                    future: _fetchOffersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text(
                          'Error fetching offers',
                          style:
                              _customFont(16, FontWeight.normal, Colors.black),
                        );
                      } else {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _offerProvider.offers.length,
                          itemBuilder: (context, index) {
                            Offer offer = _offerProvider.offers[index];
                            return OfferCard(
                              offer: offer,
                              size: size,
                              customFont: _customFont,
                            );
                          },
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Wishlist', 'lib/assets/HeartVector.png'),
                  const SizedBox(height: 8),
                  _buildViewAllLink(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const WishlistPage()),
                    );
                  }),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _wishlistVehicles.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot vehicleDoc = _wishlistVehicles[index];
                      return WishCard(
                        vehicleMakeModel:
                            vehicleDoc.get('makeModel') ?? 'Unknown',
                        vehicleImageUrl: vehicleDoc.get('mainImageUrl') ??
                            'lib/assets/default_vehicle_image.png',
                        size: size,
                        customFont: _customFont,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: 2,
        onItemTapped: (index) {},
      ),
    );
  }

  Widget _buildSectionTitle(String title, String imagePath) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // Center the title and image
      children: [
        Image.asset(
          imagePath,
          width: 24,
          height: 24,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildViewAllLink(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'View all',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              decoration: TextDecoration.underline,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_forward,
            color: Colors.white,
            size: 16,
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

class BlurryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? child;
  final double height;

  const BlurryAppBar({super.key, this.height = kToolbarHeight, this.child});

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          color: Colors.black.withOpacity(0.2),
          child: SafeArea(
            child: SizedBox(
              height: height,
              width: screenSize.width,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
