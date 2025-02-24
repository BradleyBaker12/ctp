// lib/models/maintenance.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Maintenance {
  final String vehicleId;
  final String? oemInspectionType;
  final String? oemReason;
  final String? maintenanceDocUrl;
  final String? warrantyDocUrl;
  final String? maintenanceSelection;
  final String? warrantySelection;
  final DateTime? lastUpdated;

  Maintenance({
    required this.vehicleId,
    this.oemInspectionType,
    this.oemReason,
    this.maintenanceDocUrl,
    this.warrantyDocUrl,
    this.maintenanceSelection,
    this.warrantySelection,
    this.lastUpdated,
  });

  factory Maintenance.fromMap(Map<String, dynamic> data) {
    // print('=== MAINTENANCE MODEL DEBUG ===');
    // print('Raw maintenance data received: $data');

    // Ensure string conversion for potentially non-string values
    String ensureString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

    return Maintenance(
      vehicleId: ensureString(data['vehicleId']),
      oemInspectionType: ensureString(data['oemInspectionType']),
      oemReason: ensureString(data['oemReason']),
      maintenanceDocUrl: ensureString(data['maintenanceDocUrl']),
      warrantyDocUrl: ensureString(data['warrantyDocUrl']),
      maintenanceSelection: ensureString(data['maintenanceSelection']),
      warrantySelection: ensureString(data['warrantySelection']),
      lastUpdated: data['lastUpdated']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'oemInspectionType': oemInspectionType ?? '',
      'oemReason': oemReason ?? '',
      'maintenanceDocUrl': maintenanceDocUrl ?? '',
      'warrantyDocUrl': warrantyDocUrl ?? '',
      'maintenanceSelection': maintenanceSelection ?? '',
      'warrantySelection': warrantySelection ?? '',
      'lastUpdated':
          lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }

  factory Maintenance.empty() {
    return Maintenance(
      vehicleId: '',
      oemInspectionType: '',
      oemReason: '',
      maintenanceDocUrl: '',
      warrantyDocUrl: '',
      maintenanceSelection: '',
      warrantySelection: '',
      lastUpdated: DateTime.now(),
    );
  }
}
