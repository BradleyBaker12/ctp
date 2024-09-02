import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/honesty_bar.dart';
import 'package:ctp/components/offer_card.dart';
import 'package:ctp/pages/truck_page.dart';
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
      // Fetch user data first
      await userProvider.fetchUserData();

      // Fetch vehicles after ensuring user data is ready
      await vehicleProvider.fetchVehicles(userProvider);

      // Ensure recent vehicles are also loaded after fetching all vehicles
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initialization =
        _initializeData(); // Re-initialize data whenever dependencies change
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

  void _loadInitialVehicles() async {
    try {
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Ensure user data is fetched before filtering vehicles
      await userProvider.fetchUserData();

      // Fetch and filter vehicles
      final allVehicles = vehicleProvider.vehicles
          .where((vehicle) =>
              !userProvider.getLikedVehicles.contains(vehicle.id) &&
              !userProvider.getDislikedVehicles.contains(vehicle.id))
          .toList();

      // Take the first 5 vehicles to display
      final initialVehicles = allVehicles.take(5).toList();

      // Check if there are no vehicles to display after filtering
      if (initialVehicles.isEmpty) {
        // Set the notifier value to an empty list and show the no vehicles message
        displayedVehiclesNotifier.value = [];
        _showEndMessage = true;
      } else {
        // Update the displayed vehicles notifier with the filtered and limited list
        displayedVehiclesNotifier.value = initialVehicles;
        loadedVehicleIndex = initialVehicles.length;
      }

      // Print currently showing vehicles
      print(
          'Currently Showing Vehicles: ${displayedVehiclesNotifier.value.map((v) => v.id).toList()}');
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
        // Print the vehicle that will be displayed next
        print('Next Vehicle to show: ${nextVehicle.id}');

        displayedVehiclesNotifier.value = [
          ...displayedVehiclesNotifier.value,
          nextVehicle
        ];
        loadedVehicleIndex++;

        // Print the vehicles currently showing
        print(
            'Currently Showing Vehicles: ${displayedVehiclesNotifier.value.map((v) => v.id).toList()}');
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
        await _dislikeVehicle(vehicleId);
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
      await userProvider.dislikeVehicle(vehicleId);
      dislikedVehicles.add(vehicleId);
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
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(size.height * 0.07), // Set the desired height here
        child: AppBar(
          automaticallyImplyLeading: false, // This removes the back button
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: Colors.grey.withOpacity(0.1),
              ),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 35.0), // Space on the left
                child: Image.asset(
                  'lib/assets/CTPLogo.png',
                  width: 60,
                  height: 60,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(right: 25.0), // Space on the right
                child: Consumer<UserProvider>(
                  builder: (context, userProvider, _) {
                    final profileImageUrl = userProvider.getProfileImageUrl;
                    return CircleAvatar(
                      radius: 26,
                      backgroundImage: profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : const AssetImage(
                                  'lib/assets/default-profile-photo.jpg')
                              as ImageProvider,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initialization,
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
            // Once data is loaded, build the HomePage content
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
    final userRole = userProvider.getUserRole;

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
                          'Welcome ${userProvider.getUserName.toUpperCase()}'
                              .toUpperCase(),
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFF4E00)),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Ready to steer your trading journey to success?",
                          textAlign: TextAlign.center,
                          style: _customFont(
                            14,
                            FontWeight.w500,
                            Colors.white,
                          ),
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
                const SizedBox(height: 30),
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
                      // Use displayedVehiclesNotifier to ensure the correct vehicles are shown
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
                if (recentOffers.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Column(
                    children: recentOffers.map((offer) {
                      return OfferCard(
                        offer: offer,
                      );
                    }).toList(),
                  ),
                ],
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
                : "I’m looking for".toUpperCase(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TruckPage(vehicleType: 'truck'),
                      ),
                    );
                  },
                  child: _buildVehicleTypeCard(
                      size,
                      'lib/assets/truck_image.png',
                      "TRUCKS",
                      const Color(0xFF2F7FFF)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TruckPage(vehicleType: 'trailer'),
                      ),
                    );
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: borderColor,
                ),
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
                          logoPath = 'lib/assets/Logo/DAF.png';
                          break;
                        case 'IVECO':
                          return Icon(
                            Icons.image_outlined,
                            color: Colors.white,
                            size: 40,
                          );
                        case 'MAN':
                          logoPath = 'lib/assets/Logo/MAN.png';
                          break;
                        case 'MERCEDES-BENZ':
                          logoPath = 'lib/assets/Logo/MERCEDES BENZ.png';
                          break;
                        case 'VOLVO':
                          logoPath = 'lib/assets/Logo/VOLVO.png';
                          break;
                        case 'SCANIA':
                          logoPath = 'lib/assets/Logo/SCANIA.png';
                          break;
                        case 'FUSO':
                          logoPath = 'lib/assets/Logo/FUSO.png';
                          break;
                        case 'HINO':
                          logoPath = 'lib/assets/Logo/HINO.png';
                          break;
                        case 'ISUZU':
                          logoPath = 'lib/assets/Logo/ISUZU.png';
                          break;
                        case 'UD TRUCKS':
                          logoPath = 'lib/assets/Logo/UD TRUCKS.png';
                          break;
                        case 'VW':
                          logoPath = 'lib/assets/Logo/VW.png';
                          break;
                        case 'FORD':
                          logoPath = 'lib/assets/Logo/FORD.png';
                          break;
                        case 'TOYOTA':
                          logoPath = 'lib/assets/Logo/TOYOTA.png';
                          break;
                        case 'CNHTC':
                          logoPath = 'lib/assets/Logo/CNHTC.png';
                          break;
                        case 'EICHER':
                          logoPath = 'lib/assets/Logo/EICHER.png';
                          break;
                        case 'FAW':
                          logoPath = 'lib/assets/Logo/FAW.png';
                          break;
                        case 'JAC':
                          logoPath = 'lib/assets/Logo/JAC.png';
                          break;
                        case 'POWERSTAR':
                          logoPath = 'lib/assets/Logo/POWERSTAR.png';
                          break;
                        case 'RENAULT':
                          logoPath = 'lib/assets/Logo/RENAULT.png';
                          break;
                        case 'TATA':
                          logoPath = 'lib/assets/Logo/TATA.png';
                          break;
                        case 'ASHOK LEYLAND':
                          logoPath = 'lib/assets/Logo/ASHOK LEYLAND.png';
                          break;
                        case 'DAYUN':
                          logoPath = 'lib/assets/Logo/DAYUN.png';
                          break;
                        case 'FIAT':
                          logoPath = 'lib/assets/Logo/FIAT.png';
                          break;
                        case 'FOTON':
                          logoPath = 'lib/assets/Logo/FOTON.png';
                          break;
                        case 'HYUNDAI':
                          logoPath = 'lib/assets/Logo/HYUNDAI.png';
                          break;
                        case 'JOYLONG':
                          logoPath = 'lib/assets/Logo/JOYLONG.png';
                          break;
                        case 'PEUGEOT':
                          logoPath = 'lib/assets/Logo/PEUGEOT.png';
                          break;
                        case 'US TRUCKS':
                          return Icon(
                            Icons.image_outlined,
                            color: Colors.white,
                            size: 40,
                          );
                        default:
                          return const Icon(Icons.image_outlined);
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
      'SCANIA',
      'UD TRUCKS',
      'VW',
      'VOLVO',
      'FORD',
      'TOYOTA',
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
            child: Stack(
              children: [
                Column(
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
                          const SizedBox(width: 10),
                          _buildIconButton(
                              Icons.favorite,
                              const Color(0xFFFF4E00),
                              controller,
                              'right',
                              vehicle),
                        ],
                      ),
                    ),
                  ],
                ),
                // Honesty Bar Widget
                Positioned(
                  top: 52,
                  right: 12,
                  child: HonestyBarWidget(
                    vehicle: vehicle,
                    heightFactor: 0.34,
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
