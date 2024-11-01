// lib/pages/truckForms/truck_conditions_tabs_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'external_cab_page.dart';
import 'internal_cab_page.dart';
import 'drive_train_page.dart';
import 'chassis_page.dart';
import 'tyres_page.dart';

class TruckConditionsTabsPage extends StatefulWidget {
  final int initialIndex;
  final File? mainImageFile;
  final String? mainImageUrl;
  final String vehicleId;

  const TruckConditionsTabsPage({
    Key? key,
    required this.initialIndex,
    this.mainImageFile,
    this.mainImageUrl,
    required this.vehicleId,
  }) : super(key: key);

  @override
  _TruckConditionsTabsPageState createState() =>
      _TruckConditionsTabsPageState();
}

class _TruckConditionsTabsPageState extends State<TruckConditionsTabsPage>
    with AutomaticKeepAliveClientMixin {
  int _selectedTabIndex = 0;
  bool _isSaving = false;

  // Define GlobalKeys for ExternalCabPage, InternalCabPage, DriveTrainPage, ChassisPage, and TyresPage
  final GlobalKey<ExternalCabPageState> _externalCabKey =
      GlobalKey<ExternalCabPageState>();
  final GlobalKey<InternalCabPageState> _internalCabKey =
      GlobalKey<InternalCabPageState>();
  final GlobalKey<DriveTrainPageState> _driveTrainKey =
      GlobalKey<DriveTrainPageState>();
  final GlobalKey<ChassisPageState> _chassisKey = GlobalKey<ChassisPageState>();
  final GlobalKey<TyresPageState> _tyresKey = GlobalKey<TyresPageState>();

  @override
  bool get wantKeepAlive => true; // Implementing the required getter

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialIndex;
  }

  // Using IndexedStack to keep the state alive across tab switches.
  Widget _buildTabContent() {
    return IndexedStack(
      index: _selectedTabIndex,
      children: [
        ExternalCabPage(
          key: _externalCabKey, // Assign the GlobalKey here
          vehicleId: widget.vehicleId,
        ),
        InternalCabPage(
          key: _internalCabKey, // Assign the GlobalKey here
          vehicleId: widget.vehicleId,
        ),
        DriveTrainPage(
          key: _driveTrainKey, // Assign the GlobalKey here
          vehicleId: widget.vehicleId,
        ),
        ChassisPage(
          key: _chassisKey, // Assign the GlobalKey here
          vehicleId: widget.vehicleId,
        ),
        TyresPage(
          key: _tyresKey, // Assign the GlobalKey here
          vehicleId: widget.vehicleId,
        ),
      ],
    );
  }

  // Method to save data of the current tab
  Future<void> _saveCurrentTabData() async {
    if (_isSaving) return; // Prevent multiple saves at the same time

    setState(() {
      _isSaving = true;
    });

    try {
      bool success = false;
      switch (_selectedTabIndex) {
        case 0:
          // ExternalCabPage
          success = await _externalCabKey.currentState?.saveData() ?? false;
          break;
        case 1:
          // InternalCabPage
          success = await _internalCabKey.currentState?.saveData() ?? false;
          break;
        case 2:
          // DriveTrainPage
          success = await _driveTrainKey.currentState?.saveData() ?? false;
          break;
        case 3:
          // ChassisPage
          success = await _chassisKey.currentState?.saveData() ?? false;
          break;
        case 4:
          // TyresPage
          success = await _tyresKey.currentState?.saveData() ?? false;
          break;
        default:
          break;
      }

      if (!success) {
        throw Exception('Failed to save data for the current tab.');
      }

      // Optionally, handle post-save operations here
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save data: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      body: GradientBackground(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              Column(
                children: [
                  Stack(
                    children: [
                      _buildImageSection(),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10.0,
                        left: 0,
                        right: 0,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              _buildCustomTabButton('BACK', -1,
                                  isBackButton: true),
                              _buildCustomTabButton('External Cab', 0),
                              _buildCustomTabButton('Internal Cab', 1),
                              _buildCustomTabButton('Drive Train', 2),
                              _buildCustomTabButton('Chassis', 3),
                              _buildCustomTabButton('Tyres', 4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Expanded(child: _buildTabContent()),
                          const SizedBox(height: 24.0),
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: 'Continue',
                                  onPressed: () async {
                                    await _saveCurrentTabData();
                                    if (_selectedTabIndex < 4) {
                                      setState(() {
                                        _selectedTabIndex++;
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'You are on the last tab.')),
                                      );
                                    }
                                  },
                                  borderColor: AppColors.blue,
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: CustomButton(
                                  text: 'Done',
                                  onPressed: () async {
                                    await _saveCurrentTabData();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'All data saved successfully.')),
                                    );
                                    Navigator.of(context).pop();
                                  },
                                  borderColor: AppColors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_isSaving)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build the main image section
  Widget _buildImageSection() {
    return Container(
      height: 300.0,
      width: double.infinity,
      decoration: BoxDecoration(
        image: widget.mainImageFile != null
            ? DecorationImage(
                image: FileImage(widget.mainImageFile!),
                fit: BoxFit.cover,
              )
            : (widget.mainImageUrl != null && widget.mainImageUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(widget.mainImageUrl!),
                    fit: BoxFit.cover,
                  )
                : null),
        color: Colors.grey[300],
      ),
      child: widget.mainImageFile == null &&
              (widget.mainImageUrl == null || widget.mainImageUrl!.isEmpty)
          ? const Center(
              child: Text(
                'No Image Available',
                style: TextStyle(color: Colors.black54),
              ),
            )
          : null,
    );
  }

  // Helper method to create a custom tab button
  Widget _buildCustomTabButton(String title, int index,
      {bool isBackButton = false}) {
    bool isSelected = _selectedTabIndex == index && !isBackButton;
    return GestureDetector(
      onTap: () async {
        if (isBackButton) {
          Navigator.pop(context);
        } else {
          await _saveCurrentTabData();
          if (mounted) {
            setState(() {
              _selectedTabIndex = index;
            });
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.blue,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.transparent, width: 0.0),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
