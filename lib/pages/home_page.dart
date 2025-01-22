// ignore_for_file: invalid_use_of_protected_member, unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_app_bar.dart';
import 'package:ctp/components/honesty_bar.dart';
import 'package:ctp/components/offer_card.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/trailerForms/trailer_upload_screen.dart';
import 'package:ctp/pages/truckForms/vehilce_upload_screen.dart';
import 'package:ctp/pages/truck_page.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Swiper controller
  late AppinioSwiperController controller;
  // Bottom nav index
  int _selectedIndex = 0;
  // Initialization future
  late Future<void> _initialization;

  // Providers & variables
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

    // Load filtered transporter vehicles after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransporterVehicles();
    });
  }

  /// Helper function to provide different font sizes for phone vs. tablet.
  /// Adjust the breakpoint or sizes as desired.
  double _adaptiveTextSize(
      BuildContext context, double phoneSize, double tabletSize) {
    bool isTablet = MediaQuery.of(context).size.width >= 600;
    return isTablet ? tabletSize : phoneSize;
  }

  // Fetch user data, vehicles, offers, etc.
  Future<void> _initializeData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);

    try {
      await userProvider.fetchUserData();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null || userProvider.userId == null) {
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      String userRole = userProvider.getUserRole;

      // Determine route based on role
      String targetRoute =
          (userRole == 'admin' || userRole == 'sales representative')
              ? '/admin-home'
              : '/home';

      if (ModalRoute.of(context)?.settings.name != targetRoute) {
        Navigator.pushReplacementNamed(context, targetRoute);
        return;
      }

      // Fetch vehicles
      await vehicleProvider.fetchVehicles(userProvider);

      // Safely handle recent vehicles - filter for 'Live' status only
      final fetchedRecentVehicles = await vehicleProvider.fetchRecentVehicles();
      recentVehicles = List<Vehicle>.from(fetchedRecentVehicles)
          .where((vehicle) => vehicle.vehicleStatus == 'Live')
          .toList();
      displayedVehiclesNotifier.value = recentVehicles.take(5).toList();

      // Fetch offers + user preferences
      await _offerProvider.fetchOffers(
        currentUser.uid,
        userProvider.getUserRole,
      );
      likedVehicles = List<String>.from(userProvider.getLikedVehicles);
      dislikedVehicles = List<String>.from(userProvider.getDislikedVehicles);
    } catch (e, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to initialize data. Please try again.'),
        ),
      );
      await FirebaseCrashlytics.instance.recordError(e, stackTrace);
    }
  }

  // Loads vehicles uploaded by the current user with at least one offer
  void _loadTransporterVehicles() async {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);

    await userProvider.fetchUserData();
    final userId = userProvider.userId;
    await offerProvider.fetchOffers(userId!, userProvider.getUserRole);

    final transporterVehicles = vehicleProvider.vehicles.where((vehicle) {
      final hasOffers = offerProvider.offers.any(
        (offer) => offer.vehicleId == vehicle.id,
      );
      return vehicle.userId == userId && hasOffers;
    }).toList();

    displayedVehiclesNotifier.value = transporterVehicles;
  }

  // Check each offer's payment status, update if accepted
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

  // Load the next "non-liked / non-disliked" vehicle
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

  // Bottom nav item tapped
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Handle swipe actions in the swiper
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

  // Like
  Future<void> _likeVehicle(String vehicleId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!likedVehicles.contains(vehicleId)) {
      try {
        await userProvider.likeVehicle(vehicleId);
        likedVehicles.add(vehicleId);
      } catch (e, stackTrace) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to like vehicle. Please try again.'),
          ),
        );
        await FirebaseCrashlytics.instance.recordError(e, stackTrace);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle already liked.')),
      );
    }
  }

  // Dislike
  Future<void> _dislikeVehicle(String vehicleId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      await userProvider.dislikeVehicle(vehicleId);
      dislikedVehicles.add(vehicleId);
    } catch (e, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to dislike vehicle. Please try again.'),
        ),
      );
      await FirebaseCrashlytics.instance.recordError(e, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If width >= 600, we consider it a tablet layout
        bool isTablet = constraints.maxWidth >= 600;

        return Scaffold(
          // Allow the body to extend behind the app bar.
          extendBodyBehindAppBar: true, // Changed from false to true
          backgroundColor: Colors.black,
          appBar:
              CustomAppBar(), // Update your CustomAppBar if needed for transparency
          body: FutureBuilder<void>(
            future: _initialization,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Image(
                    image: AssetImage('lib/assets/Loading_Logo_CTP.gif'),
                    width: 100,
                    height: 100,
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading data',
                    style: TextStyle(
                      fontSize: _adaptiveTextSize(context, 16, 20),
                      color: Colors.white,
                    ),
                  ),
                );
              } else {
                return _buildHomePageContent(context, constraints, isTablet);
              }
            },
          ),
          bottomNavigationBar: CustomBottomNavigation(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          ),
        );
      },
    );
  }

  /// Main HomePage content, made responsive via constraints + isTablet
  Widget _buildHomePageContent(
    BuildContext context,
    BoxConstraints constraints,
    bool isTablet,
  ) {
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;

    // A simple ratio for the hero image
    final double imageHeight =
        isTablet ? screenHeight * 0.25 : screenHeight * 0.35;

    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.getUserRole;

    // Sort offers by 'createdAt' descending, filter out 'Done'
    List<Offer> sortedOffers = List.from(_offerProvider.offers);
    sortedOffers.sort((a, b) {
      final DateTime? aCreatedAt = a.createdAt;
      final DateTime? bCreatedAt = b.createdAt;
      if (aCreatedAt == null && bCreatedAt == null) return 0;
      if (bCreatedAt == null) return -1;
      if (aCreatedAt == null) return 1;
      return bCreatedAt.compareTo(aCreatedAt);
    });

    // Filter out offers with 'offerStatus' = 'Done'
    List<Offer> filteredOffers =
        sortedOffers.where((offer) => offer.offerStatus != 'Done').toList();

    // Take up to 5 most recent non-Done offers
    final recentOffers = filteredOffers.take(5).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero Section
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Background image (Hero)
              SizedBox(
                height: imageHeight,
                width: screenWidth,
                child: IgnorePointer(
                  ignoring: true,
                  child: Image.asset(
                    'lib/assets/HomePageHero.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Positioned text over the image
              Positioned(
                top: isTablet ? (imageHeight * 0.6) : (imageHeight * 0.7),
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'Welcome ${userProvider.getUserName.toUpperCase()}',
                        style: TextStyle(
                          fontSize: _adaptiveTextSize(context, 24, 28),
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFFF4E00),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        "Ready to steer your trading journey to success?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: _adaptiveTextSize(context, 14, 18),
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Spacing
          SizedBox(height: screenHeight * 0.03),

          // Vehicle Type Selection
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: _buildVehicleTypeSelection(userRole, constraints, isTablet),
          ),

          SizedBox(height: screenHeight * 0.02),

          // Only for dealer: show preferred brands
          if (userRole == 'dealer')
            _buildPreferredBrandsSection(userProvider, constraints, isTablet),

          SizedBox(height: screenHeight * 0.02),

          // Show end message if user swiped all
          if (_showEndMessage) ...[
            Text(
              "You've seen all the available trucks.",
              style: TextStyle(
                fontSize: _adaptiveTextSize(context, 18, 20),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              "The list will be updated tomorrow.",
              style: TextStyle(
                fontSize: _adaptiveTextSize(context, 16, 18),
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          // For dealers, show "NEW ARRIVALS" swiper
          if (userRole == 'dealer' && _showSwiper) ...[
            Text(
              "🔥 NEW ARRIVALS",
              style: TextStyle(
                fontSize: _adaptiveTextSize(context, 18, 20),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2F7FFF),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              "Discover the newest additions to our fleet, ready for your next venture.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _adaptiveTextSize(context, 16, 18),
                color: Colors.white,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            ValueListenableBuilder<List<Vehicle>>(
              valueListenable: displayedVehiclesNotifier,
              builder: (context, displayedVehicles, child) {
                // Filter out already liked
                final userProvider =
                    Provider.of<UserProvider>(context, listen: false);
                final filteredVehicles = displayedVehicles
                    .where(
                      (v) => !userProvider.getLikedVehicles.contains(v.id),
                    )
                    .toList();

                if (filteredVehicles.isEmpty && _hasReachedEnd) {
                  return Text(
                    "You have swiped through all the available trucks.",
                    style: TextStyle(
                      fontSize: _adaptiveTextSize(context, 18, 20),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  );
                } else if (filteredVehicles.isEmpty) {
                  return Center(
                    child: Text(
                      "No vehicles available",
                      style: TextStyle(
                        fontSize: _adaptiveTextSize(context, 18, 20),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  );
                } else {
                  return SwiperWidget(
                    parentContext: context,
                    displayedVehicles: filteredVehicles,
                    controller: controller,
                    onSwipeEnd: _handleSwipe,
                    vsync: this,
                    isTablet: isTablet,
                  );
                }
              },
            ),
            SizedBox(height: screenHeight * 0.02),
          ],

          // For transporter, show "YOUR VEHICLES WITH OFFERS"
          if (userRole == 'transporter') ...[
            Text(
              "YOUR VEHICLES WITH OFFERS",
              style: TextStyle(
                fontSize: _adaptiveTextSize(context, 18, 20),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: screenHeight * 0.015),
            ValueListenableBuilder<List<Vehicle>>(
              valueListenable: displayedVehiclesNotifier,
              builder: (context, displayedVehicles, child) {
                final offerProvider =
                    Provider.of<OfferProvider>(context, listen: false);

                return SizedBox(
                  height: isTablet ? screenHeight * 0.25 : screenHeight * 0.3,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: displayedVehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = displayedVehicles[index];
                      final hasOffers = offerProvider.offers.any(
                        (offer) =>
                            offer.vehicleId == vehicle.id &&
                            offer.offerStatus != 'Done',
                      );

                      if (hasOffers) {
                        return _buildTransporterVehicleCard(
                          vehicle,
                          constraints,
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                );
              },
            ),
            SizedBox(height: screenHeight * 0.015),
          ],

          SizedBox(height: screenHeight * 0.015),

          // RECENT PENDING OFFERS
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
                      width: screenHeight * 0.03,
                      height: screenHeight * 0.03,
                    ),
                    SizedBox(width: screenHeight * 0.01),
                    Text(
                      'RECENT PENDING OFFERS',
                      style: TextStyle(
                        fontSize: _adaptiveTextSize(context, 24, 26),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2F7FFF),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.006),
                Text(
                  'Track and manage your active trading offers here.',
                  style: TextStyle(
                    fontSize: _adaptiveTextSize(context, 16, 18),
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          if (recentOffers.isEmpty) ...[
            SizedBox(height: screenHeight * 0.01),
            Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF2F7FFF),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'lib/assets/shaking_hands.png',
                    height: 50,
                    width: 50,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'NO OFFERS YET',
                    style: TextStyle(
                      fontSize: _adaptiveTextSize(context, 18, 20),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start trading to see your offers here',
                    style: TextStyle(
                      fontSize: _adaptiveTextSize(context, 14, 16),
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
          ] else ...[
            SizedBox(height: screenHeight * 0.01),
            Column(
              children: recentOffers.map((offer) {
                return OfferCard(offer: offer);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the "I AM SELLING A / I AM LOOKING FOR" row with two cards
  Widget _buildVehicleTypeSelection(
    String userRole,
    BoxConstraints constraints,
    bool isTablet,
  ) {
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;

    final double cardHeight =
        isTablet ? screenHeight * 0.15 : screenHeight * 0.2;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            userRole == 'transporter' ? "I AM SELLING A" : "I AM LOOKING FOR",
            style: TextStyle(
              fontSize: _adaptiveTextSize(context, 18, 20),
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (userRole == 'transporter') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VehicleUploadScreen(
                            isNewUpload: true,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TruckPage(vehicleType: 'truck'),
                        ),
                      );
                    }
                  },
                  child: _buildVehicleTypeCard(
                    context,
                    cardHeight,
                    'lib/assets/truck_image.png',
                    "TRUCKS",
                    const Color(0xFF2F7FFF),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (userRole == 'transporter') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TrailerUploadScreen(),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TruckPage(vehicleType: 'trailer'),
                        ),
                      );
                    }
                  },
                  child: _buildVehicleTypeCard(
                    context,
                    cardHeight,
                    'lib/assets/trailer_image.png',
                    "TRAILERS",
                    const Color(0xFFFF4E00),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds each card (Truck / Trailer) in the above row
  Widget _buildVehicleTypeCard(
    BuildContext context,
    double cardHeight,
    String imagePath,
    String label,
    Color borderColor,
  ) {
    return Container(
      height: cardHeight,
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
                  fontSize: _adaptiveTextSize(context, 16, 18),
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

  /// Transporter vehicle card
  Widget _buildTransporterVehicleCard(
    Vehicle vehicle,
    BoxConstraints constraints,
  ) {
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;
    bool isTablet = screenWidth >= 600;

    return Container(
      width: isTablet ? (screenWidth * 0.4) : (screenWidth * 0.7),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2F7FFF), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
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
          // Info
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.makeModel.toString().toUpperCase(),
                  style: TextStyle(
                    fontSize: _adaptiveTextSize(context, 18, 20),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vehicle.year.toString(),
                  style: TextStyle(
                    fontSize: _adaptiveTextSize(context, 14, 16),
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Preferred brands section for dealers
  Widget _buildPreferredBrandsSection(
    UserProvider userProvider,
    BoxConstraints constraints,
    bool isTablet,
  ) {
    final preferredBrands = userProvider.getPreferredBrands;
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading + Edit
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CURRENT BRANDS',
                style: TextStyle(
                  fontSize: _adaptiveTextSize(context, 18, 20),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              GestureDetector(
                onTap: () => _showEditBrandsDialog(userProvider),
                child: Text(
                  'EDIT',
                  style: TextStyle(
                    fontSize: _adaptiveTextSize(context, 16, 18),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: const Divider(color: Colors.white, thickness: 1.0),
        ),
        const SizedBox(height: 10),

        // Brand logos
        Center(
          child: preferredBrands.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Please select some truck brands.',
                    style: TextStyle(
                      fontSize: _adaptiveTextSize(context, 18, 20),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : SizedBox(
                  height: isTablet ? 60 : 50,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: preferredBrands.map((brand) {
                        String logoPath;
                        switch (brand) {
                          case 'DAF':
                            logoPath = 'lib/assets/Logo/DAF.png';
                            break;
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
                          case 'FREIGHTLINER':
                            logoPath =
                                'lib/assets/Freightliner-logo-6000x2000.png';
                            break;
                          // Fallbacks
                          default:
                            // For IVECO, US TRUCKS, or anything not found
                            return const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(
                                Icons.image_outlined,
                                color: Colors.white,
                                size: 40,
                              ),
                            );
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TruckPage(
                                    vehicleType: 'all',
                                    selectedBrand: brand,
                                  ),
                                ),
                              );
                            },
                            child: Image.asset(
                              logoPath,
                              height: isTablet ? 60 : 50,
                              width: isTablet ? 60 : 50,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  /// Edit brand dialog
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
      'US TRUCKS',
      'FREIGHTLINER'
    ];

    List<String> selectedBrands = List.from(userProvider.getPreferredBrands);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Preferred Brands'),
              content: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
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
  final bool isTablet;

  const SwiperWidget({
    super.key,
    required this.displayedVehicles,
    required this.controller,
    required this.onSwipeEnd,
    required this.vsync,
    required this.parentContext,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // This percentage controls how tall the “blue stripes” at the edges are
    double blueBoxHeightPercentage = 0.9;
    double blueBoxTopOffset =
        (screenSize.height * (1 - blueBoxHeightPercentage)) / 2;

    // Height for the swiper area
    double swiperHeight =
        isTablet ? screenSize.height * 0.5 : screenSize.height * 0.6;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Left blue strip
        Positioned(
          left: 0,
          top: blueBoxTopOffset,
          bottom: blueBoxTopOffset,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(10.0),
              bottomRight: Radius.circular(10.0),
            ),
            child: Container(
              width: screenSize.height * 0.025,
              color: const Color(0xFF2F7FFF),
            ),
          ),
        ),
        // Right blue strip
        Positioned(
          right: 0,
          top: blueBoxTopOffset,
          bottom: blueBoxTopOffset,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10.0),
              bottomLeft: Radius.circular(10.0),
            ),
            child: Container(
              width: screenSize.height * 0.025,
              color: const Color(0xFF2F7FFF),
            ),
          ),
        ),
        SizedBox(
          height: swiperHeight,
          child: AppinioSwiper(
            controller: controller,
            cardCount: displayedVehicles.length,
            backgroundCardOffset: Offset.zero,
            cardBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: _buildTruckCard(
                  controller,
                  displayedVehicles[index],
                  context,
                ),
              );
            },
            swipeOptions: const SwipeOptions.symmetric(
              horizontal: false,
              vertical: false,
            ),
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

  Widget _buildTruckCard(
    AppinioSwiperController controller,
    Vehicle vehicle,
    BuildContext context,
  ) {
    var screenSize = MediaQuery.of(context).size;
    AnimationController animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: vsync,
    );

    Animation<double> scaleAnimation =
        Tween<double>(begin: 1.0, end: 1.05).animate(animationController);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleDetailsPage(vehicle: vehicle),
          ),
        );
      },
      child: AnimatedBuilder(
        animation: scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.5),
                  width: 2.0,
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Vehicle image
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
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

                      // Info + Buttons
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Vehicle brand/model row
                            Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    "${vehicle.brands.join(' ')} ${vehicle.makeModel.toUpperCase()}",
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Image.asset(
                                  'lib/assets/verified_Icon.png',
                                  width: screenSize.height * 0.021,
                                  height: screenSize.height * 0.021,
                                ),
                              ],
                            ),
                            SizedBox(height: screenSize.height * 0.01),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildBlurryContainer(
                                  'YEAR',
                                  vehicle.year.toString(),
                                  context,
                                ),
                                _buildBlurryContainer(
                                  'MILEAGE',
                                  vehicle.mileage,
                                  context,
                                ),
                                _buildBlurryContainer(
                                  'GEARBOX',
                                  vehicle.transmissionType,
                                  context,
                                ),
                                _buildBlurryContainer('CONFIG', 'N/A', context),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Swipe buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15.0,
                          vertical: 10.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildIconButton(
                              Icons.close,
                              const Color(0xFF2F7FFF),
                              controller,
                              'left',
                              vehicle,
                              'Not Interested',
                            ),
                            SizedBox(width: screenSize.height * 0.015),
                            _buildIconButton(
                              Icons.favorite,
                              const Color(0xFFFF4E00),
                              controller,
                              'right',
                              vehicle,
                              'Interested',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Honesty bar on top-right
                  Positioned(
                    top: screenSize.height * 0.055,
                    right: screenSize.height * 0.01,
                    child: HonestyBarWidget(
                      vehicle: vehicle,
                      heightFactor: 0.325,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Left / Right swipe buttons
  Widget _buildIconButton(
    IconData icon,
    Color color,
    AppinioSwiperController controller,
    String direction,
    Vehicle vehicle,
    String label,
  ) {
    final screenSize = MediaQuery.of(parentContext).size;
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
              Icon(
                icon,
                color: Colors.black,
                size: screenSize.height * 0.025,
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Info block (e.g. YEAR, MILEAGE, GEARBOX)
  Widget _buildBlurryContainer(
    String title,
    String? value,
    BuildContext context,
  ) {
    var screenSize = MediaQuery.of(context).size;
    String normalizedValue = value?.trim().toLowerCase() ?? '';

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
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: Colors.white,
          width: 0.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: screenSize.height * 0.002),
          Text(
            displayValue,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
