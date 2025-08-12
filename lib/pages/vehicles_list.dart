// lib/pages/vehicles_list_page.dart

import 'package:ctp/components/constants.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/listing_card.dart';
import 'package:ctp/pages/home_page.dart';
import 'package:ctp/pages/offersPage.dart';
import 'package:ctp/pages/profile_page.dart';
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
import 'package:ctp/utils/navigation.dart';
import 'package:ctp/components/custom_button.dart';
import 'dart:ui';

import 'package:auto_route/auto_route.dart';

@RoutePage()
class VehiclesListPage extends StatefulWidget {
  const VehiclesListPage({super.key});

  @override
  _VehiclesListPageState createState() => _VehiclesListPageState();
}

class _VehiclesListPageState extends State<VehiclesListPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  bool isLoading = true;

  // Add this getter for consistent breakpoint
  bool _isCompactNavigation(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1100;

  // Add this getter for large screen detection
  bool get _isLargeScreen => MediaQuery.of(context).size.width > 900;

  @override
  void initState() {
    super.initState();
    // Redirect admin users before the page loads fully
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userRole =
          Provider.of<UserProvider>(context, listen: false).getUserRole;
      if (userRole == 'admin') {
        Navigator.pushReplacementNamed(context, '/adminVehicles');
      }
    });
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUserId = userProvider.userId;

      if (currentUserId != null) {
        // Fetch vehicles for the logged-in user
        await vehicleProvider.fetchVehicles(
          userProvider,
          userId: currentUserId,
          filterLikedDisliked: false,
        );
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

    // Get all vehicles uploaded by the current user
    final userVehicles = vehicleProvider.getVehiclesByUserId(currentUserId);

    // Separate them by status
    final drafts =
        userVehicles.where((v) => v.vehicleStatus == 'Draft').toList();
    final pending =
        userVehicles.where((v) => v.vehicleStatus == 'pending').toList();
    final live = userVehicles.where((v) => v.vehicleStatus == 'Live').toList();

    if (_scrollController.hasClients) {
      debugPrint(
        '🔍 NestedScrollView scroll offset: ${_scrollController.offset}',
      );
    }
    return GradientBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: (_isLargeScreen || kIsWeb)
            ? PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: WebNavigationBar(
                  isCompactNavigation: _isCompactNavigation(context),
                  currentRoute: '/transporterList',
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
                      Expanded(
                        child: ListView(
                          children: [
                            ListTile(
                              title: Text('Home',
                                  style: TextStyle(color: Colors.white)),
                              onTap: () =>
                                  Navigator.pushNamed(context, '/home'),
                            ),
                            ListTile(
                              title: Text('Your Trucks',
                                  style: TextStyle(
                                      color: const Color(0xFFFF4E00))),
                              selected: true,
                              onTap: () {},
                            ),
                            ListTile(
                              title: Text('Your Offers',
                                  style: TextStyle(color: Colors.white)),
                              onTap: () =>
                                  Navigator.pushNamed(context, '/offers'),
                            ),
                            ListTile(
                              title: Text('Profile',
                                  style: TextStyle(color: Colors.white)),
                              onTap: () =>
                                  Navigator.pushNamed(context, '/profile'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (!isLoading && userVehicles.isEmpty)
                    Center(
                      child: Text(
                        'No Vehicles Found',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                    ),
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
                        'MY VEHICLES',
                        style: TextStyle(
                          color: Color(0xFFFF4E00),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 350,
                    child: Text(
                      'Here are your uploaded vehicles.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFFFF4E00),
                  unselectedLabelColor: Colors.white,
                  indicatorColor: const Color(0xFFFF4E00),
                  tabs: [
                    Tab(text: 'Drafts (${drafts.length})'),
                    Tab(text: 'Pending (${pending.length})'),
                    Tab(text: 'Live (${live.length})'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              drafts.isEmpty
                  ? Center(
                      child: Text(
                        'No Draft vehicles.',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                    )
                  : _buildVehiclesList(drafts),
              pending.isEmpty
                  ? Center(
                      child: Text(
                        'No Pending vehicles.',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                    )
                  : _buildVehiclesList(pending),
              live.isEmpty
                  ? Center(
                      child: Text(
                        'No Live vehicles.',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                    )
                  : _buildVehiclesList(live),
            ],
          ),
        ),
        floatingActionButton: null,
        bottomNavigationBar: (kIsWeb ||
                userProvider.getUserRole == 'admin' ||
                userProvider.getUserRole == 'sales representative')
            ? null
            : SafeArea(
                top: false,
                bottom: true,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewPadding.bottom,
                  ),
                  child: CustomBottomNavigation(
                    selectedIndex: _selectedIndex,
                    onItemTapped: (index) async {
                      _onItemTapped(index);
                      final userRole =
                          userProvider.getUserRole.toLowerCase().trim();

                      // Example for dealers
                      if (userRole == 'dealer') {
                        // 0: Home, 1: Vehicles, 2: Offers
                        if (index == 0) {
                          await MyNavigator.pushReplacement(
                              context, const HomePage());
                        } else if (index == 1) {
                          await MyNavigator.pushReplacement(
                              context, const VehiclesListPage());
                        } else if (index == 2) {
                          await MyNavigator.pushReplacement(
                              context, const OffersPage());
                        }
                      }
                      // Example for transporters
                      else if (userRole == 'transporter') {
                        // 0: Home, 1: Vehicles, 2: Offers, 3: Profile
                        if (index == 0) {
                          await MyNavigator.pushReplacement(
                              context, const HomePage());
                        } else if (index == 1) {
                          await MyNavigator.pushReplacement(
                            context,
                            const VehiclesListPage(),
                          );
                        } else if (index == 2) {
                          await MyNavigator.pushReplacement(
                              context, const OffersPage());
                        } else if (index == 3) {
                          await MyNavigator.pushReplacement(
                              context, ProfilePage());
                        }
                      } else {
                        // Handle other roles if needed
                      }
                    },
                  ),
                ),
              ),
      ),
    );
  }

  /// Build a grid of vehicles using ListingCard
  Widget _buildVehiclesList(List vehicles) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate number of columns based on width
        int crossAxisCount = 4; // Default to 4 columns
        double screenWidth = constraints.maxWidth;

        if (screenWidth < 600) {
          crossAxisCount = 1; // Mobile: 1 column
        } else if (screenWidth < 900) {
          crossAxisCount = 2; // Tablet: 2 columns
        } else if (screenWidth < 1200) {
          crossAxisCount = 3; // Small desktop: 3 columns
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          primary: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.8, // Adjust this value to control card height
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            final vehicle = vehicles[index];
            return ListingCard(
              onTap: () async {
                await MyNavigator.push(
                  context,
                  VehicleDetailsPage(vehicle: vehicle),
                );
              },
              vehicle: vehicle,
            );
          },
        );
      },
    );
  }

  void _showVehicleTypeSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Select Vehicle Type',
          style: GoogleFonts.montserrat(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomButton(
              text: 'Truck',
              borderColor: const Color(0xFFFF4E00),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/truckUploadForm');
              },
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Trailer',
              borderColor: AppColors.blue,
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/trailerUploadForm');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverTabBarDelegate(this._tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    debugPrint(
        '⏱ SliverTabBarDelegate.build called - shrinkOffset: $shrinkOffset, overlapsContent: $overlapsContent');
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: shrinkOffset > 0 ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final bgColor = Color.lerp(Colors.transparent, AppColors.blue, value)!;
        final elev = lerpDouble(0, 4, value)!;
        return Material(
          color: bgColor,
          elevation: elev,
          child: child,
        );
      },
      child: _tabBar,
    );
  }

  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return _tabBar != oldDelegate._tabBar;
  }
}
