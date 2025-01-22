// import 'package:ctp/models/time_slot.dart';

// class InspectionLocation {
//   final String address;
//   final List<TimeSlot> timeSlots;

//   InspectionLocation({required this.address, required this.timeSlots});

//   factory InspectionLocation.fromMap(Map<String, dynamic> data) {
//     var times = data['timeSlots'] as List<dynamic>? ?? [];
//     List<TimeSlot> timeSlots = times.map((e) => TimeSlot.fromMap(e)).toList();
//     return InspectionLocation(
//       address: data['address'] ?? '',
//       timeSlots: timeSlots,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'address': address,
//       'timeSlots': timeSlots.map((e) => e.toMap()).toList(),
//     };
//   }
// }
