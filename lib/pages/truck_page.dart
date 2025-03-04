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
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:ctp/components/trailer_card.dart'; // Trailer card widget

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

class TruckPage extends StatefulWidget {
  final String? vehicleType;
  final String? selectedBrand;

  const TruckPage({
    super.key,
    this.vehicleType,
    this.selectedBrand,
  });

  @override
  _TruckPageState createState() => _TruckPageState();
}

class _TruckPageState extends State<TruckPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool get _isLargeScreen => MediaQuery.of(context).size.width > 900;
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
  final bool _isFiltering = false;

  /// NEW: Track total number of filtered vehicles
  int _totalFilteredVehicles = 0;

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
  // 2) Hard-coded Filter Lists
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
  final List<String> _vehicleTypeOptions = ['All', 'truck', 'trailer'];

  // --------------------------------------------------------------------
  // 3) Dynamic Brand & Model Loading
  // --------------------------------------------------------------------
  final List<String> _brandOptions = ['All']; // From JSON
  List<String> _makeModelOptions = ['All']; // From JSON
  List<dynamic> _countriesData = [];

  // --------------------------------------------------------------------
  // 4) Initialization and Data Loading
  // --------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);

    // Initialize vehicle type filter if provided
    if (widget.vehicleType != null) {
      _selectedVehicleType.add(widget.vehicleType!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
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
    } catch (e) {
      debugPrint('Error loading countries from JSON: $e');
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
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      await vehicleProvider.fetchAllVehicles();

      setState(() {
        /// Base filter: only vehicles with status "Live"
        var filteredVehicles = vehicleProvider.vehicles
            .where((vehicle) => vehicle.vehicleStatus == 'Live');

        /// If a brand was passed in, apply it only if != 'All'
        if (widget.selectedBrand != null && widget.selectedBrand != 'All') {
          filteredVehicles = filteredVehicles.where(
            (vehicle) => vehicle.brands.contains(widget.selectedBrand),
          );
        }

        // Apply any user-chosen filters
        filteredVehicles = _applySelectedFilters(filteredVehicles);

        /// 1) Count them all
        _totalFilteredVehicles = filteredVehicles.length;

        /// 2) Take the first page
        displayedVehicles = filteredVehicles.take(_itemsPerPage).toList();
        _currentPage = 1;
        _isLoading = false;
        loadedVehicleIndex = displayedVehicles.length;

        /// If we already got them all in the first page, mark `_hasReachedEnd`
        _hasReachedEnd = displayedVehicles.length >= _totalFilteredVehicles;
      });
    } catch (e) {
      print('Error in _loadInitialVehicles: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load vehicles. Please try again later.'),
        ),
      );
    }
  }

  void _loadMoreVehicles() async {
    // If we've loaded all already, no need to do more
    if (_hasReachedEnd) return;

    setState(() {
      _isLoadingMore = true;
    });
    try {
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      int startIndex = _currentPage * _itemsPerPage;

      // Re-filter everything (same logic as in _loadInitialVehicles)
      var filteredVehicles = vehicleProvider.vehicles
          .where((vehicle) => vehicle.vehicleStatus == 'Live');

      if (widget.selectedBrand != null && widget.selectedBrand != 'All') {
        filteredVehicles = filteredVehicles.where(
          (vehicle) => vehicle.brands.contains(widget.selectedBrand),
        );
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
      // First apply vehicle type filter if specified in widget
      if (widget.vehicleType != null &&
          widget.vehicleType!.toLowerCase() != 'all' &&
          vehicle.vehicleType.toLowerCase() !=
              widget.vehicleType!.toLowerCase()) {
        return false;
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
      // Only apply selected vehicle type filter if widget.vehicleType is null
      if (widget.vehicleType == null &&
          _selectedVehicleType.isNotEmpty &&
          !_selectedVehicleType.contains('All')) {
        if (!_selectedVehicleType.contains(vehicle.vehicleType)) return false;
      }
      return true;
    });
  }

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
  void _clearLikedAndDislikedVehicles() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.clearDislikedVehicles();
      await userProvider.clearLikedVehicles();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Liked and disliked vehicles have been cleared.'),
        ),
      );
      _loadInitialVehicles();
    } catch (e) {
      print('Error in _clearLikedAndDislikedVehicles: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to clear vehicles. Please try again.'),
        ),
      );
    }
  }

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
    final bool showBottomNav = !_isLargeScreen && !kIsWeb;
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

    return Scaffold(
      key: _scaffoldKey,
      appBar: (_isLargeScreen || kIsWeb)
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: WebNavigationBar(
                isCompactNavigation: _isCompactNavigation(context),
                currentRoute: '/truckPage',
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            )
          : CustomAppBar(),
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
      body: Column(
        children: [
          // Vehicle count display and filter actions
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// Show the *total* number of filtered vehicles, not just the first page
                Text(
                  'All Vehicles Total: $_totalFilteredVehicles',
                  style: _customFont(16, FontWeight.bold, Colors.white),
                ),
                Row(
                  children: [
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
          ),

          // Main body
          Expanded(
            child: _isLoading || _isFiltering
                ? GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _calculateCrossAxisCount(context),
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      mainAxisExtent: 600,
                    ),
                    itemCount: 8, // Show 8 shimmer cards
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F7FFF).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: const Color(0xFF2F7FFF),
                            width: 2,
                          ),
                        ),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[900]!,
                          highlightColor: Colors.grey[800]!,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Image placeholder
                              Container(
                                height: 360, // 60% of 600
                                decoration: const BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                ),
                              ),
                              // Content area
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Title placeholder
                                      Container(
                                        height: 24,
                                        width: double.infinity,
                                        color: Colors.black12,
                                      ),
                                      const SizedBox(height: 8),
                                      // Subtitle placeholder
                                      Container(
                                        height: 16,
                                        width: 100,
                                        color: Colors.black12,
                                      ),
                                      const SizedBox(height: 24),
                                      // Spec boxes
                                      Row(
                                        children: [
                                          for (var i = 0; i < 3; i++) ...[
                                            if (i > 0) const SizedBox(width: 8),
                                            Container(
                                              height: 36,
                                              width: 80,
                                              decoration: BoxDecoration(
                                                color: Colors.black12,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      // Progress bar placeholder
                                      Container(
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      const Spacer(),
                                      // Button placeholder
                                      Container(
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Colors.black12,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : displayedVehicles.isNotEmpty
                    ? NotificationListener<ScrollNotification>(
                        onNotification: (scrollInfo) {
                          if (scrollInfo is ScrollEndNotification) {
                            _scrollListener();
                          }
                          return false;
                        },
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(24),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _calculateCrossAxisCount(context),
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                            mainAxisExtent: 600,
                          ),
                          itemCount: displayedVehicles.length +
                              (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < displayedVehicles.length) {
                              final vehicle = displayedVehicles[index];
                              return vehicle.vehicleType == 'trailer'
                                  ? TrailerCard(
                                      trailer: vehicle.trailer!,
                                      onInterested: (trailer) {
                                        _markAsInterested(trailer);
                                      },
                                    )
                                  : TruckCard(
                                      vehicle: vehicle,
                                      onInterested: _markAsInterested,
                                    );
                            } else {
                              // Loading indicator for the next page
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                          },
                        ),
                      )
                    : _buildNoVehiclesAvailable(),
          ),
        ],
      ),
      bottomNavigationBar: showBottomNav
          ? CustomBottomNavigation(
              selectedIndex: _selectedIndex,
              onItemTapped: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            )
          : null,
    );
  }
}

// Extension to capitalize the first letter of a string (if you need it)
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
