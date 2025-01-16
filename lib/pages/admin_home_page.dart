// lib/adminScreens/admin_home_page.dart

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
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth for logout

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

  // Common method to show confirmation dialogs (e.g., Logout confirmation)
  Future<bool?> _showConfirmationDialog(
      BuildContext context, String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title,
              style: GoogleFonts.montserrat(
                color: Colors.white,
              )),
          content: Text(content,
              style: GoogleFonts.montserrat(
                color: Colors.white70,
              )),
          backgroundColor: Colors.black87,
          actions: [
            TextButton(
              child: Text('Cancel',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                  )),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Logout',
                  style: GoogleFonts.montserrat(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  // Method to handle logout
  Future<void> _logout() async {
    bool? confirmLogout = await _showConfirmationDialog(
        context, 'Confirm Logout', 'Are you sure you want to logout?');

    if (confirmLogout == true) {
      try {
        await FirebaseAuth.instance.signOut();

        // Optionally, clear any stored user data here

        // Navigate to the login screen and remove all previous routes
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } catch (e) {
        print('Error during logout: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var blue = const Color(0xFF2F7FFF);

    // Access the UserProvider to get user details
    final userProvider = Provider.of<UserProvider>(context);

    // Ensure only admins can access this page
    if (userProvider.userRole != 'admin' &&
        userProvider.userRole != 'sales representative') {
      // Redirect to an error page or unauthorized access page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/error');
      });
      return const SizedBox.shrink(); // Return empty widget while redirecting
    }

    return GradientBackground(
      // begin: const FractionalOffset(0.5, 0),
      // end: const FractionalOffset(0.5, 1),
      // stops: const [0.0, 1.0],
      child: Scaffold(
        backgroundColor:
            Colors.transparent, // Make Scaffold background transparent
        appBar: AppBar(
          backgroundColor: blue,
          elevation: 0,
          automaticallyImplyLeading:
              false, // Remove back arrow (since this is home page)
          title: Text(
            'Admin Dashboard',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.logout,
                color: Colors.white,
              ),
              tooltip: 'Logout',
              onPressed: _logout,
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
            labelPadding:
                const EdgeInsets.symmetric(horizontal: 16.0), // Add padding
            isScrollable: false, // Force tabs to fill width
          ),
          // Optional: Adjust the AppBar height if needed
          // toolbarHeight: 60.0,
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
