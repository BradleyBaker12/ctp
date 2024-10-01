import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'location_confirmation_page.dart';
import 'package:intl/intl.dart'; // Import for date parsing

class InspectionDetailsPage extends StatefulWidget {
  final String offerId;
  final String makeModel;
  final String offerAmount;
  final String vehicleId; // Add vehicleId to fetch vehicle data

  const InspectionDetailsPage({
    super.key,
    required this.offerId,
    required this.makeModel,
    required this.offerAmount,
    required this.vehicleId,
  });

  @override
  _InspectionDetailsPageState createState() => _InspectionDetailsPageState();
}

class _InspectionDetailsPageState extends State<InspectionDetailsPage> {
  int _selectedLocation = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _selectedTimeSlot = 0;
  bool _isLoading = true;

  List<String> _locations = [];
  List<String> _addresses = [];
  List<List<DateTime>> _locationDates = [];
  List<List<Map<String, dynamic>>> _locationTimeSlots = [];

  @override
  void initState() {
    super.initState();
    _fetchInspectionLocations();
  }

  Future<void> _fetchInspectionLocations() async {
    try {
      // Get the vehicle document
      DocumentSnapshot vehicleSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .get();

      if (vehicleSnapshot.exists) {
        print('Vehicle Document Data: ${vehicleSnapshot.data()}');

        // Check if 'inspectionLocations' field exists
        Map<String, dynamic>? vehicleData =
            vehicleSnapshot.data() as Map<String, dynamic>?;

        // Use null-aware operators to safely access the field
        var inspectionLocations = vehicleData?['inspectionDetails']
            ?['inspectionLocations']?['locations'] as List<dynamic>?;

        // Check for null or empty inspectionLocations
        if (inspectionLocations == null || inspectionLocations.isEmpty) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'No inspection locations available for this vehicle ${widget.vehicleId}.'),
            ),
          );
          return;
        }

        print('Inspection Locations Data: $inspectionLocations');

        List<String> locations = [];
        List<String> addresses = [];
        List<List<DateTime>> locationDates = [];
        List<List<Map<String, dynamic>>> locationTimeSlots = [];

        for (var locationEntry in inspectionLocations) {
          if (locationEntry == null) continue; // Skip if null

          String address = locationEntry['address'] ?? '';
          List<dynamic> timeSlots = locationEntry['timeSlots'] ?? [];

          if (address.isEmpty || timeSlots.isEmpty) {
            continue; // Skip if data is missing
          }

          print('Processing location: $address');

          // Lists to hold dates and time slots for this location
          List<DateTime> dates = [];
          List<Map<String, dynamic>> timeSlotsList = [];

          for (var timeSlot in timeSlots) {
            if (timeSlot == null) continue; // Skip if null

            String? dateString = timeSlot['date']; // e.g., "18-9-2024"
            if (dateString == null) continue; // Skip if date is missing

            DateTime date;
            try {
              date = DateFormat('d-M-yyyy').parse(dateString);
              print('Parsed dateString $dateString to date $date');
            } catch (e) {
              print('Error parsing date: $dateString');
              continue; // Skip this timeSlot if date parsing fails
            }

            // Add the date to the dates list if not already present
            if (!dates.contains(date)) {
              dates.add(date);
            }

            // Add the times
            List<dynamic> times = timeSlot['times'] ?? []; // List<String>
            if (times.isEmpty) {
              continue; // Skip if times are missing
            }

            print('Date: $date, Times: $times');

            // Store the date and times together
            timeSlotsList.add({
              'date': date,
              'times': times,
            });
          }

          if (dates.isEmpty || timeSlotsList.isEmpty) {
            continue; // Skip this location if no valid dates or times
          }

          // Add the address
          locations.add(address);
          addresses.add(address);

          // Add the dates and time slots
          locationDates.add(dates);
          locationTimeSlots.add(timeSlotsList);
        }

        // Check if any valid locations were found
        if (locations.isEmpty) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'No valid inspection locations found for this vehicle ${widget.vehicleId}.'),
            ),
          );
          return;
        }

        // For debugging, print the populated data
        print('Final Locations: $locations');
        print('Final Addresses: $addresses');
        print('Final Location Dates: $locationDates');
        print('Final Location Time Slots: $locationTimeSlots');

        // Find the first available date across all locations
        DateTime? firstAvailableDate;
        for (var dates in locationDates) {
          for (var date in dates) {
            if (date.isAfter(DateTime.now()) &&
                (firstAvailableDate == null ||
                    date.isBefore(firstAvailableDate))) {
              firstAvailableDate = date;
            }
          }
        }

        // Set the focused day to the first available date or the current date if none found
        _focusedDay = firstAvailableDate ?? DateTime.now();
        _selectedDay = _focusedDay;

        setState(() {
          _locations = locations;
          _addresses = addresses;
          _locationDates = locationDates;
          _locationTimeSlots = locationTimeSlots;
          _isLoading = false;
        });

        // Update the offer status to "set location and time"
        FirebaseFirestore.instance
            .collection('offers')
            .doc(widget.offerId)
            .update({'offerStatus': 'set location and time'});
      } else {
        // Handle the case where the vehicle document does not exist
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vehicle not found for ${widget.vehicleId}')),
        );
      }
    } catch (e, stacktrace) {
      print('Error fetching inspection locations: $e');
      print(stacktrace);
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  List<String> get _availableTimes {
    if (_selectedDay != null &&
        _locationTimeSlots.isNotEmpty &&
        _selectedLocation < _locationTimeSlots.length) {
      final normalizedSelectedDay = _normalizeDate(_selectedDay!);
      List<Map<String, dynamic>> timeSlots =
          _locationTimeSlots[_selectedLocation];

      for (var timeSlot in timeSlots) {
        DateTime date = _normalizeDate(timeSlot['date']);
        if (date.isAtSameMomentAs(normalizedSelectedDay)) {
          List<dynamic> times = timeSlot['times']; // List<String>
          print('Available times for $_selectedDay: $times');
          return times.cast<String>();
        }
      }
    }
    return [];
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool isDateAvailable(DateTime day) {
    if (_locationDates.isEmpty ||
        _selectedLocation >= _locationDates.length ||
        _locationDates[_selectedLocation].isEmpty) {
      return false;
    }

    DateTime checkDay = _normalizeDate(day);
    List<DateTime> dates = _locationDates[_selectedLocation];
    for (var date in dates) {
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
        'dealerSelectedInspectionAddress': _addresses[_selectedLocation],
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

    if (_isLoading) {
      return GradientBackground(
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_locations.isEmpty) {
      return GradientBackground(
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: Text(
                  'No inspection locations available.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
              Positioned(
                top: 120,
                left: 16,
                child: CustomBackButton(
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                          const SizedBox(height: 80),
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
                            margin: const EdgeInsets.only(top: 20.0),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: TableCalendar(
                              availableGestures:
                                  AvailableGestures.verticalSwipe,
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
                                          color:
                                              Color.fromARGB(255, 54, 54, 54),
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
                              shouldFillViewport: false,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_selectedDay != null)
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
                              alignment: Alignment.centerLeft,
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
                            onPressed: (_selectedDay != null &&
                                    _availableTimes.isNotEmpty)
                                ? () async {
                                    await _saveInspectionDetails();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LocationConfirmationPage(
                                          offerId: widget.offerId,
                                          location:
                                              _locations[_selectedLocation],
                                          address:
                                              _addresses[_selectedLocation],
                                          date: _selectedDay!,
                                          time: _availableTimes[
                                              _selectedTimeSlot],
                                          makeModel: widget.makeModel,
                                          offerAmount: widget.offerAmount,
                                          vehicleId: widget.vehicleId,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                CustomBottomNavigation(
                  selectedIndex: 1,
                  onItemTapped: (index) {
                    setState(() {
                      // Handle navigation logic if necessary
                    });
                  },
                ),
              ],
            ),
            Positioned(
              top: 120,
              left: 16,
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
