import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/editTruckForms/admin_edit_section.dart';
import 'package:ctp/pages/editTruckForms/basic_information_edit.dart';
import 'package:ctp/pages/editTruckForms/maintenance_edit_section.dart';
import 'package:ctp/pages/editTruckForms/truck_conditions_tabs_edit_page.dart';
import 'package:ctp/pages/vehicles_list.dart';
import 'package:ctp/utils/navigation.dart';
import 'package:flutter/material.dart';

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
      if (doc['maintenanceData'] != null) {
        maintenanceData = extractMaintenanceData(doc['maintenanceData']);
      }
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
    return value != null && value != "N/A" && value.isNotEmpty;
  }

  int _calculateBasicInfoProgress() {
    int completedSteps = 9;
    const totalSteps = 15; // Total number of possible fields

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
    int totalSteps = 7; // Base fields: condition, damages, additional features

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

    var driveTrainKeys = driveTrain?.images.keys.toList() ?? [];

    // "Engine Left" and "Engine Right" are linked to other parts of the vehicle
    if (driveTrainKeys.contains("Engine Left")) {
      completedSteps += 1;
    }
    if (driveTrainKeys.contains("Engine Right")) {
      completedSteps += 1;
    }
    // if (driveTrain?.images.isNotEmpty == true) completedSteps++;
    completedSteps += driveTrain?.images.length ?? 0;

    // Check damages
    if (driveTrain?.damages.isNotEmpty == true) completedSteps++;

    // Check additional features
    if (driveTrain?.additionalFeatures.isNotEmpty == true) completedSteps++;

    // Check fault codes
    if (driveTrain?.faultCodes.isNotEmpty == true) completedSteps++;
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

  @override
  Widget build(BuildContext context) {
    if (vehicle == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        leading: Container(
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
      body: GradientBackground(
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
              _buildSection(context, 'TRUCK CONDITION',
                  '${_calculateTruckConditionsProgress()}/89'),
              _buildSection(
                context,
                'MAINTENANCE\nAND WARRANTY',
                '${_calculateMaintenanceProgress()}/${maintenanceData["oemInspectionType"] == 'no' ? 4 : 3}',
              ),
              _buildSection(context, 'ADMIN', '${_calculateAdminProgress()}/2'),
              const SizedBox(height: 20),
              if (vehicle?.vehicleStatus == 'Draft')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: CustomButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('vehicles')
                          .doc(vehicle!.id)
                          .update({'vehicleStatus': 'Live'});

                      // Fetch updated vehicle data
                      await _fetchVehicleData();
                      await MyNavigator.pushReplacement(
                          context, VehiclesListPage());
                    },
                    text: 'PUSH TO LIVE',
                    borderColor: Colors.green,
                  ),
                )
              else if (vehicle?.vehicleStatus == 'Live')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: CustomButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('vehicles')
                          .doc(vehicle!.id)
                          .update({'vehicleStatus': 'Draft'});

                      // Fetch updated vehicle data
                      await _fetchVehicleData();
                      await MyNavigator.pushReplacement(
                          context, VehiclesListPage());
                    },
                    text: 'MOVE TO DRAFT',
                    borderColor: Colors.blueAccent,
                  ),
                ),
              const SizedBox(height: 20),
              _buildBottomButtons(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String progress) {
    List<String> progressValues = progress.split('/');
    double first = double.parse(progressValues[0]);
    double second = double.parse(progressValues[1]);
    double progressValue = first / second;
    return GestureDetector(
      onTap: () async {
        if (title.contains('MAINTENANCE')) {
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
                builder: (BuildContext context) => Scaffold(
                  appBar: AppBar(
                    backgroundColor: Colors.blueAccent,
                    leading: Container(
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
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          vehicle!.makeModel.toString().toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15),
                        ),
                      ],
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundImage: vehicle!.mainImageUrl != null
                              ? NetworkImage(vehicle!.mainImageUrl!)
                                  as ImageProvider
                              : const AssetImage('assets/truck_image.png'),
                        ),
                      ),
                    ],
                  ),
                  body: MaintenanceEditSection(
                    vehicleId: vehicle!.id,
                    isUploading: false,
                    isEditing: true,
                    isFromAdmin: true,
                    onMaintenanceFileSelected: (file) {
                      // Handle maintenance file selection
                    },
                    onWarrantyFileSelected: (file) {
                      // Handle warranty file selection
                    },
                    oemInspectionType:
                        maintenanceData['oemInspectionType'] ?? 'yes',
                    oemInspectionExplanation:
                        maintenanceData['oemReason'] ?? '',
                    onProgressUpdate: () {
                      setState(() {
                        // Update progress if needed
                      });
                    },
                    maintenanceSelection:
                        maintenanceData['maintenanceSelection'] ?? 'yes',
                    warrantySelection:
                        maintenanceData['warrantySelection'] ?? 'yes',
                    maintenanceDocUrl: maintenanceData['maintenanceDocUrl'],
                    warrantyDocUrl: maintenanceData['warrantyDocUrl'],
                  ),
                ),
              ),
            );

            // Refresh the vehicle data after returning from maintenance
            setState(() {});
          } catch (e) {
            print('Error loading maintenance data: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading maintenance data: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else if (title.contains('BASIC')) {
          var updatedVehicle = await Navigator.of(context).push<Vehicle>(
            MaterialPageRoute(
              builder: (BuildContext context) => BasicInformationEdit(
                vehicle: vehicle!,
              ),
            ),
          );
          if (updatedVehicle != null) {
            setState(() {
              vehicle = updatedVehicle;
            });
          }
        } else if (title.contains('TRUCK CONDITION')) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) => TruckConditionsTabsEditPage(
                initialIndex: 0,
                vehicleId: vehicle!.id,
                mainImageUrl: vehicle!.mainImageUrl,
                referenceNumber: vehicle!.referenceNumber ?? 'REF',
                isEditing: true,
              ),
            ),
          );
          // Refresh the vehicle data after returning from truck conditions
          setState(() {});
        } else if (title.contains('ADMIN')) {
          // Navigate to AdminEditSection with vehicleId
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) => AdminEditSection(
                vehicle: vehicle!,
                isUploading: false,
                isEditing: true,
                onAdminDoc1Selected: (file, fileName) {
                  // Handle admin doc 1 selection
                },
                onAdminDoc2Selected: (file, fileName) {
                  // Handle admin doc 2 selection
                },
                onAdminDoc3Selected: (file, fileName) {
                  // Handle admin doc 3 selection
                },
                requireToSettleType: vehicle!.requireToSettleType ?? 'no',
                settlementAmount: vehicle!.adminData.settlementAmount,
                natisRc1Url: vehicle!.adminData.natisRc1Url,
                licenseDiskUrl: vehicle!.adminData.licenseDiskUrl,
                settlementLetterUrl: vehicle!.adminData.settlementLetterUrl,
              ),
            ),
          );
          // Refresh the vehicle data after returning from admin edit
          setState(() {});
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
        text: 'DONE',
        borderColor: Colors.deepOrange,
      ),
    );
  }
}
