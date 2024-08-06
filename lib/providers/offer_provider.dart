import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Offer extends ChangeNotifier {
  final String offerId;
  final String dealerId;
  final String vehicleId;
  final String transportId;
  final double? offerAmount;
  final String? offerStatus;
  String? vehicleMakeModel;
  String? vehicleMainImage;
  String? reason;

  Offer(
      {required this.offerId,
      required this.dealerId,
      required this.vehicleId,
      required this.transportId,
      this.offerAmount,
      this.offerStatus,
      this.vehicleMakeModel,
      this.vehicleMainImage,
      this.reason});

  factory Offer.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Offer(
      offerId: data['offerId'] ?? '',
      dealerId: data['dealerId'] ?? '',
      vehicleId: data['vehicleId'] ?? '',
      transportId: data['transportId'] ?? '',
      offerAmount: data['offerAmount']?.toDouble(),
      offerStatus: data['offerStatus'] ?? 'Unknown',
      vehicleMakeModel: data['vehicleMakeModel'],
      vehicleMainImage: data['vehicleMainImage'],
      reason: data['reason'],
    );
  }

  Future<void> fetchVehicleDetails() async {
    try {
      DocumentSnapshot vehicleSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      if (vehicleSnapshot.exists) {
        Map<String, dynamic> vehicleData =
            vehicleSnapshot.data() as Map<String, dynamic>;
        vehicleMakeModel = vehicleData['makeModel'] ?? 'Unknown';
        vehicleMainImage = vehicleData['mainImageUrl'];
        print('Fetched vehicle details for $vehicleId');
        notifyListeners(); // Notify listeners after fetching vehicle details
      } else {
        vehicleMakeModel = 'Unknown';
        vehicleMainImage = null;
        print('No vehicle details found for $vehicleId');
      }
    } catch (e) {
      print('Error fetching vehicle details: $e');
    }
  }
}

class OfferProvider extends ChangeNotifier {
  List<Offer> _offers = [];

  List<Offer> get offers => _offers;

  Future<void> fetchOffers(String dealerId) async {
    try {
      print('Fetching offers for dealer $dealerId');
      QuerySnapshot offersSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('dealerId', isEqualTo: dealerId)
          .get();

      _offers = offersSnapshot.docs.map((doc) {
        return Offer.fromFirestore(doc);
      }).toList();

      for (Offer offer in _offers) {
        await offer.fetchVehicleDetails();
      }
      print('Fetched ${_offers.length} offers for dealer $dealerId');
      notifyListeners(); // Notify listeners after fetching offers
    } catch (e) {
      print('Error fetching offers: $e');
    }
  }
}
