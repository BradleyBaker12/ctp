import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/pages/editTruckForms/basic_information_edit.dart';
import 'package:ctp/pages/editTruckForms/external_cab_edit_page.dart';
import 'package:ctp/pages/editTruckForms/maintenance_edit_section.dart';
import 'package:ctp/pages/editTruckForms/admin_edit_section.dart';
import 'package:flutter/material.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadFormNavigation extends StatefulWidget {
  final Vehicle vehicle;

  const UploadFormNavigation({
    super.key,
    required this.vehicle,
  });

  @override
  State<UploadFormNavigation> createState() => _UploadFormNavigationState();
}

class _UploadFormNavigationState extends State<UploadFormNavigation> {
  Vehicle? vehicle;

  @override
  void initState() {
    super.initState();
    _fetchVehicleData();
  }

  Future<void> _fetchVehicleData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicle.id)
          .get();

      if (!doc.exists) {
        throw Exception('Vehicle document not found');
      }

      vehicle = Vehicle.fromDocument(doc);
      setState(() {});
    } catch (e) {
      print('Error fetching vehicle data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching vehicle data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            Text(
              vehicle!.makeModel.toString().toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 15),
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
            _buildSection(
                context, 'BASIC\nINFORMATION', '10 OF 20 STEPS\nCOMPLETED'),
            _buildSection(
                context, 'TRUCK CONDITION', '10 OF 20 STEPS\nCOMPLETED'),
            _buildSection(
              context,
              'MAINTENANCE\nAND WARRANTY',
              '10 OF 20 STEPS\nCOMPLETED',
            ),
            _buildSection(context, 'ADMIN', '10 OF 20 STEPS\nCOMPLETED'),
            const Spacer(),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String progress) {
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
                    warrantyDocUrl: maintenanceData['warrantyDocUrl'], isFromAdmin: false,
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
              builder: (BuildContext context) => ExternalCabEditPage(
                vehicleId: vehicle!.id,
                isEditing: true,
                onProgressUpdate: () {
                  setState(() {
                    // Update progress if needed
                  });
                },
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              progress,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
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
        text: 'DONE',
        borderColor: Colors.deepOrange,
      ),
    );
  }
}
