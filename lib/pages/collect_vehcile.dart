import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_text_field.dart';
import 'package:ctp/pages/rating_pages/rate_transporter_page.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';

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
    _fetchTruckData();
  }

  Future<void> _fetchTruckData() async {
    try {
      DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .get();

      if (offerSnapshot.exists) {
        String vehicleId = offerSnapshot.get('vehicleId');
        DocumentSnapshot vehicleSnapshot = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(vehicleId)
            .get();

        if (vehicleSnapshot.exists) {
          setState(() {
            _truckMainImageUrl = vehicleSnapshot.get('mainImageUrl');
            _truckName = vehicleSnapshot.get('name');
            _registrationNumber = vehicleSnapshot.get('registrationNumber');
          });
        }
      }
    } catch (e) {
      print('Error fetching truck data: $e');
    }
  }

  void _verifyLicensePlate() {
    if (_licensePlateController.text == _registrationNumber) {
      setState(() {
        _isMatched = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('License plate matched successfully')),
      );
      Future.delayed(const Duration(seconds: 3), () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RateTransporterPage(
              offerId: widget.offerId,
              fromCollectionPage: true, // Pass the new parameter
            ),
          ),
        );
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
                      Image.asset('lib/assets/CTPLogo.png'),
                      const SizedBox(height: 16),
                      const Text(
                        'COLLECT VEHICLE',
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
                        backgroundImage: _truckMainImageUrl != null
                            ? NetworkImage(_truckMainImageUrl!)
                            : const AssetImage('lib/assets/truck_image.png')
                                as ImageProvider,
                      ),
                      const SizedBox(height: 16),
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
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
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
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              CustomButton(
                text: 'SUBMIT',
                borderColor: const Color(0xFFFF4E00),
                onPressed: _verifyLicensePlate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
