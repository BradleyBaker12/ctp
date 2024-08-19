import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:google_fonts/google_fonts.dart';

class TruckPage extends StatefulWidget {
  const TruckPage({super.key});

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

  @override
  void initState() {
    super.initState();
    controller = AppinioSwiperController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialVehicles();
    });
  }

  void _loadInitialVehicles() {
    try {
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      setState(() {
        displayedVehicles = vehicleProvider.vehicles
            .where((vehicle) =>
                !userProvider.getLikedVehicles.contains(vehicle.id) &&
                !userProvider.getDislikedVehicles.contains(vehicle.id))
            .take(5)
            .toList();
        loadedVehicleIndex = displayedVehicles.length;
        print('Initial vehicles loaded: ${displayedVehicles.length}');
        for (var vehicle in displayedVehicles) {
          print(
              'Displayed Vehicle ID: ${vehicle.id}, MakeModel: ${vehicle.makeModel}');
        }
      });
    } catch (e) {
      print('Error loading initial vehicles: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
      print(
          'Loading next vehicle. Current loaded index: $loadedVehicleIndex, Total vehicles: ${vehicleProvider.vehicles.length}');
      while (loadedVehicleIndex < vehicleProvider.vehicles.length) {
        final nextVehicle = vehicleProvider.vehicles[loadedVehicleIndex];
        if (!userProvider.getLikedVehicles.contains(nextVehicle.id) &&
            !userProvider.getDislikedVehicles.contains(nextVehicle.id)) {
          setState(() {
            displayedVehicles.add(nextVehicle);
            loadedVehicleIndex++;
            print('Next vehicle loaded: ${nextVehicle.id}');
          });
          return;
        }
        loadedVehicleIndex++;
      }
      setState(() {
        _hasReachedEnd = true;
        print('No more vehicles to load.');
      });
    } catch (e) {
      print('Error loading next vehicle: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
      // List of fields to check
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

      // Increment filledFields for each non-empty string field
      for (var field in fieldsToCheck) {
        if (field.isNotEmpty) {
          filledFields++;
          print('Field filled: $field');
        } else {
          print('Field empty: $field');
        }
      }

      // Check nullable fields
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

      // Increment filledFields for each non-null field
      for (var field in nullableFieldsToCheck) {
        if (field != null) {
          filledFields++;
          print('Nullable field filled: $field');
        } else {
          print('Nullable field empty');
        }
      }

      // Checking each photo in the photos array
      for (var photo in vehicle.photos) {
        if (photo != null && photo.isNotEmpty) {
          filledFields++;
          print('Photo filled: $photo');
        } else {
          print('Photo empty');
        }
      }

      // Calculate honesty percentage
      double honestyPercentage = (filledFields / totalFields) * 100;

      // Debugging output
      print('Total fields: $totalFields');
      print('Filled fields: $filledFields');
      print('Honesty percentage: $honestyPercentage%');

      return honestyPercentage;
    } catch (e) {
      print('Error calculating honesty percentage: $e');
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: const BlurryAppBar(),
      body: displayedVehicles.isNotEmpty
          ? !_hasReachedEnd
              ? AppinioSwiper(
                  key: ValueKey(displayedVehicles.length), // Ensure unique key
                  controller: controller,
                  cardCount: displayedVehicles.length,
                  cardBuilder: (BuildContext context, int index) {
                    print('Building card at index: $index');
                    if (index < displayedVehicles.length) {
                      return _buildTruckCard(
                          context, controller, displayedVehicles[index], size);
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                  onSwipeEnd:
                      (int previousIndex, int? targetIndex, direction) async {
                    try {
                      print(
                          'Swiped card at index: $previousIndex in direction: $direction');
                      if (direction == AxisDirection.left ||
                          direction == AxisDirection.right) {
                        final vehicle = displayedVehicles[previousIndex];
                        setState(() {
                          print('Adding vehicle to swiped list');
                          swipedVehicles.add(vehicle);
                          swipedDirections.add(direction == AxisDirection.right
                              ? 'right'
                              : 'left');
                          print('Removing vehicle from displayed list');
                          displayedVehicles.removeAt(previousIndex);
                        });
                        print(
                            'Displayed vehicles after removal: ${displayedVehicles.map((v) => v.id).toList()}');
                        print(
                            'Swiped vehicles: ${swipedVehicles.map((v) => v.id).toList()}');
                        _loadNextVehicle();

                        final userProvider =
                            Provider.of<UserProvider>(context, listen: false);
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
                        print('All cards swiped');
                      }
                    } catch (e) {
                      print('Error handling swipe: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
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
                    print('All cards swiped');
                  },
                )
              : Center(
                  child: Text("You've seen all the vehicles!",
                      style: _customFont(16, FontWeight.normal, Colors.black)),
                )
          : Center(
              child: Text("No vehicles available",
                  style: _customFont(16, FontWeight.normal, Colors.black)),
            ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildTruckCard(BuildContext context,
      AppinioSwiperController controller, Vehicle vehicle, Size size) {
    double honestyPercentage = _calculateHonestyPercentage(vehicle);
    int filledFields = (honestyPercentage / 100 * (35 + 18)).round();

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
          print('Error navigating to vehicle details: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Failed to load vehicle details. Please try again.'),
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        height: size.height -
            AppBar().preferredSize.height -
            80, // Adjust for app bar and bottom navigation
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: vehicle.mainImageUrl != null &&
                        vehicle.mainImageUrl!.isNotEmpty
                    ? Image.network(
                        vehicle.mainImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'lib/assets/default_vehicle_image.png',
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Stack(
                        children: [
                          Image.asset(
                            'lib/assets/default_vehicle_image.png', // Placeholder image
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          Container(
                            color: Colors.black
                                .withOpacity(0.2), // Overlay with 0.2 opacity
                          ),
                        ],
                      ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Adjust for shrink-wrapping
                children: [
                  _buildHonestyBar(honestyPercentage),
                  const SizedBox(height: 8),
                  Text(
                    "${honestyPercentage.toStringAsFixed(0)}/100",
                    style: _customFont(
                        size.height * 0.015, FontWeight.bold, Colors.white),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 90,
              left: 10,
              right: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Adjust for shrink-wrapping
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        vehicle.makeModel,
                        style: _customFont(
                            size.height * 0.025, FontWeight.bold, Colors.white),
                      ),
                      const SizedBox(width: 5),
                      Image.asset(
                        'lib/assets/verified_Icon.png',
                        width: size.width * 0.05,
                        height: size.height * 0.05,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildBlurryContainer(
                          'YEAR',
                          vehicle.year.isNotEmpty ? vehicle.year : "Unknown",
                        ),
                      ),
                      const SizedBox(
                          width: 8), // Add some spacing between columns
                      Expanded(
                        child: _buildBlurryContainer(
                          'MILEAGE',
                          vehicle.mileage.isNotEmpty
                              ? vehicle.mileage
                              : "Unknown",
                        ),
                      ),
                      const SizedBox(
                          width: 8), // Add some spacing between columns
                      Expanded(
                        child: _buildBlurryContainer(
                          'GEARBOX',
                          vehicle.transmission.isNotEmpty
                              ? vehicle.transmission
                              : "Unknown",
                        ),
                      ),
                      const SizedBox(
                          width: 8), // Add some spacing between columns
                      Expanded(
                        child: _buildBlurryContainer(
                          'TYPE',
                          vehicle.vehicleType.isNotEmpty
                              ? vehicle.vehicleType
                              : "Unknown",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIconButton(Icons.close, const Color(0xFF2F7FFF),
                      controller, 'left', vehicle),
                  _buildCenterButton(controller),
                  _buildIconButton(Icons.favorite, const Color(0xFFFF4E00),
                      controller, 'right', vehicle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHonestyBar(double percentage) {
    final size = MediaQuery.of(context).size;
    return Container(
      width: size.height * 0.025,
      height: size.height * 0.62, // Adjust the height as needed
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height:
                    (560 * percentage) / 100, // Adjust the height calculation
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4E00),
                  borderRadius: BorderRadius.circular(5),
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
            value.isNotEmpty ? value : "Unknown",
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
            print('${icon == Icons.close ? "DISLIKE" : "LIKE"} button pressed');
            if (direction == 'left') {
              final userProvider =
                  Provider.of<UserProvider>(context, listen: false);
              await userProvider.dislikeVehicle(vehicle.id);

              print(
                  'Disliked vehicle: ${vehicle.id}, MakeModel: ${vehicle.makeModel}'); // Debugging statement

              controller.swipeLeft();
              print('Swiping left');
            } else if (direction == 'right') {
              final userProvider =
                  Provider.of<UserProvider>(context, listen: false);
              await userProvider.likeVehicle(vehicle.id);

              print(
                  'Liked vehicle: ${vehicle.id}, MakeModel: ${vehicle.makeModel}'); // Debugging statement

              controller.swipeRight();
              print('Swiping right');
            }
          } catch (e) {
            print('Error swiping vehicle: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to swipe vehicle. Please try again.'),
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: size.height * 0.025),
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
            print("Undo button pressed");
            print(
                'Swiped vehicles before undo: ${swipedVehicles.map((v) => v.id).toList()}');
            print(
                'Displayed vehicles before undo: ${displayedVehicles.map((v) => v.id).toList()}');

            if (swipedVehicles.isNotEmpty) {
              final lastVehicle = swipedVehicles.removeLast();
              final lastDirection = swipedDirections.removeLast();
              final userProvider =
                  Provider.of<UserProvider>(context, listen: false);

              // Remove the vehicle from liked or disliked list in the database
              if (lastDirection == 'right') {
                await userProvider.removeLikedVehicle(lastVehicle.id);
              } else if (lastDirection == 'left') {
                await userProvider.removeDislikedVehicle(lastVehicle.id);
              }

              controller.unswipe();

              print(
                  'Swiped vehicles after undo: ${swipedVehicles.map((v) => v.id).toList()}');
              print(
                  'Displayed vehicles after undo: ${displayedVehicles.map((v) => v.id).toList()}');
            }
          } catch (e) {
            print('Error undoing swipe: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to undo swipe. Please try again.'),
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black, width: 2),
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
