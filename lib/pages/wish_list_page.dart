import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ctp/components/wish_card.dart';
import 'vehicle_details_page.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/components/gradient_background.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  _WishlistPageState createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final List<DocumentSnapshot> _wishlistVehicles = [];
  String profileImageUrl = '';
  late Future<void> _fetchOffersFuture;
  late OfferProvider _offerProvider;

  String _selectedTab = 'Trucks';

  @override
  void initState() {
    super.initState();
    _offerProvider = Provider.of<OfferProvider>(context, listen: false);
    _fetchUserProfile();
    _fetchWishlist();
    _fetchOffersFuture = _fetchOffers();
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
          profileImageUrl = userDoc.get('profileImageUrl') ?? '';
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

  Future<void> _fetchOffers() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userRole = userProvider.getUserRole;

      await _offerProvider.fetchOffers(user.uid, userRole);
      setState(() {});
    }
  }

  List<DocumentSnapshot> _getFilteredVehicles() {
    return _wishlistVehicles.where((vehicleDoc) {
      Map<String, dynamic>? data = vehicleDoc.data() as Map<String, dynamic>?;

      if (_selectedTab == 'Trucks') {
        return data != null &&
            (data['vehicleType'] == 'truck' ||
                data['vehicleType'] == 'pickup' ||
                data['vehicleType'] == 'lorry');
      } else if (_selectedTab == 'Trailers') {
        return data != null &&
            (data['vehicleType'] == 'trailer' ||
                data['vehicleType'] == 'semi-trailer');
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    final vehicleProvider = Provider.of<VehicleProvider>(context);
    final offerProvider = _offerProvider;

    final filteredVehicles = _getFilteredVehicles();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const BlurryAppBar(),
      body: GradientBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: screenSize.height * 0.02),
                  Image.asset(
                    'lib/assets/CTPLogo.png',
                    height: screenSize.height * 0.2,
                    width: screenSize.height * 0.2,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: screenSize.height * 0.05),
                  const Text(
                    'WISHLIST',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.03),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTab('Trucks'),
                      SizedBox(width: screenSize.width * 0.06),
                      _buildTab('Trailers'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<void>(
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
                      itemCount: filteredVehicles.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot vehicleDoc = filteredVehicles[index];
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
                            vehicleType: _selectedTab.toLowerCase(),
                            vinNumber: 'N/A',
                            warranty: 'N/A',
                            warrantyType: 'N/A',
                            weightClass: 'N/A',
                            year: 'N/A',
                            createdAt:
                                (vehicleDoc['createdAt'] as Timestamp).toDate(),
                            spareTyre: 'N/A',
                            vehicleStatus: 'N/A',
                            vehicleAvailableImmediately: 'N/A',
                            availableDate: 'N/A',
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

                        // Debugging statement to check the offer status
                        print(
                            'Vehicle ID: ${vehicle.id}, Has Offer: $hasOffer');

                        return WishCard(
                          vehicleMakeModel: vehicle.makeModel,
                          vehicleImageUrl: imageUrl,
                          size: screenSize, // Use screenSize instead of size
                          customFont: (double fontSize, FontWeight fontWeight,
                              Color color) {
                            return TextStyle(
                              fontSize: fontSize,
                              fontWeight: fontWeight,
                              color: color,
                              fontFamily: 'Montserrat',
                            );
                          },
                          hasOffer: hasOffer, // Pass offer status to WishCard
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
                            // Remove the vehicle from Firestore 'likedVehicles' list
                            User? user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              DocumentReference userDocRef = FirebaseFirestore
                                  .instance
                                  .collection('users')
                                  .doc(user.uid);

                              await userDocRef.update({
                                'likedVehicles': FieldValue.arrayRemove([
                                  vehicleDoc.id
                                ]), // Remove vehicle ID from the array
                              });

                              // Remove the vehicle from the local wishlist
                              setState(() {
                                _wishlistVehicles.remove(
                                    vehicleDoc); // Remove vehicle locally
                              });

                              // Show a confirmation snackbar
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
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: 3,
        onItemTapped: (index) {
          setState(() {
            // Handle navigation here
          });
        },
      ),
    );
  }

  Widget _buildTab(String tabName) {
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
          Text(
            tabName.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.blue : Colors.white,
            ),
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
}
