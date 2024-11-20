import 'package:ctp/models/admin_data.dart';
import 'package:ctp/models/chassis.dart';
import 'package:ctp/models/drive_train.dart';
import 'package:ctp/models/external_cab.dart';
import 'package:ctp/models/internal_cab.dart';
import 'package:ctp/models/maintenance.dart';
import 'package:ctp/models/maintenance_data.dart';
import 'package:ctp/models/truck_conditions.dart';
import 'package:ctp/models/tyres.dart';
import 'package:ctp/models/vehicle.dart';
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
    _fetchOffersFuture = _fetchOffers(); // Moved initialization here
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
        QuerySnapshot vehiclesSnapshot = await FirebaseFirestore.instance
            .collection('vehicles')
            .where(FieldPath.documentId, whereIn: wishlistItems)
            .get();
        setState(() {
          _wishlistVehicles.addAll(vehiclesSnapshot.docs);
        });
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
                        width: 100,
                        height: 100,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Error fetching wishlist',
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
                            application: data != null && data['application'] != null
                                    ? data['application']
                                    : 'Unknown',
                            warrantyDetails: 'N/A',
                            damageDescription: '',
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
                            trailerType: 'N/A',
                            axles: 'N/A',
                            trailerLength: 'N/A',
                            adminData: AdminData(
                              settlementAmount: '0',
                              natisRc1Url: '',
                              licenseDiskUrl: '',
                              settlementLetterUrl: '',
                            ),
                            maintenance: Maintenance(
                              maintenanceDocumentUrl: '',
                              warrantyDocumentUrl: '',
                              oemInspectionType: '',
                              oemInspectionReason: '',
                              updatedAt: DateTime.now(),
                              maintenanceData: MaintenanceData(
                                vehicleId: vehicleDoc.id,
                                oemInspectionType: '',
                                oemReason: '',
                              ),
                              warrantySelection: '',
                            ),
                            truckConditions: TruckConditions(
                              externalCab: ExternalCab(
                                selectedCondition: '',
                                anyDamages: '',
                                anyAdditionalFeatures: '',
                                photos: {
                                  'FRONT VIEW': '',
                                  'RIGHT SIDE VIEW': '',
                                  'REAR VIEW': '',
                                  'LEFT SIDE VIEW': '',
                                },
                                lastUpdated: DateTime.now(),
                                damages: [],
                                additionalFeatures: [],
                              ),
                              internalCab: InternalCab(
                                condition: '',
                                oemInspectionType: '',
                                oemInspectionReason: '',
                                lastUpdated: DateTime.now(),
                                photos: {
                                  'Center Dash': '',
                                  'Left Dash': '',
                                  'Right Dash (Vehicle On)': '',
                                  'Mileage': '',
                                  'Sun Visors': '',
                                  'Center Console': '',
                                  'Steering': '',
                                  'Left Door Panel': '',
                                  'Left Seat': '',
                                  'Roof': '',
                                  'Bunk Beds': '',
                                  'Rear Panel': '',
                                  'Right Door Panel': '',
                                  'Right Seat': '',
                                },
                                damages: [],
                                additionalFeatures: [],
                                faultCodes: [],
                              ),
                              chassis: Chassis(
                                condition: '',
                                damagesCondition: '',
                                additionalFeaturesCondition: '',
                                photos: {
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
                                lastUpdated: DateTime.now(),
                                damages: [],
                                additionalFeatures: [],
                                faultCodes: [],
                              ),
                              driveTrain: DriveTrain(
                                condition: '',
                                oilLeakConditionEngine: '',
                                waterLeakConditionEngine: '',
                                blowbyCondition: '',
                                oilLeakConditionGearbox: '',
                                retarderCondition: '',
                                lastUpdated: DateTime.now(),
                                photos: {
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
                                ),
                              },
                            ),
                            vehicleStatus: 'N/A',
                            dashboardPhoto: '',
                            faultCodesPhoto: '',
                            licenceDiskUrl: '',
                            mileageImage: '',
                            rc1NatisFile: '',
                            config: '',
                            referenceNumber: '',
                            brands: [],
                            country: '',
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
                                'likedVehicles':
                                    FieldValue.arrayRemove([vehicleDoc.id]),
                              });

                              // Remove the vehicle from the local wishlist
                              setState(() {
                                _wishlistVehicles.remove(vehicleDoc);
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
