// lib/adminScreens/create_fleet_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ctp/models/vehicle.dart';

@RoutePage()
class CreateFleetPage extends StatefulWidget {
  const CreateFleetPage({super.key});

  @override
  _CreateFleetPageState createState() => _CreateFleetPageState();
}

class _CreateFleetPageState extends State<CreateFleetPage> {
  bool _isLoading = false;
  // --- State for company dropdown ---
  List<Map<String, dynamic>> _companies = [];
  String? _selectedCompanyId;
  String? _selectedCompanyName;

  // --- Fleet name field ---
  final TextEditingController _fleetNameController = TextEditingController();

  // --- Vehicles list state ---
  List<DocumentSnapshot> _allVehicles = [];
  List<DocumentSnapshot> _filteredVehicles = [];
  final Set<String> _selectedVehicleIds = {};

  // --- Search / Sort / Filter state ---
  String _searchQuery = '';
  bool _sortAscending = true;
  List<String> _selectedStatuses = [];

  // Hard-coded status options for filter dialog
  final List<String> _statusOptions = ['Live', 'Sold', 'Draft', 'pending'];

  // Fleet type: 'truck' or 'trailer'
  String _fleetType = 'truck';

  @override
  void initState() {
    super.initState();
    _loadCompaniesAndVehicles();
  }

  /// Fetch all companies from Firestore, then fetch all vehicles.
  Future<void> _loadCompaniesAndVehicles() async {
    setState(() => _isLoading = true);

    try {
      // 1) Load companies
      final companiesSnapshot =
          await FirebaseFirestore.instance.collection('companies').get();
      _companies = companiesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'displayName': data['displayName'] as String? ?? 'Unnamed',
        };
      }).toList();

      // 2) Load all vehicles
      final vehiclesSnapshot =
          await FirebaseFirestore.instance.collection('vehicles').get();
      _allVehicles = vehiclesSnapshot.docs;

      // 3) Apply initial search/sort/filter
      _applySearchSortFilter();
    } catch (e) {
      // If needed, show a SnackBar or handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Filters _allVehicles by search query and selected statuses, then sorts.
  void _applySearchSortFilter() {
    final queryLower = _searchQuery.toLowerCase();

    _filteredVehicles = _allVehicles.where((doc) {
      final data = doc.data()! as Map<String, dynamic>;
      final type = (data['vehicleType'] as String?)?.toLowerCase() ?? '';
      // Filter by fleet type first
      if (type != _fleetType) return false;
      final status = (data['vehicleStatus'] as String?) ?? '';
      // Only show vehicles with status 'draft' or 'live'
      if (status.toLowerCase() != 'draft' && status.toLowerCase() != 'live') {
        return false;
      }
      final makeModel = ((data['makeModel'] as String?) ?? '').toLowerCase();
      final reference =
          ((data['referenceNumber'] as String?) ?? '').toLowerCase();

      // 1) Status filter
      if (_selectedStatuses.isNotEmpty && !_selectedStatuses.contains(status)) {
        return false;
      }

      // 2) Search by makeModel or reference
      if (queryLower.isNotEmpty) {
        if (!makeModel.contains(queryLower) &&
            !reference.contains(queryLower)) {
          return false;
        }
      }

      return true;
    }).toList();

    // 3) Sort by makeModel field (ascending or descending)
    _filteredVehicles.sort((a, b) {
      final aData = a.data()! as Map<String, dynamic>;
      final bData = b.data()! as Map<String, dynamic>;
      final aMake = (aData['makeModel'] as String?) ?? '';
      final bMake = (bData['makeModel'] as String?) ?? '';
      return _sortAscending
          ? aMake.toLowerCase().compareTo(bMake.toLowerCase())
          : bMake.toLowerCase().compareTo(aMake.toLowerCase());
    });

    setState(() {});
  }

  /// Shows a dialog to pick statuses for filtering.
  Future<void> _showFilterDialog() async {
    final tempSelected = List<String>.from(_selectedStatuses);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Filter by Status',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _statusOptions.map((status) {
                return CheckboxListTile(
                  title: Text(
                    status,
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                  value: tempSelected.contains(status),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        tempSelected.add(status);
                      } else {
                        tempSelected.remove(status);
                      }
                    });
                  },
                  activeColor: const Color(0xFFFF4E00),
                  checkColor: Colors.black,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
            ),
          ),
          actions: [
            // Clear button
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedStatuses.clear();
                });
                _applySearchSortFilter();
              },
              child: Text('Clear',
                  style: GoogleFonts.montserrat(color: Colors.white)),
            ),
            // Apply button
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _selectedStatuses = tempSelected;
                });
                _applySearchSortFilter();
              },
              child: Text('Apply',
                  style:
                      GoogleFonts.montserrat(color: const Color(0xFFFF4E00))),
            ),
          ],
        );
      },
    );
  }

  /// Writes a new fleet document with the selected vehicles.
  Future<void> _createFleet() async {
    final fleetName = _fleetNameController.text.trim();
    if (_selectedCompanyId == null ||
        fleetName.isEmpty ||
        _selectedVehicleIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please select a company, enter a name, and pick vehicles.'),
        ),
      );
      return;
    }

    try {
      final fleetRef = FirebaseFirestore.instance.collection('fleets').doc();
      await fleetRef.set({
        'companyId': _selectedCompanyId,
        'companyName': _selectedCompanyName,
        'fleetName': fleetName,
        'vehicleIds': _selectedVehicleIds.toList(),
        'fleetStatus': 'draft',
        'createdAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fleet created successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating fleet: $e')),
      );
    }
  }

  String _getTrailerTypeString(dynamic trailerType) {
    if (trailerType == null) return 'N/A';
    if (trailerType is String) return trailerType;
    if (trailerType is Map<String, dynamic>) {
      return trailerType['name']?.toString() ?? 'N/A';
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    // If still loading, show a spinner
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: const Color(0xFF0E4CAF),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text('Create Fleet',
              style: GoogleFonts.montserrat(color: Colors.white)),
        ),
        body: GradientBackground(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Fleet type tabs
                DefaultTabController(
                  length: 2,
                  initialIndex: _fleetType == 'truck' ? 0 : 1,
                  child: Container(
                    color: const Color(0xFF0E4CAF),
                    child: TabBar(
                      labelColor: const Color(0xFFFF4E00),
                      unselectedLabelColor: Colors.white,
                      indicatorColor: const Color(0xFFFF4E00),
                      onTap: (index) {
                        setState(() {
                          _fleetType = index == 0 ? 'truck' : 'trailer';
                          _applySearchSortFilter();
                        });
                      },
                      tabs: const [
                        Tab(text: 'Trucks'),
                        Tab(text: 'Trailers'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // --- Company dropdown ---
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select Company',
                    labelStyle: GoogleFonts.montserrat(color: Colors.white),
                    filled: true,
                    fillColor: Colors.grey[800],
                  ),
                  dropdownColor: Colors.grey[900],
                  initialValue: _selectedCompanyId,
                  items: _companies.map((company) {
                    return DropdownMenuItem<String>(
                      value: company['id'] as String,
                      child: Text(
                        company['displayName'] as String,
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      final selected =
                          _companies.firstWhere((c) => c['id'] == value);
                      setState(() {
                        _selectedCompanyId = value;
                        _selectedCompanyName =
                            selected['displayName'] as String;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),

                // --- Fleet name input ---
                TextField(
                  controller: _fleetNameController,
                  style: GoogleFonts.montserrat(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Fleet Name',
                    labelStyle: GoogleFonts.montserrat(color: Colors.white),
                    filled: true,
                    fillColor: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),

                // --- Search / Sort / Filter row ---
                Row(
                  children: [
                    // Search box
                    Expanded(
                      child: TextField(
                        style: GoogleFonts.montserrat(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search vehicles...',
                          hintStyle:
                              GoogleFonts.montserrat(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.grey[800],
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white54),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          _searchQuery = value;
                          _applySearchSortFilter();
                        },
                      ),
                    ),
                    // Sort toggle
                    IconButton(
                      icon: Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _sortAscending = !_sortAscending;
                        });
                        _applySearchSortFilter();
                      },
                      tooltip: 'Toggle Sort',
                    ),
                    // Filter button
                    IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: _showFilterDialog,
                      tooltip: 'Filter Vehicles',
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // --- Vehicle list with details ---
                Expanded(
                  child: _filteredVehicles.isEmpty
                      ? Center(
                          child: Text(
                            'No vehicles found.',
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredVehicles.length,
                          itemBuilder: (context, index) {
                            final doc = _filteredVehicles[index];
                            final vehicleData =
                                doc.data()! as Map<String, dynamic>;
                            final vehicleId = doc.id;
                            final vehicleType =
                                (vehicleData['vehicleType'] as String?) ?? '';
                            final variant =
                                (vehicleData['makeModel'] as String?) ?? '';
                            final referenceNumber =
                                (vehicleData['referenceNumber'] as String?) ??
                                    '';
                            final year =
                                (vehicleData['year'] as dynamic)?.toString() ??
                                    'N/A';
                            final vehicleStatus =
                                (vehicleData['vehicleStatus'] as String?) ?? '';
                            return Card(
                              color: Colors.grey[900],
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              child: ListTile(
                                leading: SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: (vehicleData['mainImageUrl'] !=
                                                null &&
                                            vehicleData['mainImageUrl']
                                                .toString()
                                                .isNotEmpty)
                                        ? Image.network(
                                            vehicleData['mainImageUrl'],
                                            fit: BoxFit.cover,
                                            width: 50,
                                            height: 50,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.directions_car,
                                                color: Colors.blueAccent,
                                              );
                                            },
                                          )
                                        : const Icon(
                                            Icons.directions_car,
                                            color: Colors.blueAccent,
                                            size: 50,
                                          ),
                                  ),
                                ),
                                title: Builder(
                                  builder: (context) {
                                    if (vehicleType.toLowerCase() ==
                                        'trailer') {
                                      final trailerType =
                                          vehicleData['trailerType']
                                                  ?.toString() ??
                                              '';
                                      final trailerExtraInfo =
                                          vehicleData['trailerExtraInfo']
                                                  as Map<String, dynamic>? ??
                                              {};
                                      if (trailerType.toLowerCase() ==
                                          'superlink') {
                                        Map<String, dynamic>? trailerA;
                                        if (trailerExtraInfo['trailerA']
                                            is Map<String, dynamic>) {
                                          trailerA =
                                              trailerExtraInfo['trailerA']
                                                  as Map<String, dynamic>?;
                                        } else if (trailerExtraInfo['trailerA']
                                            is Map) {
                                          trailerA = Map<String, dynamic>.from(
                                              trailerExtraInfo['trailerA']
                                                  as Map);
                                        } else {
                                          trailerA = null;
                                        }
                                        final makeA = trailerA?['make'] ??
                                            vehicleData['makeModel'] ??
                                            '';
                                        final modelA = trailerA?['model'] ?? '';
                                        final yearA = trailerA?['year'] ??
                                            vehicleData['year'] ??
                                            '';
                                        if ((makeA.toString() +
                                                modelA.toString() +
                                                yearA.toString())
                                            .trim()
                                            .isEmpty) {
                                          return Text(
                                            'Superlink - Trailer A: (no info)',
                                            style: GoogleFonts.montserrat(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          );
                                        }
                                        return Text(
                                          'Superlink - Trailer A: $makeA $modelA $yearA',
                                          style: GoogleFonts.montserrat(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        );
                                      } else if (trailerType == 'Tri-Axle' ||
                                          trailerType == 'Double Axle' ||
                                          trailerType == 'Other') {
                                        final make = trailerExtraInfo['make'] ??
                                            vehicleData['makeModel'] ??
                                            '';
                                        final model =
                                            trailerExtraInfo['model'] ?? '';
                                        final yearVal =
                                            trailerExtraInfo['year'] ??
                                                vehicleData['year'] ??
                                                '';
                                        return Text(
                                          '$make $model $yearVal',
                                          style: GoogleFonts.montserrat(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        );
                                      }
                                      return Text(
                                        '$variant${variant.isNotEmpty ? ' ' : ''}$year'
                                            .trim(),
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      );
                                    } else {
                                      return Text(
                                        variant,
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                subtitle: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Ref: $referenceNumber\n',
                                        style: GoogleFonts.montserrat(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFFF4E00),
                                          fontSize: 16,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            'Year: $year\nStatus: $vehicleStatus\n${vehicleType.toLowerCase() == 'trailer' ? 'Trailer Type' : 'Transmission'}: ${vehicleType.toLowerCase() == 'trailer' ? _getTrailerTypeString(vehicleData['trailerType']) : vehicleData['transmissionType']?.toString() ?? 'N/A'}',
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                isThreeLine: true,
                                trailing: Checkbox(
                                  value:
                                      _selectedVehicleIds.contains(vehicleId),
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        _selectedVehicleIds.add(vehicleId);
                                      } else {
                                        _selectedVehicleIds.remove(vehicleId);
                                      }
                                    });
                                  },
                                  activeColor: const Color(0xFFFF4E00),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VehicleDetailsPage(
                                          vehicle: Vehicle.fromFirestore(
                                              vehicleId, vehicleData)),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),

                // --- Create Fleet button ---
                if (_selectedVehicleIds.length >= 3)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E4CAF),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14.0, horizontal: 24.0),
                    ),
                    onPressed: _createFleet,
                    child: Text(
                      'Create Fleet (${_selectedVehicleIds.length} selected)',
                      style: GoogleFonts.montserrat(
                          color: Colors.white, fontSize: 16),
                    ),
                  ),
              ],
            ),
          ),
        ));
  }

  @override
  void dispose() {
    _fleetNameController.dispose();
    super.dispose();
  }
}
