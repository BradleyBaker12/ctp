// lib/adminScreens/admin_home_page.dart

// ignore_for_file: unused_local_variable, unused_field

import 'package:ctp/adminScreens/complaints_tab.dart';
import 'package:ctp/adminScreens/offers_tab.dart';
import 'package:ctp/adminScreens/user_tabs.dart';
import 'package:ctp/adminScreens/vehicle_tab.dart';
import 'package:ctp/components/gradient_background.dart';
// Remove FirebaseAuth import if you don't need logout functionality anymore
// import 'package:firebase_auth/firebase_auth.dart';

// Import the ProfilePage for navigation
import 'package:ctp/pages/profile_page.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/utils/navigation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Key _offersTabKey = UniqueKey(); // Add this line

  final List<Tab> myTabs = <Tab>[
    const Tab(text: 'Users'),
    const Tab(text: 'Offers'),
    const Tab(text: 'Complaints'),
    const Tab(text: 'Vehicles'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: myTabs.length, vsync: this);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      offerProvider.initialize(
          userProvider.userId ?? 'unknown', userProvider.userRole);
    });

    _tabController.addListener(() {
      if (_tabController.index == 1) {
        Provider.of<OfferProvider>(context, listen: false).refreshOffers();
      }
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
                    const ProfilePage(),
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
            tabs: myTabs,
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
            labelPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            isScrollable: false, // Force tabs to fill width
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
