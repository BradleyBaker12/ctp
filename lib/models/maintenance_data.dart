// lib/models/maintenance_data.dart

class MaintenanceData {
  final String vehicleId;
  final String? oemInspectionType;
  final String? oemReason;
  final String? maintenanceDocUrl;
  final String? warrantyDocUrl;
  final String? maintenanceSelection;
  final String? warrantySelection;
  final DateTime? lastUpdated;

  MaintenanceData({
    required this.vehicleId,
    this.oemInspectionType,
    this.oemReason,
    this.maintenanceDocUrl,
    this.warrantyDocUrl,
    this.maintenanceSelection,
    this.warrantySelection,
    this.lastUpdated,
  });

  factory MaintenanceData.fromMap(Map<String, dynamic> data) {
    print('=== MAINTENANCE DATA MODEL DEBUG ===');
    print('Raw data received in MaintenanceData: $data');

    final maintenanceData = MaintenanceData(
      vehicleId: data['vehicleId'] ?? '',
      oemInspectionType: data['oemInspectionType'],
      oemReason: data['oemReason'],
      maintenanceDocUrl: data['maintenanceDocUrl'],
      warrantyDocUrl: data['warrantyDocUrl'],
      maintenanceSelection: data['maintenanceSelection'],
      warrantySelection: data['warrantySelection'],
      lastUpdated: data['lastUpdated']?.toDate(),
    );

    print('Created MaintenanceData object:');
    print('vehicleId: ${maintenanceData.vehicleId}');
    print('oemInspectionType: ${maintenanceData.oemInspectionType}');
    print('maintenanceSelection: ${maintenanceData.maintenanceSelection}');

    return maintenanceData;
  }
  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'oemInspectionType': oemInspectionType,
      'oemReason': oemReason,
      'maintenanceDocUrl': maintenanceDocUrl,
      'warrantyDocUrl': warrantyDocUrl,
      'maintenanceSelection': maintenanceSelection,
      'warrantySelection': warrantySelection,
      'lastUpdated': lastUpdated,
    };
  }
}
