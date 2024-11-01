// lib/utils/timestamp_helper.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Parses a dynamic timestamp from Firestore and returns a DateTime object.
/// If parsing fails, returns the current DateTime and logs a warning.
DateTime parseTimestamp(dynamic timestamp, String vehicleId) {
  if (timestamp is Timestamp) {
    return timestamp.toDate();
  } else if (timestamp is String) {
    return DateTime.tryParse(timestamp) ?? DateTime.now();
  } else {
    print(
        'Warning: Timestamp is null or invalid for vehicle ID $vehicleId. Using DateTime.now() as default.');
    return DateTime.now();
  }
}
