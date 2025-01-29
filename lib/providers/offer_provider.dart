// lib/models/offer.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Added for the widget

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

  String? proofOfPaymentUrl;

  Offer({
    required this.offerId,
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
    this.proofOfPaymentUrl,
    this.vehicleYear,
    this.vehicleMileage,
    this.vehicleTransmission,
    this.externalInvoice,
    this.needsInvoice,
  });

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
      vehicleBrand: data['brands'] is List
          ? (data['brands'] as List).first.toString()
          : data['brands']?.toString(),

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
      proofOfPaymentUrl: data['proofOfPaymentUrl'],
      needsInvoice: data['needsInvoice'] is bool
          ? data['needsInvoice'] as bool
          : (data['needsInvoice'] == 'true' ? true : false),
    );
  }

  Future<void> fetchVehicleDetails() async {
    if (isVehicleDetailsLoading) return;

    isVehicleDetailsLoading = true;
    notifyListeners();

    try {
      final vehicleDoc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      if (vehicleDoc.exists) {
        Map<String, dynamic> data = vehicleDoc.data() as Map<String, dynamic>;

        // Update to use mainImageUrl field instead of mainImage
        vehicleMakeModel = data['makeModel'] as String?;
        vehicleMainImage =
            data['mainImageUrl'] as String?; // Changed from mainImage
        vehicleImages =
            List<String>.from(data['photos'] ?? []); // Changed from images

        // Additional details
        vehicleYear = data['vehicleYear']?.toString();
        vehicleMileage = data['vehicleMileage']?.toString();
        vehicleTransmission = data['vehicleTransmission']?.toString();
      } else {
        print('ERROR: Vehicle document not found for ID: $vehicleId');
      }
    } catch (e, stackTrace) {
      print('ERROR: Failed to fetch vehicle details: $e');
      print('ERROR: Stack trace: $stackTrace');
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
      print('ERROR: Failed to update offer amount: $e');
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
class OfferProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Offer> _offers = [];
  bool _isFetching = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final int _limit = 10; // Number of offers to fetch per page
  String? _currentUserId;
  String? _currentUserRole;
  String? _errorMessage; // Optional: Track error messages

  final _offersController = StreamController<List<Offer>>.broadcast();
  Stream<List<Offer>> get offersStream => _offersController.stream;

  List<Offer> get offers => _offers;
  bool get isFetching => _isFetching;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  bool _isInitialized = false;

  /// Initialize with user data
  void initialize(String userId, String userRole) {
    print('DEBUG: Initializing OfferProvider');
    _currentUserId = userId;
    _currentUserRole = userRole;
    _isInitialized = true;
    print(
        'DEBUG: Initialized with userId: $_currentUserId, role: $_currentUserRole');
    notifyListeners();
  }

  /// Fetches the initial batch of offers based on user ID and role.
  Future<void> fetchOffers(String userId, String userRole) async {
    print('DEBUG: Starting fetchOffers');
    if (_isFetching) return;

    try {
      _isFetching = true;
      _errorMessage = null;
      notifyListeners();

      Query query = _buildQuery(userId, userRole).limit(_limit);
      QuerySnapshot querySnapshot = await query.get();

      _offers = await Future.wait(querySnapshot.docs.map((doc) async {
        print('DEBUG: Processing offer ${doc.id}');
        Offer offer = Offer.fromFirestore(doc);
        await offer.fetchVehicleDetails();
        print(
            'DEBUG: Vehicle details fetched - mainImage: ${offer.vehicleMainImage}');
        return offer;
      }));

      if (_offers.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        _hasMore = querySnapshot.docs.length >= _limit;
      } else {
        _hasMore = false;
      }

      _offersController.add(_offers);
    } catch (e) {
      print('ERROR: Failed to fetch offers: $e');
      _errorMessage = 'Failed to load offers: $e';
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  /// Fetches the next batch of offers for pagination.
  Future<void> fetchMoreOffers() async {
    if (_isFetching || !_hasMore) return;

    _isFetching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Query query = _buildQuery(_currentUserId!, _currentUserRole!)
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

      _offersController.add(_offers);
    } catch (e) {
      print('ERROR: Failed to fetch more offers: $e');
      _errorMessage = 'Failed to load more offers. Please try again.';
    }

    _isFetching = false;
    notifyListeners();
  }

  /// Refreshes the offers by clearing existing ones and fetching the initial batch again.
  Future<void> refreshOffers() async {
    print('DEBUG: Starting refreshOffers');
    if (!_isInitialized) {
      print('ERROR: Provider not initialized');
      _errorMessage = 'Provider not initialized.';
      notifyListeners();
      return;
    }

    _offers.clear();
    _hasMore = true;
    _lastDocument = null;
    _errorMessage = null;

    await fetchOffers(_currentUserId!, _currentUserRole!);
    print('DEBUG: Refresh completed, offers count: ${_offers.length}');
  }

  /// Builds the Firestore query based on user role.
  Query _buildQuery(String userId, String userRole) {
    print('DEBUG: Building query for userId: $userId, role: $userRole');
    Query query = _firestore.collection('offers');

    if (userRole != 'admin') {
      if (userRole == 'dealer') {
        query = query.where('dealerId', isEqualTo: userId);
      } else if (userRole == 'transporter') {
        query = query.where('transporterId', isEqualTo: userId);
      }
    }

    query = query.orderBy('createdAt', descending: true);
    print('DEBUG: Final query path: ${query.parameters}');
    return query;
  }

  /// Updates the status of an offer.
  Future<void> updateOfferStatus(String offerId, String newStatus) async {
    try {
      await _firestore
          .collection('offers')
          .doc(offerId)
          .update({'paymentStatus': newStatus});
      // await _firestore
      //     .collection('offers')
      //     .doc(offerId)
      //     .update({'offerStatus': newStatus});

      // Update local state
      Offer? offer = getOfferById(offerId);
      if (offer != null) {
        offer.offerStatus = newStatus;
        notifyListeners();
      }
    } catch (e) {
      print('ERROR: Failed to update offer status: $e');
      _errorMessage = 'Failed to update offer status. Please try again.';
      notifyListeners();
    }
  }

  /// Deletes an offer from Firestore and updates the local list.
  Future<void> deleteOffer(String offerId) async {
    try {
      // Instead of deleting the document, update its offerStatus to "Archived".
      await _firestore
          .collection('offers')
          .doc(offerId)
          .update({'offerStatus': 'Archived'});

      // Update local state
      _offers.removeWhere((offer) => offer.offerId == offerId);
      _offersController.add(_offers);
      notifyListeners();
    } catch (e) {
      print('ERROR: Failed to delete offer: $e');
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
        _offersController.add(_offers);
        notifyListeners();
      }
    } catch (e) {
      print('ERROR: Failed to fetch offer details: $e');
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
        _offersController.add(_offers);
        notifyListeners();
      } else {
        print('ERROR: Offer not found for ID: $offerId');
        _errorMessage = 'Offer not found.';
        notifyListeners();
      }
    } catch (e) {
      print('ERROR: Failed to update offer amount: $e');
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
      print('ERROR: Failed to fetch offers for vehicle: $e');
      _errorMessage = 'Failed to fetch offers for vehicle. Please try again.';
      notifyListeners();
      return [];
    }
  }

  Future<void> acceptOffer(String offerId, String vehicleId) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Get all offers for this vehicle
        final offersQuery = await FirebaseFirestore.instance
            .collection('offers')
            .where('vehicleId', isEqualTo: vehicleId)
            .get();

        // Update the accepted offer
        await transaction.update(
            FirebaseFirestore.instance.collection('offers').doc(offerId),
            {'offerStatus': 'accepted'});

        // Update vehicle status
        await transaction.update(
            FirebaseFirestore.instance.collection('vehicles').doc(vehicleId), {
          'isAccepted': true,
          'acceptedOfferId': offerId,
        });

        // Update all other offers for this vehicle to rejected
        for (var doc in offersQuery.docs) {
          if (doc.id != offerId) {
            await transaction.update(
                FirebaseFirestore.instance.collection('offers').doc(doc.id),
                {'offerStatus': 'rejected'});
          }
        }
      });

      // Refresh offers list after successful update
      notifyListeners();
    } catch (e) {
      print('Error accepting offer: $e');
      rethrow; // Allow UI to handle the error
    }
  }

  @override
  void dispose() {
    _offersController.close();
    super.dispose();
  }
}

/// Widget to build the offer image with loading indicator and error handling.
Widget _buildOfferImage(Offer offer) {
  if (offer.isVehicleDetailsLoading) {
    return CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4E00)),
    );
  }

  return offer.vehicleMainImage != null
      ? Image.network(
          offer.vehicleMainImage!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('DEBUG: Error loading image: $error');
            return Icon(Icons.directions_car, color: Colors.blueAccent);
          },
        )
      : Icon(Icons.directions_car, color: Colors.blueAccent);
}
