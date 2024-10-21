import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

                    // Construct the Vehicle object with all fields, adding default values for null
                    Vehicle vehicle = Vehicle(
                      id: vehicleId,
                      accidentFree: vehicleData['accidentFree'] ?? 'N/A',
                      application: vehicleData['application'] ?? 'N/A',
                      bookValue: vehicleData['bookValue'] ?? 'N/A',
                      damageDescription: vehicleData['damageDescription'] ?? '',
                      damagePhotos: vehicleData['damagePhotos'] != null
                          ? List<String?>.from(
                              vehicleData['damagePhotos'] ?? [])
                          : [],
                      dashboardPhoto: vehicleData['dashboardPhoto'] ?? '',
                      engineNumber: vehicleData['engineNumber'] ?? 'N/A',
                      expectedSellingPrice:
                          vehicleData['expectedSellingPrice'] ?? 'N/A',
                      faultCodesPhoto: vehicleData['faultCodesPhoto'] ?? '',
                      firstOwner: vehicleData['firstOwner'] ?? 'N/A',
                      hydraulics: vehicleData['hydraulics'] ?? 'N/A',
                      licenceDiskUrl: vehicleData['licenceDiskUrl'] ?? '',
                      listDamages: vehicleData['listDamages'] ?? 'N/A',
                      maintenance: vehicleData['maintenance'] ?? 'N/A',
                      makeModel: vehicleData['makeModel'] ?? 'N/A',
                      mileage: vehicleData['mileage'] ?? 'N/A',
                      mileageImage: vehicleData['mileageImage'] ?? '',
                      oemInspection: vehicleData['oemInspection'] ?? 'N/A',
                      mainImageUrl: vehicleData['mainImageUrl'] ?? '',
                      photos: List<String?>.from(vehicleData['photos'] ?? []),
                      rc1NatisFile: vehicleData['rc1NatisFile'] ?? '',
                      registrationNumber:
                          vehicleData['registrationNumber'] ?? 'N/A',
                      roadWorthy: vehicleData['roadWorthy'] ?? 'N/A',
                      settleBeforeSelling:
                          vehicleData['settleBeforeSelling'] ?? 'N/A',
                      settlementAmount:
                          vehicleData['settlementAmount'] ?? 'N/A',
                      settlementLetterFile:
                          vehicleData['settlementLetterFile'] ?? '',
                      spareTyre: vehicleData['spareTyre'] ?? 'N/A',
                      suspension: vehicleData['suspension'] ?? 'N/A',
                      transmission: vehicleData['transmission'] ?? 'N/A',
                      config: vehicleData['config'] ?? '',
                      treadLeft: vehicleData['treadLeft'] ?? '',
                      tyrePhoto1: vehicleData['tyrePhoto1'] ?? '',
                      tyrePhoto2: vehicleData['tyrePhoto2'] ?? '',
                      tyreType: vehicleData['tyreType'] ?? 'N/A',
                      userId: vehicleData['userId'] ?? 'N/A',
                      vehicleType: vehicleData['vehicleType'] ?? 'N/A',
                      vinNumber: vehicleData['vinNumber'] ?? 'N/A',
                      warranty: vehicleData['warranty'] ?? 'N/A',
                      warrantyType: vehicleData['warrantyType'] ?? 'N/A',
                      weightClass: vehicleData['weightClass'] ?? 'N/A',
                      year: vehicleData['year'] ?? 'N/A',
                      createdAt: vehicleData['createdAt'] != null
                          ? (vehicleData['createdAt'] as Timestamp).toDate()
                          : DateTime.now(),
                      vehicleStatus: vehicleData['vehicleStatus'] ?? 'Live',
                      vehicleAvailableImmediately:
                          vehicleData['vehicleAvailableImmediately'] ?? '',
                      availableDate: vehicleData['availableDate'] ?? '',
                    );

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
