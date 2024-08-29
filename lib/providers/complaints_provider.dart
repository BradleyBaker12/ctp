import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintsProvider with ChangeNotifier {
  List<Map<String, dynamic>> _complaints = [];

  List<Map<String, dynamic>> get complaints => _complaints;

  Future<void> fetchComplaints(String offerId) async {
    try {
      QuerySnapshot complaintSnapshot = await FirebaseFirestore.instance
          .collection('complaints')
          .where('offerId', isEqualTo: offerId)
          .get();

      _complaints = complaintSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching complaints: $e');
      print('${_complaints}');
    }
  }

  Map<String, dynamic> getResolvedComplaint(String offerId) {
    return _complaints.firstWhere(
      (complaint) =>
          complaint['offerId'] == offerId &&
          complaint['complaintStatus'] == 'resolved',
      orElse: () => {},
    );
  }
}
