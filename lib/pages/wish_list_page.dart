import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ctp/components/wish_card.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  _WishlistPageState createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final List<DocumentSnapshot> _wishlistVehicles = [];

  @override
  void initState() {
    super.initState();
    _fetchWishlist();
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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('lib/assets/CTPLogo.png'),
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
                      DocumentSnapshot vehicleDoc = _wishlistVehicles[index];
                      return WishCard(
                        vehicleMakeModel:
                            vehicleDoc.get('makeModel') ?? 'Unknown',
                        vehicleImageUrl: vehicleDoc.get('mainImageUrl') ??
                            'lib/assets/default_vehicle_image.png',
                        size: size,
                        customFont: (double fontSize, FontWeight fontWeight,
                            Color color) {
                          return TextStyle(
                            fontSize: fontSize,
                            fontWeight: fontWeight,
                            color: color,
                            fontFamily: 'Montserrat',
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
    );
  }
}
