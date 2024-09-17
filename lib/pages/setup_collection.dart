import 'package:flutter/material.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:table_calendar/table_calendar.dart';
// import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart'; // Import intl package to handle custom date formats

class SetupCollectionPage extends StatefulWidget {
  @override
  _SetupCollectionPageState createState() => _SetupCollectionPageState();
}

class _SetupCollectionPageState extends State<SetupCollectionPage> {
  DateTime _focusedDay = DateTime.now();
  List<DateTime> _selectedDays = [];
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Map to store times for each selected date
  Map<DateTime, List<TimeOfDay>> _dateTimeSlots = {};

  // List of time dropdowns for the current day
  List<TimeOfDay?> _selectedTimes = [null];

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
  List<Map<String, dynamic>> _locations = [];
  int? _editIndex;

  // Controllers for address input fields
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (_selectedDay != null &&
        (_dateTimeSlots[_selectedDay!] == null ||
            _dateTimeSlots[_selectedDay!]!.isEmpty)) {
      _showTimeRequiredDialog();
      return;
    }

    setState(() {
      _focusedDay = focusedDay;

      if (_selectedDays.any((day) => _isSameDay(day, selectedDay))) {
        _showEditOrRemoveDialog(selectedDay);
      } else {
        if (_selectedDay != null) {
          _dateTimeSlots[_selectedDay!] =
              _selectedTimes.whereType<TimeOfDay>().toList();
        }

        _selectedTimes = [null];

        _selectedDays.add(selectedDay);
      }

      _selectedDay = selectedDay;
    });
  }

  bool _isSameDay(DateTime day1, DateTime day2) {
    return day1.year == day2.year &&
        day1.month == day2.month &&
        day1.day == day2.day;
  }

  void _showTimeRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Time Required'),
          content: const Text(
              'Please add at least one time for the selected date before selecting another date.'),
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
                  _selectedTimes = _dateTimeSlots[selectedDay] != null
                      ? _dateTimeSlots[selectedDay]!.map((e) => e).toList()
                      : [null];
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveCollectionDetails() async {
    if (_locations.isNotEmpty) {
      // Prepare the data to pass back
      Map<String, dynamic> collectionDetails = {
        'locations': _locations,
      };

      // Return the collection details to the previous page
      Navigator.pop(context, collectionDetails);
    } else {
      _showErrorDialog('Please save at least one location.');
    }
  }

  Future<void> _saveLocation() async {
    if (_selectedDays.isEmpty || _dateTimeSlots.isEmpty) {
      _showErrorDialog(
          'Please select at least one date and time for this location.');
      return;
    }

    if (_addressLine1Controller.text.isEmpty) {
      _showErrorDialog('Please enter the collection location.');
      return;
    }

    // Concatenate address into one line
    String fullAddress =
        '${_addressLine1Controller.text}, ${_addressLine2Controller.text.isNotEmpty ? _addressLine2Controller.text + ', ' : ''}${_cityController.text}, ${_stateController.text}, ${_postalCodeController.text}';

    Map<String, dynamic> locationData = {
      'address': fullAddress,
      'dates': _selectedDays.map((date) => date.toShortString()).toList(),
      'timeSlots': _selectedDays
          .map((date) => {
                'date': date.toShortString(),
                'times': _dateTimeSlots[date]
                    ?.map((time) => time.format(context))
                    .toList()
              })
          .toList(),
    };

    setState(() {
      if (_editIndex != null) {
        // If we are editing a location, update it
        _locations[_editIndex!] = locationData;
        _editIndex = null; // Reset edit mode
      } else {
        // Otherwise, add a new location
        _locations.add(locationData);
      }

      // Clear fields for the next location
      _selectedDays.clear();
      _dateTimeSlots.clear();
      _selectedDay = null;
      _selectedTimes = [null];
      _addressLine1Controller.clear();
      _addressLine2Controller.clear();
      _cityController.clear();
      _stateController.clear();
      _postalCodeController.clear();
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
            .firstWhere((slot) => slot['date'] == date.toShortString())['times']
            .cast<String>();
        _dateTimeSlots[date] = times
            .map((timeStr) => TimeOfDay(
                hour: int.parse(timeStr.split(':')[0]),
                minute: int.parse(timeStr.split(':')[1].split(' ')[0])))
            .toList();
      }
    });
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

  @override
  Widget build(BuildContext context) {
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
                            child: Image.asset('lib/assets/CTPLogo.png'),
                          ),
                          const SizedBox(height: 35),
                          const Text(
                            'SETUP COLLECTION DETAILS',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'Please provide the necessary details for the collection of the vehicle. Your careful selection ensures a smooth process ahead.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),

                          const Text(
                            'ENTER COLLECTION LOCATION',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                              controller: _addressLine1Controller,
                              hintText: 'Address Line 1'),
                          const SizedBox(height: 16),
                          _buildTextField(
                              controller: _addressLine2Controller,
                              hintText: 'Suburb (Optional)',
                              isOptional: true),
                          const SizedBox(height: 16),
                          _buildTextField(
                              controller: _cityController, hintText: 'City'),
                          const SizedBox(height: 16),
                          _buildTextField(
                              controller: _stateController,
                              hintText: 'State/Province/Region'),
                          const SizedBox(height: 16),
                          _buildTextField(
                              controller: _postalCodeController,
                              hintText: 'Postal Code'),
                          const SizedBox(height: 32),

                          const Text(
                            'SELECT AVAILABLE DATES AND TIMES FOR COLLECTION',
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
                              calendarFormat: _calendarFormat,
                              selectedDayPredicate: (day) {
                                return _selectedDays.any((selectedDay) =>
                                    _isSameDay(day, selectedDay));
                              },
                              onDaySelected: _onDaySelected,
                              enabledDayPredicate: (day) => day.isAfter(
                                  DateTime.now()
                                      .subtract(const Duration(days: 1))),
                              calendarStyle: CalendarStyle(
                                selectedDecoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.rectangle,
                                ),
                                todayDecoration: BoxDecoration(
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
                                disabledDecoration: BoxDecoration(
                                  color: Colors.transparent,
                                  shape: BoxShape.rectangle,
                                ),
                                markerDecoration: const BoxDecoration(
                                  color: Colors.transparent,
                                ),
                              ),
                              headerStyle: HeaderStyle(
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
                              daysOfWeekStyle: DaysOfWeekStyle(
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
                              children:
                                  _selectedTimes.asMap().entries.map((entry) {
                                int index = entry.key;
                                TimeOfDay? selectedTime = entry.value;
                                return DropdownButton<TimeOfDay>(
                                  value: selectedTime,
                                  hint: const Text(
                                    'Select Time Slot',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  dropdownColor: Colors.black,
                                  items: _timeSlots.map((TimeOfDay time) {
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
                                    _onTimeSlotSelected(newValue, index);
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

                          // Display saved locations above Confirm Meeting button
                          if (_locations.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _locations.asMap().entries.map((entry) {
                                int index = entry.key;
                                Map<String, dynamic> location = entry.value;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 3,
                                            softWrap: true,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.orange,
                                          ),
                                          onPressed: () => _editLocation(index),
                                        ),
                                      ],
                                    ),
                                    ...location['timeSlots']
                                        .map<Widget>((timeSlot) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
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

                          CustomButton(
                            text: 'Save Collection Details',
                            borderColor: Colors.blue,
                            onPressed: _saveLocation,
                          ),

                          const SizedBox(height: 16),

                          CustomButton(
                            text: 'Back to Form',
                            borderColor: Color(0xFFFF4E00),
                            onPressed: () async {
                              await _saveCollectionDetails();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                CustomBottomNavigation(
                  selectedIndex: 1,
                  onItemTapped: (int) {},
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
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
}

extension on DateTime {
  String toShortString() {
    return '${this.day}-${this.month}-${this.year}';
  }
}
