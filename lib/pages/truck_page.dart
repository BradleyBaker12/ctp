import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/honesty_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:google_fonts/google_fonts.dart';

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

      setState(() {
        displayedVehicles = vehicleProvider.vehicles.take(5).toList();
        loadedVehicleIndex = displayedVehicles.length;
        _isLoading = false; // Loading complete
      });
    } catch (e) {
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
        if (!userProvider.getLikedVehicles.contains(nextVehicle.id) &&
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

  void _applyFilters(String? makeModel, String? year, String? transmission) {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      displayedVehicles = vehicleProvider.vehicles
          .where((vehicle) {
            bool matchesMakeModel = makeModel == null ||
                makeModel == 'All' ||
                vehicleProvider.doesMakeModelContainBrand(
                    vehicle.makeModel, makeModel);
            bool matchesYear =
                year == null || year == 'All' || vehicle.year == year;
            bool matchesTransmission = transmission == null ||
                transmission == 'All' ||
                vehicle.transmission == transmission;

            bool isLikedOrDisliked =
                userProvider.getLikedVehicles.contains(vehicle.id) ||
                    userProvider.getDislikedVehicles.contains(vehicle.id);

            return matchesMakeModel &&
                matchesYear &&
                matchesTransmission &&
                !isLikedOrDisliked;
          })
          .where((vehicle) =>
              widget.vehicleType == null ||
              vehicle.vehicleType == widget.vehicleType)
          .take(5)
          .toList();
      loadedVehicleIndex = displayedVehicles.length;
    });
  }

  void _clearFilters() {
    setState(() {
      selectedMakeModel = null;
      selectedYear = null;
      selectedTransmission = null;
    });
    _loadInitialVehicles();
  }

  Future<void> _showFilterDialog() async {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);

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
                  items: vehicleProvider.getAllMakeModels().map((String value) {
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
                  items: vehicleProvider.getAllYears().map((String value) {
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
                  items:
                      vehicleProvider.getAllTransmissions().map((String value) {
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
                _applyFilters(
                    selectedMakeModel, selectedYear, selectedTransmission);
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
      appBar: const BlurryAppBar(),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF4E00),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'lib/assets/CTPLogo.png',
                  width: size.width * 0.15,
                ),
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
                        selectedTransmission != null)
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
                                padding: const EdgeInsets.only(left: 2.0),
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
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 2.0, bottom: 10),
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
                                  const SizedBox(width: 60),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Image.asset(
                                      'lib/assets/verified_Icon.png',
                                      width: size.width * 0.05,
                                      height: size.height * 0.05,
                                    ),
                                  ),
                                  const SizedBox(height: 30)
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
                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                  ),

                  // Honesty Bar Widget
                  Positioned(
                    top: 52,
                    right: 12,
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

  Widget _buildHonestyBar(double percentage) {
    final size = MediaQuery.of(context).size;
    return Container(
      width: size.height * 0.018,
      height: size.height * 0.49,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: ((size.height * 0.51) * percentage) / 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F7FFF),
                  borderRadius: BorderRadius.circular(0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlurryContainer(String title, String value) {
    final size = MediaQuery.of(context).size;
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style:
                _customFont(size.height * 0.012, FontWeight.w400, Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value.isNotEmpty ? value : "N/A",
            style:
                _customFont(size.height * 0.016, FontWeight.bold, Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
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
