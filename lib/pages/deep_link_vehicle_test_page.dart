import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/models/vehicle.dart';

class DeepLinkVehicleTestPage extends StatefulWidget {
  const DeepLinkVehicleTestPage({super.key});

  @override
  State<DeepLinkVehicleTestPage> createState() =>
      _DeepLinkVehicleTestPageState();
}

class _DeepLinkVehicleTestPageState extends State<DeepLinkVehicleTestPage> {
  final TextEditingController _vehicleIdController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Vehicle? _foundVehicle;

  @override
  void initState() {
    super.initState();
    // Pre-populate with a sample URL format
    _urlController.text = 'https://www.ctpapp.co.za/vehicle/';
  }

  Future<void> _testVehicleDeepLink() async {
    final vehicleId = _vehicleIdController.text.trim();
    if (vehicleId.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a vehicle ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _foundVehicle = null;
    });

    try {
      // Test fetching vehicle from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      if (!doc.exists) {
        setState(() {
          _errorMessage = 'Vehicle not found with ID: $vehicleId';
          _isLoading = false;
        });
        return;
      }

      final vehicle = Vehicle.fromDocument(doc);
      setState(() {
        _foundVehicle = vehicle;
        _urlController.text = 'https://www.ctpapp.co.za/vehicle/$vehicleId';
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Vehicle found! Deep link would work.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error testing deep link: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _copyUrlToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _urlController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('URL copied to clipboard!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _navigateToVehicle() {
    if (_foundVehicle != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VehicleDetailsPage(vehicle: _foundVehicle!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101828),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F7FFF),
        title: const Text(
          'Vehicle Deep Link Tester',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions Card
            Card(
              color: const Color(0xFF1F2937),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Vehicle Deep Link Testing',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Test the vehicle deep linking functionality by entering a vehicle ID below. This will verify that the vehicle exists and generate a shareable URL.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Vehicle ID Input
            TextField(
              controller: _vehicleIdController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Vehicle ID',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: 'Enter vehicle ID to test',
                hintStyle: const TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF2F7FFF)),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Button
            ElevatedButton(
              onPressed: _isLoading ? null : _testVehicleDeepLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4E00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Test Vehicle Deep Link',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // Error Message
            if (_errorMessage != null)
              Card(
                color: Colors.red.shade900,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

            // Success Result
            if (_foundVehicle != null) ...[
              Card(
                color: Colors.green.shade900,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✅ Vehicle Found!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Brand: ${_foundVehicle!.brands.join(', ')}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Model: ${_foundVehicle!.makeModel}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        'Year: ${_foundVehicle!.year}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Generated URL
              TextField(
                controller: _urlController,
                readOnly: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Generated Deep Link URL',
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF2F7FFF)),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.copy, color: Color(0xFF2F7FFF)),
                    onPressed: _copyUrlToClipboard,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Navigate Button
              ElevatedButton(
                onPressed: _navigateToVehicle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F7FFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Navigate to Vehicle Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            const Spacer(),

            // Instructions Card
            Card(
              color: const Color(0xFF1F2937),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'How Vehicle Deep Linking Works:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Vehicle details page has a share button\n'
                      '2. Sharing creates URL: https://www.ctpapp.co.za/vehicle/{vehicleId}\n'
                      '3. When someone clicks the link, app routes to vehicle details\n'
                      '4. Vehicle is loaded from Firestore and displayed\n'
                      '5. Works on web, mobile, and when app is closed',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _vehicleIdController.dispose();
    _urlController.dispose();
    super.dispose();
  }
}
