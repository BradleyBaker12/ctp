// lib/pages/sold_vehicles_list.dart

import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/listing_card.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:ctp/components/custom_app_bar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ctp/components/web_navigation_bar.dart';

class SoldVehiclesListPage extends StatefulWidget {
  const SoldVehiclesListPage({super.key});

  @override
  _SoldVehiclesListPageState createState() => _SoldVehiclesListPageState();
}

class _SoldVehiclesListPageState extends State<SoldVehiclesListPage> {
  final int _selectedIndex = 1;
  final ScrollController _scrollController = ScrollController();
  bool isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isCompactNavigation(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1100;

  bool get _isLargeScreen => MediaQuery.of(context).size.width > 900;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUserId = userProvider.userId;

      if (currentUserId != null) {
        await vehicleProvider.fetchVehicles(userProvider,
            userId: currentUserId, filterLikedDisliked: false);
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicleProvider = Provider.of<VehicleProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final currentUserId = userProvider.userId;

    if (currentUserId == null) {
      return Scaffold(
        appBar: CustomAppBar(),
        body: const Center(
          child: Text('User is not signed in.'),
        ),
      );
    }

    final userVehicles = vehicleProvider.getVehiclesByUserId(currentUserId);
    final soldVehicles = userVehicles
        .where((vehicle) => vehicle.vehicleStatus == 'Sold')
        .toList();

    return GradientBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: (_isLargeScreen || kIsWeb)
            ? PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: WebNavigationBar(
                  isCompactNavigation: _isCompactNavigation(context),
                  currentRoute: '/soldVehicles',
                  onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              )
            : CustomAppBar(),
        drawer: _isCompactNavigation(context)
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
                            bottom: BorderSide(color: Colors.white24, width: 1),
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
                      ListTile(
                        title:
                            Text('Home', style: TextStyle(color: Colors.white)),
                        onTap: () => Navigator.pushNamed(context, '/home'),
                      ),
                      ListTile(
                        title: Text('Your Trucks',
                            style: TextStyle(color: Colors.white)),
                        onTap: () =>
                            Navigator.pushNamed(context, '/transporterList'),
                      ),
                      ListTile(
                        title: Text('Sold Vehicles',
                            style: TextStyle(color: const Color(0xFFFF4E00))),
                        selected: true,
                        onTap: () {},
                      ),
                      ListTile(
                        title: Text('Profile',
                            style: TextStyle(color: Colors.white)),
                        onTap: () => Navigator.pushNamed(context, '/profile'),
                      ),
                    ],
                  ),
                ),
              )
            : null,
        body: Column(
          children: [
            if (isLoading) const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 40),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_shipping,
                  color: Color(0xFFFF4E00),
                  size: 30,
                ),
                SizedBox(width: 8),
                Text(
                  'SOLD VEHICLES',
                  style: TextStyle(
                    color: Color(0xFFFF4E00),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: soldVehicles.isEmpty
                  ? Center(
                      child: Text(
                        'No Sold Vehicles Found',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: soldVehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = soldVehicles[index];

                        return ListingCard(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VehicleDetailsPage(
                                  vehicle: vehicle,
                                ),
                              ),
                            );
                          }, vehicle: vehicle,
                        );
                      },
                    ),
            ),
          ],
        ),
        bottomNavigationBar: (kIsWeb || MediaQuery.of(context).size.width > 600)
            ? null
            : CustomBottomNavigation(
                selectedIndex: _selectedIndex,
                onItemTapped: (index) {
                  // same nav logic
                },
              ),
      ),
    );
  }
}
