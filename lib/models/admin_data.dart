// lib/models/admin_data.dart

class AdminData {
  final String settlementAmount;
  final String natisRc1Url;
  final String licenseDiskUrl;
  final String settlementLetterUrl;

  AdminData({
    required this.settlementAmount,
    required this.natisRc1Url,
    required this.licenseDiskUrl,
    required this.settlementLetterUrl,
  });

  factory AdminData.fromMap(Map<String, dynamic> data) {
    return AdminData(
      settlementAmount: data['settlementAmount'] ?? '',
      natisRc1Url: data['natisRc1Url'] ?? '',
      licenseDiskUrl: data['licenseDiskUrl'] ?? '',
      settlementLetterUrl: data['settlementLetterUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'settlementAmount': settlementAmount,
      'natisRc1Url': natisRc1Url,
      'licenseDiskUrl': licenseDiskUrl,
      'settlementLetterUrl': settlementLetterUrl,
    };
  }
}
