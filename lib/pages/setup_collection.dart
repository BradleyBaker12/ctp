import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import 'package:intl/intl.dart'; // For date/time formatting
import 'package:table_calendar/table_calendar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';

class SetupCollectionPage extends StatefulWidget {
  final String vehicleId;

  const SetupCollectionPage({super.key, required this.vehicleId});

  @override
  _SetupCollectionPageState createState() => _SetupCollectionPageState();
}

class _SetupCollectionPageState extends State<SetupCollectionPage> {
  DateTime _focusedDay = DateTime.now();
  List<DateTime> _selectedDays = [];
  DateTime? _selectedDay;
  final CalendarFormat _calendarFormat = CalendarFormat.month;

  // Map to store times for each selected date
  final Map<DateTime, List<TimeOfDay>> _dateTimeSlots = {};

  // List of time dropdowns for the current day
  List<TimeOfDay?> _selectedTimes = [null];

  // Predefined time slots in 24-hour increments
  // Adjust these slots to match any times you expect from Firestore.
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
    // Add a 13:00 slot since Firestore has times like "13:00"
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
  // Store information for multiple collection locations
  final List<Map<String, dynamic>> _locations = [];
  int? _editIndex;

  // Controllers for address input fields
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  bool _isAddingLocation = true;
  bool _showBackToFormButton = false;
  bool _isLoading = false;
  bool _useInspectionDetails = false;
  bool _offerDeliveryOption = false;
  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
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
        _showEditOrRemoveDialog(selectedDay);
      } else {
        _selectedDays.add(selectedDay);
      }

      _selectedDay = selectedDay;
      _selectedTimes =
          _dateTimeSlots[selectedDay]?.map((e) => e).toList() ?? [null];

      // If no time selected, choose the first time slot by default
      if (_selectedTimes.isEmpty || _selectedTimes.first == null) {
        _selectedTimes[0] = _timeSlots.first;
      }
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

                  if (_selectedTimes.isEmpty || _selectedTimes.first == null) {
                    _selectedTimes[0] = _timeSlots.first;
                  }
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
      // Add another time slot with a default first slot selected
      _selectedTimes.add(_timeSlots.first);
    });
  }

  void _onTimeSlotSelected(TimeOfDay? selectedTime, int index) {
    setState(() {
      _selectedTimes[index] = selectedTime;
      if (_selectedDay != null && selectedTime != null) {
        _dateTimeSlots[_selectedDay!] ??= [];
        // Ensure we set the correct index if we're adding time slots dynamically
        if (_dateTimeSlots[_selectedDay!]!.length <= index) {
          // Extend the list if necessary
          _dateTimeSlots[_selectedDay!]!.addAll(List.filled(
              index - _dateTimeSlots[_selectedDay!]!.length + 1,
              _timeSlots.first));
        }
        _dateTimeSlots[_selectedDay!]![index] = selectedTime;
      }
    });
  }

  DateTime _parseDateString(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) throw FormatException("Invalid date format");
    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);
    return DateTime(year, month, day);
  }

  Future<void> _editLocation(int index) async {
    setState(() {
      _editIndex = index;
      Map<String, dynamic> location = _locations[index];
      List<String> dates = List<String>.from(location['dates']);
      List<Map<String, dynamic>> timeSlots =
          List<Map<String, dynamic>>.from(location['timeSlots']);

      List<String> addressParts = location['address'].split(', ');
      _addressLine1Controller.text =
          addressParts.isNotEmpty ? addressParts[0] : '';
      _addressLine2Controller.text =
          addressParts.length > 1 ? addressParts[1] : '';
      _cityController.text = addressParts.length > 2 ? addressParts[2] : '';
      _stateController.text = addressParts.length > 3 ? addressParts[3] : '';
      _postalCodeController.text =
          addressParts.length > 4 ? addressParts[4] : '';

      _selectedDays =
          dates.map((dateStr) => _parseDateString(dateStr)).toList();

      _dateTimeSlots.clear();
      for (var date in _selectedDays) {
        List<String> times = timeSlots
            .firstWhere((slot) => slot['date'] == date.toShortString())['times']
            .cast<String>();
        _dateTimeSlots[date] = times
            .map((timeStr) => _parseTimeOfDay(timeStr))
            .whereType<TimeOfDay>()
            .toList();
      }

      if (_selectedDays.isNotEmpty) {
        _selectedDay = _selectedDays.first;
        _selectedTimes =
            _dateTimeSlots[_selectedDay!]?.map((e) => e).toList() ?? [null];

        // If no time selected, choose the first time slot by default
        if (_selectedTimes.isEmpty || _selectedTimes.first == null) {
          _selectedTimes[0] = _timeSlots.first;
        }
      }

      _isAddingLocation = true;
    });
  }

  // Updated parser to handle 24-hour format like "13:00"
  TimeOfDay? _parseTimeOfDay(String timeStr) {
    try {
      final format = DateFormat("HH:mm"); // 24-hour format
      final dateTime = format.parse(timeStr);
      return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
    } catch (e) {
      print('Error parsing time: $timeStr, $e');
      return null;
    }
  }

  Future<void> _saveCollectionDetails() async {
    if (_locations.isNotEmpty) {
      Map<String, dynamic> collectionDetails = {
        'collectionDetails': {
          'collectionLocations': {
            'locations': _locations,
          },
        },
        'offerDeliveryService': _offerDeliveryOption,
      };

      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.vehicleId)
            .update(collectionDetails);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collection details saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      } catch (e) {
        _showErrorDialog(
            'Failed to save collection details. Please try again.');
        print('Error saving collection details: $e');
      } finally {
        setState(() {
          _isLoading = false;
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

    // Check if each selected day has at least one time slot
    List<DateTime> daysMissingTimes = [];
    for (var day in _selectedDays) {
      if (_dateTimeSlots[day] == null || _dateTimeSlots[day]!.isEmpty) {
        daysMissingTimes.add(day);
      }
    }

    if (daysMissingTimes.isNotEmpty) {
      String daysList = daysMissingTimes.map((day) {
        return DateFormat('dd MMM yyyy').format(day);
      }).join(', ');

      _showErrorDialog(
          'Please assign at least one time for the following dates:\n$daysList');
      return;
    }

    if (_addressLine1Controller.text.isEmpty) {
      _showErrorDialog('Please enter the collection location.');
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

      _clearFields();
      _isAddingLocation = false;
      _showBackToFormButton = true;
    });
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

  void _addAnotherLocation() {
    setState(() {
      _isAddingLocation = true;
      _clearFields();
    });
  }

  Future<void> _populateFromInspectionDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .get();

      if (!doc.exists) {
        _showErrorDialog('No inspection details found for this vehicle.');
        setState(() {
          _useInspectionDetails = false;
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic>? inspectionData =
          doc.data() as Map<String, dynamic>?;

      if (inspectionData == null ||
          inspectionData['inspectionDetails'] == null ||
          inspectionData['inspectionDetails']['inspectionLocations'] == null ||
          inspectionData['inspectionDetails']['inspectionLocations']
                  ['locations'] ==
              null ||
          (inspectionData['inspectionDetails']['inspectionLocations']
                  ['locations'] as List)
              .isEmpty) {
        _showErrorDialog('No inspection details available to copy.');
        setState(() {
          _useInspectionDetails = false;
          _isLoading = false;
        });
        return;
      }

      List locations = inspectionData['inspectionDetails']
          ['inspectionLocations']['locations'];

      Map<String, dynamic> inspectionLocation = locations.first;

      _clearFields();
      _locations.clear();

      String address = inspectionLocation['address'];
      List<String> addressParts = address.split(', ');
      _addressLine1Controller.text =
          addressParts.isNotEmpty ? addressParts[0] : '';
      _addressLine2Controller.text =
          addressParts.length > 1 ? addressParts[1] : '';
      _cityController.text = addressParts.length > 2 ? addressParts[2] : '';
      _stateController.text = addressParts.length > 3 ? addressParts[3] : '';
      _postalCodeController.text =
          addressParts.length > 4 ? addressParts[4] : '';

      List dates = inspectionLocation['dates'];
      _selectedDays =
          dates.map((dateStr) => _parseDateString(dateStr)).toList();

      _dateTimeSlots.clear();
      for (var timeSlotData in inspectionLocation['timeSlots']) {
        DateTime date = _parseDateString(timeSlotData['date']);
        List times = timeSlotData['times'];
        _dateTimeSlots[date] = times
            .map((timeStr) => _parseTimeOfDay(timeStr))
            .whereType<TimeOfDay>()
            .toList();
      }

      if (_selectedDays.isNotEmpty) {
        _selectedDay = _selectedDays.first;
        _selectedTimes = _dateTimeSlots[_selectedDay!] ?? [null];
        // If no time selected, choose the first time slot by default
        if (_selectedTimes.isEmpty || _selectedTimes.first == null) {
          _selectedTimes[0] = _timeSlots.first;
        }
      }

      _isAddingLocation = true;
      _showBackToFormButton = true;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching inspection details: $e');
      _showErrorDialog('Failed to fetch inspection details.');
      setState(() {
        _useInspectionDetails = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GradientBackground(
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
                              CheckboxListTile(
                                title: const Text(
                                  "Use the same details as the inspection?",
                                  style: TextStyle(color: Colors.white),
                                ),
                                value: _useInspectionDetails,
                                activeColor: Colors.blue,
                                onChanged: (bool? value) async {
                                  if (value == true) {
                                    _useInspectionDetails = true;
                                    await _populateFromInspectionDetails();
                                  } else {
                                    setState(() {
                                      _useInspectionDetails = false;
                                      _clearFields();
                                      _locations.clear();
                                      _isAddingLocation = true;
                                      _showBackToFormButton = false;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                              CheckboxListTile(
                                title: const Text(
                                  "Offer delivery service to dealer's preferred address?",
                                  style: TextStyle(color: Colors.white),
                                ),
                                value: _offerDeliveryOption,
                                activeColor: Colors.blue,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _offerDeliveryOption = value ?? false;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
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
                              if (_isAddingLocation) ...[
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
                                      return Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Colors.white,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: DropdownButton<TimeOfDay>(
                                          value: selectedTime,
                                          hint: const Text(
                                            'Select Time Slot',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          dropdownColor: Colors.black,
                                          underline: const SizedBox(),
                                          iconEnabledColor: Colors.white,
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
                                        ),
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
                              if (_locations.isNotEmpty && !_isAddingLocation)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children:
                                      _locations.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    Map<String, dynamic> location = entry.value;
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
                                              onPressed: () =>
                                                  _editLocation(index),
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
                              if (_isAddingLocation)
                                CustomButton(
                                  text: 'Save Collection Details',
                                  borderColor: Colors.blue,
                                  onPressed: _saveLocation,
                                ),
                              if (!_isAddingLocation)
                                CustomButton(
                                  text: 'Add Another Location',
                                  borderColor: Colors.blue,
                                  onPressed: _addAnotherLocation,
                                ),
                              const SizedBox(height: 16),
                              if (_showBackToFormButton)
                                CustomButton(
                                  text: 'Save Collection Details',
                                  borderColor: const Color(0xFFFF4E00),
                                  onPressed: () {
                                    _saveCollectionDetails();
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
              ],
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: Image.asset(
                  'lib/assets/Loading_Logo_CTP.gif',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
      ],
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
}

extension DateTimeExtension on DateTime {
  String toShortString() {
    return '$day-$month-$year';
  }
}
