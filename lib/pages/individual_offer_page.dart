// lib/pages/individual_offer_page.dart
import 'package:flutter/material.dart';

class IndividualOfferPage extends StatefulWidget {
  static const routeName = '/individualOffer';

  const IndividualOfferPage({super.key});
  @override
  _IndividualOfferPageState createState() => _IndividualOfferPageState();
}

class _IndividualOfferPageState extends State<IndividualOfferPage> {
  final _controllers = <String, TextEditingController>{};
  late List<String> vehicleIds;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    vehicleIds =
        ModalRoute.of(context)!.settings.arguments as List<String>? ?? [];
    for (var id in vehicleIds) {
      _controllers[id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Individual Offers (${vehicleIds.length})')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            for (var id in vehicleIds) ...[
              Text('Vehicle ID: $id',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: _controllers[id],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Offer Amount for $id'),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(
              onPressed: () {
                // TODO: collect all _controllers[id].text and submit per-vehicle offers
              },
              child: Text('Submit All Offers'),
            ),
          ],
        ),
      ),
    );
  }
}
