import 'package:ctp/models/admin_data.dart';
import 'package:ctp/models/chassis.dart';
import 'package:ctp/models/drive_train.dart';
import 'package:ctp/models/external_cab.dart';
import 'package:ctp/models/internal_cab.dart';
import 'package:ctp/models/maintenance.dart';
import 'package:ctp/models/truck_conditions.dart';
import 'package:ctp/models/tyres.dart';
import 'package:ctp/models/vehicle.dart';
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
import 'package:ctp/utils/navigation.dart';

class WishlistOffersPage extends StatefulWidget {
  const WishlistOffersPage({super.key});

  @override
  _WishlistOffersPageState createState() => _WishlistOffersPageState();
}

class _WishlistOffersPageState extends State<WishlistOffersPage> {
  final List<DocumentSnapshot> _wishlistVehicles = [];
  late Future<void> _fetchDataFuture;
  late OfferProvider _offerProvider;

  @override
  void initState() {
    super.initState();
    _offerProvider = Provider.of<OfferProvider>(context, listen: false);
    _fetchDataFuture = _fetchData();
  }

  Future<void> _fetchData() async {
    await _fetchWishlist();
    await _fetchOffers();
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
      }
    }
  }

  Future<void> _fetchOffers() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userRole = userProvider.getUserRole;

      await _offerProvider.fetchOffers(user.uid, userRole);
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
                  'View your wishlisted trucks below or click on View More to see the trucks and trailers respectively.',
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
                onPressed: () async {
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
                future: _fetchDataFuture,
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
                        'No Liked Vehicles',
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
                            application:
                                data != null && data['application'] != null
                                    ? data['application']
                                    : 'Unknown',
                            brands: [],
                            referenceNumber: 'N/A',
                            warrantyDetails: 'N/A',
                            damageDescription: '',
                            isAccepted: false,
                            acceptedOfferId: 'N/A',
                            damagePhotos: [],
                            engineNumber: 'N/A',
                            expectedSellingPrice: 'N/A',
                            hydraluicType: 'N/A',

                            makeModel: data != null && data['makeModel'] != null
                                ? data['makeModel']
                                : 'Unknown',
                            mileage: 'N/A',
                            mainImageUrl: null,
                            photos: [],
                            registrationNumber: 'N/A',
                            suspensionType: 'N/A',
                            transmissionType: 'N/A',
                            userId: 'N/A',
                            vehicleType: data != null
                                ? data['vehicleType'].toLowerCase()
                                : 'unknown',
                            vinNumber: 'N/A',
                            warrentyType: 'N/A',
                            year: data != null && data['year'] != null
                                ? data['year']
                                : 'Unknown',
                            createdAt:
                                (vehicleDoc['createdAt'] as Timestamp).toDate(),
                            vehicleAvailableImmediately: 'N/A',
                            availableDate: 'N/A',
                            // Provide default or empty instances for required nested fields
                            adminData: AdminData(
                              settlementAmount: '0',
                              natisRc1Url: '',
                              licenseDiskUrl: '',
                              settlementLetterUrl: '',
                            ),
                            maintenance: Maintenance(
                              vehicleId: vehicleDoc.id,
                              oemInspectionType: '',
                              maintenanceDocUrl: '',
                              warrantyDocUrl: '',
                              maintenanceSelection: '',
                              warrantySelection: '',
                              lastUpdated: DateTime.now(),
                            ),
                            truckConditions: TruckConditions(
                              externalCab: ExternalCab(
                                damages: [],
                                additionalFeatures: [],
                                condition: '',
                                damagesCondition: '',
                                additionalFeaturesCondition: '',
                                images: {},
                              ),
                              internalCab: InternalCab(
                                  condition: '',
                                  damagesCondition: '',
                                  additionalFeaturesCondition: '',
                                  faultCodesCondition: '',
                                  viewImages: {},
                                  damages: [],
                                  additionalFeatures: [],
                                  faultCodes: []),
                              chassis: Chassis(
                                  condition: '',
                                  damagesCondition: '',
                                  additionalFeaturesCondition: '',
                                  images: {},
                                  damages: [],
                                  additionalFeatures: []),
                              driveTrain: DriveTrain(
                                condition: '',
                                oilLeakConditionEngine: '',
                                waterLeakConditionEngine: '',
                                blowbyCondition: '',
                                oilLeakConditionGearbox: '',
                                retarderCondition: '',
                                lastUpdated: DateTime.now(),
                                images: {
                                  'Right Brake': '',
                                  'Left Brake': '',
                                  'Front Axel': '',
                                  'Suspension': '',
                                  'Fuel Tank': '',
                                  'Battery': '',
                                  'Cat Walk': '',
                                  'Electrical Cable Black': '',
                                  'Air Cable Yellow': '',
                                  'Air Cable Red': '',
                                  'Tail Board': '',
                                  '5th Wheel': '',
                                  'Left Brake Rear Axel': '',
                                  'Right Brake Rear Axel': '',
                                },
                                damages: [],
                                additionalFeatures: [],
                                faultCodes: [],
                              ),
                              tyres: {
                                'default': Tyres(
                                  lastUpdated: DateTime.now(),
                                  positions: {},
                                )
                              },
                            ),
                            vehicleStatus: 'N/A',
                            dashboardPhoto: '',
                            faultCodesPhoto: '',
                            licenceDiskUrl: '',
                            mileageImage: '',
                            rc1NatisFile: '',
                            config: '',
                            country: '',
                            province: '',
                            damagesDescription: '',
                            additionalFeatures: '',
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
                          vehicleMakeModel: vehicle.makeModel.toString(),
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
                          onTap: () async {
                            await MyNavigator.push(
                              context,
                              VehicleDetailsPage(
                                vehicle: vehicle,
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
                          vehicle: vehicle,
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
          onItemTapped: (index) async {
            if (index == 0) {
              await MyNavigator.pushReplacement(context, const HomePage());
            } else if (index == 1) {
              await MyNavigator.pushReplacement(context, const TruckPage());
            } else if (index == 2) {
              await MyNavigator.pushReplacement(
                  context, const WishlistOffersPage());
            } else if (index == 3) {
              await MyNavigator.pushReplacement(context, const OffersPage());
            }
          },
        ),
      ),
    );
  }
}
