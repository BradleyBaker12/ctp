// lib/models/user_details.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetails {
  final String name;
  final String email;
  final String phone;

  UserDetails({
    required this.name,
    required this.email,
    required this.phone,
  });

  factory UserDetails.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserDetails(
      name: data['firstName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phoneNumber'] ?? '',
    );
  }
}
