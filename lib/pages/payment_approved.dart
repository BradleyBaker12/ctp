// If you're not using this model, you can remove this import
import 'package:ctp/pages/collect_vehcile.dart';
import 'package:ctp/pages/report_issue.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/components/web_navigation_bar.dart' as ctp_nav;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ctp/utils/navigation.dart';
import 'package:ctp/pages/collectionPages/collection_details_page.dart'
    show CollectionDetailsPage;

import 'package:auto_route/auto_route.dart';

@RoutePage()
class PaymentApprovedPage extends StatefulWidget {
  final String offerId;

  const PaymentApprovedPage({super.key, required this.offerId});

  @override
  _PaymentApprovedPageState createState() => _PaymentApprovedPageState();
}

class _PaymentApprovedPageState extends State<PaymentApprovedPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  Future<Map<String, dynamic>> _fetchOfferData(String offerId) async {
    final offerSnapshot = await FirebaseFirestore.instance
        .collection('offers')
        .doc(offerId)
        .get();
    return offerSnapshot.data() ?? {};
  }

  Future<Map<String, dynamic>> _fetchVehicleData(String vehicleId) async {
    final vehicleSnapshot = await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(vehicleId)
        .get();
    return vehicleSnapshot.data() ?? {};
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  bool _isCompactNavigation(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1100;

  bool get _isLargeScreen => MediaQuery.of(context).size.width > 900;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.getUserRole;
    final bool showBottomNav = !_isLargeScreen && !kIsWeb;

    List<ctp_nav.NavigationItem> navigationItems = userRole == 'dealer'
        ? [
            ctp_nav.NavigationItem(title: 'Home', route: '/home'),
            ctp_nav.NavigationItem(title: 'Search Trucks', route: '/truckPage'),
            ctp_nav.NavigationItem(title: 'Wishlist', route: '/wishlist'),
            ctp_nav.NavigationItem(title: 'Pending Offers', route: '/offers'),
          ]
        : [
            ctp_nav.NavigationItem(title: 'Home', route: '/home'),
            ctp_nav.NavigationItem(
                title: 'Your Trucks', route: '/transporterList'),
            ctp_nav.NavigationItem(title: 'Your Offers', route: '/offers'),
            ctp_nav.NavigationItem(title: 'In-Progress', route: '/in-progress'),
          ];

    // Do not mutate status on view; status should have been updated by admin verification flow.

    return Scaffold(
      key: _scaffoldKey,
      appBar: kIsWeb
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: ctp_nav.WebNavigationBar(
                isCompactNavigation: _isCompactNavigation(context),
                currentRoute: '/offers',
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            )
          : null,
      drawer: _isCompactNavigation(context) && kIsWeb
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
                        children:
                            navigationItems.map((ctp_nav.NavigationItem item) {
                          bool isActive = '/offers' == item.route;
                          return ListTile(
                            title: Text(
                              item.title,
                              style: TextStyle(
                                color: isActive
                                    ? const Color(0xFFFF4E00)
                                    : Colors.white,
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
      body: GradientBackground(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchOfferData(widget.offerId),
          builder: (context, offerSnapshot) {
            if (offerSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (offerSnapshot.hasError) {
              return const Center(child: Text('Error loading offer data'));
            }

            final offerData = offerSnapshot.data!;
            final vehicleId = offerData['vehicleId'] as String;

            return FutureBuilder<Map<String, dynamic>>(
              future: _fetchVehicleData(vehicleId),
              builder: (context, vehicleSnapshot) {
                if (vehicleSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (vehicleSnapshot.hasError) {
                  return const Center(
                      child: Text('Error loading vehicle data'));
                }

                final vehicleData = vehicleSnapshot.data!;
                final truckName = vehicleData['makeModel'] ?? 'Unknown Vehicle';
                final mainImageUrl = vehicleData['mainImageUrl'] ?? '';
                final readyDate =
                    offerData['dealerSelectedCollectionDate'] != null
                        ? DateFormat('d MMMM yyyy').format(
                            offerData['dealerSelectedCollectionDate'].toDate())
                        : 'Unknown Date';
                final readyTime =
                    offerData['dealerSelectedCollectionTime'] ?? 'Unknown Time';
                final location =
                    offerData['dealerSelectedCollectionLocation'] ??
                        'Unknown Location';
                final address = (offerData['dealerSelectedCollectionAddress'] ??
                        offerData['dealerSelectedCollectionLocation'] ??
                        '')
                    .toString();

                final bool hasDealerSelection =
                    offerData['dealerSelectedCollectionDate'] != null &&
                        offerData['dealerSelectedCollectionTime'] != null &&
                        (offerData['dealerSelectedCollectionLocation'] ?? '')
                            .toString()
                            .isNotEmpty;

                // If dealer hasn't selected collection yet, prompt navigation to selection page
                if (userRole == 'dealer' && !hasDealerSelection) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Please select your collection date and time.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            text: 'Select Collection Slot',
                            borderColor: Colors.blue,
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CollectionDetailsPage(
                                    offerId: widget.offerId,
                                  ),
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                            width: 100,
                            height: 100,
                            child: Image.asset('lib/assets/CTPLogo.png')),
                        const SizedBox(height: 32),
                        const Text(
                          'Collection Ready',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Your vehicle is now ready for collection. Please review the details below and proceed when you are ready.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: mainImageUrl.isNotEmpty
                              ? NetworkImage(mainImageUrl)
                              : const AssetImage('lib/assets/truck_image.png')
                                  as ImageProvider,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          truckName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'READY FOR COLLECTION',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            readyDate,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            'TIME : $readyTime',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            location.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Quick actions: copy address and open in maps
                        CustomButton(
                          text: 'COPY ADDRESS',
                          borderColor: Colors.blue,
                          onPressed: () async {
                            final formatted = 'Address: ${address.isNotEmpty ? address : location.toString()}\nDate: $readyDate\nTime: $readyTime';
                            await Clipboard.setData(ClipboardData(text: formatted));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Collection details copied')),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        CustomButton(
                          text: 'OPEN IN MAPS',
                          borderColor: Colors.blue,
                          onPressed: () async {
                            final query = (address.isNotEmpty ? address : location.toString()).trim();
                            if (query.isEmpty) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No address available')),
                                );
                              }
                              return;
                            }
                            final encoded = Uri.encodeComponent(query);
                            // Prefer Apple Maps on iOS, Google Maps elsewhere
                            final TargetPlatform platform = Theme.of(context).platform;
                            final uri = (platform == TargetPlatform.iOS)
                                ? Uri.parse('https://maps.apple.com/?q=$encoded')
                                : Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
                            final ok = await canLaunchUrl(uri);
                            if (ok) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not open maps')),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        CustomButton(
                          text: 'VEHICLE COLLECTED',
                          borderColor: Colors.blue,
                          onPressed: () async {
                            await MyNavigator.push(
                              context,
                              CollectVehiclePage(offerId: widget.offerId),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        CustomButton(
                          text: 'REPORT AN ISSUE',
                          borderColor: const Color(0xFFFF4E00),
                          onPressed: () async {
                            await MyNavigator.push(
                                context,
                                ReportIssuePage(
                                  offerId: widget.offerId,
                                ));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? CustomBottomNavigation(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            )
          : null,
    );
  }
}
