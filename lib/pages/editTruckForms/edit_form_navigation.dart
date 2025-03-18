import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/pages/editTruckForms/basic_information_edit.dart';
import 'package:ctp/pages/editTruckForms/external_cab_edit_page.dart';
import 'package:ctp/pages/editTruckForms/internal_cab_edit_page.dart';
import 'package:ctp/pages/editTruckForms/chassis_edit_page.dart';
import 'package:ctp/pages/editTruckForms/drive_train_edit_page.dart';
import 'package:ctp/pages/editTruckForms/tyres_edit_page.dart';
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
import 'package:provider/provider.dart';

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
  // Used to toggle the truck conditions block
  bool _isTruckConditionsExpanded = false;

  @override
  void initState() {
    super.initState();
    // Initialize with the passed vehicle data
    vehicle = widget.vehicle;
    // Then fetch any updates if needed
    _fetchVehicleData();
  }

  Map<String, dynamic> maintenanceData = {};
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
      // print('Raw Firestore data: $data');

      // Handle application field conversion if necessary
      if (data['application'] is String) {
        data['application'] = [data['application']];
      } else if (data['application'] == null) {
        data['application'] = [];
      }
      // Handle brands field conversion if necessary
      if (data['brands'] is String) {
        data['brands'] = [data['brands']];
      } else if (data['brands'] == null) {
        data['brands'] = [];
      }

      if (doc['maintenanceData'] != null) {
        maintenanceData = extractMaintenanceData(doc['maintenanceData']);
      }

      // Create or update the vehicle property
      vehicle = Vehicle.fromDocument(doc);
      setState(() {});
    } catch (e, s) {
      print('Error fetching vehicle data: $e');
      print('Stack trace: $s');
    }
  }

  Map<String, dynamic> extractMaintenanceData(
      Map<String, dynamic> documentData) {
    return {
      "lastUpdated": documentData["lastUpdated"],
      "maintenanceDocUrl": documentData["maintenanceDocUrl"],
      "maintenanceSelection": documentData["maintenanceSelection"],
      "oemInspectionType": documentData["oemInspectionType"],
      "oemReason": documentData["oemReason"],
      "vehicleId": documentData["vehicleId"],
      "warrantyDocUrl": documentData["warrantyDocUrl"],
      "warrantySelection": documentData["warrantySelection"],
      "makeModel": documentData["makeModel"],
      "mileage": documentData["mileage"],
      "province": documentData["province"],
      "rc1NatisFile": documentData["rc1NatisFile"],
    };
  }

  bool isNotEmpty(String? value) {
    var res = value != null && value != "N/A" && value.isNotEmpty;
    print("Res: $res, value: $value");
    return value != null && value != "N/A" && value.isNotEmpty;
  }

  int _calculateBasicInfoProgress() {
    int completedSteps = 9;
    const totalSteps = 15;
    // Main image
    if (isNotEmpty(vehicle?.mainImageUrl)) completedSteps++;
    // Vehicle status
    // if (isNotEmpty(vehicle?.vehicleStatus)) completedSteps++;
    // Reference number
    // if (isNotEmpty(vehicle?.referenceNumber)) completedSteps++;
    // RC1/NATIS file
    if (isNotEmpty(vehicle?.rc1NatisFile)) completedSteps++;
    // Vehicle type (truck/trailer)
    if (isNotEmpty(vehicle?.vehicleType)) completedSteps++;
    // Year
    if (isNotEmpty(vehicle?.year)) completedSteps++;
    // Make/Model
    if (isNotEmpty(vehicle?.makeModel)) completedSteps++;
    // Variant
    if (isNotEmpty(vehicle?.variant)) completedSteps++;
    // Country
    if (isNotEmpty(vehicle?.country)) completedSteps++;
    // Mileage
    if (isNotEmpty(vehicle?.mileage)) completedSteps++;
    // Configuration
    if (isNotEmpty(vehicle?.config)) completedSteps++;
    // Application
    if (vehicle?.application.isNotEmpty == true) completedSteps++;
    // VIN Number
    // if (isNotEmpty(vehicle?.vinNumber)) completedSteps++;
    // Engine Number
    if (isNotEmpty(vehicle?.engineNumber)) completedSteps++;
    // Registration Number
    if (isNotEmpty(vehicle?.registrationNumber)) completedSteps++;
    return completedSteps;
  }

  int _calculateMaintenanceProgress() {
    int completedSteps = 0;
    const totalSteps = 4; // Total possible fields

    print("Maintenance Data: $maintenanceData");

    // Check maintenance document
    if (maintenanceData["maintenanceDocUrl"] != null) completedSteps++;

    // Check warranty document
    if (maintenanceData["warrantyDocUrl"] != null) completedSteps++;

    // Check OEM inspection type
    if (maintenanceData["oemInspectionType"] != null) completedSteps++;

    // Check OEM reason if inspection type is 'no'
    if (maintenanceData["oemInspectionType"] == 'no' &&
        (maintenanceData["oemReason"]?.isNotEmpty ?? false)) {
      completedSteps++;
    }

    return completedSteps;
  }

  int _calculateAdminProgress() {
    int completedSteps = 0;
    if (vehicle?.adminData.natisRc1Url != null) completedSteps++;
    if (vehicle?.adminData.licenseDiskUrl != null) completedSteps++;
    if (vehicle?.requireToSettleType == 'yes') {
      if (vehicle?.adminData.settlementLetterUrl != null) completedSteps++;
      if (vehicle?.adminData.settlementAmount.isNotEmpty == true) {
        completedSteps++;
      }
    }
    return completedSteps;
  }

  // Truck Conditions progress is the sum of all its subsections progress

  int _calculateExternalCabProgress() {
    int completedSteps = 0;
    int totalSteps = 7;
    final externalCab = vehicle?.truckConditions.externalCab;
    // Check main condition
    if (externalCab?.condition.isNotEmpty == true) completedSteps++;

    // Check images
    // if (externalCab?.images.isNotEmpty == true) completedSteps++;
    print("Images: ${externalCab?.images.length ?? 0}");
    completedSteps += externalCab?.images.length ?? 0;

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
        20; // Base fields: condition, damages, additional features, fault codes, view images

    final internalCab = vehicle?.truckConditions.internalCab;

    // Check main condition
    if (internalCab?.condition.isNotEmpty == true) completedSteps++;

    // Check view images
    // if (internalCab?.viewImages.isNotEmpty == true) completedSteps++;
    completedSteps += internalCab?.viewImages.length ?? 0;

    var keysList = internalCab?.viewImages.keys.toList() ?? [];
    // "Right Dash (Vehicle On)" and "Left Dash" are linked to other parts of the vehicle
    if (keysList.contains("Right Dash (Vehicle On)")) {
      completedSteps += 1;
    }
    if (keysList.contains("Left Dash")) {
      completedSteps += 1;
    }

    // Check damages section
    if (internalCab?.damagesCondition.isNotEmpty == true) completedSteps++;

    // Check additional features section
    if (internalCab?.additionalFeaturesCondition.isNotEmpty == true) {
      completedSteps++;
    }

    // Check fault codes section
    if (internalCab?.faultCodesCondition.isNotEmpty == true) completedSteps++;

    return completedSteps <= totalSteps ? completedSteps : totalSteps;
  }

  int _calculateDriveTrainProgress() {
    int completedSteps = 0;
    int totalSteps = 21; // All fields from the DriveTrain model

    final driveTrain = vehicle?.truckConditions.driveTrain;

    // Check main condition
    if (driveTrain?.condition.isNotEmpty == true) completedSteps++;

    if (driveTrain == null) {
      return 0;
    }

    // Check main condition
    if (isNotEmpty(driveTrain.condition)) completedSteps++;

    // Check engine conditions
    if (isNotEmpty(driveTrain.oilLeakConditionEngine)) completedSteps++;
    if (isNotEmpty(driveTrain.waterLeakConditionEngine)) {
      completedSteps++;
    }
    if (isNotEmpty(driveTrain.blowbyCondition)) completedSteps++;

    // Check gearbox and retarder conditions
    if (isNotEmpty(driveTrain.oilLeakConditionGearbox)) {
      completedSteps++;
    }
    if (isNotEmpty(driveTrain.retarderCondition)) completedSteps++;

    if (driveTrain.images.isNotEmpty) {
      int validImageCount = driveTrain.images.entries
          .where((entry) => entry.key.isNotEmpty && entry.value.isNotEmpty)
          .length;

      completedSteps += validImageCount;

      // "Engine Left" and "Engine Right" are linked to other parts of the vehicle
      if (driveTrain.images.containsKey("Engine Left") &&
          driveTrain.images["Engine Left"]!.isNotEmpty) {
        completedSteps++;
      }
      if (driveTrain.images.containsKey("Engine Right") &&
          driveTrain.images["Engine Right"]!.isNotEmpty) {
        completedSteps++;
      }
    }
    // Check damages
    if (driveTrain.damages.isNotEmpty == true) completedSteps++;

    // Check additional features
    if (driveTrain.additionalFeatures.isNotEmpty == true) completedSteps++;

    // Check fault codes
    if (driveTrain.faultCodes.isNotEmpty == true) completedSteps++;
    // completedSteps += driveTrain?.faultCodes.length ?? 0;

    return completedSteps <= totalSteps ? completedSteps : totalSteps;
  }

  int _calculateChassisProgress() {
    int completedSteps = 0;
    int totalSteps =
        17; // Base fields: condition, images, damages, additional features

    final chassis = vehicle?.truckConditions.chassis;

    // Check main condition
    if (chassis?.condition.isNotEmpty == true) completedSteps++;

    // Check images
    // if (chassis?.images.isNotEmpty == true) completedSteps++;
    completedSteps += chassis?.images.length ?? 0;

    // Check damages section
    if (chassis?.damagesCondition.isNotEmpty == true) completedSteps++;

    // Check additional features section
    if (chassis?.additionalFeaturesCondition.isNotEmpty == true) {
      completedSteps++;
    }

    return completedSteps <= totalSteps ? completedSteps : totalSteps;
  }

  int _calculateTyresProgress() {
    int completedSteps = 0;
    int totalSteps = 24;

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
          if (tyreData?.imagePath != null && tyreData!.imagePath.isNotEmpty) {
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

  // ---------------------------
  // Custom Truck Conditions Section Block
  // ---------------------------
  Widget _buildTruckConditionsSection(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;
    final containerWidth = isLargeScreen ? 942.0 : size.width * 0.9;
    final containerPadding = isLargeScreen ? 37.31 : 16.0;
    const borderSideWidth = 0.93;
    const borderRadius = 20.0;
    const borderColor = Color(0xFF2F7FFF);
    final titleBoxHeight = isLargeScreen ? 76.48 : 45.0;
    final titleBoxPadding = isLargeScreen
        ? const EdgeInsets.symmetric(horizontal: 48.50, vertical: 18.65)
        : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
    const titleBoxRadius = 6.0;
    final titleFontSize = isLargeScreen ? 20.0 : 14.0;
    final titleLetterSpace = isLargeScreen ? 1.87 : 0.5;
    final progressFontSize = isLargeScreen ? 22.38 : 12.0;
    final progressLetterSp = isLargeScreen ? 2.24 : 0.5;
    final gapHeight = isLargeScreen ? 27.98 : 16.0;
    const progressBarHeight = 5.0;
    final progressSpacing = isLargeScreen ? 26.11 : 12.0;

    int subSectionTotal = 35;
    int subSectionCompleted = _calculateTruckConditionsProgress();
    double topRatio =
        subSectionTotal == 0 ? 0 : (subSectionCompleted / subSectionTotal);

    return Container(
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
        children: [
          // Header: Tappable to toggle expansion
          GestureDetector(
            onTap: () {
              setState(() {
                _isTruckConditionsExpanded = !_isTruckConditionsExpanded;
              });
            },
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: titleBoxHeight,
                  padding: titleBoxPadding,
                  decoration: ShapeDecoration(
                    color: borderColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(titleBoxRadius),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'TRUCK CONDITIONS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w800,
                        height: 1.10,
                        letterSpacing: titleLetterSpace,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: gapHeight),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: progressBarHeight,
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: progressBarHeight,
                              color: const Color(0x7F526584),
                            ),
                            FractionallySizedBox(
                              widthFactor: topRatio,
                              child: Container(
                                height: progressBarHeight,
                                color: const Color(0xFF39BB36),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: progressSpacing),
                    Text(
                      '$subSectionCompleted/$subSectionTotal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: progressFontSize,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w400,
                        height: 1.40,
                        letterSpacing: progressLetterSp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Expanded content: show subsections if toggled open
          if (_isTruckConditionsExpanded) ...[
            const SizedBox(height: 20),
            _buildSubSectionItem(
              context: context,
              containerWidth: containerWidth,
              title: 'EXTERNAL CAB',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExternalCabEditPage(
                    vehicleId: widget.vehicle.id,
                    isEditing: true,
                    onProgressUpdate: () {
                      setState(() {
                        _fetchVehicleData();
                      });
                    },
                  ),
                ),
              ),
              progressString: _calculateExternalCabProgress().toString(),
              progressRatio: _calculateExternalCabProgress() / 4,
              titleBoxHeight: titleBoxHeight,
              titleBoxPadding: titleBoxPadding,
              borderColor: borderColor,
              gapHeight: gapHeight,
              progressBarHeight: progressBarHeight,
              progressSpacing: progressSpacing,
              titleFontSize: titleFontSize,
              titleLetterSpace: titleLetterSpace,
              progressFontSize: progressFontSize,
              progressLetterSp: progressLetterSp,
              titleBoxRadius: titleBoxRadius,
            ),
            _buildSubSectionItem(
              context: context,
              containerWidth: containerWidth,
              title: 'INTERNAL CAB',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InternalCabEditPage(
                    vehicleId: widget.vehicle.id,
                    isEditing: true,
                    onProgressUpdate: () {
                      setState(() {});
                    },
                  ),
                ),
              ),
              progressString: _calculateInternalCabProgress().toString(),
              progressRatio: _calculateInternalCabProgress() / 5,
              titleBoxHeight: titleBoxHeight,
              titleBoxPadding: titleBoxPadding,
              borderColor: borderColor,
              gapHeight: gapHeight,
              progressBarHeight: progressBarHeight,
              progressSpacing: progressSpacing,
              titleFontSize: titleFontSize,
              titleLetterSpace: titleLetterSpace,
              progressFontSize: progressFontSize,
              progressLetterSp: progressLetterSp,
              titleBoxRadius: titleBoxRadius,
            ),
            _buildSubSectionItem(
              context: context,
              containerWidth: containerWidth,
              title: 'CHASSIS',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChassisEditPage(
                    vehicleId: widget.vehicle.id,
                    isEditing: true,
                    onProgressUpdate: () {
                      setState(() {});
                    },
                  ),
                ),
              ),
              progressString: _calculateChassisProgress().toString(),
              progressRatio: _calculateChassisProgress() / 4,
              titleBoxHeight: titleBoxHeight,
              titleBoxPadding: titleBoxPadding,
              borderColor: borderColor,
              gapHeight: gapHeight,
              progressBarHeight: progressBarHeight,
              progressSpacing: progressSpacing,
              titleFontSize: titleFontSize,
              titleLetterSpace: titleLetterSpace,
              progressFontSize: progressFontSize,
              progressLetterSp: progressLetterSp,
              titleBoxRadius: titleBoxRadius,
            ),
            _buildSubSectionItem(
              context: context,
              containerWidth: containerWidth,
              title: 'DRIVE TRAIN',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DriveTrainEditPage(
                    vehicleId: widget.vehicle.id,
                    isEditing: true,
                    onProgressUpdate: () {
                      setState(() {});
                    },
                  ),
                ),
              ),
              progressString: _calculateDriveTrainProgress().toString(),
              progressRatio: _calculateDriveTrainProgress() / 10,
              titleBoxHeight: titleBoxHeight,
              titleBoxPadding: titleBoxPadding,
              borderColor: borderColor,
              gapHeight: gapHeight,
              progressBarHeight: progressBarHeight,
              progressSpacing: progressSpacing,
              titleFontSize: titleFontSize,
              titleLetterSpace: titleLetterSpace,
              progressFontSize: progressFontSize,
              progressLetterSp: progressLetterSp,
              titleBoxRadius: titleBoxRadius,
            ),
            _buildSubSectionItem(
              context: context,
              containerWidth: containerWidth,
              title: 'TYRES',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TyresEditPage(
                    vehicleId: widget.vehicle.id,
                    isEditing: true,
                    onProgressUpdate: () {
                      setState(() {});
                    },
                  ),
                ),
              ),
              progressString: _calculateTyresProgress().toString(),
              progressRatio:
                  _calculateTyresProgress() / 36, // adjust based on your logic
              titleBoxHeight: titleBoxHeight,
              titleBoxPadding: titleBoxPadding,
              borderColor: borderColor,
              gapHeight: gapHeight,
              progressBarHeight: progressBarHeight,
              progressSpacing: progressSpacing,
              titleFontSize: titleFontSize,
              titleLetterSpace: titleLetterSpace,
              progressFontSize: progressFontSize,
              progressLetterSp: progressLetterSp,
              titleBoxRadius: titleBoxRadius,
            ),
          ],
        ],
      ),
    );
  }

  // Helper for building a sub-section block
  Widget _buildSubSectionItem({
    required BuildContext context,
    required double containerWidth,
    required String title,
    required VoidCallback onTap,
    required String progressString,
    required double progressRatio,
    required double titleBoxHeight,
    required EdgeInsets titleBoxPadding,
    required Color borderColor,
    required double gapHeight,
    required double progressBarHeight,
    required double progressSpacing,
    required double titleFontSize,
    required double titleLetterSpace,
    required double progressFontSize,
    required double progressLetterSp,
    required double titleBoxRadius,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 15),
        width: containerWidth * 0.8,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: containerWidth * 0.8,
              height: titleBoxHeight,
              padding: titleBoxPadding,
              decoration: ShapeDecoration(
                color: borderColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(titleBoxRadius),
                ),
              ),
              child: Center(
                child: Text(
                  title.toUpperCase(),
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
            Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(2.5),
                        child: SizedBox(
                          height: progressBarHeight,
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                height: progressBarHeight,
                                color: const Color(0x7F526584),
                              ),
                              Container(
                                width: constraints.maxWidth *
                                    progressRatio.clamp(0.0, 1.0),
                                height: progressBarHeight,
                                color: const Color(0xFF39BB36),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: progressSpacing),
                SizedBox(
                  width: 60,
                  child: Text(
                    progressString,
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
            ),
          ],
        ),
      ),
    );
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

  void _navigateToMaintenance() async {
    try {
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
            isFromTransporter: true,
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
  }

  @override
  Widget build(BuildContext context) {
    if (vehicle == null) {
      return Center(child: CircularProgressIndicator());
    }
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isCompactNavigation = screenWidth < 800;
    final bool showHamburger = screenWidth <= 1024;
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
          : null,
      // : AppBar(
      //     backgroundColor: Colors.blueAccent,
      //     leading: showHamburger
      //         ? Builder(
      //             builder: (BuildContext context) => IconButton(
      //               icon: const Icon(Icons.menu, color: Colors.white),
      //               onPressed: () => _showNavigationDrawer([]),
      //             ),
      //           )
      //         : Container(
      //             margin: const EdgeInsets.all(4),
      //             decoration: BoxDecoration(
      //               color: Colors.black,
      //               borderRadius: BorderRadius.circular(4),
      //             ),
      //             child: IconButton(
      //               padding: EdgeInsets.zero,
      //               constraints: const BoxConstraints(
      //                 minWidth: 30,
      //                 minHeight: 30,
      //               ),
      //               icon: const Text(
      //                 'BACK',
      //                 style: TextStyle(
      //                   color: Colors.white,
      //                   fontSize: 12,
      //                   fontWeight: FontWeight.bold,
      //                 ),
      //               ),
      //               onPressed: () => Navigator.pop(context),
      //             ),
      //           ),
      //     title: Row(
      //       mainAxisAlignment: MainAxisAlignment.end,
      //       children: [
      //         Text(
      //           vehicle!.referenceNumber ?? 'REF',
      //           style: const TextStyle(color: Colors.white, fontSize: 15),
      //         ),
      //         const SizedBox(width: 16),
      //         Expanded(
      //           child: Text(
      //             vehicle!.makeModel.toString().toUpperCase(),
      //             style: const TextStyle(color: Colors.white, fontSize: 15),
      //           ),
      //         ),
      //         const SizedBox(width: 16),
      //       ],
      //     ),
      //     actions: [
      //       Padding(
      //         padding: const EdgeInsets.only(right: 16.0),
      //         child: CircleAvatar(
      //           radius: 24,
      //           backgroundImage: vehicle!.mainImageUrl != null
      //               ? NetworkImage(vehicle!.mainImageUrl!) as ImageProvider
      //               : const AssetImage('assets/truck_image.png'),
      //         ),
      //       ),
      //     ],
      //   ),
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
                    _buildSection(context, 'BASIC\nINFORMATION',
                        '${_calculateBasicInfoProgress()}/21'),
                    // Custom Truck Conditions Block
                    _buildSection(context, 'TRUCK CONDITION',
                        '${_calculateTruckConditionsProgress()}/89'),
                    _buildSection(
                      context,
                      'MAINTENANCE\nAND WARRANTY',
                      '${_calculateMaintenanceProgress()}/${maintenanceData["oemInspectionType"] == 'no' ? 4 : 3}',
                    ),
                    _buildSection(
                        context, 'ADMIN', '${_calculateAdminProgress()}/2'),

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
    int total = 3;
    if (widget.vehicle.adminData.natisRc1Url.isNotEmpty ?? false) {
      completed++;
    }
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
    final displayProgress =
        title.contains('ADMIN') ? _calculateAdminProgressString() : progress;

    List<String> progressValues = progress.split('/');
    double first = double.parse(progressValues[0]);
    double second = double.parse(progressValues[1]);
    double progressValue = first / second;

    return GestureDetector(
      onTap: () {
        switch (title.replaceAll('\n', ' ').trim()) {
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
                  isFromTransporter: true,
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
            if (title.contains('TRUCK')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExternalCabEditPage(
                    vehicleId: vehicle!.id,
                    onProgressUpdate: () {
                      setState(() {});
                    },
                  ),
                ),
              );
            }
            break;
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 10).copyWith(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Prevents infinite height issues
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.green),
                      backgroundColor: Colors.grey.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    progress,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (title.contains('TRUCK CONDITION')) ...[
              subFields("EXTERNAL CAB", '${_calculateExternalCabProgress()}/7'),
              subFields(
                  "INTERNAL CAB", '${_calculateInternalCabProgress()}/20'),
              subFields("CHASSIS", '${_calculateChassisProgress()}/17'),
              subFields("DRIVE TRAIN", '${_calculateDriveTrainProgress()}/21'),
              subFields("TYRES", '${_calculateTyresProgress()}/24'),
            ],
          ],
        ),
      ),
    );
  }

  Widget subFields(String title, String progress) {
    List<String> progressValues = progress.split('/');
    double first = double.parse(progressValues[0]);
    double second = double.parse(progressValues[1]);
    double progressValue = first / second;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width / 1.6,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width / 2,
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
                  backgroundColor: Colors.grey.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                progress,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
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
