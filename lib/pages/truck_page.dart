// lib/pages/truck_page.dart

import 'package:ctp/components/custom_app_bar.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/honesty_bar.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final String? vehicleType; // Optional vehicleType, null means show all

  const TruckPage({super.key, this.vehicleType});

  @override
  _TruckPageState createState() => _TruckPageState();
}

class _TruckPageState extends State<TruckPage> {
  late AppinioSwiperController controller;
  int _selectedIndex = 1; // Set initial selected index to the trucks tab
  List<Vehicle> swipedVehicles = []; // Track swiped vehicles
  List<Vehicle> displayedVehicles = []; // Vehicles currently displayed
  List<String> swipedDirections = []; // Track swipe directions for undo
  int loadedVehicleIndex = 0; // Index to track loaded vehicles
  bool _hasReachedEnd = false; // Track if all cards are swiped
  bool _isLoading = true; // Track loading state
  bool _isFiltering = false; // Track filtering state

  // List to hold dynamic filter criteria
  List<FilterCriterion> filterCriteria = [];

  // Map to hold filter options for each field
  Map<String, List<dynamic>> filterOptions = {};

  @override
  void initState() {
    super.initState();
    controller = AppinioSwiperController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialVehicles();
    });
  }

  void _loadInitialVehicles() async {
    try {
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Fetch vehicles based on the selected vehicleType
      await vehicleProvider.fetchVehicles(userProvider,
          vehicleType: widget.vehicleType);

      print('Total vehicles fetched: ${vehicleProvider.vehicles.length}');
      print('User Preferred Brands: ${userProvider.getPreferredBrands}');
      print('User Liked Vehicles: ${userProvider.getLikedVehicles}');
      print('User Disliked Vehicles: ${userProvider.getDislikedVehicles}');

      setState(() {
        // Separate vehicles based on whether they match preferred brands
        List<Vehicle> preferredVehicles = [];
        List<Vehicle> nonPreferredVehicles = [];

        for (var vehicle in vehicleProvider.vehicles) {
          bool matchesPreferredBrand = userProvider.getPreferredBrands.any(
              (brand) => vehicle.makeModel
                  .toLowerCase()
                  .contains(brand.toLowerCase()));

          bool isNotDraft = vehicle.vehicleStatus != 'Draft';

          if (matchesPreferredBrand && isNotDraft) {
            preferredVehicles.add(vehicle);
          } else if (isNotDraft) {
            nonPreferredVehicles.add(vehicle);
          }
        }

        print('Preferred Vehicles: ${preferredVehicles.length}');
        print('Non-Preferred Vehicles: ${nonPreferredVehicles.length}');

        // Combine preferred vehicles first, followed by non-preferred vehicles
        displayedVehicles = [...preferredVehicles, ...nonPreferredVehicles];

        loadedVehicleIndex = displayedVehicles.length;
        _isLoading = false; // Loading complete

        print('Displayed Vehicles: ${displayedVehicles.length}');
        print(
            'Displayed Vehicle IDs: ${displayedVehicles.map((v) => v.id).toList()}');

        // Initialize filter options
        _initializeFilterOptions(vehicleProvider.vehicles);
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

  void _initializeFilterOptions(List<Vehicle> vehicles) {
    // Collect distinct values for each filterable field
    filterOptions = {
      'application': vehicles
          .map((v) => v.application)
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(),
      'expectedSellingPrice': _getPriceRanges(vehicles),
      'hydraluicType': vehicles
          .map((v) => v.hydraluicType)
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(),
      'makeModel': vehicles
          .map((v) => v.makeModel)
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(),
      'mileage': _getMileageRanges(vehicles),
      'transmissionType': vehicles
          .map((v) => v.transmissionType)
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(),
      'configuration': vehicles
          .map((v) => v.config)
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(),
      'vehicleType': vehicles
          .map((v) => v.vehicleType)
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(),
      'year': vehicles
          .map((v) => v.year)
          .where((value) => value.isNotEmpty)
          .toSet()
          .map((year) => int.tryParse(year) ?? 0)
          .toSet()
          .toList()
        ..sort(),
      'adminData.settlementAmount': _getSettlementAmountRanges(vehicles),
      'maintenance.oemInspectionType': vehicles
          .map((v) => v.maintenance.oemInspectionType)
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(),
    };
  }

  List<String> _getPriceRanges(List<Vehicle> vehicles) {
    // You can define your own price ranges
    return [
      '< 100,000',
      '100,000 - 500,000',
      '500,000 - 1,000,000',
      '> 1,000,000'
    ];
  }

  List<String> _getMileageRanges(List<Vehicle> vehicles) {
    // Define mileage ranges
    return ['< 50,000', '50,000 - 100,000', '100,000 - 200,000', '> 200,000'];
  }

  List<String> _getSettlementAmountRanges(List<Vehicle> vehicles) {
    // Define settlement amount ranges
    return ['< 50,000', '50,000 - 100,000', '100,000 - 200,000', '> 200,000'];
  }

  void _loadNextVehicle() {
    try {
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      while (loadedVehicleIndex < vehicleProvider.vehicles.length) {
        final nextVehicle = vehicleProvider.vehicles[loadedVehicleIndex];
        if (nextVehicle.vehicleStatus != 'Draft' &&
            !userProvider.getLikedVehicles.contains(nextVehicle.id) &&
            !userProvider.getDislikedVehicles.contains(nextVehicle.id)) {
          setState(() {
            displayedVehicles.add(nextVehicle);
            loadedVehicleIndex++;
          });
          return;
        }
        loadedVehicleIndex++;
      }
      setState(() {
        _hasReachedEnd = true;
      });
    } catch (e) {
      print('Error in _loadNextVehicle: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load the next vehicle. Please try again.'),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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
        vehicle.application,
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
        if (field != null && field.isNotEmpty) {
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

  void _applyFilters(List<FilterCriterion> filters) {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      _isFiltering = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        displayedVehicles = vehicleProvider.vehicles.where((vehicle) {
          // Apply each filter criterion
          for (var filter in filters) {
            var fieldValue = _getFieldValue(vehicle, filter.fieldName);
            if (!_evaluateFilter(fieldValue, filter)) {
              return false; // If any filter fails, exclude the vehicle
            }
          }

          // Existing conditions
          bool isLikedOrDisliked =
              userProvider.getLikedVehicles.contains(vehicle.id) ||
                  userProvider.getDislikedVehicles.contains(vehicle.id);
          bool isNotDraft = vehicle.vehicleStatus != 'Draft';
          bool matchesVehicleType = widget.vehicleType == null ||
              vehicle.vehicleType == widget.vehicleType;

          return !isLikedOrDisliked && isNotDraft && matchesVehicleType;
        }).toList();

        loadedVehicleIndex = displayedVehicles.length;
        _isFiltering = false;

        print('Vehicles after applying filters: ${displayedVehicles.length}');
        print(
            'Displayed Vehicle IDs: ${displayedVehicles.map((v) => v.id).toList()}');
      });
    });
  }

  // Helper method to retrieve field value from Vehicle based on field name
  dynamic _getFieldValue(Vehicle vehicle, String fieldName) {
    switch (fieldName) {
      case 'application':
        return vehicle.application;
      case 'expectedSellingPrice':
        return double.tryParse(vehicle.expectedSellingPrice
                .replaceAll(',', '')
                .replaceAll(' ', '')) ??
            0.0;
      case 'expectedSellingPriceRange':
        return vehicle.expectedSellingPrice; // We will handle ranges in filter
      case 'hydraluicType':
        return vehicle.hydraluicType;
      case 'makeModel':
        return vehicle.makeModel;
      case 'mileage':
        return int.tryParse(
                vehicle.mileage.replaceAll(',', '').replaceAll(' ', '')) ??
            0;
      case 'mileageRange':
        return vehicle.mileage; // Handle ranges
      case 'transmissionType':
        return vehicle.transmissionType;
      case 'config':
        return vehicle.config;
      case 'vehicleType':
        return vehicle.vehicleType;
      case 'year':
        return int.tryParse(vehicle.year.replaceAll(' ', '')) ?? 0;
      case 'adminData.settlementAmount':
        return double.tryParse(vehicle.adminData.settlementAmount
                .replaceAll(',', '')
                .replaceAll(' ', '')) ??
            0.0;
      case 'settlementAmountRange':
        return vehicle.adminData.settlementAmount; // Handle ranges
      case 'maintenance.oemInspectionType':
        return vehicle.maintenance.oemInspectionType;
      // Add more cases for additional fields
      default:
        return null;
    }
  }

  // Helper method to evaluate a single filter criterion
  bool _evaluateFilter(dynamic fieldValue, FilterCriterion filter) {
    switch (filter.operation) {
      case FilterOperation.equals:
        return fieldValue == filter.value;
      case FilterOperation.contains:
        if (fieldValue is String && filter.value is String) {
          return fieldValue.toLowerCase() == filter.value.toLowerCase();
        }
        return false;
      // Since we're using predefined values, we might not need greaterThan, lessThan
      default:
        return false;
    }
  }

  void _clearFilters() {
    setState(() {
      _isFiltering = true; // Start filtering
      filterCriteria.clear();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      _loadInitialVehicles();
      setState(() {
        _isFiltering = false; // End filtering
      });
    });
  }

  Future<void> _showFilterDialog() async {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);

    // Define all filterable fields along with their data types
    final List<Map<String, dynamic>> filterableFields = [
      {'name': 'Application', 'field': 'application', 'type': 'String'},
      {
        'name': 'Expected Selling Price',
        'field': 'expectedSellingPriceRange',
        'type': 'range'
      },
      {'name': 'Hydraulic Type', 'field': 'hydraluicType', 'type': 'String'},
      {'name': 'Make Model', 'field': 'makeModel', 'type': 'String'},
      {'name': 'Mileage', 'field': 'mileageRange', 'type': 'range'},
      {'name': 'Transmission', 'field': 'transmissionType', 'type': 'String'},
      {'name': 'Config', 'field': 'config', 'type': 'String'},
      {'name': 'Vehicle Type', 'field': 'vehicleType', 'type': 'String'},
      {'name': 'Year', 'field': 'year', 'type': 'int'},
      {
        'name': 'Settlement Amount',
        'field': 'settlementAmountRange',
        'type': 'range'
      },
      {
        'name': 'OEM Inspection Type',
        'field': 'maintenance.oemInspectionType',
        'type': 'String'
      },
      // Add more fields as needed
    ];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Filter Vehicles'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Display existing filter criteria
                    ...filterCriteria.map((criterion) {
                      // Find the field details
                      final fieldDetails = filterableFields.firstWhere(
                          (field) => field['field'] == criterion.fieldName,
                          orElse: () => {});

                      if (fieldDetails == null) return SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Field Selection Dropdown
                          DropdownButtonFormField<String>(
                            decoration:
                                const InputDecoration(labelText: 'Field'),
                            value: criterion.fieldName,
                            items: filterableFields.map((field) {
                              return DropdownMenuItem<String>(
                                value: field['field'],
                                child: Text(field['name']),
                              );
                            }).toList(),
                            onChanged: (newField) {
                              setStateDialog(() {
                                criterion.fieldName = newField!;
                                // Optionally reset operation and value
                                criterion.operation = FilterOperation.equals;
                                criterion.value = null;
                              });
                            },
                          ),
                          SizedBox(height: 8),
                          // Value Selection
                          _buildValueDropdown(fieldDetails['field'] as String,
                              criterion, setStateDialog),
                          SizedBox(height: 8),
                          // Remove Button aligned to the right
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon:
                                  Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () {
                                setStateDialog(() {
                                  filterCriteria.remove(criterion);
                                });
                              },
                            ),
                          ),
                          Divider(), // Optional: add a divider between filters
                        ],
                      );
                    }).toList(),
                    SizedBox(height: 10),
                    // Button to add a new filter criterion
                    ElevatedButton.icon(
                      onPressed: () {
                        setStateDialog(() {
                          filterCriteria.add(
                            FilterCriterion(
                              fieldName: filterableFields.first['field'],
                              operation: FilterOperation.equals,
                              value: null,
                            ),
                          );
                        });
                      },
                      icon: Icon(Icons.add),
                      label: Text('Add Filter'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    _applyFilters(filterCriteria);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper method to build value dropdown based on field
  Widget _buildValueDropdown(
      String fieldName, FilterCriterion criterion, StateSetter setStateDialog) {
    List<dynamic> options = filterOptions[fieldName] ?? [];

    return DropdownButtonFormField<dynamic>(
      decoration: const InputDecoration(labelText: 'Value'),
      value: criterion.value,
      items: options.map((option) {
        return DropdownMenuItem<dynamic>(
          value: option,
          child: Text(option.toString()),
        );
      }).toList(),
      onChanged: (newValue) {
        setStateDialog(() {
          criterion.value = newValue;
        });
      },
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: CustomAppBar(),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Move the filter controls here
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
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
                if (filterCriteria.isNotEmpty)
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text(
                      "Clear Filters",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                _isLoading ||
                        _isFiltering // Show loading icon during initial load or filtering
                    ? Center(
                        child: Image.asset(
                          'lib/assets/Loading_Logo_CTP.gif',
                          width: 100, // Adjust width and height as needed
                          height: 100,
                        ),
                      )
                    : displayedVehicles.isNotEmpty
                        ? !_hasReachedEnd
                            ? AppinioSwiper(
                                key: ValueKey(displayedVehicles.length),
                                controller: controller,
                                swipeOptions: const SwipeOptions.symmetric(
                                    vertical: false, horizontal: false),
                                cardCount: displayedVehicles.length,
                                cardBuilder: (BuildContext context, int index) {
                                  if (index < displayedVehicles.length) {
                                    return _buildTruckCard(context, controller,
                                        displayedVehicles[index], size);
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                },
                                onSwipeEnd: (int previousIndex,
                                    int? targetIndex, direction) async {
                                  try {
                                    if (direction == AxisDirection.left ||
                                        direction == AxisDirection.right) {
                                      final vehicle =
                                          displayedVehicles[previousIndex];
                                      setState(() {
                                        swipedVehicles.add(vehicle);
                                        swipedDirections.add(
                                            direction == AxisDirection.right
                                                ? 'right'
                                                : 'left');
                                        displayedVehicles
                                            .removeAt(previousIndex);
                                      });
                                      _loadNextVehicle();

                                      final userProvider =
                                          Provider.of<UserProvider>(context,
                                              listen: false);
                                      if (direction == AxisDirection.right) {
                                        await userProvider
                                            .likeVehicle(vehicle.id);
                                      } else if (direction ==
                                          AxisDirection.left) {
                                        await userProvider
                                            .dislikeVehicle(vehicle.id);
                                      }
                                    }
                                    if (targetIndex == null) {
                                      setState(() {
                                        _hasReachedEnd = true;
                                      });
                                    }
                                  } catch (e) {
                                    print('Error in onSwipeEnd: $e');
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'An error occurred while processing your swipe.'),
                                      ),
                                    );
                                  }
                                },
                                onEnd: () {
                                  setState(() {
                                    _hasReachedEnd = true;
                                  });
                                },
                              )
                            : Center(
                                child: Text(
                                  "You've seen all the vehicles!",
                                  style: _customFont(
                                      16, FontWeight.normal, Colors.white),
                                ),
                              )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "No vehicles available",
                                  style: _customFont(
                                      16, FontWeight.normal, Colors.white),
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  child: Text(
                                    "For TESTING PURPOSES ONLY the below button can be used to loop through all the trucks on the database",
                                    style: _customFont(
                                        16, FontWeight.normal, Colors.white),
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
                                    style: _customFont(
                                        14, FontWeight.bold, Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildTruckCard(BuildContext context,
      AppinioSwiperController controller, Vehicle vehicle, Size size) {
    return GestureDetector(
        onDoubleTap: () {
          try {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VehicleDetailsPage(vehicle: vehicle),
              ),
            );
          } catch (e) {
            print('Error in onDoubleTap: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Failed to load vehicle details. Please try again.'),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            width: size.width,
            height: size.height -
                AppBar().preferredSize.height -
                80, // Adjust for app bar and bottom navigation
            margin: const EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 10), // Margin for spacing between cards
            decoration: BoxDecoration(
              color: Colors.white, // White background for the card
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.white, width: 1), // Thin white border
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                  10), // Ensure the child content respects the border radius
              child: Stack(
                children: [
                  // Image Section
                  Positioned.fill(
                    top: 0,
                    bottom:
                        size.height * 0.23, // Adjusted to prevent overlapping
                    child: Stack(
                      children: [
                        // The vehicle image or placeholder
                        Center(
                          child: vehicle.mainImageUrl != null &&
                                  vehicle.mainImageUrl!.isNotEmpty
                              ? Image.network(
                                  vehicle.mainImageUrl!,
                                  fit: BoxFit.fitHeight,
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

                        // Gradient overlay on top of the image
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.2), // Start color
                                Colors.black.withOpacity(0.2), // End color
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              stops: const [1.0, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Container for buttons and info cards
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors
                          .black, // Black background for buttons and info cards
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    EdgeInsets.only(left: size.width * 0.005),
                                child: Text(
                                  "GAUTENG, PRETORIA", // Add location text above the name
                                  style: _customFont(
                                    size.height * 0.015,
                                    FontWeight.w600,
                                    Colors.white,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          left: size.width * 0.005,
                                          bottom: size.height * 0.009),
                                      child: Text(
                                        vehicle.makeModel.length > 16
                                            ? '${vehicle.makeModel.substring(0, 15).toUpperCase()}...'
                                            : vehicle.makeModel.toUpperCase(),
                                        style: _customFont(
                                          size.height * 0.03,
                                          FontWeight.w900,
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Image.asset(
                                      'lib/assets/verified_Icon.png',
                                      width: size.width * 0.05,
                                      height: size.height * 0.05,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(height: 10),
                              _buildInfoContainer(
                                  'YEAR',
                                  vehicle.year.isNotEmpty
                                      ? vehicle.year
                                      : "N/A"),
                              const SizedBox(width: 8),
                              _buildInfoContainer(
                                  'MILEAGE',
                                  vehicle.mileage.isNotEmpty
                                      ? vehicle.mileage
                                      : "N/A"),
                              const SizedBox(width: 8),
                              _buildInfoContainer(
                                  'GEARBOX',
                                  vehicle.transmissionType.isNotEmpty
                                      ? vehicle.transmissionType
                                      : "N/A"),
                              const SizedBox(width: 8),
                              _buildInfoContainer(
                                  'CONFIG',
                                  vehicle.config.isNotEmpty
                                      ? vehicle.config
                                      : "N/A"),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Update the calls to _buildIconButton to include the label
                              _buildIconButton(
                                Icons.close,
                                const Color(0xFF2F7FFF),
                                controller,
                                'left',
                                vehicle,
                                'Not Interested', // Added label
                              ),
                              _buildCenterButton(controller),
                              _buildIconButton(
                                Icons.favorite,
                                const Color(0xFFFF4E00),
                                controller,
                                'right',
                                vehicle,
                                'Interested', // Added label
                              ),
                            ],
                          ),
                          SizedBox(height: size.height * 0.015),
                        ],
                      ),
                    ),
                  ),

                  // Honesty Bar Widget
                  Positioned(
                    top: size.height *
                        0.01, // Dynamically adjusted based on screen size
                    right: size.width * 0.03, // Dynamically adjusted
                    child: HonestyBarWidget(vehicle: vehicle),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildInfoContainer(String title, String? value) {
    var screenSize = MediaQuery.of(context).size;

    String normalizedValue = value?.trim().toLowerCase() ?? '';

    String displayValue = (title == 'GEARBOX' && value != null)
        ? (normalizedValue.contains('auto')
            ? 'AUTO'
            : normalizedValue.contains('manual')
                ? 'MANUAL'
                : value.toUpperCase())
        : value?.toUpperCase() ?? 'N/A';

    return Flexible(
      child: Container(
        height: screenSize.height * 0.06,
        width: screenSize.width * 0.22,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: _customFont(
                  screenSize.height * 0.012, FontWeight.w500, Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              displayValue,
              style: _customFont(
                  screenSize.height * 0.017, FontWeight.bold, Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // Update the _buildIconButton function to accept a label parameter
  Widget _buildIconButton(
    IconData icon,
    Color color,
    AppinioSwiperController controller,
    String direction,
    Vehicle vehicle,
    String label, // Added label
  ) {
    final size = MediaQuery.of(context).size;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          try {
            final userProvider =
                Provider.of<UserProvider>(context, listen: false);

            if (direction == 'left') {
              if (!userProvider.getDislikedVehicles.contains(vehicle.id)) {
                await userProvider.dislikeVehicle(vehicle.id);
                controller.swipeLeft();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vehicle already disliked.')),
                );
              }
            } else if (direction == 'right') {
              if (!userProvider.getLikedVehicles.contains(vehicle.id)) {
                await userProvider.likeVehicle(vehicle.id);
                controller.swipeRight();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vehicle already liked.')),
                );
              }
            }
          } catch (e) {
            print('Error in _buildIconButton: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to swipe vehicle. Please try again.'),
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.black, size: size.height * 0.025),
              SizedBox(height: 4), // Space between the icon and text
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton(AppinioSwiperController controller) {
    final size = MediaQuery.of(context).size;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          try {
            if (swipedVehicles.isNotEmpty) {
              final lastVehicle = swipedVehicles.removeLast();
              final lastDirection = swipedDirections.removeLast();
              final userProvider =
                  Provider.of<UserProvider>(context, listen: false);

              if (lastDirection == 'right') {
                await userProvider.removeLikedVehicle(lastVehicle.id);
              } else if (lastDirection == 'left') {
                await userProvider.removeDislikedVehicle(lastVehicle.id);
              }

              controller.unswipe();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No card to unswipe.'),
                ),
              );
            }
          } catch (e) {
            print('Error in _buildCenterButton: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to undo swipe. Please try again.'),
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.undo,
                color: Colors.white,
                size: size.height * 0.025,
              ),
              SizedBox(height: 4), // Space between icon and text
              Text(
                'Undo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
