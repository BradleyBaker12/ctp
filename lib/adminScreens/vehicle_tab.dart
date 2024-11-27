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

  // Method to update vehicle status
  Future<bool> updateVehicleStatus(String vehicleId, String newStatus) async {
    try {
      await vehiclesCollection.doc(vehicleId).update({'status': newStatus});
      print('Vehicle $vehicleId status updated to $newStatus');
      return true;
    } catch (e) {
      print('Error updating vehicle status: $e');
      return false;
    }
  }

  // Method to delete vehicle
  Future<bool> deleteVehicle(String vehicleId) async {
    try {
      await vehiclesCollection.doc(vehicleId).delete();
      print('Vehicle $vehicleId deleted');
      return true;
    } catch (e) {
      print('Error deleting vehicle: $e');
      return false;
    }
  }

  // Helper method to filter vehicles based on search query
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

  // Helper method to create default AdminData
  AdminData _getDefaultAdminData() {
    return AdminData(
      settlementAmount: '0',
      natisRc1Url: '',
      licenseDiskUrl: '',
      settlementLetterUrl: '',
    );
  }

  // Helper method to create default Maintenance
  Maintenance _getDefaultMaintenance(String vehicleId) {
    return Maintenance(
        vehicleId: '',
        oemInspectionType: '',
        maintenanceDocUrl: '',
        warrantyDocUrl: '',
        maintenanceSelection: '',
        warrantySelection: '',
        lastUpdated: DateTime.now());
  }

  // Helper method to create default TruckConditions
  TruckConditions _getDefaultTruckConditions() {
    return TruckConditions(
      externalCab: ExternalCab(
        damages: [],
        additionalFeatures: [],
        condition: '',
        damagesCondition: '',
        additionalFeaturesCondition: '',
        images: {},
      ),
      internalCab: InternalCab(
          condition: '',
          damagesCondition: '',
          additionalFeaturesCondition: '',
          faultCodesCondition: '',
          viewImages: {},
          damages: [],
          additionalFeatures: [],
          faultCodes: []),
      chassis: Chassis(
          condition: '',
          damagesCondition: '',
          additionalFeaturesCondition: '',
          images: {},
          damages: [],
          additionalFeatures: []),
      driveTrain: DriveTrain(
        condition: '',
        oilLeakConditionEngine: '',
        waterLeakConditionEngine: '',
        blowbyCondition: '',
        oilLeakConditionGearbox: '',
        retarderCondition: '',
        lastUpdated: DateTime.now(),
        images: {
          'Right Brake': '',
          'Left Brake': '',
          'Front Axel': '',
          'Suspension': '',
          'Fuel Tank': '',
          'Battery': '',
          'Cat Walk': '',
          'Electrical Cable Black': '',
          'Air Cable Yellow': '',
          'Air Cable Red': '',
          'Tail Board': '',
          '5th Wheel': '',
          'Left Brake Rear Axel': '',
          'Right Brake Rear Axel': '',
        },
        damages: [],
        additionalFeatures: [],
        faultCodes: [],
      ),
      tyres: {
        'default': Tyres(
          lastUpdated: DateTime.now(),
          positions: {},
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Apply filtering based on search query
    List<DocumentSnapshot> filteredVehicles = _vehicles.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return _matchesSearch(data);
    }).toList();

    return Column(
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
                // Reset pagination and fetch again
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
                      // Show a loading indicator at the bottom
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    var vehicleData =
                        filteredVehicles[index].data() as Map<String, dynamic>;
                    String vehicleId = filteredVehicles[index].id;
                    String make = vehicleData['makeModel'] ?? 'Unknown';

                    // Corrected constructor call with both docId and data
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
                                    errorBuilder: (context, error, stackTrace) {
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
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        subtitle: Text(
                          'Year: ${vehicle.year}\nStatus: ${vehicle.vehicleStatus}',
                          style: GoogleFonts.montserrat(color: Colors.white70),
                        ),
                        isThreeLine: true,
                        onTap: () {
                          // Navigate to VehicleDetailsPageAdmin with full vehicle details
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
    );
  }
}
