// import 'package:intl/intl.dart';

// class TimeSlot {
//   final DateTime date;
//   final List<String> times;

//   TimeSlot({required this.date, required this.times});

//   factory TimeSlot.fromMap(Map<String, dynamic> data) {
//     String dateString = data['date'] ?? '';
//     DateTime date;
//     try {
//       date = DateFormat('d-M-yyyy').parse(dateString);
//     } catch (e) {
//       date = DateTime.now();
//     }

//     List<dynamic> timesDynamic = data['times'] ?? [];
//     List<String> times = timesDynamic.cast<String>();

//     return TimeSlot(
//       date: date,
//       times: times,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'date': DateFormat('d-M-yyyy').format(date),
//       'times': times,
//     };
//   }
// }
