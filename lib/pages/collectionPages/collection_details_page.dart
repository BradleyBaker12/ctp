import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/pages/collectionPages/collection_confirmationPage.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:geocoding/geocoding.dart'; // Add this import

class CollectionDetailsPage extends StatefulWidget {
  final String offerId; // Add offerId parameter

  const CollectionDetailsPage({super.key, required this.offerId});

  @override
  _CollectionDetailsPageState createState() => _CollectionDetailsPageState();
}

class _CollectionDetailsPageState extends State<CollectionDetailsPage> {
  int _selectedLocation = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _selectedTimeSlot = 0;
  int _selectedIndex = 0;
  bool _isLoading = false;

  final List<String> _locations = [
    'Vereeniging, South Africa',
    'Meyerton, South Africa',
    'Springs, South Africa'
  ];
  final List<String> _addresses = [
    'Vereenging, South Africa',
    'Meyerton, South Africa',
    'Springs, South Africa'
  ];
  final List<LatLng> _latLngs = [];

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

  @override
  void initState() {
    super.initState();
    _updateOfferStatus();
    _convertAddressesToLatLng();

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

    // Set the focused day and selected day to the first available date or the current date if none found
    _focusedDay = firstAvailableDate ?? DateTime.now();
    _selectedDay = _focusedDay;
  }

  Future<void> _updateOfferStatus() async {
    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .update({'offerStatus': 'Confirm Collection'});
    } catch (e) {
      print('Error updating offer status: $e');
    }
  }

  Future<void> _convertAddressesToLatLng() async {
    setState(() {
      _isLoading = true;
    });

    try {
      for (String address in _addresses) {
        List<Location> locations = await locationFromAddress(address);
        if (locations.isNotEmpty) {
          final location = locations.first;
          _latLngs.add(LatLng(location.latitude, location.longitude));
        } else {
          _latLngs.add(const LatLng(0, 0));
        }
      }
    } catch (e) {
      print('Error converting addresses to coordinates: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to convert addresses: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCollectionDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final DocumentReference offerRef =
          FirebaseFirestore.instance.collection('offers').doc(widget.offerId);

      await offerRef.set({
        'dealerSelectedCollectionDate': _selectedDay,
        'dealerSelectedCollectionTime': _availableTimes[_selectedTimeSlot],
        'dealerSelectedCollectionLocation': _addresses[_selectedLocation],
        'latLng': _latLngs[_selectedLocation] != null
            ? GeoPoint(_latLngs[_selectedLocation].latitude,
                _latLngs[_selectedLocation].longitude)
            : null,
      }, SetOptions(merge: true));

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CollectionConfirmationPage(
            offerId: widget.offerId,
            location: _locations[_selectedLocation],
            address: _addresses[_selectedLocation],
            date: _selectedDay!,
            time: _availableTimes[_selectedTimeSlot],
            latLng: _latLngs[_selectedLocation],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save collection details: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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

    return Scaffold(
      body: GradientBackground(
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              SingleChildScrollView(
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
                      const SizedBox(height: 50),
                      SizedBox(
                          width: 100,
                          height: 100,
                          child: Image.asset('lib/assets/CTPLogo.png')),
                      const SizedBox(height: 16),
                      const Text(
                        'CONFIRM YOUR COLLECTION DETAILS',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Great news!',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
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
                                fontWeight: FontWeight.w400),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Now, let\'s set up a meeting with the potential seller to collect the vehicle. Your careful selection ensures a smooth process ahead.',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 64),
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
                              location.toUpperCase(),
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
                      const SizedBox(height: 32),
                      const Text(
                        'SELECT FROM AVAILABLE DATES AND TIMES FOR YOUR SELECTED LOCATION',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Container(
                        margin: const EdgeInsets.only(top: 20.0),
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
                            cellMargin: const EdgeInsets.all(4.0),
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
                              color: Color.fromARGB(255, 54, 54, 54),
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
                                      color: Color.fromARGB(255, 54, 54, 54),
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
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedDay != null) // Display the selected date
                        Text(
                          'Selected Date: ${_selectedDay!.day} ${monthNames[_selectedDay!.month - 1]}, ${_selectedDay!.year}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF4E00),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (_selectedDay != null &&
                          _availableTimes.isNotEmpty) ...[
                        const Text(
                          'AVAILABLE TIMES',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
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
                        text: 'CONFIRM PICKUP',
                        borderColor: Colors.blue,
                        onPressed: _saveCollectionDetails,
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFFF4E00)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
