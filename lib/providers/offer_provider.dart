import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Offer extends ChangeNotifier {
  final String offerId;
  final String dealerId;
  final String vehicleId;
  final String transportId;
  double? offerAmount; // This can now be modified
  String offerStatus; // Made mutable to update locally
  String? vehicleMakeModel;
  String? vehicleMainImage;
  String? reason;
  DateTime? createdAt; // Add this field

  // New properties for vehicle details
  List<String> vehicleImages = [];
  Map<String, String?> additionalInfo = {};
  String? vehicleYear;
  String? vehicleMileage;
  String? vehicleTransmission;

  // Inspection-related properties
  DateTime? dealerSelectedInspectionDate;
  String? dealerSelectedInspectionTime;
  String? dealerSelectedInspectionLocation;
  GeoPoint? latLng; // LatLng coordinates for location

  // Collection-related properties
  String? dealerSelectedCollectionLocation;
  String? dealerSelectedCollectionAddress;
  DateTime? dealerSelectedCollectionDate;
  String? dealerSelectedCollectionTime;

  // New fields for inspection and collection dates and locations
  final List<dynamic>? inspectionDates;
  final List<dynamic>? inspectionLocations;
  final List<dynamic>? collectionDates;
  final List<dynamic>? collectionLocations;

  Offer({
    required this.offerId,
    required this.dealerId,
    required this.vehicleId,
    required this.transportId,
    this.offerAmount,
    required this.offerStatus,
    this.vehicleMakeModel,
    this.vehicleMainImage,
    this.reason,
    this.createdAt, // Include in constructor
    this.dealerSelectedInspectionDate,
    this.dealerSelectedInspectionTime,
    this.dealerSelectedInspectionLocation,
    this.latLng,
    this.dealerSelectedCollectionLocation,
    this.dealerSelectedCollectionAddress,
    this.dealerSelectedCollectionDate,
    this.dealerSelectedCollectionTime,
    this.inspectionDates,
    this.inspectionLocations,
    this.collectionDates,
    this.collectionLocations,
  });

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
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null, // Handle null case
      dealerSelectedInspectionDate:
          (data['dealerSelectedInspectionDate'] != null)
              ? (data['dealerSelectedInspectionDate'] as Timestamp).toDate()
              : null,
      dealerSelectedInspectionTime: data['dealerSelectedInspectionTime'],
      dealerSelectedInspectionLocation:
          data['dealerSelectedInspectionLocation'],
      latLng: data['latLng'] != null ? data['latLng'] as GeoPoint : null,
      dealerSelectedCollectionLocation:
          data['dealerSelectedCollectionLocation'],
      dealerSelectedCollectionAddress: data['dealerSelectedCollectionAddress'],
      dealerSelectedCollectionDate:
          (data['dealerSelectedCollectionDate'] != null)
              ? (data['dealerSelectedCollectionDate'] as Timestamp).toDate()
              : null,
      dealerSelectedCollectionTime: data['dealerSelectedCollectionTime'],
      inspectionDates: data['inspectionDates'],
      inspectionLocations: data['inspectionLocations'],
      collectionDates: data['collectionDates'],
      collectionLocations: data['collectionLocations'],
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
        vehicleImages = List<String>.from(vehicleData['photos'] ?? []);
        additionalInfo = {
          'Engine Number': vehicleData['engineNumber'],
          'VIN Number': vehicleData['vinNumber'],
          // Add more fields as necessary
        };
        vehicleYear = vehicleData['year'];
        vehicleMileage = vehicleData['mileage'];
        vehicleTransmission = vehicleData['transmission'];
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

  Future<void> updateOfferAmount(double newAmount) async {
    try {
      offerAmount = newAmount; // Update local value
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(offerId)
          .update({'offerAmount': newAmount});
      notifyListeners(); // Notify listeners after updating
    } catch (e) {
      print('Error updating offer amount: $e');
    }
  }
}


class OfferProvider extends ChangeNotifier {
  List<Offer> _offers = [];

  List<Offer> get offers => _offers;

  // Method to fetch a specific offer by its ID
  Future<void> fetchOfferById(String offerId) async {
    try {
      DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .doc(offerId)
          .get();

      if (offerSnapshot.exists) {
        Offer offer = Offer.fromFirestore(offerSnapshot);
        _offers.add(offer);
        await offer.fetchVehicleDetails(); // Fetch related vehicle details
      } else {
        print('No offer found with ID $offerId');
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching offer: $e');
    }
  }

  Offer? getOfferById(String offerId) {
    for (var offer in _offers) {
      if (offer.offerId == offerId) {
        return offer;
      }
    }
    return null;
  }

  // Method to update the offer amount
  Future<void> updateOfferAmount(String offerId, double newAmount) async {
    try {
      Offer? offer = getOfferById(offerId);
      if (offer != null) {
        offer.offerAmount = newAmount; // Update local value
        await FirebaseFirestore.instance
            .collection('offers')
            .doc(offerId)
            .update({'offerAmount': newAmount});
        notifyListeners(); // Notify listeners after updating
      } else {
        print('Offer not found for update');
      }
    } catch (e) {
      print('Error updating offer amount: $e');
    }
  }

  Future<void> fetchOffers(String userId, String userRole) async {
    try {
      print('Fetching offers for user $userId with role $userRole');

      QuerySnapshot offersSnapshot;
      if (userRole == 'dealer') {
        // Fetch offers for dealer
        offersSnapshot = await FirebaseFirestore.instance
            .collection('offers')
            .where('dealerId', isEqualTo: userId)
            .get();
      } else if (userRole == 'transporter') {
        // Fetch offers for transporter
        offersSnapshot = await FirebaseFirestore.instance
            .collection('offers')
            .where('transportId', isEqualTo: userId)
            .get();
      } else {
        // Handle other roles or throw an error
        print('Unsupported user role: $userRole');
        return;
      }

      _offers = offersSnapshot.docs.map((doc) {
        return Offer.fromFirestore(doc);
      }).toList();

      for (Offer offer in _offers) {
        await offer.fetchVehicleDetails();
      }
      print('Fetched ${_offers.length} offers for user $userId');
      notifyListeners(); // Notify listeners after fetching offers
    } catch (e) {
      print('Error fetching offers: $e');
    }
  }

  Future<void> refreshOffers(String userId, String userRole) async {
    await fetchOffers(userId, userRole);
  }
}
