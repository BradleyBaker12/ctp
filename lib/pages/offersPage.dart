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
import 'package:ctp/utils/navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  ///
  /// Filtering logic (4 tabs):
  /// 1. ALL: Show everything.
  /// 2. IN_PROGRESS: Show everything EXCEPT "rejected", "completed", "successful".
  /// 3. SUCCESSFUL: Show only "completed" or "successful".
  /// 4. REJECTED: Show only "rejected".
  ///
  List<Offer> _filterOffers(String status) {
    final offers = _offerProvider.offers;

    switch (status.toUpperCase()) {
      case 'ALL':
        return offers; // Show everything
      case 'IN_PROGRESS':
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
        // If unknown status passed, return empty or handle otherwise
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = userProvider.getUserRole.toLowerCase().trim();

    print('[OffersPage] Current User Role: $userRole');

    // Example navigation index handling
    int selectedIndex;
    if (userRole == 'dealer') {
      selectedIndex = 2;
    } else if (userRole == 'transporter') {
      selectedIndex = 2;
    } else {
      selectedIndex = 0;
    }

    return GradientBackground(
      child: Consumer<OfferProvider>(
        builder: (context, offerProvider, child) {
          if (offerProvider.isFetching) {
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
                      onPressed: _fetchOffers,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          } else {
            // Main UI: 4 tabs
            return DefaultTabController(
              length: 4,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: CustomAppBar(),
                body: Column(
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
                    TabBar(
                      isScrollable: true,
                      labelColor: const Color(0xFFFF4E00),
                      unselectedLabelColor: Colors.white,
                      indicatorColor: const Color(0xFFFF4E00),
                      tabs: const [
                        Tab(text: 'All'),
                        Tab(text: 'In Progress'),
                        Tab(text: 'Successful'),
                        Tab(text: 'Rejected'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildOffersSection('ALL'),
                          _buildOffersSection('IN_PROGRESS'),
                          _buildOffersSection('SUCCESSFUL'),
                          _buildOffersSection('REJECTED'),
                        ],
                      ),
                    ),
                  ],
                ),
                bottomNavigationBar: CustomBottomNavigation(
                  selectedIndex: selectedIndex,
                  onItemTapped: (index) async {
                    if (userRole == 'dealer') {
                      // Dealer nav: 0 -> Home, 1 -> Vehicles, 2 -> Offers
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
                      // Transporter nav: 0 -> Home, 1 -> Vehicles, 2 -> Offers, 3 -> Profile
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
                            context, const ProfilePage());
                      }
                    } else {
                      // Handle other roles or additional logic here
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

    // Sort by 'createdAt' descending
    filteredOffers.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;
      if (aDate == null && bDate == null) return 0;
      if (bDate == null) return -1;
      if (aDate == null) return 1;
      return bDate.compareTo(aDate);
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
          onPop: () {
            _fetchOffers();
          },
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
