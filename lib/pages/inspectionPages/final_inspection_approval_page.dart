import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
// Removed direct navigation to rating pages; branching is handled inline
// Import RateDealerPage
import 'package:ctp/pages/report_issue.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:ctp/components/web_navigation_bar.dart';
import 'package:ctp/pages/payment_options_page.dart';

import 'package:auto_route/auto_route.dart';

@RoutePage()
class FinalInspectionApprovalPage extends StatefulWidget {
  final String offerId;
  final String oldOffer;
  final String vehicleName;

  const FinalInspectionApprovalPage({
    super.key,
    required this.offerId,
    required this.oldOffer,
    required this.vehicleName,
  });

  @override
  _FinalInspectionApprovalPageState createState() =>
      _FinalInspectionApprovalPageState();
}

class _FinalInspectionApprovalPageState
    extends State<FinalInspectionApprovalPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;
  bool _isLoading = false;
  bool dealerInspectionApproval = false;
  bool transporterInspectionApproval = false;
  bool _bothApproved = false;
  String? _collectionOption; // 'immediate' | 'scheduled'
  StreamSubscription<DocumentSnapshot>? _offerSub;
  final bool _navigated = false;

  // Add this getter for consistent breakpoint
  bool _isCompactNavigation(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1100;

  @override
  void initState() {
    super.initState();
    _updateOfferStatus();
    _checkApprovalStatus();
    _listenToOffer();
    print(
        'Initial state - Dealer approval: $dealerInspectionApproval, Transporter approval: $transporterInspectionApproval');
  }

  void _listenToOffer() {
    _offerSub = FirebaseFirestore.instance
        .collection('offers')
        .doc(widget.offerId)
        .snapshots()
        .listen((offerSnapshot) {
      if (!mounted) return;
      final Map<String, dynamic>? data = offerSnapshot.data();
      if (data == null) return;
      final dealerApproved = data['dealerApproved'] ?? false;
      final transporterApproved = data['transporterApproved'] ?? false;
      final collectionOption =
          (data['collectionOption'] as String?)?.toLowerCase();

      setState(() {
        dealerInspectionApproval = dealerApproved;
        transporterInspectionApproval = transporterApproved;
        _bothApproved = dealerApproved && transporterApproved;
        _collectionOption = collectionOption;
      });

      // Do not auto-navigate to collection here; next step is payment options.
    });
  }

  @override
  void dispose() {
    _offerSub?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _updateOfferStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({'offerStatus': 'inspection done'});
    } catch (e) {
      print('Failed to update offer status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkApprovalStatus() async {
    try {
      DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .get();

      Map<String, dynamic> data = offerSnapshot.data() as Map<String, dynamic>;
      bool dealerApproved = data['dealerApproved'] ?? false;
      bool transporterApproved = data['transporterApproved'] ?? false;
      final collectionOption =
          (data['collectionOption'] as String?)?.toLowerCase();

      print(
          'Checked approval status - Dealer: $dealerApproved, Transporter: $transporterApproved');

      setState(() {
        dealerInspectionApproval = dealerApproved;
        transporterInspectionApproval = transporterApproved;
        _bothApproved = dealerApproved && transporterApproved;
        _collectionOption = collectionOption;
      });
    } catch (e) {
      print('Failed to check approval status: $e');
    }
  }

  Future<void> _approveInspection(String userRole) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String fieldToUpdate =
          userRole == 'dealer' ? 'dealerApproved' : 'transporterApproved';
      print('Attempting to update $fieldToUpdate for $userRole');

      // Update the current user's approval
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({fieldToUpdate: true});

      // Get latest approval status
      DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .get();

      Map<String, dynamic> data = offerSnapshot.data() as Map<String, dynamic>;
      bool dealerApproved = data['dealerApproved'] ?? false;
      bool transporterApproved = data['transporterApproved'] ?? false;

      print(
          'Current approval status - Dealer: $dealerApproved, Transporter: $transporterApproved');

      // If both have approved, update status and show next-step options
      if (dealerApproved && transporterApproved) {
        print(
            'Both parties have approved - updating offer status and enabling next steps');

        await FirebaseFirestore.instance
            .collection('offers')
            .doc(widget.offerId)
            .update({'offerStatus': 'inspection done'});

        if (!mounted) return;

        setState(() {
          _bothApproved = true;
        });
      } else {
        // Update local state for UI
        setState(() {
          if (userRole == 'dealer') {
            dealerInspectionApproval = true;
          } else {
            transporterInspectionApproval = true;
          }
        });

        if (!mounted) return;

        // Show waiting message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userRole == 'dealer'
                ? 'Waiting for transporter approval'
                : 'Waiting for dealer approval'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error in approval process: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred during the approval process'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectImmediateCollection() async {
    try {
      final now = DateTime.now();
      final dueBy = now.add(const Duration(hours: 48));
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({
        'collectionOption': 'immediate',
        'immediateCollectionSelectedAt': FieldValue.serverTimestamp(),
        'paymentWindowHours': 48,
        'paymentDueBy': Timestamp.fromDate(dueBy),
        'offerStatus': 'payment options',
      });

      if (mounted) {
        setState(() {
          _collectionOption = 'immediate';
        });
      }

      // Notify admins/sales reps
      try {
        final adminSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('userRole',
                whereIn: ['admin', 'sales representative']).get();
        for (var doc in adminSnapshot.docs) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': doc.id,
            'offerId': widget.offerId,
            'type': 'immediateCollectionSelected',
            'createdAt': FieldValue.serverTimestamp(),
            'message':
                'Dealer selected Immediate Collection. Payment due within 48h.',
          });
        }
      } catch (_) {}

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentOptionsPage(offerId: widget.offerId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to select immediate collection: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectScheduledCollection() async {
    try {
      final now = DateTime.now();
      final dueBy = now.add(const Duration(hours: 48));
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({
        'collectionOption': 'scheduled',
        'scheduledCollectionSelectedAt': FieldValue.serverTimestamp(),
        // Align with immediate flow: set payment window + due date
        'paymentWindowHours': 48,
        'paymentDueBy': Timestamp.fromDate(dueBy),
        'offerStatus': 'payment options',
      });

      if (mounted) {
        setState(() {
          _collectionOption = 'scheduled';
        });
      }

      // Notify admins/sales reps similar to immediate flow
      try {
        final adminSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('userRole',
                whereIn: ['admin', 'sales representative']).get();
        for (var doc in adminSnapshot.docs) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': doc.id,
            'offerId': widget.offerId,
            'type': 'scheduledCollectionSelected',
            'createdAt': FieldValue.serverTimestamp(),
            'message': 'Dealer selected Scheduled Collection. Proceed to payment.',
          });
        }
      } catch (_) {}

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentOptionsPage(offerId: widget.offerId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to proceed to collection setup: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = screenSize.width * 0.05;
    final spacing = screenSize.height * 0.02;
    const bool isWeb = kIsWeb;

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

    return Scaffold(
      key: _scaffoldKey,
      appBar: isWeb
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: WebNavigationBar(
                isCompactNavigation: _isCompactNavigation(context),
                currentRoute: '/offers',
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            )
          : null,
      drawer: _isCompactNavigation(context) && isWeb
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
      body: Stack(
        children: [
          GradientBackground(
            child: SizedBox.expand(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: spacing),
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      SizedBox(height: spacing),
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: Image.asset(
                          'lib/assets/CTPLogo.png',
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'FINAL INSPECTION APPROVAL',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: spacing),
                      const Text(
                        "You're almost there!",
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: spacing),
                      const Text(
                        'By approving the transaction, you confirm that all conditions have been met to your satisfaction. If there are any issues, please select "Report an Issue" to provide details. Our team is here to assist you in resolving any concerns.',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: spacing),
                      Column(
                        children: [
                          // Hide Approve while selecting or after choosing collection option
                          if (!((_bothApproved && userRole == 'dealer') ||
                                  (_collectionOption == 'immediate' ||
                                      _collectionOption == 'scheduled')) &&
                              ((userRole == 'dealer' &&
                                      !dealerInspectionApproval) ||
                                  ((userRole == 'transporter' ||
                                          userRole == 'oem' || userRole == 'tradein' || userRole == 'trade-in') &&
                                      !transporterInspectionApproval)))
                            CustomButton(
                              text: 'APPROVE',
                              borderColor: Colors.blue,
                              onPressed: () {
                                _approveInspection(userRole);
                              },
                            ),
                          if (!_bothApproved &&
                              ((userRole == 'dealer' &&
                                      dealerInspectionApproval) ||
                                  ((userRole == 'transporter' ||
                                          userRole == 'oem' || userRole == 'tradein' || userRole == 'trade-in') &&
                                      transporterInspectionApproval)))
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Inspection Approved - Waiting for other party\'s approval',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          if (_bothApproved &&
                              (userRole == 'transporter' || userRole == 'oem' || userRole == 'tradein' || userRole == 'trade-in'))
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Both parties have approved. Waiting for the dealer to choose collection.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          // Show next-step options when both have approved
                          if (_bothApproved && userRole == 'dealer') ...[
                            const SizedBox(height: 20),
                            const Text(
                              'Choose how you\'d like to proceed with collection:',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            CustomButton(
                              text: 'IMMEDIATE COLLECTION (PAY WITHIN 48H)',
                              borderColor: Colors.orange,
                              onPressed: _selectImmediateCollection,
                            ),
                            const SizedBox(height: 12),
                            CustomButton(
                              text: 'SCHEDULE COLLECTION LATER',
                              borderColor: Colors.blue,
                              onPressed: _selectScheduledCollection,
                            ),
                          ],
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
                      SizedBox(height: spacing),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: (!kIsWeb)
          ? CustomBottomNavigation(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            )
          : null,
    );
  }
}
