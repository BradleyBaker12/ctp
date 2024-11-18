// lib/models/maintenance_data.dart

class MaintenanceData {
  final String vehicleId;
  final String oemInspectionType;
  final String oemReason;
  final String? maintenanceDocUrl;
  final String? warrantyDocUrl;

  MaintenanceData({
    required this.vehicleId,
    required this.oemInspectionType,
    required this.oemReason,
    this.maintenanceDocUrl,
    this.warrantyDocUrl,
  });

  factory MaintenanceData.fromMap(Map<String, dynamic> data) {
    return MaintenanceData(
      vehicleId: data['vehicleId'] ?? '',
      oemInspectionType: data['oemInspectionType'] ?? '',
      oemReason: data['oemReason'] ?? '',
      maintenanceDocUrl: data['maintenanceDocUrl'],
      warrantyDocUrl: data['warrantyDocUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'oemInspectionType': oemInspectionType,
      'oemReason': oemReason,
      'maintenanceDocUrl': maintenanceDocUrl,
      'warrantyDocUrl': warrantyDocUrl,
    };
  }
}
