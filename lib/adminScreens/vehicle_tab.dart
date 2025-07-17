// lib/adminScreens/vehicle_tab.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/truckForms/vehilce_upload_screen.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

// Import Provider packages if you use them to access the current user data:
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart'; // Adjust this path if needed
import 'package:ctp/pages/trailerForms/trailer_upload_screen.dart';

// import 'package:auto_route/auto_route.dart';

// @RoutePage()
class VehiclesTab extends StatefulWidget {
  const VehiclesTab({super.key});

  @override
  _VehiclesTabState createState() => _VehiclesTabState();
}

class _VehiclesTabState extends State<VehiclesTab>
    with TickerProviderStateMixin {
  // --------------------------------------------------------------------
  // 1) Filter State
  // --------------------------------------------------------------------
  final List<String> _selectedYears = [];
  final List<String> _selectedBrands = [];
  final List<String> _selectedMakeModels = [];
  final List<String> _selectedVehicleStatuses = [];
  final List<String> _selectedTransmissions = [];

  // We'll load countries/provinces from JSON:
  final List<String> _selectedCountries = [];
  final List<String> _selectedProvinces = [];

  final List<String> _selectedApplicationOfUse = [];
  final List<String> _selectedConfigs = [];

  // For search and pagination:
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final int _limit = 10;
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  final List<DocumentSnapshot> _vehicles = [];
  final ScrollController _scrollController = ScrollController();

  String _sortField = 'createdAt';
  bool _sortAscending = false;
  final List<String> _selectedFilters = [];
  final List<String> _filterOptions = ['All', 'Live', 'Sold', 'Draft'];

  // --------------------------------------------------------------------
  // 2) Hard-coded filter lists for other fields
  // --------------------------------------------------------------------
  final List<String> _yearOptions = [
    'All',
    '2015',
    '2016',
    '2017',
    '2018',
    '2019',
    '2020',
    '2021',
    '2022',
    '2023',
    '2024'
  ];

  final List<String> _vehicleStatusOptions = ['All', 'Live', 'Sold', 'Draft'];
  final List<String> _transmissionOptions = ['All', 'manual', 'automatic'];

  // Dynamically loaded country and province options:
  final List<String> _countryOptions = ['All'];
  List<String> _provinceOptions = ['All'];

  final List<String> _applicationOfUseOptions = [
    'Bowser Body Trucks',
    'Cage Body Trucks',
    'Cattle Body Trucks',
    'Chassis Cab Trucks',
    'Cherry Picker Trucks',
    'Compactor Body Trucks',
    'Concrete Mixer Body Trucks',
    'Crane Body Trucks',
    'Curtain Body Trucks',
    'Fuel Tanker Body Trucks',
    'Dropside Body Trucks',
    'Fire Fighting Body Trucks',
    'Flatbed Body Trucks',
    'Honey Sucker Body Trucks',
    'Hooklift Body Trucks',
    'Insulated Body Trucks',
    'Mass Side Body Trucks',
    'Pantechnicon Body Trucks',
    'Refrigerated Body Trucks',
    'Roll Back Body Trucks',
    'Side Tipper Body Trucks',
    'Skip Loader Body Trucks',
    'Tanker Body Trucks',
    'Tipper Body Trucks',
    'Volume Body Trucks',
  ];

  final List<String> _configOptions = [
    'All',
    '4x2',
    '6x4',
    '6x2',
    '8x4',
    '10x4'
  ];

  // --------------------------------------------------------------------
  // 3) Dynamic brand & model loading from JSON
  // --------------------------------------------------------------------
  final List<String> _brandOptions = ['All']; // Populated from JSON
  List<String> _makeModelOptions = ['All']; // Populated from JSON

  // Store the entire countries.json so we can find provinces:
  List<dynamic> _countriesData = [];

  // --------------------------------------------------------------------
  // NEW: Top-level Tab Controller (Statuses) and second-level Tab Controller (Truck/Trailer)
  // --------------------------------------------------------------------
  late TabController _tabController; // For Draft / Pending / Live
  late TabController _innerTabController; // For Truck / Trailer

  // Current selected status from the top-level tabs:
  String _currentTabStatus = 'Draft'; // default

  // Current selected vehicle type from the second-level tabs:
  String _currentInnerVehicleType = 'truck'; // default

  // Streams for top-level tab counts:
  late Stream<int> _draftCountStream;
  late Stream<int> _pendingCountStream;
  late Stream<int> _liveCountStream;

  // Add a helper method to get the count stream for a given status and type:
  Stream<int> _getCountStream(String status, String type) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    Query baseQuery = FirebaseFirestore.instance.collection('vehicles');
    if (userProvider.userRole == 'sales representative') {
      baseQuery =
          baseQuery.where('assignedSalesRepId', isEqualTo: userProvider.userId);
    }
    return baseQuery
        .where('vehicleStatus', isEqualTo: status)
        .where('vehicleType', isEqualTo: type)
        .snapshots()
        .map((snap) => snap.size);
  }

  @override
  void initState() {
    super.initState();

    // 1) Set up top-level tab controller (3 tabs)
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // 2) Set up second-level tab controller (2 tabs)
    _innerTabController = TabController(length: 2, vsync: this);
    _innerTabController.addListener(() {
      // Only trigger if we have a "final" index (not mid-swipe)
      if (_innerTabController.indexIsChanging) return;
      setState(() {
        _currentInnerVehicleType =
            _innerTabController.index == 0 ? 'truck' : 'trailer';
        // Clear and reload vehicles for the new type
        _vehicles.clear();
        _lastDocument = null;
        _hasMore = true;
      });
      _fetchVehicles();
    });

    // Load JSON data for brand/countries
    _loadBrandsFromJson();
    _loadCountriesFromJson();

    // Fetch initial vehicles
    _fetchVehicles();

    // Listen for scroll events for pagination
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchVehicles();
      }
    });

    // Initialize the count streams for top-level tabs
    _initializeCountStreams();
  }

  void _initializeCountStreams() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    String currentUserRole = userProvider.userRole;
    String? currentUserId = userProvider.userId;

    Query baseQuery = FirebaseFirestore.instance.collection('vehicles');

    if (currentUserRole == 'sales representative') {
      baseQuery =
          baseQuery.where('assignedSalesRepId', isEqualTo: currentUserId);
    }

    // We'll just count total Draft, Pending, Live (all vehicle types) for the top tabs
    // (But we do sub-totals with _getCountStream(...) in the sub tab bar)
    _draftCountStream = baseQuery
        .where('vehicleStatus', isEqualTo: 'Draft')
        .snapshots()
        .map((snap) => snap.size);

    _pendingCountStream = baseQuery
        .where('vehicleStatus', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.size);

    _liveCountStream = baseQuery
        .where('vehicleStatus', isEqualTo: 'Live')
        .snapshots()
        .map((snap) => snap.size);
  }

  /// Handle the top-level tab selection for statuses
  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return; // prevent mid-swipe calls
    setState(() {
      // Decide which status is selected
      _currentTabStatus = _tabController.index == 0
          ? 'Draft'
          : _tabController.index == 1
              ? 'pending'
              : 'Live';

      // Reset pagination
      _vehicles.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    _fetchVehicles();
  }

  /// Loads distinct brand names from updated_truck_data.json.
  Future<void> _loadBrandsFromJson() async {
    try {
      final String response =
          await rootBundle.loadString('lib/assets/updated_truck_data.json');
      final Map<String, dynamic> jsonData = json.decode(response);

      Set<String> uniqueBrands = {};

      jsonData.forEach((year, yearData) {
        if (yearData is Map<String, dynamic>) {
          yearData.forEach((brandName, _) {
            final String normalized = brandName.trim();
            uniqueBrands.add(normalized);
          });
        }
      });

      List<String> sortedBrands = uniqueBrands.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      setState(() {
        _brandOptions.clear();
        _brandOptions.add('All');
        _brandOptions.addAll(sortedBrands);
      });

      debugPrint(
          '--- DEBUG: Loaded ${_brandOptions.length - 1} brands: ${_brandOptions.skip(1).join(", ")}');
    } catch (e, stackTrace) {
      debugPrint('Error loading brands from JSON: $e');
      debugPrint(stackTrace.toString());
    }
  }

  /// Loads countries.json to populate _countryOptions.
  Future<void> _loadCountriesFromJson() async {
    try {
      final String response =
          await rootBundle.loadString('lib/assets/countries.json');
      final data = json.decode(response);

      if (data is List) {
        setState(() {
          _countriesData = data;
          _countryOptions.clear();
          _countryOptions.add('All');
          for (var item in data) {
            if (item is Map<String, dynamic>) {
              final countryName = item['name'];
              if (countryName != null) {
                _countryOptions.add(countryName);
              }
            }
          }
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading countries from JSON: $e');
      debugPrint(stackTrace.toString());
    }
  }

  /// Updates the list of provinces based on a selected country.
  void _updateProvincesForCountry(String countryName) {
    if (countryName == 'All') {
      setState(() {
        _provinceOptions = ['All'];
      });
      return;
    }

    final country = _countriesData.firstWhere(
      (element) =>
          (element is Map<String, dynamic>) && (element['name'] == countryName),
      orElse: () => null,
    );

    if (country == null || country['states'] == null) {
      setState(() {
        _provinceOptions = ['All'];
      });
    } else {
      final statesList = country['states'] as List<dynamic>;
      final provinceNames = <String>[];
      for (var s in statesList) {
        if (s is Map<String, dynamic>) {
          final provinceName = s['name'];
          if (provinceName != null) {
            provinceNames.add(provinceName);
          }
        }
      }
      provinceNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      setState(() {
        _provinceOptions = ['All', ...provinceNames];
      });
    }
  }

  /// Updates the model list based on the selected brand.
  void _updateModelsForBrand(String brand) async {
    try {
      if (brand == 'All') {
        setState(() {
          _makeModelOptions = ['All'];
        });
        return;
      }

      final String response =
          await rootBundle.loadString('lib/assets/updated_truck_data.json');
      final Map<String, dynamic> jsonData = json.decode(response);

      Set<String> models = {};

      jsonData.forEach((year, yearData) {
        if (yearData is Map<String, dynamic>) {
          yearData.forEach((dataBrand, modelList) {
            if (dataBrand.trim().toLowerCase() == brand.trim().toLowerCase()) {
              if (modelList is List) {
                for (var m in modelList) {
                  models.add(m.toString().trim());
                }
              }
            }
          });
        }
      });

      List<String> sortedModels = models.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      setState(() {
        _makeModelOptions = ['All', ...sortedModels];
      });

      debugPrint(
          '--- DEBUG: Loaded ${_makeModelOptions.length - 1} models for $brand: ${_makeModelOptions.skip(1).join(", ")}');
    } catch (e, stackTrace) {
      debugPrint('Error loading models for brand $brand: $e');
      debugPrint(stackTrace.toString());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _innerTabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _safeToLower(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.toLowerCase();
    if (value is num) return value.toString().toLowerCase();
    if (value is Map) {
      if (value.containsKey('brandName')) {
        return value['brandName'].toString().toLowerCase();
      }
      return value.toString().toLowerCase();
    }
    return value.toString().toLowerCase();
  }

  // --------------------------------------------------------------------
  // 4) Client-Side Searching
  // --------------------------------------------------------------------
  bool _matchesSearch(Map<String, dynamic> vehicleData) {
    if (_searchQuery.isEmpty) return true;
    final query = _searchQuery.toLowerCase();

    String reference = _safeToLower(vehicleData['referenceNumber']);
    List<dynamic> brandList = vehicleData['brands'] ?? [];
    String brandConcat = brandList.map((e) => _safeToLower(e)).join(' ');
    String makeModel = _safeToLower(vehicleData['makeModel']);
    String variant = _safeToLower(vehicleData['variant']);
    String yearStr = _safeToLower(vehicleData['year']?.toString());
    String statusStr = _safeToLower(vehicleData['vehicleStatus']);
    String transmissionStr = _safeToLower(vehicleData['transmissionType']);
    String countryStr = _safeToLower(vehicleData['country']);
    String provinceStr = _safeToLower(vehicleData['province']);
    String applicationStr = _safeToLower(vehicleData['applicationOfUse']);
    String configStr = _safeToLower(vehicleData['config']);
    String vehicleTypeStr = _safeToLower(vehicleData['vehicleType']);

    return brandConcat.contains(query) ||
        makeModel.contains(query) ||
        variant.contains(query) ||
        yearStr.contains(query) ||
        statusStr.contains(query) ||
        transmissionStr.contains(query) ||
        countryStr.contains(query) ||
        provinceStr.contains(query) ||
        applicationStr.contains(query) ||
        configStr.contains(query) ||
        vehicleTypeStr.contains(query) ||
        reference.contains(query);
  }

  // --------------------------------------------------------------------
  // 5) Firestore Query + Filter
  // --------------------------------------------------------------------
  Future<void> _fetchVehicles() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Base query
      Query query = FirebaseFirestore.instance.collection('vehicles');

      // 1) Filter by current tab status:
      query = query.where('vehicleStatus', isEqualTo: _currentTabStatus);

      // 2) Filter by current sub tab vehicle type:
      query = query.where('vehicleType', isEqualTo: _currentInnerVehicleType);

      // User role filtering
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.userRole == 'sales representative') {
        query =
            query.where('assignedSalesRepId', isEqualTo: userProvider.userId);
      }

      // Build additional filter conditions map
      Map<String, dynamic> filterConditions = {};

      // Year
      if (_selectedYears.isNotEmpty && !_selectedYears.contains('All')) {
        filterConditions['year'] = _selectedYears;
      }

      // Brand (arrayContainsAny)
      if (_selectedBrands.isNotEmpty && !_selectedBrands.contains('All')) {
        query = query.where('brands', arrayContainsAny: _selectedBrands);
      }

      // Model
      if (_selectedMakeModels.isNotEmpty &&
          !_selectedMakeModels.contains('All')) {
        filterConditions['makeModel'] = _selectedMakeModels;
      }

      // Transmission
      if (_selectedTransmissions.isNotEmpty &&
          !_selectedTransmissions.contains('All')) {
        filterConditions['transmissionType'] = _selectedTransmissions;
      }

      // Country
      if (_selectedCountries.isNotEmpty &&
          !_selectedCountries.contains('All')) {
        filterConditions['country'] = _selectedCountries;
      }

      // Province
      if (_selectedProvinces.isNotEmpty &&
          !_selectedProvinces.contains('All')) {
        filterConditions['province'] = _selectedProvinces;
      }

      // Application of Use
      if (_selectedApplicationOfUse.isNotEmpty &&
          !_selectedApplicationOfUse.contains('All')) {
        filterConditions['applicationOfUse'] = _selectedApplicationOfUse;
      }

      // Config
      if (_selectedConfigs.isNotEmpty && !_selectedConfigs.contains('All')) {
        filterConditions['config'] = _selectedConfigs;
      }

      // Apply whereIn filters
      filterConditions.forEach((field, values) {
        query = query.where(field, whereIn: values);
      });

      // Apply sorting
      query = query.orderBy(_sortField, descending: !_sortAscending);

      // Apply pagination
      query = query.limit(_limit);
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      debugPrint('Executing query with status=$_currentTabStatus, '
          'type=$_currentInnerVehicleType, extra filters: $filterConditions');

      final QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        // Additional in-memory filtering for brand array, if needed
        final filteredDocs = querySnapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          if (_selectedBrands.isNotEmpty && !_selectedBrands.contains('All')) {
            final docBrands = List<String>.from(data['brands'] ?? []);
            if (!_selectedBrands.any((b) => docBrands.contains(b))) {
              return false;
            }
          }

          return true;
        }).toList();

        setState(() {
          if (filteredDocs.isNotEmpty) {
            _lastDocument = filteredDocs.last;
            _vehicles.addAll(filteredDocs);
          }
          _hasMore = filteredDocs.length >= _limit;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error fetching vehicles: $e\n$stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --------------------------------------------------------------------
  // 6) Build UI
  // --------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Apply client-side search filter
    List<DocumentSnapshot> filteredVehicles = _vehicles.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return _matchesSearch(data);
    }).toList();

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            // --- TOP-LEVEL TAB BAR (Draft, Pending, Live) ---
            _buildTabBarWithCounts(),

            // --- SECOND-LEVEL TAB BAR (Truck, Trailer) ---
            _buildInnerTabBarWithCounts(),

            // --- SEARCH, SORT, and FILTER controls ---
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // SEARCH BAR
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.montserrat(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search vehicles...',
                          hintStyle:
                              GoogleFonts.montserrat(color: Colors.white54),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white54),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // SORT BUTTON
                  IconButton(
                    icon: const Icon(Icons.sort, color: Colors.white),
                    onPressed: _showSortMenu,
                    tooltip: 'Sort by: ${_sortField.replaceAll('_', ' ')}',
                  ),

                  // SORT DIRECTION BUTTON
                  IconButton(
                    icon: Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _sortAscending = !_sortAscending;
                        _vehicles.clear();
                        _lastDocument = null;
                        _hasMore = true;
                      });
                      _fetchVehicles();
                    },
                    tooltip:
                        _sortAscending ? 'Sort Ascending' : 'Sort Descending',
                  ),

                  // FILTER BUTTON
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onPressed: _showFilterDialog,
                    tooltip: 'Filter Vehicles',
                  ),
                ],
              ),
            ),

            // --- VEHICLE LIST ---
            Expanded(
              child: filteredVehicles.isEmpty
                  ? _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Center(
                          child: Text(
                            'No vehicles found.',
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                        )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredVehicles.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == filteredVehicles.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        var vehicleData = filteredVehicles[index].data()
                            as Map<String, dynamic>;
                        String vehicleId = filteredVehicles[index].id;

                        // Get the makeModel directly from the data
                        String makeModel =
                            vehicleData['makeModel']?.toString() ?? 'N/A';
                        String variant =
                            vehicleData['variant']?.toString() ?? '';
                        String referenceNumber =
                            vehicleData['referenceNumber']?.toString() ?? 'N/A';
                        String year = vehicleData['year']?.toString() ?? 'N/A';
                        String vehicleStatus =
                            vehicleData['vehicleStatus']?.toString() ?? 'N/A';
                        String vehicleType =
                            vehicleData['vehicleType']?.toString() ?? 'truck';

                        return Card(
                          color: Colors.grey[900],
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          child: ListTile(
                            leading: SizedBox(
                              width: 60,
                              height: 60,
                              child: Align(
                                alignment: Alignment.center,
                                child: (vehicleData['mainImageUrl'] != null &&
                                        vehicleData['mainImageUrl']
                                            .toString()
                                            .isNotEmpty)
                                    ? Image.network(
                                        vehicleData['mainImageUrl'],
                                        fit: BoxFit.cover,
                                        width: 50,
                                        height: 50,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.directions_car,
                                            color: Colors.blueAccent,
                                          );
                                        },
                                      )
                                    : const Icon(
                                        Icons.directions_car,
                                        color: Colors.blueAccent,
                                        size: 50,
                                      ),
                              ),
                            ),
                            title: Builder(
                              builder: (context) {
                                if (vehicleType.toLowerCase() == 'trailer') {
                                  // Debug: print the trailerExtraInfo and trailer object
                                  debugPrint(
                                      'TRAILER vehicleData: $vehicleData');
                                  final trailerType =
                                      vehicleData['trailerType']?.toString() ??
                                          '';
                                  final trailerExtraInfo =
                                      vehicleData['trailerExtraInfo']
                                              as Map<String, dynamic>? ??
                                          {};
                                  debugPrint(
                                      'DEBUG: trailerType: $trailerType');
                                  debugPrint(
                                      'DEBUG: trailerExtraInfo: $trailerExtraInfo');
                                  // --- PATCH: Robust Superlink TrailerA info extraction ---
                                  if (trailerType.toLowerCase() ==
                                      'superlink') {
                                    // Try all possible keys for Trailer A info
                                    Map<String, dynamic>? trailerA;
                                    if (trailerExtraInfo['trailerA']
                                        is Map<String, dynamic>) {
                                      trailerA = trailerExtraInfo['trailerA'];
                                    } else if (trailerExtraInfo['trailerA']
                                        is Map) {
                                      trailerA = Map<String, dynamic>.from(
                                          trailerExtraInfo['trailerA']);
                                    } else {
                                      trailerA = null;
                                    }
                                    debugPrint('Superlink TrailerA: $trailerA');
                                    // Try to get make/model/year from trailerA, fallback to vehicleData
                                    final makeA = trailerA?['make'] ??
                                        vehicleData['makeModel'] ??
                                        '';
                                    final modelA = trailerA?['model'] ?? '';
                                    final yearA = trailerA?['year'] ??
                                        vehicleData['year'] ??
                                        '';
                                    // If all are empty, show fallback
                                    if ((makeA.toString() +
                                            modelA.toString() +
                                            yearA.toString())
                                        .trim()
                                        .isEmpty) {
                                      return Text(
                                        'Superlink - Trailer A: (no info)',
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      );
                                    }
                                    return Text(
                                      'Superlink - Trailer A: $makeA $modelA $yearA',
                                      style: GoogleFonts.montserrat(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    );
                                  }
                                  // For Tri-Axle, Double Axle, Other: show make/model/year
                                  else if (trailerType == 'Tri-Axle' ||
                                      trailerType == 'Double Axle' ||
                                      trailerType == 'Other') {
                                    debugPrint(
                                        '$trailerType Info: $trailerExtraInfo');
                                    String make =
                                        trailerExtraInfo['make']?.toString() ??
                                            '';
                                    String model =
                                        trailerExtraInfo['model']?.toString() ??
                                            '';
                                    String year =
                                        trailerExtraInfo['year']?.toString() ??
                                            '';
                                    // Fallbacks if missing
                                    if (make.isEmpty) {
                                      make = vehicleData['makeModel']
                                              ?.toString() ??
                                          '';
                                    }
                                    if (year.isEmpty) {
                                      year =
                                          vehicleData['year']?.toString() ?? '';
                                    }
                                    // If all are empty, fallback to VIN, registration, or length
                                    if ((make + model + year).trim().isEmpty) {
                                      String vin =
                                          trailerExtraInfo['vin']?.toString() ??
                                              '';
                                      String reg =
                                          trailerExtraInfo['registration']
                                                  ?.toString() ??
                                              '';
                                      String length =
                                          trailerExtraInfo['lengthTrailer']
                                                  ?.toString() ??
                                              '';
                                      String fallback = '';
                                      if (fallback.isEmpty) {
                                        fallback = 'Trailer Info Unavailable';
                                      }
                                      return Text(
                                        fallback.trim(),
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      );
                                    }
                                    return Text(
                                      '$trailerType: $make $model $year',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                      ),
                                    );
                                  }
                                  // fallback for unknown trailer types
                                  return Text(
                                    '$makeModel${variant.isNotEmpty ? ' $variant' : ''} ${year != 'N/A' ? year : ''}'
                                        .trim(),
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                } else {
                                  // Not a trailer, show variant as before
                                  return Text(
                                    variant,
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }
                              },
                            ),
                            subtitle: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Ref: $referenceNumber\n',
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.orange,
                                      fontSize: 16,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'Year: $year\nStatus: $vehicleStatus\n'
                                        '${vehicleType.toLowerCase() == 'trailer' ? 'Trailer Type' : 'Transmission'}: '
                                        '${vehicleType.toLowerCase() == 'trailer' ? _getTrailerTypeString(vehicleData['trailerType']) : vehicleData['transmissionType']?.toString() ?? 'N/A'}',
                                    style: GoogleFonts.montserrat(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            isThreeLine: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VehicleDetailsPage(
                                      vehicle: Vehicle.fromFirestore(
                                          vehicleId, vehicleData)),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      // --- Floating Action Button for Adding a Vehicle and Create Fleet (admin only) ---
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Create Fleet button (only for admins)
          // Builder(
          //   builder: (context) {
          //     final userProvider = Provider.of<UserProvider>(context);
          //     if (userProvider.userRole != 'admin') {
          //       return const SizedBox.shrink();
          //     }
          //     // return Padding(
          //     //   padding: const EdgeInsets.only(bottom: 12.0),
          //     //   child: FloatingActionButton.extended(
          //     //     onPressed: () {
          //     //       Navigator.push(
          //     //         context,
          //     //         MaterialPageRoute(
          //     //             builder: (_) => const CreateFleetPage()),
          //     //       );
          //     //     },
          //     //     label: Text(
          //     //       'Create Fleet',
          //     //       style: GoogleFonts.montserrat(color: Colors.white),
          //     //     ),
          //     //     icon: const Icon(Icons.add, color: Colors.white),
          //     //     backgroundColor: const Color(0xFF0E4CAF),
          //     //   ),
          //     // );
          //   },
          // ),
          // Add Vehicle button
          FloatingActionButton.extended(
            onPressed: () => _showVehicleTypeSelectionDialog(),
            label: Text(
              'Add Vehicle',
              style: GoogleFonts.montserrat(color: Colors.white),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            backgroundColor: const Color(0xFF0E4CAF),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------
  // 7) Transporter Selection Dialog
  // --------------------------------------------------------------------
  void _showVehicleTypeSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Select Vehicle Type',
          style: GoogleFonts.montserrat(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomButton(
              text: 'Truck',
              borderColor: AppColors.blue,
              onPressed: () {
                Navigator.pop(context);
                _showTransporterSelectionDialog('truck');
              },
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Trailer',
              borderColor: AppColors.orange,
              onPressed: () {
                Navigator.pop(context);
                _showTransporterSelectionDialog('trailer');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTransporterSelectionDialog(String vehicleType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Select Transporter',
            style: GoogleFonts.montserrat(color: Colors.white)),
        content: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('userRole', whereIn: ['transporter', 'admin']).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator(color: Color(0xFFFF4E00));
            }
            final docs = snapshot.data!.docs;
            return SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.4,
                child: DropdownButtonFormField<String>(
                  dropdownColor: Colors.grey[900],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  hint: Text('Select a transporter',
                      style: GoogleFonts.montserrat(color: Colors.white)),
                  items: docs.map((transporter) {
                    var userData = transporter.data() as Map<String, dynamic>;
                    String displayName = userData['tradingAs'] ??
                        userData['name'] ??
                        userData['email'] ??
                        'Unknown';
                    return DropdownMenuItem<String>(
                      value: transporter.id,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(displayName,
                                style:
                                    GoogleFonts.montserrat(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1),
                            Text(userData['email'] ?? '',
                                style: GoogleFonts.montserrat(
                                    color: Colors.grey, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (transporterId) {
                    if (transporterId != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.pop(context);
                        if (vehicleType == 'truck') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VehicleUploadScreen(
                                isNewUpload: true,
                                isAdminUpload: true,
                              ),
                            ),
                          );
                        } else if (vehicleType == 'trailer') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrailerUploadScreen(
                                isNewUpload: true,
                                isAdminUpload: true,
                                transporterId: transporterId,
                              ),
                            ),
                          );
                        }
                      });
                    }
                  },
                ));
          },
        ),
      ),
    );
  }

  // --------------------------------------------------------------------
  // 8) Show Sort Menu
  // --------------------------------------------------------------------
  void _showSortMenu() async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    await showMenu(
      context: context,
      position: position,
      color: Colors.grey[900],
      items: [
        _popupSortOption('createdAt', 'Date'),
        _popupSortOption('year', 'Year'),
        _popupSortOption('vehicleStatus', 'Status'),
        _popupSortOption('makeModel', 'Model'),
      ],
    ).then((value) {
      if (value != null) {
        setState(() {
          _sortField = value;
          _vehicles.clear();
          _lastDocument = null;
          _hasMore = true;
        });
        _fetchVehicles();
      }
    });
  }

  PopupMenuItem<String> _popupSortOption(String field, String label) {
    return PopupMenuItem<String>(
      value: field,
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          if (_sortField == field) const SizedBox(width: 8),
          if (_sortField == field)
            const Icon(Icons.check, size: 18, color: Colors.white),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------
  // 9) Show Filter Dialog
  // --------------------------------------------------------------------
  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Filter Vehicles',
              style: GoogleFonts.montserrat(color: Colors.white)),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // YEAR
                    ExpansionTile(
                      title: Text('By Year',
                          style: GoogleFonts.montserrat(color: Colors.white)),
                      children: _yearOptions.map((year) {
                        return CheckboxListTile(
                          title: Text(year,
                              style:
                                  GoogleFonts.montserrat(color: Colors.white)),
                          value: _selectedYears.contains(year),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (year == 'All') {
                                  _selectedYears.clear();
                                }
                                if (_selectedYears.contains('All')) {
                                  _selectedYears.remove('All');
                                }
                                _selectedYears.add(year);
                              } else {
                                _selectedYears.remove(year);
                              }
                            });
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),
                    // BRAND
                    ExpansionTile(
                      title: Text('By Brand',
                          style: GoogleFonts.montserrat(color: Colors.white)),
                      children: _brandOptions.map((brand) {
                        return CheckboxListTile(
                          title: Text(brand,
                              style:
                                  GoogleFonts.montserrat(color: Colors.white)),
                          value: _selectedBrands.contains(brand),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (brand == 'All') {
                                  _selectedBrands.clear();
                                }
                                if (_selectedBrands.contains('All')) {
                                  _selectedBrands.remove('All');
                                }
                                _selectedBrands.add(brand);
                                if (_selectedBrands.length == 1) {
                                  _updateModelsForBrand(brand);
                                }
                              } else {
                                _selectedBrands.remove(brand);
                                if (_selectedBrands.isEmpty) {
                                  _makeModelOptions = ['All'];
                                }
                              }
                            });
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),
                    // MODEL
                    ExpansionTile(
                      title: Text('By Model',
                          style: GoogleFonts.montserrat(color: Colors.white)),
                      children: _makeModelOptions.map((model) {
                        return CheckboxListTile(
                          title: Text(model,
                              style:
                                  GoogleFonts.montserrat(color: Colors.white)),
                          value: _selectedMakeModels.contains(model),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (model == 'All') {
                                  _selectedMakeModels.clear();
                                }
                                if (_selectedMakeModels.contains('All')) {
                                  _selectedMakeModels.remove('All');
                                }
                                _selectedMakeModels.add(model);
                              } else {
                                _selectedMakeModels.remove(model);
                              }
                            });
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),
                    // VEHICLE STATUS (Note: We typically handle status with top-level tabs,
                    // but leaving here in case you want "Sold" or others)
                    ExpansionTile(
                      title: Text('By Status',
                          style: GoogleFonts.montserrat(color: Colors.white)),
                      children: _vehicleStatusOptions
                          .where((status) =>
                              status != 'Draft' &&
                              status != 'pending' &&
                              status != 'Live')
                          .map((status) {
                        return CheckboxListTile(
                          title: Text(status,
                              style:
                                  GoogleFonts.montserrat(color: Colors.white)),
                          value: _selectedVehicleStatuses.contains(status),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (status == 'All') {
                                  _selectedVehicleStatuses.clear();
                                }
                                if (_selectedVehicleStatuses.contains('All')) {
                                  _selectedVehicleStatuses.remove('All');
                                }
                                _selectedVehicleStatuses.add(status);
                              } else {
                                _selectedVehicleStatuses.remove(status);
                              }
                            });
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),
                    // TRANSMISSION
                    ExpansionTile(
                      title: Text('By Transmission',
                          style: GoogleFonts.montserrat(color: Colors.white)),
                      children: _transmissionOptions.map((trans) {
                        return CheckboxListTile(
                          title: Text(trans,
                              style:
                                  GoogleFonts.montserrat(color: Colors.white)),
                          value: _selectedTransmissions.contains(trans),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (trans == 'All') {
                                  _selectedTransmissions.clear();
                                }
                                if (_selectedTransmissions.contains('All')) {
                                  _selectedTransmissions.remove('All');
                                }
                                _selectedTransmissions.add(trans);
                              } else {
                                _selectedTransmissions.remove(trans);
                              }
                            });
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),
                    // COUNTRY
                    ExpansionTile(
                      title: Text('By Country',
                          style: GoogleFonts.montserrat(color: Colors.white)),
                      children: _countryOptions.map((ctry) {
                        return CheckboxListTile(
                          title: Text(ctry,
                              style:
                                  GoogleFonts.montserrat(color: Colors.white)),
                          value: _selectedCountries.contains(ctry),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (ctry == 'All') {
                                  _selectedCountries.clear();
                                }
                                if (_selectedCountries.contains('All')) {
                                  _selectedCountries.remove('All');
                                }
                                _selectedCountries.add(ctry);
                                if (_selectedCountries.length == 1 &&
                                    ctry != 'All') {
                                  _updateProvincesForCountry(ctry);
                                } else {
                                  _provinceOptions = ['All'];
                                }
                              } else {
                                _selectedCountries.remove(ctry);
                                if (_selectedCountries.isEmpty) {
                                  _provinceOptions = ['All'];
                                } else if (_selectedCountries.length == 1) {
                                  final onlyCtry = _selectedCountries.first;
                                  if (onlyCtry != 'All') {
                                    _updateProvincesForCountry(onlyCtry);
                                  }
                                }
                              }
                            });
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),
                    // PROVINCE
                    ExpansionTile(
                      title: Text('By Province',
                          style: GoogleFonts.montserrat(color: Colors.white)),
                      children: _provinceOptions.map((prov) {
                        return CheckboxListTile(
                          title: Text(prov,
                              style:
                                  GoogleFonts.montserrat(color: Colors.white)),
                          value: _selectedProvinces.contains(prov),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (prov == 'All') {
                                  _selectedProvinces.clear();
                                }
                                if (_selectedProvinces.contains('All')) {
                                  _selectedProvinces.remove('All');
                                }
                                _selectedProvinces.add(prov);
                              } else {
                                _selectedProvinces.remove(prov);
                              }
                            });
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),
                    // APPLICATION OF USE
                    ExpansionTile(
                      title: Text('By Application Of Use',
                          style: GoogleFonts.montserrat(color: Colors.white)),
                      children: _applicationOfUseOptions.map((vtype) {
                        return CheckboxListTile(
                          title: Text(vtype,
                              style:
                                  GoogleFonts.montserrat(color: Colors.white)),
                          value: _selectedApplicationOfUse.contains(vtype),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (vtype == 'All') {
                                  _selectedApplicationOfUse.clear();
                                }
                                if (_selectedApplicationOfUse.contains('All')) {
                                  _selectedApplicationOfUse.remove('All');
                                }
                                _selectedApplicationOfUse.add(vtype);
                              } else {
                                _selectedApplicationOfUse.remove(vtype);
                              }
                            });
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),
                    // CONFIG
                    ExpansionTile(
                      title: Text('By Config',
                          style: GoogleFonts.montserrat(color: Colors.white)),
                      children: _configOptions.map((cfg) {
                        return CheckboxListTile(
                          title: Text(cfg,
                              style:
                                  GoogleFonts.montserrat(color: Colors.white)),
                          value: _selectedConfigs.contains(cfg),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (cfg == 'All') {
                                  _selectedConfigs.clear();
                                }
                                if (_selectedConfigs.contains('All')) {
                                  _selectedConfigs.remove('All');
                                }
                                _selectedConfigs.add(cfg);
                              } else {
                                _selectedConfigs.remove(cfg);
                              }
                            });
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),
                    // (Removed "By Vehicle Type" here, since we have a second-level tab bar)
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Clear All',
                  style: GoogleFonts.montserrat(color: Colors.white)),
              onPressed: () {
                setState(() {
                  _selectedYears.clear();
                  _selectedBrands.clear();
                  _selectedMakeModels.clear();
                  _selectedVehicleStatuses.clear();
                  _selectedTransmissions.clear();
                  _selectedCountries.clear();
                  _selectedProvinces.clear();
                  _selectedApplicationOfUse.clear();
                  _selectedConfigs.clear();

                  // Reset pagination, search, etc.
                  _vehicles.clear();
                  _lastDocument = null;
                  _hasMore = true;
                  _searchQuery = '';
                  _searchController.clear();
                  _provinceOptions = ['All'];
                });
                Navigator.pop(context);
                _fetchVehicles();
              },
            ),
            TextButton(
              child: Text('Apply',
                  style: GoogleFonts.montserrat(color: Color(0xFFFF4E00))),
              onPressed: () {
                setState(() {
                  _vehicles.clear();
                  _lastDocument = null;
                  _hasMore = true;
                });
                Navigator.pop(context);
                _fetchVehicles();
              },
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------------
  // BUILD TOP-LEVEL TAB BAR (Draft / Pending / Live) WITH COUNTS
  // --------------------------------------------------------------------
  Widget _buildTabBarWithCounts() {
    return TabBar(
      controller: _tabController,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: const Color(0xFFFF4E00),
      tabs: [
        // Draft
        StreamBuilder<int>(
          stream: _draftCountStream,
          builder: (context, snapshot) {
            return Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Draft"),
                  const SizedBox(width: 4),
                  Text(
                    '(${snapshot.data ?? 0})',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        // Pending
        StreamBuilder<int>(
          stream: _pendingCountStream,
          builder: (context, snapshot) {
            return Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Pending"),
                  const SizedBox(width: 4),
                  Text(
                    '(${snapshot.data ?? 0})',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        // Live
        StreamBuilder<int>(
          stream: _liveCountStream,
          builder: (context, snapshot) {
            return Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Live"),
                  const SizedBox(width: 4),
                  Text(
                    '(${snapshot.data ?? 0})',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // --------------------------------------------------------------------
  // BUILD SECOND-LEVEL TAB BAR (Truck / Trailer) WITH COUNTS
  // --------------------------------------------------------------------
  Widget _buildInnerTabBarWithCounts() {
    return TabBar(
      controller: _innerTabController,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: const Color(0xFFFF4E00),
      tabs: [
        // Truck
        StreamBuilder<int>(
          stream: _getCountStream(_currentTabStatus, 'truck'),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Trucks"),
                  const SizedBox(width: 4),
                  Text(
                    '($count)',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        // Trailer
        StreamBuilder<int>(
          stream: _getCountStream(_currentTabStatus, 'trailer'),
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Trailers"),
                  const SizedBox(width: 4),
                  Text(
                    '($count)',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // Add this helper method to your _VehiclesTabState class
  String _getTrailerTypeString(dynamic trailerType) {
    if (trailerType == null) return 'N/A';
    if (trailerType is String) return trailerType;
    if (trailerType is Map) {
      return trailerType['name']?.toString() ?? 'N/A';
    }
    return 'N/A';
  }

  /// Creates a fleet document for each company in the 'companies' collection.
  Future<void> _createFleetsFromCompanies() async {
    final firestore = FirebaseFirestore.instance;
    try {
      final companiesSnapshot = await firestore.collection('companies').get();
      for (var companyDoc in companiesSnapshot.docs) {
        final companyData = companyDoc.data();
        final displayName = companyData['displayName'] as String? ?? 'Unnamed';
        final fleetDocId = companyDoc.id; // reuse company ID for fleet

        await firestore.collection('fleets').doc(fleetDocId).set({
          'companyId': companyDoc.id,
          'companyName': displayName,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fleets created successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating fleets: $e')),
      );
    }
  }
}
