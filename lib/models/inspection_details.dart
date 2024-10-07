// inspection_detail.dart

class InspectionDetail {
  final String location;
  final DateTime time;

  InspectionDetail({required this.location, required this.time});

  Map<String, dynamic> toMap() {
    return {
      'location': location,
      'time': time.toIso8601String(),
    };
  }

  factory InspectionDetail.fromMap(Map<String, dynamic> map) {
    return InspectionDetail(
      location: map['location'] ?? '',
      time: DateTime.parse(map['time'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  String toString() {
    return '$location at ${time.toLocal()}';
  }
}
