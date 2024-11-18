import 'dart:io';
import 'package:flutter/material.dart';
import 'truck_conditions_tabs_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TruckConditionSection extends StatelessWidget {
  final File? mainImageFile;
  final String? mainImageUrl;
  final String vehicleId;

  const TruckConditionSection({
    super.key,
    this.mainImageFile,
    this.mainImageUrl,
    required this.vehicleId,
  });

  Future<Map<String, int>> getOverallProgress(int index) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['truckConditions'] != null) {
          Map<String, dynamic> conditions = data['truckConditions'];

          // Define section-specific field counts based on each page's actual fields
          final Map<String, int> sectionTotals = {
            'externalCab':
                7, // From ExternalCabPage (1 condition + 4 images + 2 sections)
            'internalCab': 15, // From InternalCabPage
            'driveTrain': 19, // From DriveTrainPage
            'chassis':
                17, // From ChassisPage (1 condition + 14 images + 2 sections)
            'tyres': 24, // From TyresPage (6 positions × 4 fields)
          };

          // Get the section based on index
          String sectionKey = _getSectionKey(index);
          int sectionTotal = sectionTotals[sectionKey] ?? 0;
          int sectionCompleted = 0;

          if (conditions[sectionKey] != null) {
            Map<String, dynamic> section = conditions[sectionKey];
            section.forEach((key, value) {
              if (value != null && value.toString().isNotEmpty) {
                sectionCompleted++;
              }
            });
          }

          return {
            'completed': sectionCompleted,
            'total': sectionTotal,
          };
        }
      }
      return {'completed': 0, 'total': 0};
    } catch (e) {
      print('Error calculating overall progress: $e');
      return {'completed': 0, 'total': 0};
    }
  }

  String _getSectionKey(int index) {
    switch (index) {
      case 0:
        return 'externalCab';
      case 1:
        return 'internalCab';
      case 2:
        return 'driveTrain';
      case 3:
        return 'chassis';
      case 4:
        return 'tyres';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TruckConditionsTabsPage(
                      initialIndex: index,
                      mainImageFile: mainImageFile,
                      mainImageUrl: mainImageUrl,
                      vehicleId: vehicleId,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _getSectionTitle(index),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getSectionTitle(int index) {
    switch (index) {
      case 0:
        return 'EXTERNAL CAB';
      case 1:
        return 'INTERNAL CAB';
      case 2:
        return 'DRIVE TRAIN';
      case 3:
        return 'CHASSIS';
      case 4:
        return 'TYRES';
      default:
        return '';
    }
  }
}
