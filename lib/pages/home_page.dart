import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/offer_card.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  late Future<void> _fetchVehiclesFuture;
  late Future<void> _fetchOffersFuture;
  final OfferProvider _offerProvider = OfferProvider();

  @override
  void initState() {
    super.initState();
    controller = AppinioSwiperController();
    _fetchVehiclesFuture =
        Provider.of<VehicleProvider>(context, listen: false).fetchVehicles();
    _fetchOffersFuture = _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _offerProvider.fetchOffers(user.uid);
      setState(() {});
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
    final userProvider = Provider.of<UserProvider>(context);
    final vehicleProvider = Provider.of<VehicleProvider>(context);
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
            child: CircleAvatar(
              radius: 20,
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
      body: Container(
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
                            'Welcome ${userProvider.getUserName}',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: orange,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Ready to steer your trading journey to success?",
                            textAlign: TextAlign.center,
                            style: _customFont(
                                16, FontWeight.normal, Colors.white),
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
                              userProvider.getUserRole == 'transporter'
                                  ? "I’m selling a".toUpperCase()
                                  : "I’m looking for".toLowerCase(),
                              style: _customFont(
                                  18, FontWeight.bold, Colors.white),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (userProvider.getUserRole ==
                                          'transporter') {
                                        Navigator.pushNamed(
                                            context, '/firstTruckForm');
                                      } else {
                                        // Handle truck button tap
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
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                "TRUCKS",
                                                style: _customFont(
                                                    18,
                                                    FontWeight.bold,
                                                    Colors.blue),
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
                                      if (userProvider.getUserRole ==
                                          'transporter') {
                                        Navigator.pushNamed(
                                            context, '/firstTruckForm');
                                      } else {
                                        // Handle trailer button tap
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
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                "TRAILERS",
                                                style: _customFont(18,
                                                    FontWeight.bold, orange),
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
                    // Current Brands Section
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: size.width * 0.05),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "CURRENT BRANDS",
                            style:
                                _customFont(18, FontWeight.bold, Colors.white),
                          ),
                          GestureDetector(
                            onTap: () {
                              _showEditBrandsDialog(context, userProvider);
                            },
                            child: Text(
                              "EDIT",
                              style: _customFont(
                                  14, FontWeight.bold, Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      color: Colors.white,
                      thickness: 1,
                      height: 20,
                      indent: 16,
                      endIndent: 16,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 20.0,
                        runSpacing: 20.0,
                        children: userProvider.getPreferredBrands.map((brand) {
                          return Image.asset(
                            'lib/assets/${brand.toLowerCase()}_logo.png',
                            width: size.width * 0.12,
                            height: size.width * 0.12,
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // New Arrivals Section
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
                    FutureBuilder<void>(
                      future: _fetchVehiclesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text(
                            'Error fetching vehicles',
                            style: _customFont(
                                16, FontWeight.normal, Colors.white),
                          );
                        } else {
                          return ValueListenableBuilder(
                            valueListenable: vehicleProvider.vehicleListenable,
                            builder: (context, List<Vehicle> vehicles, child) {
                              if (vehicles.isEmpty) {
                                return Center(
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 20),
                                      Text(
                                        'You have reached the end of the cards.',
                                        style: _customFont(
                                            18, FontWeight.bold, Colors.white),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Discover more vehicles later or refresh the page.',
                                        textAlign: TextAlign.center,
                                        style: _customFont(16,
                                            FontWeight.normal, Colors.white),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return SizedBox(
                                height: size.height * 0.6,
                                child: AppinioSwiper(
                                  controller: controller,
                                  cardCount: vehicles.length,
                                  cardBuilder:
                                      (BuildContext context, int index) {
                                    return _buildTruckCard(
                                        context, controller, vehicles[index]);
                                  },
                                  onSwipeEnd: (int index, int targetIndex,
                                      SwiperActivity direction) async {
                                    if (direction == AxisDirection.left) {
                                      await _dislikeTruck(
                                          context, vehicles[index].id);
                                    } else if (direction ==
                                        AxisDirection.right) {
                                      await _likeTruck(
                                          context, vehicles[index].id);
                                    }
                                    _removeTruckFromProvider(index, context);
                                    if (targetIndex >= vehicles.length) {
                                      _showEndOfCardsMessage(context);
                                    }
                                  },
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 50),
                    // Add Recent Pending Offers section
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
                                style: _customFont(
                                    24, FontWeight.bold, Colors.blue),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Track and manage your active trading offers here.',
                            style: _customFont(
                                16, FontWeight.normal, Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    FutureBuilder<void>(
                      future: _fetchOffersFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text(
                            'Error fetching offers',
                            style: _customFont(
                                16, FontWeight.normal, Colors.white),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
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
              child: vehicle.photos.isNotEmpty && vehicle.photos[0] != null
                  ? Image.network(
                      vehicle.photos[0]!,
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
                _buildIconButton(Icons.close, Colors.blue, controller, 'left'),
                _buildIconButton(Icons.favorite, const Color(0xFFFF4E00),
                    controller, 'right'),
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
      AppinioSwiperController controller, String direction) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          print('${icon == Icons.close ? "DISLIKE" : "LIKE"} button pressed');
          if (direction == 'left') {
            controller.swipeLeft();
            print('Swiping left');
          } else if (direction == 'right') {
            controller.swipeRight();
            print('Swiping right');
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

  void _showEndOfCardsMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You have reached the end of the cards.'),
      ),
    );
  }

  void _showEditBrandsDialog(BuildContext context, UserProvider userProvider) {
    final List<String> semiTruckBrands = [
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final Set<String> selectedBrands =
            userProvider.getPreferredBrands.toSet();
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Preferred Brands'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: semiTruckBrands.map((brand) {
                    return CheckboxListTile(
                      title: Text(brand),
                      value: selectedBrands.contains(brand),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
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
              actions: [
                TextButton(
                  child: const Text('CANCEL'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('SAVE'),
                  onPressed: () {
                    userProvider.updatePreferredBrands(selectedBrands.toList());
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

  Future<void> _likeTruck(BuildContext context, String vehicleId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentReference userRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);

        await userRef.update({
          'likedTrucks': FieldValue.arrayUnion([vehicleId]),
        });

        print('Debug: Truck liked with ID: $vehicleId');
      } catch (e) {
        print('Debug: Failed to like truck: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to like truck: $e')),
        );
      }
    } else {
      print('Debug: User not logged in');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
    }
  }

  Future<void> _dislikeTruck(BuildContext context, String vehicleId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentReference userRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);

        DocumentSnapshot userDoc = await userRef.get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          List<dynamic> dislikedTrucks = userData['dislikedTrucks'] ?? [];

          if (dislikedTrucks.length >= 40) {
            dislikedTrucks.removeAt(0);
          }

          dislikedTrucks.add(vehicleId);

          await userRef.update({
            'dislikedTrucks': dislikedTrucks,
          });
        } else {
          await userRef.set({
            'dislikedTrucks': [vehicleId],
          }, SetOptions(merge: true));
        }

        print('Debug: Truck disliked with ID: $vehicleId');
      } catch (e) {
        print('Debug: Failed to dislike truck: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to dislike truck: $e')),
        );
      }
    } else {
      print('Debug: User not logged in');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
    }
  }

  void _removeTruckFromProvider(int index, BuildContext context) {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    if (index < vehicleProvider.vehicles.length) {
      vehicleProvider.removeVehicle(index);
      print('Debug: Remaining vehicles: ${vehicleProvider.vehicles}');
    }
  }
}
