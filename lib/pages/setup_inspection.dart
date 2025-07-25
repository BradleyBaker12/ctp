import 'package:ctp/components/web_navigation_bar.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/services/places_services.dart';
import 'package:ctp/services/places_widget.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase Auth
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';
import '../services/places_data_model.dart'; // For Firebase Auth

import 'package:auto_route/auto_route.dart';
@RoutePage()class SetupInspectionPage extends StatefulWidget {
  final String offerId; // Change from vehicleId to offerId

  const SetupInspectionPage({super.key, required this.offerId});

  @override
  _SetupInspectionPageState createState() => _SetupInspectionPageState();
}

class _SetupInspectionPageState extends State<SetupInspectionPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Add this getter for consistent breakpoint
  bool _isCompactNavigation(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1100;

  DateTime _focusedDay = DateTime.now();
  List<DateTime> _selectedDays = [];
  DateTime? _selectedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  LatLng? latLng;
  bool isAddressSelected = false;

  // Availability date and range
  final DateTime _availabilityDate =
      DateTime.now(); // Change this to your specific availability start date
  final int _daysAvailable = 7; // Only show the first 7 available days

  // Map to store times for each selected date
  final Map<DateTime, List<TimeOfDay>> _dateTimeSlots = {};

  // List of time dropdowns for the current day
  List<TimeOfDay?> _selectedTimes = [null];

  bool _isAddingLocation = true;
  bool _showBackToFormButton = false;

  // Loading state
  bool _isLoading = false;

  // Create a list of time slots (e.g., every 30 minutes from 8 AM to 6 PM)
  final List<TimeOfDay> _timeSlots = [
    TimeOfDay(hour: 8, minute: 0),
    TimeOfDay(hour: 8, minute: 30),
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 9, minute: 30),
    TimeOfDay(hour: 10, minute: 0),
    TimeOfDay(hour: 10, minute: 30),
    TimeOfDay(hour: 11, minute: 0),
    TimeOfDay(hour: 11, minute: 30),
    TimeOfDay(hour: 12, minute: 0),
    TimeOfDay(hour: 12, minute: 30),
    TimeOfDay(hour: 13, minute: 0),
    TimeOfDay(hour: 13, minute: 30),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 14, minute: 30),
    TimeOfDay(hour: 15, minute: 0),
    TimeOfDay(hour: 15, minute: 30),
    TimeOfDay(hour: 16, minute: 0),
    TimeOfDay(hour: 16, minute: 30),
    TimeOfDay(hour: 17, minute: 0),
    TimeOfDay(hour: 17, minute: 30),
  ];

  // Store information for multiple locations
  final List<Map<String, dynamic>> _locations = [];
  int? _editIndex; // Store the index of the location being edited

  // Controllers for address input fields
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  // List to store saved locations fetched from Firestore
  List<Map<String, dynamic>> _savedLocations = [];

  @override
  void initState() {
    super.initState();
    _fetchSavedLocations();
  }

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _fetchSavedLocations() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        // Safely access savedLocations field, defaulting to empty list if it doesn't exist
        final data = userDoc.data() as Map<String, dynamic>?;
        List<dynamic> savedLocations = data?['savedLocations'] ?? [];
        setState(() {
          _savedLocations = List<Map<String, dynamic>>.from(savedLocations);
        });
      }
    } catch (e) {
      print('Error fetching saved locations: $e');
      // Initialize with empty list on error
      setState(() {
        _savedLocations = [];
      });
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;

      // Save times for the previously selected day
      if (_selectedDay != null) {
        _dateTimeSlots[_selectedDay!] =
            _selectedTimes.whereType<TimeOfDay>().toList();
      }

      if (_selectedDays.any((day) => _isSameDay(day, selectedDay))) {
        // If the day is already selected, allow editing or removal
        _showEditOrRemoveDialog(selectedDay);
      } else {
        // Add the new day to selected days
        _selectedDays.add(selectedDay);
      }

      // Update the currently selected day and its times
      _selectedDay = selectedDay;
      _selectedTimes =
          _dateTimeSlots[selectedDay]?.map((e) => e).toList() ?? [null];
    });
  }

  bool _isSameDay(DateTime day1, DateTime day2) {
    return day1.year == day2.year &&
        day1.month == day2.month &&
        day1.day == day2.day;
  }

  void _showEditOrRemoveDialog(DateTime selectedDay) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit or Remove Date'),
          content: const Text(
              'Would you like to edit the time slots or remove this date from the selection?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Remove Date'),
              onPressed: () {
                setState(() {
                  _selectedDays.remove(selectedDay);
                  _dateTimeSlots.remove(selectedDay);
                  if (_selectedDay == selectedDay) {
                    _selectedDay = null;
                    _selectedTimes = [null];
                  }
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Edit Times'),
              onPressed: () {
                setState(() {
                  _selectedDay = selectedDay;
                  _selectedTimes =
                      _dateTimeSlots[selectedDay]?.map((e) => e).toList() ??
                          [null];
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addSelectedTimeSlot() {
    setState(() {
      _selectedTimes.add(null);
    });
  }

  void _onTimeSlotSelected(TimeOfDay? selectedTime, int index) {
    setState(() {
      _selectedTimes[index] = selectedTime;

      if (_selectedDay != null && selectedTime != null) {
        _dateTimeSlots[_selectedDay!] ??= [];
        _dateTimeSlots[_selectedDay!]?.add(selectedTime);
      }
    });
  }

  Future<void> _editLocation(int index) async {
    setState(() {
      _editIndex = index;

      // Load the selected location's data back into the form
      Map<String, dynamic> location = _locations[index];
      List<String> dates = List<String>.from(location['dates']);
      List<Map<String, dynamic>> timeSlots =
          List<Map<String, dynamic>>.from(location['timeSlots']);

      // Populate address fields
      List<String> addressParts = location['address'].split(', ');
      _addressLine1Controller.text = addressParts[0];
      _addressLine2Controller.text =
          addressParts.length > 1 ? addressParts[1] : '';
      _cityController.text = addressParts.length > 2 ? addressParts[2] : '';
      _stateController.text = addressParts.length > 3 ? addressParts[3] : '';
      _postalCodeController.text =
          addressParts.length > 4 ? addressParts[4] : '';

      // Parse the dates using DateFormat
      DateFormat dateFormat = DateFormat('d-M-yyyy'); // Custom date format
      _selectedDays = dates
          .map((dateStr) => dateFormat
              .parse(dateStr)) // Convert custom date format to DateTime
          .toList();

      // Populate the times for the selected dates
      for (var date in _selectedDays) {
        List<String> times = timeSlots
            .firstWhere((slot) => _isSameDay(
                date, DateFormat('d-M-yyyy').parse(slot['date'])))['times']
            .cast<String>();
        _dateTimeSlots[date] = times
            .map((timeStr) => _parseTimeOfDay(timeStr))
            .whereType<TimeOfDay>()
            .toList();
      }

      _isAddingLocation = true;
    });
  }

  TimeOfDay? _parseTimeOfDay(String timeStr) {
    try {
      final format = DateFormat.jm(); // e.g., 08:00 AM
      final dateTime = format.parse(timeStr);
      return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    } catch (e) {
      print('Error parsing time: $timeStr');
      return null;
    }
  }

  Future<void> _saveInspectionDetails() async {
    if (_locations.isEmpty) {
      _showErrorDialog('Please save at least one location.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get a reference to the offer document
      DocumentReference offerRef =
          FirebaseFirestore.instance.collection('offers').doc(widget.offerId);

      // Get the current offer data
      DocumentSnapshot offerDoc = await offerRef.get();

      if (!offerDoc.exists) {
        throw Exception('Offer document not found');
      }

      // Prepare the inspection details
      Map<String, dynamic> updateData = {
        'inspectionDetails': {
          'inspectionLocations': {
            'locations': _locations,
          },
          'status': 'completed',
          'lastUpdated': FieldValue.serverTimestamp(),
        },
      };

      // Update the offer document
      await offerRef.update(updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inspection details saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error saving inspection details: $e');
      _showErrorDialog(
          'Failed to save inspection details. Please check if the offer still exists and try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLocation() async {
    if (_selectedDays.isEmpty) {
      _showErrorDialog('Please select at least one date for this location.');
      return;
    }

    // Collect all dates that are missing time assignments
    List<DateTime> daysMissingTimes = [];
    for (var day in _selectedDays) {
      if (_dateTimeSlots[day] == null || _dateTimeSlots[day]!.isEmpty) {
        daysMissingTimes.add(day);
      }
    }

    if (daysMissingTimes.isNotEmpty) {
      // Format the list of dates to a readable string
      String daysList = daysMissingTimes.map((day) {
        // You can format the date as you prefer
        return DateFormat('dd MMM yyyy').format(day);
      }).join(', ');

      _showErrorDialog(
          'Please assign at least one time for the following dates:\n$daysList');
      return;
    }

    if (_addressLine1Controller.text.isEmpty) {
      _showErrorDialog('Please enter the inspection location.');
      return;
    }
    if (_cityController.text.isEmpty) {
      _showErrorDialog('Please enter City.');
      return;
    }

    if (_stateController.text.isEmpty) {
      _showErrorDialog('Please enter State/Province/Region.');
      return;
    }

    // if (_postalCodeController.text.isEmpty) {
    //   _showErrorDialog('Please enter Postal Code.');
    //   return;
    // }

    // Save the location
    // String fullAddress = '${_addressLine1Controller.text}, '
    //     '${_addressLine2Controller.text.isNotEmpty ? '${_addressLine2Controller.text}, ' : ''}'
    //     '${_cityController.text}, ${_stateController.text}, ${_postalCodeController.text}';

    String fullAddress = _addressLine1Controller.text;

    Map<String, dynamic> locationData = {
      'lat': latLng?.latitude,
      'lng': latLng?.longitude,
      'address': fullAddress,
      'dates': _selectedDays.map((date) => date.toShortString()).toList(),
      'timeSlots': _selectedDays
          .map((date) => {
                'date': date.toShortString(),
                'times': _dateTimeSlots[date]
                    ?.map((time) => time.format(context))
                    .toList(),
              })
          .toList(),
    };

    setState(() {
      if (_editIndex != null) {
        _locations[_editIndex!] = locationData;
        _editIndex = null;
      } else {
        _locations.add(locationData);
      }

      // Clear the input fields and update the UI state
      _clearFields();
      _isAddingLocation = false;
      _showBackToFormButton = true;
    });

    // Save location to Firestore under user's profile
    await _saveLocationToUserProfile({
      'address': fullAddress,
    });
  }

  List<String> predictions = [];

  void fetchPlacesAutocomplete(String input) async {
    final functionUrl = Uri.parse(
      'https://europe-west3-ctp-central-database.cloudfunctions.net/placesAutocomplete?input=$input',
    );

    try {
      final response = await http.get(functionUrl);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['predictions'] != null) {
          predictions = data['predictions']
              .map<String>((prediction) => prediction['description'])
              .toList();
          print('Predictions: $predictions');
        }
      }
    } catch (e) {
      print('Exception: $e');
    }
  }

  Future<void> _saveLocationToUserProfile(
      Map<String, dynamic> locationData) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(userId);

      // First ensure the document exists with an empty savedLocations array
      await userDoc.set({
        'savedLocations': [],
      }, SetOptions(merge: true));

      // Then fetch current data
      DocumentSnapshot userSnapshot = await userDoc.get();
      final data = userSnapshot.data() as Map<String, dynamic>?;
      List<dynamic> existingLocations = data?['savedLocations'] ?? [];

      // Check if location already exists
      bool locationExists = existingLocations
          .any((location) => location['address'] == locationData['address']);

      if (!locationExists) {
        // Update with new location
        await userDoc.update({
          'savedLocations': FieldValue.arrayUnion([locationData]),
        });
      }
    } catch (e) {
      print('Error saving location to user profile: $e');
    }
  }

  void _clearFields() {
    _selectedDays.clear();
    _dateTimeSlots.clear();
    _selectedDay = null;
    _selectedTimes = [null];
    _addressLine1Controller.clear();
    _addressLine2Controller.clear();
    _cityController.clear();
    _stateController.clear();
    _postalCodeController.clear();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Oops!'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Got it'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool isOptional = false,
    bool isEnabled = true,
  }) {
    return TextFormField(
      controller: controller,
      cursorColor: const Color(0xFFFF4E00),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        enabled: isEnabled,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
          borderSide: BorderSide(
            color: Color(0xFFFF4E00),
            width: 2.0,
          ),
        ),
      ),
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (!isOptional && (value == null || value.isEmpty)) {
          return 'Please enter $hintText';
        }
        return null;
      },
    );
  }

  Widget _buildSavedLocationsDropdown() {
    if (_savedLocations.isEmpty) {
      return Container(); // Return empty container if no saved locations
    }

    return DropdownButtonFormField<Map<String, dynamic>>(
      decoration: InputDecoration(
        labelText: 'Select a Saved Location',
        labelStyle: const TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
      ),
      dropdownColor: Colors.black,
      items: _savedLocations.map((location) {
        return DropdownMenuItem<Map<String, dynamic>>(
          value: location,
          child: Text(
            location['address'],
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      onChanged: (Map<String, dynamic>? selectedLocation) {
        if (selectedLocation != null) {
          _populateLocationFields(selectedLocation);
        }
      },
    );
  }

  void _populateLocationFields(Map<String, dynamic> locationData) {
    // Parse the address and populate the controllers
    List<String> addressParts = locationData['address'].split(', ');
    _addressLine1Controller.text = addressParts[0];
    _addressLine2Controller.text =
        addressParts.length > 1 ? addressParts[1] : '';
    _cityController.text = addressParts.length > 2 ? addressParts[2] : '';
    _stateController.text = addressParts.length > 3 ? addressParts[3] : '';
    _postalCodeController.text = addressParts.length > 4 ? addressParts[4] : '';

    // Clear selected days and time slots to allow the user to set new ones
    setState(() {
      _selectedDays.clear();
      _dateTimeSlots.clear();
      _selectedDay = null;
      _selectedTimes = [null];
    });
  }

  Future<List<String>> fetchPlacesAutocompleteWithProxyUrl(String input) async {
    const String proxyUrl =
        "https://europe-west3-ctp-central-database.cloudfunctions.net/placesAutocomplete";

    final response = await http.get(Uri.parse("$proxyUrl?input=$input"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      List<dynamic> predictions = data["predictions"] ?? [];
      return predictions.map((p) => p.toString()).toList();
    } else {
      throw Exception("Failed to fetch autocomplete results");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add UserProvider at the top
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String userRole = userProvider.getUserRole;
    final bool isAdmin = userRole == 'admin'; // Check if the user is an admin
    final bool isDealer = userRole == 'dealer'; // Check if the user is a dealer
    final bool isTransporter =
        userRole == 'transporter'; // Check if the user is a dealer
    const bool isWeb = kIsWeb;

    return GradientBackground(
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
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
                                  bottom: BorderSide(
                                      color: Colors.white24, width: 1),
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
                                          Navigator.pop(context);
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
              body: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: AbsorbPointer(
                              absorbing:
                                  _isLoading, // Prevent interaction when loading
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 80),
                                  Row(
                                    children: [
                                      CustomBackButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    width: 100,
                                    height: 100,
                                    child:
                                        Image.asset('lib/assets/CTPLogo.png'),
                                  ),
                                  const SizedBox(height: 35),
                                  const Text(
                                    'SETUP INSPECTION DETAILS',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 35),
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(width: 5),
                                      SizedBox(
                                        child: Text(
                                          'Provide Details For The Potential Dealer',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 30),
                                  const Text(
                                    'Now, Let\'s Set up a Meeting with the Potential Buyer to Inspect the Vehicle. Your Careful Selection Ensures a Smooth Process Ahead.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 32),
                                  const Text(
                                    'ENTER INSPECTION LOCATION',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),

                                  // Show input fields and calendar only if adding location
                                  if (_isAddingLocation) ...[
                                    // Validation prompts for transporter setup
                                    if (_addressLine1Controller
                                        .text.isEmpty) ...[
                                      Text(
                                        'Please select an inspection location.',
                                        style: TextStyle(
                                            color: Colors.yellow, fontSize: 16),
                                      ),
                                      const SizedBox(height: 8),
                                    ] else if (_selectedDay == null) ...[
                                      Text(
                                        'Please pick a date for inspection.',
                                        style: TextStyle(
                                            color: Colors.yellow, fontSize: 16),
                                      ),
                                      const SizedBox(height: 8),
                                    ] else if (_selectedTimes
                                        .any((t) => t == null)) ...[
                                      Text(
                                        'Please select at least one time slot.',
                                        style: TextStyle(
                                            color: Colors.yellow, fontSize: 16),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    // _buildSavedLocationsDropdown(),
                                    PlacesSearchField(
                                      controller: _addressLine1Controller,
                                      onSuggestionSelected:
                                          (PlacesData p) async {
                                        log("Suggestion Selected: \\${p.description}");
                                        setState(() {
                                          isAddressSelected = true;
                                          _addressLine1Controller.text =
                                              p.description ?? '';
                                          print(
                                              "Address1controller: \\${_addressLine1Controller.text}");
                                        });
                                        print(
                                            "Address1Controller: \\${_addressLine1Controller.text}");
                                        Map<String, dynamic> latLngData =
                                            await PlacesService.getPlaceLatLng(
                                                p.placeId!);
                                        print("LatLngData: \\$latLngData");
                                        latLng = LatLng(
                                          latLngData['lat'],
                                          latLngData['lng'],
                                        );
                                        _cityController.text =
                                            latLngData['city'];
                                        _stateController.text =
                                            latLngData['state'];
                                        _postalCodeController.text =
                                            latLngData["postalCode"];
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    // Removed duplicate Address Line 1 field to avoid confusion
                                    // _buildTextField(
                                    //   controller: _addressLine1Controller,
                                    //   hintText: 'Address Line 1',
                                    // ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      controller: _addressLine2Controller,
                                      hintText: 'Suburb (Optional)',
                                      isOptional: true,
                                      isEnabled: !isAddressSelected,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      controller: _cityController,
                                      hintText: 'City',
                                      isEnabled: !isAddressSelected,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      controller: _stateController,
                                      hintText: 'State/Province/Region',
                                    ),
                                    const SizedBox(height: 32),

                                    const Text(
                                      'SELECT AVAILABLE DATES AND TIMES',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),

                                    // Calendar
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: TableCalendar(
                                        firstDay: DateTime.utc(2020, 1, 1),
                                        lastDay: DateTime.utc(2100, 1, 1),
                                        focusedDay: _focusedDay,
                                        calendarFormat: _calendarFormat,
                                        selectedDayPredicate: (day) {
                                          return _selectedDays.any(
                                              (selectedDay) =>
                                                  _isSameDay(day, selectedDay));
                                        },
                                        onDaySelected: _onDaySelected,

                                        // Here we limit the enabled days to only the first 7 days starting from availability date
                                        enabledDayPredicate: (day) {
                                          DateTime endDay =
                                              _availabilityDate.add(Duration(
                                                  days: _daysAvailable));
                                          return day.isAfter(
                                                  _availabilityDate.subtract(
                                                      Duration(days: 1))) &&
                                              day.isBefore(endDay
                                                  .add(Duration(days: 1)));
                                        },

                                        calendarStyle: CalendarStyle(
                                          selectedDecoration:
                                              const BoxDecoration(
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
                                            color: Colors.grey[800],
                                            shape: BoxShape.rectangle,
                                          ),
                                          defaultTextStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          weekendDecoration: BoxDecoration(
                                            color: Colors.grey[800],
                                            shape: BoxShape.rectangle,
                                          ),
                                          weekendTextStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          outsideDaysVisible: false,
                                          disabledDecoration:
                                              const BoxDecoration(
                                            color: Colors.transparent,
                                            shape: BoxShape.rectangle,
                                          ),
                                          markerDecoration: const BoxDecoration(
                                            color: Colors.transparent,
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
                                    // Time slots for selected day
                                    if (_selectedDay != null) ...[
                                      Text(
                                        'Set Times for ${_selectedDay?.toLocal().toShortString()}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Column(
                                        children: _selectedTimes
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          int index = entry.key;
                                          TimeOfDay? selectedTime = entry.value;
                                          return DropdownButton<TimeOfDay>(
                                            value: selectedTime,
                                            hint: const Text(
                                              'Select Time Slot',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            dropdownColor: Colors.black,
                                            items: _timeSlots
                                                .map((TimeOfDay time) {
                                              return DropdownMenuItem<
                                                  TimeOfDay>(
                                                value: time,
                                                child: Text(
                                                  time.format(context),
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (TimeOfDay? newValue) {
                                              _onTimeSlotSelected(
                                                  newValue, index);
                                            },
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 8),
                                      CustomButton(
                                        text: 'Add Another Time Slot',
                                        borderColor: Colors.blue,
                                        onPressed: _addSelectedTimeSlot,
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                  ],

                                  // Display saved locations after the form is hidden
                                  if (_locations.isNotEmpty &&
                                      !_isAddingLocation)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: _locations
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        int index = entry.key;
                                        Map<String, dynamic> location =
                                            entry.value;
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    'Location ${index + 1}: ${location['address']}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 3,
                                                    softWrap: true,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Colors.orange,
                                                  ),
                                                  onPressed: () =>
                                                      _editLocation(index),
                                                ),
                                              ],
                                            ),
                                            ...location['timeSlots']
                                                .map<Widget>((timeSlot) {
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 4.0),
                                                child: Text(
                                                  'Date: ${timeSlot['date']}, Times: ${timeSlot['times'].join(', ')}',
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            const Divider(
                                              color: Colors.white,
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  const SizedBox(height: 16),

                                  // Save Setup Details button (when adding location)
                                  if (_isAddingLocation)
                                    CustomButton(
                                      text: 'Save Setup Details',
                                      borderColor: Colors.blue,
                                      onPressed: _saveLocation,
                                    ),

                                  // Add Another Location button (shown after saving the current location)
                                  if (!_isAddingLocation)
                                    CustomButton(
                                      text: 'Add Another Location',
                                      borderColor: Colors.blue,
                                      onPressed: () {
                                        setState(() {
                                          _isAddingLocation = true;
                                          _clearFields(); // Clear fields for the next location
                                        });
                                      },
                                    ),

                                  const SizedBox(height: 16),

                                  // Save Setup Details button
                                  if (_showBackToFormButton)
                                    CustomButton(
                                      text: 'Save Setup Details',
                                      borderColor: const Color(0xFFFF4E00),
                                      onPressed: () {
                                        _saveInspectionDetails();
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Remove the CustomBottomNavigation widget
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Image.asset(
                  'lib/assets/Loading_Logo_CTP.gif',
                  width: 100,
                  height: 100,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Extension method to format DateTime to a short string
extension DateTimeExtension on DateTime {
  String toShortString() {
    return '$day-$month-$year';
  }
}
