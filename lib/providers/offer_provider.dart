// lib/models/offer.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// The Offer model representing each offer from Firestore.
class Offer extends ChangeNotifier {
  final String offerId;
  final String dealerId;
  final String vehicleId;
  final String transporterId;
  double? offerAmount;
  String offerStatus;
  String? description;
  String? vehicleMakeModel;
  String? vehicleMainImage;
  String? reason;
  DateTime? createdAt;
  String? vehicleBrand;
  String? externalInvoice;
  bool? needsInvoice;

  List<String> vehicleImages = [];
  Map<String, String?> additionalInfo = {};
  String? vehicleYear;
  String? vehicleMileage;
  String? vehicleTransmission;

  DateTime? dealerSelectedInspectionDate;
  String? dealerSelectedInspectionTime;
  String? dealerSelectedInspectionLocation;
  String? transporterDeliveryAddress;
  GeoPoint? latLng;

  String? dealerSelectedCollectionLocation;
  String? dealerSelectedCollectionAddress;
  DateTime? dealerSelectedCollectionDate;
  String? dealerSelectedCollectionTime;

  final List<dynamic>? inspectionDates;
  final List<dynamic>? inspectionLocations;
  final List<dynamic>? collectionDates;
  final List<dynamic>? collectionLocations;

  bool isVehicleDetailsLoading = false;

  String? proofOfPayment;

  Offer(
      {required this.offerId,
      required this.dealerId,
      required this.vehicleId,
      required this.transporterId,
      this.offerAmount,
      required this.offerStatus,
      this.description,
      this.vehicleMakeModel,
      this.vehicleMainImage,
      this.reason,
      this.createdAt,
      this.vehicleBrand,
      this.dealerSelectedInspectionDate,
      this.dealerSelectedInspectionTime,
      this.dealerSelectedInspectionLocation,
      this.transporterDeliveryAddress,
      this.latLng,
      this.dealerSelectedCollectionLocation,
      this.dealerSelectedCollectionAddress,
      this.dealerSelectedCollectionDate,
      this.dealerSelectedCollectionTime,
      this.inspectionDates,
      this.inspectionLocations,
      this.collectionDates,
      this.collectionLocations,
      this.proofOfPayment,
      this.vehicleYear,
      this.vehicleMileage,
      this.vehicleTransmission,
      this.externalInvoice,
      this.needsInvoice});

  /// IMPORTANT: Ensure these keys match your Firestore fields.
  factory Offer.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Offer(
      offerId: doc.id,
      dealerId: data['dealerId'] ?? '',
      vehicleId: data['vehicleId'] ?? '',
      transporterId: data['transporterId'] ?? '',
      offerAmount: data['offerAmount']?.toDouble(),
      offerStatus: data['offerStatus'] ?? 'pending',
      description: data['description'] ?? 'No Description',
      vehicleMakeModel: data['makeModel'],
      externalInvoice: data['externalInvoice'],
      vehicleMainImage: data['vehicleMainImage'],
      reason: data['reason'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      vehicleBrand: data['brands'],

      /// Add these mappings to pull fields from Firestore
      vehicleYear: data['vehicleYear'],
      vehicleMileage: data['vehicleMileage'],
      vehicleTransmission: data['vehicleTransmission'],

      dealerSelectedInspectionDate: data['dealerSelectedInspectionDate'] != null
          ? (data['dealerSelectedInspectionDate'] as Timestamp).toDate()
          : null,
      dealerSelectedInspectionTime: data['dealerSelectedInspectionTime'],
      dealerSelectedInspectionLocation:
          data['dealerSelectedInspectionLocation'],
      transporterDeliveryAddress: data['transporterDeliveryAddress'],
      latLng: data['latLng'] != null ? data['latLng'] as GeoPoint : null,
      dealerSelectedCollectionLocation:
          data['dealerSelectedCollectionLocation'],
      dealerSelectedCollectionAddress: data['dealerSelectedCollectionAddress'],
      dealerSelectedCollectionDate: data['dealerSelectedCollectionDate'] != null
          ? (data['dealerSelectedCollectionDate'] as Timestamp).toDate()
          : null,
      dealerSelectedCollectionTime: data['dealerSelectedCollectionTime'],
      inspectionDates: data['inspectionDates'],
      inspectionLocations: data['inspectionLocations'],
      collectionDates: data['collectionDates'],
      collectionLocations: data['collectionLocations'],
      proofOfPayment: data['proofOfPayment'],
      needsInvoice: data['needsInvoice'] is bool
          ? data['needsInvoice'] as bool
          : (data['needsInvoice'] == 'true' ? true : false),
    );
  }

  Future<void> fetchVehicleDetails() async {
    isVehicleDetailsLoading = true;
    notifyListeners();

    try {
      DocumentSnapshot vehicleSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      if (vehicleSnapshot.exists) {
        Map<String, dynamic> vehicleData =
            vehicleSnapshot.data() as Map<String, dynamic>;

        // Map the data from the vehicle document
        vehicleBrand = vehicleData['brands'] is List
            ? (vehicleData['brands'] as List).first.toString()
            : vehicleData['brands']?.toString();

        // Explicitly map the makeModel
        vehicleMakeModel = vehicleData['makeModel']?.toString();
        vehicleMainImage = vehicleData['mainImageUrl'];

        // If your 'vehicles' collection also has year/mileage/transmission fields:
        // vehicleYear = vehicleData['vehicleYear'];
        // vehicleMileage = vehicleData['vehicleMileage'];
        // vehicleTransmission = vehicleData['vehicleTransmission'];
      }
    } finally {
      isVehicleDetailsLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOfferAmount(double newAmount) async {
    try {
      offerAmount = newAmount;
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(offerId)
          .update({'offerAmount': newAmount});
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }
}

/// Extension to safely retrieve the first element that matches a condition or return null.
extension IterableExtensions<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (E element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

/// The OfferProvider manages the state and operations related to offers, including pagination.
class OfferProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Offer> _offers = [];
  bool _isFetching = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final int _limit = 10; // Number of offers to fetch per page
  final String _currentUserId = '';
  final String _currentUserRole = '';
  String? _errorMessage; // Optional: Track error messages

  List<Offer> get offers => _offers;
  bool get isFetching => _isFetching;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  /// Fetches the initial batch of offers based on user ID and role.
  Future<void> fetchOffers(String userId, String userRole) async {
    if (_isFetching) return;

    _isFetching = true;
    notifyListeners();

    try {
      Query query = _buildQuery(userId, userRole);

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        _offers = querySnapshot.docs.map((doc) {
          return Offer.fromFirestore(doc);
        }).toList();

        // Fetch vehicle details for each offer
        for (Offer offer in _offers) {
          await offer.fetchVehicleDetails();
        }
      } else {
        // If no docs, you could set _hasMore = false;
      }
    } catch (e) {
      _errorMessage = 'Failed to load offers. Please try again.';
    }

    _isFetching = false;
    notifyListeners();
  }

  /// Fetches the next batch of offers for pagination.
  Future<void> fetchMoreOffers() async {
    if (_isFetching || !_hasMore) return;

    _isFetching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Query query = _buildQuery(_currentUserId, _currentUserRole)
          .startAfterDocument(_lastDocument!)
          .limit(_limit);

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        List<Offer> newOffers =
            querySnapshot.docs.map((doc) => Offer.fromFirestore(doc)).toList();

        // Fetch vehicle details for each new offer
        for (Offer offer in newOffers) {
          await offer.fetchVehicleDetails();
        }

        _offers.addAll(newOffers);

        if (querySnapshot.docs.length < _limit) {
          _hasMore = false;
        }
      } else {
        _hasMore = false;
      }
    } catch (e) {
      _errorMessage = 'Failed to load more offers. Please try again.';
    }

    _isFetching = false;
    notifyListeners();
  }

  /// Refreshes the offers by clearing existing ones and fetching the initial batch again.
  Future<void> refreshOffers() async {
    _offers.clear();
    _lastDocument = null;
    _hasMore = true;
    await fetchOffers(_currentUserId, _currentUserRole);
  }

  /// Builds the Firestore query based on user role.
  Query _buildQuery(String userId, String userRole) {
    var query = _firestore.collection('offers');

    // Admin sees all offers
    if (userRole == 'admin') {
      return query.orderBy('createdAt', descending: true).limit(_limit);
    }

    // For dealers or transporters, filter by their respective IDs
    return query
        .where(userRole == 'dealer' ? 'dealerId' : 'transporterId',
            isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(_limit);
  }

  /// Updates the status of an offer.
  Future<void> updateOfferStatus(String offerId, String newStatus) async {
    try {
      await _firestore
          .collection('offers')
          .doc(offerId)
          .update({'offerStatus': newStatus});

      // Update local state
      Offer? offer = getOfferById(offerId);
      if (offer != null) {
        offer.offerStatus = newStatus;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update offer status. Please try again.';
      notifyListeners();
    }
  }

  /// Deletes an offer from Firestore and updates the local list.
  Future<void> deleteOffer(String offerId) async {
    try {
      await _firestore.collection('offers').doc(offerId).delete();

      // Update local state
      _offers.removeWhere((offer) => offer.offerId == offerId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to delete offer. Please try again.';
      notifyListeners();
    }
  }

  /// Retrieves an offer by its ID using the `firstWhereOrNull` extension.
  Offer? getOfferById(String offerId) {
    return _offers.firstWhereOrNull((offer) => offer.offerId == offerId);
  }

  /// Fetches a specific offer by its ID.
  Future<void> fetchOfferById(String offerId) async {
    try {
      DocumentSnapshot offerSnapshot =
          await _firestore.collection('offers').doc(offerId).get();

      if (offerSnapshot.exists) {
        Offer offer = Offer.fromFirestore(offerSnapshot);
        await offer.fetchVehicleDetails();
        _offers.add(offer);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch offer details. Please try again.';
      notifyListeners();
    }
  }

  /// Updates the offer amount for a specific offer.
  Future<void> updateOfferAmount(String offerId, double newAmount) async {
    try {
      Offer? offer = getOfferById(offerId);
      if (offer != null) {
        await offer.updateOfferAmount(newAmount);
        notifyListeners();
      } else {
        _errorMessage = 'Offer not found.';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update offer amount. Please try again.';
      notifyListeners();
    }
  }

  /// Fetches offers related to a specific vehicle.
  Future<List<Offer>> fetchOffersForVehicle(String vehicleId) async {
    try {
      QuerySnapshot offersSnapshot = await _firestore
          .collection('offers')
          .where('vehicleId', isEqualTo: vehicleId)
          .get();

      List<Offer> vehicleOffers =
          offersSnapshot.docs.map((doc) => Offer.fromFirestore(doc)).toList();

      // Fetch related vehicle details for each offer
      for (Offer offer in vehicleOffers) {
        await offer.fetchVehicleDetails();
      }

      return vehicleOffers;
    } catch (e) {
      _errorMessage = 'Failed to fetch offers for vehicle. Please try again.';
      notifyListeners();
      return [];
    }
  }
}
