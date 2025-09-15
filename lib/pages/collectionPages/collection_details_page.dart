import 'package:auto_route/auto_route.dart';
import 'package:ctp/components/web_navigation_bar.dart';
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
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class NavigationItem {
  final String title;
  final String route;

  NavigationItem({required this.title, required this.route});
}

@RoutePage()
class CollectionDetailsPage extends StatefulWidget {
  final String offerId;

  const CollectionDetailsPage({super.key, required this.offerId});

  @override
  _CollectionDetailsPageState createState() => _CollectionDetailsPageState();
}

class _CollectionDetailsPageState extends State<CollectionDetailsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Add getter for compact navigation
  bool _isCompactNavigation(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1100;

  // Large screen helper removed (unused)

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

  // New state variables for delivery confirmation view
  bool _deliveryConfirmed = false;
  String _fullDeliveryAddress = '';
  LatLng? _deliveryLatLng;

  // Collector details (dealer-provided)
  final TextEditingController _collectorNameController =
      TextEditingController();
  final TextEditingController _collectorIdController = TextEditingController();
  final TextEditingController _collectorLicenseController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCollectionLocations();
  }

  /// Fetches collection-related data **directly from the `offer`** document.
  Future<void> _fetchCollectionLocations() async {
    setState(() => _isLoading = true);

    try {
      // 1) Fetch the offer doc
      DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .get();

      if (!offerSnapshot.exists) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer does not exist.')),
        );
        return;
      }

      // 2) Extract top-level fields from the offer
      final Map<String, dynamic>? offerData =
          offerSnapshot.data() as Map<String, dynamic>?;

      final bool offerDeliveryService =
          offerData?['offerDeliveryService'] ?? false;

      // 3) Extract collectionDetails -> locations from the same offer
      final Map<String, dynamic>? collectionDetails =
          offerData?['collectionDetails'] as Map<String, dynamic>?;

      if (collectionDetails == null) {
        setState(() {
          _offerDeliveryService = offerDeliveryService;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No collectionDetails found in this offer.'),
          ),
        );
        return;
      }

      final List<dynamic>? locationsArray =
          collectionDetails['locations'] as List<dynamic>?;

      // Pre-fill collector details if already present (read for display or editing)
      final Map<String, dynamic>? collector =
          collectionDetails['collector'] as Map<String, dynamic>?;
      if (collector != null) {
        _collectorNameController.text = (collector['name'] ?? '').toString();
        _collectorIdController.text = (collector['idNumber'] ?? '').toString();
        _collectorLicenseController.text =
            (collector['licenseNumber'] ?? '').toString();
      }

      if (locationsArray == null || locationsArray.isEmpty) {
        setState(() {
          _offerDeliveryService = offerDeliveryService;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No collection locations available in this offer.'),
          ),
        );
        return;
      }

      // 4) Prepare local variables
      List<String> locations = [];
      List<String> addresses = [];
      List<List<DateTime>> locationDates = [];
      List<List<Map<String, dynamic>>> locationTimeSlots = [];
      List<LatLng> latLngs = [];

      // 5) Iterate over each location entry
      for (var locationEntry in locationsArray) {
        if (locationEntry == null) continue;

        final String address = locationEntry['address'] ?? '';
        final List<dynamic> timeSlots = locationEntry['timeSlots'] ?? [];
        final List<dynamic> dateStrings = locationEntry['dates'] ?? [];

        if (address.isEmpty || timeSlots.isEmpty || dateStrings.isEmpty) {
          continue;
        }

        final List<DateTime> parsedDates = [];
        for (var dateStr in dateStrings) {
          if (dateStr is String) {
            try {
              final DateTime dt = DateFormat('d-MM-yyyy').parse(dateStr);
              parsedDates.add(dt);
            } catch (e) {
              // skip invalid
            }
          }
        }

        final List<Map<String, dynamic>> parsedTimeSlots = [];
        for (var slot in timeSlots) {
          if (slot == null) continue;
          final String? slotDateStr = slot['date'];
          final List<dynamic> times = slot['times'] ?? [];

          if (slotDateStr == null || times.isEmpty) continue;

          try {
            final DateTime slotDate =
                DateFormat('d-MM-yyyy').parse(slotDateStr);

            parsedTimeSlots.add({
              'date': slotDate,
              'times': times,
            });
          } catch (e) {
            // skip invalid
          }
        }

        if (parsedDates.isNotEmpty && parsedTimeSlots.isNotEmpty) {
          locations.add(address);
          addresses.add(address);
          locationDates.add(parsedDates);
          locationTimeSlots.add(parsedTimeSlots);

          try {
            final List<Location> geoLocations =
                await locationFromAddress(address);
            if (geoLocations.isNotEmpty) {
              final loc = geoLocations.first;
              latLngs.add(LatLng(loc.latitude, loc.longitude));
            } else {
              latLngs.add(const LatLng(0, 0));
            }
          } catch (_) {
            latLngs.add(const LatLng(0, 0));
          }
        }
      }

      if (locations.isEmpty) {
        setState(() {
          _offerDeliveryService = offerDeliveryService;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid collection locations found in this offer.'),
          ),
        );
        return;
      }

      DateTime? earliest;
      for (var dateList in locationDates) {
        for (var d in dateList) {
          if (d.isAfter(DateTime.now().subtract(const Duration(days: 1))) &&
              (earliest == null || d.isBefore(earliest))) {
            earliest = d;
          }
        }
      }

      setState(() {
        _offerDeliveryService = offerDeliveryService;
        _locations = locations;
        _addresses = addresses;
        _locationDates = locationDates;
        _locationTimeSlots = locationTimeSlots;
        _latLngs = latLngs;
        _isLoading = false;
        _focusedDay = earliest ?? DateTime.now();
        _selectedDay = _focusedDay;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load collection details: $e'),
        ),
      );
    }
  }

  /// For delivery, always use location index = 0.
  int get _currentLocationIndex {
    if (_selectedDeliveryOption == 1) {
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
      final List<Map<String, dynamic>> timeSlots =
          _locationTimeSlots[_currentLocationIndex];

      for (var slotMap in timeSlots) {
        final DateTime slotDate = _normalizeDate(slotMap['date']);
        if (slotDate.isAtSameMomentAs(normalizedSelectedDay)) {
          final List<dynamic> times = slotMap['times'];
          return times.cast<String>();
        }
      }
    }
    return [];
  }

  DateTime _normalizeDate(DateTime d) => DateTime(d.year, d.month, d.day);

  bool isDateAvailable(DateTime day) {
    if (_locationDates.isEmpty ||
        _currentLocationIndex >= _locationDates.length ||
        _locationDates[_currentLocationIndex].isEmpty) {
      return false;
    }
    final checkDay = _normalizeDate(day);
    for (var d in _locationDates[_currentLocationIndex]) {
      if (_normalizeDate(d).isAtSameMomentAs(checkDay)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _saveCollectionDetails() async {
    if (_selectedDay == null || _availableTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time first.')),
      );
      return;
    }

    // Validate collector for dealers
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = userProvider.getUserRole;
    if (userRole == 'dealer') {
      if (_collectorNameController.text.trim().isEmpty ||
          _collectorIdController.text.trim().isEmpty ||
          _collectorLicenseController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter collector name, ID and license.')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final offerRef =
          FirebaseFirestore.instance.collection('offers').doc(widget.offerId);

      await offerRef.set(
        {
          'dealerSelectedCollectionDate': _selectedDay,
          'dealerSelectedCollectionTime': _availableTimes[_selectedTimeSlot],
          'dealerSelectedCollectionLocation': _addresses[_selectedLocation],
          'latLng': GeoPoint(
            _latLngs[_selectedLocation].latitude,
            _latLngs[_selectedLocation].longitude,
          ),
          'dealerSelectedDelivery': false,
          if (userRole == 'dealer')
            'collectionDetails.collector': {
              'name': _collectorNameController.text.trim(),
              'idNumber': _collectorIdController.text.trim(),
              'licenseNumber': _collectorLicenseController.text.trim(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
        },
        SetOptions(merge: true),
      );

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => CollectionConfirmationPage(
            offerId: widget.offerId,
            location: _locations[_selectedLocation],
            address: _addresses[_selectedLocation],
            date: _selectedDay!,
            time: _availableTimes[_selectedTimeSlot],
            latLng: _latLngs[_selectedLocation],
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save collection details: $err')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Updated _saveDeliveryDetails now performs geocoding to retrieve coordinates,
  /// writes to Firestore and then sets state to display a delivery confirmation view.
  Future<void> _saveDeliveryDetails() async {
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
    if (_selectedDay == null || _availableTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time.')),
      );
      return;
    }

    final fullDeliveryAddress = [
      _deliveryAddressLine1Controller.text,
      if (_deliveryAddressLine2Controller.text.isNotEmpty)
        _deliveryAddressLine2Controller.text,
      _deliveryCityController.text,
      _deliveryStateController.text,
      _deliveryPostalCodeController.text
    ].join(', ');

    setState(() => _isLoading = true);

    try {
      LatLng deliveryCoordinates = const LatLng(0, 0);
      try {
        final locations = await locationFromAddress(fullDeliveryAddress);
        if (locations.isNotEmpty) {
          deliveryCoordinates =
              LatLng(locations.first.latitude, locations.first.longitude);
        }
      } catch (e) {
        deliveryCoordinates = const LatLng(0, 0);
      }

      final offerRef =
          FirebaseFirestore.instance.collection('offers').doc(widget.offerId);

      await offerRef.set(
        {
          'dealerSelectedDelivery': true,
          'transporterDeliveryAddress': fullDeliveryAddress,
          'dealerSelectedDeliveryDate': _selectedDay,
          'dealerSelectedDeliveryTime': _availableTimes[_selectedTimeSlot],
        },
        SetOptions(merge: true),
      );

      setState(() {
        _fullDeliveryAddress = fullDeliveryAddress;
        _deliveryLatLng = deliveryCoordinates;
        _deliveryConfirmed = true;
      });
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save delivery details: $err')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDeliveryMap(LatLng location) {
    return SizedBox(
      height: 300,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: location,
          zoom: 14,
        ),
        markers: {
          Marker(
            markerId: const MarkerId("deliveryAddress"),
            position: location,
          ),
        },
      ),
    );
  }

  /// This view is shown when delivery details have been confirmed.
  /// It displays different messages depending on whether the current user is a dealer or transporter.
  Widget _buildDeliveryConfirmationView() {
    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.getUserRole;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: Image.asset('lib/assets/CTPLogo.png'),
                  ),
                  const SizedBox(height: 16),
                  if (userRole == 'dealer') ...[
                    const Text(
                      "The transporter will deliver the vehicle to your address:",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ] else if (userRole == 'transporter' ||
                      userRole == 'oem' || userRole == 'tradein' || userRole == 'trade-in') ...[
                    const Text(
                      "Dealer's delivery address:",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    _fullDeliveryAddress,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (_deliveryLatLng != null)
                    _buildDeliveryMap(_deliveryLatLng!),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'BACK',
                    borderColor: Colors.blue,
                    onPressed: () {
                      setState(() {
                        _deliveryConfirmed = false;
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
      ),
    );
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
                          fontWeight: FontWeight.w500,
                        ),
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
                    padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
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
                          'Now, let\'s set up a meeting to collect the vehicle. '
                          'Your careful selection ensures a smooth process ahead.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        // Collector details section
                        Builder(
                          builder: (context) {
                            final userRole =
                                Provider.of<UserProvider>(context).getUserRole;
                            final bool isDealer = userRole == 'dealer';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'COLLECTOR DETAILS',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                if (isDealer) ...[
                                  _buildTextField(
                                    controller: _collectorNameController,
                                    hintText: 'Collector Full Name',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _collectorIdController,
                                    hintText: 'Collector ID/Passport Number',
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _collectorLicenseController,
                                    hintText: 'Collector License Number',
                                  ),
                                  const SizedBox(height: 24),
                                ] else ...[
                                  // Read-only view for transporter/admin
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Name: ${_collectorNameController.text.isEmpty ? '—' : _collectorNameController.text}',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'ID/Passport: ${_collectorIdController.text.isEmpty ? '—' : _collectorIdController.text}',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'License: ${_collectorLicenseController.text.isEmpty ? '—' : _collectorLicenseController.text}',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 8),
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
                            final idx = entry.key;
                            final location = entry.value;
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
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            enabledDayPredicate: (day) {
                              return day.isAfter(
                                    DateTime.now().subtract(
                                      const Duration(days: 2),
                                    ),
                                  ) &&
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
                            'Selected Date: ${_selectedDay!.day} '
                            '${monthNames[_selectedDay!.month - 1]}, ${_selectedDay!.year}',
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
                                    final idx = entry.key;
                                    final timeSlot = entry.value;
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
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
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
            'Selected Date: ${_selectedDay!.day} '
            '${monthNames[_selectedDay!.month - 1]}, ${_selectedDay!.year}',
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
            children: _availableTimes.asMap().entries.map((entry) {
              final idx = entry.key;
              final timeSlot = entry.value;
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
            padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.asset('lib/assets/CTPLogo.png'),
                ),
                const SizedBox(height: 16),
                // Title
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
                // Explanation
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
                // Radio for collect
                RadioListTile<int>(
                  title: const Text(
                    'Collect the vehicle',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: 0,
                  groupValue: _selectedDeliveryOption,
                  activeColor: const Color(0xFFFF4E00),
                  onChanged: (value) {
                    setState(() => _selectedDeliveryOption = value!);
                  },
                ),
                // Radio for delivery
                RadioListTile<int>(
                  title: const Text(
                    'Have it delivered to me',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: 1,
                  groupValue: _selectedDeliveryOption,
                  activeColor: const Color(0xFFFF4E00),
                  onChanged: (value) {
                    setState(() => _selectedDeliveryOption = value!);
                  },
                ),
                const SizedBox(height: 24),
                // If delivery is chosen => show address form & date/time
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
                // If collecting => show a "Continue" button to show the standard "collection" UI
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
        // Back button
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

    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.getUserRole;

    List<NavigationItem> navigationItems = userRole == 'dealer'
        ? [
            NavigationItem(title: 'Home', route: '/home'),
            NavigationItem(title: 'Search Trucks', route: '/truckPage'),
            NavigationItem(title: 'Wishlist', route: '/wishlist'),
            NavigationItem(title: 'Pending Offers', route: '/offers'),
          ]
        : [
            NavigationItem(title: 'Home', route: '/home'),
            NavigationItem(title: 'Your Trucks', route: '/transporterList'),
            NavigationItem(title: 'Your Offers', route: '/offers'),
            NavigationItem(title: 'In-Progress', route: '/in-progress'),
          ];

    return GradientBackground(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: kIsWeb
            ? PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: WebNavigationBar(
                  isCompactNavigation: _isCompactNavigation(context),
                  currentRoute: '/offers',
                  onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              )
            : null,
        drawer: _isCompactNavigation(context) && kIsWeb
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
                            bottom: BorderSide(color: Colors.white24, width: 1),
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
                        child: ListView(
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
                                  Navigator.pushNamed(context, item.route);
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF4E00),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              if (_deliveryConfirmed && _selectedDeliveryOption == 1) {
                return _buildDeliveryConfirmationView();
              }
              if (!_offerDeliveryService) {
                return _buildCollectionPage(monthNames);
              }
              if (_offerDeliveryService &&
                  !_showCollectionDetails &&
                  _selectedDeliveryOption == 1) {
                return _buildDeliveryOrCollectionChoice(monthNames);
              }
              if (_offerDeliveryService &&
                  !_showCollectionDetails &&
                  _selectedDeliveryOption == 0) {
                return _buildDeliveryOrCollectionChoice(monthNames);
              }
              if (_showCollectionDetails) {
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
