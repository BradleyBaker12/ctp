import 'package:ctp/pages/truck_page.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/custom_app_bar.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/pages/home_page.dart';
import 'package:ctp/pages/offersPage.dart';
import 'package:ctp/pages/wish_list_page.dart'; // Import the WishlistPage
import 'package:ctp/providers/user_provider.dart';
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
  final List<DocumentSnapshot> _wishlistVehicles = [];
  late Future<void> _fetchOffersFuture;
  late OfferProvider _offerProvider;

  @override
  void initState() {
    super.initState();
    _offerProvider = Provider.of<OfferProvider>(context, listen: false);
    _fetchWishlist();
    _fetchOffersFuture = _fetchOffers();
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

  Future<void> _fetchOffers() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userRole = userProvider.getUserRole;

      await _offerProvider.fetchOffers(user.uid, userRole);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    final vehicleProvider = Provider.of<VehicleProvider>(context);
    final offerProvider = _offerProvider;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(
                height: 40,
              ),
              // Row to include both the "WISHLIST" text and the heart icon
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
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 370,
                child: Text(
                  'View your wish listed trucks below or click on view more to see the trucks and trailer respectively.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Text Button for "View More"
              TextButton(
                onPressed: () {
                  // Navigate to the WishlistPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WishlistPage()),
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
              const SizedBox(height: 24),
              FutureBuilder<void>(
                future: _fetchOffersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Image.asset(
                        'lib/assets/Loading_Logo_CTP.gif',
                        width:
                            100, // You can adjust the width and height as needed
                        height: 100,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Error fetching offers',
                        style: TextStyle(color: Colors.red),
                      ),
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
                            makeModel: data != null && data['makeModel'] != null
                                ? data['makeModel']
                                : 'Unknown',
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
                            vehicleType: data != null
                                ? data['vehicleType'].toLowerCase()
                                : 'unknown',
                            vinNumber: 'N/A',
                            warranty: 'N/A',
                            warrantyType: 'N/A',
                            weightClass: 'N/A',
                            year: 'N/A',
                            createdAt:
                                (vehicleDoc['createdAt'] as Timestamp).toDate(),
                            spareTyre: 'N/A', vehicleStatus: 'N/A', vehicleAvailableImmediately: 'N/A', availableDate: 'N/A',
                          ),
                        );

                        String imageUrl = data != null &&
                                data.containsKey('mainImageUrl') &&
                                data['mainImageUrl'] != null
                            ? data['mainImageUrl']
                            : 'lib/assets/default_vehicle_image.png';

                        // Check if there's an offer for this vehicle
                        bool hasOffer = offerProvider.offers
                            .any((offer) => offer.vehicleId == vehicle.id);

                        return WishCard(
                          vehicleMakeModel: vehicle.makeModel,
                          vehicleImageUrl: imageUrl,
                          size: screenSize,
                          customFont: (double fontSize, FontWeight fontWeight,
                              Color color) {
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
                                _wishlistVehicles.remove(vehicleDoc);
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${vehicle.makeModel} removed from wishlist.'),
                                ),
                              );
                            }
                          },
                          vehicleId: vehicle.id,
                        );
                      },
                    );
                  }
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNavigation(
          selectedIndex: 3,
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
                MaterialPageRoute(builder: (context) => const OffersPage()),
              );
            }
          },
        ),
      ),
    );
  }
}
