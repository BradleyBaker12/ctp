import 'dart:convert';
import 'package:ctp/components/custom_app_bar.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/truck_card.dart';
import 'package:ctp/components/web_navigation_bar.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
// Trailer card widget
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auto_route/auto_route.dart';

class NavigationItem {
  final String title;
  final String route;
  NavigationItem({
    required this.title,
    required this.route,
  });
}

// If still needed:
enum FilterOperation { equals, contains }

class FilterCriterion {
  String fieldName;
  FilterOperation operation;
  dynamic value;
  FilterCriterion({
    required this.fieldName,
    required this.operation,
    required this.value,
  });
}

@RoutePage()
class TruckPage extends StatefulWidget {
  final String? vehicleType;
  final String? selectedBrand;
  // When true, open the page with the OEM tab selected even if no brand is chosen
  final bool openOemTab;
  // When true, open the page with the Trade-In tab selected
  final bool openTradeInTab;
  // Selected Trade-In brand (mirrors selectedBrand for OEM)
  final String? selectedTradeInBrand;

  const TruckPage({
    super.key,
    this.vehicleType,
    this.selectedBrand,
    this.openOemTab = false,
    this.openTradeInTab = false,
    this.selectedTradeInBrand,
  });

  @override
  _TruckPageState createState() => _TruckPageState();
}

class _TruckPageState extends State<TruckPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isCompactNavigation(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1100;

  late ScrollController _scrollController;
  bool _isLoadingMore = false;
  final int _itemsPerPage = 10;
  int _currentPage = 0;
  int _selectedIndex = 1;
  List<Vehicle> swipedVehicles = [];
  List<Vehicle> displayedVehicles = [];
  List<String> swipedDirections = [];
  int loadedVehicleIndex = 0;
  bool _hasReachedEnd = false;
  bool _isLoading = true;
  // Removed unused _isFiltering; shimmer grid not used in this refactor.

  /// NEW: Track total number of filtered vehicles
  int _totalFilteredVehicles = 0;

  // Company filter and bulk offer state
  String? _selectedCompany;
  List<String> _companyOptions = ['All'];
  final Set<String> _selectedVehicleIdsForOffer = {};

  // Fleet/All mode state
  bool _isFleetMode = false;
  // Trade-In tab state (dealer only)
  bool _isTradeInMode = false;

  // Selection mode for fleet view (long-press to activate)
  bool _isSelectionMode = false;

  // --------------------------------------------------------------------
  // 1) Filter State
  // --------------------------------------------------------------------
  final List<String> _selectedYears = [];
  final List<String> _selectedBrands = [];
  final List<String> _selectedMakeModels = [];
  final List<String> _selectedVehicleStatuses = [];
  final List<String> _selectedTransmissions = [];
  final List<String> _selectedCountries = [];
  final List<String> _selectedProvinces = [];
  final List<String> _selectedApplicationOfUse = [];
  final List<String> _selectedConfigs = [];
  final List<String> _selectedVehicleType = [];

  // --------------------------------------------------------------------
  // 2) Hard-coded Filter Lists (re-added)
  // --------------------------------------------------------------------
  final List<String> _yearOptions = const [
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
  final List<String> _vehicleStatusOptions = const [
    'All',
    'Live',
    'Sold',
    'Draft'
  ];
  final List<String> _transmissionOptions = const [
    'All',
    'manual',
    'automatic'
  ];
  final List<String> _countryOptions = ['All'];
  List<String> _provinceOptions = ['All'];
  final List<String> _applicationOfUseOptions = const [
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
  final List<String> _configOptions = const [
    'All',
    '4x2',
    '6x4',
    '6x2',
    '8x4',
    '10x4'
  ];
  final List<String> _vehicleTypeOptions = const ['All', 'truck', 'trailer'];

  // --------------------------------------------------------------------
  // 3) Dynamic Brand & Model Loading (re-added)
  // --------------------------------------------------------------------
  final List<String> _brandOptions = ['All']; // Populated from JSON
  List<String> _makeModelOptions = ['All']; // Populated based on brand
  List<dynamic> _countriesData = [];

  // OEM tab state (dealer only)
  bool _isOemMode = false;
  List<String> _oemBrands = [];
  bool _isLoadingOemBrands = false;
  // When a brand is selected from the OEM tab, we only show vehicles uploaded by OEM users for that brand
  final Set<String> _oemUserIdsForSelectedBrand = {};
  bool _oemUserIdsLoadedForBrand = false;
  String? _oemUserIdsBrandKey;
  // Cache of all OEM userIds for excluding OEM uploads from All Stock
  final Set<String> _allOemUserIds = {};
  bool _allOemUserIdsLoaded = false;

  // (Removed) OEM debug dialog helper

  // --------------------------------------------------------------------
  // 4) Initialization and Data Loading
  // --------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    // Determine initial OEM mode based on deep-linked brand
    final hasBrand = widget.selectedBrand != null &&
        widget.selectedBrand!.isNotEmpty &&
        widget.selectedBrand != 'All';
    _isOemMode = widget.openOemTab || hasBrand;

    // Determine initial Trade-In mode based on deep-linked brand or tab flag
    final hasTradeInBrand = widget.selectedTradeInBrand != null &&
        widget.selectedTradeInBrand!.isNotEmpty &&
        widget.selectedTradeInBrand != 'All';
    _isTradeInMode = widget.openTradeInTab || hasTradeInBrand;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isOemMode && !hasBrand) {
        _loadOemBrands();
      }
      if (_isTradeInMode && !hasTradeInBrand) {
        _loadTradeInBrands();
      }
      _loadInitialVehicles();
    });

    _loadBrandsFromJson();
    _loadCountriesFromJson();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      if (!_isLoadingMore && !_hasReachedEnd) {
        _loadMoreVehicles();
      }
    }
  }

  Future<void> _loadBrandsFromJson() async {
    try {
      final String response =
          await rootBundle.loadString('lib/assets/updated_truck_data.json');
      final Map<String, dynamic> jsonData = json.decode(response);
      final Set<String> uniqueBrands = {};
      jsonData.forEach((year, yearData) {
        if (yearData is Map<String, dynamic>) {
          yearData.forEach((brandName, _) {
            uniqueBrands.add(brandName.toString().trim());
          });
        }
      });
      final List<String> sortedBrands = uniqueBrands.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      setState(() {
        _brandOptions
          ..clear()
          ..add('All')
          ..addAll(sortedBrands);
      });
    } catch (e) {
      debugPrint('Error loading brands from JSON: $e');
    }
  }

  Future<void> _loadCountriesFromJson() async {
    try {
      final String response =
          await rootBundle.loadString('lib/assets/countries.json');
      final data = json.decode(response);
      if (data is List) {
        setState(() {
          _countriesData = data;
          _countryOptions
            ..clear()
            ..add('All');
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
    } catch (e) {
      debugPrint('Error loading countries from JSON: $e');
    }
  }

  // --------------------------------------------------------------------
  // OEM Brands loading and selection (dealer only)
  // --------------------------------------------------------------------
  Future<void> _loadOemBrands() async {
    try {
      setState(() => _isLoadingOemBrands = true);
      final usersRef = FirebaseFirestore.instance.collection('users');
      // Ensure we have vehicles loaded for fallbacks
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      if (vehicleProvider.vehicles.isEmpty) {
        await vehicleProvider.fetchAllVehicles();
      }
      // Fetch candidates by multiple role field variants and by non-empty oemBrand
      final futures = <Future<QuerySnapshot>>[
        usersRef.where('userRole', whereIn: ['oem', 'OEM', 'Oem']).get(),
        usersRef.where('role', whereIn: ['oem', 'OEM', 'Oem']).get(),
        usersRef.where('oemBrand', isGreaterThan: '').get(),
      ];
      final snapshots = await Future.wait(futures);
      final set = <String>{};
      for (final snap in snapshots) {
        for (final doc in snap.docs) {
          final Map<String, dynamic> data =
              Map<String, dynamic>.from(doc.data() as Map);
          final brand = (data['oemBrand'] ?? '').toString().trim();
          if (brand.isNotEmpty) set.add(brand);
        }
      }
      // If no brands found from users, derive from vehicles owned by OEM users
      if (set.isEmpty) {
        try {
          final vehicleProvider =
              Provider.of<VehicleProvider>(context, listen: false);
          // Unique ownerIds from vehicles
          final ownerIds =
              vehicleProvider.vehicles.map((v) => v.userId).toSet().toList();
          // Fetch owner user docs in small batches
          for (final ownerId in ownerIds) {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(ownerId)
                .get();
            if (!doc.exists) continue;
            final data = Map<String, dynamic>.from(doc.data() ?? {});
            final brand = (data['oemBrand'] ?? '').toString().trim();
            if (brand.isNotEmpty) {
              set.add(brand);
            } else {
              // derive brand from vehicles owned by this user
              final ownedVehicleBrands = vehicleProvider.vehicles
                  .where((v) => v.userId == ownerId)
                  .expand((v) => v.brands)
                  .map((b) => b.trim())
                  .where((b) => b.isNotEmpty)
                  .toSet();
              set.addAll(ownedVehicleBrands);
            }
          }
        } catch (e) {
          debugPrint('Fallback OEM brand derivation failed: $e');
        }
      }

      // Final fallback: derive from vehicles' own ownerRole/oemBrand metadata
      if (set.isEmpty) {
        final vehicleProvider =
            Provider.of<VehicleProvider>(context, listen: false);
        for (final v in vehicleProvider.vehicles) {
          final role = (v.ownerRole ?? '').trim().toLowerCase();
          final brand = (v.oemBrand ?? '').trim();
          if (role == 'oem' && brand.isNotEmpty) set.add(brand);
        }
      }

      // If still empty, show all known brands from vehicles (UI discovery); results page will filter to OEM-owned
      if (set.isEmpty) {
        final vehicleProvider =
            Provider.of<VehicleProvider>(context, listen: false);
        for (final v in vehicleProvider.vehicles) {
          for (final b in v.brands) {
            final brand = (b).trim();
            if (brand.isNotEmpty) set.add(brand);
          }
        }
      }

      final brands = set.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      setState(() {
        _oemBrands = brands;
        _isLoadingOemBrands = false;
      });
    } catch (e) {
      debugPrint('Error loading OEM brands: $e');
      setState(() => _isLoadingOemBrands = false);
    }
  }

  // Ensure we have the set of OEM userIds for the selected brand when filtering
  Future<void> _ensureOemUserIdsForSelectedBrandLoaded() async {
    final brand = widget.selectedBrand;
    if (brand == null || brand == 'All') return;
    // Reload when brand changes
    if (_oemUserIdsLoadedForBrand && _oemUserIdsBrandKey == brand) return;
    try {
      final usersRef = FirebaseFirestore.instance.collection('users');
      // Fetch all OEM users (both schemas), then filter locally by brand (case-insensitive)
      final results = await Future.wait([
        usersRef.where('userRole', whereIn: ['oem', 'OEM', 'Oem']).get(),
        usersRef.where('role', whereIn: ['oem', 'OEM', 'Oem']).get(),
        usersRef.where('oemBrand', isGreaterThan: '').get(),
      ]);
      final target = brand.trim().toLowerCase();
      _oemUserIdsForSelectedBrand.clear();
      for (final snap in results) {
        for (final doc in snap.docs) {
          final Map<String, dynamic> data =
              Map<String, dynamic>.from(doc.data() as Map);
          final b = (data['oemBrand'] ?? '').toString().trim().toLowerCase();
          if (b != target) continue;
          // If role fields exist, prefer requiring them to equal oem; else allow presence of oemBrand to qualify
          final roleVal = (data['userRole'] ?? data['role'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          if (roleVal.isEmpty || roleVal == 'oem') {
            _oemUserIdsForSelectedBrand.add(doc.id);
          }
        }
      }
      _oemUserIdsLoadedForBrand = true;
      _oemUserIdsBrandKey = brand;
    } catch (e) {
      debugPrint('Error loading OEM userIds for brand $brand: $e');
      _oemUserIdsLoadedForBrand = true; // avoid retry loop; show none if failed
      _oemUserIdsBrandKey = brand;
    }
    // Fallback: if no userIds were found, allow filter by vehicle.ownerRole/oemBrand
    if (_oemUserIdsForSelectedBrand.isEmpty) {
      debugPrint(
          'OEM userIds empty for brand $brand; will rely on vehicle.ownerRole/oemBrand meta.');
    }
  }

  // OEM brand selection now navigates to a new TruckPage; no in-place filter here.

  // =============================
  // Trade-In helpers
  // =============================
  // Cache of all Trade-In userIds for filtering
  final Set<String> _allTradeInUserIds = {};
  bool _allTradeInUserIdsLoaded = false;

  // Trade-In tab state (dealer only)
  List<String> _tradeInBrands = [];
  bool _isLoadingTradeInBrands = false;
  // When a brand is selected from the Trade-In tab, we only show vehicles uploaded by Trade-In users for that brand
  final Set<String> _tradeInUserIdsForSelectedBrand = {};
  bool _tradeInUserIdsLoadedForBrand = false;
  String? _tradeInUserIdsBrandKey;

  // Load Trade-In brands (from users' tradeInBrand field), with vehicle-based fallbacks
  Future<void> _loadTradeInBrands() async {
    try {
      setState(() => _isLoadingTradeInBrands = true);
      final usersRef = FirebaseFirestore.instance.collection('users');
      // Ensure we have vehicles loaded for fallbacks
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      if (vehicleProvider.vehicles.isEmpty) {
        await vehicleProvider.fetchAllVehicles();
      }
      // Fetch candidates by multiple role field variants and by non-empty tradeInBrand
      final futures = <Future<QuerySnapshot>>[
        usersRef
            .where('userRole', whereIn: ['tradein', 'trade-in', 'TradeIn'])
            .get(),
        usersRef
            .where('role', whereIn: ['tradein', 'trade-in', 'TradeIn'])
            .get(),
        usersRef.where('tradeInBrand', isGreaterThan: '').get(),
      ];
      final snapshots = await Future.wait(futures);
      final set = <String>{};
      for (final snap in snapshots) {
        for (final doc in snap.docs) {
          final Map<String, dynamic> data =
              Map<String, dynamic>.from(doc.data() as Map);
          final brand = (data['tradeInBrand'] ?? '').toString().trim();
          if (brand.isNotEmpty) set.add(brand);
        }
      }
      // If empty, derive brands from vehicles owned by Trade-In users
      if (set.isEmpty) {
        try {
          await _ensureAllTradeInUserIdsLoaded();
          final ownedByTradeIn = vehicleProvider.vehicles.where((v) {
            final role = (v.ownerRole ?? '').trim().toLowerCase();
            if (role == 'tradein' || role == 'trade-in') return true;
            return _allTradeInUserIds.contains(v.userId);
          });
          for (final v in ownedByTradeIn) {
            for (final b in v.brands) {
              final bb = b.trim();
              if (bb.isNotEmpty) set.add(bb);
            }
          }
        } catch (e) {
          debugPrint('Fallback Trade-In brand derivation failed: $e');
        }
      }
      final brands = set.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      setState(() {
        _tradeInBrands = brands;
      });
    } catch (e) {
      debugPrint('Error loading Trade-In brands: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTradeInBrands = false);
    }
  }

  // Ensure we have the set of Trade-In userIds for the selected brand when filtering
  Future<void> _ensureTradeInUserIdsForSelectedBrandLoaded(String brand) async {
    if (_tradeInUserIdsLoadedForBrand && _tradeInUserIdsBrandKey == brand) {
      return;
    }
    try {
      final usersRef = FirebaseFirestore.instance.collection('users');
      // Fetch all Trade-In users (both schemas), then filter locally by brand (case-insensitive)
      final results = await Future.wait([
        usersRef
            .where('userRole', whereIn: ['tradein', 'trade-in', 'TradeIn'])
            .get(),
        usersRef
            .where('role', whereIn: ['tradein', 'trade-in', 'TradeIn'])
            .get(),
        usersRef.where('tradeInBrand', isGreaterThan: '').get(),
      ]);
      final target = brand.trim().toLowerCase();
      _tradeInUserIdsForSelectedBrand.clear();
      for (final snap in results) {
        for (final doc in snap.docs) {
          final Map<String, dynamic> data =
              Map<String, dynamic>.from(doc.data() as Map);
          final b =
              (data['tradeInBrand'] ?? '').toString().trim().toLowerCase();
          if (b != target) continue;
          final roleVal = (data['userRole'] ?? data['role'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          if (roleVal.isEmpty || roleVal == 'tradein' || roleVal == 'trade-in') {
            _tradeInUserIdsForSelectedBrand.add(doc.id);
          }
        }
      }
      _tradeInUserIdsLoadedForBrand = true;
      _tradeInUserIdsBrandKey = brand;
    } catch (e) {
      debugPrint('Error loading Trade-In userIds for brand $brand: $e');
      _tradeInUserIdsLoadedForBrand = true; // avoid repeated attempts
      _tradeInUserIdsBrandKey = brand;
    }
  }

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
    } catch (e, stackTrace) {
      debugPrint('Error loading models for brand $brand: $e');
      debugPrint(stackTrace.toString());
    }
  }

  // --------------------------------------------------------------------
  // 5) Data Loading with Filtering
  // --------------------------------------------------------------------
  void _loadInitialVehicles() async {
    try {
      debugPrint(
          'DEBUG: _loadInitialVehicles called. isFleetMode=$_isFleetMode, selectedCompany=$_selectedCompany');
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      await vehicleProvider.fetchAllVehicles();
      if (_isFleetMode && _selectedCompany != null) {
        debugPrint('DEBUG: Fetching fleet for name=$_selectedCompany');
        final firestore = FirebaseFirestore.instance;
        final fleetQuery = await firestore
            .collection('fleets')
            .where('fleetName', isEqualTo: _selectedCompany)
            .limit(1)
            .get();

        List<String> vehicleIdsRaw = [];
        if (fleetQuery.docs.isNotEmpty) {
          vehicleIdsRaw = List<String>.from(
            fleetQuery.docs.first.data()['vehicleIds'] ?? [],
          );
        }
        debugPrint('DEBUG: fleetVehicleIds = $vehicleIdsRaw');
        debugPrint(
            'DEBUG: vehicleProvider.vehicles count = ${vehicleProvider.vehicles.length}');

        final normalizedFleetIds = vehicleIdsRaw.map((id) => id.trim()).toSet();

        var fleetVehicles = vehicleProvider.vehicles.where((v) {
          final vid = v.id.trim();
          debugPrint(
              'DEBUG: Checking vehicle ${v.id} with status ${v.vehicleStatus}');
          return normalizedFleetIds.contains(vid) &&
              (v.vehicleStatus == 'Live' || v.vehicleStatus == 'Draft');
        }).toList();

        setState(() {
          _totalFilteredVehicles = fleetVehicles.length;
          displayedVehicles = fleetVehicles;
          _currentPage = 1;
          _isLoading = false;
          loadedVehicleIndex = displayedVehicles.length;
          _hasReachedEnd = true;
        });
      } else {
        // Default All/OEM mode (non-fleet)
        debugPrint(
            'DEBUG: All mode. vehicleProvider.vehicles count = ${vehicleProvider.vehicles.length}');
        _setCompanyOptions(vehicleProvider.vehicles);

        // Base status filter
        Iterable<Vehicle> filteredVehicles = vehicleProvider.vehicles.where(
          (vehicle) => vehicle.vehicleStatus == 'Live',
        );

        // Brand/ownership scoping
        final bool hasBrand =
            widget.selectedBrand != null && widget.selectedBrand != 'All';
        if (_isOemMode && hasBrand) {
          await _ensureOemUserIdsForSelectedBrandLoaded();
          final tgt = (widget.selectedBrand ?? '').trim().toLowerCase();
          filteredVehicles = filteredVehicles.where((vehicle) {
            final matchesOwnerByUser =
                _oemUserIdsForSelectedBrand.contains(vehicle.userId);
            final matchesOwnerByMeta =
                (vehicle.ownerRole?.toLowerCase() == 'oem') &&
                    ((vehicle.oemBrand ?? '').trim().toLowerCase() == tgt);
            return matchesOwnerByUser || matchesOwnerByMeta;
          });
        }

        // Trade-In mode: include Trade-In owned vehicles, or restrict to selected Trade-In brand
        if (_isTradeInMode) {
          final tb = (widget.selectedTradeInBrand ?? '').trim();
          if (tb.isNotEmpty && tb.toLowerCase() != 'all') {
            await _ensureTradeInUserIdsForSelectedBrandLoaded(tb);
            filteredVehicles = filteredVehicles.where(
                (v) => _tradeInUserIdsForSelectedBrand.contains(v.userId));
          } else {
            await _ensureAllTradeInUserIdsLoaded();
            filteredVehicles = filteredVehicles.where((v) {
              final role = (v.ownerRole ?? '').trim().toLowerCase();
              if (role == 'tradein' || role == 'trade-in') return true;
              return _allTradeInUserIds.contains(v.userId);
            });
          }
        }

        // In All Stock (non-OEM/Trade-In) view, exclude OEM-owned vehicles entirely
        if (!_isOemMode && !_isTradeInMode) {
          await _ensureAllOemUserIdsLoaded();
          filteredVehicles =
              filteredVehicles.where((v) => !_isVehicleOemOwned(v));
        }

        // Apply any user-chosen filters
        filteredVehicles = _applySelectedFilters(filteredVehicles);

        debugPrint(
            'DEBUG: filteredVehicles count = ${filteredVehicles.length}');

        setState(() {
          _totalFilteredVehicles = filteredVehicles.length;
          displayedVehicles = filteredVehicles.take(_itemsPerPage).toList();
          _currentPage = 1;
          _isLoading = false;
          loadedVehicleIndex = displayedVehicles.length;
          _hasReachedEnd = displayedVehicles.length >= _totalFilteredVehicles;
        });
      }
    } catch (e) {
      debugPrint('ERROR in _loadInitialVehicles: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load vehicles. Please try again later.'),
        ),
      );
    }
  }

  void _loadMoreVehicles() async {
    // If not in All mode, we do not paginate fleet view
    if (_isFleetMode) return;
    // If we've loaded all already, no need to do more
    if (_hasReachedEnd) return;
    setState(() {
      _isLoadingMore = true;
    });
    try {
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      _setCompanyOptions(vehicleProvider.vehicles);
      int startIndex = _currentPage * _itemsPerPage;
      // Re-filter everything (same logic as in _loadInitialVehicles "All" branch)
      // Base status filter (Live-only for all views)
      var filteredVehicles = vehicleProvider.vehicles
          .where((vehicle) => vehicle.vehicleStatus == 'Live');
      final hasBrand =
          widget.selectedBrand != null && widget.selectedBrand != 'All';
      if (_isOemMode && hasBrand) {
        await _ensureOemUserIdsForSelectedBrandLoaded();
        filteredVehicles = filteredVehicles.where((vehicle) {
          final matchesOwnerByUser =
              _oemUserIdsForSelectedBrand.contains(vehicle.userId);
          final matchesOwnerByMeta =
              (vehicle.ownerRole?.toLowerCase() == 'oem') &&
                  ((vehicle.oemBrand ?? '').trim().toLowerCase() ==
                      (widget.selectedBrand ?? '').trim().toLowerCase());
          return matchesOwnerByUser || matchesOwnerByMeta;
        });
      }
      // Trade-In mode: include Trade-In owned vehicles, or restrict to selected Trade-In brand
      if (_isTradeInMode) {
        final tb = (widget.selectedTradeInBrand ?? '').trim();
        if (tb.isNotEmpty && tb.toLowerCase() != 'all') {
          await _ensureTradeInUserIdsForSelectedBrandLoaded(tb);
          filteredVehicles = filteredVehicles.where(
              (v) => _tradeInUserIdsForSelectedBrand.contains(v.userId));
        } else {
          await _ensureAllTradeInUserIdsLoaded();
          filteredVehicles = filteredVehicles.where((v) {
            final role = (v.ownerRole ?? '').trim().toLowerCase();
            if (role == 'tradein' || role == 'trade-in') return true;
            return _allTradeInUserIds.contains(v.userId);
          });
        }
      }
      // In All Stock (non-OEM/Trade-In) view, exclude OEM-owned vehicles entirely
      if (!_isOemMode && !_isTradeInMode) {
        await _ensureAllOemUserIdsLoaded();
        filteredVehicles =
            filteredVehicles.where((v) => !_isVehicleOemOwned(v));
      }
      filteredVehicles = _applySelectedFilters(filteredVehicles);
      // Get the next batch
      List<Vehicle> moreVehicles =
          filteredVehicles.skip(startIndex).take(_itemsPerPage).toList();
      if (moreVehicles.isNotEmpty) {
        setState(() {
          displayedVehicles.addAll(moreVehicles);
          _currentPage++;
          _isLoadingMore = false;
          // Check if we’ve now got them all
          if (displayedVehicles.length >= _totalFilteredVehicles) {
            _hasReachedEnd = true;
          }
        });
      } else {
        setState(() {
          _hasReachedEnd = true;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Error in _loadMoreVehicles: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  // Helper method to apply all selected filters.
  Iterable<Vehicle> _applySelectedFilters(Iterable<Vehicle> vehicles) {
    return vehicles.where((vehicle) {
      // Company filter
      if (_selectedCompany != null && _selectedCompany != 'All') {
        if ((vehicle.companyName ?? 'Anonymous') != _selectedCompany) {
          return false;
        }
      }
      // Apply vehicle type filter only if the user selected it; otherwise respect explicit widget.vehicleType
      if (_selectedVehicleType.isNotEmpty &&
          !_selectedVehicleType.contains('All')) {
        if (!_selectedVehicleType.contains(vehicle.vehicleType.toLowerCase())) {
          return false;
        }
      } else if (widget.vehicleType != null &&
          widget.vehicleType!.toLowerCase() != 'all') {
        if (vehicle.vehicleType.toLowerCase() !=
            widget.vehicleType!.toLowerCase()) {
          return false;
        }
      }

      // Then apply other filters
      if (_selectedYears.isNotEmpty && !_selectedYears.contains('All')) {
        if (!_selectedYears.contains(vehicle.year)) return false;
      }
      if (_selectedBrands.isNotEmpty && !_selectedBrands.contains('All')) {
        // The brand must appear in the vehicle's brand list
        if (!vehicle.brands.any((brand) => _selectedBrands.contains(brand))) {
          return false;
        }
      }
      if (_selectedMakeModels.isNotEmpty &&
          !_selectedMakeModels.contains('All')) {
        if (!_selectedMakeModels.contains(vehicle.makeModel)) return false;
      }
      if (_selectedVehicleStatuses.isNotEmpty &&
          !_selectedVehicleStatuses.contains('All')) {
        if (!_selectedVehicleStatuses.contains(vehicle.vehicleStatus)) {
          return false;
        }
      }
      if (_selectedTransmissions.isNotEmpty &&
          !_selectedTransmissions.contains('All')) {
        if (!_selectedTransmissions.contains(vehicle.transmissionType)) {
          return false;
        }
      }
      if (_selectedCountries.isNotEmpty &&
          !_selectedCountries.contains('All')) {
        if (!_selectedCountries.contains(vehicle.country)) return false;
      }
      if (_selectedProvinces.isNotEmpty &&
          !_selectedProvinces.contains('All')) {
        if (!_selectedProvinces.contains(vehicle.province)) return false;
      }
      if (_selectedApplicationOfUse.isNotEmpty &&
          !_selectedApplicationOfUse.contains('All')) {
        if (!_selectedApplicationOfUse.contains(vehicle.application)) {
          return false;
        }
      }
      if (_selectedConfigs.isNotEmpty && !_selectedConfigs.contains('All')) {
        if (!_selectedConfigs.contains(vehicle.config)) return false;
      }
      return true;
    });
  }

  void _setCompanyOptions(List<Vehicle> vehicles) {
    final companies = vehicles
        .map((v) => v.companyName ?? 'Anonymous')
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    setState(() {
      _companyOptions = ['All', ...companies];
    });
  }

  // Fleet options loader removed (unused)
  // Note: _loadFleetOptions is currently unused; keeping for future Fleet tab work.

  // --------------------------------------------------------------------
  // 6) Filter Dialog
  // --------------------------------------------------------------------
  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Filter Vehicles',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // YEAR
                    ExpansionTile(
                      title: Text(
                        'By Year',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      children: _yearOptions.map((year) {
                        return CheckboxListTile(
                          title: Text(
                            year,
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                          value: _selectedYears.contains(year),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (year == 'All') _selectedYears.clear();
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
                      title: Text(
                        'By Brand',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      children: _brandOptions.map((brand) {
                        return CheckboxListTile(
                          title: Text(
                            brand,
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                          value: _selectedBrands.contains(brand),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (brand == 'All') _selectedBrands.clear();
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
                      title: Text(
                        'By Model',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      children: _makeModelOptions.map((model) {
                        return CheckboxListTile(
                          title: Text(
                            model,
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
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

                    // VEHICLE STATUS
                    ExpansionTile(
                      title: Text(
                        'By Status',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      children: _vehicleStatusOptions
                          .where((status) =>
                              status != 'Draft' &&
                              status != 'pending' &&
                              status != 'Live')
                          .map((status) {
                        return CheckboxListTile(
                          title: Text(
                            status,
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
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
                      title: Text(
                        'By Transmission',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      children: _transmissionOptions.map((trans) {
                        return CheckboxListTile(
                          title: Text(
                            trans,
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
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
                      title: Text(
                        'By Country',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      children: _countryOptions.map((ctry) {
                        return CheckboxListTile(
                          title: Text(
                            ctry,
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
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
                      title: Text(
                        'By Province',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      children: _provinceOptions.map((prov) {
                        return CheckboxListTile(
                          title: Text(
                            prov,
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
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
                      title: Text(
                        'By Application Of Use',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      children: _applicationOfUseOptions.map((vtype) {
                        return CheckboxListTile(
                          title: Text(
                            vtype,
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
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
                      title: Text(
                        'By Config',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      children: _configOptions.map((cfg) {
                        return CheckboxListTile(
                          title: Text(
                            cfg,
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
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

                    // VEHICLE TYPE
                    ExpansionTile(
                      title: Text(
                        'By Vehicle Type',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      children: _vehicleTypeOptions.map((type) {
                        return CheckboxListTile(
                          title: Text(
                            type,
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
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
              child: Text(
                'Clear All',
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
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
                });
                Navigator.pop(context);
                _loadInitialVehicles();
              },
            ),
            TextButton(
              child: Text(
                'Apply',
                style: GoogleFonts.montserrat(color: Color(0xFFFF4E00)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _loadInitialVehicles();
              },
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------------
  // 7) Clear Liked and Disliked Vehicles (For Testing)
  // --------------------------------------------------------------------
  // Testing util removed (unused)
  // Note: _clearLikedAndDislikedVehicles is currently unused; leaving for testing utilities.

  // --------------------------------------------------------------------
  // 8) UI Helpers and Build Methods
  // --------------------------------------------------------------------
  TextStyle _customFont(double fontSize, FontWeight fontWeight, Color color) {
    return GoogleFonts.montserrat(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // Update the function signature to accept dynamic instead of Vehicle
  void _markAsInterested(dynamic vehicle) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.getLikedVehicles.contains(vehicle.id)) {
        await userProvider.unlikeVehicle(vehicle.id);
      } else {
        await userProvider.likeVehicle(vehicle.id);
      }
      setState(() {});
    } catch (e) {
      print('Error in _markAsInterested: $e');
    }
  }

  // Handle bulk offer logic
  void _onBulkOfferPressed() {
    Navigator.pushNamed(
      context,
      '/bulkOffer',
      arguments: _selectedVehicleIdsForOffer.toList(),
    );
  }

  // Handle individual offers for selected vehicles
  void _onIndividualOfferPressed() {
    Navigator.pushNamed(
      context,
      '/individualOffer',
      arguments: _selectedVehicleIdsForOffer.toList(),
    );
  }

  Widget _buildNoVehiclesAvailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "No Vehicles Available",
            style: _customFont(16, FontWeight.normal, Colors.white),
          ),
          const SizedBox(height: 16),
          // For testing only, you could reintroduce the button to clear liked/disliked:
          // ElevatedButton(
          //   onPressed: _clearLikedAndDislikedVehicles,
          //   style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          //   child: Text(
          //     'Clear Liked & Disliked Vehicles',
          //     style: _customFont(14, FontWeight.bold, Colors.white),
          //   ),
          // ),
        ],
      ),
    );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    // Adjust breakpoints to account for card width
    if (width >= 1500) return 4;
    if (width >= 1100) return 3;
    if (width >= 700) return 2;
    return 1;
  }

  // --------------------------------------------------------------------
  // 9) Build Method
  // --------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.getUserRole;

    // Optionally removed: admin redirect logic moved to initState

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

    // --- BEGIN: AppBar logic for selection mode ---
    PreferredSizeWidget? appBarWidget;
    if (_isSelectionMode) {
      appBarWidget = AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            setState(() {
              _selectedVehicleIdsForOffer.clear();
              _isSelectionMode = false;
            });
          },
        ),
        title: Text(
          '${_selectedVehicleIdsForOffer.length} selected',
          style: _customFont(18, FontWeight.bold, Colors.white),
        ),
      );
    } else {
      appBarWidget = kIsWeb
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: WebNavigationBar(
                isCompactNavigation: _isCompactNavigation(context),
                currentRoute: '/truckPage',
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            )
          : const CustomAppBar(showBackButton: false);
    }
    // --- END: AppBar logic for selection mode ---

    return Scaffold(
      key: _scaffoldKey,
      appBar: appBarWidget,
      drawer: (kIsWeb && _isCompactNavigation(context))
          ? Drawer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.black, Color(0xFF2F7FFD)],
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
                              child: const Icon(
                                Icons.local_shipping,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children: navigationItems.map((item) {
                          bool isActive = '/truckPage' == item.route;
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              // View mode tabs (All vs. Fleet) and company selector when in Fleet mode
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    if (userRole == 'dealer')
                      DefaultTabController(
                        length: 3,
                        initialIndex: _isTradeInMode
                            ? 2
                            : (_isOemMode ? 1 : 0),
                        child: TabBar(
                          labelColor: const Color(0xFFFF4E00),
                          unselectedLabelColor: Colors.white,
                          indicatorColor: const Color(0xFFFF4E00),
                          onTap: (index) async {
                            setState(() {
                              _isOemMode = index == 1;
                              _isTradeInMode = index == 2;
                              _isFleetMode =
                                  false; // disable fleet UI in dealer tabs
                            });
                            if (_isOemMode) {
                              await _loadOemBrands();
                              setState(() {
                                displayedVehicles = [];
                                _totalFilteredVehicles = 0;
                              });
                            } else if (_isTradeInMode) {
                              await _loadTradeInBrands();
                              setState(() {
                                displayedVehicles = [];
                                _totalFilteredVehicles = 0;
                              });
                            } else {
                              setState(() => _isLoading = true);
                              _loadInitialVehicles();
                            }
                          },
                          tabs: const [
                            Tab(text: 'All Stock'),
                            Tab(text: 'OEM'),
                            Tab(text: 'Trade-In'),
                          ],
                        ),
                      ),
                    // OEM brand list moved to main content body below
                    if (_isFleetMode) ...[
                      const SizedBox(height: 8),
                      // Only show dropdown when live fleets exist
                      if (_companyOptions
                          .where((c) => c != 'All')
                          .isNotEmpty) ...[
                        DropdownButton<String>(
                          style: _customFont(
                              14, FontWeight.normal, const Color(0xFFFF4E00)),
                          value: (_selectedCompany != null &&
                                  _selectedCompany != 'All' &&
                                  _companyOptions.contains(_selectedCompany))
                              ? _selectedCompany
                              : null,
                          hint: Text(
                            'Select Company',
                            style: _customFont(
                                14, FontWeight.normal, Colors.white),
                          ),
                          dropdownColor: Colors.grey[900],
                          items: _companyOptions
                              .where((c) => c != 'All')
                              .map((fleetName) => DropdownMenuItem(
                                    value: fleetName,
                                    child: Text(
                                      fleetName,
                                      style: _customFont(
                                          14, FontWeight.normal, Colors.white),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCompany = value;
                              _isLoading = true;
                            });
                            _loadInitialVehicles();
                          },
                        ),
                      ],
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'All Vehicles Total: $_totalFilteredVehicles',
                          style: _customFont(16, FontWeight.bold, Colors.white),
                        ),
                        Row(
                          children: [
                            if (_isOemMode &&
                                widget.selectedBrand != null &&
                                widget.selectedBrand!.isNotEmpty &&
                                widget.selectedBrand != 'All')
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final nav = Navigator.of(context);
                                  if (nav.canPop()) {
                                    nav.pop();
                                  } else {
                                    // No back stack (e.g., deep link) → jump to OEM brands list
                                    await nav.pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => const TruckPage(
                                          openOemTab: true,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.swap_horiz, size: 18),
                                label: const Text('Change Brand'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFFF4E00),
                                  side: const BorderSide(
                                      color: Color(0xFFFF4E00)),
                                  shape: const StadiumBorder(),
                                ),
                              ),
                            if (_isTradeInMode &&
                                widget.selectedTradeInBrand != null &&
                                widget.selectedTradeInBrand!.isNotEmpty &&
                                widget.selectedTradeInBrand != 'All')
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final nav = Navigator.of(context);
                                  if (nav.canPop()) {
                                    nav.pop();
                                  } else {
                                    // No back stack (e.g., deep link) → jump to Trade-In brands list
                                    await nav.pushReplacement(
                                      MaterialPageRoute(
                                        builder: (_) => const TruckPage(
                                          openTradeInTab: true,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.swap_horiz, size: 18),
                                label: const Text('Change Brand'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFFF4E00),
                                  side: const BorderSide(
                                      color: Color(0xFFFF4E00)),
                                  shape: const StadiumBorder(),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(Icons.tune, color: Colors.white),
                              onPressed: _showFilterDialog,
                            ),
                            if (_selectedYears.isNotEmpty ||
                                _selectedBrands.isNotEmpty ||
                                _selectedMakeModels.isNotEmpty ||
                                _selectedVehicleStatuses.isNotEmpty ||
                                _selectedTransmissions.isNotEmpty ||
                                _selectedCountries.isNotEmpty ||
                                _selectedProvinces.isNotEmpty ||
                                _selectedApplicationOfUse.isNotEmpty ||
                                _selectedConfigs.isNotEmpty ||
                                _selectedVehicleType.isNotEmpty)
                              TextButton(
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
                                    _selectedCompany = 'All';
                                    _isFleetMode = false;
                                  });
                                  _loadInitialVehicles();
                                },
                                child: const Text(
                                  "Clear Filters",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Main body
              Expanded(
                child: _isOemMode
                    ? _buildOemContent(context)
                    : (_isTradeInMode
                        ? _buildTradeInContent(context)
                        : _buildAllContent(context)),
              ),
            ],
          ),
          // Bulk/Individual offer buttons at bottom-right
          if (_isSelectionMode && _selectedVehicleIdsForOffer.isNotEmpty)
            Positioned(
              bottom: 16,
              right: 16,
              child: Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4E00)),
                    onPressed: _onBulkOfferPressed,
                    child: Text(
                      'Place Bulk Offer (${_selectedVehicleIdsForOffer.length})',
                      style: _customFont(14, FontWeight.bold, Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F7FFF)),
                    onPressed: _onIndividualOfferPressed,
                    child: Text(
                      'Place Individual Offers (${_selectedVehicleIdsForOffer.length})',
                      style: _customFont(14, FontWeight.bold, Colors.white),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar:
          (kIsWeb || userRole == 'admin' || userRole == 'sales representative')
              ? null
              : SafeArea(
                  top: false,
                  bottom: true,
                  maintainBottomViewPadding: true,
                  minimum: EdgeInsets.only(
                    bottom: () {
                      final mq = MediaQuery.of(context);
                      final maxSystemBottom = [
                        mq.systemGestureInsets.bottom,
                        mq.viewPadding.bottom,
                        mq.viewInsets.bottom,
                      ].reduce((a, b) => a > b ? a : b);
                      final extra = maxSystemBottom - mq.padding.bottom;
                      final extraPad = extra > 0 ? extra : 0.0;
                      return extraPad > 8.0 ? extraPad : 8.0;
                    }(),
                  ),
                  child: CustomBottomNavigation(
                    selectedIndex: _selectedIndex,
                    onItemTapped: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  ),
                ),
    );
  }

  // =============================
  // Content builders
  // =============================
  Widget _buildOemContent(BuildContext context) {
    final hasBrand = widget.selectedBrand != null &&
        widget.selectedBrand!.isNotEmpty &&
        widget.selectedBrand != 'All';
    if (hasBrand) {
      if (_isLoading) {
        return Center(
          child: Image.asset(
            'lib/assets/Loading_Logo_CTP.gif',
            width: 100,
            height: 100,
          ),
        );
      }
      return displayedVehicles.isNotEmpty
          ? _buildVehicleGrid(context)
          : _buildNoVehiclesAvailable();
    }
    // No brand selected → show brand list
    if (_isLoadingOemBrands) {
      return const Center(
        child: SizedBox(
          height: 32,
          width: 32,
          child: CircularProgressIndicator(
              color: Color(0xFFFF4E00), strokeWidth: 2),
        ),
      );
    }
    if (_oemBrands.isEmpty) {
      return Center(
        child: Text(
          'No OEM brands available yet.',
          style: _customFont(14, FontWeight.w500, Colors.white70),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemBuilder: (context, index) {
        final brand = _oemBrands[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TruckPage(selectedBrand: brand),
              ),
            );
          },
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              brand,
              style: _customFont(16, FontWeight.w600, Colors.white),
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemCount: _oemBrands.length,
    );
  }

  Widget _buildTradeInContent(BuildContext context) {
    final hasBrand = widget.selectedTradeInBrand != null &&
        widget.selectedTradeInBrand!.isNotEmpty &&
        widget.selectedTradeInBrand != 'All';
    if (hasBrand) {
      if (_isLoading) {
        return Center(
          child: Image.asset(
            'lib/assets/Loading_Logo_CTP.gif',
            width: 100,
            height: 100,
          ),
        );
      }
      return displayedVehicles.isNotEmpty
          ? _buildVehicleGrid(context)
          : _buildNoVehiclesAvailable();
    }
    // No brand selected → show brand list
    if (_isLoadingTradeInBrands) {
      return const Center(
        child: SizedBox(
          height: 32,
          width: 32,
          child: CircularProgressIndicator(
              color: Color(0xFFFF4E00), strokeWidth: 2),
        ),
      );
    }
    if (_tradeInBrands.isEmpty) {
      return Center(
        child: Text(
          'No Trade-In brands available yet.',
          style: _customFont(14, FontWeight.w500, Colors.white70),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemBuilder: (context, index) {
        final brand = _tradeInBrands[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TruckPage(selectedTradeInBrand: brand),
              ),
            );
          },
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              brand,
              style: _customFont(16, FontWeight.w600, Colors.white),
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemCount: _tradeInBrands.length,
    );
  }

  Widget _buildAllContent(BuildContext context) {
    if (_isFleetMode && _selectedCompany == null) {
      return _buildNoVehiclesAvailable();
    }
    if (_isLoading) {
      return Center(
        child: Image.asset(
          'lib/assets/Loading_Logo_CTP.gif',
          width: 100,
          height: 100,
        ),
      );
    }
    return displayedVehicles.isNotEmpty
        ? _buildVehicleGrid(context)
        : _buildNoVehiclesAvailable();
  }

  Widget _buildVehicleGrid(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo is ScrollEndNotification) {
          _scrollListener();
        }
        return false;
      },
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(24),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _calculateCrossAxisCount(context),
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          mainAxisExtent: 600,
        ),
        itemCount: displayedVehicles.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < displayedVehicles.length) {
            final vehicle = displayedVehicles[index];
            return TruckCard(
              vehicle: vehicle,
              onInterested: _markAsInterested,
              isSelectionMode: _isSelectionMode,
              borderColor: _selectedVehicleIdsForOffer.contains(vehicle.id)
                  ? const Color(0xFFFF4E00)
                  : null,
              key: ValueKey(vehicle.id),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: const CircularProgressIndicator(color: Color(0xFFFF4E00)),
            ),
          );
        },
      ),
    );
  }

  // =============================
  // Filtering helpers
  // =============================
  // (Removed) Non-OEM brand filter helper, not used in All Stock

  Future<void> _ensureAllOemUserIdsLoaded() async {
    if (_allOemUserIdsLoaded) return;
    try {
      final usersRef = FirebaseFirestore.instance.collection('users');
      final snapshots = await Future.wait([
        usersRef.where('userRole', whereIn: ['oem', 'OEM', 'Oem']).get(),
        usersRef.where('role', whereIn: ['oem', 'OEM', 'Oem']).get(),
      ]);
      for (final snap in snapshots) {
        for (final doc in snap.docs) {
          _allOemUserIds.add(doc.id);
        }
      }
      _allOemUserIdsLoaded = true;
    } catch (e) {
      debugPrint('Error loading all OEM userIds: $e');
      _allOemUserIdsLoaded = true; // avoid repeated attempts
    }
  }

  bool _isVehicleOemOwned(Vehicle v) {
    final role = (v.ownerRole ?? '').trim().toLowerCase();
    if (role == 'oem') return true;
    if (_allOemUserIds.contains(v.userId)) return true;
    // Heuristic: if oemBrand is present, treat as OEM-owned
    final ob = (v.oemBrand ?? '').trim();
    return ob.isNotEmpty;
  }

  Future<void> _ensureAllTradeInUserIdsLoaded() async {
    if (_allTradeInUserIdsLoaded) return;
    try {
      final usersRef = FirebaseFirestore.instance.collection('users');
      final snapshots = await Future.wait([
        usersRef.where('userRole', whereIn: ['tradein', 'trade-in']).get(),
        usersRef.where('role', whereIn: ['tradein', 'trade-in']).get(),
      ]);
      for (final snap in snapshots) {
        for (final doc in snap.docs) {
          _allTradeInUserIds.add(doc.id);
        }
      }
      _allTradeInUserIdsLoaded = true;
    } catch (e) {
      debugPrint('Error loading all Trade-In userIds: $e');
      _allTradeInUserIdsLoaded = true; // avoid repeated attempts
    }
  }
}

// Extension to capitalize the first letter of a string (if you need it)
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// Function to send push notifications to all dealers
Future<void> sendPushNotificationToDealers(String vehicleName) async {
  try {
    // Fetch all dealer tokens from Firestore
    final dealersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'dealer')
        .get();

    for (var dealer in dealersSnapshot.docs) {
      final token = dealer.data()['fcmToken'];
      if (token != null) {
        await FirebaseMessaging.instance.sendMessage(
          to: token,
          data: {
            'title': 'New Vehicle Available',
            'body': 'Check out the new $vehicleName now available!',
          },
        );
      }
    }
  } catch (e) {
    debugPrint('Error sending push notifications: $e');
  }
}

// Call this function when a vehicle is pushed to live
void onVehiclePushedToLive(String vehicleName) {
  sendPushNotificationToDealers(vehicleName);
}
