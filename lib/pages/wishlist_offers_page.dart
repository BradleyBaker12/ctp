import 'package:ctp/components/custom_app_bar.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/pages/home_page.dart';
import 'package:ctp/pages/offersPage.dart';
import 'package:ctp/pages/profile_page.dart';
import 'package:ctp/pages/truck_page.dart';
import 'package:ctp/pages/wish_list_page.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ctp/components/wish_card.dart';
import 'vehicle_details_page.dart'; // Import the VehicleDetailsPage
import 'package:ctp/providers/vehicles_provider.dart'; // Import VehicleProvider
import 'package:provider/provider.dart'; // Import Provider
import 'package:ctp/providers/offer_provider.dart'; // Import OfferProvider
import 'package:ctp/components/gradient_background.dart'; // Import the GradientBackground

class WishlistOffersPage extends StatefulWidget {
  const WishlistOffersPage({super.key});

  @override
  _WishlistOffersPageState createState() => _WishlistOffersPageState();
}

class _WishlistOffersPageState extends State<WishlistOffersPage> {
  late Future<void> _fetchWishlistFuture;
  final OfferProvider _offerProvider = OfferProvider();
  final List<Map<String, dynamic>> _wishlistVehicles = [];

  @override
  void initState() {
    super.initState();
    _fetchWishlistFuture = _fetchWishlist();
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

          bool hasOffer = false;
          // Check if there is an active offer for this vehicle
          QuerySnapshot offerSnapshot = await FirebaseFirestore.instance
              .collection('offers')
              .where('vehicleId', isEqualTo: vehicleId)
              .where('status',
                  isEqualTo: 'active') // Example condition for active offers
              .get();

          if (offerSnapshot.docs.isNotEmpty) {
            hasOffer = true;
          }

          if (vehicleDoc.exists) {
            _wishlistVehicles.add({
              'vehicleDoc': vehicleDoc,
              'hasOffer': hasOffer, // Pass offer status to the map
            });
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

    return GradientBackground(
      child: Scaffold(
        backgroundColor:
            Colors.transparent, // Make scaffold background transparent
        appBar: CustomAppBar(),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(
                height: 40,
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite, // Heart icon
                    color: Colors.red,
                    size: 30,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'WISHLIST',
                    style: TextStyle(
                      color: Color(0xFFFF4E00),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ), // Space between text and icon
                ],
              ),
              const SizedBox(
                width: 350,
                child: Text(
                  'View your wish listed trucks.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              _buildWishlistSection(size, vehicleProvider, userRole),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNavigation(
          selectedIndex: 3, // Ensure the heart icon is selected
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
              // Check if the user is a dealer and navigate to the OffersPage
              if (userRole == 'dealer') {
                if (ModalRoute.of(context)?.settings.name != '/offers') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const OffersPage(),
                        settings: const RouteSettings(name: '/offers')),
                  );
                }
              } else {
                if (ModalRoute.of(context)?.settings.name != '/profile') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                        settings: const RouteSettings(name: '/profile')),
                  );
                }
              }
            }
          },
        ),
      ),
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
                      child: const Row(
                        children: [
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
              ..._wishlistVehicles.map((vehicleData) {
                DocumentSnapshot vehicleDoc = vehicleData['vehicleDoc'];
                bool hasOffer = vehicleData['hasOffer']; // Extract offer status

                Map<String, dynamic>? data =
                    vehicleDoc.data() as Map<String, dynamic>?;

                String makeModel = data != null &&
                        data.containsKey('makeModel') &&
                        data['makeModel'] != null
                    ? data['makeModel']
                    : 'Unknown';

                Vehicle vehicle = Vehicle(
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
                  makeModel: makeModel,
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
                );

                String imageUrl = data != null &&
                        data.containsKey('mainImageUrl') &&
                        data['mainImageUrl'] != null
                    ? data['mainImageUrl']
                    : 'lib/assets/default_vehicle_image.png';

                // Inside your buildWishlistSection or ListView.builder where WishCard is used
                // Inside your buildWishlistSection or ListView.builder where WishCard is used
                return Dismissible(
                  key: Key(vehicleDoc.id), // Use a unique key for each vehicle
                  direction:
                      DismissDirection.endToStart, // Swipe left to delete
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) async {
                    // Immediately remove the item from the list to avoid the widget staying in the tree
                    setState(() {
                      // Ensure the item is properly removed from the list
                      _wishlistVehicles.removeWhere((vehicle) =>
                          vehicle['vehicleDoc'].id == vehicleDoc.id);
                    });

                    // Handle deletion from Firestore (async)
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      DocumentReference userDocRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid);

                      await userDocRef.update({
                        'likedVehicles':
                            FieldValue.arrayRemove([vehicleDoc.id]),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '${vehicle.makeModel} removed from wishlist.'),
                        ),
                      );
                    }
                  },
                  child: WishCard(
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
                    hasOffer: hasOffer,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VehicleDetailsPage(vehicle: vehicle),
                        ),
                      );
                    },
                    onDelete: () async {
                      // This handles the delete button functionality in the card itself (optional)
                      User? user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        DocumentReference userDocRef = FirebaseFirestore
                            .instance
                            .collection('users')
                            .doc(user.uid);

                        await userDocRef.update({
                          'likedVehicles':
                              FieldValue.arrayRemove([vehicleDoc.id]),
                        });

                        setState(() {
                          _wishlistVehicles.removeWhere((vehicle) =>
                              vehicle['vehicleDoc'].id == vehicleDoc.id);
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${vehicle.makeModel} removed from wishlist.'),
                          ),
                        );
                      }
                    }, vehicleId: vehicle.id,
                  ),
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
