import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/constants.dart';
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
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // <-- Import this for kIsWeb
import 'dart:io';
import 'dart:typed_data';
import 'package:ctp/components/web_navigation_bar.dart';
import 'package:ctp/components/web_footer.dart';

// Import your new truck card
import 'package:ctp/components/truck_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Add this getter for compact navigation
  bool get _isCompactNavigation => MediaQuery.of(context).size.width <= 1100;

  // Bottom nav index
  int _selectedIndex = 0;
  // Initialization future
  late Future<void> _initialization;

  // Providers & variables
  final OfferProvider _offerProvider = OfferProvider();
  bool _showEndMessage = false;
  late List<String> likedVehicles;
  late List<String> dislikedVehicles;

  // The main vehicles we display
  ValueNotifier<List<Vehicle>> displayedVehiclesNotifier =
      ValueNotifier<List<Vehicle>>([]);

  List<Vehicle> swipedVehicles = []; // (If you want to track them, can remove)
  int loadedVehicleIndex = 0;
  bool _hasReachedEnd = false;
  List<Vehicle> recentVehicles = [];
  List<Offer> recentOffers = [];
  List<Vehicle> todayVehicles = [];
  List<Vehicle> yesterdayVehicles = [];

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

  // ADDED FOR CAROUSEL
  late PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();

    _initialization = _initializeData();
    _checkPaymentStatusForOffers();

    // Initialize the page controller for the carousel
    _pageController = PageController(initialPage: 0);

    // Load filtered transporter vehicles after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransporterVehicles();
    });
  }

  @override
  void dispose() {
    // Dispose the page controller
    _pageController.dispose();
    super.dispose();
  }

  /// Helper function to provide different font sizes for phone vs. tablet.
  /// Adjust the breakpoint or sizes as desired.
  double _adaptiveTextSize(
    BuildContext context,
    double phoneSize,
    double tabletSize,
  ) {
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

      // Fetch today's and yesterday's vehicles
      todayVehicles = await vehicleProvider.fetchVehiclesForToday();
      yesterdayVehicles = await vehicleProvider.fetchVehiclesForYesterday();

      // Combine both lists -> displayedVehicles
      displayedVehiclesNotifier.value = [...todayVehicles, ...yesterdayVehicles]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // newest first

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

  // Loads vehicles uploaded by the current user with at least one offer (for transporters)
  void _loadTransporterVehicles() async {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);

    await userProvider.fetchUserData();
    final userId = userProvider.userId;
    await offerProvider.fetchOffers(userId!, userProvider.getUserRole);

    // Filter vehicles:
    final transporterVehicles = vehicleProvider.vehicles.where((vehicle) {
      final hasOffers = offerProvider.offers.any(
        (offer) => offer.vehicleId == vehicle.id,
      );
      return vehicle.userId == userId && hasOffers;
    }).toList();

    // Could assign them to displayedVehicles if desired, or keep for later usage
    // displayedVehiclesNotifier.value = transporterVehicles;
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

  // If you previously had a "like" action from swiping, you can keep it:
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

  // For "dislike"
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

  // This callback can be used by the TruckCard "heart" icon:
  void _handleInterestedVehicle(Vehicle vehicle) async {
    await _likeVehicle(vehicle.id);
    setState(() {});
  }

  // Nav item tapped
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Web navigation bar
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
                  // Navigation links (only in full mode)
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
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                return CircleAvatar(
                  radius: 18,
                  backgroundImage: userProvider.getProfileImageUrl != null
                      ? NetworkImage(userProvider.getProfileImageUrl)
                      : const AssetImage('lib/assets/default_profile.png')
                          as ImageProvider,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // The sliding drawer for small screens
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
              child: Container(color: Colors.black54),
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
                      colors: const [Colors.black, Color(0xFF2F7FFD)],
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
          if (!isActive) Navigator.pushNamed(context, route);
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

        // Define navigation items
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
          body: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              children: [
                Expanded(
                  child: FutureBuilder<void>(
                    future: _initialization,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Image(
                            image:
                                AssetImage('lib/assets/Loading_Logo_CTP.gif'),
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
                        return SingleChildScrollView(
                          child: _buildHomePageContent(
                              context, constraints, isTablet),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
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

    // Get userProvider and userRole
    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.getUserRole;

    return Column(
      children: [
        // Hero Section
        Column(
          children: [
            if (!kIsWeb) SizedBox(height: screenHeight * 0.1),
            // Hero image
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: screenWidth > 900
                        ? screenHeight * 0.6 // Web view - taller
                        : screenHeight * 0.45, // Mobile view - shorter
                  ),
                  child: Image.asset(
                    'lib/assets/HomePageHero.png',
                    width: screenWidth,
                    fit: screenWidth > 900 ? BoxFit.cover : BoxFit.fill,
                  ),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(1),
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.35, 0.7],
                      ),
                    ),
                  ),
                ),
              ],
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
                  SizedBox(height: screenHeight * 0.02),
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
        SizedBox(height: screenHeight * 0.05),

        // Only for dealer: show preferred brands
        if (userRole == 'dealer')
          _buildPreferredBrandsSection(userProvider, constraints, isTablet),

        SizedBox(height: screenHeight * 0.05),

        // End message if needed
        if (_showEndMessage) ...[
          Text(
            "You've seen all the available trucks.",
            style: _getTextStyle(
              fontSize: _adaptiveTextSize(context, 18, 20),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.05),
          Text(
            "The list will be updated tomorrow.",
            style: _getTextStyle(
              fontSize: _adaptiveTextSize(context, 16, 18),
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        // For dealers: NEW ARRIVALS
        if (userRole == 'dealer') ...[
          Text(
            "🔥 NEW ARRIVALS",
            style: _getTextStyle(
              fontSize: _adaptiveTextSize(context, 24, 26),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2F7FFF),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            "Discover the newest additions to our fleet, ready for your next venture.",
            style: _getTextStyle(
              fontSize: _adaptiveTextSize(context, 16, 18),
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.05),
          ValueListenableBuilder<List<Vehicle>>(
            valueListenable: displayedVehiclesNotifier,
            builder: (context, displayedVehicles, child) {
              if (displayedVehicles.isEmpty) {
                return Container(
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
                      Icon(Icons.local_shipping,
                          size: 50, color: AppColors.orange),
                      const SizedBox(height: 10),
                      Text(
                        'NO NEW TRUCKS AVAILABLE',
                        style: _getTextStyle(
                          fontSize: _adaptiveTextSize(context, 18, 20),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back later for new additions',
                        style: _getTextStyle(
                          fontSize: _adaptiveTextSize(context, 14, 16),
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              // ADDED FOR CAROUSEL:
              return _buildTruckCarousel(displayedVehicles);
            },
          ),
          SizedBox(height: screenHeight * 0.03),
        ],

        // For transporter, show "YOUR VEHICLES WITH OFFERS" (Optional)...

        SizedBox(height: screenHeight * 0.015),

        // RECENT PENDING OFFERS (example usage)
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/pendingOffers'),
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
              SizedBox(height: screenHeight * 0.02),
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
        SizedBox(height: screenHeight * 0.02),

        if (recentOffers.isEmpty) ...[
          // No offers placeholder
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
          // Show your OfferCard or something similar in a grid or list
          SizedBox(height: screenHeight * 0.01),
          LayoutBuilder(
            builder: (context, constraints) {
              // Determine number of cards per row
              int cardsPerRow;
              if (constraints.maxWidth > 1400) {
                cardsPerRow = 4;
              } else if (constraints.maxWidth > 1100) {
                cardsPerRow = 3;
              } else if (constraints.maxWidth > 700) {
                cardsPerRow = 2;
              } else {
                cardsPerRow = 1;
              }

              return Wrap(
                spacing: 16,
                runSpacing: 16,
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
        SizedBox(height: screenHeight * 0.08),
        if (kIsWeb) const WebFooter(),
      ],
    );
  }

  /// Builds a PageView carousel of TruckCards with left/right arrows
  Widget _buildTruckCarousel(List<Vehicle> vehicles) {
    if (vehicles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 560, // Enough height to fit your TruckCard
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left Arrow
          IconButton(
            icon: const Icon(Icons.arrow_left, color: Colors.white, size: 40),
            onPressed: _currentPageIndex > 0
                ? () {
                    setState(() {
                      _currentPageIndex--;
                    });
                    _pageController.animateToPage(
                      _currentPageIndex,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null, // disable if we're at page 0
          ),

          // The PageView that shows one TruckCard at a time
          SizedBox(
            width: 400, // Constrain the width of each card
            child: PageView.builder(
              controller: _pageController,
              itemCount: vehicles.length,
              onPageChanged: (page) {
                setState(() {
                  _currentPageIndex = page;
                });
              },
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return Center(
                  child: TruckCard(
                    vehicle: vehicle,
                    onInterested: _handleInterestedVehicle,
                    borderColor: Color(0xFFFFC82F),
                  ),
                );
              },
            ),
          ),

          // Right Arrow
          IconButton(
            icon: const Icon(Icons.arrow_right, color: Colors.white, size: 40),
            onPressed: _currentPageIndex < vehicles.length - 1
                ? () {
                    setState(() {
                      _currentPageIndex++;
                    });
                    _pageController.animateToPage(
                      _currentPageIndex,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                : null, // disable if we're at the last page
          ),
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

    final double cardWidth = isTablet ? screenWidth * 0.2 : screenWidth * 0.35;
    final double cardHeight = cardWidth; // Square

    final double containerWidth =
        isTablet ? screenWidth * 0.5 : screenWidth * 0.9;

    return Center(
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
              mainAxisAlignment: MainAxisAlignment.center,
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
                SizedBox(width: screenWidth * 0.02),
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

  /// Preferred brands section for dealers
  Widget _buildPreferredBrandsSection(
    UserProvider userProvider,
    BoxConstraints constraints,
    bool isTablet,
  ) {
    final preferredBrands = userProvider.getPreferredBrands;
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;

    final double maxContentWidth = isTablet ? screenWidth * 0.8 : screenWidth;
    final double logoSize = kIsWeb
        ? (screenWidth > 1200
            ? 80
            : screenWidth > 900
                ? 85
                : 70)
        : screenHeight * 0.05;
    final double containerHeight = kIsWeb ? logoSize * 1.4 : logoSize * 1.2;

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
                  height: containerHeight,
                  child: Center(
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
                                horizontal: kIsWeb
                                    ? screenWidth * 0.015
                                    : screenWidth * 0.02,
                              ),
                              width: logoSize,
                              height: logoSize,
                              alignment: Alignment.center,
                              child: logoPath != null
                                  ? Image.asset(
                                      logoPath,
                                      width: logoSize * 0.9,
                                      height: logoSize * 0.9,
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
      case 'IVECO':
        return 'lib/assets/Logo/IVECO.png';
      default:
        return null;
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

// Navigation item class
class NavigationItem {
  final String title;
  final String route;

  NavigationItem({
    required this.title,
    required this.route,
  });
}
