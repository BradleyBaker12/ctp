import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/adminScreens/create_fleet_page.dart';
import 'package:provider/provider.dart';
import 'fleets_management_page.dart';
import 'package:ctp/components/admin_web_navigation_bar.dart';

@RoutePage()
class AdminFleetsPage extends StatefulWidget {
  const AdminFleetsPage({super.key});
  @override
  State<AdminFleetsPage> createState() => _AdminFleetsPageState();
}

class _AdminFleetsPageState extends State<AdminFleetsPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  final List<Tab> _tabs = [
    const Tab(text: 'Management'),
    // If you need future tabs (e.g., Reporting), add here.
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var blue = const Color(0xFF2F7FFF);
    return Scaffold(
      key: _scaffoldKey,
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
              ListTile(
                title: const Text('Fleets'),
                textColor: Colors.white,
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/adminFleets');
                },
              ),
              if (Provider.of<UserProvider>(context, listen: false)
                      .getUserEmail ==
                  'bradley@admin.co.za')
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
        preferredSize: const Size.fromHeight(60.0),
        child: AdminWebNavigationBar(
          scaffoldKey: _scaffoldKey,
          isCompactNavigation: MediaQuery.of(context).size.width < 900,
          currentRoute: 'Fleets',
          onMenuPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          onTabSelected: (index) {
            // 0: Users, 1: Offers, 2: Complaints, 3: Vehicles
            if (index == 0) {
              Navigator.pushReplacementNamed(context, '/adminUsers');
            } else if (index == 1) {
              Navigator.pushReplacementNamed(context, '/adminOffers');
            } else if (index == 2) {
              Navigator.pushReplacementNamed(context, '/adminComplaints');
            } else if (index == 3) {
              Navigator.pushReplacementNamed(context, '/adminVehicles');
            }
          },
        ),
      ),
      body: GradientBackground(
        child: Column(
          children: [
            // Keep the TabBar in the AppBar, so we directly render the TabBarView below
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  FleetsManagementPage(),
                  // Future tabs...
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) {
          // Only show for admins; assume UserProvider exists
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          if (userProvider.userRole != 'admin') {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateFleetPage()),
              );
            },
            label: Text(
              'Create Fleet',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            backgroundColor: const Color(0xFF0E4CAF),
          );
        },
      ),
    );
  }
}
