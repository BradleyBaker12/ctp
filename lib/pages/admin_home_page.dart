// lib/adminScreens/admin_home_page.dart

// ignore_for_file: unused_local_variable, unused_field

import 'package:ctp/adminScreens/user_tabs.dart';
import 'package:ctp/adminScreens/vehicle_tab.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/utils/navigation.dart';
import 'package:flutter/material.dart';
import 'package:ctp/adminScreens/complaints_tab.dart';
import 'package:ctp/adminScreens/offers_tab.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
// Remove FirebaseAuth import if you don't need logout functionality anymore
// import 'package:firebase_auth/firebase_auth.dart';

// Import the ProfilePage for navigation
import 'package:ctp/pages/profile_page.dart';
import 'package:ctp/providers/complaints_provider.dart'; // Note the plural form
import 'package:ctp/providers/vehicles_provider.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with SingleTickerProviderStateMixin {
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
    _tabController = TabController(length: 4, vsync: this);

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
    var blue = const Color(0xFF2F7FFF);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
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
        backgroundColor: Colors.transparent, // Transparent scaffold background
        appBar: AppBar(
          backgroundColor: blue,
          elevation: 0,
          automaticallyImplyLeading:
              false, // Remove back arrow (since this is home)
          title: Text(
            isAdmin ? 'Admin Dashboard' : 'Sales Rep Dashboard',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 25.0),
              child: GestureDetector(
                onTap: () async {
                  await MyNavigator.push(
                    context,
                    ProfilePage(),
                  );
                },
                child: Consumer<UserProvider>(
                  builder: (context, userProvider, _) {
                    final profileImageUrl = userProvider.getProfileImageUrl;
                    return CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl)
                          : const AssetImage(
                                  'lib/assets/default-profile-photo.jpg')
                              as ImageProvider,
                      // Only display the fallback icon if the user is not a sales rep.
                      child: () {
                        if (currentUserRole == 'sales representative') {
                          return null;
                        }
                        return profileImageUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 26,
                                color: Colors.grey,
                              )
                            : null;
                      }(),
                    );
                  },
                ),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: getTabs(),
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.montserrat(
              fontWeight: FontWeight.w400,
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            isScrollable: true,
            tabAlignment:
                TabAlignment.center, // Add this line to center the tabs
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
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
}
