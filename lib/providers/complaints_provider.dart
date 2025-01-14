// lib/providers/complaints_provider.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Complaint Model
class Complaint {
  final String complaintId; // Unique identifier for the complaint
  String complaintStatus;
  final String description;
  final String offerId;
  final String previousStep;
  final String selectedIssue;
  final Timestamp timestamp;
  final String userId;

  Complaint({
    required this.complaintId,
    required this.complaintStatus,
    required this.description,
    required this.offerId,
    required this.previousStep,
    required this.selectedIssue,
    required this.timestamp,
    required this.userId,
  });

  // Factory method to create a Complaint from Firestore data
  factory Complaint.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Complaint(
      complaintId: doc.id, // Use document ID as complaintId
      complaintStatus: data['complaintStatus'] ?? '',
      description: data['description'] ?? '',
      offerId: data['offerId'] ?? '',
      previousStep: data['previousStep'] ?? '',
      selectedIssue: data['selectedIssue'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      userId: data['userId'] ?? '',
    );
  }

  // Method to convert a Complaint into a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'complaintStatus': complaintStatus,
      'description': description,
      'offerId': offerId,
      'previousStep': previousStep,
      'selectedIssue': selectedIssue,
      'timestamp': timestamp,
      'userId': userId,
    };
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

/// The ComplaintsProvider manages the state and operations related to complaints, including pagination.
class ComplaintsProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Complaint> _complaints = [];
  bool _isFetching = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final int _limit = 10; // Number of complaints to fetch per page
  String? _errorMessage; // Optional: Track error messages

  List<Complaint> get complaints => _complaints;
  bool get isFetching => _isFetching;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  /// Fetches complaints based on offerId with pagination.
  Future<void> fetchComplaints(String offerId) async {
    if (_isFetching) return;

    _isFetching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Query query = _firestore
          .collection('complaints')
          .where('offerId', isEqualTo: offerId)
          .orderBy('timestamp', descending: true)
          .limit(_limit);

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        List<Complaint> fetchedComplaints = querySnapshot.docs
            .map((doc) => Complaint.fromFirestore(doc))
            .toList();
        _complaints = fetchedComplaints;

        if (querySnapshot.docs.length < _limit) {
          _hasMore = false;
        }
      } else {
        _hasMore = false;
      }
    } catch (e) {
      print('Error fetching complaints: $e');
      _errorMessage = 'Failed to load complaints. Please try again.';
    }

    _isFetching = false;
    notifyListeners();
  }

  /// Fetches a resolved complaint (returns null if none found)
  Complaint? getResolvedComplaint(String offerId) {
    return _complaints.firstWhereOrNull((complaint) =>
        complaint.offerId == offerId &&
        complaint.complaintStatus.toLowerCase() == 'resolved');
  }

  /// Fetches all complaints with pagination.
  Future<void> fetchAllComplaints() async {
    if (_isFetching) return;

    _isFetching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Query query = _firestore
          .collection('complaints')
          .orderBy('timestamp', descending: true)
          .limit(_limit);

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        _complaints = querySnapshot.docs
            .map((doc) => Complaint.fromFirestore(doc))
            .toList();

        if (querySnapshot.docs.length < _limit) {
          _hasMore = false;
        }
      } else {
        _hasMore = false;
      }
    } catch (e) {
      print('Error fetching all complaints: $e');
      _errorMessage = 'Failed to load complaints. Please try again.';
    }

    _isFetching = false;
    notifyListeners();
  }

  /// Fetches the next batch of complaints for pagination.
  Future<void> fetchMoreComplaints() async {
    if (_isFetching || !_hasMore) return;

    _isFetching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Query query = _firestore
          .collection('complaints')
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_limit);

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        List<Complaint> newComplaints = querySnapshot.docs
            .map((doc) => Complaint.fromFirestore(doc))
            .toList();

        _complaints.addAll(newComplaints);

        if (querySnapshot.docs.length < _limit) {
          _hasMore = false;
        }
      } else {
        _hasMore = false;
      }
    } catch (e) {
      print('Error fetching more complaints: $e');
      _errorMessage = 'Failed to load more complaints. Please try again.';
    }

    _isFetching = false;
    notifyListeners();
  }

  /// Refreshes the complaints by clearing existing ones and fetching the initial batch again.
  Future<void> refreshComplaints() async {
    _complaints.clear();
    _lastDocument = null;
    _hasMore = true;
    await fetchAllComplaints();
  }

  /// Update complaint status
  Future<bool> updateComplaintStatus(
      String complaintId, String newStatus) async {
    var complaint =
        _complaints.firstWhereOrNull((c) => c.complaintId == complaintId);
    var previousStatus = complaint?.complaintStatus;

    try {
      //Optimistically update the local state
      optimisticallyUpdateComplaint(complaintId, newStatus);

      await _firestore
          .collection('complaints')
          .doc(complaintId)
          .update({'complaintStatus': newStatus});
      return true;
    } catch (e) {
      print('Error updating complaint status: $e');
      return false;
    }
  }

  void optimisticallyUpdateComplaint(String complaintId, String newStatus) {
    int index = _complaints.indexWhere((c) => c.complaintId == complaintId);
    if (index != -1) {
      _complaints[index].complaintStatus = newStatus;
      notifyListeners();
    }
  }

  void rollbackComplaintStatus(String complaintId, String previousStatus) {
    int index = _complaints.indexWhere((c) => c.complaintId == complaintId);
    if (index != -1) {
      _complaints[index].complaintStatus = previousStatus;
      notifyListeners();
    }
  }
}
