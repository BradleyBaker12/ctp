// lib/pages/offers_page.dart

import 'package:ctp/components/custom_app_bar.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/offer_card.dart';
import 'package:ctp/pages/home_page.dart';
import 'package:ctp/pages/profile_page.dart';
import 'package:ctp/pages/truck_page.dart';
import 'package:ctp/pages/vehicles_list.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:ctp/components/web_navigation_bar.dart';
import 'package:provider/provider.dart';
import 'package:ctp/utils/navigation.dart';

// Simple data class for navigation items.
class NavigationItem {
  final String title;
  final String route;

  NavigationItem({
    required this.title,
    required this.route,
  });
}

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  OffersPageState createState() => OffersPageState();
}

class OffersPageState extends State<OffersPage> with RouteAware {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Screen size helpers.
  bool get _isLargeScreen => MediaQuery.of(context).size.width > 900;
  bool get _isCompactNavigation => MediaQuery.of(context).size.width <= 1100;

  int selectedIndex = 2; // Default to Offers tab
  String get userRole =>
      Provider.of<UserProvider>(context, listen: false).getUserRole;

  late OfferProvider _offerProvider;
  final RouteObserver<PageRoute<dynamic>> routeObserver =
      RouteObserver<PageRoute<dynamic>>();

  bool _isInit = true; // To ensure _fetchOffers is called only once initially

  // Tab state – "All", "In Progress", "Successful", or "Rejected"
  String _selectedTab = 'All';

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
    print('[OffersPage] initState called');
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
    print('[OffersPage] dispose called');
    super.dispose();
  }

  // RouteAware methods
  @override
  void didPush() {
    print('[OffersPage] didPush called');
    _fetchOffers();
  }

  @override
  void didPopNext() {
    print('[OffersPage] didPopNext called');
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userRole = userProvider.getUserRole.toLowerCase().trim();

      print('''
      === FETCH OFFERS DEBUG ===
      Current User ID: ${user.uid}
      User Role: $userRole
      User Email: ${user.email}
      ''');

      // Changed call: pass limit null to fetch all offers.
      await _offerProvider.fetchOffers(user.uid, userRole, limit: null);

      print('''
      === FETCHED OFFERS RESULT ===
      Total Offers: ${_offerProvider.offers.length}
      ''');

      for (var offer in _offerProvider.offers) {
        print('''
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

  ///
  /// Filtering logic (4 tabs):
  /// 1. ALL: Show everything.
  /// 2. IN_PROGRESS: Show everything EXCEPT "rejected", "completed", "successful".
  /// 3. SUCCESSFUL: Show only "completed" or "successful".
  /// 4. REJECTED: Show only "rejected".
  ///
  List<dynamic> _filterOffers(String status) {
    // First, filter out any sold offers
    final offers = _offerProvider.offers.where((offer) {
      final lowerStatus = offer.offerStatus.toLowerCase();
      return lowerStatus != 'sold';
    }).toList();

    switch (status.toUpperCase()) {
      case 'ALL':
        return offers; // Show everything except sold
      case 'IN PROGRESS':
        // Exclude "rejected", "successful", "completed"
        return offers.where((offer) {
          final lowerStatus = offer.offerStatus.toLowerCase();
          return lowerStatus != 'rejected' &&
              lowerStatus != 'successful' &&
              lowerStatus != 'completed';
        }).toList();
      case 'SUCCESSFUL':
        // Show "successful" or "completed"
        return offers.where((offer) {
          final lowerStatus = offer.offerStatus.toLowerCase();
          return lowerStatus == 'successful' || lowerStatus == 'completed';
        }).toList();
      case 'REJECTED':
        // Show only "rejected"
        return offers
            .where((offer) => offer.offerStatus.toLowerCase() == 'rejected')
            .toList();
      default:
        // If unknown status passed, return empty list.
        return [];
    }
  }

  // Helper method to get the count for each tab.
  int _getFilteredCount(String status) {
    return _filterOffers(status).length;
  }

  // Method to show the navigation drawer (for compact navigation).
  void _showNavigationDrawer(List<NavigationItem> items) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final currentRoute = ModalRoute.of(context)?.settings.name ?? '/offers';
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

  /// Builds a sticky tab bar using a SliverPersistentHeader.
  Widget _buildStickyTabs() {
    return Container(
      color: Colors.transparent,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _buildTabButton('All (${_getFilteredCount("ALL")})', 'All'),
              const SizedBox(width: 12),
              _buildTabButton(
                  'In Progress (${_getFilteredCount("IN PROGRESS")})',
                  'In Progress'),
              const SizedBox(width: 12),
              _buildTabButton('Successful (${_getFilteredCount("SUCCESSFUL")})',
                  'Successful'),
              const SizedBox(width: 12),
              _buildTabButton(
                  'Rejected (${_getFilteredCount("REJECTED")})', 'Rejected'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, String tab) {
    bool isSelected = _selectedTab == tab;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tab;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange : Colors.black,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.blue,
            width: 1.0,
          ),
        ),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Helper method to calculate cross-axis count based on screen width
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

  /// Builds the list of OfferCards as a sliver grid
  Widget _buildOffersSliver() {
    // Get and sort the filtered offers
    List offers = _filterOffers(_selectedTab);
    offers.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;
      if (aDate == null && bDate == null) return 0;
      if (bDate == null) return -1;
      if (aDate == null) return 1;
      return bDate.compareTo(aDate);
    });

    if (offers.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            'No offers found in this category.',
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
          childAspectRatio: 0.85, // Adjust this value to control card height
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return OfferCard(offer: offers[index]);
          },
          childCount: offers.length,
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

  @override
  Widget build(BuildContext context) {
    // Determine whether to show bottom navigation.
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
                        currentRoute: '/offers',
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
                        currentRoute: '/offers',
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
            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: Colors.transparent,
              appBar: _isLargeScreen || kIsWeb
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(70),
                      child: WebNavigationBar(
                        isCompactNavigation: _isCompactNavigation,
                        currentRoute: '/offers',
                        onMenuPressed: () =>
                            _showNavigationDrawer(navigationItems),
                      ),
                    )
                  : CustomAppBar(),
              body: CustomScrollView(
                slivers: [
                  // Header section with "OFFERS" title and image.
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
                              'OFFERS',
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
                  // Sticky tab bar.
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      minHeight: 60,
                      maxHeight: 60,
                      child: _buildStickyTabs(),
                    ),
                  ),
                  // Offers list.
                  _buildOffersSliver(),
                ],
              ),
              bottomNavigationBar: showBottomNav
                  ? CustomBottomNavigation(
                      selectedIndex: selectedIndex,
                      onItemTapped: (index) async {
                        if (userRole == 'dealer') {
                          // Dealer navigation.
                          if (index == 0) {
                            await MyNavigator.pushReplacement(
                                context, const HomePage());
                          } else if (index == 1) {
                            await MyNavigator.pushReplacement(
                                context, const TruckPage());
                          } else if (index == 2) {
                            await MyNavigator.pushReplacement(
                                context, const OffersPage());
                          }
                        } else if (userRole == 'transporter') {
                          // Transporter navigation.
                          if (index == 0) {
                            await MyNavigator.pushReplacement(
                                context, const HomePage());
                          } else if (index == 1) {
                            await MyNavigator.pushReplacement(
                                context, const VehiclesListPage());
                          } else if (index == 2) {
                            await MyNavigator.pushReplacement(
                                context, const OffersPage());
                          } else if (index == 3) {
                            await MyNavigator.pushReplacement(
                                context, ProfilePage());
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

/// A custom SliverPersistentHeaderDelegate for the sticky tab bar.
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverTabBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight > minHeight ? maxHeight : minHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
