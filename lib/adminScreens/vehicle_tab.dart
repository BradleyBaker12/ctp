// lib/adminScreens/vehicle_tab.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/models/admin_data.dart';
import 'package:ctp/models/maintenance.dart';
import 'package:ctp/models/truck_conditions.dart';
import 'package:ctp/models/external_cab.dart';
import 'package:ctp/models/internal_cab.dart';
import 'package:ctp/models/chassis.dart';
import 'package:ctp/models/drive_train.dart';
import 'package:ctp/models/tyres.dart';
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

    String makeModel = vehicleData['makeModel']?.toString().toLowerCase() ?? '';
    String yearStr = vehicleData['year']?.toString().toLowerCase() ?? '';
    String status = vehicleData['status']?.toString().toLowerCase() ?? '';

    return makeModel.contains(_searchQuery.toLowerCase()) ||
        yearStr.contains(_searchQuery.toLowerCase()) ||
        status.contains(_searchQuery.toLowerCase());
  }

  Future<void> _fetchVehicles() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    Query query = vehiclesCollection.orderBy('createdAt').limit(_limit);

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
    List<DocumentSnapshot> filteredVehicles = _vehicles.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return _matchesSearch(data);
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.montserrat(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Search Vehicles',
                labelStyle: GoogleFonts.montserrat(color: Colors.white),
                prefixIcon: Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.transparent,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.white),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Color(0xFFFF4E00)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _vehicles.clear();
                  _lastDocument = null;
                  _hasMore = true;
                });
                _fetchVehicles();
              },
            ),
          ),
          // Expanded ListView
          Expanded(
            child: filteredVehicles.isEmpty
                ? _isLoading
                    ? Center(child: CircularProgressIndicator())
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
                      if (index == filteredVehicles.length) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      var vehicleData = filteredVehicles[index].data()
                          as Map<String, dynamic>;
                      String vehicleId = filteredVehicles[index].id;
                      String make = vehicleData['makeModel'] ?? 'Unknown';

                      Vehicle vehicle =
                          Vehicle.fromFirestore(vehicleId, vehicleData);

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
                              child: (vehicle.mainImageUrl?.isNotEmpty ?? false)
                                  ? Image.network(
                                      vehicle.mainImageUrl!,
                                      fit: BoxFit.cover,
                                      width: 50,
                                      height: 50,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Icon(Icons.directions_car,
                                            color: Colors.blueAccent);
                                      },
                                    )
                                  : Icon(Icons.directions_car,
                                      color: Colors.blueAccent, size: 50),
                            ),
                          ),
                          title: Text(
                            make,
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          subtitle: Text(
                            'Year: ${vehicle.year}\nStatus: ${vehicle.vehicleStatus}',
                            style:
                                GoogleFonts.montserrat(color: Colors.white70),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTransporterSelectionDialog(context),
        label: Text(
          'Add Vehicle',
          style: GoogleFonts.montserrat(color: Colors.white),
        ),
        icon: Icon(Icons.add, color: Colors.white),
        backgroundColor: Color(0xFF0E4CAF),
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
              .where('role', isEqualTo: 'transporter')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator(color: Color(0xFFFF4E00));
            }

            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var transporter = snapshot.data!.docs[index];
                  return ListTile(
                    title: Text(
                      transporter['companyName'] ??
                          transporter['email'] ??
                          'Unknown',
                      style: GoogleFonts.montserrat(color: Colors.white),
                    ),
                    subtitle: Text(
                      transporter['email'] ?? '',
                      style: GoogleFonts.montserrat(color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VehicleUploadScreen(
                            isNewUpload: true,
                            transporterId: transporter.id,
                            isAdminUpload: true,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
