// lib/adminScreens/fleet_detail_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/admin_web_navigation_bar.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:provider/provider.dart';

@RoutePage()
class FleetDetailPage extends StatefulWidget {
  final String fleetId;
  const FleetDetailPage({super.key, required this.fleetId});

  @override
  State<FleetDetailPage> createState() => _FleetDetailPageState();
}

class _FleetDetailPageState extends State<FleetDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  String? _selectedCompanyId;
  List<QueryDocumentSnapshot> _companies = [];
  Timestamp? _createdAt;
  String _fleetStatus = 'draft';
  bool _isLoading = true;
  List<String> _fleetVehicleIds = [];
  List<QueryDocumentSnapshot> _allVehicles = [];
  List<QueryDocumentSnapshot> _fleetVehicles = [];

  final ScrollController _scrollController = ScrollController();
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  static const int _pageSize = 10;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadFleetAndVehicles();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.8 &&
          !_isLoadingMore) {
        _loadMoreVehicles();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadFleetAndVehicles() async {
    // Fetch fleet document
    final doc = await _firestore.collection('fleets').doc(widget.fleetId).get();
    final data = doc.data() ?? {};
    _nameController.text = data['fleetName'] ?? '';
    _createdAt = data['createdAt'] as Timestamp?;
    _fleetStatus = data['fleetStatus'] ?? 'draft';

    // Fetch companies for dropdown
    final companiesSnapshot = await _firestore.collection('companies').get();
    _companies = companiesSnapshot.docs;
    // Set the dropdown to the fleet's current companyId
    _selectedCompanyId = data['companyId'] as String?;

    // Fetch first page of vehicles that are live or draft (lowercase and capitalized)
    final initialSnapshot = await _firestore
        .collection('vehicles')
        .where('vehicleStatus', whereIn: ['live', 'draft', 'Live', 'Draft'])
        .limit(_pageSize)
        .get();
    _allVehicles = initialSnapshot.docs;
    if (_allVehicles.isNotEmpty) {
      _lastDocument = _allVehicles.last;
    }
    _hasMore = initialSnapshot.docs.length == _pageSize;

    // Load vehicle IDs in this fleet
    _fleetVehicleIds = List<String>.from(data['vehicleIds'] ?? []);
    // Debug: print fetched vehicle IDs for the fleet
    print('DEBUG: Fleet vehicle IDs: $_fleetVehicleIds');

    // Fetch the documents for the vehicles already in this fleet
    if (_fleetVehicleIds.isNotEmpty) {
      // Firestore 'in' queries can only handle up to 10 items at once
      final batches = <List<String>>[];
      for (var i = 0; i < _fleetVehicleIds.length; i += 10) {
        batches.add(_fleetVehicleIds.sublist(
            i,
            i + 10 > _fleetVehicleIds.length
                ? _fleetVehicleIds.length
                : i + 10));
      }
      _fleetVehicles = [];
      for (var batch in batches) {
        final batchSnapshot = await _firestore
            .collection('vehicles')
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        _fleetVehicles.addAll(batchSnapshot.docs);
      }
    }
    // Debug: print number of fetched vehicle docs
    print('DEBUG: _fleetVehicles length after fetch: ${_fleetVehicles.length}');

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveChanges() async {
    final updatedName = _nameController.text.trim();
    await _firestore.collection('fleets').doc(widget.fleetId).update({
      'companyId': _selectedCompanyId,
      'fleetName': updatedName,
      'fleetStatus': _fleetStatus,
      'vehicleIds': _fleetVehicleIds,
    });
    Navigator.of(context).pop();
  }

  void _onVehicleCheckboxChanged(bool? isChecked, String vehicleId) {
    setState(() {
      if (isChecked == true) {
        if (!_fleetVehicleIds.contains(vehicleId)) {
          _fleetVehicleIds.add(vehicleId);
          // Also add to _fleetVehicles list for real-time update
          final matches = _allVehicles.where((v) => v.id == vehicleId);
          if (matches.isNotEmpty &&
              !_fleetVehicles.any((d) => d.id == vehicleId)) {
            _fleetVehicles.add(matches.first);
          }
        }
      } else {
        _fleetVehicleIds.remove(vehicleId);
        // Also remove from _fleetVehicles list
        _fleetVehicles.removeWhere((d) => d.id == vehicleId);
      }
    });
  }

  Future<void> _loadMoreVehicles() async {
    if (!_hasMore || _isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    final nextSnapshot = await _firestore
        .collection('vehicles')
        .where('vehicleStatus', whereIn: ['live', 'draft', 'Live', 'Draft'])
        .startAfterDocument(_lastDocument!)
        .limit(_pageSize)
        .get();
    final newDocs = nextSnapshot.docs;
    if (newDocs.isNotEmpty) {
      _lastDocument = newDocs.last;
      _allVehicles.addAll(newDocs);
    }
    _hasMore = newDocs.length == _pageSize;
    setState(() {
      _isLoadingMore = false;
    });
  }

  void _openEditVehicles() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          backgroundColor: Colors.grey[900],
          child: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Edit Vehicles',
                    style: GoogleFonts.montserrat(
                        color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _allVehicles.length + (_hasMore ? 1 : 0),
                      controller: _scrollController,
                      itemBuilder: (context, index) {
                        if (index == _allVehicles.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final vehicleDoc = _allVehicles[index];
                        final vehicleId = vehicleDoc.id;
                        final vehicleData =
                            vehicleDoc.data() as Map<String, dynamic>;
                        // Extract brand, makeModel, variant, and year
                        final brandList =
                            (vehicleData['brands'] as List<dynamic>?)
                                    ?.map((e) => e.toString())
                                    .toList() ??
                                [];
                        final brand =
                            brandList.isNotEmpty ? brandList.first : '';
                        final makeModel =
                            vehicleData['makeModel']?.toString() ?? '';
                        final variant =
                            vehicleData['variant']?.toString() ?? '';
                        final year = vehicleData['year']?.toString() ?? '';
                        final mainImageUrl =
                            (vehicleData['mainImageUrl'] as String?) ?? '';
                        final isInFleet = _fleetVehicleIds.contains(vehicleId);
                        return Card(
                          color: Colors.grey[800],
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CheckboxListTile(
                            tileColor: Colors.transparent,
                            activeColor: Colors.blue,
                            secondary: mainImageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      mainImageUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : null,
                            title: Text(
                              '$brand - $makeModel${variant.isNotEmpty ? ' ($variant)' : ''} [$year]',
                              style:
                                  GoogleFonts.montserrat(color: Colors.white),
                            ),
                            value: isInFleet,
                            onChanged: (checked) {
                              _onVehicleCheckboxChanged(checked, vehicleId);
                              setStateDialog(() {});
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E4CAF),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Done',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug: print fleetVehicles when building
    print(
        'DEBUG: Building list with _fleetVehicles length: ${_fleetVehicles.length}');
    return GradientBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        drawer: Drawer(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Color(0xFF2F7FFD)],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black, Color(0xFF2F7FFD)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Admin Menu',
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Users'),
                  textColor: Colors.white,
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/adminUsers');
                  },
                ),
                ListTile(
                  title: const Text('Offers'),
                  textColor: Colors.white,
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/adminOffers');
                  },
                ),
                ListTile(
                  title: const Text('Complaints'),
                  textColor: Colors.white,
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/adminComplaints');
                  },
                ),
                ListTile(
                  title: const Text('Vehicles'),
                  textColor: Colors.white,
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/adminVehicles');
                  },
                ),
                ListTile(
                  title: const Text('Fleets'),
                  textColor: Colors.white,
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/adminFleets');
                  },
                ),
                if (Provider.of<UserProvider>(context, listen: false)
                        .getUserEmail ==
                    'bradley@admin.co.za')
                  ListTile(
                    title: const Text('Notification Test'),
                    textColor: Colors.white,
                    onTap: () {
                      Navigator.pushReplacementNamed(
                          context, '/adminNotificationTest');
                    },
                  ),
              ],
            ),
          ),
        ),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: AdminWebNavigationBar(
            scaffoldKey: _scaffoldKey,
            isCompactNavigation: MediaQuery.of(context).size.width < 900,
            currentRoute: 'Fleets',
            onMenuPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            onTabSelected: (index) {
              if (index == 0) {
                Navigator.pushReplacementNamed(context, '/adminUsers');
              } else if (index == 1) {
                Navigator.pushReplacementNamed(context, '/adminOffers');
              } else if (index == 2) {
                Navigator.pushReplacementNamed(context, '/adminComplaints');
              } else if (index == 3) {
                Navigator.pushReplacementNamed(context, '/adminVehicles');
              }
            },
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Company Name (dropdown)
                    DropdownButtonFormField<String>(
                      value: _selectedCompanyId,
                      isExpanded: true,
                      dropdownColor: Colors.grey[900],
                      decoration: InputDecoration(
                        labelText: 'Company Name',
                        labelStyle: GoogleFonts.montserrat(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: GoogleFonts.montserrat(color: Colors.white),
                      items: _companies.map((doc) {
                        final id = doc.id;
                        final name =
                            (doc.data() as Map<String, dynamic>)['displayName']
                                    as String? ??
                                '';
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(
                            name,
                            style: GoogleFonts.montserrat(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCompanyId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Fleet Name (editable)
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Fleet Name',
                        labelStyle: GoogleFonts.montserrat(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: GoogleFonts.montserrat(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    // Fleet Status (dropdown)
                    DropdownButtonFormField<String>(
                      value: _fleetStatus,
                      dropdownColor: Colors.grey[900],
                      decoration: InputDecoration(
                        labelText: 'Fleet Status',
                        labelStyle: GoogleFonts.montserrat(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: GoogleFonts.montserrat(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
                        DropdownMenuItem(value: 'live', child: Text('Live')),
                        DropdownMenuItem(
                            value: 'archived', child: Text('Archived')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _fleetStatus = value ?? 'draft';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Vehicles in fleet (read-only)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _fleetVehicles.length,
                        itemBuilder: (context, idx) {
                          final vehicleDoc = _fleetVehicles[idx];
                          final vehicleId = vehicleDoc.id;
                          final vehicleData =
                              vehicleDoc.data() as Map<String, dynamic>;
                          // Extract brand(s), makeModel, variant, and year
                          final brandList =
                              (vehicleData['brands'] as List<dynamic>?)
                                      ?.map((e) => e.toString())
                                      .toList() ??
                                  [];
                          final brand =
                              brandList.isNotEmpty ? brandList.first : '';
                          final makeModel =
                              vehicleData['makeModel']?.toString() ?? '';
                          final variant =
                              vehicleData['variant']?.toString() ?? '';
                          final year = vehicleData['year']?.toString() ?? '';
                          final mainImageUrl =
                              (vehicleData['mainImageUrl'] as String?) ?? '';
                          return Card(
                            color: Colors.grey[900],
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: mainImageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        mainImageUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : null,
                              title: Text(
                                '$brand - $makeModel${variant.isNotEmpty ? ' ($variant)' : ''} [$year]',
                                style:
                                    GoogleFonts.montserrat(color: Colors.white),
                              ),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _fleetVehicleIds.remove(vehicleId);
                                    _fleetVehicles.removeWhere(
                                        (doc) => doc.id == vehicleId);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Edit Vehicles button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _openEditVehicles,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0E4CAF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Edit Vehicles',
                          style: GoogleFonts.montserrat(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0E4CAF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Save Changes',
                          style: GoogleFonts.montserrat(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
