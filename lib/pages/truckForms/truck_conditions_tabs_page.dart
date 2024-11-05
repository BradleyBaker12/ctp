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
    super.key,
    required this.initialIndex,
    this.mainImageFile,
    this.mainImageUrl,
    required this.vehicleId,
  });

  @override
  _TruckConditionsTabsPageState createState() =>
      _TruckConditionsTabsPageState();
}

class _TruckConditionsTabsPageState extends State<TruckConditionsTabsPage> {
  int _selectedTabIndex = 0;
  bool _isSaving = false;
  bool _isDataModified = false;
  bool _isLoading = true;
  Map<String, dynamic> _cachedData = {};

  // Define GlobalKeys for ExternalCabPage, InternalCabPage, DriveTrainPage, ChassisPage, and TyresPage
  final GlobalKey<ExternalCabPageState> _externalCabKey =
      GlobalKey<ExternalCabPageState>();
  final GlobalKey<InternalCabPageState> _internalCabKey =
      GlobalKey<InternalCabPageState>();
  final GlobalKey<DriveTrainPageState> _driveTrainKey =
      GlobalKey<DriveTrainPageState>();
  final GlobalKey<ChassisPageState> _chassisKey = GlobalKey<ChassisPageState>();
  final GlobalKey<TyresPageState> _tyresKey = GlobalKey<TyresPageState>();

  // Add a flag to track if any data has been modified
  Map<String, bool> _modifiedSections = {
    'externalCab': false,
    'internalCab': false,
    'driveTrain': false,
    'chassis': false,
    'tyres': false,
  };

  // Add a flag to track if we're navigating home
  bool _isNavigatingHome = false;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialIndex;
    _loadSavedData();
  }

  // Modified load method to handle cached data
  Future<void> _loadSavedData() async {
    try {
      setState(() => _isLoading = true);

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .get();

      if (doc.exists) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          // Load truckConditions data if it exists
          if (data['truckConditions'] != null) {
            setState(() {
              _cachedData = Map<String, dynamic>.from(data['truckConditions']);
            });
          }

          // Initialize each tab with its respective data
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeTabsWithData();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Enhanced initialization method
  void _initializeTabsWithData() {
    try {
      if (_externalCabKey.currentState != null &&
          _cachedData['externalCab'] != null) {
        _externalCabKey.currentState!
            .initializeWithData(_cachedData['externalCab']);
      }
      if (_internalCabKey.currentState != null &&
          _cachedData['internalCab'] != null) {
        _internalCabKey.currentState!
            .initializeWithData(_cachedData['internalCab']);
      }
      if (_driveTrainKey.currentState != null &&
          _cachedData['driveTrain'] != null) {
        _driveTrainKey.currentState!
            .initializeWithData(_cachedData['driveTrain']);
      }
      if (_chassisKey.currentState != null && _cachedData['chassis'] != null) {
        _chassisKey.currentState!.initializeWithData(_cachedData['chassis']);
      }
      if (_tyresKey.currentState != null && _cachedData['tyres'] != null) {
        _tyresKey.currentState!.initializeWithData(_cachedData['tyres']);
      }
    } catch (e) {
      print('Error initializing tabs with data: $e');
    }
  }

  // Modified Continue button handler
  Future<void> _handleContinue() async {
    try {
      // Save current tab data
      await _saveCurrentTabData();

      // If not on the last tab, move to next tab
      if (_selectedTabIndex < 4) {
        setState(() {
          _selectedTabIndex = _selectedTabIndex + 1;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are on the last tab.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing tab: $e')),
        );
      }
    }
  }

  // Modified Done button handler
  Future<void> _handleDone() async {
    try {
      setState(() => _isSaving = true);

      // Collect data from all tabs
      Map<String, dynamic> allData = {};

      // Get External Cab data
      if (_externalCabKey.currentState != null) {
        allData['externalCab'] = await _externalCabKey.currentState!.getData();
      }

      // Get Internal Cab data
      if (_internalCabKey.currentState != null) {
        allData['internalCab'] = await _internalCabKey.currentState!.getData();
      }

      // Get Drive Train data
      if (_driveTrainKey.currentState != null) {
        allData['driveTrain'] = await _driveTrainKey.currentState!.getData();
      }

      // Get Chassis data
      if (_chassisKey.currentState != null) {
        allData['chassis'] = await _chassisKey.currentState!.getData();
      }

      // Get Tyres data
      if (_tyresKey.currentState != null) {
        allData['tyres'] = await _tyresKey.currentState!.getData();
      }

      // Save all data to Firestore
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .set({
        'truckConditions': allData,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _isNavigatingHome = true;

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data saved successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error saving all data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Modified tab change handler to save data before changing tabs
  Future<bool> _handleTabChange(int newIndex) async {
    if (_selectedTabIndex == newIndex) return true;

    try {
      // Save current tab data before switching
      await _saveCurrentTabData();

      // Set new tab index
      setState(() {
        _selectedTabIndex = newIndex;
      });

      // Initialize the new tab with cached data if available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeTabWithCachedData(newIndex);
      });

      return true;
    } catch (e) {
      print('Error handling tab change: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
        );
      }
      return false;
    }
  }

  // Add method to save current tab data
  Future<void> _saveCurrentTabData() async {
    try {
      Map<String, dynamic> currentTabData = {};

      // Get data from current tab
      switch (_selectedTabIndex) {
        case 0:
          if (_externalCabKey.currentState != null) {
            currentTabData['externalCab'] =
                await _externalCabKey.currentState!.getData();
          }
          break;
        case 1:
          if (_internalCabKey.currentState != null) {
            currentTabData['internalCab'] =
                await _internalCabKey.currentState!.getData();
          }
          break;
        case 2:
          if (_driveTrainKey.currentState != null) {
            currentTabData['driveTrain'] =
                await _driveTrainKey.currentState!.getData();
          }
          break;
        case 3:
          if (_chassisKey.currentState != null) {
            currentTabData['chassis'] =
                await _chassisKey.currentState!.getData();
          }
          break;
        case 4:
          if (_tyresKey.currentState != null) {
            currentTabData['tyres'] = await _tyresKey.currentState!.getData();
          }
          break;
      }

      // Save to Firestore if we have data
      if (currentTabData.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.vehicleId)
            .set({
          'truckConditions': currentTabData,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error saving current tab data: $e');
      rethrow;
    }
  }

  // Add method to initialize specific tab with cached data
  void _initializeTabWithCachedData(int tabIndex) {
    try {
      switch (tabIndex) {
        case 0:
          if (_cachedData['externalCab'] != null &&
              _externalCabKey.currentState != null) {
            _externalCabKey.currentState!
                .initializeWithData(_cachedData['externalCab']);
          }
          break;
        case 1:
          if (_cachedData['internalCab'] != null &&
              _internalCabKey.currentState != null) {
            _internalCabKey.currentState!
                .initializeWithData(_cachedData['internalCab']);
          }
          break;
        case 2:
          if (_cachedData['driveTrain'] != null &&
              _driveTrainKey.currentState != null) {
            _driveTrainKey.currentState!
                .initializeWithData(_cachedData['driveTrain']);
          }
          break;
        case 3:
          if (_cachedData['chassis'] != null &&
              _chassisKey.currentState != null) {
            _chassisKey.currentState!
                .initializeWithData(_cachedData['chassis']);
          }
          break;
        case 4:
          if (_cachedData['tyres'] != null && _tyresKey.currentState != null) {
            _tyresKey.currentState!.initializeWithData(_cachedData['tyres']);
          }
          break;
      }
    } catch (e) {
      print('Error initializing tab with cached data: $e');
    }
  }

  // Update the _cacheCurrentTabData method
  Future<void> _cacheCurrentTabData() async {
    // This can be empty or removed since we're getting fresh data in _handleDone
  }

  Future<void> _saveAllModifiedData() async {
    try {
      setState(() => _isSaving = true);
      await _handleDone();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Modified build method to include a save button
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (!_isNavigatingHome && _modifiedSections.values.contains(true)) {
          bool shouldSave = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Save Changes?'),
                  content: const Text(
                      'Would you like to save your changes before leaving?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Discard'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ) ??
              false;

          if (shouldSave) {
            await _saveAllModifiedData();
          }
        }
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            GradientBackground(
              child: Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + 10.0,
                          bottom: 16.0,
                        ),
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
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Expanded(child: _buildTabContent()),
                              const SizedBox(height: 24.0),
                              Row(
                                children: [
                                  if (_selectedTabIndex < 4)
                                    Expanded(
                                      child: CustomButton(
                                        text: 'Continue',
                                        onPressed:
                                            _isSaving ? null : _handleContinue,
                                        borderColor: AppColors.blue,
                                      ),
                                    ),
                                  if (_selectedTabIndex < 4)
                                    const SizedBox(width: 16.0),
                                  Expanded(
                                    child: CustomButton(
                                      text: 'Done',
                                      onPressed: _isSaving ? null : _handleDone,
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
                  if (_isLoading)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  if (_isSaving)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Saving...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Add a save button that appears when there are modifications
            if (_modifiedSections.values.contains(true))
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  onPressed: _isSaving ? null : _saveAllModifiedData,
                  backgroundColor: Colors.green,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.save),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to create a custom tab button
  Widget _buildCustomTabButton(String title, int index,
      {bool isBackButton = false}) {
    bool isSelected = _selectedTabIndex == index && !isBackButton;
    return GestureDetector(
      onTap: () async {
        if (isBackButton) {
          bool shouldSave = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Save Changes?'),
                  content: const Text(
                      'Would you like to save your changes before leaving?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Discard'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ) ??
              false;

          if (shouldSave) {
            await _saveAllModifiedData();
          }
        } else {
          await _handleTabChange(index);
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

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return ExternalCabPage(
            key: _externalCabKey, vehicleId: widget.vehicleId);
      case 1:
        return InternalCabPage(
            key: _internalCabKey, vehicleId: widget.vehicleId);
      case 2:
        return DriveTrainPage(key: _driveTrainKey, vehicleId: widget.vehicleId);
      case 3:
        return ChassisPage(key: _chassisKey, vehicleId: widget.vehicleId);
      case 4:
        return TyresPage(key: _tyresKey, vehicleId: widget.vehicleId);
      default:
        return const SizedBox.shrink();
    }
  }

  // Add method to clear cached data when navigating home
  @override
  void dispose() {
    if (_isNavigatingHome) {
      _cachedData.clear();
      _modifiedSections.clear();
    }
    super.dispose();
  }
}
