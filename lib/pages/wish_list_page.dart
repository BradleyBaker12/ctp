import 'package:ctp/models/admin_data.dart';
import 'package:ctp/models/chassis.dart';
import 'package:ctp/models/drive_train.dart';
import 'package:ctp/models/external_cab.dart';
import 'package:ctp/models/internal_cab.dart';
import 'package:ctp/models/maintenance.dart';
import 'package:ctp/models/truck_conditions.dart';
import 'package:ctp/models/tyres.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/custom_app_bar.dart';
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

  // State variable to manage selected tab
  String _selectedTab = 'Trucks';

  // Lists to hold filtered vehicles
  List<DocumentSnapshot> _trucks = [];
  List<DocumentSnapshot> _trailers = [];

  @override
  void initState() {
    super.initState();
    _offerProvider = Provider.of<OfferProvider>(context, listen: false);
    _fetchOffersFuture =
        Future.wait([_fetchUserProfile(), _fetchWishlist(), _fetchOffers()]);
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
        if (wishlistItems.isNotEmpty) {
          // Firestore's 'whereIn' can handle a maximum of 10 items. Handle accordingly.
          // Split the wishlistItems into chunks of 10.
          List<List<String>> chunks = [];
          const int chunkSize = 10;
          for (var i = 0; i < wishlistItems.length; i += chunkSize) {
            chunks.add(
                wishlistItems.skip(i).take(chunkSize).toList(growable: false));
          }

          List<DocumentSnapshot> allDocs = [];

          for (var chunk in chunks) {
            QuerySnapshot snapshot = await FirebaseFirestore.instance
                .collection('vehicles')
                .where(FieldPath.documentId, whereIn: chunk)
                .get();
            allDocs.addAll(snapshot.docs);
          }

          final vehicleProvider =
              Provider.of<VehicleProvider>(context, listen: false);

          for (var doc in allDocs) {
            Vehicle vehicle = Vehicle.fromFirestore(
                doc.id, doc.data() as Map<String, dynamic>);
            vehicleProvider.addVehicle(vehicle);
          }

          setState(() {
            _wishlistVehicles.addAll(allDocs);
            _trucks = _wishlistVehicles.where((vehicleDoc) {
              Map<String, dynamic>? data =
                  vehicleDoc.data() as Map<String, dynamic>?;
              return data != null &&
                  (data['vehicleType'] == 'truck' ||
                      data['vehicleType'] == 'pickup' ||
                      data['vehicleType'] == 'lorry');
            }).toList();

            _trailers = _wishlistVehicles.where((vehicleDoc) {
              Map<String, dynamic>? data =
                  vehicleDoc.data() as Map<String, dynamic>?;
              return data != null &&
                  (data['vehicleType'] == 'trailer' ||
                      data['vehicleType'] == 'semi-trailer');
            }).toList();
          });
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

  // Method to build the custom tabs with black and blue blocks
  Widget _buildCustomTabs(Size screenSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTabButton('Trucks', 'Trucks'),
        SizedBox(width: screenSize.width * 0.02),
        _buildTabButton('Trailers', 'Trailers'),
      ],
    );
  }

  // Helper method to create a custom tab button
  Widget _buildTabButton(String title, String tab) {
    bool isSelected = _selectedTab == tab;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tab;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange : Colors.black,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.blue,
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            // Colored block (if any) can be customized here
            // Removed the dot as per your request
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method to build the list of vehicles based on the selected tab
  Widget _buildVehicleList(
    List<DocumentSnapshot> vehicles,
    VehicleProvider vehicleProvider,
    OfferProvider offerProvider,
    Size screenSize,
  ) {
    if (vehicles.isEmpty) {
      return Center(
        child: Text(
          'No vehicles found.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        DocumentSnapshot vehicleDoc = vehicles[index];
        Map<String, dynamic>? data = vehicleDoc.data() as Map<String, dynamic>?;
        Vehicle vehicle = vehicleProvider.vehicles.firstWhere(
          (v) => v.id == vehicleDoc.id,
          orElse: () => Vehicle(
            id: vehicleDoc.id,
            application: data != null && data['application'] != null
                ? (data['application'] is String
                    ? [data['application']]
                    : List<String>.from(data['application']))
                : [],
            warrantyDetails: 'N/A',
            isAccepted: false,
            acceptedOfferId: 'N/A',
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
            vehicleType:
                data != null ? data['vehicleType'].toLowerCase() : 'unknown',
            vinNumber: 'N/A',
            warrentyType: 'N/A',
            year:
                data != null && data['year'] != null ? data['year'] : 'Unknown',
            createdAt: (vehicleDoc['createdAt'] as Timestamp).toDate(),
            vehicleAvailableImmediately: 'N/A',
            availableDate: 'N/A',
            trailerType: 'N/A',
            axles: 'N/A',
            trailerLength: 'N/A',
            dashboardPhoto: '',
            faultCodesPhoto: '',
            licenceDiskUrl: '',
            mileageImage: '',
            rc1NatisFile: '',
            config: '',
            referenceNumber: '',
            brands: [],
            country: '',
            province: '',
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
                ),
              },
            ),
            vehicleStatus: '',
            length: '',
            vinTrailer: '',
            damagesDescription: '',
            additionalFeatures: '',
          ),
        );

        bool hasOffer =
            offerProvider.offers.any((offer) => offer.vehicleId == vehicle.id);

        return WishCard(
          vehicleMakeModel: "${vehicle.makeModel} ${vehicle.year}",
          vehicleImageUrl: vehicle.mainImageUrl != null
              ? vehicle.mainImageUrl!
              : 'lib/assets/default_vehicle_image.png',
          size: screenSize,
          customFont: (double fontSize, FontWeight fontWeight, Color color) {
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
                builder: (context) => VehicleDetailsPage(vehicle: vehicle),
              ),
            );
          },
          onDelete: () async {
            User? user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update({
                'likedVehicles': FieldValue.arrayRemove([vehicle.id])
              });
              setState(() {
                _wishlistVehicles.remove(vehicleDoc);
                if (_selectedTab == 'Trucks') {
                  _trucks.remove(vehicleDoc);
                } else {
                  _trailers.remove(vehicleDoc);
                }
              });
            }
          },
          vehicleId: vehicle.id,
          vehicle: vehicle,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    final vehicleProvider = Provider.of<VehicleProvider>(context);
    final offerProvider = _offerProvider;

    // Determine which list to display based on the selected tab
    List<DocumentSnapshot> currentList =
        _selectedTab == 'Trucks' ? _trucks : _trailers;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const CustomAppBar(),
        body: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: screenSize.height * 0.05),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'lib/assets/HeartVector.png',
                        width: 30,
                        height: 30,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'WISHLIST',
                        style: TextStyle(
                          color: Color(0xFFFF4E00),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  SizedBox(height: screenSize.height * 0.03),
                  // Custom Tabs
                  _buildCustomTabs(screenSize),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Vehicle List Section
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
                    return _buildVehicleList(
                      currentList,
                      vehicleProvider,
                      offerProvider,
                      screenSize,
                    );
                  }
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavigation(
          selectedIndex: 3,
          onItemTapped: (index) {
            setState(() {
              // Handle navigation here
            });
          },
        ),
      ),
    );
  }
}
