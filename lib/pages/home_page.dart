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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AppinioSwiperController controller;
  int _selectedIndex = 0;
  late Future<void> _initialization;

  final OfferProvider _offerProvider = OfferProvider();
  final bool _showSwiper = true;
  bool _showEndMessage = false;
  late List<String> likedVehicles;
  late List<String> dislikedVehicles;

  // Use ValueNotifier to manage displayedVehicles
  ValueNotifier<List<Vehicle>> displayedVehiclesNotifier =
      ValueNotifier<List<Vehicle>>([]);
  int loadedVehicleIndex = 0;
  bool _hasReachedEnd = false;

  // New list to store the most recent vehicles
  List<Vehicle> recentVehicles = [];

  @override
  void initState() {
    super.initState();
    controller = AppinioSwiperController();
    _initialization = _initializeData();
    _checkPaymentStatusForOffers();

    // Load initial vehicles after data initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialVehicles();
    });
  }

  Future<void> _initializeData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);

    try {
      await userProvider.fetchUserData();
      await vehicleProvider.fetchVehicles();

      // Fetch the most recent vehicles
      recentVehicles = await vehicleProvider.fetchRecentVehicles();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userRole = userProvider.getUserRole;
        await _offerProvider.fetchOffers(user.uid, userRole);

        likedVehicles = userProvider.getLikedVehicles;
        dislikedVehicles = userProvider.getDislikedVehicles;
      }
    } catch (e, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to initialize data. Please try again.')),
      );
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
            await FirebaseFirestore.instance
                .collection('offers')
                .doc(offer.offerId)
                .update({'offerStatus': 'paid'});

            await _offerProvider.fetchOffers(
              userProvider.userId!,
              userProvider.getUserRole,
            );
          }
        }
      } catch (e, stackTrace) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Error checking payment status. Please try again later.'),
          ),
        );
        await FirebaseCrashlytics.instance.recordError(e, stackTrace);
      }
    }
  }

  void _loadInitialVehicles() {
    try {
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final initialVehicles = vehicleProvider.vehicles
          .where((vehicle) =>
              !userProvider.getLikedVehicles.contains(vehicle.id) &&
              !userProvider.getDislikedVehicles.contains(vehicle.id))
          .take(5)
          .toList();
      displayedVehiclesNotifier.value = initialVehicles;
      loadedVehicleIndex = initialVehicles.length;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to load vehicles. Please try again later.')),
      );
    }
  }

  void _loadNextVehicle(BuildContext context) {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    while (loadedVehicleIndex < vehicleProvider.vehicles.length) {
      final nextVehicle = vehicleProvider.vehicles[loadedVehicleIndex];
      if (!userProvider.getLikedVehicles.contains(nextVehicle.id) &&
          !userProvider.getDislikedVehicles.contains(nextVehicle.id)) {
        displayedVehiclesNotifier.value = [
          ...displayedVehiclesNotifier.value,
          nextVehicle
        ];
        loadedVehicleIndex++;
        return;
      }
      loadedVehicleIndex++;
    }

    if (loadedVehicleIndex >= vehicleProvider.vehicles.length) {
      _hasReachedEnd = true;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // New method for handling swipes
  void _handleSwipe(int previousIndex, SwiperActivity activity) async {
    final vehicleId = displayedVehiclesNotifier.value[previousIndex].id;

    if (activity is Swipe) {
      if (activity.direction == AxisDirection.right) {
        await _likeVehicle(vehicleId);
      } else if (activity.direction == AxisDirection.left) {
        await _dislikeVehicle(vehicleId);
      }
    }

    // Check if all vehicles are swiped
    if (previousIndex == displayedVehiclesNotifier.value.length - 1) {
      _showEndMessage = true;
      setState(() {}); // Trigger a rebuild to show the message
    }
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

    final userRole = userProvider.getUserRole;

    // Filter vehicles with offers for the current user
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
                          'Welcome ${userProvider.getUserName}',
                          style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFF4E00)),
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
                    child: _buildVehicleTypeSelection(userRole, size),
                  ),
                  const SizedBox(height: 20),
                  _buildPreferredBrandsSection(userProvider),
                  const SizedBox(height: 20),
                  if (_showEndMessage) ...[
                    Text(
                      "You've seen all the available trucks.",
                      style: _customFont(18, FontWeight.bold, Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "The list will be updated tomorrow.",
                      style: _customFont(16, FontWeight.normal, Colors.grey),
                    ),
                  ] else if (userRole == 'dealer' && _showSwiper) ...[
                    Text("🔥 NEW ARRIVALS",
                        style: _customFont(18, FontWeight.bold, Colors.blue)),
                    const SizedBox(height: 10),
                    Text(
                      "Discover the newest additions to our fleet, ready for your next venture.",
                      textAlign: TextAlign.center,
                      style: _customFont(16, FontWeight.normal, Colors.white),
                    ),
                    const SizedBox(height: 20),
                    ValueListenableBuilder<List<Vehicle>>(
                      valueListenable: displayedVehiclesNotifier,
                      builder: (context, displayedVehicles, child) {
                        if (displayedVehicles.isEmpty && _hasReachedEnd) {
                          return Text(
                            "You have swiped through all the available trucks.",
                            style:
                                _customFont(18, FontWeight.bold, Colors.white),
                          );
                        } else if (displayedVehicles.isEmpty) {
                          return Center(
                            child: Text(
                              "No vehicles available",
                              style: _customFont(
                                  18, FontWeight.bold, Colors.white),
                            ),
                          );
                        } else {
                          return SwiperWidget(
                            parentContext:
                                context, // Pass context from HomePage
                            displayedVehicles: displayedVehicles,
                            controller: controller,
                            onSwipeEnd: _handleSwipe, // Pass the swipe handler
                            vsync: this, // Pass the TickerProvider
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (userRole == 'transporter') ...[
                    Text("YOUR VEHICLES WITH OFFERS",
                        style: _customFont(18, FontWeight.bold, Colors.white)),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<List<Vehicle>>(
                      valueListenable: displayedVehiclesNotifier,
                      builder: (context, displayedVehicles, child) {
                        return SizedBox(
                          height: size.height * 0.3,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: displayedVehicles.length,
                            itemBuilder: (context, index) {
                              final vehicle = displayedVehicles[index];
                              return _buildTransporterVehicleCard(
                                  vehicle, size);
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                  const SizedBox(height: 10),
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
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  // Offer cards section for both roles
                  if (vehiclesWithOffers.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        ListView.builder(
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
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTypeSelection(String userRole, Size size) {
    return Container(
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
            style: _customFont(18, FontWeight.bold, Colors.white),
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
                  child: _buildVehicleTypeCard(size,
                      'lib/assets/truck_image.png', "TRUCKS", Colors.blue),
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
                  child: _buildVehicleTypeCard(
                      size,
                      'lib/assets/trailer_image.png',
                      "TRAILERS",
                      const Color(0xFFFF4E00)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleTypeCard(
      Size size, String imagePath, String label, Color borderColor) {
    return Container(
      height: size.height * 0.2,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
          width: 3,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                imagePath,
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
                label,
                style: _customFont(18, FontWeight.bold, borderColor),
                textAlign: TextAlign.center,
              ),
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
                  ? Image.network(vehicle.mainImageUrl!,
                      width: double.infinity, fit: BoxFit.cover)
                  : Image.asset('lib/assets/default_vehicle_image.png',
                      width: double.infinity, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicle.makeModel,
                    style: _customFont(18, FontWeight.bold, Colors.white)),
                const SizedBox(height: 4),
                Text(vehicle.year ?? 'Unknown Year',
                    style: _customFont(14, FontWeight.normal, Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _likeVehicle(String vehicleId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Check if the vehicle is already liked
    if (!likedVehicles.contains(vehicleId)) {
      try {
        await userProvider.likeVehicle(vehicleId);
        likedVehicles.add(vehicleId);
      } catch (e, stackTrace) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to like vehicle. Please try again.')),
        );
        await FirebaseCrashlytics.instance.recordError(e, stackTrace);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle already liked.')),
      );
    }
  }

  Future<void> _dislikeVehicle(String vehicleId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      await userProvider.dislikeVehicle(vehicleId);
      dislikedVehicles.add(vehicleId);
    } catch (e, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to dislike vehicle. Please try again.')),
      );
      await FirebaseCrashlytics.instance.recordError(e, stackTrace);
    }
  }

  Widget _buildPreferredBrandsSection(UserProvider userProvider) {
    final preferredBrands = userProvider.getPreferredBrands;

    if (preferredBrands.isEmpty) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('CURRENT BRANDS',
                style: _customFont(18, FontWeight.bold, Colors.white)),
            GestureDetector(
              onTap: () => _showEditBrandsDialog(userProvider),
              child: Text('EDIT',
                  style: _customFont(16, FontWeight.bold, Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 1.0),
          child: Divider(color: Colors.white, thickness: 1.0),
        ),
        const SizedBox(height: 10),
        Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: preferredBrands.map((brand) {
                String logoPath;
                switch (brand) {
                  case 'DAF':
                    logoPath = 'lib/assets/Logo/DAF-removebg-preview.png';
                    break;
                  case 'IVECO':
                    logoPath = 'lib/assets/Logo/Iveco 2023 New.png';
                    break;
                  case 'MAN':
                    logoPath =
                        'lib/assets/Logo/png-clipart-man-truck-bus-scania-ab-logo-man-se-truck-angle-text-removebg-preview.png';
                    break;
                  case 'MERCEDES-BENZ':
                    logoPath = 'lib/assets/Logo/Mercedes Benz 3D Star.png';
                    break;
                  case 'VOLVO':
                    logoPath =
                        'lib/assets/Logo/Volvo_Icon-removebg-preview.png';
                    break;
                  case 'SCANIA':
                    logoPath = 'lib/assets/Logo/Scania Emblem.png';
                    break;
                  case 'CNHTC':
                  case 'EICHER':
                  case 'FAW':
                  case 'FUSO':
                  case 'HINO':
                  case 'ISUZU':
                  case 'JAC':
                  case 'POWERSTAR':
                  case 'RENAULT':
                  case 'SSCANIA':
                  case 'TATA':
                  case 'UD TRUCKS':
                  case 'VOLKSWAGEN':
                  case 'MAKE':
                  default:
                    logoPath = 'lib/assets/Logo/Globe Emoji.png';
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
      'DAF',
      'FUSO',
      'HINO',
      'ISUZU',
      'IVECO',
      'MAN',
      'MERCEDES-BENZ',
      'SSCANIA',
      'UD TRUCKS',
      'VW',
      'VOLVO',
      'FORD',
      'TOYOTA',
      'MAKE',
      'CNHTC',
      'EICHER',
      'FAW',
      'JAC',
      'POWERSTAR',
      'RENAULT',
      'TATA',
      'ASHOK LEYLAND',
      'DAYUN',
      'FIAT',
      'FOTON',
      'HYUNDAI',
      'JOYLONG',
      'PEUGEOT',
      'US TRUCKS'
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
}

class SwiperWidget extends StatelessWidget {
  final List<Vehicle> displayedVehicles;
  final AppinioSwiperController controller;
  final void Function(int, SwiperActivity) onSwipeEnd;
  final TickerProvider vsync;
  final BuildContext parentContext; // Pass the context from the parent

  const SwiperWidget({
    super.key,
    required this.displayedVehicles,
    required this.controller,
    required this.onSwipeEnd,
    required this.vsync,
    required this.parentContext, // Initialize the context from the parent
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height:
          MediaQuery.of(parentContext).size.height * 0.6, // Use parent context
      child: AppinioSwiper(
        controller: controller,
        cardCount: displayedVehicles.length,
        backgroundCardOffset: Offset.zero,
        cardBuilder: (BuildContext context, int index) {
          return _buildTruckCard(controller, displayedVehicles[index]);
        },
        swipeOptions: const SwipeOptions.symmetric(
            horizontal: false, vertical: false), // Disable swiping
        onSwipeEnd: (int previousIndex, int? targetIndex,
            SwiperActivity direction) async {
          onSwipeEnd(previousIndex, direction);
        },
        onEnd: () {
          // Handle end of swiping
          final parentState =
              parentContext.findAncestorStateOfType<_HomePageState>();
          parentState?._showEndMessage = true;
          parentState?.setState(() {});
        },
      ),
    );
  }

  Widget _buildTruckCard(AppinioSwiperController controller, Vehicle vehicle) {
    AnimationController animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
    );

    Animation<double> scaleAnimation =
        Tween<double>(begin: 1.0, end: 1.05).animate(animationController);

    return AnimatedBuilder(
      animation: scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Container(
            // margin: const EdgeInsets.symmetric(vertical: 10),
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
                        ? Image.network(vehicle.mainImageUrl!,
                            fit: BoxFit.cover)
                        : Image.asset('lib/assets/default_vehicle_image.png',
                            fit: BoxFit.cover),
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
                          Text(vehicle.makeModel,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const SizedBox(width: 5),
                          Image.asset('lib/assets/verified_Icon.png',
                              width: 20, height: 20),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildBlurryContainer('YEAR', vehicle.year),
                          _buildBlurryContainer('MILEAGE', vehicle.mileage),
                          _buildBlurryContainer(
                              'TRANSMISSION', vehicle.transmission),
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
                      _buildIconButton(Icons.close, Colors.blue, controller,
                          'left', vehicle), // Dislike
                      _buildIconButton(Icons.favorite, const Color(0xFFFF4E00),
                          controller, 'right', vehicle), // Like
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIconButton(IconData icon, Color color,
      AppinioSwiperController controller, String direction, Vehicle vehicle) {
    final size = MediaQuery.of(parentContext).size;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          try {
            print('${icon == Icons.close ? "DISLIKE" : "LIKE"} button pressed');
            final userProvider =
                Provider.of<UserProvider>(parentContext, listen: false);

            if (direction == 'left') {
              // Check if the vehicle is already disliked
              if (!userProvider.getDislikedVehicles.contains(vehicle.id)) {
                await userProvider.dislikeVehicle(vehicle.id);
                print(
                    'Disliked vehicle: ${vehicle.id}, MakeModel: ${vehicle.makeModel}'); // Debugging statement
                controller.swipeLeft();
                print('Swiping left');
              } else {
                print('Vehicle is already disliked.');
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(content: Text('Vehicle already disliked.')),
                );
              }
            } else if (direction == 'right') {
              // Check if the vehicle is already liked
              if (!userProvider.getLikedVehicles.contains(vehicle.id)) {
                await userProvider.likeVehicle(vehicle.id);
                print(
                    'Liked vehicle: ${vehicle.id}, MakeModel: ${vehicle.makeModel}'); // Debugging statement
                controller.swipeRight();
                print('Swiping right');
              } else {
                print('Vehicle is already liked.');
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(content: Text('Vehicle already liked.')),
                );
              }
            }
          } catch (e) {
            print('Error swiping vehicle: $e');
            ScaffoldMessenger.of(parentContext).showSnackBar(
              const SnackBar(
                content: Text('Failed to swipe vehicle. Please try again.'),
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.black, size: size.height * 0.025),
            ],
          ),
        ),
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
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value ?? 'Unknown',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ],
      ),
    );
  }
}
