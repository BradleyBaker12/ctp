import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class VehicleFormService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> saveVehicleForm(Map<String, dynamic> formData) async {
    try {
      // Add user ID to form data
      formData['userId'] = _auth.currentUser?.uid;

      // Add to Firestore and get the document reference
      final docRef = await _firestore.collection('vehicles').add(formData);

      return docRef.id; // Return the vehicle ID
    } catch (e) {
      print('Error saving vehicle form: $e');
      throw 'Failed to save vehicle form';
    }
  }

  Future<String> uploadFile(File file, String folder) async {
    try {
      final fileName =
          '$folder/${DateTime.now().millisecondsSinceEpoch}_${_auth.currentUser?.uid}';
      final ref = _storage.ref().child(fileName);

      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      throw 'Failed to upload file';
    }
  }
}
