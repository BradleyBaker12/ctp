import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/pages/report_issue.dart';
import 'package:ctp/pages/upload_pop.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/pages/payment_approved.dart';
import 'package:ctp/pages/collectionPages/collection_details_page.dart';
import 'package:ctp/components/custom_bottom_navigation.dart'; // Ensure this import is correct
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ctp/components/web_navigation_bar.dart' as ctp_nav;
import 'package:ctp/utils/navigation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:auto_route/auto_route.dart';

@RoutePage()
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

  // Cache admin/sales rep contacts for Help dialog
  List<Map<String, dynamic>> _adminContacts = [];
  bool _loadingAdmins = false;

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

          final userRole =
              Provider.of<UserProvider>(context, listen: false).getUserRole;
          if (userRole == 'dealer') {
            await MyNavigator.pushReplacement(
              context,
              CollectionDetailsPage(offerId: widget.offerId),
            );
          } else {
            await MyNavigator.pushReplacement(
              context,
              PaymentApprovedPage(offerId: widget.offerId),
            );
          }
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

  Future<void> _loadAdminContacts() async {
    if (_adminContacts.isNotEmpty || _loadingAdmins) return;
    setState(() => _loadingAdmins = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userRole', whereIn: ['admin', 'sales representative']).get();
      setState(() {
        _adminContacts = snapshot.docs.map((d) {
          final data = d.data();
          return {
            'id': d.id,
            'name': ((data['firstName'] ?? '') + ' ' + (data['lastName'] ?? ''))
                .trim(),
            'tradingName': data['tradingName'] ?? '',
            'email': data['email'] ?? '',
            'phone': data['phoneNumber'] ?? '',
            'role': data['userRole'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      // ignore silently; help panel will show empty state
    } finally {
      if (mounted) setState(() => _loadingAdmins = false);
    }
  }

  Future<void> _notifyAdminsSupport({String? note}) async {
    try {
      // Ensure we have admin contacts to notify
      if (_adminContacts.isEmpty) {
        await _loadAdminContacts();
      }

      final now = FieldValue.serverTimestamp();
      // Create a support request record
      await FirebaseFirestore.instance.collection('supportRequests').add({
        'offerId': widget.offerId,
        'createdAt': now,
        'status': 'open',
        'source': 'PaymentPendingPage',
        'note': note ?? 'Dealer requested help on payment pending.',
      });

      // Create a notification for each admin/sales rep
      for (final admin in _adminContacts) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': admin['id'],
          'offerId': widget.offerId,
          'type': 'supportRequest',
          'createdAt': now,
          'message': 'Help requested for offer ${widget.offerId}',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CTP has been notified. Someone will contact you.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to notify support: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showHelpSheet() async {
    await _loadAdminContacts();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1520),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Need help?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Contact CTP or notify an admin to assist you.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                if (_loadingAdmins)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_adminContacts.isEmpty)
                  const Text(
                    'Admin contacts are currently unavailable.',
                    style: TextStyle(color: Colors.white70),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _adminContacts.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.white24),
                      itemBuilder: (context, index) {
                        final a = _adminContacts[index];
                        final trading = (a['tradingName'] ?? '') as String;
                        final name = (a['name'] ?? '') as String;
                        final displayName = trading.isNotEmpty
                            ? trading
                            : (name.isNotEmpty ? name : 'CTP Admin');
                        final email = a['email'] as String? ?? '';
                        final phone = a['phone'] as String? ?? '';
                        return ListTile(
                          title: Text(displayName,
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (email.isNotEmpty)
                                InkWell(
                                  onTap: () async {
                                    final uri =
                                        Uri(scheme: 'mailto', path: email);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    }
                                  },
                                  child: Text(email,
                                      style: const TextStyle(
                                          color: Colors.lightBlueAccent)),
                                ),
                              if (phone.isNotEmpty)
                                InkWell(
                                  onTap: () async {
                                    final uri = Uri(scheme: 'tel', path: phone);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    }
                                  },
                                  child: Text(phone,
                                      style: const TextStyle(
                                          color: Colors.lightBlueAccent)),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4E00),
                        ),
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await _notifyAdminsSupport();
                        },
                        child: const Text('Notify CTP'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
                        text: 'HELP',
                        borderColor: Colors.blueAccent,
                        onPressed: _showHelpSheet,
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
