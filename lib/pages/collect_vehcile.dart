// ignore_for_file: unused_local_variable

import 'package:ctp/components/custom_text_field.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/rating_pages/rate_dealer_page_two.dart';
import 'package:ctp/pages/rating_pages/rate_transporter_page_two.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:provider/provider.dart';

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

  void _verifyLicensePlate() {
    if (_licensePlateController.text == _registrationNumber) {
      setState(() {
        _isMatched = true;
      });

      // Get the current user's role from UserProvider
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final String userRole = userProvider.getUserRole;
      final bool isAdmin = userRole == 'admin'; // Check if the user is an admin
      final bool isDealer =
          userRole == 'dealer'; // Check if the user is a dealer
      final bool isTransporter =
          userRole == 'transporter'; // Check if the user is a dealer

      ScaffoldMessenger.of(context)
          .showSnackBar(
            const SnackBar(
                content: Text('License plate matched successfully'),
                duration: Duration(seconds: 3)),
          )
          .closed
          .then((_) {
        if (isDealer) {
          // If user is dealer, navigate to rate transporter page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RateTransporterPageTwo(
                offerId: widget.offerId,
                fromCollectionPage: true,
              ),
            ),
          );
        } else {
          // If user is transporter, navigate to rate dealer page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RateDealerPageTwo(
                offerId: widget.offerId,
              ),
            ),
          );
        }
      });
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
