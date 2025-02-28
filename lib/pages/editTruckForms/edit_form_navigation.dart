import 'package:auto_size_text/auto_size_text.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/pages/editTruckForms/basic_information_edit.dart';
import 'package:ctp/pages/editTruckForms/external_cab_edit_page.dart';
import 'package:ctp/pages/editTruckForms/maintenance_edit_section.dart';
import 'package:ctp/pages/editTruckForms/admin_edit_section.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ctp/components/web_navigation_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ctp/components/truck_info_web_nav.dart';
import 'package:provider/provider.dart'; // import for TruckInfoWebNavBar

class EditFormNavigation extends StatefulWidget {
  final Vehicle vehicle;

  const EditFormNavigation({
    super.key,
    required this.vehicle,
  });

  @override
  State<EditFormNavigation> createState() => _EditFormNavigationState();
}

class _EditFormNavigationState extends State<EditFormNavigation> {
  Vehicle? vehicle;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    // Initialize with the passed vehicle data
    vehicle = widget.vehicle;
    // Then fetch any updates if needed
    _fetchVehicleData();
  }

  Future<void> _fetchVehicleData() async {
    try {
      print('Fetching vehicle data for ID: ${widget.vehicle.id}');
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicle.id)
          .get();

      if (!doc.exists) {
        throw Exception('Vehicle document not found');
      }

      final docData = doc.data();
      if (docData == null) {
        throw Exception(
            'No data found for document with ID: ${widget.vehicle.id}');
      }

      Map<String, dynamic> data = docData as Map<String, dynamic>;

      // Debug raw data
      print('Raw Firestore data: $data');
      print('Application field type: ${data['application']?.runtimeType}');
      print('Brands field type: ${data['brands']?.runtimeType}');
      print('Photos field type: ${data['photos']?.runtimeType}');

      // Handle application field
      if (data['application'] is String) {
        print(
            'Converting application from String to List: ${data['application']}');
        data['application'] = [data['application']];
      } else if (data['application'] == null) {
        print('Application field is null, defaulting to an empty list.');
        data['application'] = [];
      }

      // Handle brands field
      if (data['brands'] is String) {
        print('Converting brands from String to List: ${data['brands']}');
        data['brands'] = [data['brands']];
      } else if (data['brands'] == null) {
        print('Brands field is null, defaulting to an empty list.');
        data['brands'] = [];
      }

      print('Processed data before Vehicle creation:');
      print('Application: ${data['application']}');
      print('Brands: ${data['brands']}');

      // Create or update the `vehicle` property from the Firestore document
      vehicle = Vehicle.fromDocument(doc);
      print('Vehicle object created successfully');

      // Update the UI
      setState(() {});
    } catch (e, s) {
      print('Error fetching vehicle data: $e');
      print('Stack trace: $s');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Error fetching vehicle data: $e'),
      //     backgroundColor: Colors.red,
      //   ),
      // );
    }
  }

  int _calculateBasicInfoProgress() {
    int completedSteps = 0;
    const totalSteps = 15; // Total number of possible fields

    // Main image
    if (vehicle?.mainImageUrl != null) completedSteps++;
    // Vehicle status
    // if (vehicle?.vehicleStatus != null) completedSteps++;
    // Reference number
    // if (vehicle?.referenceNumber != null) completedSteps++;
    // RC1/NATIS file
    // if (vehicle?.rc1NatisFile != null) completedSteps++;
    // Vehicle type (truck/trailer)
    if (vehicle?.vehicleType != null) completedSteps++;
    // Year
    if (vehicle?.year != null) completedSteps++;
    // Make/Model
    if (vehicle?.makeModel != null) completedSteps++;
    // Variant
    if (vehicle?.variant != null) completedSteps++;
    // Country
    if (vehicle?.country != null) completedSteps++;
    // Mileage
    if (vehicle?.mileage != null) completedSteps++;
    // Configuration
    if (vehicle?.config != null) completedSteps++;
    // Application
    if (vehicle?.application.isNotEmpty == true) completedSteps++;
    // VIN Number
    // if (vehicle?.vinNumber != null) completedSteps++;
    // Engine Number
    if (vehicle?.engineNumber != null) completedSteps++;
    // Registration Number
    if (vehicle?.registrationNumber != null) completedSteps++;

    return completedSteps;
  }

  int _calculateMaintenanceProgress() {
    int completedSteps = 0;
    const totalSteps = 4; // Total possible fields

    // Check maintenance document
    if (vehicle?.maintenance.maintenanceDocUrl != null) completedSteps++;
    // Check warranty document
    if (vehicle?.maintenance.warrantyDocUrl != null) completedSteps++;
    // Check OEM inspection type
    if (vehicle?.maintenance.oemInspectionType != null) completedSteps++;
    // Check OEM reason if inspection type is 'no'
    if (vehicle?.maintenance.oemInspectionType == 'no' &&
        vehicle?.maintenance.oemReason?.isNotEmpty == true) {
      completedSteps++;
    }

    return completedSteps;
  }

  int _calculateAdminProgress() {
    int completedSteps = 0;
    const totalSteps = 4; // Total possible fields

    // NATIS/RC1 document
    if (vehicle?.adminData.natisRc1Url != null) completedSteps++;
    // License disk
    if (vehicle?.adminData.licenseDiskUrl != null) completedSteps++;
    // Settlement letter (if required)
    if (vehicle?.requireToSettleType == 'yes') {
      if (vehicle?.adminData.settlementLetterUrl != null) completedSteps++;
      if (vehicle?.adminData.settlementAmount.isNotEmpty == true) {
        completedSteps++;
      }
    }

    return completedSteps;
  }

  int _calculateExternalCabProgress() {
    int completedSteps = 0;
    int totalSteps = 3; // Base fields: condition, damages, additional features

    final externalCab = vehicle?.truckConditions.externalCab;

    // Check main condition
    if (externalCab?.condition.isNotEmpty == true) completedSteps++;

    // Check images
    if (externalCab?.images.isNotEmpty == true) completedSteps++;

    // Check damages section
    if (externalCab?.damagesCondition.isNotEmpty == true) {
      completedSteps++;
    }

    // Check additional features section
    if (externalCab?.additionalFeaturesCondition.isNotEmpty == true) {
      completedSteps++;
    }

    return completedSteps;
  }

  int _calculateInternalCabProgress() {
    int completedSteps = 0;
    int totalSteps =
        5; // Base fields: condition, damages, additional features, fault codes, view images

    final internalCab = vehicle?.truckConditions.internalCab;

    // Check main condition
    if (internalCab?.condition.isNotEmpty == true) completedSteps++;

    // Check view images
    if (internalCab?.viewImages.isNotEmpty == true) completedSteps++;

    // Check damages section
    if (internalCab?.damagesCondition.isNotEmpty == true) completedSteps++;

    // Check additional features section
    if (internalCab?.additionalFeaturesCondition.isNotEmpty == true) {
      completedSteps++;
    }

    // Check fault codes section
    if (internalCab?.faultCodesCondition.isNotEmpty == true) completedSteps++;

    return completedSteps;
  }

  int _calculateDriveTrainProgress() {
    int completedSteps = 0;
    int totalSteps = 10; // All fields from the DriveTrain model

    final driveTrain = vehicle?.truckConditions.driveTrain;

    // Check main condition
    if (driveTrain?.condition.isNotEmpty == true) completedSteps++;

    // Check engine conditions
    if (driveTrain?.oilLeakConditionEngine.isNotEmpty == true) completedSteps++;
    if (driveTrain?.waterLeakConditionEngine.isNotEmpty == true) {
      completedSteps++;
    }
    if (driveTrain?.blowbyCondition.isNotEmpty == true) completedSteps++;

    // Check gearbox and retarder conditions
    if (driveTrain?.oilLeakConditionGearbox.isNotEmpty == true) {
      completedSteps++;
    }
    if (driveTrain?.retarderCondition.isNotEmpty == true) completedSteps++;

    // Check images
    if (driveTrain?.images.isNotEmpty == true) completedSteps++;

    // Check damages
    if (driveTrain?.damages.isNotEmpty == true) completedSteps++;

    // Check additional features
    if (driveTrain?.additionalFeatures.isNotEmpty == true) completedSteps++;

    // Check fault codes
    if (driveTrain?.faultCodes.isNotEmpty == true) completedSteps++;

    return completedSteps;
  }

  int _calculateChassisProgress() {
    int completedSteps = 0;
    int totalSteps =
        4; // Base fields: condition, images, damages, additional features

    final chassis = vehicle?.truckConditions.chassis;

    // Check main condition
    if (chassis?.condition.isNotEmpty == true) completedSteps++;

    // Check images
    if (chassis?.images.isNotEmpty == true) completedSteps++;

    // Check damages section
    if (chassis?.damagesCondition.isNotEmpty == true) completedSteps++;

    // Check additional features section
    if (chassis?.additionalFeaturesCondition.isNotEmpty == true) {
      completedSteps++;
    }

    return completedSteps;
  }

  int _calculateTyresProgress() {
    int completedSteps = 0;

    final tyresMap = vehicle?.truckConditions.tyres;
    if (tyresMap != null) {
      tyresMap.forEach((key, tyres) {
        // Loop through tyre positions
        for (int pos = 1; pos <= 6; pos++) {
          String posKey = 'Tyre_Pos_$pos';
          final tyreData =
              tyres.positions[posKey]; // Access `positions` from `Tyres`

          if (tyreData?.chassisCondition != null &&
              tyreData!.chassisCondition.isNotEmpty) {
            completedSteps++;
          }
          if (tyreData?.virginOrRecap != null &&
              tyreData!.virginOrRecap.isNotEmpty) {
            completedSteps++;
          }
          if (tyreData?.rimType != null && tyreData!.rimType.isNotEmpty) {
            completedSteps++;
          }
        }
      });
    }

    return completedSteps;
  }

  int _calculateTruckConditionsProgress() {
    return _calculateExternalCabProgress() +
        _calculateInternalCabProgress() +
        _calculateDriveTrainProgress() +
        _calculateChassisProgress() +
        _calculateTyresProgress();
  }

  void _showNavigationDrawer(List<NavigationItem> items) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final currentRoute =
            ModalRoute.of(context)?.settings.name ?? '/editForm';
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black54),
            ),
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(-1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: ModalRoute.of(context)!.animation!,
                curve: Curves.easeOut,
              )),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: const [Colors.black, Color(0xFF2F7FFD)],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 20,
                          bottom: 20,
                          left: 16,
                          right: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.network(
                              'https://firebasestorage.googleapis.com/v0/b/ctp-central-database.appspot.com/o/CTPLOGOWeb.png?alt=media&token=d85ec0b5-f2ba-4772-aa08-e9ac6d4c2253',
                              height: 40,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 40,
                                  width: 40,
                                  color: Colors.grey[900],
                                  child: const Icon(Icons.local_shipping,
                                      color: Colors.white),
                                );
                              },
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white24),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            _buildDrawerItem('Basic Information', Icons.info,
                                () {
                              Navigator.pop(context);
                              _navigateToBasicInfo();
                            }),
                            _buildDrawerItem('Truck Conditions', Icons.build,
                                () {
                              Navigator.pop(context);
                              _navigateToTruckConditions();
                            }),
                            _buildDrawerItem('Maintenance', Icons.settings, () {
                              Navigator.pop(context);
                              _navigateToMaintenance();
                            }),
                            _buildDrawerItem(
                                'Admin', Icons.admin_panel_settings, () {
                              Navigator.pop(context);
                              _navigateToAdmin();
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawerItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }

  // Navigation helper methods
  void _navigateToBasicInfo() async {
    var updatedVehicle = await Navigator.of(context).push<Vehicle>(
      MaterialPageRoute(
        builder: (context) => BasicInformationEdit(vehicle: vehicle!),
      ),
    );
    if (updatedVehicle != null) {
      setState(() => vehicle = updatedVehicle);
    }
  }

  void _navigateToTruckConditions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExternalCabEditPage(
          vehicleId: vehicle!.id,
          isEditing: true,
          onProgressUpdate: () {
            setState(() {
              // Refresh the UI when progress is updated
            });
          },
        ),
      ),
    );
  }

  void _navigateToMaintenance() async {
    try {
      // Fetch the maintenance data from Firestore
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicle!.id)
          .get();

      if (!doc.exists) {
        throw Exception('Vehicle document not found');
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      Map<String, dynamic> maintenanceData =
          data['maintenanceData'] as Map<String, dynamic>? ?? {};

      // Navigate to maintenance section with existing data
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) => MaintenanceEditSection(
            vehicleId: vehicle!.id,
            isUploading: false,
            isEditing: true,
            isFromAdmin: true,
            onMaintenanceFileSelected: (file) {},
            onWarrantyFileSelected: (file) {},
            oemInspectionType: maintenanceData['oemInspectionType'] ?? 'yes',
            oemInspectionExplanation: maintenanceData['oemReason'] ?? '',
            onProgressUpdate: () {
              setState(() {});
            },
            maintenanceSelection:
                maintenanceData['maintenanceSelection'] ?? 'yes',
            warrantySelection: maintenanceData['warrantySelection'] ?? 'yes',
            maintenanceDocUrl: maintenanceData['maintenanceDocUrl'],
            warrantyDocUrl: maintenanceData['warrantyDocUrl'],
          ),
        ),
      );
    } catch (e) {
      print('Error loading maintenance data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading maintenance data: $e')),
      );
    }
  }

  void _navigateToAdmin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminEditSection(
          vehicle: vehicle!,
          isUploading: false,
          isEditing: true,
          onAdminDoc1Selected: (file, fileName) {},
          onAdminDoc2Selected: (file, fileName) {},
          onAdminDoc3Selected: (file, fileName) {},
          requireToSettleType: vehicle!.requireToSettleType ?? 'no',
          settlementAmount: vehicle!.adminData.settlementAmount,
          natisRc1Url: vehicle!.adminData.natisRc1Url,
          licenseDiskUrl: vehicle!.adminData.licenseDiskUrl,
          settlementLetterUrl: vehicle!.adminData.settlementLetterUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (vehicle == null) {
      return Center(child: CircularProgressIndicator());
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isCompactNavigation = screenWidth < 800;
    final bool showHamburger = screenWidth <= 1024; // Added this line
    final userProvider = Provider.of<UserProvider>(context);
    final String userRole = userProvider.getUserRole;

    return Scaffold(
      key: _scaffoldKey,
      drawer: null,
      appBar: kIsWeb
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: (userRole == 'admin' || userRole == 'salesRep')
                  ? TruckInfoWebNavBar(
                      scaffoldKey: _scaffoldKey,
                      selectedTab: "Edit Form",
                      vehicleId: vehicle!.id,
                      onHomePressed: () =>
                          Navigator.pushNamed(context, '/home'),
                      onBasicInfoPressed: () =>
                          Navigator.pushNamed(context, '/basic_information'),
                      onTruckConditionsPressed: () =>
                          Navigator.pushNamed(context, '/truck_conditions'),
                      onMaintenanceWarrantyPressed: () =>
                          Navigator.pushNamed(context, '/maintenance_warranty'),
                      onExternalCabPressed: () =>
                          Navigator.pushNamed(context, '/external_cab'),
                      onInternalCabPressed: () =>
                          Navigator.pushNamed(context, '/internal_cab'),
                      onChassisPressed: () =>
                          Navigator.pushNamed(context, '/chassis'),
                      onDriveTrainPressed: () =>
                          Navigator.pushNamed(context, '/drive_train'),
                      onTyresPressed: () =>
                          Navigator.pushNamed(context, '/tyres'),
                    )
                  : WebNavigationBar(
                      scaffoldKey: _scaffoldKey,
                      isCompactNavigation: isCompactNavigation,
                      currentRoute: '/editForm',
                      onMenuPressed: () => _showNavigationDrawer([]),
                    ),
            )
          : AppBar(
              backgroundColor: Colors.blueAccent,
              leading: showHamburger
                  ? Builder(
                      builder: (BuildContext context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => _showNavigationDrawer([]),
                      ),
                    )
                  : Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                        icon: const Text(
                          'BACK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    vehicle!.referenceNumber ?? 'REF',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      vehicle!.makeModel.toString().toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: vehicle!.mainImageUrl != null
                        ? NetworkImage(vehicle!.mainImageUrl!) as ImageProvider
                        : const AssetImage('assets/truck_image.png'),
                  ),
                ),
              ],
            ),
      body: Column(
        children: [
          if (!kIsWeb)
            WebNavigationBar(
              scaffoldKey: _scaffoldKey,
              isCompactNavigation: isCompactNavigation,
              currentRoute: '/editForm',
              onMenuPressed: () => _showNavigationDrawer([]),
            ),
          Expanded(
            child: GradientBackground(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'COMPLETE ALL STEPS AS\nPOSSIBLE TO RECEIVE\nBETTER OFFERS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSection(context, 'BASIC INFORMATION',
                        '${_calculateBasicInfoProgress()} OF 11'),
                    _buildSection(context, 'TRUCK CONDITION',
                        '${_calculateTruckConditionsProgress()} OF 35'),
                    _buildSection(
                      context,
                      'MAINTENANCE AND WARRANTY',
                      '${_calculateMaintenanceProgress()} OF 4',
                    ),
                    _buildSection(
                        context, 'ADMIN', '${_calculateAdminProgress()} OF 4'),
                    const SizedBox(height: 20),
                    // if (vehicle?.vehicleStatus == 'Draft')
                    //   Padding(
                    //     padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    //     child: CustomButton(
                    //       onPressed: () async {
                    //         await FirebaseFirestore.instance
                    //             .collection('vehicles')
                    //             .doc(vehicle!.id)
                    //             .update({'vehicleStatus': 'Live'});

                    //         // Fetch updated vehicle data
                    //         await _fetchVehicleData();
                    //         await MyNavigator.pushReplacement(
                    //             context, VehiclesListPage());
                    //       },
                    //       text: 'PUSH TO LIVE',
                    //       borderColor: Colors.green,
                    //     ),
                    //   )
                    // else if (vehicle?.vehicleStatus == 'Live')
                    //   Padding(
                    //     padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    //     child: CustomButton(
                    //       onPressed: () async {
                    //         await FirebaseFirestore.instance
                    //             .collection('vehicles')
                    //             .doc(vehicle!.id)
                    //             .update({'vehicleStatus': 'Draft'});

                    //         // Fetch updated vehicle data
                    //         await _fetchVehicleData();
                    //         await MyNavigator.pushReplacement(
                    //             context, VehiclesListPage());
                    //       },
                    //       text: 'MOVE TO DRAFT',
                    //       borderColor: Colors.blueAccent,
                    //     ),
                    //   ),
                    const SizedBox(height: 20),
                    _buildBottomButtons(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateAdminProgressString() {
    int completed = 0;
    int total = 3; // NATIS/RC1, License Disk, and Settlement if required

    // Check NATIS/RC1
    if (widget.vehicle.adminData.natisRc1Url.isNotEmpty ?? false) {
      completed++;
    }

    // Check License Disk
    if (widget.vehicle.adminData.licenseDiskUrl.isNotEmpty ?? false) {
      completed++;
    }

    // Check Settlement Letter if required
    if (widget.vehicle.requireToSettleType == 'yes') {
      total++; // Add settlement amount to total
      if (widget.vehicle.adminData.settlementLetterUrl.isNotEmpty ?? false) {
        completed++;
      }
      if (widget.vehicle.adminData.settlementAmount.isNotEmpty ?? false) {
        completed++;
      }
    }

    return "$completed/$total";
  }

  double _calculateAdminProgressPercentage() {
    int completed = 0;
    int total = 3;

    if (widget.vehicle.adminData.natisRc1Url.isNotEmpty ?? false) completed++;
    if (widget.vehicle.adminData.licenseDiskUrl.isNotEmpty ?? false) {
      completed++;
    }

    if (widget.vehicle.requireToSettleType == 'yes') {
      total++;
      if (widget.vehicle.adminData.settlementLetterUrl.isNotEmpty ?? false) {
        completed++;
      }
      if (widget.vehicle.adminData.settlementAmount.isNotEmpty ?? false) {
        completed++;
      }
    }

    return total == 0 ? 0.0 : completed / total;
  }

  Widget _buildSection(BuildContext context, String title, String progress) {
    final size = MediaQuery.of(context).size;
    // Expecting progress in the format "current/total"
    final parts = progress.split('/');
    final current = int.tryParse(parts[0]) ?? 0;
    final total = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;
    final progressRatio = total == 0 ? 0.0 : (current / total);

    final isLargeScreen = size.width > 600;
    final containerWidth = isLargeScreen ? 942.0 : size.width * 0.9;
    final containerPadding = isLargeScreen ? 37.31 : 20.0;
    const borderSideWidth = 0.93;
    const borderRadius = 20.0;
    const borderColor = Color(0xFF2F7FFF);
    final titleBoxHeight = isLargeScreen ? 76.48 : 45.0;
    final titleBoxPadding = isLargeScreen
        ? const EdgeInsets.symmetric(horizontal: 48.50, vertical: 18.65)
        : const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0);
    const titleBoxRadius = 6.0;
    final titleFontSize = isLargeScreen ? 20.0 : 16.0;
    final titleLetterSpace = isLargeScreen ? 1.87 : 1.0;
    final progressFontSize = isLargeScreen ? 14.0 : 12.0;
    final progressLetterSp = isLargeScreen ? 2.24 : 1.0;
    final gapHeight = isLargeScreen ? 20.98 : 20.0;
    const progressBarHeight = 5.0;
    final progressSpacing = isLargeScreen ? 0.0 : 20.0;

    // If you have a special progress string for ADMIN, use it here.
    final displayProgress = title.contains('ADMIN')
        ? _calculateAdminProgressString() // Ensure this method exists
        : progress;

    // Clean title to remove newlines for navigation matching
    final cleanTitle = title.replaceAll('\n', ' ').trim();

    return GestureDetector(
      onTap: () {
        // Navigation logic based on the clean title
        switch (cleanTitle) {
          case 'BASIC INFORMATION':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BasicInformationEdit(vehicle: vehicle!),
              ),
            );
            break;
          case 'MAINTENANCE AND WARRANTY':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MaintenanceEditSection(
                  vehicleId: vehicle!.id,
                  isUploading: false,
                  onMaintenanceFileSelected: (file) {},
                  onWarrantyFileSelected: (file) {},
                  oemInspectionType:
                      vehicle!.maintenance.oemInspectionType ?? '',
                  oemInspectionExplanation:
                      vehicle!.maintenance.oemReason ?? '',
                  onProgressUpdate: () {},
                  maintenanceSelection:
                      vehicle!.maintenance.maintenanceSelection ?? '',
                  warrantySelection:
                      vehicle!.maintenance.warrantySelection ?? '',
                  isFromAdmin: Provider.of<UserProvider>(context, listen: false)
                          .getUserRole ==
                      'admin',
                ),
              ),
            );
            break;
          case 'ADMIN':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminEditSection(
                  vehicle: vehicle!,
                  isUploading: false,
                  isEditing: true,
                  onAdminDoc1Selected: (file, name) {},
                  onAdminDoc2Selected: (file, name) {},
                  onAdminDoc3Selected: (file, name) {},
                  requireToSettleType: vehicle!.requireToSettleType ?? 'no',
                  settlementAmount: vehicle!.adminData.settlementAmount,
                  natisRc1Url: vehicle!.adminData.natisRc1Url,
                  licenseDiskUrl: vehicle!.adminData.licenseDiskUrl,
                  settlementLetterUrl: vehicle!.adminData.settlementLetterUrl,
                ),
              ),
            );
            break;
          default:
            if (cleanTitle.contains('TRUCK')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExternalCabEditPage(
                    vehicleId: vehicle!.id,
                    onProgressUpdate: () {
                      setState(() {
                        // Refresh UI after progress update if needed.
                      });
                    },
                  ),
                ),
              );
            }
            break;
        }
      },
      child: Container(
        width: containerWidth,
        padding: EdgeInsets.all(containerPadding),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: ShapeDecoration(
          color: const Color(0x332F7FFF),
          shape: RoundedRectangleBorder(
            side: BorderSide(width: borderSideWidth, color: borderColor),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Box
            Container(
              width: double.infinity,
              height: titleBoxHeight,
              // padding: titleBoxPadding,
              decoration: ShapeDecoration(
                color: borderColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(titleBoxRadius),
                ),
              ),
              child: Center(
                child: AutoSizeText(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleFontSize,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w800,
                    letterSpacing: titleLetterSpace,
                  ),
                ),
              ),
            ),
            SizedBox(height: gapHeight),
            // Progress Row with flexible widgets to allow wrapping
            LayoutBuilder(builder: (context, constraints) {
              return Row(
                children: [
                  // Progress bar takes 70% of available space
                  Expanded(
                    flex: 7,
                    child: Container(
                      height: progressBarHeight,
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: progressBarHeight,
                            decoration: const BoxDecoration(
                              color: Color(0x7F526584),
                            ),
                          ),
                          FractionallySizedBox(
                            widthFactor: progressRatio.clamp(0.0, 1.0),
                            child: Container(
                              height: progressBarHeight,
                              decoration: const BoxDecoration(
                                color: Color(0xFF39BB36),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: progressSpacing),
                  // Progress text takes 30% but will wrap if needed.
                  Expanded(
                    flex: 3,
                    child: Text(
                      displayProgress,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: progressFontSize,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w400,
                        letterSpacing: progressLetterSp,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CustomButton(
        onPressed: () {
          Navigator.pop(context);
        },
        text: 'Save Changes',
        borderColor: Colors.deepOrange,
      ),
    );
  }
}
