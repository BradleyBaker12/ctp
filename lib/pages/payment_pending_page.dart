import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/pages/report_issue.dart';
import 'package:ctp/pages/upload_pop.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/pages/payment_approved.dart';
import 'package:ctp/components/custom_bottom_navigation.dart'; // Ensure this import is correct
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ctp/components/web_navigation_bar.dart';
import 'package:ctp/utils/navigation.dart';

class PaymentPendingPage extends StatefulWidget {
  final String offerId;

  const PaymentPendingPage({super.key, required this.offerId});

  @override
  _PaymentPendingPageState createState() => _PaymentPendingPageState();
}

class _PaymentPendingPageState extends State<PaymentPendingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex =
      0; // Variable to keep track of the selected bottom nav item
  bool _proofOfPaymentUploaded = false; // Track proof of payment status

  // Add getter for compact navigation
  bool _isCompactNavigation(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1100;

  // Add getter for large screen
  bool get _isLargeScreen => MediaQuery.of(context).size.width > 900;

  @override
  void initState() {
    super.initState();
    _updateOfferStatus(); // Update the offer status to "payment pending"
    _checkPaymentStatus();
    _checkProofOfPayment(); // Check if proof of payment is already uploaded
  }

  Future<void> _updateOfferStatus() async {
    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({
        'offerStatus': 'payment pending'
      }); // Update status to "payment pending"
    } catch (e) {
      print('Error updating offer status: $e');
    }
  }

  Future<void> _checkPaymentStatus() async {
    try {
      DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .get();

      if (offerSnapshot.exists) {
        String paymentStatus = offerSnapshot['paymentStatus'];

        if (paymentStatus == 'accepted') {
          // Update the offer status to "Payment Approved"
          await FirebaseFirestore.instance
              .collection('offers')
              .doc(widget.offerId)
              .update({'offerStatus': 'paid'});

          await MyNavigator.pushReplacement(
            context,
            PaymentApprovedPage(offerId: widget.offerId),
          );
        } else {
          // Keep checking the payment status if not yet accepted
          Future.delayed(const Duration(seconds: 5), _checkPaymentStatus);
        }
      }
    } catch (e) {
      print('Error checking payment status: $e');
    }
  }

  Future<void> _checkProofOfPayment() async {
    try {
      DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .get();

      if (offerSnapshot.exists) {
        String? proofOfPaymentUrl = offerSnapshot['proofOfPaymentUrl'];
        setState(() {
          _proofOfPaymentUploaded = proofOfPaymentUrl!.isNotEmpty;
        });
      }
    } catch (e) {
      print('Error checking proof of payment: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Optional: Refresh the proof of payment status when the page is resumed
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkProofOfPayment();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.getUserRole;
    final bool showBottomNav = !_isLargeScreen && !kIsWeb;

    // Define navigation items based on user role
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
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Image.asset('lib/assets/CTPLogo.png'),
                      const SizedBox(height: 100),
                      const Text(
                        'PAYMENT PENDING',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "You're almost there!",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      const SizedBox(
                        width: 350,
                        child: Text(
                          'Full payment needs to reflect before arranging collection. If payment is not made within 3 days, the transaction will be cancelled and other dealers will be able to offer again.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      // Conditionally display the "UPLOAD PROOF OF PAYMENT" button
                      if (userRole != 'transporter' && !_proofOfPaymentUploaded)
                        CustomButton(
                          text: 'UPLOAD PROOF OF PAYMENT',
                          borderColor: Colors.blue,
                          onPressed: () async {
                            await MyNavigator.push(
                              context,
                             UploadProofOfPaymentPage(offerId: widget.offerId),
                            ).then((_) {
                              // Refresh the proof of payment status when returning
                              _checkProofOfPayment();
                            });
                          },
                        ),
                      // Optionally, display a message or another widget indicating that the proof has been uploaded
                      if (_proofOfPaymentUploaded && userRole != 'transporter')
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Proof of payment has been uploaded and an admin will get back to you shortly.',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      CustomButton(
                        text: 'REPORT AN ISSUE',
                        borderColor: const Color(0xFFFF4E00),
                        onPressed: () async {
                         await MyNavigator.push(
                            context,
                            ReportIssuePage(
                              offerId: widget.offerId,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
