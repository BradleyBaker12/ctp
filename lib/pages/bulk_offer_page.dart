// lib/pages/bulk_offer_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:auto_route/auto_route.dart';
@RoutePage()class BulkOfferPage extends StatefulWidget {
  static const routeName = '/bulkOffer';

  const BulkOfferPage({super.key});

  @override
  _BulkOfferPageState createState() => _BulkOfferPageState();
}

class _BulkOfferPageState extends State<BulkOfferPage> {
  bool _didFetchArgs = false;

  late Future<List<Vehicle>> _vehiclesFuture;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // move argument fetching into didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didFetchArgs) {
      _didFetchArgs = true;
      final vehicleIds =
          ModalRoute.of(context)!.settings.arguments as List<String>? ?? [];
      _vehiclesFuture = FirebaseFirestore.instance
          .collection('vehicles')
          .where(FieldPath.documentId, whereIn: vehicleIds)
          .get()
          .then((snap) =>
              snap.docs.map((doc) => Vehicle.fromDocument(doc)).toList());
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Bulk Offer')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: FutureBuilder<List<Vehicle>>(
                  future: _vehiclesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final vehicles = snapshot.data ?? [];
                    if (vehicles.isEmpty) {
                      return const Center(child: Text('No vehicles found.'));
                    }
                    return ListView.builder(
                      itemCount: vehicles.length,
                      itemBuilder: (ctx, i) {
                        final v = vehicles[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          color: Colors.grey[800],
                          child: ListTile(
                            leading: v.mainImageUrl != null &&
                                    v.mainImageUrl!.isNotEmpty
                                ? Image.network(
                                    v.mainImageUrl!,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  )
                                : const SizedBox(width: 60, height: 60),
                            title: Text(
                              '${v.brands.join(', ')} ${v.makeModel.toUpperCase()} ${v.year}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '${v.brands.join(', ')} ${v.makeModel} ${v.variant} ${v.year}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Single bulk-offer amount input
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Offer Amount',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixText: 'R ',
                  prefixStyle: const TextStyle(color: Colors.white),
                  border: OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Color(0xFFD84315)), // deep orange
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD84315), // deep orange
                    foregroundColor: Colors.white, // text color
                  ),
                  onPressed: () async {
                    final amount =
                        double.tryParse(_amountController.text) ?? 0.0;
                    final dealerId = FirebaseAuth.instance.currentUser!.uid;
                    final vehicles = await _vehiclesFuture;
                    final docRef =
                        FirebaseFirestore.instance.collection('offers').doc();
                    await docRef.set({
                      'offerId': docRef.id,
                      'offerType': 'bulk',
                      'vehicleId': vehicles.map((v) => v.id).toList(),
                      'dealerId': dealerId,
                      'offerAmount': amount,
                      'offerStatus': 'in-progress',
                      'paymentStatus': 'pending',
                      'createdAt': FieldValue.serverTimestamp(),
                      'dealerInspectionComplete': false,
                      'transporterInspectionComplete': false,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Bulk offers submitted successfully')),
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Submit Bulk Offer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
