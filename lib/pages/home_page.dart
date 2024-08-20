import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/offer_card.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'dart:ui';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late AppinioSwiperController controller;
  int _selectedIndex = 0;
  late Future<void> _initialization;

  final OfferProvider _offerProvider = OfferProvider();
  bool _showSwiper = true; // Initially, show the swiper
  bool _showEndMessage = false; // Control to show the end message
  late List<String> likedVehicles;
  late List<String> dislikedVehicles;

  @override
  void initState() {
    super.initState();
    controller = AppinioSwiperController();

    _initialization = _initializeData();
    _checkPaymentStatusForOffers();
  }

  Future<void> _initializeData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);

    try {
      // Fetch user data
      await userProvider.fetchUserData();

      // Fetch vehicles
      await vehicleProvider.fetchVehicles();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userRole = userProvider.getUserRole;
        await _offerProvider.fetchOffers(user.uid, userRole);

        // Get liked and disliked vehicles from the user provider
        likedVehicles = userProvider.getLikedVehicles;
        dislikedVehicles = userProvider.getDislikedVehicles;
      }
    } catch (e, stackTrace) {
      print('Error initializing data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize data. Please try again.')),
      );
      // Report error to Crashlytics
      await FirebaseCrashlytics.instance.recordError(e, stackTrace);
    }
  }

  Future<void> _checkPaymentStatusForOffers() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    for (var offer in _offerProvider.offers) {
      try {
        DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
            .collection('offers')
            .doc(offer.offerId)
            .get();

        if (offerSnapshot.exists) {
          String paymentStatus = offerSnapshot['paymentStatus'];

          if (paymentStatus == 'accepted') {
            // Update the offer status to "Payment Approved"
            await FirebaseFirestore.instance
                .collection('offers')
                .doc(offer.offerId)
                .update({'offerStatus': 'paid'});

            // Optionally, refresh offers after updating status
            await _offerProvider.fetchOffers(
              userProvider.userId!,
              userProvider.getUserRole,
            );
          }
        }
      } catch (e, stackTrace) {
        print('Error checking payment status for offer ${offer.offerId}: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error checking payment status for one or more offers. Please try again later.'),
          ),
        );
        // Report error to Crashlytics
        await FirebaseCrashlytics.instance.recordError(e, stackTrace);
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  TextStyle _customFont(double fontSize, FontWeight fontWeight, Color color) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFamily: 'Montserrat',
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final imageHeight = size.height * 0.2;
    const orange = Color(0xFFFF4E00);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ),
        leading: Padding(
          padding: EdgeInsets.all(size.width * 0.02),
          child: Image.asset('lib/assets/CTPLogo.png'),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.all(size.width * 0.02),
            child: Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                final profileImageUrl = userProvider.getProfileImageUrl;
                return CircleAvatar(
                  radius: 20,
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : const AssetImage('lib/assets/default-profile-photo.jpg')
                          as ImageProvider,
                  onBackgroundImageError: (_, __) =>
                      Image.asset('lib/assets/default-profile-photo.jpg'),
                );
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializeData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error loading data',
                    style: _customFont(16, FontWeight.normal, Colors.white)));
          } else {
            return _buildHomePageContent(context, size, imageHeight, orange);
          }
        },
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildHomePageContent(
      BuildContext context, Size size, double imageHeight, Color orange) {
    final userProvider = Provider.of<UserProvider>(context);
    final vehicleProvider = Provider.of<VehicleProvider>(context);

    final userName = userProvider.getUserName;
    final userRole = userProvider.getUserRole;
    final profileImageUrl = userProvider.getProfileImageUrl;

    // Filter vehicles to exclude those in liked or disliked arrays and limit to 5 per day
    final recentTruckUploads = vehicleProvider.vehicles
        .where((vehicle) =>
            vehicle.vehicleType == 'truck' &&
            !likedVehicles.contains(vehicle.id) &&
            !dislikedVehicles.contains(vehicle.id))
        .take(5)
        .toList();

    final vehiclesWithOffers = vehicleProvider.vehicles.where((vehicle) {
      return _offerProvider.offers
          .any((offer) => offer.vehicleId == vehicle.id);
    }).toList();

    return Container(
      color: Colors.black,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Image.asset(
                  'lib/assets/HomePageHero.png',
                  width: size.width,
                  height: imageHeight * 2.6,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: imageHeight * 2.3,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'Welcome $userName',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF4E00),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Ready to steer your trading journey to success?",
                          textAlign: TextAlign.center,
                          style:
                              _customFont(16, FontWeight.normal, Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: size.width * 0.05),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            userRole == 'transporter'
                                ? "I’m selling a".toUpperCase()
                                : "I’m looking for".toLowerCase(),
                            style:
                                _customFont(18, FontWeight.bold, Colors.white),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (userRole == 'transporter') {
                                      Navigator.pushNamed(
                                        context,
                                        '/firstTruckForm',
                                        arguments: {'vehicleType': 'truck'},
                                      );
                                    } else if (userRole == 'dealer') {
                                      Navigator.pushNamed(
                                        context,
                                        '/searchTruck',
                                      );
                                    }
                                  },
                                  child: Container(
                                    height: size.height * 0.2,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.blue,
                                        width: 3,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.asset(
                                              'lib/assets/truck_image.png',
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Container(
                                            color: Colors.black54,
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              "TRUCKS",
                                              style: _customFont(18,
                                                  FontWeight.bold, Colors.blue),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (userRole == 'transporter') {
                                      Navigator.pushNamed(
                                        context,
                                        '/firstTruckForm',
                                        arguments: {'vehicleType': 'trailer'},
                                      );
                                    } else if (userRole == 'dealer') {
                                      Navigator.pushNamed(
                                        context,
                                        '/searchTrailer',
                                      );
                                    }
                                  },
                                  child: Container(
                                    height: size.height * 0.2,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: orange,
                                        width: 3,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: Image.asset(
                                              'lib/assets/trailer_image.png',
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Container(
                                            color: Colors.black54,
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              "TRAILERS",
                                              style: _customFont(
                                                  18, FontWeight.bold, orange),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // New Section: Preferred Brands
                  _buildPreferredBrandsSection(userProvider),
                  const SizedBox(height: 20),
                  // Conditional rendering based on user role
                  if (userRole == 'dealer' &&
                      _showSwiper &&
                      recentTruckUploads.isNotEmpty) ...[
                    Text(
                      "🔥 NEW ARRIVALS",
                      style: _customFont(18, FontWeight.bold, Colors.blue),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Discover the newest additions to our fleet, ready for your next venture.",
                      textAlign: TextAlign.center,
                      style: _customFont(16, FontWeight.normal, Colors.white),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: size.height * 0.6, // Adjust the height as needed
                      child: AppinioSwiper(
                        controller: controller,
                        cardCount: recentTruckUploads.length,
                        cardBuilder: (BuildContext context, int index) {
                          final vehicle = recentTruckUploads[index];
                          return _buildTruckCard(context, controller, vehicle);
                        },
                        onEnd: () {
                          setState(() {
                            _showEndMessage = true; // Show the end message
                            Future.delayed(const Duration(seconds: 2), () {
                              setState(() {
                                _showSwiper =
                                    false; // Hide the swiper after showing the message
                                _showEndMessage = false; // Hide the message
                              });
                            });
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (userRole == 'transporter' &&
                      vehiclesWithOffers.isNotEmpty) ...[
                    Text(
                      "YOUR VEHICLES WITH OFFERS",
                      style: _customFont(18, FontWeight.bold, Colors.white),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: size.height * 0.3,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: vehiclesWithOffers.length,
                        itemBuilder: (context, index) {
                          final vehicle = vehiclesWithOffers[index];
                          return _buildTransporterVehicleCard(vehicle, size);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (_showEndMessage)
                    Text(
                      "You have swiped through all the available trucks.",
                      style: _customFont(18, FontWeight.bold, Colors.white),
                    ),
                  const SizedBox(height: 10), // Reduce the gap here
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/pendingOffers');
                    },
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'lib/assets/shaking_hands.png',
                              width: 30,
                              height: 30,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'RECENT PENDING OFFERS',
                              style:
                                  _customFont(24, FontWeight.bold, Colors.blue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Track and manage your active trading offers here.',
                          style:
                              _customFont(16, FontWeight.normal, Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10), // Reduce the gap here
                      ],
                    ),
                  ),
                  // Offer cards section for both roles
                  FutureBuilder<void>(
                    future: _initialization,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text(
                          'Error fetching offers',
                          style:
                              _customFont(16, FontWeight.normal, Colors.white),
                        );
                      } else {
                        // Display offer cards for both transporters and dealers
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: vehiclesWithOffers.length,
                          itemBuilder: (context, index) {
                            final vehicle = vehiclesWithOffers[index];
                            final offer = _offerProvider.offers.firstWhere(
                                (offer) => offer.vehicleId == vehicle.id);
                            return OfferCard(
                              offer: offer,
                            );
                          },
                        );
                      }
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

  Widget _buildPreferredBrandsSection(UserProvider userProvider) {
    final preferredBrands = userProvider.getPreferredBrands;

    if (preferredBrands.isEmpty) {
      return Container(); // Return empty container if no brands are preferred
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CURRENT BRANDS',
              style: _customFont(18, FontWeight.bold, Colors.white),
            ),
            GestureDetector(
              onTap: () => _showEditBrandsDialog(userProvider),
              child: Text(
                'EDIT',
                style: _customFont(16, FontWeight.bold, Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 1.0), // Padding from the sides
          child: Divider(
            color: Colors.white, // Set the color of the divider
            thickness: 1.0, // Set the thickness of the divider
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center the logos horizontally
              children: preferredBrands.map((brand) {
                String logoPath;
                switch (brand) {
                  case 'DAF':
                    logoPath = 'lib/assets/Logo/DAF-removebg-preview.png';
                    break;
                  case 'Freightliner':
                    logoPath =
                        'lib/assets/Logo/Freightliner_Trucks_Red-removebg-preview.png';
                    break;
                  case 'International':
                    logoPath = 'lib/assets/Logo/Globe Emoji.png';
                    break;
                  case 'Iveco':
                    logoPath = 'lib/assets/Logo/Iveco 2023 New.png';
                    break;
                  case 'Kenworth':
                    logoPath =
                        'lib/assets/Logo/kenworth-red-logo-7q7yvcad0c7g543b-removebg-preview.png';
                    break;
                  case 'Mack':
                    logoPath = 'lib/assets/Logo/Mack Trucks.png';
                    break;
                  case 'Peterbilt':
                    logoPath = 'lib/assets/Logo/Peterbilt.png';
                    break;
                  case 'MAN':
                    logoPath =
                        'lib/assets/Logo/png-clipart-man-truck-bus-scania-ab-logo-man-se-truck-angle-text-removebg-preview.png';
                    break;
                  case 'Scania':
                    logoPath = 'lib/assets/Logo/Scania Emblem.png';
                    break;
                  case 'Volvo':
                    logoPath =
                        'lib/assets/Logo/Volvo_Icon-removebg-preview.png';
                    break;
                  case 'Mercedes':
                    logoPath = 'lib/assets/Logo/Mercedes Benz 3D Star.png';
                    break;
                  case 'Western Star':
                    logoPath = 'lib/assets/Logo/Western Star Trucks.png';
                    break;
                  default:
                    logoPath =
                        'lib/assets/Logo/Globe Emoji.png'; // Fallback logo
                    break;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Image.asset(
                    logoPath,
                    height: 50,
                    width: 50,
                    fit: BoxFit.contain,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditBrandsDialog(UserProvider userProvider) {
    final availableBrands = [
      'Volvo',
      'Freightliner',
      'Kenworth',
      'Peterbilt',
      'Mack',
      'Western Star',
      'International',
      'Scania',
      'Mercedes-Benz',
      'MAN',
      'DAF',
      'Iveco'
    ];

    List<String> selectedBrands = List.from(userProvider.getPreferredBrands);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Preferred Brands'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: availableBrands.map((brand) {
                    return CheckboxListTile(
                      title: Text(brand),
                      value: selectedBrands.contains(brand),
                      onChanged: (bool? isChecked) {
                        setState(() {
                          if (isChecked == true) {
                            selectedBrands.add(brand);
                          } else {
                            selectedBrands.remove(brand);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('CANCEL'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('DONE'),
                  onPressed: () async {
                    await userProvider.updatePreferredBrands(selectedBrands);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTruckCard(BuildContext context,
      AppinioSwiperController controller, Vehicle vehicle) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: vehicle.mainImageUrl != null
                  ? Image.network(
                      vehicle.mainImageUrl!,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'lib/assets/default_vehicle_image.png',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          Positioned(
            bottom: 90,
            left: 10,
            right: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      vehicle.makeModel,
                      style: _customFont(20, FontWeight.bold, Colors.white),
                    ),
                    const SizedBox(width: 5),
                    Image.asset(
                      'lib/assets/verified_Icon.png',
                      width: 20,
                      height: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBlurryContainer('YEAR', vehicle.year),
                    _buildBlurryContainer('MILEAGE', vehicle.mileage),
                    _buildBlurryContainer('TRANSMISSION', vehicle.transmission),
                    _buildBlurryContainer('CONFIG', 'N/A'),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildIconButton(
                    Icons.close, Colors.blue, controller, 'left', vehicle),
                _buildIconButton(Icons.favorite, const Color(0xFFFF4E00),
                    controller, 'right', vehicle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransporterVehicleCard(Vehicle vehicle, Size size) {
    return Container(
      width: size.width * 0.7,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              child: vehicle.mainImageUrl != null
                  ? Image.network(
                      vehicle.mainImageUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'lib/assets/default_vehicle_image.png',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.makeModel,
                  style: _customFont(18, FontWeight.bold, Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  vehicle.year ?? 'Unknown Year',
                  style: _customFont(14, FontWeight.normal, Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurryContainer(String title, String? value) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: _customFont(12, FontWeight.bold, Colors.grey),
          ),
          const SizedBox(height: 2),
          Text(
            value ?? 'Unknown',
            style: _customFont(14, FontWeight.bold, Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color,
      AppinioSwiperController controller, String direction, Vehicle vehicle) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          try {
            if (direction == 'left') {
              await _dislikeVehicle(vehicle.id);
              controller.swipeLeft();
            } else if (direction == 'right') {
              await _likeVehicle(vehicle.id);
              controller.swipeRight();
            }
          } catch (e) {
            print('Error handling swipe action for vehicle ${vehicle.id}: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Failed to process the action. Please try again later.'),
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.black, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _likeVehicle(String vehicleId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      await userProvider.likeVehicle(vehicleId);
      setState(() {
        likedVehicles.add(vehicleId);
      });
    } catch (e, stackTrace) {
      print('Error liking vehicle $vehicleId: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to like vehicle. Please try again.')),
      );
      // Report error to Crashlytics
      await FirebaseCrashlytics.instance.recordError(e, stackTrace);
    }
  }

  Future<void> _dislikeVehicle(String vehicleId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      await userProvider.dislikeVehicle(vehicleId);
      setState(() {
        dislikedVehicles.add(vehicleId);
      });
    } catch (e, stackTrace) {
      print('Error disliking vehicle $vehicleId: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to dislike vehicle. Please try again.')),
      );
      // Report error to Crashlytics
      await FirebaseCrashlytics.instance.recordError(e, stackTrace);
    }
  }
}
