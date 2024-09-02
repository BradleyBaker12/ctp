import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'location_confirmation_page.dart';

class InspectionDetailsPage extends StatefulWidget {
  final String offerId;
  final String makeModel;
  final String offerAmount;

  const InspectionDetailsPage({
    super.key,
    required this.offerId,
    required this.makeModel,
    required this.offerAmount,
  });

  @override
  _InspectionDetailsPageState createState() => _InspectionDetailsPageState();
}

class _InspectionDetailsPageState extends State<InspectionDetailsPage> {
  int _selectedLocation = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _selectedTimeSlot = 0;

  @override
  void initState() {
    super.initState();

    // Find the first available date across all locations
    DateTime? firstAvailableDate;
    for (var dates in _locationDates.values) {
      for (var date in dates) {
        if (date.isAfter(DateTime.now()) &&
            (firstAvailableDate == null || date.isBefore(firstAvailableDate))) {
          firstAvailableDate = date;
        }
      }
    }

    // Set the focused day to the first available date or the current date if none found
    _focusedDay = firstAvailableDate ?? DateTime.now();
    _selectedDay = _focusedDay;

    // Update the offer status to "set location and time" when the page loads
    FirebaseFirestore.instance
        .collection('offers')
        .doc(widget.offerId)
        .update({'offerStatus': 'set location and time'});
  }

  final List<String> _locations = ['Cape Town', 'Pretoria', 'Sandton'];

  final List<String> _addresses = ['Cape Town', 'Pretoria', 'Sandton'];

  final Map<int, List<DateTime>> _locationDates = {
    0: [
      DateTime(2024, 09, 13),
      DateTime(2024, 09, 18),
      DateTime(2024, 09, 25),
    ],
    1: [
      DateTime(2024, 09, 15),
      DateTime(2024, 09, 20),
      DateTime(2024, 09, 27),
    ],
    2: [
      DateTime(2024, 09, 09),
      DateTime(2024, 09, 17),
      DateTime(2024, 09, 24),
    ],
  };

  final Map<int, Map<DateTime, List<String>>> _locationTimes = {
    0: {
      DateTime(2024, 09, 13): ['12:00', '13:45'],
      DateTime(2024, 09, 18): ['13:45', '15:00'],
      DateTime(2024, 09, 25): ['12:00', '15:00'],
    },
    1: {
      DateTime(2024, 09, 15): ['12:00'],
      DateTime(2024, 09, 20): ['13:45'],
      DateTime(2024, 09, 27): ['15:00'],
    },
    2: {
      DateTime(2024, 09, 09): ['12:00', '15:00'],
      DateTime(2024, 09, 17): ['13:45'],
      DateTime(2024, 09, 24): ['12:00', '13:45', '15:00'],
    },
  };

  List<String> get _availableTimes {
    if (_selectedDay != null && _locationTimes.containsKey(_selectedLocation)) {
      final normalizedSelectedDay = _normalizeDate(_selectedDay!);
      if (_locationTimes[_selectedLocation]!
          .containsKey(normalizedSelectedDay)) {
        return _locationTimes[_selectedLocation]![normalizedSelectedDay]!;
      }
    }
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

  Future<void> _saveInspectionDetails() async {
    setState(() {
      // Optional: You can add a loading state if you want
    });

    try {
      final DocumentReference offerRef =
          FirebaseFirestore.instance.collection('offers').doc(widget.offerId);

      await offerRef.set({
        'dealerSelectedInspectionDate': _selectedDay,
        'dealerSelectedInspectionTime': _availableTimes[_selectedTimeSlot],
        'dealerSelectedInspectionLocation': _locations[_selectedLocation],
      }, SetOptions(merge: true));

      // Optionally, show a confirmation or navigate to the next page
    } catch (e) {
      print('Error saving inspection details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save inspection details: $e')),
      );
    } finally {
      setState(() {
        // Optional: Reset the loading state
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Array to get the name of the month
    final List<String> monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return GradientBackground(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                              height: 80), // Adjust the height as needed
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: Image.asset(
                              'lib/assets/CTPLogo.png',
                            ),
                          ),
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
                          const SizedBox(height: 16),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Great news!',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              Text(
                                'You have a potential buyer.',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          const Text(
                            'Now, let\'s set up a meeting with the potential seller to inspect the vehicle. Your careful selection ensures a smooth process ahead.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
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
                                fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          const Text(
                            'SELECT LOCATION',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
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
                                activeColor: const Color(0xFFFF4E00),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedLocation = value!;
                                    _selectedDay = null;
                                    _selectedTimeSlot = 0;
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
                            margin: const EdgeInsets.only(
                                top:
                                    20.0), // Adds space between days and calendar
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
                                  _focusedDay = focusedDay;
                                });
                              },
                              enabledDayPredicate: (day) {
                                return day.isAfter(DateTime.now()
                                        .subtract(const Duration(days: 1))) &&
                                    isDateAvailable(day);
                              },
                              calendarStyle: CalendarStyle(
                                cellMargin: const EdgeInsets.all(
                                    4.0), // Adding space between cells
                                selectedDecoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.rectangle,
                                ),
                                todayDecoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.rectangle,
                                ),
                                todayTextStyle: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                defaultDecoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  shape: BoxShape.rectangle,
                                ),
                                defaultTextStyle: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                weekendDecoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  shape: BoxShape.rectangle,
                                ),
                                weekendTextStyle: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                outsideDaysVisible: false,
                                disabledDecoration: const BoxDecoration(
                                  color: Colors.transparent,
                                  shape: BoxShape.rectangle,
                                ),
                                disabledTextStyle: const TextStyle(
                                  color: Color.fromARGB(255, 54, 54,
                                      54), // Dull color for unavailable dates
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                markerDecoration: const BoxDecoration(
                                  color: Colors.transparent,
                                ),
                              ),
                              calendarBuilders: CalendarBuilders(
                                disabledBuilder: (context, day, focusedDay) {
                                  return Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.transparent,
                                      shape: BoxShape.rectangle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${day.day}',
                                        style: const TextStyle(
                                          color: Color.fromARGB(255, 54, 54,
                                              54), // Dull color for unavailable dates
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
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
                                  fontWeight: FontWeight.bold,
                                ),
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
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                weekendStyle: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // Disable horizontal swipe
                              shouldFillViewport: false,
                              availableGestures: AvailableGestures.none,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_selectedDay !=
                              null) // Ensure the text appears only if a date is selected
                            Text(
                              'Selected Date: ${_selectedDay!.day} ${monthNames[_selectedDay!.month - 1]}, ${_selectedDay!.year}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF4E00),
                              ),
                            ),
                          const SizedBox(height: 32),
                          if (_selectedDay != null &&
                              _availableTimes.isNotEmpty) ...[
                            Align(
                              alignment: Alignment
                                  .centerLeft, // Aligns the heading to the left
                              child: const Text(
                                'AVAILABLE TIMES',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.start,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              children:
                                  _availableTimes.asMap().entries.map((entry) {
                                int idx = entry.key;
                                String timeSlot = entry.value;
                                return RadioListTile(
                                  title: Text(
                                    timeSlot,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  value: idx,
                                  groupValue: _selectedTimeSlot,
                                  activeColor: const Color(0xFFFF4E00),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTimeSlot = value!;
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
                            onPressed: () async {
                              await _saveInspectionDetails();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      LocationConfirmationPage(
                                    offerId: widget.offerId,
                                    location: _locations[_selectedLocation],
                                    address: _addresses[_selectedLocation],
                                    date: _selectedDay!,
                                    time: _availableTimes[_selectedTimeSlot],
                                    makeModel: widget.makeModel,
                                    offerAmount: widget.offerAmount,
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
                CustomBottomNavigation(
                  selectedIndex: 1, // Set the appropriate selectedIndex here
                  onItemTapped: (index) {
                    setState(() {
                      // Handle navigation logic if necessary
                    });
                  },
                ),
              ],
            ),
            Positioned(
              top: 120, // Adjust this value to move the back button up or down
              left:
                  16, // Adjust this value if you need to change the horizontal position
              child: CustomBackButton(
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
