import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/diagonal_line_painter.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'location_confirmation_page.dart';

class InspectionDetailsPage extends StatefulWidget {
  final String offerId;

  const InspectionDetailsPage({super.key, required this.offerId});

  @override
  _InspectionDetailsPageState createState() => _InspectionDetailsPageState();
}

class _InspectionDetailsPageState extends State<InspectionDetailsPage> {
  int _selectedLocation = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _selectedTimeSlot = 0;

  final List<String> _locations = ['LOCATION 1', 'LOCATION 2', 'LOCATION 3'];

  final List<String> _addresses = [
    '56 Iffley Road, Henley On Klip, Meyerton, 1962',
    '119 Blackwood Street, Three Rivers, Vereeniging, 1929',
    'Sandton'
  ];

  final List<LatLng> _latLngs = [
    const LatLng(-26.2041, 28.0473), // Example coordinates for Johannesburg
    const LatLng(-25.7461, 28.1881), // Example coordinates for Pretoria
    const LatLng(-33.9249, 18.4241) // Example coordinates for Cape Town
  ];

  final Map<int, List<DateTime>> _locationDates = {
    0: [
      DateTime(2024, 10, 13),
      DateTime(2024, 10, 18),
      DateTime(2024, 10, 25),
    ],
    1: [
      DateTime(2024, 10, 15),
      DateTime(2024, 10, 20),
      DateTime(2024, 10, 27),
    ],
    2: [
      DateTime(2024, 10, 10),
      DateTime(2024, 10, 17),
      DateTime(2024, 10, 24),
    ],
  };

  final Map<int, Map<DateTime, List<String>>> _locationTimes = {
    0: {
      DateTime(2024, 10, 13): ['12:00', '13:45'],
      DateTime(2024, 10, 18): ['13:45', '15:00'],
      DateTime(2024, 10, 25): ['12:00', '15:00'],
    },
    1: {
      DateTime(2024, 10, 15): ['12:00'],
      DateTime(2024, 10, 20): ['13:45'],
      DateTime(2024, 10, 27): ['15:00'],
    },
    2: {
      DateTime(2024, 10, 10): ['12:00', '15:00'],
      DateTime(2024, 10, 17): ['13:45'],
      DateTime(2024, 10, 24): ['12:00', '13:45', '15:00'],
    },
  };

  List<String> get _availableTimes {
    if (_selectedDay != null && _locationTimes.containsKey(_selectedLocation)) {
      final normalizedSelectedDay = _normalizeDate(_selectedDay!);
      if (_locationTimes[_selectedLocation]!
          .containsKey(normalizedSelectedDay)) {
        print(
            'Debug: Fetching available times for selected day $_selectedDay at location $_selectedLocation');
        return _locationTimes[_selectedLocation]![normalizedSelectedDay]!;
      }
    }
    print(
        'Debug: No available times found for selected day $_selectedDay at location $_selectedLocation');
    return [];
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool isDateAvailable(DateTime day) {
    DateTime checkDay = _normalizeDate(day);
    for (var date in _locationDates[_selectedLocation]!) {
      DateTime availableDate = _normalizeDate(date);
      if (checkDay.isAtSameMomentAs(availableDate)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Material(
        color: Colors.transparent,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: CustomBackButton(
                      onPressed: () => Navigator.of(context).pop()),
                ),
                const SizedBox(height: 16),
                Image.asset('lib/assets/CTPLogo.png'),
                const SizedBox(height: 16),
                const Text(
                  'CONFIRM YOUR FINAL INSPECTION DETAILS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Great news! You have a potential buyer.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Now, let\'s set up a meeting with the potential seller to inspect the vehicle. Your careful selection ensures a smooth process ahead.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    // Handle skip action
                  },
                  child: const Text(
                    'SKIP >',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF4E00),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'YOU CAN SKIP THIS STEP IF YOU TRUST THE TRANSPORTER',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'SELECT LOCATION',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Column(
                  children: _locations.asMap().entries.map((entry) {
                    int idx = entry.key;
                    String location = entry.value;
                    return RadioListTile(
                      title: Text(
                        location,
                        style: const TextStyle(color: Colors.white),
                      ),
                      value: idx,
                      groupValue: _selectedLocation,
                      activeColor:
                          const Color(0xFFFF4E00), // Active color set here
                      onChanged: (value) {
                        setState(() {
                          _selectedLocation = value!;
                          _selectedDay = null;
                          _selectedTimeSlot = 0;
                          // Debugging: print the selected location and available dates
                          print('Debug: Selected Location: $_selectedLocation');
                          print(
                              'Debug: Available Dates: ${_locationDates[_selectedLocation]}');
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SELECT FROM AVAILABLE DATES AND TIMES FOR YOUR SELECTED LOCATION',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2100, 1, 1),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay; // update focused day as well
                        // Debugging: print the selected day
                        print('Debug: Selected Day: $_selectedDay');
                        // Debugging: print the available times for the selected day
                        if (_locationTimes[_selectedLocation] != null &&
                            _locationTimes[_selectedLocation]!
                                .containsKey(_normalizeDate(_selectedDay!))) {
                          print(
                              'Debug: Available Times: ${_locationTimes[_selectedLocation]![_normalizeDate(_selectedDay!)]}');
                        } else {
                          print(
                              'Debug: No available times for the selected day');
                        }
                      });
                    },
                    enabledDayPredicate: (day) {
                      // Disable previous days and ensure the day is in the available dates
                      bool isEnabled = day.isAfter(DateTime.now()
                              .subtract(const Duration(days: 1))) &&
                          isDateAvailable(day);
                      // Debugging: print the day and whether it's enabled
                      return isEnabled;
                    },
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      todayTextStyle: const TextStyle(color: Colors.black),
                      defaultDecoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.white),
                      ),
                      weekendDecoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.white),
                      ),
                      defaultTextStyle: const TextStyle(color: Colors.white),
                      weekendTextStyle: const TextStyle(color: Colors.white),
                      outsideDaysVisible: false,
                      disabledDecoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(8.0),
                        color: Colors.black.withOpacity(0.5),
                      ),
                      disabledTextStyle: const TextStyle(color: Colors.white),
                      markerDecoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      disabledBuilder: (context, day, focusedDay) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(8.0),
                            color: Colors.black.withOpacity(0.5),
                          ),
                          child: Center(
                            child: CustomPaint(
                              painter: SingleDiagonalLinePainter(),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    headerStyle: const HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                    ),
                    daysOfWeekStyle: const DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      weekendStyle: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectedDay != null && _availableTimes.isNotEmpty) ...[
                  const Text(
                    'SELECT TIME SLOT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: _availableTimes.asMap().entries.map((entry) {
                      int idx = entry.key;
                      String timeSlot = entry.value;
                      return RadioListTile(
                        title: Text(
                          timeSlot,
                          style: const TextStyle(color: Colors.white),
                        ),
                        value: idx,
                        groupValue: _selectedTimeSlot,
                        activeColor:
                            const Color(0xFFFF4E00), // Active color set here
                        onChanged: (value) {
                          setState(() {
                            _selectedTimeSlot = value!;
                            // Debugging: print the selected time slot
                            print(
                                'Debug: Selected Time Slot: $_selectedTimeSlot');
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                CustomButton(
                  text: 'CONFIRM MEETING',
                  borderColor: Colors.blue,
                  onPressed: () {
                    // Navigate to the LocationConfirmationPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationConfirmationPage(
                          offerId: widget.offerId,
                          location: _locations[_selectedLocation],
                          address: _addresses[_selectedLocation],
                          date: _selectedDay!,
                          time: _availableTimes[_selectedTimeSlot],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
