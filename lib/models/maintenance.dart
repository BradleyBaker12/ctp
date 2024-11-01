// lib/models/maintenance.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/timestamp_helper.dart';
import 'maintenance_data.dart';

class Maintenance {
  final String maintenanceDocumentUrl;
  final String warrantyDocumentUrl;
  final String oemInspectionType;
  final String oemInspectionReason;
  final DateTime updatedAt;
  final MaintenanceData maintenanceData;

  Maintenance({
    required this.maintenanceDocumentUrl,
    required this.warrantyDocumentUrl,
    required this.oemInspectionType,
    required this.oemInspectionReason,
    required this.updatedAt,
    required this.maintenanceData,
  });

  factory Maintenance.fromMap(Map<String, dynamic> data) {
    return Maintenance(
      maintenanceDocumentUrl: data['maintenanceDocumentUrl'] ?? '',
      warrantyDocumentUrl: data['warrantyDocumentUrl'] ?? '',
      oemInspectionType: data['oemInspectionType'] ?? '',
      oemInspectionReason: data['oemInspectionReason'] ?? '',
      updatedAt: parseTimestamp(data['updatedAt'], ''),
      maintenanceData: MaintenanceData.fromMap(data['maintenanceData'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maintenanceDocumentUrl': maintenanceDocumentUrl,
      'warrantyDocumentUrl': warrantyDocumentUrl,
      'oemInspectionType': oemInspectionType,
      'oemInspectionReason': oemInspectionReason,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'maintenanceData': maintenanceData.toMap(),
    };
  }
}
