import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'location_confirmation_page.dart';
import 'package:intl/intl.dart'; // Import for date parsing
import 'package:ctp/components/web_navigation_bar.dart'; // Add this import

import 'package:auto_route/auto_route.dart';

@RoutePage()
class InspectionDetailsPage extends StatefulWidget {
  final String offerId;
  final String brand; // Changed from makeModel
  final String variant; // Added new property
  final String offerAmount;
  final String vehicleId; // Add vehicleId to fetch vehicle data

  const InspectionDetailsPage({
    super.key,
    required this.offerId,
    required this.brand, // Changed from makeModel
    required this.variant, // Added new parameter
    required this.offerAmount,
    required this.vehicleId,
  });

  @override
  _InspectionDetailsPageState createState() => _InspectionDetailsPageState();
}

class _InspectionDetailsPageState extends State<InspectionDetailsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Add this getter for consistent breakpoint
  bool _isCompactNavigation(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1100;

  int _selectedLocation = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _selectedTimeSlot = 0;
  bool _isLoading = true;

  List<String> _locations = [];
  List<String> _addresses = [];
  List<List<DateTime>> _locationDates = [];
  List<List<Map<String, dynamic>>> _locationTimeSlots = [];

  // Add this helper method to convert string to DateTime
  DateTime _parseDateTime(String dateStr) {
    // Expected format: "29-1-2025" or "29-01-2025"
    List<String> parts = dateStr.split('-');
    if (parts.length == 3) {
      int day = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int year = int.parse(parts[2]);
      return DateTime(year, month, day);
    }
    return DateTime.now(); // Fallback value
  }

  // List<String> _availableTimes(DateTime selectedDay) {
  //   // _selectedLocation is already the index, no need to search for it
  //   int locationIndex = _selectedLocation;
  //   if (locationIndex >= _locations.length) return [];

  //   // Find matching date in location dates
  //   int dateIndex = _locationDates[locationIndex].indexWhere((date) =>
  //       date.year == selectedDay.year &&
  //       date.month == selectedDay.month &&
  //       date.day == selectedDay.day);
  //   if (dateIndex == -1) return [];

  //   // Get time slots for this date
  //   var timeSlots = _locationTimeSlots[locationIndex];
  //   if (dateIndex >= timeSlots.length) return [];

  //   // Find matching date in time slots
  //   var matchingSlot = timeSlots.firstWhere(
  //     (slot) => _parseDateTime(slot['date'].toString()).isAtSameMomentAs(selectedDay),
  //     orElse: () => {'times': []},
  //   );

  //   return (matchingSlot['times'] as List?)?.cast<String>() ?? [];
  // }

  @override
  void initState() {
    super.initState();
    // print('DEBUG: initState called');
    // print('DEBUG: offerId: ${widget.offerId}');
    // print('DEBUG: vehicleId: ${widget.vehicleId}');
    _fetchInspectionLocations();
  }

  Future<void> _fetchInspectionLocations() async {
    // print('DEBUG: Starting _fetchInspectionLocations');
    try {
      setState(() {
        _isLoading = true;
      });

      // 1. Fetch document
      DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .get();

      // print('DEBUG: Document fetch complete');
      // print('DEBUG: Document exists: ${offerSnapshot.exists}');

      Map<String, dynamic>? data =
          offerSnapshot.data() as Map<String, dynamic>?;
      // print('DEBUG: Raw data: $data');

      // 2. Parse inspection locations following the correct path
      var inspectionLocations = data?['inspectionDetails']
              ?['inspectionLocations']?['locations'] ??
          [];
      // print('DEBUG: Inspection locations: $inspectionLocations');

      // Also check collectionDetails.locations as a fallback
      if (inspectionLocations.isEmpty) {
        inspectionLocations = data?['collectionDetails']?['locations'] ?? [];
        // print(
        //     'DEBUG: Falling back to collection details locations: $inspectionLocations');
      }

      if (inspectionLocations.isEmpty) {
        // print('DEBUG: No inspection locations found in either path');
        setState(() {
          _isLoading = false;
          _locations = [];
        });
        return;
      }

      // 3. Process locations
      List<String> tempLocations = [];
      List<String> tempAddresses = [];
      List<List<DateTime>> tempDates = [];
      List<List<Map<String, dynamic>>> tempTimeSlots = [];

      for (var location in inspectionLocations) {
        // print('DEBUG: Processing location: $location');

        String address = location['address'] ?? '';
        var dates = location['dates'] ?? [];
        var timeSlots = location['timeSlots'] ?? [];

        // print('DEBUG: Address: $address');
        // print('DEBUG: Dates: $dates');
        // print('DEBUG: TimeSlots: $timeSlots');

        tempLocations.add(address);
        tempAddresses.add(address);

        // Process dates
        List<DateTime> locationDates = [];
        for (var dateStr in dates) {
          try {
            // Handle both formats: "11-2-2025" and "11-02-2025"
            DateTime date = DateFormat('dd-M-yyyy').parse(dateStr);
            locationDates.add(date);
          } catch (e) {
            // print('DEBUG: Date parsing error: $e for date: $dateStr');
            try {
              // Try alternative format
              DateTime date = DateFormat('dd-MM-yyyy').parse(dateStr);
              locationDates.add(date);
            } catch (e) {
              // print('DEBUG: Alternative date parsing also failed: $e');
            }
          }
        }
        tempDates.add(locationDates);

        // Process time slots
        List<Map<String, dynamic>> locationTimeSlots = [];
        for (var slot in timeSlots) {
          locationTimeSlots.add(Map<String, dynamic>.from(slot));
        }
        tempTimeSlots.add(locationTimeSlots);
      }

      // 4. Update state
      setState(() {
        _isLoading = false;
        _locations = tempLocations;
        _addresses = tempAddresses;
        _locationDates = tempDates;
        _locationTimeSlots = tempTimeSlots;
      });

      // print('DEBUG: Final state:');
      // print('Locations: $_locations');
      // print('Dates: $_locationDates');
      // print('TimeSlots: $_locationTimeSlots');
    } catch (e) {
      // print('DEBUG: Error in _fetchInspectionLocations: $e');
      // print('DEBUG: Stack trace: $stack');
      setState(() {
        _isLoading = false;
      });
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
        // Parse the string date into a DateTime
        final dateString = timeSlot['date'] as String;
        final parsedDate = _parseDateTime(dateString);
        final date = _normalizeDate(parsedDate);

        if (date.isAtSameMomentAs(normalizedSelectedDay)) {
          List<dynamic> times = timeSlot['times']; // should be List<String>
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

  /// Helper function to provide different font sizes for phone vs. tablet.
  double _adaptiveTextSize(
      BuildContext context, double phoneSize, double tabletSize) {
    bool isTablet = MediaQuery.of(context).size.width >= 1000;
    return isTablet ? tabletSize : phoneSize;
  }

  /// Helper function for text styles
  TextStyle _getTextStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.white,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width >= 600;
    const bool isWeb = kIsWeb;
    final double contentWidth =
        isTablet ? screenSize.width * 1 : screenSize.width;
    final double horizontalPadding =
        isTablet ? (screenSize.width - contentWidth) / 2 : 16;

    // print('DEBUG: Build method called');
    // print('DEBUG: isLoading: $_isLoading');
    // print('DEBUG: locations: $_locations');
    // print('DEBUG: selectedDay: $_selectedDay');

    if (_isLoading) {
      return GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Loading inspection details...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

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

    if (_locations.isEmpty) {
      // Update the message to be more accurate
      return GradientBackground(
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: Text(
                  'No inspection locations available.\nPlease try again later.',
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
      child: ErrorBoundary(
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          appBar: isWeb
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(70),
                  child: WebNavigationBar(
                    isCompactNavigation: _isCompactNavigation(context),
                    currentRoute: '/offers',
                    onMenuPressed: () =>
                        _scaffoldKey.currentState?.openDrawer(),
                  ),
                )
              : null,
          drawer: _isCompactNavigation(context) && isWeb
              ? Drawer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: const [Colors.black, Color(0xFF2F7FFD)],
                      ),
                    ),
                    child: Column(
                      children: [
                        DrawerHeader(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom:
                                  BorderSide(color: Colors.white24, width: 1),
                            ),
                          ),
                          child: Center(
                            child: Image.network(
                              'https://firebasestorage.googleapis.com/v0/b/ctp-central-database.appspot.com/o/CTPLOGOWeb.png?alt=media&token=d85ec0b5-f2ba-4772-aa08-e9ac6d4c2253',
                              height: 50,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 50,
                                  width: 50,
                                  color: Colors.grey[900],
                                  child: const Icon(Icons.local_shipping,
                                      color: Colors.white),
                                );
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: Consumer<UserProvider>(
                            builder: (context, userProvider, _) {
                              final userRole = userProvider.getUserRole;
                              final navigationItems = userRole == 'dealer'
                                  ? [
                                      NavigationItem(
                                          title: 'Home', route: '/home'),
                                      NavigationItem(
                                          title: 'Search Trucks',
                                          route: '/truckPage'),
                                      NavigationItem(
                                          title: 'Wishlist',
                                          route: '/wishlist'),
                                      NavigationItem(
                                          title: 'Pending Offers',
                                          route: '/offers'),
                                    ]
                                  : [
                                      NavigationItem(
                                          title: 'Home', route: '/home'),
                                      NavigationItem(
                                          title: 'Your Trucks',
                                          route: '/transporterList'),
                                      NavigationItem(
                                          title: 'Your Offers',
                                          route: '/offers'),
                                      NavigationItem(
                                          title: 'In-Progress',
                                          route: '/in-progress'),
                                    ];

                              return ListView(
                                children: navigationItems.map((item) {
                                  bool isActive = '/offers' == item.route;
                                  return ListTile(
                                    title: Text(
                                      item.title,
                                      style: TextStyle(
                                        color: isActive
                                            ? const Color(0xFFFF4E00)
                                            : Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    selected: isActive,
                                    selectedTileColor: Colors.black12,
                                    onTap: () {
                                      Navigator.pop(context); // Close drawer
                                      if (!isActive) {
                                        Navigator.pushNamed(
                                            context, item.route);
                                      }
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // if (isWeb)
                    //   WebNavigationBar(
                    //     isCompactNavigation: false,
                    //     currentRoute: '/offers',
                    //   ),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Center(
                          // Center the content for web
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: isTablet ? 800 : double.infinity,
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding,
                              vertical: 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 80),
                                SizedBox(
                                  width: isTablet ? 120 : 100,
                                  height: isTablet ? 120 : 100,
                                  child: Image.asset(
                                    'lib/assets/CTPLogo.png',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'CONFIRM YOUR FINAL INSPECTION DETAILS',
                                  style: _getTextStyle(
                                    fontSize:
                                        _adaptiveTextSize(context, 24, 32),
                                    fontWeight: FontWeight.bold,
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
                                // GestureDetector(
                                //   onTap: () {
                                //     // Handle skip action
                                //   },
                                //   child: const Text(
                                //     'SKIP >',
                                //     style: TextStyle(
                                //       fontSize: 18,
                                //       fontWeight: FontWeight.bold,
                                //       color: Color(0xFFFF4E00),
                                //     ),
                                //   ),
                                // ),
                                // const SizedBox(height: 5),
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
                                  children:
                                      _locations.asMap().entries.map((entry) {
                                    int idx = entry.key;
                                    String location = entry.value;
                                    return RadioListTile(
                                      title: Text(
                                        location,
                                        style: const TextStyle(
                                            color: Colors.white),
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
                                  width: isTablet
                                      ? contentWidth * 0.8
                                      : double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: TableCalendar(
                                    availableGestures: AvailableGestures.none,
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
                                              .subtract(
                                                  const Duration(days: 1))) &&
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
                                      defaultTextStyle: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize:
                                            _adaptiveTextSize(context, 16, 20),
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
                                      disabledBuilder:
                                          (context, day, focusedDay) {
                                        return Container(
                                          decoration: const BoxDecoration(
                                            color: Colors.transparent,
                                            shape: BoxShape.rectangle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${day.day}',
                                              style: const TextStyle(
                                                color: Color.fromARGB(
                                                    255, 54, 54, 54),
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
                                  SizedBox(
                                    width: isTablet
                                        ? contentWidth * 0.6
                                        : double.infinity,
                                    child: Column(
                                      children: _availableTimes
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        int idx = entry.key;
                                        String timeSlot = entry.value;
                                        return RadioListTile(
                                          title: Text(
                                            timeSlot,
                                            style: const TextStyle(
                                                color: Colors.white),
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
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Container(
                                  width: isTablet
                                      ? contentWidth * 0.4
                                      : double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: CustomButton(
                                      text: 'CONFIRM MEETING',
                                      borderColor: Colors.blue,
                                      onPressed: () async {
                                        // FirebaseFirestore.instance
                                        //     .collection('vehicles')
                                        //     .doc(widget.vehicleId)
                                        //     .update(
                                        //   {"inspectionDetails": {}},
                                        // );
                                        // FirebaseFirestore.instance
                                        //     .collection('offers')
                                        //     .doc(widget.offerId)
                                        //     .delete();
                                        // return;
                                        if (_selectedDay == null) {
                                          print("_selectedDay null: --------");
                                          return;
                                        }
                                        if (_availableTimes.isEmpty) {
                                          print(
                                              "_availableTimes is Empty: --------");
                                          return;
                                        }

                                        await _saveInspectionDetails();
                                        print(
                                            "Confirm Meeting Details: --------");
                                        print("OfferId: ${widget.offerId}");
                                        print(
                                            "Locations: ${_locations[_selectedLocation]}");
                                        print(
                                            "Addresses: ${_addresses[_selectedLocation]}");
                                        print("Day: $_selectedDay}");
                                        print(
                                            "Time: ${_availableTimes[_selectedTimeSlot]}");
                                        print(
                                            "Offer Amount: ${widget.offerAmount}");
                                        print("VehicleId: ${widget.vehicleId}");

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
                                              offerAmount: widget.offerAmount,
                                              vehicleId: widget.vehicleId,
                                              brand: widget.brand,
                                              variant: widget.variant,
                                            ),
                                          ),
                                        );
                                      }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!isWeb)
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
                if (!isWeb && !_isLoading) // Modified this condition
                  Positioned(
                    top: 120,
                    left: isTablet ? horizontalPadding : 16,
                    child: CustomBackButton(
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Add new ErrorBoundary widget:
class ErrorBoundary extends StatelessWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          top: 40,
          right: 16,
          child: IconButton(
            icon: Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Debug Info'),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: [
                        Text(
                            'Screen Width: ${MediaQuery.of(context).size.width}'),
                        Text(
                            'Screen Height: ${MediaQuery.of(context).size.height}'),
                        Text('Platform: ${Theme.of(context).platform}'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: Text('Close'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
