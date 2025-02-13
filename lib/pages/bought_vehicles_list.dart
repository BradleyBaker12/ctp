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
import 'package:ctp/utils/navigation.dart';

class BoughtVehiclesListPage extends StatefulWidget {
  const BoughtVehiclesListPage({super.key});

  @override
  _BoughtVehiclesListPageState createState() => _BoughtVehiclesListPageState();
}

class _BoughtVehiclesListPageState extends State<BoughtVehiclesListPage> {
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
      final vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUserId = userProvider.userId;

      if (currentUserId != null) {
        await vehicleProvider.fetchBoughtVehicles(userProvider, userId: currentUserId);
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

    final boughtVehicles = vehicleProvider.getBoughtVehicles();

    return GradientBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: (_isLargeScreen || kIsWeb)
            ? PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: WebNavigationBar(
                  isCompactNavigation: _isCompactNavigation(context),
                  currentRoute: '/boughtVehicles',
                  onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              )
            : CustomAppBar(),
        drawer: _isCompactNavigation(context)
            ? Drawer(/* Same drawer implementation as sold vehicles */)
            : null,
        body: Column(
          children: [
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
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
                    'BOUGHT VEHICLES',
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
                child: boughtVehicles.isEmpty
                    ? Center(
                        child: Text(
                          'No Bought Vehicles Found',
                          style: GoogleFonts.montserrat(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: boughtVehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = boughtVehicles[index];

                          return ListingCard(
                            onTap: () async {
                              await MyNavigator.push(
                                context,
                                VehicleDetailsPage(
                                  vehicle: vehicle,
                                ),
                              );
                            },
                            vehicle: vehicle,
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
        bottomNavigationBar: (kIsWeb || MediaQuery.of(context).size.width > 600)
            ? null
            : CustomBottomNavigation(
                selectedIndex: _selectedIndex,
                onItemTapped: (index) {
                  // Navigation logic
                },
              ),
      ),
    );
  }
}
