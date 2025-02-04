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
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // <-- Import this for kIsWeb
import 'dart:io';
import 'dart:typed_data';
import 'package:ctp/components/web_navigation_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Add this getter for compact navigation
  bool get _isCompactNavigation => MediaQuery.of(context).size.width <= 1100;

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
  List<Offer> recentOffers = [];

  // Add new properties for web navigation
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool get _isLargeScreen => MediaQuery.of(context).size.width > 900;

  // Add web navigation items
  List<NavigationItem> get _webNavigationItems => [
        NavigationItem(
          title: 'Home',
          route: '/home',
        ),
        NavigationItem(
          title: 'Trucks',
          route: '/truckPage',
        ),
        NavigationItem(
          title: 'Wishlist',
          route: '/wishlist',
        ),
        NavigationItem(
          title: 'Offers',
          route: '/offers',
        ),
      ];

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

  TextStyle _getTextStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.white,
  }) {
    return GoogleFonts.montserrat(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
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

  // Add web navigation bar widget
  Widget _buildWebNavigationBar() {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/home';
    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.getUserRole;

    List<NavigationItem> navigationItems = userRole == 'dealer'
        ? [
            NavigationItem(title: 'Home', route: '/home'),
            NavigationItem(title: 'Search Trucks', route: '/truckPage'),
            NavigationItem(title: 'Wishlist', route: '/wishlist'),
            NavigationItem(title: 'Pending Offers', route: '/offers'),
          ]
        : [
            NavigationItem(title: 'Home', route: '/home'),
            NavigationItem(title: 'Your Trucks', route: '/transporterList'),
            NavigationItem(title: 'Your Offers', route: '/offers'),
            NavigationItem(title: 'In-Progress', route: '/in-progress'),
          ];

    return Container(
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [Colors.black, Color(0xFF2F7FFD)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left section - Hamburger menu (only shown in compact mode)
            if (_isCompactNavigation)
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                onPressed: () {
                  _showNavigationDrawer(navigationItems);
                },
              ),

            // Center section - Logo
            Expanded(
              child: Row(
                mainAxisAlignment: _isCompactNavigation
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Image.network(
                    'https://firebasestorage.googleapis.com/v0/b/ctp-central-database.appspot.com/o/CTPLOGOWeb.png?alt=media&token=d85ec0b5-f2ba-4772-aa08-e9ac6d4c2253',
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 40,
                        width: 40,
                        color: Colors.grey[900],
                        child: const Icon(Icons.local_shipping,
                            color: Colors.white),
                      );
                    },
                  ),
                  // Navigation links (only shown in full mode)
                  if (!_isCompactNavigation) ...[
                    const SizedBox(width: 60),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: navigationItems.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildNavItem(
                                item.title, item.route, currentRoute),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Right section - Profile
            CircleAvatar(
              radius: 18,
              backgroundImage: userProvider.getProfileImageUrl != null
                  ? NetworkImage(userProvider.getProfileImageUrl)
                  : const AssetImage('lib/assets/default_profile.png')
                      as ImageProvider,
            ),
          ],
        ),
      ),
    );
  }

  // Add navigation drawer method
  void _showNavigationDrawer(List<NavigationItem> items) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final currentRoute = ModalRoute.of(context)?.settings.name ?? '/home';
        return Stack(
          children: [
            // Semi-transparent background
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black54,
              ),
            ),
            // Sliding drawer
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: ModalRoute.of(context)!.animation!,
                curve: Curves.easeOut,
              )),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: const [
                        Colors.black,
                        Color(0xFF2F7FFD),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header with logo
                      Container(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 20,
                          bottom: 20,
                          left: 16,
                          right: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.network(
                              'https://firebasestorage.googleapis.com/v0/b/ctp-central-database.appspot.com/o/CTPLOGOWeb.png?alt=media&token=d85ec0b5-f2ba-4772-aa08-e9ac6d4c2253',
                              height: 40,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 40,
                                  width: 40,
                                  color: Colors.grey[900],
                                  child: const Icon(Icons.local_shipping,
                                      color: Colors.white),
                                );
                              },
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white24),
                      // Navigation items
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: items
                              .map((item) => ListTile(
                                    selected: currentRoute == item.route,
                                    selectedColor: const Color(0xFFFF4E00),
                                    title: Text(
                                      item.title,
                                      style: TextStyle(
                                        color: currentRoute == item.route
                                            ? const Color(0xFFFF4E00)
                                            : Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      if (currentRoute != item.route) {
                                        Navigator.pushNamed(
                                            context, item.route);
                                      }
                                    },
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavItem(String title, String route, String currentRoute) {
    bool isActive = currentRoute == route;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () {
          if (!isActive) {
            Navigator.pushNamed(context, route);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: isActive
              ? BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFFF4E00),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                )
              : null,
          child: Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isActive ? const Color(0xFFFF4E00) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isTablet = constraints.maxWidth >= 600;
        bool showBottomNav = !_isLargeScreen && !kIsWeb;
        final userProvider = Provider.of<UserProvider>(context);
        final userRole = userProvider.getUserRole;

        // Define navigation items here so we can use them in both drawer and nav bar
        List<NavigationItem> navigationItems = userRole == 'dealer'
            ? [
                NavigationItem(title: 'Home', route: '/home'),
                NavigationItem(title: 'Search Trucks', route: '/truckPage'),
                NavigationItem(title: 'Wishlist', route: '/wishlist'),
                NavigationItem(title: 'Pending Offers', route: '/offers'),
              ]
            : [
                NavigationItem(title: 'Home', route: '/home'),
                NavigationItem(title: 'Your Trucks', route: '/transporterList'),
                NavigationItem(title: 'Your Offers', route: '/offers'),
                NavigationItem(title: 'In-Progress', route: '/in-progress'),
              ];

        return Scaffold(
          key: _scaffoldKey,
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.black,
          appBar: _isLargeScreen || kIsWeb
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(70),
                  child: WebNavigationBar(
                    isCompactNavigation: _isCompactNavigation,
                    currentRoute:
                        ModalRoute.of(context)?.settings.name ?? '/home',
                    onMenuPressed: () =>
                        _scaffoldKey.currentState?.openDrawer(),
                  ),
                )
              : CustomAppBar(),
          drawer: _isCompactNavigation
              ? Drawer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: const [Colors.black, Color(0xFF2F7FFD)],
                      ),
                    ),
                    child: Column(
                      children: [
                        DrawerHeader(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white24,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Image.network(
                              'https://firebasestorage.googleapis.com/v0/b/ctp-central-database.appspot.com/o/CTPLOGOWeb.png?alt=media&token=d85ec0b5-f2ba-4772-aa08-e9ac6d4c2253',
                              height: 50,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 50,
                                  width: 50,
                                  color: Colors.grey[900],
                                  child: const Icon(Icons.local_shipping,
                                      color: Colors.white),
                                );
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            children: navigationItems.map((item) {
                              bool isActive =
                                  ModalRoute.of(context)?.settings.name ==
                                      item.route;
                              return ListTile(
                                title: Text(
                                  item.title,
                                  style: TextStyle(
                                    color: isActive
                                        ? const Color(0xFFFF4E00)
                                        : Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                selected: isActive,
                                selectedTileColor: Colors.black12,
                                onTap: () {
                                  Navigator.pop(context); // Close drawer
                                  if (!isActive) {
                                    Navigator.pushNamed(context, item.route);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
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
          bottomNavigationBar: showBottomNav
              ? CustomBottomNavigation(
                  selectedIndex: _selectedIndex,
                  onItemTapped: _onItemTapped,
                )
              : null,
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

    // Get providers and data
    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.getUserRole;

    // Sort and filter offers - update the class variable
    List<Offer> sortedOffers = List.from(_offerProvider.offers);
    sortedOffers.sort((a, b) {
      final DateTime? aCreatedAt = a.createdAt;
      final DateTime? bCreatedAt = b.createdAt;
      if (aCreatedAt == null && bCreatedAt == null) return 0;
      if (bCreatedAt == null) return -1;
      if (aCreatedAt == null) return 1;
      return bCreatedAt.compareTo(aCreatedAt);
    });

    // Update the class variable
    recentOffers = sortedOffers
        .where((offer) => offer.offerStatus != 'Done')
        .take(5)
        .toList();

    // Calculate aspect ratio based on device type
    final heroAspectRatio = isTablet
        ? 18 / 8 // Standard 16:9 for tablet/web
        : 4 / 5; // Taller 4:5 ratio for mobile

    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero Section - Full width image
          Column(
            children: [
              // Hero Image with adjusted aspect ratio
              AspectRatio(
                aspectRatio: heroAspectRatio,
                child: Image.asset(
                  'lib/assets/HomePageHero.png',
                  width: screenWidth,
                  fit: BoxFit.fill,
                ),
              ),
              // Welcome text
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.02,
                  horizontal: screenWidth * 0.05,
                ),
                child: Column(
                  children: [
                    Text(
                      'Welcome ${userProvider.getUserName.toUpperCase()}'
                          .toUpperCase(),
                      style: _getTextStyle(
                        fontSize: _adaptiveTextSize(context, 24, 32),
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFFF4E00),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      "Ready to steer your trading journey to success?",
                      textAlign: TextAlign.center,
                      style: _getTextStyle(
                        fontSize: _adaptiveTextSize(context, 14, 20),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: screenHeight * 0.02),

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
              style: _getTextStyle(
                fontSize: _adaptiveTextSize(context, 18, 20),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              "The list will be updated tomorrow.",
              style: _getTextStyle(
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
              style: _getTextStyle(
                fontSize: _adaptiveTextSize(context, 18, 20),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2F7FFF),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              "Discover the newest additions to our fleet, ready for your next venture.",
              textAlign: TextAlign.center,
              style: _getTextStyle(
                fontSize: _adaptiveTextSize(context, 16, 18),
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
                    style: _getTextStyle(
                      fontSize: _adaptiveTextSize(context, 18, 20),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  );
                } else if (filteredVehicles.isEmpty) {
                  return Center(
                    child: Text(
                      "No vehicles available",
                      style: _getTextStyle(
                        fontSize: _adaptiveTextSize(context, 18, 20),
                        fontWeight: FontWeight.bold,
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
              style: _getTextStyle(
                fontSize: _adaptiveTextSize(context, 18, 20),
                fontWeight: FontWeight.bold,
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
                      style: _getTextStyle(
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
                  style: _getTextStyle(
                    fontSize: _adaptiveTextSize(context, 16, 18),
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
                    style: _getTextStyle(
                      fontSize: _adaptiveTextSize(context, 18, 20),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start trading to see your offers here',
                    style: _getTextStyle(
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
            LayoutBuilder(
              builder: (context, constraints) {
                // Determine number of cards per row based on screen width
                int cardsPerRow;
                if (constraints.maxWidth > 1400) {
                  cardsPerRow = 4; // Extra large screens: 4 cards
                } else if (constraints.maxWidth > 1100) {
                  cardsPerRow = 3; // Large screens: 3 cards
                } else if (constraints.maxWidth > 700) {
                  cardsPerRow = 2; // Medium screens: 2 cards
                } else {
                  cardsPerRow = 1; // Mobile: 1 card
                }

                return Wrap(
                  spacing: 16, // Horizontal spacing between cards
                  runSpacing: 16, // Vertical spacing between rows
                  alignment: WrapAlignment.center,
                  children: recentOffers.map((offer) {
                    return SizedBox(
                      width: (constraints.maxWidth - (16 * (cardsPerRow - 1))) /
                          cardsPerRow,
                      child: OfferCard(offer: offer),
                    );
                  }).toList(),
                );
              },
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

    // Calculate card size while maintaining aspect ratio
    final double cardWidth = isTablet ? screenWidth * 0.2 : screenWidth * 0.35;
    final double cardHeight = cardWidth; // Make it square

    // Calculate container width based on content
    final double containerWidth = isTablet
        ? screenWidth * 0.5 // 50% of screen width for tablet/web
        : screenWidth * 0.9; // 90% of screen width for mobile

    return Center(
      // Center the entire container
      child: Container(
        width: containerWidth,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              userRole == 'transporter' ? "I AM SELLING A" : "I AM LOOKING FOR",
              style: _getTextStyle(
                fontSize: _adaptiveTextSize(context, 18, 20),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Center the cards
              children: [
                SizedBox(
                  width: cardWidth,
                  height: cardHeight,
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
                            builder: (context) =>
                                TruckPage(vehicleType: 'truck'),
                          ),
                        );
                      }
                    },
                    child: _buildVehicleTypeCard(
                      context,
                      cardHeight,
                      'lib/assets/truck_image.jpeg',
                      "TRUCKS",
                      const Color(0xFF2F7FFF),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02), // Dynamic spacing
                SizedBox(
                  width: cardWidth,
                  height: cardHeight,
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
                      'lib/assets/trailer_image.jpeg',
                      "TRAILERS",
                      const Color(0xFFFF4E00),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                style: _getTextStyle(
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
                  style: _getTextStyle(
                    fontSize: _adaptiveTextSize(context, 18, 20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vehicle.year.toString(),
                  style: _getTextStyle(
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

    // Calculate container width based on screen size
    final double maxContentWidth = isTablet
        ? screenWidth * 0.8 // 80% of screen width for tablet/web
        : screenWidth; // Full width for mobile

    // Calculate brand logo size based on screen size
    final double logoSize = isTablet
        ? screenHeight * 0.06 // 6% of screen height for tablet/web
        : screenHeight * 0.05; // 5% of screen height for mobile

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxContentWidth,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.02,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[900]?.withOpacity(0.5),
            borderRadius: BorderRadius.circular(isTablet ? 10 : 0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading + Edit row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CURRENT BRANDS',
                    style: _getTextStyle(
                      fontSize: _adaptiveTextSize(context, 18, 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showEditBrandsDialog(userProvider),
                    child: Text(
                      'EDIT',
                      style: _getTextStyle(
                        fontSize: _adaptiveTextSize(context, 16, 18),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.015),
              const Divider(color: Colors.white, thickness: 1.0),
              SizedBox(height: screenHeight * 0.015),

              // Brand logos with centering
              if (preferredBrands.isEmpty)
                Center(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                    child: Text(
                      'Please select some truck brands.',
                      style: _getTextStyle(
                        fontSize: _adaptiveTextSize(context, 18, 20),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: logoSize * 1.2,
                  child: Center(
                    // Center the ListView
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth:
                            isTablet ? screenWidth * 0.7 : screenWidth * 0.9,
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: preferredBrands.length,
                        itemBuilder: (context, index) {
                          final brand = preferredBrands[index];
                          final logoPath = _getBrandLogoPath(brand);

                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TruckPage(
                                  vehicleType: 'all',
                                  selectedBrand: brand,
                                ),
                              ),
                            ),
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.02),
                              width: logoSize,
                              height: logoSize,
                              alignment: Alignment.center,
                              child: logoPath != null
                                  ? Image.asset(
                                      logoPath,
                                      width: logoSize * 0.8,
                                      height: logoSize * 0.8,
                                      fit: BoxFit.contain,
                                    )
                                  : Icon(
                                      Icons.image_outlined,
                                      color: Colors.white,
                                      size: logoSize * 0.8,
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get logo path
  String? _getBrandLogoPath(String brand) {
    switch (brand) {
      case 'DAF':
        return 'lib/assets/Logo/DAF.png';
      case 'MAN':
        return 'lib/assets/Logo/MAN.png';
      case 'MERCEDES-BENZ':
        return 'lib/assets/Logo/MERCEDES BENZ.png';
      case 'VOLVO':
        return 'lib/assets/Logo/VOLVO.png';
      case 'SCANIA':
        return 'lib/assets/Logo/SCANIA.png';
      case 'FUSO':
        return 'lib/assets/Logo/FUSO.png';
      case 'HINO':
        return 'lib/assets/Logo/HINO.png';
      case 'ISUZU':
        return 'lib/assets/Logo/ISUZU.png';
      case 'UD TRUCKS':
        return 'lib/assets/Logo/UD TRUCKS.png';
      case 'VW':
        return 'lib/assets/Logo/VW.png';
      case 'FORD':
        return 'lib/assets/Logo/FORD.png';
      case 'TOYOTA':
        return 'lib/assets/Logo/TOYOTA.png';
      case 'CNHTC':
        return 'lib/assets/Logo/CNHTC.png';
      case 'EICHER':
        return 'lib/assets/Logo/EICHER.png';
      case 'FAW':
        return 'lib/assets/Logo/FAW.png';
      case 'JAC':
        return 'lib/assets/Logo/JAC.png';
      case 'POWERSTAR':
        return 'lib/assets/Logo/POWERSTAR.png';
      case 'RENAULT':
        return 'lib/assets/Logo/RENAULT.png';
      case 'TATA':
        return 'lib/assets/Logo/TATA.png';
      case 'ASHOK LEYLAND':
        return 'lib/assets/Logo/ASHOK LEYLAND.png';
      case 'DAYUN':
        return 'lib/assets/Logo/DAYUN.png';
      case 'FIAT':
        return 'lib/assets/Logo/FIAT.png';
      case 'FOTON':
        return 'lib/assets/Logo/FOTON.png';
      case 'HYUNDAI':
        return 'lib/assets/Logo/HYUNDAI.png';
      case 'JOYLONG':
        return 'lib/assets/Logo/JOYLONG.png';
      case 'PEUGEOT':
        return 'lib/assets/Logo/PEUGEOT.png';
      case 'FREIGHTLINER':
        return 'lib/assets/Freightliner-logo-6000x2000.png';
      case 'US TRUCKS':
        return 'lib/assets/Logo/US TRUCKS.png';
      case 'IVECO':
        return 'lib/assets/Logo/IVECO.png';
      default:
        return null;
    }
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

  Widget _buildActionButtons(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;

    return Container(
      constraints: BoxConstraints(
        maxWidth: isWeb ? 800 : double.infinity,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const VehicleUploadScreen()),
            ),
            label: 'Truck',
            icon: Icons.local_shipping,
            width: isWeb ? 150 : screenWidth * 0.4,
          ),
          _buildActionButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const TrailerUploadScreen()),
            ),
            label: 'Trailer',
            icon: Icons.directions_railway,
            width: isWeb ? 150 : screenWidth * 0.4,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required double width,
  }) {
    return SizedBox(
      width: width,
      height: width,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
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

  TextStyle _getTextStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.white,
  }) {
    return GoogleFonts.montserrat(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Calculate constrained width for web
    double maxWidth = kIsWeb
        ? screenSize.width * 0.4 // 40% of screen width for web
        : screenSize.width; // Full width for mobile

    // Height for the swiper area
    double swiperHeight =
        isTablet ? screenSize.height * 0.5 : screenSize.height * 0.6;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: swiperHeight,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // The card swiper
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 48.0), // Add padding here
                  child: SizedBox(
                    height: swiperHeight,
                    child: AppinioSwiper(
                      controller: controller,
                      cardCount: displayedVehicles.length,
                      backgroundCardOffset: Offset.zero,
                      cardBuilder: (BuildContext context, int index) {
                        return _buildTruckCard(
                          controller,
                          displayedVehicles[index],
                          context,
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
                        final parentState = parentContext
                            .findAncestorStateOfType<_HomePageState>();
                        parentState?._showEndMessage = true;
                        parentState?.setState(() {});
                      },
                    ),
                  ),
                ),

                // Navigation arrows - always visible
                Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left arrow
                      Container(
                        height: 40,
                        width: 40,
                        margin: const EdgeInsets.only(
                            right: 50.0), // Add margin here
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.5),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () => controller.swipeLeft(),
                        ),
                      ),

                      // Right arrow
                      Container(
                        height: 40,
                        width: 40,
                        margin: const EdgeInsets.only(
                            left: 50.0), // Add margin here
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.5),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () => controller.swipeRight(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'lib/assets/default_vehicle_image.png',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    );
                                  },
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
                                    style: _getTextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w900,
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
            style: _getTextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: screenSize.height * 0.002),
          Text(
            displayValue,
            textAlign: TextAlign.center,
            style: _getTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Navigation item class
class NavigationItem {
  final String title;
  final String route;

  NavigationItem({
    required this.title,
    required this.route,
  });
}
