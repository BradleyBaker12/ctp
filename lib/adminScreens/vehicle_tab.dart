// lib/adminScreens/vehicle_tab.dart

import 'package:cloud_firestore/cloud_firestore.dart';
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

class VehiclesTab extends StatefulWidget {
  const VehiclesTab({super.key});

  @override
  _VehiclesTabState createState() => _VehiclesTabState();
}

class _VehiclesTabState extends State<VehiclesTab>
    with SingleTickerProviderStateMixin {
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

  // NEW: For vehicle type with only 2 real options ("Truck" or "Trailer")
  final List<String> _selectedVehicleType = [];

  // Additional sort options
  final List<Map<String, String>> _sortOptions = [
    {'field': 'createdAt', 'label': 'Date'},
    {'field': 'year', 'label': 'Year'},
    {'field': 'vehicleStatus', 'label': 'Status'},
    {'field': 'makeModel', 'label': 'Model'}
  ];

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

  // NEW: Only 2 real options: "Truck" or "Trailer" (plus "All")
  final List<String> _vehicleTypeOptions = ['All', 'truck', 'trailer'];

  // --------------------------------------------------------------------
  // 3) Dynamic brand & model loading from JSON
  // --------------------------------------------------------------------
  final List<String> _brandOptions = ['All']; // Populated from JSON
  List<String> _makeModelOptions = ['All']; // Populated from JSON

  // Store the entire countries.json so we can find provinces:
  List<dynamic> _countriesData = [];

  // --------------------------------------------------------------------
  // NEW: Tab Controller and Current Tab Status
  // --------------------------------------------------------------------
  late TabController _tabController;
  String _currentTabStatus = 'Draft'; // Default selected tab

  // Add these new variables at the start of the class
  late Stream<int> _draftCountStream;
  late Stream<int> _pendingCountStream;
  late Stream<int> _liveCountStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);

    _loadBrandsFromJson();
    _loadCountriesFromJson(); // load countries & provinces
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

    // Initialize the count streams
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

  /// NEW: Handle Tab Selection
  void _handleTabSelection() {
    if (_tabController.indexIsChanging) return; // Prevent intermediate states
    setState(() {
      _currentTabStatus = _tabController.index == 0
          ? 'Draft'
          : _tabController.index == 1
              ? 'pending'
              : 'Live';
      _vehicles.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    debugPrint('--- DEBUG: Selected Tab: $_currentTabStatus ---');
    _fetchVehicles();
  }

  /// Loads distinct brand names from updated_truck_data.json.
  Future<void> _loadBrandsFromJson() async {
    try {
      debugPrint('--- DEBUG: Loading brands from JSON ---');
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
      debugPrint('--- DEBUG: Loading countries from JSON ---');
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
      debugPrint('--- DEBUG: Finished loading countries => $_countryOptions');
    } catch (e, stackTrace) {
      debugPrint('Error loading countries from JSON: $e');
      debugPrint(stackTrace.toString());
    }
  }

  /// Updates the list of provinces based on a selected country.
  void _updateProvincesForCountry(String countryName) {
    debugPrint('--- DEBUG: Updating provinces for country: $countryName ---');
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
      debugPrint('--- DEBUG: Updated provinceOptions => $_provinceOptions');
    }
  }

  /// Updates the model list based on the selected brand.
  void _updateModelsForBrand(String brand) async {
    try {
      debugPrint('--- DEBUG: Updating models for brand: $brand ---');

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
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------
  // 4) Client-Side Searching
  // --------------------------------------------------------------------
  bool _matchesSearch(Map<String, dynamic> vehicleData) {
    // Return true if no search query
    if (_searchQuery.isEmpty) return true;

    final query = _searchQuery.toLowerCase();

    // Extract all searchable fields with null safety
    List<dynamic> brandList = vehicleData['brands'] ?? [];
    String brandConcat = brandList.join(' ').toLowerCase();
    String makeModel = (vehicleData['makeModel'] ?? '').toLowerCase();
    String variant = (vehicleData['variant'] ?? '').toLowerCase();
    String yearStr = (vehicleData['year']?.toString() ?? '').toLowerCase();
    String statusStr = (vehicleData['vehicleStatus'] ?? '').toLowerCase();
    String transmissionStr =
        (vehicleData['transmissionType'] ?? '').toLowerCase();
    String countryStr = (vehicleData['country'] ?? '').toLowerCase();
    String provinceStr = (vehicleData['province'] ?? '').toLowerCase();
    String applicationStr = (vehicleData['vehicleType'] ?? '').toLowerCase();
    String configStr = (vehicleData['config'] ?? '').toLowerCase();
    String vehicleTypeStr = (vehicleData['vehicleType'] ?? '').toLowerCase();

    // Check if any field contains the search query
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
        vehicleTypeStr.contains(query);
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

      // First apply status filter (this must be first for query optimization)
      query = query.where('vehicleStatus', isEqualTo: _currentTabStatus);

      // User role filtering
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.userRole == 'sales representative') {
        query =
            query.where('assignedSalesRepId', isEqualTo: userProvider.userId);
      }

      // Build filter conditions map
      Map<String, dynamic> filterConditions = {};

      // Add year filter
      if (_selectedYears.isNotEmpty && !_selectedYears.contains('All')) {
        filterConditions['year'] = _selectedYears;
      }

      // Add brand filter (needs special handling for array contains)
      if (_selectedBrands.isNotEmpty && !_selectedBrands.contains('All')) {
        // We can only use one arrayContainsAny per query
        // So we'll handle additional brand filtering in memory
        query = query.where('brands', arrayContainsAny: _selectedBrands);
      }

      // Add model filter
      if (_selectedMakeModels.isNotEmpty &&
          !_selectedMakeModels.contains('All')) {
        filterConditions['makeModel'] = _selectedMakeModels;
      }

      // Add transmission filter (fix field name)
      if (_selectedTransmissions.isNotEmpty &&
          !_selectedTransmissions.contains('All')) {
        filterConditions['transmissionType'] = _selectedTransmissions;
      }

      // Add location filters
      if (_selectedCountries.isNotEmpty &&
          !_selectedCountries.contains('All')) {
        filterConditions['country'] = _selectedCountries;
      }

      if (_selectedProvinces.isNotEmpty &&
          !_selectedProvinces.contains('All')) {
        filterConditions['province'] = _selectedProvinces;
      }

      // FIX: Application of Use filter - use the correct field name 'applicationOfUse'
      if (_selectedApplicationOfUse.isNotEmpty &&
          !_selectedApplicationOfUse.contains('All')) {
        filterConditions['applicationOfUse'] =
            _selectedApplicationOfUse; // Changed from bodyType
      }

      // FIX: Config filter - use the correct field name 'configuration'
      if (_selectedConfigs.isNotEmpty && !_selectedConfigs.contains('All')) {
        filterConditions['config'] = _selectedConfigs; // Changed from config
      }

      // Add vehicle type filter
      if (_selectedVehicleType.isNotEmpty &&
          !_selectedVehicleType.contains('All')) {
        filterConditions['vehicleType'] = _selectedVehicleType;
      }

      // Apply all whereIn filters
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

      debugPrint('Executing query with filters: $filterConditions');

      final QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        // Additional in-memory filtering for complex conditions
        final filteredDocs = querySnapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // Apply additional brand filtering if needed
          if (_selectedBrands.isNotEmpty && !_selectedBrands.contains('All')) {
            final docBrands = List<String>.from(data['brands'] ?? []);
            if (!_selectedBrands.any((brand) => docBrands.contains(brand))) {
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

  // Update filter clear method
  void _clearFilters() {
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
      _selectedVehicleType.clear();
      _vehicles.clear();
      _lastDocument = null;
      _hasMore = true;
      _searchQuery = '';
      _searchController.clear();
    });
    _fetchVehicles();
  }

  // --------------------------------------------------------------------
  // 6) Build UI
  // --------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Apply client-side search filter to the _vehicles list.
    List<DocumentSnapshot> filteredVehicles = _vehicles.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      bool matches = _matchesSearch(data);
      debugPrint(
          '--- DEBUG: Vehicle ID ${doc.id} matches search: $matches ---');
      return matches;
    }).toList();

    debugPrint(
        '--- DEBUG: build() called. Total fetched vehicles: ${_vehicles.length}, Filtered vehicles: ${filteredVehicles.length}, Search query: "$_searchQuery" ---');

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            // --- TAB BAR ---
            _buildTabBarWithCounts(),
            // --- SEARCH, SORT, and FILTER controls:
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // --- SEARCH BAR ---
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
                          debugPrint(
                              '--- DEBUG: Search query updated: $_searchQuery ---');
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // --- SORT BUTTON ---
                  IconButton(
                    icon: const Icon(Icons.sort, color: Colors.white),
                    onPressed: _showSortMenu,
                    tooltip: 'Sort by: ${_sortField.replaceAll('_', ' ')}',
                  ),
                  // --- SORT DIRECTION BUTTON ---
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
                      debugPrint(
                          '--- DEBUG: Sort direction toggled, _fetchVehicles() called ---');
                      _fetchVehicles();
                    },
                    tooltip:
                        _sortAscending ? 'Sort Ascending' : 'Sort Descending',
                  ),
                  // --- FILTER BUTTON ---
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onPressed: _showFilterDialog,
                    tooltip: 'Filter Vehicles',
                  ),
                ],
              ),
            ),
            // VEHICLE LIST:
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
                        Vehicle vehicle =
                            Vehicle.fromFirestore(vehicleId, vehicleData);

                        String brand = vehicle.brands.isNotEmpty
                            ? vehicle.brands[0]
                            : 'Unknown Brand';
                        String variant = (vehicle.variant == null ||
                                vehicle.variant!.isEmpty)
                            ? ''
                            : vehicle.variant!;

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
                                child:
                                    (vehicle.mainImageUrl?.isNotEmpty ?? false)
                                        ? Image.network(
                                            vehicle.mainImageUrl!,
                                            fit: BoxFit.cover,
                                            width: 50,
                                            height: 50,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Icon(
                                                  Icons.directions_car,
                                                  color: Colors.blueAccent);
                                            },
                                          )
                                        : const Icon(Icons.directions_car,
                                            color: Colors.blueAccent, size: 50),
                              ),
                            ),
                            title: Text(
                              '$brand ${vehicle.makeModel} $variant',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              'Year: ${vehicle.year}\nStatus: ${vehicle.vehicleStatus}\nTransmission: ${vehicle.transmissionType}',
                              style:
                                  GoogleFonts.montserrat(color: Colors.white70),
                            ),
                            isThreeLine: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      VehicleDetailsPage(vehicle: vehicle),
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
      // Floating Action Button for Adding a Vehicle:
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTransporterSelectionDialog(context),
        label: Text(
          'Add Vehicle',
          style: GoogleFonts.montserrat(color: Colors.white),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF0E4CAF),
      ),
    );
  }

  // --------------------------------------------------------------------
  // 7) Transporter Selection Dialog
  // --------------------------------------------------------------------
  void _showTransporterSelectionDialog(BuildContext context) {
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
              debugPrint(
                  '--- DEBUG: No data received in transporter stream ---');
              return const CircularProgressIndicator(color: Color(0xFFFF4E00));
            }
            final docs = snapshot.data!.docs;
            debugPrint(
                '--- DEBUG: Number of transporters fetched: ${docs.length} ---');
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
                          Text(
                            displayName,
                            style: GoogleFonts.montserrat(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            userData['email'] ?? '',
                            style: GoogleFonts.montserrat(
                                color: Colors.grey, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (transporterId) {
                  debugPrint(
                      '--- DEBUG: Selected transporterId: $transporterId ---');
                  if (transporterId != null) {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VehicleUploadScreen(
                          isNewUpload: true,
                          isAdminUpload: true,
                        ),
                      ),
                    );
                  }
                },
              ),
            );
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
      items: _sortOptions.map((option) {
        return PopupMenuItem<String>(
          value: option['field'],
          child: Row(
            children: [
              Text(
                option['label']!,
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
              if (_sortField == option['field']) const SizedBox(width: 8),
              if (_sortField == option['field'])
                const Icon(Icons.check, size: 18, color: Colors.white),
            ],
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        setState(() {
          _sortField = value;
          _vehicles.clear();
          _lastDocument = null;
          _hasMore = true;
        });
        debugPrint(
            '--- DEBUG: sortField changed to: $value, _fetchVehicles() called ---');
        _fetchVehicles();
      }
    });
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
                            debugPrint(
                                '--- DEBUG: Year changed: $_selectedYears');
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
                            debugPrint(
                                '--- DEBUG: Brand changed: $_selectedBrands');
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
                            debugPrint(
                                '--- DEBUG: Model changed: $_selectedMakeModels');
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),
                    // VEHICLE STATUS
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
                            debugPrint(
                                '--- DEBUG: Vehicle status changed: $_selectedVehicleStatuses');
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
                            debugPrint(
                                '--- DEBUG: Transmission changed: $_selectedTransmissions');
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
                            debugPrint(
                                '--- DEBUG: Countries changed: $_selectedCountries');
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
                            debugPrint(
                                '--- DEBUG: Provinces changed: $_selectedProvinces');
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
                            debugPrint(
                                '--- DEBUG: Application Of Use changed: $_selectedApplicationOfUse');
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
                            debugPrint(
                                '--- DEBUG: Config changed: $_selectedConfigs');
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),
                    // VEHICLE TYPE
                    ExpansionTile(
                      title: Text('By Vehicle Type',
                          style: GoogleFonts.montserrat(color: Colors.white)),
                      children: _vehicleTypeOptions.map((type) {
                        return CheckboxListTile(
                          title: Text(type,
                              style:
                                  GoogleFonts.montserrat(color: Colors.white)),
                          value: _selectedVehicleType.contains(type),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (type == 'All') {
                                  _selectedVehicleType.clear();
                                }
                                if (_selectedVehicleType.contains('All')) {
                                  _selectedVehicleType.remove('All');
                                }
                                _selectedVehicleType.add(type);
                              } else {
                                _selectedVehicleType.remove(type);
                              }
                            });
                            debugPrint(
                                '--- DEBUG: Vehicle Type changed: $_selectedVehicleType');
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),
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
                  _selectedVehicleType.clear();
                  _provinceOptions = ['All'];
                  _vehicles.clear();
                  _lastDocument = null;
                  _hasMore = true;
                });
                debugPrint('--- DEBUG: Filters cleared ---');
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
                debugPrint(
                    '--- DEBUG: Filters applied, re-fetching vehicles ---');
                Navigator.pop(context);
                _fetchVehicles();
              },
            ),
          ],
        );
      },
    );
  }

  // Replace the existing TabBar in the build method with this:
  Widget _buildTabBarWithCounts() {
    return TabBar(
      controller: _tabController,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white70,
      indicatorColor: const Color(0xFFFF4E00),
      tabs: [
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
}
