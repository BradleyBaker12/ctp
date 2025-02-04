// lib/adminScreens/payment_options_page.dart

import 'package:ctp/pages/payment_approved.dart';
import 'package:ctp/pages/payment_pending_page.dart';
import 'package:ctp/pages/offer_summary_page.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/components/web_navigation_bar.dart';

class PaymentOptionsPage extends StatefulWidget {
  final String offerId;

  const PaymentOptionsPage({super.key, required this.offerId});

  @override
  _PaymentOptionsPageState createState() => _PaymentOptionsPageState();
}

class _PaymentOptionsPageState extends State<PaymentOptionsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0; // For bottom navigation

  // Add getter for compact navigation
  bool _isCompactNavigation(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1100;

  // Add getter for large screen
  bool get _isLargeScreen => MediaQuery.of(context).size.width > 900;

  @override
  void initState() {
    super.initState();
    _updateOfferStatus(); // Update the offer status when the page loads
  }

  /// Update the offer status to 'payment options' upon page load
  Future<void> _updateOfferStatus() async {
    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({'offerStatus': 'payment options'});

      print('Offer status updated to "payment options"');
    } catch (e) {
      print('Failed to update offer status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update offer status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Navigate based on payment status
  Future<void> _navigateBasedOnStatus(
      BuildContext context, String? paymentStatus) async {
    if (paymentStatus == 'approved') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentApprovedPage(offerId: widget.offerId),
        ),
      );
    } else if (paymentStatus == 'pending') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPendingPage(offerId: widget.offerId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unknown payment status: $paymentStatus'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Handle "Generate Invoice" button press
  Future<void> _handleGenerateInvoice(DocumentSnapshot offerSnapshot) async {
    final offerData = offerSnapshot.data() as Map<String, dynamic>;
    final String? externalInvoice = offerData['externalInvoice'];

    if (externalInvoice != null && externalInvoice.isNotEmpty) {
      // **Step 1:** Invoice exists, allow user to view it
      if (await canLaunch(externalInvoice)) {
        await launch(externalInvoice);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch invoice URL'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // **Step 2:** Invoice not uploaded, send a message by setting 'needsInvoice' flag
      try {
        await FirebaseFirestore.instance
            .collection('offers')
            .doc(widget.offerId)
            .update({'needsInvoice': true});

        // **Step 3:** Notify the user that the admin has been notified
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice not uploaded. Admin notified.'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        print('Failed to send invoice request: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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

    return Scaffold(
      // This ensures the body extends behind the AppBar (if present)
      extendBodyBehindAppBar: true,
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
      // Wrap the GradientBackground in a SizedBox.expand to fill the available space.
      body: SizedBox.expand(
        child: GradientBackground(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('offers')
                .doc(widget.offerId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error fetching offer details',
                    style: GoogleFonts.montserrat(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(
                  child: Text(
                    'Offer not found',
                    style: GoogleFonts.montserrat(color: Colors.red),
                  ),
                );
              }

              final offerData = snapshot.data!.data() as Map<String, dynamic>;

              final String offerStatus = offerData['offerStatus'] ?? '';
              final String? externalInvoice = offerData['externalInvoice'];
              final String? paymentStatus = offerData['paymentStatus'];

              // **Determine if "Continue" button should be enabled based on Firestore data**
              bool isContinueEnabled =
                  externalInvoice != null && externalInvoice.isNotEmpty;

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      16.0, kIsWeb ? 100 : 16.0, 16.0, 16.0),
                  child: Column(
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
                      const SizedBox(height: 16),
                      Image.asset('lib/assets/CTPLogo.png'),
                      const SizedBox(height: 64),
                      Text(
                        'PAYMENT OPTIONS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
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
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 32), // Spacing before buttons

                      /// **Step 1 & Step 2 Buttons**
                      CustomButton(
                        text: externalInvoice != null &&
                                externalInvoice.isNotEmpty
                            ? 'VIEW INVOICE'
                            : 'GENERATE INVOICE',
                        borderColor: const Color(0xFFFF4E00),
                        onPressed: () => _handleGenerateInvoice(snapshot.data!),
                      ),
                      const SizedBox(height: 16),

                      CustomButton(
                        text: 'PAY ONLINE NOW',
                        borderColor: const Color(0xFFFF4E00),
                        onPressed: () {
                          // Implement online payment functionality here
                          // For example, navigate to a payment gateway page
                        },
                      ),
                      const SizedBox(height: 16),

                      CustomButton(
                        text: 'SEND OFFER SUMMARY',
                        borderColor: const Color(0xFFFF4E00),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OfferSummaryPage(offerId: widget.offerId),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      /// **"Continue" Button**
                      CustomButton(
                        text: 'CONTINUE',
                        borderColor: const Color(0xFFFF4E00),
                        onPressed: isContinueEnabled
                            ? () {
                                _navigateBasedOnStatus(context, paymentStatus);
                              }
                            : null, // Disable if invoice not uploaded
                        // Optionally, adjust appearance when disabled
                        disabledColor: Colors.grey,
                      ),
                      const SizedBox(height: 16), // Bottom padding
                    ],
                  ),
                ),
              );
            },
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
