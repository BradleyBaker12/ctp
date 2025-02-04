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
import 'package:ctp/components/web_navigation_bar.dart';

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

    FirebaseFirestore.instance
        .collection('offers')
        .doc(widget.offerId)
        .update({'offerStatus': 'Payment Approved'});

    return Scaffold(
      key: _scaffoldKey,
      appBar: kIsWeb
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: WebNavigationBar(
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
                        children: navigationItems.map((item) {
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

            FirebaseFirestore.instance
                .collection('vehicles')
                .doc(vehicleId)
                .update({'vehicleStatus': 'Sold'});

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
                          'Payment Approved',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
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
                        CustomButton(
                          text: 'VEHICLE COLLECTED',
                          borderColor: Colors.blue,
                          onPressed: () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CollectVehiclePage(offerId: widget.offerId),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        CustomButton(
                          text: 'REPORT AN ISSUE',
                          borderColor: const Color(0xFFFF4E00),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReportIssuePage(
                                  offerId: widget.offerId,
                                ),
                              ),
                            );
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
