// lib/adminScreens/admin_home_page.dart

// ignore_for_file: unused_local_variable, unused_field

import 'package:ctp/adminScreens/user_tabs.dart';
import 'package:ctp/adminScreens/vehicle_tab.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:flutter/material.dart';
import 'package:ctp/adminScreens/complaints_tab.dart';
import 'package:ctp/adminScreens/offers_tab.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import the ProfilePage for navigation
import 'package:ctp/providers/complaints_provider.dart'; // Note the plural form
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:ctp/components/admin_web_navigation_bar.dart';

import 'package:auto_route/auto_route.dart';

@RoutePage()
class AdminHomePage extends StatefulWidget {
  final int initialTab;
  const AdminHomePage({super.key, this.initialTab = 0});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // new key
  late TabController _tabController;
  int userCount = 0;
  int offerCount = 0;
  int complaintCount = 0;
  int vehicleCount = 0;

  final Key _offersTabKey = UniqueKey(); // Add this line

  // Replace the existing myTabs with a method
  List<Tab> getTabs() {
    return <Tab>[
      Tab(text: 'Users ($userCount)'),
      Tab(text: 'Offers ($offerCount)'),
      Tab(text: 'Complaints ($complaintCount)'),
      Tab(text: 'Vehicles ($vehicleCount)'),
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 4, vsync: this, initialIndex: widget.initialTab);

    // Initialize all providers
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final offerProvider = Provider.of<OfferProvider>(context, listen: false);
      final complaintProvider =
          Provider.of<ComplaintsProvider>(context, listen: false);
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);

      // Initialize providers
      offerProvider.initialize(
          userProvider.userId ?? 'unknown', userProvider.userRole);
      await userProvider.fetchDealers(); // Fetch users
      await offerProvider.fetchOffers(userProvider.userId ?? 'unknown',
          userProvider.userRole); // Fetch offers
      await complaintProvider.fetchAllComplaints(); // Fetch complaints
      await vehicleProvider.fetchAllVehicles(); // Fetch vehicles

      _updateCounts(); // Update counts after initial fetch
    });

    // Listen to tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _refreshCurrentTab(_tabController.index);
      }
    });
  }

  // Add method to refresh current tab data
  void _refreshCurrentTab(int index) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);
    final complaintProvider =
        Provider.of<ComplaintsProvider>(context, listen: false);
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);

    switch (index) {
      case 0: // Users tab
        await userProvider.fetchDealers();
        break;
      case 1: // Offers tab
        await offerProvider.refreshOffers();
        break;
      case 2: // Complaints tab
        await complaintProvider.refreshComplaints();
        break;
      case 3: // Vehicles tab
        await vehicleProvider.fetchAllVehicles();
        break;
    }
    _updateCounts();
  }

  // Update the _updateCounts method to run asynchronously
  Future<void> _updateCounts() async {
    if (!mounted) return;

    setState(() {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final offerProvider = Provider.of<OfferProvider>(context, listen: false);
      final complaintProvider =
          Provider.of<ComplaintsProvider>(context, listen: false);
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);

      userCount = userProvider.getUserCount();
      offerCount = offerProvider.getOfferCount();
      complaintCount = complaintProvider.getComplaintCount();
      vehicleCount = vehicleProvider.getVehicleCount();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // NEW: Check if account exists for non-authenticated users
    if (FirebaseAuth.instance.currentUser == null &&
        userProvider.getAccountStatus == 'not_found') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/error');
      });
      return const SizedBox.shrink();
    }

    var blue = const Color(0xFF2F7FFF);
    final String currentUserRole = userProvider.getUserRole;
    final bool isAdmin = currentUserRole == 'admin';
    final bool isSalesRep = currentUserRole == 'sales representative';

    // Ensure only admins and sales representatives can access this page
    if (userProvider.userRole != 'admin' &&
        userProvider.userRole != 'sales representative') {
      // Redirect to an error page or unauthorized access page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/error');
      });
      return const SizedBox.shrink(); // Return empty widget while redirecting
    }

    return GradientBackground(
      child: Scaffold(
        key: _scaffoldKey, // assign key here
        backgroundColor: Colors.transparent,
        drawer: Drawer(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Color(0xFF2F7FFD)],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black, Color(0xFF2F7FFD)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Admin Menu',
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Users'),
                  textColor: Colors.white,
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/adminUsers');
                  },
                ),
                ListTile(
                  title: const Text('Offers'),
                  textColor: Colors.white,
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/adminOffers');
                  },
                ),
                ListTile(
                  title: const Text('Complaints'),
                  textColor: Colors.white,
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/adminComplaints');
                  },
                ),
                ListTile(
                  title: const Text('Vehicles'),
                  textColor: Colors.white,
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/adminVehicles');
                  },
                ),
                // ListTile(
                //   title: const Text('Fleets'),
                //   textColor: Colors.white,
                //   onTap: () {
                //     Navigator.pushReplacementNamed(context, '/adminFleets');
                //   },
                // ),
                if (userProvider.getUserEmail == 'bradley@admin.co.za')
                  ListTile(
                    title: const Text('Notification Test'),
                    textColor: Colors.white,
                    onTap: () {
                      Navigator.pushReplacementNamed(
                          context, '/adminNotificationTest');
                    },
                  ),
              ],
            ),
          ),
        ),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: AdminWebNavigationBar(
            scaffoldKey: _scaffoldKey, // pass key here
            showBackArrow: false,
            isCompactNavigation: false,
            currentRoute: _getCurrentTabTitle(),
            onMenuPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            onTabSelected: (int index) {
              _tabController.animateTo(index);
              setState(() {}); // Refresh active state if needed
            },
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          physics:
              const NeverScrollableScrollPhysics(), // added to disable swipe navigation
          children: [
            UsersTab(),
            OffersTab(
              userId: userProvider.userRole == 'admin'
                  ? 'admin'
                  : userProvider.userId ?? 'unknown',
              userRole: userProvider.userRole,
            ),
            ComplaintsTab(),
            VehiclesTab(),
          ],
        ),
      ),
    );
  }

  String _getCurrentTabTitle() {
    switch (_tabController.index) {
      case 0:
        return 'Users';
      case 1:
        return 'Offers';
      case 2:
        return 'Complaints';
      case 3:
        return 'Vehicles';
      default:
        return '';
    }
  }
}
