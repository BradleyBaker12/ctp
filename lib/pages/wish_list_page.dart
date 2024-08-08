import 'package:ctp/components/blurry_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ctp/components/wish_card.dart';
import 'vehicle_details_page.dart'; // Import the VehicleDetailsPage
import 'package:ctp/providers/vehicles_provider.dart'; // Import the VehicleProvider
import 'package:provider/provider.dart'; // Import Provider

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  _WishlistPageState createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final List<DocumentSnapshot> _wishlistVehicles = [];
  String profileImageUrl = ''; // Profile image URL

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchWishlist();
  }

  Future<void> _fetchUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        setState(() {
          profileImageUrl =
              userDoc.get('profileImageUrl') ?? ''; // Fetch profile image URL
        });
      }
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: BlurryAppBar(), // Use BlurryAppBar as background
      body: Column(
        children: [
          // Custom AppBar content
          Container(
            color: Colors.black.withOpacity(0.2),
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset('lib/assets/CTPLogo.png', height: 40),
                CircleAvatar(
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : AssetImage('lib/assets/default_profile_image.png')
                          as ImageProvider,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Wishlist',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _wishlistVehicles.length,
                          itemBuilder: (context, index) {
                            DocumentSnapshot vehicleDoc =
                                _wishlistVehicles[index];
                            Map<String, dynamic>? data =
                                vehicleDoc.data() as Map<String, dynamic>?;
                            Vehicle vehicle = vehicleProvider.vehicles
                                .firstWhere((v) =>
                                    v.id ==
                                    vehicleDoc
                                        .id); // Find the vehicle from provider
                            String imageUrl = data != null &&
                                    data.containsKey('mainImageUrl') &&
                                    data['mainImageUrl'] != null
                                ? data['mainImageUrl']
                                : 'lib/assets/default_vehicle_image.png';
                            return WishCard(
                              vehicleMakeModel:
                                  data != null && data.containsKey('makeModel')
                                      ? data['makeModel']
                                      : 'Unknown',
                              vehicleImageUrl: imageUrl,
                              size: size,
                              customFont: (double fontSize,
                                  FontWeight fontWeight, Color color) {
                                return TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: fontWeight,
                                  color: color,
                                  fontFamily: 'Montserrat',
                                );
                              },
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
