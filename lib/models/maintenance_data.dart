// lib/models/maintenance_data.dart

class MaintenanceData {
  final String vehicleId;
  final String oemInspectionType;
  final String oemReason;

  MaintenanceData({
    required this.vehicleId,
    required this.oemInspectionType,
    required this.oemReason,
  });

  factory MaintenanceData.fromMap(Map<String, dynamic> data) {
    return MaintenanceData(
      vehicleId: data['vehicleId'] ?? '',
      oemInspectionType: data['oemInspectionType'] ?? '',
      oemReason: data['oemReason'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'oemInspectionType': oemInspectionType,
      'oemReason': oemReason,
    };
  }
}
