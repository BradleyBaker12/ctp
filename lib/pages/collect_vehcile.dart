import 'package:ctp/components/custom_text_field.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/rating_pages/rate_dealer_page_two.dart';
import 'package:ctp/pages/rating_pages/rate_transporter_page_two.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:ctp/utils/navigation.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:auto_route/auto_route.dart';

@RoutePage()
class CollectVehiclePage extends StatefulWidget {
  final String offerId;

  const CollectVehiclePage({super.key, required this.offerId});

  @override
  _CollectVehiclePageState createState() => _CollectVehiclePageState();
}

class _CollectVehiclePageState extends State<CollectVehiclePage> {
  String? _truckMainImageUrl;
  String _truckName = '';
  String _registrationNumber = '';
  final TextEditingController _licensePlateController = TextEditingController();
  bool _isMatched = false;
  @override
  void initState() {
    super.initState();
    // Use Future.microtask to schedule the fetch after the build
    Future.microtask(_fetchTruckData);
  }

  Future<void> _fetchTruckData() async {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final offerProvider = Provider.of<OfferProvider>(context, listen: false);

    await vehicleProvider.fetchVehicles(userProvider);

    final Offer? offer = offerProvider.offers
        .firstWhereOrNull((o) => o.offerId == widget.offerId);
    if (offer != null) {
      final Vehicle? vehicle = vehicleProvider.vehicles
          .firstWhereOrNull((v) => v.id == offer.vehicleId);

      if (mounted) {
        setState(() {
          _truckMainImageUrl = vehicle?.mainImageUrl;
          _truckName = vehicle?.makeModel ?? '';
          _registrationNumber = vehicle?.registrationNumber ?? '';
        });
      }
    }
  }

  void _verifyLicensePlate() async {
    if (_licensePlateController.text == _registrationNumber) {
      setState(() {
        _isMatched = true;
      });

      try {
        final offerProvider =
            Provider.of<OfferProvider>(context, listen: false);
        final currentOffer = offerProvider.offers.firstWhere(
          (offer) => offer.offerId == widget.offerId,
          orElse: () => throw Exception('Offer not found'),
        );

        print('DEBUG: Starting collection process for offer ${widget.offerId}');
        print(
            'DEBUG: Current offer status before update: ${currentOffer.offerStatus}');

        // Create a batch write to ensure atomicity
        WriteBatch batch = FirebaseFirestore.instance.batch();

        // Update the vehicle status
        DocumentReference vehicleRef = FirebaseFirestore.instance
            .collection('vehicles')
            .doc(currentOffer.vehicleId);

        batch.update(vehicleRef, {
          'status': 'sold',
          'soldDate': FieldValue.serverTimestamp(),
          'isSold': true,
        });

        // Update the offer status with a more specific and final status
        DocumentReference offerRef =
            FirebaseFirestore.instance.collection('offers').doc(widget.offerId);

        batch.update(offerRef, {
          'offerStatus':
              'collected', // Use 'collected' instead of 'sold' to be more specific
          'collectionDate': FieldValue.serverTimestamp(),
          'soldDate': FieldValue.serverTimestamp(),
          'finalStatus': true,
          'isCompleted': true,
          'isSold': true,
          'collectionConfirmed': true,
          'licenseVerified': true,
          'transactionComplete':
              true, // Add this flag to prevent any auto-rejection
          'statusLocked':
              true, // Add this to indicate status should not be changed
          'collectorUserId':
              Provider.of<UserProvider>(context, listen: false).userId,
        });

        // Commit the batch
        await batch.commit();

        print('DEBUG: Batch update completed - offer status set to collected');

        // Add a small delay and then verify/re-enforce the status
        await Future.delayed(const Duration(seconds: 1));

        // Verify and re-enforce the status if it was changed
        final verifyOffer = await FirebaseFirestore.instance
            .collection('offers')
            .doc(widget.offerId)
            .get();

        final currentStatus = verifyOffer.data()?['offerStatus'];
        print('DEBUG: Verified offer status after update: $currentStatus');

        // If status was somehow changed away from 'collected', force it back
        if (currentStatus != 'collected') {
          print(
              'WARNING: Status was changed to $currentStatus, forcing back to collected');
          await FirebaseFirestore.instance
              .collection('offers')
              .doc(widget.offerId)
              .update({
            'offerStatus': 'collected',
            'statusOverride': true,
            'statusLocked': true,
            'forceCollected': FieldValue.serverTimestamp(),
          });

          // Verify again
          final reVerifyOffer = await FirebaseFirestore.instance
              .collection('offers')
              .doc(widget.offerId)
              .get();
          print(
              'DEBUG: Re-verified offer status: ${reVerifyOffer.data()?['offerStatus']}');
        }

        // Also verify the vehicle status
        final verifyVehicle = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(currentOffer.vehicleId)
            .get();

        print(
            'DEBUG: Verified vehicle status after update: ${verifyVehicle.data()?['status']}');

        // Get the current user's role from UserProvider
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final String userRole = userProvider.getUserRole;

        // Notify admins and sales reps that vehicle collection was confirmed
        try {
          final adminSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('userRole',
                  whereIn: ['admin', 'sales representative']).get();
          for (var doc in adminSnapshot.docs) {
            await FirebaseFirestore.instance.collection('notifications').add({
              'userId': doc.id,
              'offerId': widget.offerId,
              'type': 'releasePaymentToTransporter',
              'createdAt': FieldValue.serverTimestamp(),
              'message':
                  'Dealer confirmed vehicle collected for offer ${widget.offerId}. Please release payment to transporter.',
            });
          }
        } catch (_) {}

        // Update offer provider to refresh status
        if (mounted) {
          await offerProvider.fetchOffers(userProvider.userId ?? '',
              userProvider.getUserRole); // Pass user ID and role
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
              const SnackBar(
                  content: Text('License plate matched successfully'),
                  duration: Duration(seconds: 3)),
            )
            .closed
            .then((_) async {
          if (userRole == 'dealer') {
            await MyNavigator.push(
              context,
              RateTransporterPageTwo(
                offerId: widget.offerId,
                fromCollectionPage: true,
              ),
            );
          } else {
            await MyNavigator.push(
              context,
              RateDealerPageTwo(
                offerId: widget.offerId,
              ),
            );
          }
        });
      } catch (e) {
        print('Error updating offer status: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating offer status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      setState(() {
        _isMatched = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('License plate does not match')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
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
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Image.asset('lib/assets/CTPLogo.png'),
                      ),
                      const SizedBox(height: 64),
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _truckMainImageUrl != null
                            ? NetworkImage(_truckMainImageUrl!)
                            : const AssetImage('lib/assets/truck_image.png')
                                as ImageProvider,
                      ),
                      const SizedBox(height: 64),
                      const Text(
                        'COLLECT VEHICLE',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        _truckName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'CTP requires proof of collection of the vehicle. Please enter the license plate number.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      CustomTextField(
                        hintText: 'License Plate Number',
                        controller: _licensePlateController,
                      ),
                      const SizedBox(height: 16),
                      if (_isMatched)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green, size: 60),
                              SizedBox(height: 8),
                              Text(
                                'License plate matched successfully.',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    CustomButton(
                      text: 'Done'.toUpperCase(),
                      borderColor: const Color(0xFF00FF00),
                      onPressed: _verifyLicensePlate,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Cancel'.toUpperCase(),
                      borderColor: const Color(0xFFFF4E00),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension method to get the first element or return null if not found
extension ListExtensions<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
