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

  ValueNotifier<List<Vehicle>> displayedVehiclesNotifier =
      ValueNotifier<List<Vehicle>>([]);
  List<Vehicle> swipedVehicles = []; // Track swiped vehicles
  List<String> swipedDirections = []; // Track swipe directions for undo
  int loadedVehicleIndex = 0;
  bool _hasReachedEnd = false;

  List<Vehicle> recentVehicles = [];

  @override
  void initState() {
    super.initState();
    controller = AppinioSwiperController();
    _initialization = _initializeData();
    _checkPaymentStatusForOffers();

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

      recentVehicles = await vehicleProvider.fetchRecentVehicles();
      displayedVehiclesNotifier.value = recentVehicles.take(5).toList();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userRole = userProvider.getUserRole;
        await _offerProvider.fetchOffers(user.uid, userRole);

        likedVehicles = userProvider.getLikedVehicles;
        dislikedVehicles = userProvider.getDislikedVehicles;
      }
    } catch (e, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to initialize data. Please try again.')),
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

  void _handleSwipe(int previousIndex, SwiperActivity activity) async {
    final vehicleId = displayedVehiclesNotifier.value[previousIndex].id;

    if (activity is Swipe) {
      if (activity.direction == AxisDirection.right) {
        await _likeVehicle(vehicleId);
      } else if (activity.direction == AxisDirection.left) {
        // await _dislikeVehicle(vehicleId);
      }
    }

    if (previousIndex == displayedVehiclesNotifier.value.length - 1) {
      _showEndMessage = true;
      setState(() {});
    }
  }

  Future<void> _likeVehicle(String vehicleId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (!likedVehicles.contains(vehicleId)) {
      try {
        await userProvider.likeVehicle(vehicleId);
        likedVehicles.add(vehicleId);
      } catch (e, stackTrace) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to like vehicle. Please try again.')),
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
      // await userProvider.dislikeVehicle(vehicleId);
      // dislikedVehicles.add(vehicleId);
    } catch (e, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to dislike vehicle. Please try again.')),
      );
      await FirebaseCrashlytics.instance.recordError(e, stackTrace);
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
            return const Center(
                child: CircularProgressIndicator(
              color: Color(0xFFFF4E00),
            ));
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

    final vehiclesWithOffers = vehicleProvider.vehicles.where((vehicle) {
      return _offerProvider.offers
          .any((offer) => offer.vehicleId == vehicle.id);
    }).toList();

    // Get the 5 most recent offers
    final recentOffers = _offerProvider.offers.take(5).toList();

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
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
                      style:
                          _customFont(18, FontWeight.bold, Color(0xFF2F7FFF))),
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
                          style: _customFont(18, FontWeight.bold, Colors.white),
                        );
                      } else if (displayedVehicles.isEmpty) {
                        return Center(
                          child: Text(
                            "No vehicles available",
                            style:
                                _customFont(18, FontWeight.bold, Colors.white),
                          ),
                        );
                      } else {
                        return SwiperWidget(
                          parentContext: context,
                          displayedVehicles: displayedVehicles,
                          controller: controller,
                          onSwipeEnd: _handleSwipe,
                          vsync: this,
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
                            return _buildTransporterVehicleCard(vehicle, size);
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
                            style: _customFont(
                                24, FontWeight.bold, Color(0xFF2F7FFF)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Track and manage your active trading offers here.',
                        style: _customFont(16, FontWeight.normal, Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Directly displaying the 5 most recent offers
                if (recentOffers.isNotEmpty)
                  const SizedBox(
                    height: 10,
                  ),
                Column(
                  children: recentOffers.map((offer) {
                    return OfferCard(
                      offer: offer,
                    );
                  }).toList(),
                ),
              ],
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
                  child: _buildVehicleTypeCard(
                      size,
                      'lib/assets/truck_image.png',
                      "TRUCKS",
                      Color(0xFF2F7FFF)),
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
        border: Border.all(color: Color(0xFF2F7FFF), width: 2),
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

  Widget _buildPreferredBrandsSection(UserProvider userProvider) {
    final preferredBrands = userProvider.getPreferredBrands;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
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
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(color: Colors.white, thickness: 1.0),
        ),
        const SizedBox(height: 10),
        Center(
          child: preferredBrands.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Please select some truck brands.',
                    style: _customFont(18, FontWeight.bold, Colors.white),
                    textAlign: TextAlign.center,
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: preferredBrands.map((brand) {
                      String logoPath;
                      switch (brand) {
                        case 'DAF':
                          logoPath = 'lib/assets/Logo/daf-2.png';
                          break;
                        case 'IVECO':
                          logoPath = 'lib/assets/Logo/iveco.png';
                          break;
                        case 'MAN':
                          logoPath = 'lib/assets/Logo/man-logo.png';
                          break;
                        case 'MERCEDES-BENZ':
                          logoPath = 'lib/assets/Logo/mercedes-benz-9.png';
                          break;
                        case 'VOLVO':
                          logoPath = 'lib/assets/Logo/volvo.png';
                          break;
                        case 'SCANIA':
                          logoPath = 'lib/assets/Logo/scania-6.png';
                          break;
                        case 'FUSO':
                          logoPath = 'lib/assets/Logo/fuso-1.png';
                          break;
                        case 'HINO':
                          logoPath = 'lib/assets/Logo/hino.png';
                          break;
                        case 'ISUZU':
                          logoPath = 'lib/assets/Logo/isuzu-2.png';
                          break;
                        case 'UD TRUCKS':
                          logoPath = 'lib/assets/Logo/ud-trucks-1.png';
                          break;
                        case 'VW':
                          logoPath = 'lib/assets/Logo/volkswagen-10.png';
                          break;
                        case 'FORD':
                          logoPath = 'lib/assets/Logo/ford-8.png';
                          break;
                        case 'TOYOTA':
                          logoPath = 'lib/assets/Logo/toyota-7.png';
                          break;
                        case 'CNHTC':
                          logoPath = 'lib/assets/Logo/CNHTC.png';
                          break;
                        case 'EICHER':
                          logoPath = 'lib/assets/Logo/eicher-logo.png';
                          break;
                        case 'FAW':
                          logoPath = 'lib/assets/Logo/FAW.png';
                          break;
                        case 'JAC':
                          logoPath = 'lib/assets/Logo/JAC.png';
                          break;
                        case 'POWERSTAR':
                          logoPath = 'lib/assets/Logo/EVQzwvJI_400x400.png';
                          break;
                        case 'RENAULT':
                          logoPath = 'lib/assets/Logo/renault-2.png';
                          break;
                        case 'TATA':
                          logoPath = 'lib/assets/Logo/tata-logo.png';
                          break;
                        case 'ASHOK LEYLAND':
                          logoPath = 'lib/assets/Logo/ashok-leyland-logo-2.png';
                          break;
                        case 'DAYUN':
                          logoPath = 'lib/assets/Logo/DAYUN.png';
                          break;
                        case 'FIAT':
                          logoPath = 'lib/assets/Logo/fiat-3.png';
                          break;
                        case 'FOTON':
                          logoPath = 'lib/assets/Logo/Foton.png';
                          break;
                        case 'HYUNDAI':
                          logoPath =
                              'lib/assets/Logo/hyundai-motor-company-2.png';
                          break;
                        case 'JOYLONG':
                          logoPath = 'lib/assets/Logo/Joylong.png';
                          break;
                        case 'PEUGEOT':
                          logoPath = 'lib/assets/Logo/peugeot-8.png';
                          break;
                        case 'US TRUCKS':
                          logoPath = 'lib/assets/Logo/image2vector.png';
                          break;
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

  Widget _buildBrandLogo(String logoPath) {
    try {
      return Image.asset(
        logoPath,
        height: 50,
        width: 50,
        fit: BoxFit.contain,
      );
    } catch (e) {
      return Image.asset(
        'lib/assets/default_logo.png', // Provide a default image path here
        height: 50,
        width: 50,
        fit: BoxFit.contain,
      );
    }
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
      'SCANIA',
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
  final BuildContext parentContext;

  const SwiperWidget({
    super.key,
    required this.displayedVehicles,
    required this.controller,
    required this.onSwipeEnd,
    required this.vsync,
    required this.parentContext,
  });

  @override
  Widget build(BuildContext context) {
    double blueBoxHeightPercentage =
        0.9; // Percentage of the screen height for the blue box

    double blueBoxTopOffset =
        (MediaQuery.of(context).size.height * (1 - blueBoxHeightPercentage)) /
            2; // This centers the blue box vertically

    return Stack(
      children: [
        // Blue box on the left edge of the screen
        Positioned(
          left: 0,
          top: blueBoxTopOffset, // Adjust the top offset
          bottom: blueBoxTopOffset, // Adjust the bottom offset
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(10.0), // Top right corner
              bottomRight: Radius.circular(10.0), // Bottom right corner
            ),
            child: Container(
              width: 20, // Adjust the width as needed
              color: const Color(0xFF2F7FFF),
            ),
          ),
        ),
// Blue box on the right edge of the screen
        Positioned(
          right: 0,
          top: blueBoxTopOffset, // Adjust the top offset
          bottom: blueBoxTopOffset, // Adjust the bottom offset
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10.0), // Top left corner
              bottomLeft: Radius.circular(10.0), // Bottom left corner
            ),
            child: Container(
              width: 20, // Adjust the width as needed
              color: const Color(0xFF2F7FFF),
            ),
          ),
        ),

        // Swiper Widget
        SizedBox(
          height: MediaQuery.of(parentContext).size.height * 0.6,
          child: AppinioSwiper(
            controller: controller,
            cardCount: displayedVehicles.length,
            backgroundCardOffset: Offset.zero,
            cardBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal:
                        40.0), // Match this padding with the blue box width
                child: _buildTruckCard(controller, displayedVehicles[index]),
              );
            },
            swipeOptions: const SwipeOptions.symmetric(
                horizontal: false, vertical: false),
            onSwipeEnd: (int previousIndex, int? targetIndex,
                SwiperActivity direction) async {
              onSwipeEnd(previousIndex, direction);
            },
            onEnd: () {
              final parentState =
                  parentContext.findAncestorStateOfType<_HomePageState>();
              parentState?._showEndMessage = true;
              parentState?.setState(() {});
            },
          ),
        ),
      ],
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
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.grey.withOpacity(0.5), // Light grey border color
                width: 2.0, // Border width
              ),
            ),
            child: Column(
              children: [
                // Image section
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10)),
                    child: vehicle.mainImageUrl != null
                        ? Image.network(
                            vehicle.mainImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : Image.asset(
                            'lib/assets/default_vehicle_image.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                  ),
                ),
                // Text section
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              vehicle.makeModel,
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Image.asset(
                            'lib/assets/verified_Icon.png',
                            width: 20,
                            height: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildBlurryContainer('YEAR', vehicle.year),
                          _buildBlurryContainer('MILEAGE', vehicle.mileage),
                          _buildBlurryContainer(
                              'GEARBOX', vehicle.transmission),
                          _buildBlurryContainer('CONFIG', 'N/A'),
                        ],
                      ),
                    ],
                  ),
                ),
                // Buttons section
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildIconButton(Icons.close, Color(0xFF2F7FFF),
                          controller, 'left', vehicle),
                      SizedBox(
                        width: 10,
                      ),
                      _buildIconButton(Icons.favorite, const Color(0xFFFF4E00),
                          controller, 'right', vehicle),
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
            final userProvider =
                Provider.of<UserProvider>(parentContext, listen: false);

            if (direction == 'left') {
              if (!userProvider.getDislikedVehicles.contains(vehicle.id)) {
                await userProvider.dislikeVehicle(vehicle.id);
                controller.swipeLeft();
              } else {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(content: Text('Vehicle already disliked.')),
                );
              }
            } else if (direction == 'right') {
              if (!userProvider.getLikedVehicles.contains(vehicle.id)) {
                await userProvider.likeVehicle(vehicle.id);
                controller.swipeRight();
              } else {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  const SnackBar(content: Text('Vehicle already liked.')),
                );
              }
            }
          } catch (e) {
            ScaffoldMessenger.of(parentContext).showSnackBar(
              const SnackBar(
                content: Text('Failed to swipe vehicle. Please try again.'),
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
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
    String normalizedValue = value?.trim().toLowerCase() ?? '';

    // Check if the title is 'GEARBOX' and handle 'Automatic' or 'Manual'
    String displayValue = (title.toLowerCase() == 'gearbox' && value != null)
        ? (normalizedValue.contains('auto')
            ? 'AUTO'
            : normalizedValue.contains('manual')
                ? 'MANUAL'
                : value.toUpperCase())
        : value?.toUpperCase() ?? 'UNKNOWN';

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[900], // Set the background color to gray
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Colors.white, // Set the border color to white
          width: 0.2, // Border width
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.center, // Center the text horizontally
        children: [
          Text(
            title,
            textAlign: TextAlign.center, // Center the title text
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Dark gray color for the title
            ),
          ),
          const SizedBox(height: 2),
          Text(
            displayValue,
            textAlign: TextAlign.center, // Center the value text
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white, // White color for the value text
            ),
          ),
        ],
      ),
    );
  }
}
