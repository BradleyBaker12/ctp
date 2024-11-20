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

  // List to hold dynamic filter criteria
  List<FilterCriterion> filterCriteria = [];

  // Map to hold filter options for each field
  Map<String, List<dynamic>> filterOptions = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialVehicles();
    });
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

  // **Modified Method: Load Initial Vehicles Using fetchAllVehicles**
  void _loadInitialVehicles() async {
    try {
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // **Use the new fetchAllVehicles method to fetch all vehicles**
      await vehicleProvider.fetchAllVehicles();

      // Debugging output to check fetched vehicles
      print('Total vehicles fetched: ${vehicleProvider.vehicles.length}');
      // Check if the fetched vehicles are empty
      if (vehicleProvider.vehicles.isEmpty) {
        print('No vehicles found in Firestore.');
      }

      print('User Preferred Brands: ${userProvider.getPreferredBrands}');
      print('User Liked Vehicles: ${userProvider.getLikedVehicles}');
      print('User Disliked Vehicles: ${userProvider.getDislikedVehicles}');

      setState(() {
        // Remove filtering based on preferred brands
        displayedVehicles = vehicleProvider.vehicles; // Show all vehicles

        // Debugging output to check displayed vehicles
        print('Displayed Vehicles: ${displayedVehicles.length}');
        if (displayedVehicles.isEmpty) {
          print('No vehicles to display after filtering.');
        }

        loadedVehicleIndex = displayedVehicles.length;
        _isLoading = false; // Loading complete

        print(
            'Displayed Vehicle IDs: ${displayedVehicles.map((v) => v.id).toList()}');

        // Initialize displayedVehicles with the first page
        displayedVehicles =
            vehicleProvider.vehicles.take(_itemsPerPage).toList();
        _currentPage = 1;
        _isLoading = false;

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

  void _loadMoreVehicles() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);

      // Calculate the start and end indices for the next page
      int startIndex = _currentPage * _itemsPerPage;
      int endIndex = startIndex + _itemsPerPage;

      // Fetch the next set of vehicles
      List<Vehicle> moreVehicles = vehicleProvider.vehicles
          .skip(startIndex)
          .take(_itemsPerPage)
          .toList();

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load more vehicles. Please try again.'),
        ),
      );
      setState(() {
        _isLoadingMore = false;
      });
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
          .map((year) => int.tryParse(year.toString()) ?? 0)
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

  void _applyFilters(List<FilterCriterion> filters) {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);

    setState(() {
      _isFiltering = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        // Temporarily show all vehicles for testing
        displayedVehicles = vehicleProvider.vehicles.where((vehicle) {
          print(
              'Checking Vehicle ID: ${vehicle.id}, Status: ${vehicle.vehicleStatus}');

          // Apply each filter criterion
          for (var filter in filters) {
            var fieldValue = _getFieldValue(vehicle, filter.fieldName);
            if (!_evaluateFilter(fieldValue, filter)) {
              print(
                  'Filter failed for Vehicle ID: ${vehicle.id} on field: ${filter.fieldName} with value: ${filter.value}');
              return false; // If any filter fails, exclude the vehicle
            }
          }

          // Existing conditions
          bool isNotDraft = vehicle.vehicleStatus != 'Draft';
          bool isLive =
              vehicle.vehicleStatus == 'Live'; // Check for Live status

          print(
              'Vehicle ID: ${vehicle.id}, Is Not Draft: $isNotDraft, Is Live: $isLive');

          return isNotDraft && isLive; // Include only Live vehicles
        }).toList();

        // Debugging output to check vehicles after applying filters
        print('Vehicles after applying filters: ${displayedVehicles.length}');
        if (displayedVehicles.isEmpty) {
          print('No vehicles match the current filters.');
        } else {
          print(
              'Displayed Vehicle IDs: ${displayedVehicles.map((v) => v.id).toList()}');
        }

        loadedVehicleIndex = displayedVehicles.length;
        _isFiltering = false;
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
                    }),
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
          height: size.height * 0.22, // Increased height to 0.25
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
                              vehicle.makeModel.toString().toUpperCase(),
                              style: _customFont(
                                size.height * 0.025,
                                FontWeight.bold,
                                Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Provider.of<UserProvider>(context, listen: false)
                                      .getLikedVehicles
                                      .contains(vehicle.id)
                                  ? Icons.favorite // Solid red heart
                                  : Icons.favorite_border, // Outlined heart
                              color: Provider.of<UserProvider>(context,
                                          listen: false)
                                      .getLikedVehicles
                                      .contains(vehicle.id)
                                  ? Colors.red // Red color for liked
                                  : Colors.white, // White color for not liked
                            ),
                            onPressed: () => _markAsInterested(vehicle),
                          ),
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
            '$title: ',
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

      if (!userProvider.getLikedVehicles.contains(vehicle.id)) {
        await userProvider.likeVehicle(vehicle.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked as Interested'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Vehicle already marked as interested.')),
        );
      }
    } catch (e) {
      print('Error in _markAsInterested: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Failed to mark vehicle as interested. Please try again.'),
        ),
      );
    }
  }

  Widget _buildNoVehiclesAvailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "No vehicles available",
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
}
