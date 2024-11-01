import 'dart:io';
import 'package:flutter/material.dart';
import 'truck_conditions_tabs_page.dart';

class TruckConditionSection extends StatelessWidget {
  final File? mainImageFile;
  final String? mainImageUrl;
  final String vehicleId;

  const TruckConditionSection({
    Key? key,
    this.mainImageFile,
    this.mainImageUrl,
    required this.vehicleId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Debugging: Track when the build method is called
    print('TruckConditionSection build method called.');

    // List of blocks to represent the truck conditions
    final List<Map<String, String>> truckConditions = [
      {'title': 'EXTERNAL CAB', 'progress': '10 OF 20 STEPS COMPLETED'},
      {'title': 'INTERNAL CAB', 'progress': '10 OF 20 STEPS COMPLETED'},
      {'title': 'DRIVE TRAIN', 'progress': '10 OF 20 STEPS COMPLETED'},
      {'title': 'CHASSIS', 'progress': '10 OF 20 STEPS COMPLETED'},
      {'title': 'TYRES', 'progress': '10 OF 20 STEPS COMPLETED'},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: truckConditions.length,
        itemBuilder: (context, index) {
          // Debugging: Track when each list item is being built
          print('Building item for index: $index');

          final condition = truckConditions[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: InkWell(
              onTap: () {
                // Debugging: Before navigating to the TruckConditionsTabsPage
                print(
                    'Navigating to TruckConditionsTabsPage with initialIndex: $index, vehicleId: $vehicleId');
                if (mainImageFile != null) {
                  print('Main image file provided: ${mainImageFile!.path}');
                } else if (mainImageUrl != null) {
                  print('Main image URL provided: $mainImageUrl');
                } else {
                  print('No main image provided.');
                }

                // Navigate to TruckConditionsTabsPage with the respective tab index and image parameters
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      print('Creating TruckConditionsTabsPage widget...');
                      return TruckConditionsTabsPage(
                        initialIndex: index,
                        mainImageFile: mainImageFile,
                        mainImageUrl: mainImageUrl,
                        vehicleId: vehicleId,
                      );
                    },
                  ),
                ).then((_) {
                  // Debugging: After returning from TruckConditionsTabsPage
                  print('Returned from TruckConditionsTabsPage.');
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue, // Blue background color
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      condition['title']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'PROGRESS: ${condition['progress']}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
