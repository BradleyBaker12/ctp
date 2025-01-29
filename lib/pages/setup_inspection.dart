import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase Auth

class SetupInspectionPage extends StatefulWidget {
  final String vehicleId;

  const SetupInspectionPage({super.key, required this.vehicleId});

  @override
  _SetupInspectionPageState createState() => _SetupInspectionPageState();
}

class _SetupInspectionPageState extends State<SetupInspectionPage> {
  DateTime _focusedDay = DateTime.now();
  List<DateTime> _selectedDays = [];
  DateTime? _selectedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.month;

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
        List<dynamic> savedLocations = userDoc.get('savedLocations') ?? [];
        setState(() {
          _savedLocations = List<Map<String, dynamic>>.from(savedLocations);
        });
      }
    } catch (e) {
      print('Error fetching saved locations: $e');
      // Handle errors appropriately
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
    if (_locations.isNotEmpty) {
      // Prepare the data to save under 'inspectionDetails' -> 'inspectionLocations' -> 'locations'
      Map<String, dynamic> inspectionDetails = {
        'inspectionDetails': {
          'inspectionLocations': {
            'locations': _locations,
          },
        },
      };

      setState(() {
        _isLoading = true; // Start loading
      });

      try {
        // Save the inspection details to the vehicle document in Firestore
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.vehicleId)
            .update(inspectionDetails);

        // Optionally, navigate back or show a confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inspection details saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        _showErrorDialog(
            'Failed to save inspection details. Please try again.');
        print('Error saving inspection details: $e');
      } finally {
        setState(() {
          _isLoading = false; // Stop loading
        });
      }
    } else {
      _showErrorDialog('Please save at least one location.');
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

    if (_postalCodeController.text.isEmpty) {
      _showErrorDialog('Please enter Postal Code.');
      return;
    }

    // Save the location
    String fullAddress = '${_addressLine1Controller.text}, '
        '${_addressLine2Controller.text.isNotEmpty ? '${_addressLine2Controller.text}, ' : ''}'
        '${_cityController.text}, ${_stateController.text}, ${_postalCodeController.text}';

    Map<String, dynamic> locationData = {
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

  Future<void> _saveLocationToUserProfile(
      Map<String, dynamic> locationData) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentReference userDoc =
          FirebaseFirestore.instance.collection('users').doc(userId);

      // Fetch existing saved locations
      DocumentSnapshot userSnapshot = await userDoc.get();
      List<dynamic> existingLocations =
          userSnapshot.get('savedLocations') ?? [];

      // Check if the location already exists
      bool locationExists = existingLocations
          .any((location) => location['address'] == locationData['address']);

      if (!locationExists) {
        await userDoc.set({
          'savedLocations': FieldValue.arrayUnion([locationData]),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error saving location to user profile: $e');
      // Handle errors appropriately
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
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
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
  }) {
    return TextFormField(
      controller: controller,
      cursorColor: const Color(0xFFFF4E00),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
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

  @override
  Widget build(BuildContext context) {
    // Add UserProvider at the top
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String userRole = userProvider.getUserRole;
    final bool isAdmin = userRole == 'admin'; // Check if the user is an admin
    final bool isDealer = userRole == 'dealer'; // Check if the user is a dealer
    final bool isTransporter =
        userRole == 'transporter'; // Check if the user is a dealer
    return GradientBackground(
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: Stack(
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
                                  child: Image.asset('lib/assets/CTPLogo.png'),
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
                                  'Now, Let\'s Set up a Meeting with the Potential Seller to Inspect the Vehicle. Your Careful Selection Ensures a Smooth Process Ahead.',
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
                                  _buildSavedLocationsDropdown(),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _addressLine1Controller,
                                    hintText: 'Address Line 1',
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _addressLine2Controller,
                                    hintText: 'Suburb (Optional)',
                                    isOptional: true,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _cityController,
                                    hintText: 'City',
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _stateController,
                                    hintText: 'State/Province/Region',
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _postalCodeController,
                                    hintText: 'Postal Code',
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
                                        DateTime endDay = _availabilityDate.add(
                                            Duration(days: _daysAvailable));
                                        return day.isAfter(_availabilityDate
                                                .subtract(Duration(days: 1))) &&
                                            day.isBefore(
                                                endDay.add(Duration(days: 1)));
                                      },

                                      calendarStyle: CalendarStyle(
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
                                        disabledDecoration: const BoxDecoration(
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
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          dropdownColor: Colors.black,
                                          items:
                                              _timeSlots.map((TimeOfDay time) {
                                            return DropdownMenuItem<TimeOfDay>(
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
                                if (_locations.isNotEmpty && !_isAddingLocation)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        _locations.asMap().entries.map((entry) {
                                      int index = entry.key;
                                      Map<String, dynamic> location =
                                          entry.value;
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  'Location ${index + 1}: ${location['address']}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
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
                    if (!isAdmin)
                      CustomBottomNavigation(
                        selectedIndex: 1,
                        onItemTapped: (int) {},
                      ),
                  ],
                ),
              ],
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
