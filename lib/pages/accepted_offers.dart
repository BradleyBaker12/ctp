import 'package:ctp/components/custom_app_bar.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/offer_card.dart';
import 'package:ctp/components/web_navigation_bar.dart';
import 'package:ctp/pages/home_page.dart';
import 'package:ctp/pages/profile_page.dart';
import 'package:ctp/pages/truck_page.dart';
import 'package:ctp/pages/vehicles_list.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Simple data class for navigation items.
class NavigationItem {
  final String title;
  final String route;

  NavigationItem({
    required this.title,
    required this.route,
  });
}

class AcceptedOffersPage extends StatefulWidget {
  const AcceptedOffersPage({super.key});

  @override
  State<AcceptedOffersPage> createState() => _AcceptedOffersPageState();
}

class _AcceptedOffersPageState extends State<AcceptedOffersPage>
    with RouteAware {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Screen size helpers.
  bool get _isLargeScreen => MediaQuery.of(context).size.width > 900;
  bool get _isCompactNavigation => MediaQuery.of(context).size.width <= 1100;

  int selectedIndex =
      2; // If you’re reusing bottom nav, pick a suitable default
  String get userRole =>
      Provider.of<UserProvider>(context, listen: false).getUserRole;

  late OfferProvider _offerProvider;
  final RouteObserver<PageRoute<dynamic>> routeObserver =
      RouteObserver<PageRoute<dynamic>>();

  bool _isInit = true; // To ensure _fetchOffers is called once initially

  // Build your navigation items according to userRole
  List<NavigationItem> get navigationItems {
    final userRole =
        Provider.of<UserProvider>(context, listen: false).getUserRole;
    return userRole == 'dealer'
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
  }

  @override
  void initState() {
    super.initState();
    debugPrint('[AcceptedOffersPage] initState called');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _offerProvider = Provider.of<OfferProvider>(context, listen: false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchOffers());
      _isInit = false;
    }

    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    debugPrint('[AcceptedOffersPage] dispose called');
    super.dispose();
  }

  // RouteAware methods
  @override
  void didPush() {
    debugPrint('[AcceptedOffersPage] didPush called');
    _fetchOffers();
  }

  @override
  void didPopNext() {
    debugPrint('[AcceptedOffersPage] didPopNext called');
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userRole = userProvider.getUserRole.toLowerCase().trim();

      debugPrint('''
      === FETCH ACCEPTED OFFERS DEBUG ===
      Current User ID: ${user.uid}
      User Role: $userRole
      User Email: ${user.email}
      ''');

      await _offerProvider.fetchOffers(user.uid, userRole);

      debugPrint('''
      === FETCHED OFFERS RESULT (ALL) ===
      Total Offers: ${_offerProvider.offers.length}
      ''');

      for (var offer in _offerProvider.offers) {
        debugPrint('''
        Offer Details:
          ID: ${offer.offerId}
          DealerId: ${offer.dealerId}
          TransporterId: ${offer.transporterId}
          Status: ${offer.offerStatus}
          Created: ${offer.createdAt}
        ''');
      }
    }
  }

  /// This method filters ONLY the "accepted" offers.
  /// Make sure this matches your actual "accepted" status string from the backend.
  List<dynamic> _filterAcceptedOffers() {
    final allOffers = _offerProvider.offers;
    return allOffers
        .where(
          (offer) => offer.offerStatus.toLowerCase() == 'accepted',
        )
        .toList();
  }

  /// A helper method to calculate cross-axis count based on screen width.
  int _calculateCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= 1400) {
      return 4; // Extra large screens: 4 cards
    } else if (width >= 1100) {
      return 3; // Large screens: 3 cards
    } else if (width >= 700) {
      return 2; // Medium screens: 2 cards
    } else {
      return 1; // Mobile: 1 card
    }
  }

  /// Builds the list of OfferCards as a sliver grid, but ONLY for accepted offers.
  Widget _buildAcceptedOffersSliver() {
    // Get and sort the accepted offers
    final acceptedOffers = _filterAcceptedOffers()
      ..sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        // Sort descending by created date
        if (aDate == null && bDate == null) return 0;
        if (bDate == null) return -1;
        if (aDate == null) return 1;
        return bDate.compareTo(aDate);
      });

    if (acceptedOffers.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            'No accepted offers found.',
            style: _customFont(16, FontWeight.normal, Colors.white),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _calculateCrossAxisCount(context),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85, // Adjust as needed
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return OfferCard(offer: acceptedOffers[index]);
          },
          childCount: acceptedOffers.length,
        ),
      ),
    );
  }

  TextStyle _customFont(double fontSize, FontWeight fontWeight, Color color) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFamily: 'Montserrat',
    );
  }

  // Method to show the navigation drawer (for compact navigation) if you still want to reuse
  // the same logic from your existing code.
  void _showNavigationDrawer(List<NavigationItem> items) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final currentRoute =
            ModalRoute.of(context)?.settings.name ?? '/acceptedOffers';
        return Stack(
          children: [
            // Semi-transparent background.
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black54,
              ),
            ),
            // Sliding drawer.
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
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black,
                        Color(0xFF2F7FFD),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header with logo.
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
                      // Navigation items.
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: items.map((item) {
                            return ListTile(
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

  @override
  Widget build(BuildContext context) {
    // Determine whether to show bottom navigation
    final bool showBottomNav = !_isLargeScreen && !kIsWeb;

    return GradientBackground(
      child: Consumer<OfferProvider>(
        builder: (context, offerProvider, child) {
          if (offerProvider.isFetching) {
            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: Colors.transparent,
              appBar: _isLargeScreen || kIsWeb
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(70),
                      child: WebNavigationBar(
                        isCompactNavigation: _isCompactNavigation,
                        currentRoute: '/in-progress',
                        onMenuPressed: () =>
                            _showNavigationDrawer(navigationItems),
                      ),
                    )
                  : CustomAppBar(),
              body: Center(
                child: Image.asset(
                  'lib/assets/Loading_Logo_CTP.gif',
                  width: 100,
                  height: 100,
                ),
              ),
            );
          } else if (offerProvider.errorMessage != null) {
            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: Colors.transparent,
              appBar: _isLargeScreen || kIsWeb
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(70),
                      child: WebNavigationBar(
                        isCompactNavigation: _isCompactNavigation,
                        currentRoute: '/acceptedOffers',
                        onMenuPressed: () =>
                            _showNavigationDrawer(navigationItems),
                      ),
                    )
                  : CustomAppBar(),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      offerProvider.errorMessage!,
                      style: _customFont(16, FontWeight.normal, Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchOffers,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          } else {
            // All data fetched successfully, show only ACCEPTED offers
            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: Colors.transparent,
              appBar: _isLargeScreen || kIsWeb
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(70),
                      child: WebNavigationBar(
                        isCompactNavigation: _isCompactNavigation,
                        currentRoute: '/acceptedOffers',
                        onMenuPressed: () =>
                            _showNavigationDrawer(navigationItems),
                      ),
                    )
                  : CustomAppBar(),
              body: CustomScrollView(
                slivers: [
                  // Header section with "ACCEPTED OFFERS" title and image.
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'lib/assets/shaking_hands.png',
                              width: 30,
                              height: 30,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'ACCEPTED OFFERS',
                              style: TextStyle(
                                color: Color(0xFFFF4E00),
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  // The actual Sliver grid of accepted offers
                  _buildAcceptedOffersSliver(),
                ],
              ),
              bottomNavigationBar: showBottomNav
                  ? CustomBottomNavigation(
                      selectedIndex: selectedIndex,
                      onItemTapped: (index) {
                        // Adjust for your own navigation logic
                        if (userRole == 'dealer') {
                          // Dealer navigation
                          if (index == 0) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomePage(),
                              ),
                            );
                          } else if (index == 1) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TruckPage(),
                              ),
                            );
                          } else if (index == 2) {
                            // Possibly go to OffersPage or something else
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AcceptedOffersPage(),
                              ),
                            );
                          }
                        } else if (userRole == 'transporter') {
                          // Transporter navigation
                          if (index == 0) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomePage(),
                              ),
                            );
                          } else if (index == 1) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VehiclesListPage(),
                              ),
                            );
                          } else if (index == 2) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AcceptedOffersPage(),
                              ),
                            );
                          } else if (index == 3) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfilePage(),
                              ),
                            );
                          }
                        }
                      },
                    )
                  : null,
            );
          }
        },
      ),
    );
  }
}
