import 'package:flutter/material.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:intl/intl.dart';

// import 'package:auto_route/auto_route.dart';

// @RoutePage()
class BulkOfferDetailsPage extends StatelessWidget {
  final Offer offer;
  final List<Vehicle> vehicles;

  const BulkOfferDetailsPage({
    super.key,
    required this.offer,
    required this.vehicles,
  });

  String formatAmount(double? amount) {
    if (amount == null) return 'R 0';
    return NumberFormat.currency(locale: 'en_ZA', symbol: 'R', decimalDigits: 0)
        .format(amount)
        .replaceAll(',', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Offer Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Offer ID: ${offer.offerId}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Amount: ${formatAmount(offer.offerAmount)}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Status: ${offer.offerStatus}',
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(height: 24),
            Text('Vehicles (${vehicles.length})',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: vehicles.length,
                itemBuilder: (ctx, i) {
                  final v = vehicles[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading:
                          v.mainImageUrl != null && v.mainImageUrl!.isNotEmpty
                              ? Image.network(v.mainImageUrl!,
                                  width: 60, height: 60, fit: BoxFit.cover)
                              : const SizedBox(width: 60, height: 60),
                      title: Text(
                          '${v.year} ${v.brands.join(', ')} ${v.makeModel} ${v.variant}'),
                      subtitle: Text(v.registrationNumber),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
