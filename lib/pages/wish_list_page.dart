import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_app_bar.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/wish_card.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:ctp/components/web_navigation_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

/// Simple data class for navigation items.
class NavigationItem {
  final String title;
  final String route;

  NavigationItem({
    required this.title,
    required this.route,
  });
}

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  _WishlistPageState createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Lists of wishlist vehicles (as Vehicle objects)
  List<Vehicle> wishlistVehicles = [];
  List<Vehicle> trucks = [];
  List<Vehicle> trailers = [];

  // Tab state: either "Trucks" or "Trailers"
  String _selectedTab = 'Trucks';

  // Add getter for current list based on selected tab
  List<Vehicle> get currentList => _selectedTab == 'Trucks' ? trucks : trailers;

  bool _isLoading = true;

  late OfferProvider _offerProvider;
  // Removed the dedicated ScrollController since the whole page scrolls now.

  // Add this getter for consistent breakpoint
  bool _isCompactNavigation(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1100;

  @override
  void initState() {
    super.initState();
    _offerProvider = Provider.of<OfferProvider>(context, listen: false);
    _fetchWishlist();
  }

  /// Fetch the wishlist vehicles for the current user.
  Future<void> _fetchWishlist() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          List<String> likedVehicleIds =
              List<String>.from(userDoc['likedVehicles'] ?? []);
          if (likedVehicleIds.isNotEmpty) {
            // Firestore's whereIn accepts a maximum of 10 items per query.
            List<List<String>> chunks = [];
            const int chunkSize = 10;
            for (var i = 0; i < likedVehicleIds.length; i += chunkSize) {
              chunks.add(likedVehicleIds
                  .skip(i)
                  .take(chunkSize)
                  .toList(growable: false));
            }

            List<Vehicle> fetchedVehicles = [];
            for (var chunk in chunks) {
              QuerySnapshot snapshot = await FirebaseFirestore.instance
                  .collection('vehicles')
                  .where(FieldPath.documentId, whereIn: chunk)
                  .get();
              for (var doc in snapshot.docs) {
                Vehicle vehicle = Vehicle.fromFirestore(
                    doc.id, doc.data() as Map<String, dynamic>);
                fetchedVehicles.add(vehicle);
                // Optionally add to the VehicleProvider.
                Provider.of<VehicleProvider>(context, listen: false)
                    .addVehicle(vehicle);
              }
            }

            setState(() {
              wishlistVehicles = fetchedVehicles;
              // Separate vehicles into Trucks and Trailers based on vehicleType.
              trucks = wishlistVehicles.where((v) {
                String type = v.vehicleType.toLowerCase();
                return type == 'truck' || type == 'pickup' || type == 'lorry';
              }).toList();
              trailers = wishlistVehicles.where((v) {
                String type = v.vehicleType.toLowerCase();
                return type == 'trailer' || type == 'semi-trailer';
              }).toList();
              _isLoading = false;
            });
          } else {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print("Error fetching wishlist: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Computes the number of columns for the grid view based on screen width.
  int _calculateCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= 1200) {
      return 4;
    } else if (width >= 900) {
      return 3;
    } else if (width >= 600) {
      return 2;
    } else {
      return 1;
    }
  }

  /// Builds the WishCard for a given vehicle.
  Widget _buildWishCard(Vehicle vehicle, Size screenSize) {
    bool hasOffer =
        _offerProvider.offers.any((offer) => offer.vehicleId == vehicle.id);
    return WishCard(
      vehicleMakeModel: "${vehicle.makeModel} ${vehicle.year}",
      vehicleImageUrl:
          (vehicle.mainImageUrl != null && vehicle.mainImageUrl!.isNotEmpty)
              ? vehicle.mainImageUrl!
              : 'lib/assets/default_vehicle_image.png',
      size: screenSize,
      customFont: (double fontSize, FontWeight fontWeight, Color color) {
        return TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          fontFamily: 'Montserrat',
        );
      },
      hasOffer: hasOffer,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleDetailsPage(vehicle: vehicle),
          ),
        );
      },
      onDelete: () async {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'likedVehicles': FieldValue.arrayRemove([vehicle.id])
          });
          setState(() {
            wishlistVehicles.remove(vehicle);
            trucks.remove(vehicle);
            trailers.remove(vehicle);
          });
        }
      },
      vehicleId: vehicle.id,
      vehicle: vehicle,
    );
  }

  // Determine if the screen is considered large.
  bool get _isLargeScreen => MediaQuery.of(context).size.width > 900;

  // Determines if compact navigation should be used.

  /// The build method now uses a CustomScrollView so that the header and the tab bar
  /// scroll together. The tab bar is implemented as a sticky (pinned) sliver.
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool showBottomNav = !_isLargeScreen && !kIsWeb;
    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.getUserRole;

    List<NavigationItem> navigationItems = userRole == 'dealer'
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

    return GradientBackground(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: (_isLargeScreen || kIsWeb)
            ? PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: WebNavigationBar(
                  isCompactNavigation: _isCompactNavigation(context),
                  currentRoute: '/wishlist',
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
                                child: const Icon(Icons.local_shipping, color: Colors.white),
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          children: navigationItems.map((item) {
                            bool isActive = '/wishlist' == item.route;
                            return ListTile(
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  color: isActive ? const Color(0xFFFF4E00) : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              selected: isActive,
                              selectedTileColor: Colors.black12,
                              onTap: () {
                                Navigator.pop(context);
                                if (!isActive) {
                                  Navigator.pushNamed(context, item.route);
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            // Header section with the Wishlist title and image.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(height: screenSize.height * 0.05),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'lib/assets/HeartVector.png',
                          width: 30,
                          height: 30,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'WISHLIST',
                          style: TextStyle(
                            color: Color(0xFFFF4E00),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    SizedBox(height: screenSize.height * 0.03),
                  ],
                ),
              ),
            ),
            // Sticky tab bar – using SliverPersistentHeader.
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                minHeight: 60,
                maxHeight: 60,
                child: Container(
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTabButton('Trucks (${trucks.length})', 'Trucks'),
                      SizedBox(width: screenSize.width * 0.02),
                      _buildTabButton(
                          'Trailers (${trailers.length})', 'Trailers'),
                    ],
                  ),
                ),
              ),
            ),
            // Display either a loading indicator, a "No vehicles found" message, or the grid.
            if (_isLoading)
              SliverFillRemaining(
                child: Center(
                  child: Image.asset(
                    'lib/assets/Loading_Logo_CTP.gif',
                    width: 100,
                    height: 100,
                  ),
                ),
              )
            else if (currentList.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    "No vehicles found.",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _calculateCrossAxisCount(context),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8, // Adjust this value as needed.
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      Vehicle vehicle = currentList[index];
                      return _buildWishCard(vehicle, screenSize);
                    },
                    childCount: currentList.length,
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: showBottomNav
            ? CustomBottomNavigation(
                selectedIndex: 3, // Adjust this index as needed.
                onItemTapped: (index) {
                  // Handle bottom navigation taps.
                },
              )
            : null,
      ),
    );
  }

  /// Helper to build a tab button.
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
}

/// A custom SliverPersistentHeader delegate for the sticky tab bar.
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
  double get maxExtent => max(maxHeight, minHeight);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
