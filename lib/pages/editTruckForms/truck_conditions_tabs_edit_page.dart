// lib/pages/truckForms/truck_conditions_tabs_page.dart

import 'dart:io';
import 'package:ctp/pages/editTruckForms/chassis_edit_page.dart';
import 'package:ctp/pages/editTruckForms/drive_train_edit_page.dart';
import 'package:ctp/pages/editTruckForms/external_cab_edit_page.dart';
import 'package:ctp/pages/editTruckForms/internal_cab_edit_page.dart';
import 'package:ctp/pages/editTruckForms/tyres_edit_page.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:provider/provider.dart';

class TruckConditionsTabsEditPage extends StatefulWidget {
  final int initialIndex;
  final File? mainImageFile;
  final String? mainImageUrl;
  final String vehicleId;
  final String referenceNumber;
  final bool isEditing;

  const TruckConditionsTabsEditPage({
    super.key,
    required this.initialIndex,
    this.mainImageFile,
    this.mainImageUrl,
    required this.vehicleId,
    required this.referenceNumber,
    this.isEditing = false,
  });

  @override
  _TruckConditionsTabsEditPageState createState() =>
      _TruckConditionsTabsEditPageState();
}

class _TruckConditionsTabsEditPageState
    extends State<TruckConditionsTabsEditPage> {
  int _selectedTabIndex = 0;
  bool _isSaving = false;
  final bool _isDataModified = false;
  bool _isLoading = true;
  Map<String, dynamic> _cachedData = {};

  // Define GlobalKeys for ExternalCabPage, InternalCabPage, DriveTrainPage, ChassisPage, and TyresPage
  final GlobalKey<ExternalCabEditPageState> _externalCabKey =
      GlobalKey<ExternalCabEditPageState>();
  final GlobalKey<InternalCabEditPageState> _internalCabKey =
      GlobalKey<InternalCabEditPageState>();
  final GlobalKey<DriveTrainEditPageState> _driveTrainKey =
      GlobalKey<DriveTrainEditPageState>();
  final GlobalKey<ChassisEditPageState> _chassisKey =
      GlobalKey<ChassisEditPageState>();
  final GlobalKey<TyresEditPageState> _tyresKey =
      GlobalKey<TyresEditPageState>();

  // Add a flag to track if any data has been modified
  final Map<String, bool> _modifiedSections = {
    'externalCab': false,
    'internalCab': false,
    'driveTrain': false,
    'chassis': false,
    'tyres': false,
  };

  // Add a flag to track if we're navigating home
  bool _isNavigatingHome = false;

  // Add these new properties
  String _vehicleRef = '';
  String _makeModel = '';
  String _vehicleImageUrl = '';

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialIndex;
    print('Initial tab index: $_selectedTabIndex');
    _loadSavedData();
    _loadVehicleDetails();
  }

  // Add this new method to load vehicle details
  Future<void> _loadVehicleDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .get();

      if (doc.exists && mounted) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          setState(() {
            _vehicleRef = data['vehicleRef'] ?? '';
            _makeModel = data['makeModel'] ?? '';
            _vehicleImageUrl = data['mainImageUrl'] ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading vehicle details: $e');
    }
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

      // Reset form fields in all tabs
      _externalCabKey.currentState?.reset();
      _internalCabKey.currentState?.reset();
      _driveTrainKey.currentState?.reset();
      _chassisKey.currentState?.reset();
      _tyresKey.currentState?.reset();

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

  // Modified tab change handler to avoid re-initializing tabs
  Future<bool> _handleTabChange(int newIndex) async {
    if (_selectedTabIndex == newIndex) return true;

    try {
      // Save current tab data before switching
      await _saveCurrentTabData();

      // Set new tab index
      setState(() {
        _selectedTabIndex = newIndex;
      });

      // Remove re-initialization of tabs
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   _initializeTabWithCachedData(newIndex);
      // });

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
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String userRole = userProvider.getUserRole;
    final bool isAdmin = userRole == 'admin'; // Check if the user is an admin
    final bool isDealer = userRole == 'dealer'; // Check if the user is a dealer
    final bool isTransporter =
        userRole == 'transporter'; // Check if the user is a dealer
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
        body: GradientBackground(
          child: SafeArea(
            child: Column(
              children: [
                // Header with vehicle info
                Container(
                  color: AppColors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isTransporter)
                        Text(
                          "Ref#: ${widget.referenceNumber}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(width: 16),
                      Text(
                        "Make/Model: ${_makeModel}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (widget.mainImageUrl != null)
                        Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(widget.mainImageUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),

                // Tab buttons
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    children: [
                      _buildCustomTabButton('BACK', -1, isBackButton: true),
                      _buildCustomTabButton('External Cab', 0),
                      _buildCustomTabButton('Internal Cab', 1),
                      _buildCustomTabButton('Drive Train', 2),
                      _buildCustomTabButton('Chassis', 3),
                      _buildCustomTabButton('Tyres', 4),
                    ],
                  ),
                ),

                // Content area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Expanded(
                          child: IndexedStack(
                            index: _selectedTabIndex,
                            children: [
                              ExternalCabEditPage(
                                key: _externalCabKey,
                                vehicleId: widget.vehicleId,
                                onProgressUpdate: updateTabProgress,
                                isEditing: widget.isEditing,
                              ),
                              InternalCabEditPage(
                                key: _internalCabKey,
                                vehicleId: widget.vehicleId,
                                onProgressUpdate: updateTabProgress,
                                isEditing: widget.isEditing,
                              ),
                              DriveTrainEditPage(
                                key: _driveTrainKey,
                                vehicleId: widget.vehicleId,
                                onProgressUpdate: updateTabProgress,
                                isEditing: widget.isEditing,
                              ),
                              ChassisEditPage(
                                key: _chassisKey,
                                vehicleId: widget.vehicleId,
                                onProgressUpdate: updateTabProgress,
                                isEditing: widget.isEditing,
                              ),
                              TyresEditPage(
                                key: _tyresKey,
                                vehicleId: widget.vehicleId,
                                onProgressUpdate: updateTabProgress,
                                isEditing: widget.isEditing,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        Row(
                          children: [
                            if (_selectedTabIndex < 4)
                              Expanded(
                                child: CustomButton(
                                  text: 'Continue',
                                  onPressed: _isSaving ? null : _handleContinue,
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
          ),
        ),

        // FAB for saving
        floatingActionButton: _modifiedSections.values.contains(true)
            ? FloatingActionButton(
                onPressed: _isSaving ? null : _saveAllModifiedData,
                backgroundColor: Colors.green,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.save),
              )
            : null,
      ),
    );
  }

  // Helper method to create a custom tab button
  Widget _buildCustomTabButton(String title, int index,
      {bool isBackButton = false}) {
    double completionPercentage =
        !isBackButton ? _getCompletionPercentage(index) : 0.0;

    bool isSelected = !isBackButton && _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          if (isBackButton) {
            bool shouldSave = await _showSaveDialog();
            if (shouldSave) {
              await _saveAllModifiedData();
            }
            Navigator.of(context).pop();
          } else {
            await _handleTabChange(index);
          }
        },
        child: Container(
          height: 45,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(
              color: isSelected ? Colors.green : Colors.blue,
              width: 1.0,
            ),
            borderRadius: BorderRadius.zero,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress bar (shown for both selected and unselected tabs)
              if (!isBackButton && completionPercentage > 0)
                Positioned.fill(
                  child: FractionallySizedBox(
                    widthFactor: completionPercentage.clamp(0.0, 1.0),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      color: Colors.green.withOpacity(isSelected ? 1 : 0.7),
                    ),
                  ),
                ),
              // Tab title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add this helper method
  double _getCompletionPercentage(int index) {
    try {
      switch (index) {
        case 0:
          return _externalCabKey.currentState?.getCompletionPercentage() ?? 0.0;
        case 1:
          return _internalCabKey.currentState?.getCompletionPercentage() ?? 0.0;
        case 2:
          return _driveTrainKey.currentState?.getCompletionPercentage() ?? 0.0;
        case 3:
          return _chassisKey.currentState?.getCompletionPercentage() ?? 0.0;
        case 4:
          return _tyresKey.currentState?.getCompletionPercentage() ?? 0.0;
        default:
          return 0.0;
      }
    } catch (e) {
      return 0.0;
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

  Future<bool> _showSaveDialog() async {
    return await showDialog(
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
  }

  void updateTabProgress() {
    if (mounted) {
      setState(() {
        // This will trigger a rebuild of the tab buttons
      });
    }
  }
}