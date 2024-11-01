// lib/models/offer.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// The Offer model representing each offer from Firestore.
class Offer extends ChangeNotifier {
  final String offerId;
  final String dealerId;
  final String vehicleId;
  final String transportId;
  double? offerAmount; // This can now be modified
  String offerStatus; // Made mutable to update locally
  String? description; // Added description field
  String? vehicleMakeModel;
  String? vehicleMainImage;
  String? reason;
  DateTime? createdAt; // Include in constructor

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

  // Loading state
  bool isVehicleDetailsLoading = false;

  Offer({
    required this.offerId,
    required this.dealerId,
    required this.vehicleId,
    required this.transportId,
    this.offerAmount,
    required this.offerStatus,
    this.description, // Initialize description
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

  /// Factory constructor to create an Offer instance from Firestore DocumentSnapshot.
  factory Offer.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Offer(
      offerId: doc.id, // Use document ID as offerId
      dealerId: data['dealerId'] ?? '',
      vehicleId: data['vehicleId'] ?? '',
      transportId: data['transportId'] ?? '',
      offerAmount: data['offerAmount']?.toDouble(),
      offerStatus:
          data['offerStatus'] ?? 'pending', // Updated to match Firestore field
      description:
          data['description'] ?? 'No Description', // Initialize description
      vehicleMakeModel: data['vehicleMakeModel'],
      vehicleMainImage: data['vehicleMainImage'],
      reason: data['reason'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null, // Handle null case
      dealerSelectedInspectionDate: data['dealerSelectedInspectionDate'] != null
          ? (data['dealerSelectedInspectionDate'] as Timestamp).toDate()
          : null,
      dealerSelectedInspectionTime: data['dealerSelectedInspectionTime'],
      dealerSelectedInspectionLocation:
          data['dealerSelectedInspectionLocation'],
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
    );
  }

  /// Fetches related vehicle details from Firestore.
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
      } else {
        vehicleMakeModel = 'Unknown';
        vehicleMainImage = null;
        print('No vehicle details found for $vehicleId');
      }
    } catch (e) {
      print('Error fetching vehicle details: $e');
    } finally {
      isVehicleDetailsLoading = false;
      notifyListeners();
    }
  }

  /// Updates the offer amount both locally and in Firestore.
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
  String _currentUserId = '';
  String _currentUserRole = '';
  String? _errorMessage; // Optional: Track error messages

  List<Offer> get offers => _offers;
  bool get isFetching => _isFetching;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  /// Fetches the initial batch of offers based on user ID and role.
  Future<void> fetchOffers(String userId, String userRole) async {
    if (_isFetching) return;

    _currentUserId = userId;
    _currentUserRole = userRole;

    _isFetching = true;
    _errorMessage = null;
    Future.microtask(() {
      notifyListeners();
    });

    try {
      Query query = _buildQuery(userId, userRole);

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        _offers =
            querySnapshot.docs.map((doc) => Offer.fromFirestore(doc)).toList();

        // Fetch related vehicle details for each offer
        for (Offer offer in _offers) {
          await offer.fetchVehicleDetails();
        }

        if (querySnapshot.docs.length < _limit) {
          _hasMore = false;
        }
      } else {
        _hasMore = false;
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching offers: $e');
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

        // Fetch related vehicle details for each new offer
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
      print('Error fetching more offers: $e');
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
    Query query = _firestore
        .collection('offers')
        .orderBy('createdAt', descending: true)
        .limit(_limit);

    if (userRole == 'dealer') {
      query = query.where('dealerId', isEqualTo: userId);
    } else if (userRole == 'transporter') {
      query = query.where('transportId', isEqualTo: userId);
    } else if (userRole == 'admin') {
      // Admin can fetch all offers, already handled by the base query
    } else {
      // Handle other roles or throw an error
      print('Unsupported user role: $userRole');
    }

    return query;
  }

  /// Updates the status of an offer (e.g., Approve, Reject).
  Future<void> updateOfferStatus(String offerId, String newStatus) async {
    try {
      await _firestore
          .collection('offers')
          .doc(offerId)
          .update({'status': newStatus});
      print('Offer $offerId status updated to $newStatus');

      // Update local state
      Offer? offer = getOfferById(offerId);
      if (offer != null) {
        offer.offerStatus = newStatus;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating offer status: $e');
      _errorMessage = 'Failed to update offer status. Please try again.';
      notifyListeners();
    }
  }

  /// Deletes an offer from Firestore and updates the local list.
  Future<void> deleteOffer(String offerId) async {
    try {
      await _firestore.collection('offers').doc(offerId).delete();
      print('Offer $offerId deleted');

      // Update local state
      _offers.removeWhere((offer) => offer.offerId == offerId);
      notifyListeners();
    } catch (e) {
      print('Error deleting offer: $e');
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
      } else {
        print('No offer found with ID $offerId');
      }
    } catch (e) {
      print('Error fetching offer: $e');
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
        notifyListeners(); // Notify listeners after updating
      } else {
        print('Offer not found for update');
        _errorMessage = 'Offer not found.';
        notifyListeners();
      }
    } catch (e) {
      print('Error updating offer amount: $e');
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
      print('Error fetching offers for vehicle: $e');
      _errorMessage = 'Failed to fetch offers for vehicle. Please try again.';
      notifyListeners();
      return [];
    }
  }
}
