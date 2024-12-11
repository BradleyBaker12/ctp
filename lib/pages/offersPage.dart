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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  OffersPageState createState() => OffersPageState();
}

class OffersPageState extends State<OffersPage> with RouteAware {
  late OfferProvider _offerProvider;
  final RouteObserver<PageRoute<dynamic>> routeObserver =
      RouteObserver<PageRoute<dynamic>>();

  bool _isInit = true; // To ensure _fetchOffers is called only once initially

  @override
  void initState() {
    super.initState();
    print('[OffersPage] initState called');
    // Note: Do not call _fetchOffers here as _offerProvider is not yet initialized
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isInit) {
      // Initialize OfferProvider from Provider
      _offerProvider = Provider.of<OfferProvider>(context, listen: false);
      print('[OffersPage] didChangeDependencies called');

      // **Defer the fetchOffers call to after the build phase**
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchOffers();
      });

      _isInit = false;
    }

    // Subscribe to the global RouteObserver with proper type checking
    ModalRoute<dynamic>? modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute<dynamic>) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    // Unsubscribe from the RouteObserver
    routeObserver.unsubscribe(this);
    print('[OffersPage] dispose called');
    super.dispose();
  }

  // RouteAware methods

  // Called when the page is first pushed onto the navigation stack
  @override
  void didPush() {
    print('[OffersPage] didPush called');
    // Re-fetch data
    _fetchOffers();
  }

  // Called when the page is again visible after popping back from another page
  @override
  void didPopNext() {
    print('[OffersPage] didPopNext called');
    // Re-fetch data
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userRole = userProvider.getUserRole.toLowerCase().trim();

      print('''
  === FETCH OFFERS DEBUG ===
  Current User ID: ${user.uid}
  User Role: $userRole
  User Email: ${user.email}
  ''');

      await _offerProvider.fetchOffers(user.uid, userRole);

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

  // Modify the filter to include all statuses except 'accepted', 'in-progress', and 'rejected'
  List<Offer> _filterOffers(String status) {
    List<Offer> filtered;
    if (status.toUpperCase() == "ALL") {
      filtered = _offerProvider.offers;
    } else if (status.toUpperCase() == "PENDING") {
      // Include offers with statuses not 'accepted', 'in-progress', or 'rejected'
      filtered = _offerProvider.offers
          .where((offer) =>
              offer.offerStatus != 'accepted' &&
              offer.offerStatus != 'in-progress' &&
              offer.offerStatus != 'rejected')
          .toList();
    } else {
      // For 'accepted', 'in-progress', and 'rejected' statuses
      filtered = _offerProvider.offers
          .where((offer) =>
              offer.offerStatus.toLowerCase() == status.toLowerCase())
          .toList();
    }

    // Debug: Log the number of filtered offers
    print(
        '[_filterOffers] Status: $status, Filtered Offers Count: ${filtered.length}');

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = userProvider.getUserRole.toLowerCase().trim();

    print('[OffersPage] Current User Role: $userRole');

    // Determine selectedIndex based on userRole
    int selectedIndex;
    if (userRole == 'dealer') {
      selectedIndex = 2; // OffersPage index for dealer
    } else if (userRole == 'transporter') {
      selectedIndex = 2; // OffersPage index for transporter
    } else {
      selectedIndex = 0; // Default to Home if role is undefined
    }

    // Debug: Log the selectedIndex
    print(
        '[OffersPage] Determined selectedIndex: $selectedIndex for User Role: $userRole');

    return GradientBackground(
      child: Consumer<OfferProvider>(
        builder: (context, offerProvider, child) {
          if (offerProvider.isFetching) {
            // Show a centralized loading indicator while fetching data
            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: CustomAppBar(),
              body: Center(
                child: Image.asset(
                  'lib/assets/Loading_Logo_CTP.gif',
                  width: 100,
                  height: 100,
                ),
              ),
            );
          } else if (offerProvider.errorMessage != null) {
            // Show an error message if fetching fails
            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: CustomAppBar(),
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
                      onPressed: () {
                        _fetchOffers();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          } else {
            // Data has been fetched successfully, build the main UI
            return DefaultTabController(
              length: 5, // Number of tabs increased to 5
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: CustomAppBar(), // Use the custom app bar here
                body: Column(
                  children: [
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'lib/assets/shaking_hands.png', // Path to the handshake image
                          width: 30,
                          height: 30,
                        ),
                        const SizedBox(
                            width: 8), // Space between image and text
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
                    TabBar(
                      isScrollable: true,
                      labelColor: const Color(0xFFFF4E00),
                      unselectedLabelColor: Colors.white,
                      indicatorColor: const Color(0xFFFF4E00),
                      tabs: [
                        Tab(
                          child: Text(
                            'All',
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.04,
                            ),
                          ),
                        ),
                        Tab(
                          child: Text(
                            'Pending',
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.04,
                            ),
                          ),
                        ),
                        Tab(
                          child: Text(
                            'Accepted',
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.04,
                            ),
                          ),
                        ),
                        Tab(
                          child: Text(
                            'In Progress',
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.04,
                            ),
                          ),
                        ),
                        // New 'REJECTED' tab
                        Tab(
                          child: Text(
                            'Rejected',
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.04,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildOffersSection('ALL'),
                          _buildOffersSection('PENDING'),
                          _buildOffersSection('ACCEPTED'),
                          _buildOffersSection('IN-PROGRESS'),
                          // New 'REJECTED' tab content
                          _buildOffersSection('REJECTED'),
                        ],
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: CustomBottomNavigation(
                  selectedIndex: selectedIndex,
                  onItemTapped: (index) {
                    final userRole =
                        userProvider.getUserRole.toLowerCase().trim();

                    // Debug: Log the navigation action
                    print(
                        '[OffersPage] User Role: $userRole, Tapped Index: $index');

                    if (userRole == 'dealer') {
                      // Navigation items for dealers:
                      // 0: Home, 1: Vehicles, 2: Offers
                      if (index == 0) {
                        print('[OffersPage] Navigating to HomePage...');
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HomePage()),
                        );
                      } else if (index == 1) {
                        print(
                            '[OffersPage] Navigating to TruckPage (Dealer)...');
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const TruckPage()),
                        );
                      } else if (index == 2) {
                        print(
                            '[OffersPage] Navigating to OffersPage (Dealer)...');
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const OffersPage()),
                        );
                      } else {
                        // Dealers do not have a Profile icon, so handle gracefully
                        print(
                            '[OffersPage] Dealer tapped on an undefined navigation item.');
                      }
                    } else if (userRole == 'transporter') {
                      // Navigation items for transporters:
                      // 0: Home, 1: Vehicles, 2: Offers, 3: Profile
                      if (index == 0) {
                        print('[OffersPage] Navigating to HomePage...');
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HomePage()),
                        );
                      } else if (index == 1) {
                        print(
                            '[OffersPage] Navigating to VehiclesListPage (Transporter)...');
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const VehiclesListPage()),
                        );
                      } else if (index == 2) {
                        print(
                            '[OffersPage] Navigating to OffersPage (Transporter)...');
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const OffersPage()),
                        );
                      } else if (index == 3) {
                        print(
                            '[OffersPage] Navigating to ProfilePage (Transporter)...');
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProfilePage()),
                        );
                      } else {
                        print(
                            '[OffersPage] Transporter tapped on an undefined navigation item.');
                      }
                    } else {
                      // Handle other roles or undefined roles if necessary
                      print(
                          '[OffersPage] Undefined role tapped on navigation index: $index');
                    }
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildOffersSection(String status) {
    final filteredOffers = _filterOffers(status);

    // Sort the filtered offers by 'createdAt' in descending order
    filteredOffers.sort((a, b) {
      final DateTime? aCreatedAt = a.createdAt;
      final DateTime? bCreatedAt = b.createdAt;

      if (aCreatedAt == null && bCreatedAt == null) return 0;
      if (bCreatedAt == null) {
        return -1; // Place offers with null 'createdAt' at the end
      }
      if (aCreatedAt == null) return 1;
      return bCreatedAt.compareTo(aCreatedAt);
    });

    if (filteredOffers.isEmpty) {
      return Center(
        child: Text(
          'No offers found in this category.',
          style: _customFont(16, FontWeight.normal, Colors.white),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredOffers.length,
      itemBuilder: (context, index) {
        return OfferCard(
          offer: filteredOffers[index],
        );
      },
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
}
