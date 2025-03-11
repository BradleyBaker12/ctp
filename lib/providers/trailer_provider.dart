import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trailer.dart';

class TrailerProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Trailer> _trailers = [];
  Trailer? _trailer;

  List<Trailer> get trailers => _trailers;
  Trailer? get trailer => _trailer;

  // Fetch all trailers
  Future<void> fetchTrailers() async {
    try {
      final snapshot = await _firestore
          .collection('vehicles')
          .where('vehicleType', isEqualTo: 'trailer')
          .get();
      _trailers = snapshot.docs.map((doc) {
        final data = doc.data();
        debugPrint('Parsing trailer doc ${doc.id}: $data');
        return Trailer.fromFirestore(doc.id, data);
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching trailers: $e');
      rethrow;
    }
  }

  // Add new trailer
  Future<void> addTrailer(Trailer trailer) async {
    try {
      await _firestore
          .collection('vehicles') // Changed from 'trailers'
          .doc(trailer.id)
          .set(trailer.toMap());
      _trailers.add(trailer);
      notifyListeners();
    } catch (e) {
      print('Error adding trailer: $e');
      rethrow;
    }
  }

  // Update existing trailer
  Future<void> updateTrailer(Trailer trailer) async {
    try {
      await _firestore
          .collection('vehicles') // Changed from 'trailers'
          .doc(trailer.id)
          .update(trailer.toMap());
      final index = _trailers.indexWhere((t) => t.id == trailer.id);
      if (index != -1) {
        _trailers[index] = trailer;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating trailer: $e');
      rethrow;
    }
  }

  // Delete trailer
  Future<void> deleteTrailer(String trailerId) async {
    try {
      await _firestore
          .collection('vehicles')
          .doc(trailerId)
          .delete(); // Changed from 'trailers'
      _trailers.removeWhere((trailer) => trailer.id == trailerId);
      notifyListeners();
    } catch (e) {
      print('Error deleting trailer: $e');
      rethrow;
    }
  }

  // Get trailer by ID
  Trailer? getTrailerById(String id) {
    try {
      return _trailers.firstWhere((trailer) => trailer.id == id);
    } catch (e) {
      return null;
    }
  }

  // NEW: Fetch trailer data by id from Firestore
  Future<void> fetchTrailerById(String trailerId) async {
    debugPrint('Fetching trailer by id: $trailerId');
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(trailerId)
          .get();
      if (doc.exists) {
        debugPrint('Document data for trailer $trailerId: ${doc.data()}');
        _trailer =
            Trailer.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
        debugPrint('Parsed trailer: ${_trailer?.toMap()}');
        notifyListeners();
      } else {
        debugPrint('No document found for trailer id: $trailerId');
        _trailer = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching trailer: $e');
      _trailer = null;
      notifyListeners();
    }
  }

  // Filter trailers by status
  List<Trailer> getTrailersByStatus(String status) {
    return _trailers
        .where((trailer) => trailer.vehicleStatus == status)
        .toList();
  }

  // Filter trailers by assigned sales rep
  List<Trailer> getTrailersBySalesRep(String salesRepId) {
    return _trailers
        .where((trailer) => trailer.assignedSalesRepId == salesRepId)
        .toList();
  }

  // Search trailers by make/model
  List<Trailer> searchTrailers(String query) {
    return _trailers
        .where((trailer) =>
            trailer.makeModel.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Get trailers by type
  List<Trailer> getTrailersByType(String trailerType) {
    return _trailers
        .where((trailer) => trailer.trailerType == trailerType)
        .toList();
  }

  // Get Superlink trailers
  List<Trailer> get superlinkTrailers => getTrailersByType('Superlink');

  // Get Tri-Axle trailers
  List<Trailer> get triAxleTrailers => getTrailersByType('Tri-Axle');

  // Get Double Axle trailers
  List<Trailer> get doubleAxleTrailers => getTrailersByType('Double Axle');

  // Get Other trailers
  List<Trailer> get otherTrailers => getTrailersByType('Other');

  // Add Superlink trailer
  Future<void> addSuperlinkTrailer(Trailer trailer) async {
    if (trailer.trailerType != 'Superlink') {
      throw ArgumentError('Invalid trailer type');
    }
    await addTrailer(trailer);
  }

  // Add Tri-Axle trailer
  Future<void> addTriAxleTrailer(Trailer trailer) async {
    if (trailer.trailerType != 'Tri-Axle') {
      throw ArgumentError('Invalid trailer type');
    }
    await addTrailer(trailer);
  }

  // Update Superlink trailer
  Future<void> updateSuperlinkTrailer(Trailer trailer) async {
    if (trailer.trailerType != 'Superlink') {
      throw ArgumentError('Invalid trailer type');
    }
    await updateTrailer(trailer);
  }

  // Update Tri-Axle trailer
  Future<void> updateTriAxleTrailer(Trailer trailer) async {
    if (trailer.trailerType != 'Tri-Axle') {
      throw ArgumentError('Invalid trailer type');
    }
    await updateTrailer(trailer);
  }

  // Validate trailer data based on type
  bool validateTrailerData(Trailer trailer) {
    switch (trailer.trailerType) {
      case 'Superlink':
        return _validateSuperlinkData(trailer);
      case 'Tri-Axle':
        return _validateTriAxleData(trailer);
      case 'Double Axle':
      case 'Other':
        return false; // These types are not implemented yet
      default:
        return false;
    }
  }

  bool _validateSuperlinkData(Trailer trailer) {
    final info = trailer.superlinkData; // Changed from superLinkInfo
    if (info == null) return false;

    return info.lengthA.isNotEmpty &&
        info.vinA.isNotEmpty &&
        info.registrationA.isNotEmpty &&
        info.lengthB.isNotEmpty &&
        info.vinB.isNotEmpty &&
        info.registrationB.isNotEmpty;
  }

  bool _validateTriAxleData(Trailer trailer) {
    final info = trailer.triAxleData; // Changed from triAxleInfo
    if (info == null) return false;

    return info.length.isNotEmpty &&
        info.vin.isNotEmpty &&
        info.registration.isNotEmpty;
  }
}
