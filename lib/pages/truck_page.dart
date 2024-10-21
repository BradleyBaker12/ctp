import 'package:ctp/components/custom_app_bar.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/honesty_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
// Required for the AppBar's blur effect

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
  String? selectedMakeModel;
  String? selectedYear;
  String? selectedTransmission;
  String? selectedMileage; // <--- Add selectedMileage variable here
  bool _isFiltering = false; // Track filtering state

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

        vehicleProvider.vehicles.forEach((vehicle) {
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
        });

        // Combine preferred vehicles first, followed by non-preferred vehicles
        displayedVehicles = [...preferredVehicles, ...nonPreferredVehicles];

        loadedVehicleIndex = displayedVehicles.length;
        _isLoading = false; // Loading complete

        print('Displayed Vehicles: ${displayedVehicles.length}');
        print(
            'Displayed Vehicle IDs: ${displayedVehicles.map((v) => v.id).toList()}');
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
        vehicle.accidentFree,
        vehicle.application,
        vehicle.bookValue,
        vehicle.damageDescription,
        vehicle.engineNumber,
        vehicle.expectedSellingPrice,
        vehicle.firstOwner,
        vehicle.hydraulics,
        vehicle.listDamages,
        vehicle.maintenance,
        vehicle.makeModel,
        vehicle.mileage,
        vehicle.oemInspection,
        vehicle.registrationNumber,
        vehicle.roadWorthy,
        vehicle.settleBeforeSelling,
        vehicle.settlementAmount,
        vehicle.spareTyre,
        vehicle.suspension,
        vehicle.transmission,
        vehicle.tyreType,
        vehicle.userId,
        vehicle.vinNumber,
        vehicle.warranty,
        vehicle.warrantyType,
        vehicle.weightClass,
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
        vehicle.settlementLetterFile,
        vehicle.treadLeft,
        vehicle.tyrePhoto1,
        vehicle.tyrePhoto2,
      ];

      for (var field in nullableFieldsToCheck) {
        if (field != null) {
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

  void _applyFilters(
      String? makeModel, String? year, String? transmission, String? mileage) {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      _isFiltering = true; // Start filtering
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        displayedVehicles = vehicleProvider.vehicles
            .where((vehicle) {
              bool matchesMakeModel = makeModel == null ||
                  makeModel == 'All' ||
                  vehicle.makeModel
                      .toLowerCase()
                      .contains(makeModel.toLowerCase());

              bool matchesYear =
                  year == null || year == 'All' || vehicle.year == year;

              bool matchesTransmission = transmission == null ||
                  transmission == 'All' ||
                  vehicle.transmission.toLowerCase() ==
                      transmission.toLowerCase();

              bool matchesMileage = true;
              if (mileage != null && mileage != 'All') {
                int vehicleMileage =
                    int.tryParse(vehicle.mileage.replaceAll(',', '')) ?? 0;
                if (mileage == '0 - 50,000') {
                  matchesMileage =
                      vehicleMileage >= 0 && vehicleMileage <= 50000;
                } else if (mileage == '50,001 - 100,000') {
                  matchesMileage =
                      vehicleMileage >= 50001 && vehicleMileage <= 100000;
                } else if (mileage == '100,001 - 150,000') {
                  matchesMileage =
                      vehicleMileage >= 100001 && vehicleMileage <= 150000;
                } else if (mileage == '150,001 - 200,000') {
                  matchesMileage =
                      vehicleMileage >= 150001 && vehicleMileage <= 200000;
                } else if (mileage == '200,001+') {
                  matchesMileage = vehicleMileage >= 200001;
                }
              }

              bool isLikedOrDisliked =
                  userProvider.getLikedVehicles.contains(vehicle.id) ||
                      userProvider.getDislikedVehicles.contains(vehicle.id);

              bool isNotDraft = vehicle.vehicleStatus != 'Draft';

              return matchesMakeModel &&
                  matchesYear &&
                  matchesTransmission &&
                  matchesMileage &&
                  !isLikedOrDisliked &&
                  isNotDraft;
            })
            .where((vehicle) =>
                widget.vehicleType == null ||
                vehicle.vehicleType == widget.vehicleType)
            .toList();

        loadedVehicleIndex = displayedVehicles.length;
        _isFiltering = false; // End filtering

        print('Vehicles after applying filters: ${displayedVehicles.length}');
        print(
            'Displayed Vehicle IDs: ${displayedVehicles.map((v) => v.id).toList()}');
      });
    });
  }

  void _clearFilters() {
    setState(() {
      _isFiltering = true; // Start filtering
      selectedMakeModel = null;
      selectedYear = null;
      selectedTransmission = null;
      selectedMileage = null;
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

    // Get all unique make models from the fetched vehicles
    Set<String> allMakeModelsSet = vehicleProvider.vehicles
        .map((vehicle) => vehicle.makeModel)
        .map(
            (makeModel) => makeModel.split(" ")[0]) // Extracting the brand name
        .toSet(); // Ensure uniqueness
    List<String> allMakeModels = ['All', ...allMakeModelsSet.toList()];

    // Get all unique years from the fetched vehicles
    Set<String> allYearsSet = vehicleProvider.vehicles
        .map((vehicle) => vehicle.year)
        .where((year) => year.isNotEmpty)
        .toSet();
    List<String> allYears = ['All', ...allYearsSet.toList()];

    // Get all unique transmissions from the fetched vehicles
    Set<String> allTransmissionsSet = vehicleProvider.vehicles
        .map((vehicle) => vehicle.transmission)
        .where((transmission) => transmission.isNotEmpty)
        .toSet();
    List<String> allTransmissions = ['All', ...allTransmissionsSet.toList()];

    // Define mileage ranges
    List<String> allMileages = [
      'All',
      '0 - 50,000',
      '50,001 - 100,000',
      '100,001 - 150,000',
      '150,001 - 200,000',
      '200,001+'
    ];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Vehicles'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Make Model'),
                  value: selectedMakeModel,
                  items: allMakeModels.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedMakeModel = newValue;
                    });
                  },
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Year'),
                  value: selectedYear,
                  items: allYears.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedYear = newValue;
                    });
                  },
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Transmission'),
                  value: selectedTransmission,
                  items: allTransmissions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedTransmission = newValue;
                    });
                  },
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Mileage'),
                  value: selectedMileage,
                  items: allMileages.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedMileage = newValue;
                    });
                  },
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
                _applyFilters(selectedMakeModel, selectedYear,
                    selectedTransmission, selectedMileage);
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  void _clearLikedAndDislikedVehicles() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      await userProvider.clearDislikedVehicles();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disliked vehicles have been cleared.'),
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
      body: Stack(
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
                          onSwipeEnd: (int previousIndex, int? targetIndex,
                              direction) async {
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
                                  displayedVehicles.removeAt(previousIndex);
                                });
                                _loadNextVehicle();

                                final userProvider = Provider.of<UserProvider>(
                                    context,
                                    listen: false);
                                if (direction == AxisDirection.right) {
                                  await userProvider.likeVehicle(vehicle.id);
                                } else if (direction == AxisDirection.left) {
                                  await userProvider.dislikeVehicle(vehicle.id);
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Text(
                              "For TESTING PURPOSES ONLY the below button can be used to loop through all the trucks on the the database",
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
                              'Clear Disliked Vehicles',
                              style: _customFont(
                                  14, FontWeight.bold, Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
          Positioned(
            top: 25,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.end, // Adjusted to remove the logo
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.tune,
                        color: Colors.white,
                      ),
                      onPressed: _showFilterDialog,
                    ),
                    if (selectedMakeModel != null ||
                        selectedYear != null ||
                        selectedTransmission != null ||
                        selectedMileage != null)
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text(
                          "Clear Filters",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            // Implement bell notification action
                          },
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                    bottom: size.height *
                        0.23, // Set to 0 to allow the image to fill the entire height
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
                                            : vehicle.makeModel,
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
                                  vehicle.transmission.isNotEmpty
                                      ? vehicle.transmission
                                      : "N/A"),
                              const SizedBox(width: 8),
                              _buildInfoContainer(
                                  'TYPE',
                                  vehicle.vehicleType.isNotEmpty
                                      ? vehicle.vehicleType
                                      : "N/A"),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildIconButton(
                                  Icons.close,
                                  const Color(0xFF2F7FFF),
                                  controller,
                                  'left',
                                  vehicle),
                              _buildCenterButton(controller),
                              _buildIconButton(
                                  Icons.favorite,
                                  const Color(0xFFFF4E00),
                                  controller,
                                  'right',
                                  vehicle),
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
                        0.055, // Dynamically adjusted based on screen size
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

  Widget _buildIconButton(IconData icon, Color color,
      AppinioSwiperController controller, String direction, Vehicle vehicle) {
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
              Icon(Icons.undo, color: Colors.white, size: size.height * 0.025),
            ],
          ),
        ),
      ),
    );
  }
}
