import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/pages/collectionPages/collection_confirmationPage.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart'; // Import for date parsing

class CollectionDetailsPage extends StatefulWidget {
  final String offerId;

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
  bool _isLoading = true;

  List<String> _locations = [];
  List<String> _addresses = [];
  List<List<DateTime>> _locationDates = [];
  List<List<Map<String, dynamic>>> _locationTimeSlots = [];
  List<LatLng> _latLngs = [];

  @override
  void initState() {
    super.initState();
    _fetchCollectionLocations();
  }

  Future<void> _fetchCollectionLocations() async {
    // Set loading state to true
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Fetching offer document with ID: ${widget.offerId}');
      // Fetch the offer document to get the vehicleId
      DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .get();

      debugPrint('Offer document data: ${offerSnapshot.data()}');

      // If the offer document doesn't exist, show an error message and return
      if (!offerSnapshot.exists) {
        debugPrint('Offer document does not exist.');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offer does not exist.'),
          ),
        );
        return;
      }

      // Extract vehicleId from the offer document
      Map<String, dynamic>? offerData =
          offerSnapshot.data() as Map<String, dynamic>?;
      String? vehicleId = offerData?['vehicleId'];

      debugPrint('Vehicle ID extracted: $vehicleId');

      // If vehicleId is not found, show an error message and return
      if (vehicleId == null || vehicleId.isEmpty) {
        debugPrint('Vehicle ID not found in the offer.');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle ID not found in the offer.'),
          ),
        );
        return;
      }

      // Fetch the vehicle document using vehicleId
      debugPrint('Fetching vehicle document with ID: $vehicleId');
      DocumentSnapshot vehicleSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      debugPrint('Vehicle document data: ${vehicleSnapshot.data()}');

      // If the vehicle document doesn't exist, show an error message and return
      if (!vehicleSnapshot.exists) {
        debugPrint('Vehicle document does not exist.');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle does not exist.'),
          ),
        );
        return;
      }

      // Extract collection locations from the vehicle document
      Map<String, dynamic>? vehicleData =
          vehicleSnapshot.data() as Map<String, dynamic>?;
      var collectionLocations = vehicleData?['collectionDetails']
          ?['collectionLocations']?['locations'] as List<dynamic>?;

      debugPrint(
          'Collection locations extracted (updated access): \$collectionLocations');

      // If no collection locations are available, show an error message and return
      if (collectionLocations == null || collectionLocations.isEmpty) {
        debugPrint('No collection locations available for this offer.');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No collection locations available for this offer.'),
          ),
        );
        return;
      }

      // Initialize lists to store location data
      List<String> locations = [];
      List<String> addresses = [];
      List<List<DateTime>> locationDates = [];
      List<List<Map<String, dynamic>>> locationTimeSlots = [];
      List<LatLng> latLngs = [];

      // Loop through each collection location entry
      for (var locationEntry in collectionLocations) {
        if (locationEntry == null) continue;

        String address = locationEntry['address'] ?? '';
        List<dynamic> timeSlots = locationEntry['timeSlots'] ?? [];

        debugPrint('Processing location entry: $locationEntry');

        // Skip if address or time slots are empty
        if (address.isEmpty || timeSlots.isEmpty) {
          debugPrint('Skipping location with empty address or time slots.');
          continue;
        }

        // Lists to hold dates and time slots for this location
        List<DateTime> dates = [];
        List<Map<String, dynamic>> timeSlotsList = [];

        // Loop through each time slot for the current location
        for (var timeSlot in timeSlots) {
          if (timeSlot == null) continue;

          String? dateString = timeSlot['date'];
          if (dateString == null) continue;

          DateTime date;
          try {
            // Parse the date string
            date = DateFormat('d-M-yyyy').parse(dateString);
            debugPrint('Parsed date: $date');
          } catch (e) {
            debugPrint('Error parsing date: $e');
            continue;
          }

          // Add date to the list if not already present
          if (!dates.contains(date)) {
            dates.add(date);
          }

          // Extract times for the current date
          List<dynamic> times = timeSlot['times'] ?? [];
          if (times.isEmpty) {
            debugPrint('Skipping date with empty times.');
            continue;
          }

          // Add date and corresponding time slots to the list
          timeSlotsList.add({
            'date': date,
            'times': times,
          });
        }

        // Skip if no valid dates or time slots are found
        if (dates.isEmpty || timeSlotsList.isEmpty) {
          debugPrint('Skipping location with no valid dates or time slots.');
          continue;
        }

        // Add location data to the lists
        locations.add(address);
        addresses.add(address);
        locationDates.add(dates);
        locationTimeSlots.add(timeSlotsList);

        // Convert address to LatLng
        try {
          List<Location> geoLocations = await locationFromAddress(address);
          if (geoLocations.isNotEmpty) {
            final location = geoLocations.first;
            latLngs.add(LatLng(location.latitude, location.longitude));
          } else {
            latLngs.add(const LatLng(0, 0));
          }
        } catch (e) {
          debugPrint('Error converting address to LatLng: $e');
          latLngs.add(const LatLng(0, 0));
        }
      }

      // If no valid locations are found, show an error message and return
      if (locations.isEmpty) {
        debugPrint('No valid collection locations found.');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('No valid collection locations found for this offer.'),
          ),
        );
        return;
      }

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

      debugPrint('First available date: $firstAvailableDate');

      // Set the focused and selected day to the first available date or today
      _focusedDay = firstAvailableDate ?? DateTime.now();
      _selectedDay = _focusedDay;

      // Update the state with the fetched location data
      setState(() {
        _locations = locations;
        _addresses = addresses;
        _locationDates = locationDates;
        _locationTimeSlots = locationTimeSlots;
        _latLngs = latLngs;
        _isLoading = false;
      });
    } catch (e) {
      // Handle any errors that occur during the fetching process
      debugPrint('Failed to fetch collection locations: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load collection locations: $e'),
        ),
      );
    }
  }

// Getter to retrieve available time slots for the selected day
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
          List<dynamic> times = timeSlot['times'];
          return times.cast<String>();
        }
      }
    }
    return [];
  }

// Helper method to normalize a DateTime object to year, month, and day
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

// Method to check if a date is available for the selected location
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
                  'No collection locations available.',
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
                      padding:
                          const EdgeInsets.fromLTRB(16.0, 80.0, 16.0, 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: Image.asset(
                              'lib/assets/CTPLogo.png',
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'CONFIRM YOUR COLLECTION DETAILS',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Great news! You have a potential buyer.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Now, let\'s set up a meeting with the potential seller to collect the vehicle. Your careful selection ensures a smooth process ahead.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
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
                                        .subtract(const Duration(days: 2))) &&
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
                          if (_selectedDay != null)
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
                              children: _availableTimes.asMap().entries.map(
                                (entry) {
                                  int idx = entry.key;
                                  String timeSlot = entry.value;
                                  return RadioListTile(
                                    title: Text(
                                      timeSlot,
                                      style:
                                          const TextStyle(color: Colors.white),
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
                                },
                              ).toList(),
                            ),
                          ],
                          const SizedBox(height: 16),
                          CustomButton(
                            text: 'CONFIRM PICKUP',
                            borderColor: Colors.blue,
                            onPressed: (_selectedDay != null &&
                                    _availableTimes.isNotEmpty)
                                ? _saveCollectionDetails
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                CustomBottomNavigation(
                  selectedIndex: _selectedIndex,
                  onItemTapped: _onItemTapped,
                ),
              ],
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
