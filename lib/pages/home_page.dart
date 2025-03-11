import 'dart:math' as Math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_app_bar.dart';
import 'package:ctp/components/offer_card.dart';
import 'package:ctp/components/truck_card.dart'; // Your custom TruckCard
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/trailerForms/trailer_upload_screen.dart';
import 'package:ctp/pages/truckForms/vehilce_upload_screen.dart';
import 'package:ctp/pages/truck_page.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/web_navigation_bar.dart';
import 'package:ctp/components/web_footer.dart';
import 'package:ctp/utils/navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  /// If the screen width is <= 1100, we use a more "compact" navigation approach (mobile/tablet).
  bool get _isCompactNavigation => MediaQuery.of(context).size.width <= 1100;

  /// Bottom nav index
  int _selectedIndex = 0;

  /// Initialization future
  late Future<void> _initialization;

  /// Providers & variables
  final OfferProvider _offerProvider = OfferProvider();
  final bool _showEndMessage = false;
  late List<String> likedVehicles;
  late List<String> dislikedVehicles;

  /// ValueNotifier for the main vehicles we display
  ValueNotifier<List<Vehicle>> displayedVehiclesNotifier =
      ValueNotifier<List<Vehicle>>([]);

  List<Vehicle> swipedVehicles = [];
  int loadedVehicleIndex = 0;
  final bool _hasReachedEnd = false;
  List<Vehicle> recentVehicles = [];
  List<Offer> recentOffers = [];
  List<Vehicle> todayVehicles = [];
  List<Vehicle> yesterdayVehicles = [];

  /// Add new properties for web navigation
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool get _isLargeScreen => MediaQuery.of(context).size.width > 900;

  /// Variables for carousel usage
  late PageController _pageController;
  int _currentPageIndex = 0;

  // Add back the T&C dialog property
  bool _termsDialogShown = false;

  @override
  void initState() {
    super.initState();

    // Immediately check the user's account & role status after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAccountStatus();
    });

    // Initialize data
    _initialization = _initializeData();
    _checkPaymentStatusForOffers();

    _pageController = PageController(initialPage: 0);

    // Load any "transporter vehicles" if relevant
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTransporterVehicles();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Checks user role & account status, and also checks VAT/Reg. Number:
  ///
  /// 1) If `userRole == 'pending'`, route to `/tradingCategory`
  /// 2) Else if `accountStatus == 'pending'`, route to `/waiting-for-approval`
  /// 3) Else if `userRole == 'dealer'` and missing VAT or Reg. => `/dealerRegistration`
  /// 4) Else if `userRole == 'transporter'` and missing VAT or Reg. => `/transporterRegistration`
  Future<void> _checkAccountStatus() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.fetchUserData();

    // Break chain at first missing requirement

    // 1. Phone number check is most important
    final String? phoneNumber = userProvider.getPhoneNumber;
    if (phoneNumber == null || phoneNumber.isEmpty) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/phoneNumber');
      }
      return; // Phone number page will handle next steps
    }

    // 2. User role check
    final userRole = userProvider.getUserRole.toLowerCase();
    if (userRole == 'pending') {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/tradingCategory');
      }
      return; // Trading category page will handle next steps
    }

    // 3. VAT/Registration check
    final vatNumber = userProvider.getVatNumber;
    final regNumber = userProvider.getRegistrationNumber;

    bool hasValidRegistration = !(vatNumber == null ||
        vatNumber.isEmpty ||
        regNumber == null ||
        regNumber.isEmpty);

    if (!hasValidRegistration) {
      if (mounted) {
        if (userRole == 'dealer') {
          Navigator.of(context).pushReplacementNamed('/dealerRegister');
        } else if (userRole == 'transporter') {
          Navigator.of(context).pushReplacementNamed('/transporterRegister');
        }
      }
      return; // Registration pages will handle next steps
    }

    // 4. Account status check (only if all above are valid)
    final accountStatus = userProvider.getAccountStatus.toLowerCase();
    if (accountStatus == 'pending') {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/waiting-for-approval');
      }
      return;
    }
  }

  /// Adaptive text size helper
  double _adaptiveTextSize(
      BuildContext context, double phoneSize, double tabletSize) {
    bool isTablet = MediaQuery.of(context).size.width >= 600;
    return isTablet ? tabletSize : phoneSize;
  }

  /// Helper to unify text styling with Google Fonts
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

  /// Initialize data: user data, vehicles, offers, etc.
  Future<void> _initializeData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);

    try {
      await userProvider.fetchUserData();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null || userProvider.userId == null) {
        // If not logged in or userId is null, go to /login
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // Check if phone number is empty
      final String? phoneNumber = userProvider.getPhoneNumber;
      if (phoneNumber == null || phoneNumber.isEmpty) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/phoneNumber');
          return;
        }
      }

      // Possibly check if user is admin or normal user
      String userRole = userProvider.getUserRole;

      // Example route decision for admin vs. normal user
      if (userRole == 'admin' || userRole == 'sales representative') {
        // If on /home but is admin -> /admin-home
        if (ModalRoute.of(context)?.settings.name != '/admin-home') {
          Navigator.pushReplacementNamed(context, '/admin-home');
        }
      } else {
        // Else normal user -> /home
        if (ModalRoute.of(context)?.settings.name != '/home') {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }

      // Fetch today’s/yesterday’s vehicles
      todayVehicles = await vehicleProvider.fetchVehiclesForToday();
      yesterdayVehicles = await vehicleProvider.fetchVehiclesForYesterday();

      // Combine them into the displayed list
      displayedVehiclesNotifier.value = [...todayVehicles, ...yesterdayVehicles]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Fetch offers & user preferences (liked/disliked)
      await _offerProvider.fetchOffers(
          currentUser.uid, userProvider.getUserRole);
      likedVehicles = List<String>.from(userProvider.getLikedVehicles);
      dislikedVehicles = List<String>.from(userProvider.getDislikedVehicles);

      // Update recentOffers with the 5 most recent offers
      setState(() {
        recentOffers = List<Offer>.from(_offerProvider.offers);
        // recentOffers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (recentOffers.length > 5) {
          recentOffers = recentOffers.sublist(0, 5);
        }
      });
    } catch (e, stackTrace) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to initialize data. Please try again.'),
        ),
      );
      await FirebaseCrashlytics.instance.recordError(e, stackTrace);
    }
  }

  /// Loads vehicles uploaded by the current user that have at least one offer (transporter flow)
  Future<void> _loadTransporterVehicles() async {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);

    await userProvider.fetchUserData();
    final userId = userProvider.userId;
    await offerProvider.fetchOffers(userId!, userProvider.getUserRole);

    // If needed, you can filter vehicles this user has posted that have offers
    final transporterVehicles = vehicleProvider.vehicles.where((vehicle) {
      final hasOffers =
          offerProvider.offers.any((offer) => offer.vehicleId == vehicle.id);
      return vehicle.userId == userId && hasOffers;
    }).toList();

    // You could display these, or keep for any other purpose
    // displayedVehiclesNotifier.value = transporterVehicles;
  }

  /// Check each offer’s payment status, update if accepted
  Future<void> _checkPaymentStatusForOffers() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    for (var offer in _offerProvider.offers) {
      try {
        DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
            .collection('offers')
            .doc(offer.offerId)
            .get();

        if (offerSnapshot.exists) {
          String paymentStatus = offerSnapshot['paymentStatus'] ?? '';

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

  /// Like a vehicle
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

  /// Dislike a vehicle
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

  /// When TruckCard user taps the 'Interested' heart button
  void _handleInterestedVehicle(dynamic vehicle) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.getLikedVehicles.contains(vehicle.id)) {
        await userProvider.unlikeVehicle(vehicle.id);
      } else {
        await userProvider.likeVehicle(vehicle.id);
      }
      setState(() {});
    } catch (e) {
      print('Error in _handleInterestedVehicle: $e');
    }
  }

  /// Bottom nav item tapped
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Build the top web navigation bar (if using your own)
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
            // Left section - Hamburger menu (only for web, if compact)
            if (kIsWeb && _isCompactNavigation)
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                onPressed: () {
                  _showNavigationDrawer(navigationItems);
                },
              ),
            // Center - Logo and full nav items (if not compact)
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
            // Right - Profile avatar
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

  /// Display a sliding drawer (for mobile) with navigation items
  void _showNavigationDrawer(List<NavigationItem> items) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final currentRoute = ModalRoute.of(context)?.settings.name ?? '/home';
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black54),
            ),
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
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: items.map((item) {
                            bool isActive = currentRoute == item.route;
                            return ListTile(
                              selected: isActive,
                              selectedColor: const Color(0xFFFF4E00),
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  color: isActive
                                      ? const Color(0xFFFF4E00)
                                      : Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
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
                  border: Border.all(color: const Color(0xFFFF4E00), width: 2),
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

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isTablet = constraints.maxWidth >= 600;
        bool showBottomNav = !_isLargeScreen && !kIsWeb;
        final userProvider = Provider.of<UserProvider>(context);
        final userRole = userProvider.getUserRole;

        // Build a list of nav items depending on userRole
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
          drawer: (kIsWeb && _isCompactNavigation)
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
                        // Only show T&C dialog if never accepted
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final userProvider =
                              Provider.of<UserProvider>(context, listen: false);
                          if (!_termsDialogShown &&
                              !userProvider.hasAcceptedTerms &&
                              userProvider.hasCompletedRegistration) {
                            _termsDialogShown = true;
                            _showTermsAndConditionsDialog();
                          }
                        });

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

  /// Builds the main content of the home page
  Widget _buildHomePageContent(
      BuildContext context, BoxConstraints constraints, bool isTablet) {
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;

    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.getUserRole;

    return Column(
      children: [
        // Hero section
        Column(
          children: [
            if (!kIsWeb) SizedBox(height: screenHeight * 0.1),
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: screenWidth > 900
                        ? screenHeight * 0.6
                        : screenHeight * 0.45,
                  ),
                  child: Image.asset(
                    'lib/assets/HomePageHero.png',
                    width: screenWidth,
                    fit: screenWidth > 900 ? BoxFit.cover : BoxFit.fill,
                  ),
                ),
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
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.02,
                horizontal: screenWidth * 0.05,
              ),
              child: Column(
                children: [
                  Text(
                    'Welcome ${userProvider.getUserName.toUpperCase()}',
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

        // "I AM SELLING A" / "I AM LOOKING FOR" block
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: _buildVehicleTypeSelection(userRole, constraints, isTablet),
        ),
        SizedBox(height: screenHeight * 0.05),

        // If the user is a dealer, show "Preferred Brands"
        if (userRole == 'dealer')
          _buildPreferredBrandsSection(userProvider, constraints, isTablet),
        SizedBox(height: screenHeight * 0.05),

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

        // Dealer: "NEW ARRIVALS"
        if (userRole == 'dealer') ...[
          Text(
            "🔥 NEW ARRIVALS",
            style: _getTextStyle(
              fontSize: _adaptiveTextSize(
                context,
                24,
                Math.min(80, MediaQuery.of(context).size.width * 0.04),
              ),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2F7FFF),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            "Discover the newest additions to our fleet, ready for your next venture.",
            style: _getTextStyle(
              fontSize: _adaptiveTextSize(
                context,
                24,
                Math.min(30, MediaQuery.of(context).size.width * 0.03),
              ),
              fontWeight: FontWeight.w400,
              color: Colors.white,
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
                    border:
                        Border.all(color: const Color(0xFF2F7FFF), width: 1),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.local_shipping,
                          size: 50, color: AppColors.orange),
                      const SizedBox(height: 10),
                      Text(
                        'NO NEW TRUCKS AVAILABLE',
                        style: _getTextStyle(
                          fontSize: _adaptiveTextSize(context, 20, 22),
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
              // Carousel for new arrivals
              return _buildTruckCarousel(displayedVehicles);
            },
          ),
          SizedBox(height: screenHeight * 0.03),
        ],

        // Example pending offers section
        SizedBox(height: screenHeight * 0.015),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/pendingOffers'),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'lib/assets/shaking_hands.png',
                    width: MediaQuery.of(context).size.width * 0.04,
                    height: MediaQuery.of(context).size.width * 0.04,
                  ),
                  SizedBox(width: screenHeight * 0.01),
                  Text(
                    'RECENT PENDING OFFERS',
                    style: _getTextStyle(
                      fontSize: _adaptiveTextSize(
                        context,
                        24,
                        Math.min(80, MediaQuery.of(context).size.width * 0.04),
                      ),
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
                  fontSize: _adaptiveTextSize(
                    context,
                    24,
                    Math.min(30, MediaQuery.of(context).size.width * 0.03),
                  ),
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        if (recentOffers.isEmpty) ...[
          // No offers
          Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2F7FFF), width: 1),
            ),
            child: Column(
              children: [
                Image.asset('lib/assets/shaking_hands.png',
                    height: 50, width: 50),
                const SizedBox(height: 10),
                Text(
                  'NO OFFERS YET',
                  style: _getTextStyle(
                    fontSize: _adaptiveTextSize(context, 20, 22),
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

    final bool isMobile = MediaQuery.of(context).size.width <= 600;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: 616, // ~600 for card + a bit of margin
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Left arrow (only for non-mobile)
          if (!isMobile) ...[
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_left_outlined,
                  color: Color(0xFF2F7FFD),
                  size: 40,
                ),
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
                    : null,
              ),
            ),
            const SizedBox(width: 50),
          ],
          SizedBox(
            width: isMobile ? screenWidth : 400,
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
                return Padding(
                  padding: isMobile
                      ? EdgeInsets.symmetric(horizontal: screenWidth * 0.1)
                      : EdgeInsets.zero,
                  child: Center(
                    child: TruckCard(
                      vehicle: vehicle,
                      onInterested: _handleInterestedVehicle,
                      borderColor: const Color(0xFFFFC82F),
                    ),
                  ),
                );
              },
            ),
          ),
          // Right arrow (only for non-mobile)
          if (!isMobile) ...[
            const SizedBox(width: 50),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.keyboard_arrow_right_outlined,
                  color: Color(0xFF2F7FFD),
                  size: 40,
                ),
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
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// "I AM SELLING A" / "I AM LOOKING FOR" section
  Widget _buildVehicleTypeSelection(
      String userRole, BoxConstraints constraints, bool isTablet) {
    final screenWidth = constraints.maxWidth;
    const double containerPadding = 16.0;
    final double containerWidth = screenWidth * 0.85;
    final double innerWidth = containerWidth - (2 * containerPadding);
    const double horizontalSpacing = 16.0;
    final double cardWidth = (innerWidth - horizontalSpacing) / 2;
    final double titleFontSize = screenWidth < 600 ? 16 : 24;

    return Center(
      child: Container(
        width: containerWidth,
        padding: const EdgeInsets.all(containerPadding),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[600]!,
            width: 2.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              userRole == 'transporter' ? "I AM SELLING A" : "I AM LOOKING FOR",
              style: _getTextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: horizontalSpacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Trucks
                SizedBox(
                  width: cardWidth,
                  child: _buildVehicleTypeCard(
                    context,
                    cardWidth,
                    'lib/assets/truck_image.jpeg',
                    "TRUCKS",
                    const Color(0xFF2F7FFF),
                    onTap: () async {
                      if (userRole == 'transporter') {
                        await MyNavigator.push(
                          context,
                          VehicleUploadScreen(isNewUpload: true),
                        );
                      } else {
                        await MyNavigator.push(
                          context,
                          TruckPage(vehicleType: 'truck'),
                        );
                      }
                    },
                  ),
                ),
                SizedBox(width: 10),
                // Trailers
                SizedBox(
                  width: cardWidth,
                  child: _buildVehicleTypeCard(
                    context,
                    cardWidth,
                    'lib/assets/trailer_image.jpeg',
                    "TRAILERS",
                    const Color(0xFFFF4E00),
                    onTap: () async {
                      if (userRole == 'transporter') {
                        await MyNavigator.push(
                          context,
                          const TrailerUploadScreen(
                            isNewUpload: true,
                          ),
                        );
                      } else {
                        await MyNavigator.push(
                          context,
                          TruckPage(vehicleType: 'trailer'),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: horizontalSpacing),
          ],
        ),
      ),
    );
  }

  /// Builds each of the truck/trailer "cards" in the user role selection row
  Widget _buildVehicleTypeCard(
    BuildContext context,
    double cardSize,
    String imagePath,
    String label,
    Color borderColor, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardSize,
        height: cardSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cardSize * 0.04),
          border: Border.all(color: borderColor, width: cardSize * 0.01),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(cardSize * 0.04),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cardSize * 0.04),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: cardSize * 0.05),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(cardSize * 0.04),
                    bottomRight: Radius.circular(cardSize * 0.04),
                  ),
                ),
                child: Text(
                  label,
                  style: _getTextStyle(
                    fontSize: cardSize * 0.08,
                    fontWeight: FontWeight.bold,
                    color: borderColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the "Preferred Brands" section for dealers
  Widget _buildPreferredBrandsSection(
    UserProvider userProvider,
    BoxConstraints constraints,
    bool isTablet,
  ) {
    final preferredBrands = userProvider.getPreferredBrands;
    final screenWidth = constraints.maxWidth;
    final screenHeight = constraints.maxHeight;

    final double logoSize = kIsWeb
        ? (screenWidth > 1200
            ? 120
            : screenWidth > 900
                ? 85
                : 70)
        : screenHeight * 0.05;
    final double containerHeight = kIsWeb ? logoSize * 1.4 : logoSize * 1.2;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: screenWidth * 0.95),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.02,
          ),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(isTablet ? 10 : 0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heading + edit
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
                // Change: Wrap ListView.builder with a Listener and use a ScrollController
                Builder(builder: (context) {
                  final ScrollController brandScrollController =
                      ScrollController();
                  return SizedBox(
                    height: containerHeight,
                    child: Center(
                      child: Listener(
                        onPointerSignal: (pointerSignal) {
                          if (pointerSignal is PointerScrollEvent) {
                            double newOffset = brandScrollController.offset +
                                pointerSignal.scrollDelta.dy;
                            if (newOffset < 0) {
                              newOffset = 0;
                            } else if (newOffset >
                                brandScrollController
                                    .position.maxScrollExtent) {
                              newOffset = brandScrollController
                                  .position.maxScrollExtent;
                            }
                            brandScrollController.jumpTo(newOffset);
                          }
                        },
                        child: ListView.builder(
                          controller: brandScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: preferredBrands.length,
                          itemBuilder: (context, index) {
                            final brand = preferredBrands[index];
                            final logoPath = _getBrandLogoPath(brand);

                            return GestureDetector(
                              onTap: () async {
                                await MyNavigator.push(
                                  context,
                                  TruckPage(
                                      vehicleType: 'all', selectedBrand: brand),
                                );
                              },
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
                                    : Icon(Icons.image_outlined,
                                        color: Colors.white,
                                        size: logoSize * 0.8),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }),
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

  // Add back the T&C dialog method
  Future<void> _showTermsAndConditionsDialog() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            'Terms and Conditions',
            style: _getTextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please review and accept our Terms and Conditions before proceeding.',
                style: _getTextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _launchURL(
                  'https://firebasestorage.googleapis.com/v0/b/ctp-central-database.appspot.com/o/Product%20Terms%20.pdf?alt=media&token=8f27f138-afe2-4b82-83a6-9b49564b4d48',
                ),
                child: Text(
                  'View Terms and Conditions',
                  style: _getTextStyle(
                    fontSize: 16,
                    color: const Color(0xFF2F7FFD),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // If user declines, sign out
                await userProvider.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: Text(
                'Decline',
                style: _getTextStyle(
                  fontSize: 16,
                  color: const Color(0xFFFF4E00),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Accept T&C in Firestore
                await userProvider.setTermsAcceptance(true);
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                'Accept',
                style: _getTextStyle(
                  fontSize: 16,
                  color: const Color(0xFF2F7FFD),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Simple navigation item class
class NavigationItem {
  final String title;
  final String route;

  NavigationItem({required this.title, required this.route});
}
