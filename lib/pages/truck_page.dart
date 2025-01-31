// lib/pages/truck_page.dart

import 'package:ctp/components/custom_app_bar.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

// Define the FilterOperation enum to handle various filter operations
enum FilterOperation {
  equals,
  contains,
  // Since we're using predefined values, we might not need greaterThan, lessThan
}

// Define the FilterCriterion class to encapsulate filter criteria
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
  final String? selectedBrand; // Add this parameter

  const TruckPage({
    super.key,
    this.vehicleType,
    this.selectedBrand, // Add this
  });

  @override
  _TruckPageState createState() => _TruckPageState();
}

class _TruckPageState extends State<TruckPage> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;
  final int _itemsPerPage = 10; // Number of items to load per page
  int _currentPage = 0; // Current page index
  int _selectedIndex = 1; // Set initial selected index to the trucks tab
  List<Vehicle> swipedVehicles = []; // Track swiped vehicles
  List<Vehicle> displayedVehicles = []; // Vehicles currently displayed
  List<String> swipedDirections = []; // Track swipe directions for undo
  int loadedVehicleIndex = 0; // Index to track loaded vehicles
  bool _hasReachedEnd = false; // Track if all cards are swiped
  bool _isLoading = true; // Track loading state
  bool _isFiltering = false; // Track filtering state

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
  // 4) Initialization and Data Loading
  // --------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
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
        // Start with only Live vehicles
        var filteredVehicles = vehicleProvider.vehicles
            .where((vehicle) => vehicle.vehicleStatus == 'Live');

        // Add brand filter if selectedBrand is specified
        if (widget.selectedBrand != null) {
          filteredVehicles = filteredVehicles.where(
              (vehicle) => vehicle.brands.contains(widget.selectedBrand));
        }

        // Apply selected filters
        filteredVehicles = _applySelectedFilters(filteredVehicles);

        displayedVehicles = filteredVehicles.take(_itemsPerPage).toList();
        _currentPage = 1;
        _isLoading = false;
        loadedVehicleIndex = displayedVehicles.length;
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
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);

      int startIndex = _currentPage * _itemsPerPage;
      int endIndex = startIndex + _itemsPerPage;

      // Start with only Live vehicles
      var filteredVehicles = vehicleProvider.vehicles
          .where((vehicle) => vehicle.vehicleStatus == 'Live');

      // Add brand filter if selectedBrand is specified
      if (widget.selectedBrand != null) {
        filteredVehicles = filteredVehicles
            .where((vehicle) => vehicle.brands.contains(widget.selectedBrand));
      }

      // Apply selected filters
      filteredVehicles = _applySelectedFilters(filteredVehicles);

      List<Vehicle> moreVehicles =
          filteredVehicles.skip(startIndex).take(_itemsPerPage).toList();

      if (moreVehicles.isNotEmpty) {
        setState(() {
          displayedVehicles.addAll(moreVehicles);
          _currentPage++;
          _isLoadingMore = false;
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

  // Helper method to apply all selected filters
  Iterable<Vehicle> _applySelectedFilters(Iterable<Vehicle> vehicles) {
    return vehicles.where((vehicle) {
      // Year Filter
      if (_selectedYears.isNotEmpty && !_selectedYears.contains('All')) {
        if (!_selectedYears.contains(vehicle.year)) return false;
      }

      // Brand Filter
      if (_selectedBrands.isNotEmpty && !_selectedBrands.contains('All')) {
        if (!vehicle.brands.any((brand) => _selectedBrands.contains(brand)))
          return false;
      }

      // Make Model Filter
      if (_selectedMakeModels.isNotEmpty &&
          !_selectedMakeModels.contains('All')) {
        if (!_selectedMakeModels.contains(vehicle.makeModel)) return false;
      }

      // Vehicle Status Filter
      if (_selectedVehicleStatuses.isNotEmpty &&
          !_selectedVehicleStatuses.contains('All')) {
        if (!_selectedVehicleStatuses.contains(vehicle.vehicleStatus))
          return false;
      }

      // Transmission Filter
      if (_selectedTransmissions.isNotEmpty &&
          !_selectedTransmissions.contains('All')) {
        if (!_selectedTransmissions.contains(vehicle.transmissionType))
          return false;
      }

      // Country Filter
      if (_selectedCountries.isNotEmpty &&
          !_selectedCountries.contains('All')) {
        if (!_selectedCountries.contains(vehicle.country)) return false;
      }

      // Province Filter
      if (_selectedProvinces.isNotEmpty &&
          !_selectedProvinces.contains('All')) {
        if (!_selectedProvinces.contains(vehicle.province)) return false;
      }

      // Application Of Use Filter
      if (_selectedApplicationOfUse.isNotEmpty &&
          !_selectedApplicationOfUse.contains('All')) {
        if (!_selectedApplicationOfUse.contains(vehicle.application))
          return false;
      }

      // Config Filter
      if (_selectedConfigs.isNotEmpty && !_selectedConfigs.contains('All')) {
        if (!_selectedConfigs.contains(vehicle.config)) return false;
      }

      // Vehicle Type Filter
      if (_selectedVehicleType.isNotEmpty &&
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
                });
                Navigator.pop(context);
                _loadInitialVehicles();
              },
            ),
            TextButton(
              child: Text('Apply',
                  style: GoogleFonts.montserrat(color: Color(0xFFFF4E00))),
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
      await userProvider
          .clearLikedVehicles(); // Assuming you want to clear liked as well

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

  double _calculateHonestyPercentage(Vehicle vehicle) {
    int totalFields = 35 + 18; // Total fields and photos
    int filledFields = 0;

    try {
      final fieldsToCheck = [
        vehicle.application.toString(),
        vehicle.damageDescription,
        vehicle.engineNumber,
        vehicle.expectedSellingPrice,
        vehicle.hydraluicType,
        vehicle.makeModel,
        vehicle.mileage,
        vehicle.registrationNumber,
        vehicle.suspensionType,
        vehicle.transmissionType,
        vehicle.userId,
        vehicle.vinNumber,
        vehicle.warrentyType,
        vehicle.year,
        vehicle.vehicleType,
      ];

      for (var field in fieldsToCheck) {
        if (field.isNotEmpty) {
          filledFields++;
        }
      }

      final nullableFieldsToCheck = [
        vehicle.dashboardPhoto,
        vehicle.faultCodesPhoto,
        vehicle.licenceDiskUrl,
        vehicle.mileageImage,
        vehicle.rc1NatisFile,
      ];

      for (var field in nullableFieldsToCheck) {
        if (field.isNotEmpty) {
          filledFields++;
        }
      }

      for (var photo in vehicle.photos) {
        if (photo != null && photo.isNotEmpty) {
          filledFields++;
        }
      }

      double honestyPercentage = (filledFields / totalFields) * 100;

      return honestyPercentage;
    } catch (e) {
      return 0.0;
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildTruckCard(BuildContext context, Vehicle vehicle) {
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () {
        try {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleDetailsPage(vehicle: vehicle),
            ),
          );
        } catch (e) {
          print('Error in onTap: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Failed to load vehicle details. Please try again.'),
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.black, // Set card background to black
        shape: RoundedRectangleBorder(
          side: BorderSide(
              color: Colors.deepOrange, width: 2), // Deep orange border
          borderRadius: BorderRadius.circular(8), // Optional: add border radius
        ),
        child: SizedBox(
          height: size.height * 0.245, // Increased height to 0.25
          child: Row(
            children: [
              // Image on the left with rounded corners
              Expanded(
                flex: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  child: vehicle.mainImageUrl != null &&
                          vehicle.mainImageUrl!.isNotEmpty
                      ? Image.network(
                          vehicle.mainImageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'lib/assets/default_vehicle_image.png',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            );
                          },
                        )
                      : Image.asset(
                          'lib/assets/default_vehicle_image.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                ),
              ),
              // Information on the right
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Title and IconButton in the same Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${vehicle.brands.join(" ")} ${vehicle.makeModel.toString().toUpperCase()}",
                              style: _customFont(
                                size.height * 0.025,
                                FontWeight.bold,
                                Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis, // Add this line
                              maxLines:
                                  2, // Optionally add this to limit to single line
                            ),
                          ),
                          Consumer<UserProvider>(
                            builder: (context, userProvider, child) {
                              return TweenAnimationBuilder(
                                duration: Duration(milliseconds: 200),
                                tween: Tween<double>(
                                  begin: userProvider.getLikedVehicles
                                          .contains(vehicle.id)
                                      ? 0.0
                                      : 1.0,
                                  end: userProvider.getLikedVehicles
                                          .contains(vehicle.id)
                                      ? 1.0
                                      : 0.0,
                                ),
                                builder: (context, double value, child) {
                                  return Transform.scale(
                                    scale: 1 + (value * 0.2),
                                    child: IconButton(
                                      icon: Icon(
                                        userProvider.getLikedVehicles
                                                .contains(vehicle.id)
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: userProvider.getLikedVehicles
                                                .contains(vehicle.id)
                                            ? Colors.red
                                            : Colors.white,
                                      ),
                                      onPressed: () =>
                                          _markAsInterested(vehicle),
                                    ),
                                  );
                                },
                              );
                            },
                          )
                        ],
                      ),
                      SizedBox(height: 8),
                      // Info rows in a simple Column
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Year', vehicle.year.toString()),
                          _buildInfoRow('Mileage', vehicle.mileage),
                          _buildInfoRow('Gearbox', vehicle.transmissionType),
                          _buildInfoRow('Config', vehicle.config),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            '${title.capitalize()}: ',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Expanded(
            child: Text(value ?? 'N/A', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _markAsInterested(Vehicle vehicle) async {
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              "For TESTING PURPOSES ONLY the below button can be used to loop through all the trucks on the database",
              style: _customFont(16, FontWeight.normal, Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _clearLikedAndDislikedVehicles,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'Clear Liked & Disliked Vehicles',
              style: _customFont(14, FontWeight.bold, Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------
  // 9) Build Method
  // --------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: CustomAppBar(),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Add vehicle count display
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Vehicles Total: ${displayedVehicles.length}',
                  style: _customFont(16, FontWeight.bold, Colors.white),
                ),
                Row(
                  children: [
                    // Filter Icon Button
                    IconButton(
                      icon: const Icon(
                        Icons.tune,
                        color: Colors.white,
                      ),
                      onPressed: _showFilterDialog,
                    ),
                    // Clear Filters Button
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
          Expanded(
            child: _isLoading || _isFiltering
                ? Center(
                    child: Image.asset(
                      'lib/assets/Loading_Logo_CTP.gif',
                      width: 100,
                      height: 100,
                    ),
                  )
                : displayedVehicles.isNotEmpty
                    ? NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification notification) {
                          if (notification is ScrollEndNotification) {
                            _scrollListener();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount:
                              displayedVehicles.length + 1, // +1 for the loader
                          itemBuilder: (context, index) {
                            if (index < displayedVehicles.length) {
                              return _buildTruckCard(
                                  context, displayedVehicles[index]);
                            } else {
                              // Loader at the bottom
                              return _isLoadingMore
                                  ? Center(child: CircularProgressIndicator())
                                  : SizedBox.shrink();
                            }
                          },
                        ),
                      )
                    : _buildNoVehiclesAvailable(),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
