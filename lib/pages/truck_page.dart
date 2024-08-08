import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:ctp/components/blurry_app_bar.dart';

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
  }

  void _loadNextVehicle() {
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
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  TextStyle _customFont(double fontSize, FontWeight fontWeight, Color color) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFamily: 'Montserrat',
    );
  }

  double _calculateHonestyPercentage(Vehicle vehicle) {
    int totalFields = 29 + 18; // 29 fields and 18 photos
    int filledFields = 0;

    // Checking each field and incrementing filledFields if it is not null or empty
    if (vehicle.accidentFree.isNotEmpty) filledFields++;
    if (vehicle.application.isNotEmpty) filledFields++;
    if (vehicle.bookValue.isNotEmpty) filledFields++;
    if (vehicle.damageDescription.isNotEmpty) filledFields++;
    if (vehicle.dashboardPhoto != null) filledFields++;
    if (vehicle.engineNumber.isNotEmpty) filledFields++;
    if (vehicle.expectedSellingPrice.isNotEmpty) filledFields++;
    if (vehicle.faultCodesPhoto != null) filledFields++;
    if (vehicle.firstOwner.isNotEmpty) filledFields++;
    if (vehicle.hydraulics.isNotEmpty) filledFields++;
    if (vehicle.licenceDiskUrl != null) filledFields++;
    if (vehicle.listDamages.isNotEmpty) filledFields++;
    if (vehicle.maintenance.isNotEmpty) filledFields++;
    if (vehicle.makeModel.isNotEmpty) filledFields++;
    if (vehicle.mileage.isNotEmpty) filledFields++;
    if (vehicle.oemInspection.isNotEmpty) filledFields++;
    if (vehicle.rc1NatisFile != null) filledFields++;
    if (vehicle.registrationNumber.isNotEmpty) filledFields++;
    if (vehicle.roadWorthy.isNotEmpty) filledFields++;
    if (vehicle.settleBeforeSelling.isNotEmpty) filledFields++;
    if (vehicle.settlementAmount.isNotEmpty) filledFields++;
    if (vehicle.settlementLetterFile != null) filledFields++;
    if (vehicle.spareTyre.isNotEmpty) filledFields++;
    if (vehicle.suspension.isNotEmpty) filledFields++;
    if (vehicle.transmission.isNotEmpty) filledFields++;
    if (vehicle.treadLeft.isNotEmpty) filledFields++;
    if (vehicle.tyrePhoto1 != null) filledFields++;
    if (vehicle.tyrePhoto2 != null) filledFields++;
    if (vehicle.tyreType.isNotEmpty) filledFields++;
    if (vehicle.userId.isNotEmpty) filledFields++;
    if (vehicle.vinNumber.isNotEmpty) filledFields++;
    if (vehicle.warranty.isNotEmpty) filledFields++;
    if (vehicle.warrantyType.isNotEmpty) filledFields++;
    if (vehicle.year.isNotEmpty) filledFields++;

    // Checking each photo in the photos array
    for (var photo in vehicle.photos) {
      if (photo != null) filledFields++;
    }

    return (filledFields / totalFields) * 100;
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
    int filledFields = (honestyPercentage / 100 * (29 + 18)).round();

    return GestureDetector(
      onDoubleTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VehicleDetailsPage(vehicle: vehicle),
          ),
        );
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
                child: vehicle.photos.isNotEmpty && vehicle.photos[0] != null
                    ? Image.network(
                        vehicle.photos[0]!,
                        fit: BoxFit.cover,
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
                children: [
                  _buildHonestyBar(honestyPercentage),
                  const SizedBox(height: 8),
                  Text(
                    "$filledFields/100",
                    style: _customFont(14, FontWeight.bold, Colors.white),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 90,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        vehicle.makeModel,
                        style: _customFont(20, FontWeight.bold, Colors.white),
                      ),
                      const SizedBox(width: 5),
                      Image.asset(
                        'lib/assets/verified_Icon.png',
                        width: 20,
                        height: 20,
                      )
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBlurryContainer('YEAR',
                          vehicle.year.isNotEmpty ? vehicle.year : "Unknown"),
                      const SizedBox(width: 1),
                      _buildBlurryContainer(
                          'MILEAGE',
                          vehicle.mileage.isNotEmpty
                              ? vehicle.mileage
                              : "Unknown"),
                      const SizedBox(width: 1),
                      _buildBlurryContainer(
                          'TRANSMISSION',
                          vehicle.transmission.isNotEmpty
                              ? vehicle.transmission
                              : "Unknown"),
                      const SizedBox(width: 1),
                      _buildBlurryContainer('CONFIG', 'Unknown'),
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
    return Container(
      width: 25,
      height: 560, // Adjust the height as needed
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
    return Flexible(
      child: Container(
        height: 90,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
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
              style: _customFont(14, FontWeight.w300, Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value.isNotEmpty ? value : "Unknown",
              style: _customFont(16, FontWeight.bold, Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color,
      AppinioSwiperController controller, String direction, Vehicle vehicle) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
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
              Icon(icon, color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton(AppinioSwiperController controller) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
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
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.undo, color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
