// lib/models/maintenance.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/timestamp_helper.dart';
import 'maintenance_data.dart';

class Maintenance {
  final String maintenanceDocumentUrl;
  final String warrantyDocumentUrl;
  final String oemInspectionType;
  final String oemInspectionReason;
  final String warrantySelection;
  final DateTime updatedAt;
  final MaintenanceData maintenanceData;

  Maintenance({
    required this.maintenanceDocumentUrl,
    required this.warrantyDocumentUrl,
    required this.oemInspectionType,
    required this.oemInspectionReason,
    required this.warrantySelection,
    required this.updatedAt,
    required this.maintenanceData,
  });

  factory Maintenance.fromMap(Map<String, dynamic> data) {
    return Maintenance(
      maintenanceDocumentUrl: data['maintenanceDocUrl'] ?? '',
      warrantyDocumentUrl: data['warrantyDocUrl'] ?? '',
      oemInspectionType: data['oemInspectionType'] ?? '',
      oemInspectionReason: data['oemReason'] ?? '',
      warrantySelection: data['warrantySelection'] ?? '',
      updatedAt: parseTimestamp(data['lastUpdated'], ''),
      maintenanceData: MaintenanceData.fromMap(data['maintenanceData'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maintenanceDocUrl': maintenanceDocumentUrl,
      'warrantyDocUrl': warrantyDocumentUrl,
      'oemInspectionType': oemInspectionType,
      'oemReason': oemInspectionReason,
      'warrantySelection': warrantySelection,
      'lastUpdated': Timestamp.fromDate(updatedAt),
      'maintenanceData': maintenanceData.toMap(),
    };
  }

  factory Maintenance.empty() {
    return Maintenance(
      maintenanceData:
          MaintenanceData(vehicleId: '', oemInspectionType: '', oemReason: ''),
      maintenanceDocumentUrl: '',
      warrantyDocumentUrl: '',
      oemInspectionType: '',
      oemInspectionReason: '',
      warrantySelection: '',
      updatedAt: DateTime.timestamp(),
    );
  }
}
