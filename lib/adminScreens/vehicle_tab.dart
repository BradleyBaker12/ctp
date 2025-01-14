// lib/adminScreens/vehicle_tab.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/truckForms/vehilce_upload_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ctp/pages/vehicle_details_page.dart';

class VehiclesTab extends StatefulWidget {
  const VehiclesTab({super.key});

  @override
  _VehiclesTabState createState() => _VehiclesTabState();
}

class _VehiclesTabState extends State<VehiclesTab> {
  final CollectionReference vehiclesCollection =
      FirebaseFirestore.instance.collection('vehicles');

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Pagination variables
  final int _limit = 10; // Number of documents to fetch per page
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  final List<DocumentSnapshot> _vehicles = [];

  final ScrollController _scrollController = ScrollController();

  String _sortField = 'createdAt';
  bool _sortAscending = false;
  final List<String> _selectedFilters = [];
  final List<String> _filterOptions = ['All', 'Live', 'Sold', 'Draft'];

  final List<Map<String, String>> _sortOptions = [
    {'field': 'createdAt', 'label': 'Date'},
    {'field': 'year', 'label': 'Year'},
    {'field': 'vehicleStatus', 'label': 'Status'},
    {'field': 'makeModel', 'label': 'Model'}
  ];

  @override
  void initState() {
    super.initState();
    _fetchVehicles();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchVehicles();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> updateVehicleStatus(String vehicleId, String newStatus) async {
    try {
      await vehiclesCollection.doc(vehicleId).update({'status': newStatus});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteVehicle(String vehicleId) async {
    try {
      await vehiclesCollection.doc(vehicleId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  bool _matchesSearch(Map<String, dynamic> vehicleData) {
    if (_searchQuery.isEmpty) return true;

    // Lowercase search
    String query = _searchQuery.toLowerCase();

    // We can search across brand(s), makeModel, variant, year, status, etc.
    // Because `brands` is a List<String>, we join them into one string to match.
    List<dynamic> brandList = vehicleData['brands'] ?? [];
    String brandConcat = brandList.join(' ').toLowerCase();

    String makeModel = (vehicleData['makeModel'] ?? '').toLowerCase();
    String variant = (vehicleData['variant'] ?? '').toLowerCase();
    String yearStr = (vehicleData['year'] ?? '').toLowerCase();
    String statusStr = (vehicleData['vehicleStatus'] ?? '').toLowerCase();

    return brandConcat.contains(query) ||
        makeModel.contains(query) ||
        variant.contains(query) ||
        yearStr.contains(query) ||
        statusStr.contains(query);
  }

  Future<void> _fetchVehicles() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    Query query =
        vehiclesCollection.orderBy(_sortField, descending: !_sortAscending);

    // Apply filters
    if (_selectedFilters.isNotEmpty && !_selectedFilters.contains('All')) {
      query = query.where('vehicleStatus', whereIn: _selectedFilters);
    }

    query = query.limit(_limit);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    try {
      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        _vehicles.addAll(querySnapshot.docs);
        if (querySnapshot.docs.length < _limit) {
          _hasMore = false;
        }
      } else {
        _hasMore = false;
      }
    } catch (e) {
      print('Error fetching vehicles: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter the local _vehicles list based on search
    List<DocumentSnapshot> filteredVehicles = _vehicles.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return _matchesSearch(data);
    }).toList();

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            // SEARCH BAR
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // Search Bar
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.montserrat(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search vehicles...',
                          hintStyle:
                              GoogleFonts.montserrat(color: Colors.white54),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white54),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                            _vehicles.clear();
                            _lastDocument = null;
                            _hasMore = true;
                          });
                          _fetchVehicles();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Sort Button
                  IconButton(
                    icon: const Icon(Icons.sort, color: Colors.white),
                    onPressed: () => _showSortMenu(),
                    tooltip: 'Sort by: ${_sortField.replaceAll('_', ' ')}',
                  ),
                  // Sort Direction Button
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
                        _vehicles.clear();
                        _lastDocument = null;
                        _hasMore = true;
                        _fetchVehicles();
                      });
                    },
                    tooltip:
                        _sortAscending ? 'Sort Ascending' : 'Sort Descending',
                  ),
                  // Filter Button
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onPressed: _showFilterDialog,
                    tooltip: 'Filter Vehicles',
                  ),
                ],
              ),
            ),

            // VEHICLE LIST
            Expanded(
              child: filteredVehicles.isEmpty
                  ? _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Center(
                          child: Text(
                            'No vehicles found.',
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                        )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredVehicles.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Show a loading indicator at the bottom if there are more
                        if (index == filteredVehicles.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        // Build the Vehicle object
                        var vehicleData = filteredVehicles[index].data()
                            as Map<String, dynamic>;
                        String vehicleId = filteredVehicles[index].id;
                        Vehicle vehicle =
                            Vehicle.fromFirestore(vehicleId, vehicleData);

                        // Safely get the brand from the list of brands
                        String brand = vehicle.brands.isNotEmpty
                            ? vehicle.brands[0]
                            : 'Unknown Brand';

                        // We'll treat `vehicle.makeModel` as the "make".
                        // For variant, fallback to "Unknown Variant" if null or empty
                        String variant = (vehicle.variant == null ||
                                vehicle.variant!.isEmpty)
                            ? ''
                            : vehicle.variant!;

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
                                child:
                                    (vehicle.mainImageUrl?.isNotEmpty ?? false)
                                        ? Image.network(
                                            vehicle.mainImageUrl!,
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
                                        : const Icon(Icons.directions_car,
                                            color: Colors.blueAccent, size: 50),
                              ),
                            ),
                            // Display brand, make, variant:
                            title: Text(
                              '$brand ${vehicle.makeModel} $variant',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            // Keep year/status in the subtitle if you like
                            subtitle: Text(
                              'Year: ${vehicle.year}\nStatus: ${vehicle.vehicleStatus}',
                              style: GoogleFonts.montserrat(
                                color: Colors.white70,
                              ),
                            ),
                            isThreeLine: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VehicleDetailsPage(
                                    vehicle: vehicle,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTransporterSelectionDialog(context),
        label: Text(
          'Add Vehicle',
          style: GoogleFonts.montserrat(color: Colors.white),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF0E4CAF),
      ),
    );
  }

  void _showTransporterSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Select Transporter',
            style: GoogleFonts.montserrat(color: Colors.white)),
        content: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('userRole', isEqualTo: 'transporter')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator(color: Color(0xFFFF4E00));
            }

            return SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.4,
              child: DropdownButtonFormField<String>(
                dropdownColor: Colors.grey[900],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                hint: Text('Select a transporter',
                    style: GoogleFonts.montserrat(color: Colors.white)),
                items: snapshot.data!.docs.map((transporter) {
                  var userData = transporter.data() as Map<String, dynamic>;
                  String displayName = userData['tradingName'] ??
                      userData['name'] ??
                      userData['email'] ??
                      'Unknown';

                  return DropdownMenuItem<String>(
                    value: transporter.id,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.5,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayName,
                            style: GoogleFonts.montserrat(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            maxLines: 1,
                          ),
                          Text(
                            userData['email'] ?? '',
                            style: GoogleFonts.montserrat(
                                color: Colors.grey, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (transporterId) {
                  if (transporterId != null) {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VehicleUploadScreen(
                          isNewUpload: true,
                          transporterId: transporterId,
                          isAdminUpload: true,
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSortMenu() async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    await showMenu(
      context: context,
      position: position,
      color: Colors.grey[900],
      items: _sortOptions.map((option) {
        return PopupMenuItem<String>(
          value: option['field'],
          child: Row(
            children: [
              Text(
                option['label']!,
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
              if (_sortField == option['field']) const SizedBox(width: 8),
              if (_sortField == option['field'])
                const Icon(Icons.check, size: 18, color: Colors.white),
            ],
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        setState(() {
          _sortField = value;
          _vehicles.clear();
          _lastDocument = null;
          _hasMore = true;
          _fetchVehicles();
        });
      }
    });
  }

  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Filter Vehicles',
              style: GoogleFonts.montserrat(color: Colors.white)),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _filterOptions.map((filter) {
                    return CheckboxListTile(
                      title: Text(filter,
                          style: GoogleFonts.montserrat(color: Colors.white)),
                      value: _selectedFilters.contains(filter),
                      checkColor: Colors.black,
                      activeColor: const Color(0xFFFF4E00),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedFilters.add(filter);
                          } else {
                            _selectedFilters.remove(filter);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: Text('Clear All',
                  style: GoogleFonts.montserrat(color: Colors.white)),
              onPressed: () {
                setState(() {
                  _selectedFilters.clear();
                  _vehicles.clear();
                  _lastDocument = null;
                  _hasMore = true;
                  _fetchVehicles();
                });
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('Apply',
                  style:
                      GoogleFonts.montserrat(color: const Color(0xFFFF4E00))),
              onPressed: () {
                setState(() {
                  _vehicles.clear();
                  _lastDocument = null;
                  _hasMore = true;
                  _fetchVehicles();
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
