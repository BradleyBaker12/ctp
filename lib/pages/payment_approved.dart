import 'package:ctp/pages/collect_vehcile.dart';
import 'package:ctp/pages/report_issue.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:ctp/components/custom_bottom_navigation.dart'; // Ensure this import is correct

class PaymentApprovedPage extends StatefulWidget {
  final String offerId;

  const PaymentApprovedPage({super.key, required this.offerId});

  @override
  _PaymentApprovedPageState createState() => _PaymentApprovedPageState();
}

class _PaymentApprovedPageState extends State<PaymentApprovedPage> {
  int _selectedIndex =
      0; // Variable to keep track of the selected bottom nav item

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

  Future<void> _updateOfferStatusToDone() async {
    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({'offerStatus': 'Done'});
      print('Offer status updated to Done');
    } catch (e) {
      print('Error updating offer status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update the offer status to "Payment Approved"
    FirebaseFirestore.instance
        .collection('offers')
        .doc(widget.offerId)
        .update({'offerStatus': 'Payment Approved'});

    return Scaffold(
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
                        ? DateFormat('dd / MM / yyyy').format(
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
                        const SizedBox(height: 16),
                        Image.asset('lib/assets/CTPLogo.png'),
                        const SizedBox(height: 16),
                        const Text(
                          'PAYMENT APPROVED',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: mainImageUrl.isNotEmpty
                              ? NetworkImage(mainImageUrl)
                              : const AssetImage('lib/assets/truck_image.png')
                                  as ImageProvider,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          truckName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'READY FOR COLLECTION',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
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
                            readyDate,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
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
                            location,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16), // Add some spacing
                        CustomButton(
                          text: 'VEHICLE COLLECTED',
                          borderColor: Colors.blue,
                          onPressed: () async {
                            await _updateOfferStatusToDone();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CollectVehiclePage(offerId: widget.offerId),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8), // Add some spacing
                        CustomButton(
                          text: 'REPORT AN ISSUE',
                          borderColor: const Color(0xFFFF4E00),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ReportIssuePage(),
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
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
