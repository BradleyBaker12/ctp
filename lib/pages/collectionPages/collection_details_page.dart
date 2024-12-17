import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/pages/collectionPages/collection_confirmationPage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

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
  bool _isLoading = true;

  List<String> _locations = [];
  List<String> _addresses = [];
  List<List<DateTime>> _locationDates = [];
  List<List<Map<String, dynamic>>> _locationTimeSlots = [];
  List<LatLng> _latLngs = [];

  bool _offerDeliveryService = false;
  int _selectedDeliveryOption = 0; // 0 = Collect, 1 = Deliver
  bool _showCollectionDetails = false;

  // Delivery address controllers
  final TextEditingController _deliveryAddressLine1Controller =
      TextEditingController();
  final TextEditingController _deliveryAddressLine2Controller =
      TextEditingController();
  final TextEditingController _deliveryCityController = TextEditingController();
  final TextEditingController _deliveryStateController =
      TextEditingController();
  final TextEditingController _deliveryPostalCodeController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCollectionLocations();
  }

  Future<void> _fetchCollectionLocations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .get();

      if (!offerSnapshot.exists) {
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

      Map<String, dynamic>? offerData =
          offerSnapshot.data() as Map<String, dynamic>?;
      String? vehicleId = offerData?['vehicleId'];

      if (vehicleId == null || vehicleId.isEmpty) {
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

      DocumentSnapshot vehicleSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      if (!vehicleSnapshot.exists) {
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

      Map<String, dynamic>? vehicleData =
          vehicleSnapshot.data() as Map<String, dynamic>?;
      var collectionLocations = vehicleData?['collectionDetails']
          ?['collectionLocations']?['locations'] as List<dynamic>?;

      bool offerDeliveryService = vehicleData?['offerDeliveryService'] ?? false;

      if (collectionLocations == null || collectionLocations.isEmpty) {
        setState(() {
          _offerDeliveryService = offerDeliveryService;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No collection locations available for this offer.'),
          ),
        );
        return;
      }

      List<String> locations = [];
      List<String> addresses = [];
      List<List<DateTime>> locationDates = [];
      List<List<Map<String, dynamic>>> locationTimeSlots = [];
      List<LatLng> latLngs = [];

      for (var locationEntry in collectionLocations) {
        if (locationEntry == null) continue;

        String address = locationEntry['address'] ?? '';
        List<dynamic> timeSlots = locationEntry['timeSlots'] ?? [];

        if (address.isEmpty || timeSlots.isEmpty) {
          continue;
        }

        List<DateTime> dates = [];
        List<Map<String, dynamic>> timeSlotsList = [];

        for (var timeSlot in timeSlots) {
          if (timeSlot == null) continue;

          String? dateString = timeSlot['date'];
          if (dateString == null) continue;

          DateTime date;
          try {
            date = DateFormat('d-M-yyyy').parse(dateString);
          } catch (e) {
            continue;
          }

          if (!dates.contains(date)) {
            dates.add(date);
          }

          List<dynamic> times = timeSlot['times'] ?? [];
          if (times.isEmpty) {
            continue;
          }

          timeSlotsList.add({
            'date': date,
            'times': times,
          });
        }

        if (dates.isEmpty || timeSlotsList.isEmpty) {
          continue;
        }

        locations.add(address);
        addresses.add(address);
        locationDates.add(dates);
        locationTimeSlots.add(timeSlotsList);

        try {
          List<Location> geoLocations = await locationFromAddress(address);
          if (geoLocations.isNotEmpty) {
            final location = geoLocations.first;
            latLngs.add(LatLng(location.latitude, location.longitude));
          } else {
            latLngs.add(const LatLng(0, 0));
          }
        } catch (e) {
          latLngs.add(const LatLng(0, 0));
        }
      }

      if (locations.isEmpty) {
        setState(() {
          _offerDeliveryService = offerDeliveryService;
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

      _focusedDay = firstAvailableDate ?? DateTime.now();
      _selectedDay = _focusedDay;

      setState(() {
        _locations = locations;
        _addresses = addresses;
        _locationDates = locationDates;
        _locationTimeSlots = locationTimeSlots;
        _latLngs = latLngs;
        _offerDeliveryService = offerDeliveryService;
        _isLoading = false;
      });
    } catch (e) {
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

  int get _currentLocationIndex {
    if (_selectedDeliveryOption == 1) {
      // For delivery, use times from the first location as an example
      return 0;
    } else {
      return _selectedLocation;
    }
  }

  List<String> get _availableTimes {
    if (_selectedDay != null &&
        _locationTimeSlots.isNotEmpty &&
        _currentLocationIndex < _locationTimeSlots.length) {
      final normalizedSelectedDay = _normalizeDate(_selectedDay!);
      List<Map<String, dynamic>> timeSlots =
          _locationTimeSlots[_currentLocationIndex];
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

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool isDateAvailable(DateTime day) {
    if (_locationDates.isEmpty ||
        _currentLocationIndex >= _locationDates.length ||
        _locationDates[_currentLocationIndex].isEmpty) {
      return false;
    }
    DateTime checkDay = _normalizeDate(day);
    List<DateTime> dates = _locationDates[_currentLocationIndex];
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
        'dealerSelectedDelivery': false,
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

  Future<void> _saveDeliveryDetails() async {
    // Validate required fields
    if (_deliveryAddressLine1Controller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Address Line 1.')),
      );
      return;
    }
    if (_deliveryCityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter City.')),
      );
      return;
    }
    if (_deliveryStateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter State/Province/Region.')),
      );
      return;
    }
    if (_deliveryPostalCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Postal Code.')),
      );
      return;
    }

    // Validate date/time
    if (_selectedDay == null || _availableTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String fullDeliveryAddress = '${_deliveryAddressLine1Controller.text}, '
        '${_deliveryAddressLine2Controller.text.isNotEmpty ? '${_deliveryAddressLine2Controller.text}, ' : ''}'
        '${_deliveryCityController.text}, ${_deliveryStateController.text}, ${_deliveryPostalCodeController.text}';

    try {
      final DocumentReference offerRef =
          FirebaseFirestore.instance.collection('offers').doc(widget.offerId);

      await offerRef.set({
        'dealerSelectedDelivery': true,
        'transporterDeliveryAddress': fullDeliveryAddress,
        'dealerSelectedDeliveryDate': _selectedDay,
        'dealerSelectedDeliveryTime': _availableTimes[_selectedTimeSlot],
      }, SetOptions(merge: true));

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CollectionConfirmationPage(
            offerId: widget.offerId,
            location: fullDeliveryAddress,
            address: fullDeliveryAddress,
            date: _selectedDay!,
            time: _availableTimes[_selectedTimeSlot],
            latLng: null,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save delivery details: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildCollectionPage(List<String> monthNames) {
    if (_locations.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Waiting for collection locations from transporter.',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'HOME',
                        onPressed: () => Navigator.of(context)
                            .pushNamedAndRemoveUntil('/', (route) => false),
                        borderColor: const Color(0xFFFF4E00),
                      ),
                    ],
                  ),
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
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 80.0, 16.0, 16.0),
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
                            availableGestures: AvailableGestures.verticalSwipe,
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
                        if (_selectedDay != null && _availableTimes.isNotEmpty)
                          Column(
                            children: [
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
                                  },
                                ).toList(),
                              ),
                            ],
                          ),
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
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4E00)),
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
    );
  }

  Widget _buildDeliveryAddressForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ENTER DELIVERY ADDRESS',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _deliveryAddressLine1Controller,
          hintText: 'Address Line 1',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _deliveryAddressLine2Controller,
          hintText: 'Suburb (Optional)',
          isOptional: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _deliveryCityController,
          hintText: 'City',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _deliveryStateController,
          hintText: 'State/Province/Region',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _deliveryPostalCodeController,
          hintText: 'Postal Code',
        ),
      ],
    );
  }

  Widget _buildDeliveryDateTimeSelection(List<String> monthNames) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        const Text(
          'SELECT DELIVERY DATE AND TIME',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.only(top: 20.0),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: TableCalendar(
            availableGestures: AvailableGestures.verticalSwipe,
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
              return day.isAfter(
                      DateTime.now().subtract(const Duration(days: 2))) &&
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
        if (_selectedDay != null && _availableTimes.isNotEmpty) ...[
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
              },
            ).toList(),
          ),
        ],
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

  Widget _buildDeliveryOrCollectionChoice(List<String> monthNames) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 80.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.asset('lib/assets/CTPLogo.png'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'HOW WOULD YOU LIKE TO PROCEED?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const Text(
                  'You can choose to collect the vehicle or have it delivered to your preferred location.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                RadioListTile<int>(
                  title: const Text(
                    'Collect the vehicle',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: 0,
                  groupValue: _selectedDeliveryOption,
                  activeColor: const Color(0xFFFF4E00),
                  onChanged: (value) {
                    setState(() {
                      _selectedDeliveryOption = value!;
                    });
                  },
                ),
                RadioListTile<int>(
                  title: const Text(
                    'Have it delivered to me',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: 1,
                  groupValue: _selectedDeliveryOption,
                  activeColor: const Color(0xFFFF4E00),
                  onChanged: (value) {
                    setState(() {
                      _selectedDeliveryOption = value!;
                    });
                  },
                ),
                const SizedBox(height: 24),
                // If delivery option chosen, show address and date/time at once
                if (_selectedDeliveryOption == 1) ...[
                  _buildDeliveryAddressForm(),
                  _buildDeliveryDateTimeSelection(monthNames),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'CONFIRM DELIVERY',
                    borderColor: Colors.blue,
                    onPressed: _saveDeliveryDetails,
                  ),
                ],
                if (_selectedDeliveryOption == 0)
                  CustomButton(
                    text: 'CONTINUE',
                    borderColor: Colors.blue,
                    onPressed: () {
                      setState(() {
                        _showCollectionDetails = true;
                      });
                    },
                  ),
              ],
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
    );
  }

  @override
  Widget build(BuildContext context) {
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Builder(
          builder: (context) {
            if (_isLoading) {
              return Stack(
                children: [
                  _offerDeliveryService &&
                          !_showCollectionDetails &&
                          _selectedDeliveryOption == 0
                      ? _buildDeliveryOrCollectionChoice(monthNames)
                      : (!_offerDeliveryService
                          ? _buildCollectionPage(monthNames)
                          : (_showCollectionDetails
                              ? _buildCollectionPage(monthNames)
                              : _buildDeliveryOrCollectionChoice(monthNames))),
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
              );
            } else {
              if (!_offerDeliveryService) {
                // No delivery option, show collection page
                return _buildCollectionPage(monthNames);
              }
              // Delivery is offered:
              if (_offerDeliveryService &&
                  !_showCollectionDetails &&
                  _selectedDeliveryOption == 1) {
                // Show both address and date/time for delivery
                return _buildDeliveryOrCollectionChoice(monthNames);
              }
              if (_offerDeliveryService &&
                  !_showCollectionDetails &&
                  _selectedDeliveryOption == 0) {
                // Chose collection after seeing delivery option
                return _buildDeliveryOrCollectionChoice(monthNames);
              }
              if (_showCollectionDetails) {
                // Show collection details page
                return _buildCollectionPage(monthNames);
              }
              return _buildDeliveryOrCollectionChoice(monthNames);
            }
          },
        ),
      ),
    );
  }
}
