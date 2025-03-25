import 'dart:math';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_app_bar.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/wish_card.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:ctp/components/web_navigation_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:ctp/utils/navigation.dart';

/// Simple data class for navigation items.
class NavigationItem {
  final String title;
  final String route;

  NavigationItem({
    required this.title,
    required this.route,
  });
}

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  _WishlistPageState createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Lists of wishlist vehicles (as Vehicle objects)
  List<Vehicle> wishlistVehicles = [];
  List<Vehicle> trucks = [];
  List<Vehicle> trailers = [];

  // Tab state: either "Trucks" or "Trailers"
  String _selectedTab = 'Trucks';

  // Getter for current list based on selected tab
  List<Vehicle> get currentList => _selectedTab == 'Trucks' ? trucks : trailers;

  bool _isLoading = true;

  late OfferProvider _offerProvider;
  final ScrollController _scrollController = ScrollController();

  // Consistent breakpoint for compact navigation.
  bool _isCompactNavigation(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1100;

  @override
  void initState() {
    super.initState();
    _offerProvider = Provider.of<OfferProvider>(context, listen: false);
    _fetchWishlist();
  }

  /// Fetch the wishlist vehicles for the current user.
  Future<void> _fetchWishlist() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          List<String> likedVehicleIds =
              List<String>.from(userDoc['likedVehicles'] ?? []);
          if (likedVehicleIds.isNotEmpty) {
            // Firestore's whereIn accepts a maximum of 10 items per query.
            List<List<String>> chunks = [];
            const int chunkSize = 10;
            for (var i = 0; i < likedVehicleIds.length; i += chunkSize) {
              chunks.add(likedVehicleIds
                  .skip(i)
                  .take(chunkSize)
                  .toList(growable: false));
            }

            List<Vehicle> fetchedVehicles = [];
            for (var chunk in chunks) {
              QuerySnapshot snapshot = await FirebaseFirestore.instance
                  .collection('vehicles')
                  .where(FieldPath.documentId, whereIn: chunk)
                  .get();
              for (var doc in snapshot.docs) {
                Vehicle vehicle = Vehicle.fromFirestore(
                    doc.id, doc.data() as Map<String, dynamic>);
                fetchedVehicles.add(vehicle);
                // Optionally add to the VehicleProvider.
                Provider.of<VehicleProvider>(context, listen: false)
                    .addVehicle(vehicle);
              }
            }

            setState(() {
              wishlistVehicles = fetchedVehicles;
              // Separate vehicles into Trucks and Trailers based on vehicleType.
              trucks = wishlistVehicles.where((v) {
                String type = v.vehicleType.toLowerCase();
                return type == 'truck' || type == 'pickup' || type == 'lorry';
              }).toList();
              trailers = wishlistVehicles.where((v) {
                String type = v.vehicleType.toLowerCase();
                return type == 'trailer' || type == 'semi-trailer';
              }).toList();
              // Set displayedVehicles to the current tab's list.
              displayedVehicles = _selectedTab == 'Trucks' ? trucks : trailers;
              _isLoading = false;
            });
          } else {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print("Error fetching wishlist: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Computes the number of columns for the grid view based on screen width.
  int _calculateCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= 1200) {
      return 4;
    } else if (width >= 900) {
      return 3;
    } else if (width >= 600) {
      return 2;
    } else {
      return 1;
    }
  }

  /// Updated cross-axis count for handling the card's aspect ratio.
  int _calculateCrossAxisCountUpdated(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= 1500) {
      return 4;
    } else if (width >= 1100)
      return 3;
    else if (width >= 700)
      return 2;
    else
      return 1;
  }

  /// Builds the WishCard for a given vehicle.
  Widget _buildWishCard(Vehicle vehicle, Size screenSize) {
    bool hasOffer =
        _offerProvider.offers.any((offer) => offer.vehicleId == vehicle.id);
    return WishCard(
      vehicleMakeModel: "${vehicle.makeModel} ${vehicle.year}",
      vehicleImageUrl:
          (vehicle.mainImageUrl != null && vehicle.mainImageUrl!.isNotEmpty)
              ? vehicle.mainImageUrl!
              : 'lib/assets/default_vehicle_image.png',
      size: screenSize,
      customFont: (double fontSize, FontWeight fontWeight, Color color) {
        return TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          fontFamily: 'Montserrat',
        );
      },
      hasOffer: hasOffer,
      onTap: () async {
        await MyNavigator.push(context, VehicleDetailsPage(vehicle: vehicle));
      },
      onDelete: () async {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'likedVehicles': FieldValue.arrayRemove([vehicle.id])
          });
          setState(() {
            wishlistVehicles.remove(vehicle);
            trucks.remove(vehicle);
            trailers.remove(vehicle);
            // Also update displayedVehicles after deletion.
            displayedVehicles = _selectedTab == 'Trucks' ? trucks : trailers;
          });
        }
      },
      vehicleId: vehicle.id,
      vehicle: vehicle,
    );
  }

  // Determine if the screen is considered large.
  bool get _isLargeScreen => MediaQuery.of(context).size.width > 900;

  // --------------------------------------------------------------------
  // Filtering, Sorting, and Pagination Related Code
  // --------------------------------------------------------------------
  List<Vehicle> displayedVehicles = [];
  bool _isLoadingMore = false;
  final int _itemsPerPage = 10;
  int _currentPage = 0;
  bool _hasReachedEnd = false;

  // ***** Filter State Fields *****
  final List<String> _selectedYears = [];
  final List<String> _selectedBrands = [];
  List<String> _selectedMakeModels = [];
  final List<String> _selectedVehicleStatuses = [];
  final List<String> _selectedTransmissions = [];
  final List<String> _selectedCountries = [];
  final List<String> _selectedProvinces = [];
  final List<String> _selectedApplicationOfUse = [];
  final List<String> _selectedConfigs = [];
  final List<String> _selectedVehicleType = [];
  // ********************************

  // Hard-coded filter options.
  final List<String> _yearOptions = [
    'All',
    '2015',
    '2016',
    '2017',
    '2018',
    '2019',
    '2020',
    '2021',
    '2022',
    '2023',
    '2024'
  ];
  final List<String> _vehicleStatusOptions = ['All', 'Live', 'Sold', 'Draft'];
  final List<String> _transmissionOptions = ['All', 'manual', 'automatic'];
  final List<String> _countryOptions = ['All'];
  List<String> _provinceOptions = ['All'];
  final List<String> _applicationOfUseOptions = [
    'Bowser Body Trucks',
    'Cage Body Trucks',
    'Cattle Body Trucks',
    'Chassis Cab Trucks',
    'Cherry Picker Trucks',
    'Compactor Body Trucks',
    'Concrete Mixer Body Trucks',
    'Crane Body Trucks',
    'Curtain Body Trucks',
    'Fuel Tanker Body Trucks',
    'Dropside Body Trucks',
    'Fire Fighting Body Trucks',
    'Flatbed Body Trucks',
    'Honey Sucker Body Trucks',
    'Hooklift Body Trucks',
    'Insulated Body Trucks',
    'Mass Side Body Trucks',
    'Pantechnicon Body Trucks',
    'Refrigerated Body Trucks',
    'Roll Back Body Trucks',
    'Side Tipper Body Trucks',
    'Skip Loader Body Trucks',
    'Tanker Body Trucks',
    'Tipper Body Trucks',
    'Volume Body Trucks',
  ];
  final List<String> _configOptions = [
    'All',
    '4x2',
    '6x4',
    '6x2',
    '8x4',
    '10x4'
  ];
  final List<String> _vehicleTypeOptions = ['All', 'truck', 'trailer'];

  final List<String> _brandOptions = ['All']; // From JSON
  List<String> _makeModelOptions = ['All']; // From JSON
  List<dynamic> _countriesData = [];

  Future<void> _loadBrandsFromJson() async {
    try {
      final String response =
          await rootBundle.loadString('lib/assets/updated_truck_data.json');
      final Map<String, dynamic> jsonData = json.decode(response);
      Set<String> uniqueBrands = {};
      jsonData.forEach((year, yearData) {
        if (yearData is Map<String, dynamic>) {
          yearData.forEach((brandName, _) {
            final String normalized = brandName.trim();
            uniqueBrands.add(normalized);
          });
        }
      });
      List<String> sortedBrands = uniqueBrands.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      setState(() {
        _brandOptions.clear();
        _brandOptions.add('All');
        _brandOptions.addAll(sortedBrands);
      });
    } catch (e) {
      debugPrint('Error loading brands from JSON: $e');
    }
  }

  Future<void> _loadCountriesFromJson() async {
    try {
      final String response =
          await rootBundle.loadString('lib/assets/countries.json');
      final data = json.decode(response);
      if (data is List) {
        setState(() {
          _countriesData = data;
          _countryOptions.clear();
          _countryOptions.add('All');
          for (var item in data) {
            if (item is Map<String, dynamic>) {
              final countryName = item['name'];
              if (countryName != null) {
                _countryOptions.add(countryName);
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading countries from JSON: $e');
    }
  }

  void _updateProvincesForCountry(String countryName) {
    if (countryName == 'All') {
      setState(() {
        _provinceOptions = ['All'];
      });
      return;
    }
    final country = _countriesData.firstWhere(
      (element) =>
          (element is Map<String, dynamic>) && (element['name'] == countryName),
      orElse: () => null,
    );
    if (country == null || country['states'] == null) {
      setState(() {
        _provinceOptions = ['All'];
      });
    } else {
      final statesList = country['states'] as List<dynamic>;
      final provinceNames = <String>[];
      for (var s in statesList) {
        if (s is Map<String, dynamic>) {
          final provinceName = s['name'];
          if (provinceName != null) {
            provinceNames.add(provinceName);
          }
        }
      }
      provinceNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      setState(() {
        _provinceOptions = ['All', ...provinceNames];
      });
    }
  }

  void _updateModelsForBrand(String brand) async {
    try {
      if (brand == 'All') {
        setState(() {
          _makeModelOptions = ['All'];
        });
        return;
      }
      final String response =
          await rootBundle.loadString('lib/assets/updated_truck_data.json');
      final Map<String, dynamic> jsonData = json.decode(response);
      Set<String> models = {};
      jsonData.forEach((year, yearData) {
        if (yearData is Map<String, dynamic>) {
          yearData.forEach((dataBrand, modelList) {
            if (dataBrand.trim().toLowerCase() == brand.trim().toLowerCase()) {
              if (modelList is List) {
                for (var m in modelList) {
                  models.add(m.toString().trim());
                }
              }
            }
          });
        }
      });
      List<String> sortedModels = models.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      setState(() {
        _makeModelOptions = ['All', ...sortedModels];
      });
    } catch (e, stackTrace) {
      debugPrint('Error loading models for brand $brand: $e');
      debugPrint(stackTrace.toString());
    }
  }

  void _loadInitialVehicles() async {
    try {
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      await vehicleProvider.fetchAllVehicles();
      setState(() {
        var filteredVehicles = vehicleProvider.vehicles
            .where((vehicle) => vehicle.vehicleStatus == 'Live');
        // If a selected brand is provided (via widget.selectedBrand), apply it.
        if (widget.toString().contains('selectedBrand')) {
          filteredVehicles = filteredVehicles.where(
            (vehicle) =>
                vehicle.brands.contains((widget as dynamic).selectedBrand),
          );
        }
        filteredVehicles = _applySelectedFilters(filteredVehicles);
        displayedVehicles = filteredVehicles.take(_itemsPerPage).toList();
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _loadInitialVehicles: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load vehicles. Please try again later.'),
        ),
      );
    }
  }

  void _loadMoreVehicles() async {
    setState(() {
      _isLoadingMore = true;
    });
    try {
      final vehicleProvider =
          Provider.of<VehicleProvider>(context, listen: false);
      int startIndex = _currentPage * _itemsPerPage;
      var filteredVehicles = vehicleProvider.vehicles
          .where((vehicle) => vehicle.vehicleStatus == 'Live');
      if (widget.toString().contains('selectedBrand')) {
        filteredVehicles = filteredVehicles.where(
          (vehicle) =>
              vehicle.brands.contains((widget as dynamic).selectedBrand),
        );
      }
      filteredVehicles = _applySelectedFilters(filteredVehicles);
      List<Vehicle> moreVehicles =
          filteredVehicles.skip(startIndex).take(_itemsPerPage).toList();
      if (moreVehicles.isNotEmpty) {
        setState(() {
          displayedVehicles.addAll(moreVehicles);
          _currentPage++;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _hasReachedEnd = true;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      print('Error in _loadMoreVehicles: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Iterable<Vehicle> _applySelectedFilters(Iterable<Vehicle> vehicles) {
    return vehicles.where((vehicle) {
      // YEAR
      if (_selectedYears.isNotEmpty && !_selectedYears.contains('All')) {
        if (!_selectedYears.contains(vehicle.year)) return false;
      }
      // BRAND
      if (_selectedBrands.isNotEmpty && !_selectedBrands.contains('All')) {
        if (!vehicle.brands.any((brand) => _selectedBrands.contains(brand))) {
          return false;
        }
      }
      // MODEL
      if (_selectedMakeModels.isNotEmpty &&
          !_selectedMakeModels.contains('All')) {
        if (!_selectedMakeModels.contains(vehicle.makeModel)) return false;
      }
      // VEHICLE STATUS
      if (_selectedVehicleStatuses.isNotEmpty &&
          !_selectedVehicleStatuses.contains('All')) {
        if (!_selectedVehicleStatuses.contains(vehicle.vehicleStatus)) {
          return false;
        }
      }
      // TRANSMISSION
      if (_selectedTransmissions.isNotEmpty &&
          !_selectedTransmissions.contains('All')) {
        if (!_selectedTransmissions.contains(vehicle.transmissionType)) {
          return false;
        }
      }
      // COUNTRY
      if (_selectedCountries.isNotEmpty &&
          !_selectedCountries.contains('All')) {
        if (!_selectedCountries.contains(vehicle.country)) return false;
      }
      // PROVINCE
      if (_selectedProvinces.isNotEmpty &&
          !_selectedProvinces.contains('All')) {
        if (!_selectedProvinces.contains(vehicle.province)) return false;
      }
      // APPLICATION OF USE
      if (_selectedApplicationOfUse.isNotEmpty &&
          !_selectedApplicationOfUse.contains('All')) {
        if (!_selectedApplicationOfUse.contains(vehicle.application)) {
          return false;
        }
      }
      // CONFIG
      if (_selectedConfigs.isNotEmpty && !_selectedConfigs.contains('All')) {
        if (!_selectedConfigs.contains(vehicle.config)) return false;
      }
      // VEHICLE TYPE
      if (_selectedVehicleType.isNotEmpty &&
          !_selectedVehicleType.contains('All')) {
        if (!_selectedVehicleType.contains(vehicle.vehicleType)) return false;
      }
      return true;
    });
  }

  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Filter Vehicles',
            style: GoogleFonts.montserrat(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // YEAR
                    ExpansionTile(
                      title: Text(
                        'By Year',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      children: _yearOptions.map((year) {
                        return CheckboxListTile(
                          title: Text(
                            year,
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                          value: _selectedYears.contains(year),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (year == 'All') _selectedYears.clear();
                                if (_selectedYears.contains('All')) {
                                  _selectedYears.remove('All');
                                }
                                _selectedYears.add(year);
                              } else {
                                _selectedYears.remove(year);
                              }
                            });
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),

                    // BRAND
                    ExpansionTile(
                      title: Text(
                        'By Brand',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      children: _brandOptions.map((brand) {
                        return CheckboxListTile(
                          title: Text(
                            brand,
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                          value: _selectedBrands.contains(brand),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (brand == 'All') _selectedBrands.clear();
                                if (_selectedBrands.contains('All')) {
                                  _selectedBrands.remove('All');
                                }
                                _selectedBrands.add(brand);
                                if (_selectedBrands.length == 1) {
                                  _updateModelsForBrand(brand);
                                }
                              } else {
                                _selectedBrands.remove(brand);
                                if (_selectedBrands.isEmpty) {
                                  _selectedMakeModels = ['All'];
                                }
                              }
                            });
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),

                    // MODEL
                    ExpansionTile(
                      title: Text(
                        'By Model',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      children: _makeModelOptions.map((model) {
                        return CheckboxListTile(
                          title: Text(
                            model,
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                          value: _selectedMakeModels.contains(model),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (model == 'All') {
                                  _selectedMakeModels.clear();
                                }
                                if (_selectedMakeModels.contains('All')) {
                                  _selectedMakeModels.remove('All');
                                }
                                _selectedMakeModels.add(model);
                              } else {
                                _selectedMakeModels.remove(model);
                              }
                            });
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),

                    // VEHICLE STATUS
                    ExpansionTile(
                      title: Text(
                        'By Status',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      children: _vehicleStatusOptions
                          .where((status) =>
                              status != 'Draft' &&
                              status != 'pending' &&
                              status != 'Live')
                          .map((status) {
                        return CheckboxListTile(
                          title: Text(
                            status,
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                          value: _selectedVehicleStatuses.contains(status),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (status == 'All') {
                                  _selectedVehicleStatuses.clear();
                                }
                                if (_selectedVehicleStatuses.contains('All')) {
                                  _selectedVehicleStatuses.remove('All');
                                }
                                _selectedVehicleStatuses.add(status);
                              } else {
                                _selectedVehicleStatuses.remove(status);
                              }
                            });
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),

                    // TRANSMISSION
                    ExpansionTile(
                      title: Text(
                        'By Transmission',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      children: _transmissionOptions.map((trans) {
                        return CheckboxListTile(
                          title: Text(
                            trans,
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                          value: _selectedTransmissions.contains(trans),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (trans == 'All') {
                                  _selectedTransmissions.clear();
                                }
                                if (_selectedTransmissions.contains('All')) {
                                  _selectedTransmissions.remove('All');
                                }
                                _selectedTransmissions.add(trans);
                              } else {
                                _selectedTransmissions.remove(trans);
                              }
                            });
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),

                    // COUNTRY
                    ExpansionTile(
                      title: Text(
                        'By Country',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      children: _countryOptions.map((ctry) {
                        return CheckboxListTile(
                          title: Text(
                            ctry,
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                          value: _selectedCountries.contains(ctry),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (ctry == 'All') {
                                  _selectedCountries.clear();
                                }
                                if (_selectedCountries.contains('All')) {
                                  _selectedCountries.remove('All');
                                }
                                _selectedCountries.add(ctry);
                                if (_selectedCountries.length == 1 &&
                                    ctry != 'All') {
                                  _updateProvincesForCountry(ctry);
                                } else {
                                  _provinceOptions = ['All'];
                                }
                              } else {
                                _selectedCountries.remove(ctry);
                                if (_selectedCountries.isEmpty) {
                                  _provinceOptions = ['All'];
                                } else if (_selectedCountries.length == 1) {
                                  final onlyCtry = _selectedCountries.first;
                                  if (onlyCtry != 'All') {
                                    _updateProvincesForCountry(onlyCtry);
                                  }
                                }
                              }
                            });
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),

                    // PROVINCE
                    ExpansionTile(
                      title: Text(
                        'By Province',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      children: _provinceOptions.map((prov) {
                        return CheckboxListTile(
                          title: Text(
                            prov,
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                          value: _selectedProvinces.contains(prov),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (prov == 'All') {
                                  _selectedProvinces.clear();
                                }
                                if (_selectedProvinces.contains('All')) {
                                  _selectedProvinces.remove('All');
                                }
                                _selectedProvinces.add(prov);
                              } else {
                                _selectedProvinces.remove(prov);
                              }
                            });
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),

                    // APPLICATION OF USE
                    ExpansionTile(
                      title: Text(
                        'By Application Of Use',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      children: _applicationOfUseOptions.map((vtype) {
                        return CheckboxListTile(
                          title: Text(
                            vtype,
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                          value: _selectedApplicationOfUse.contains(vtype),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (vtype == 'All') {
                                  _selectedApplicationOfUse.clear();
                                }
                                if (_selectedApplicationOfUse.contains('All')) {
                                  _selectedApplicationOfUse.remove('All');
                                }
                                _selectedApplicationOfUse.add(vtype);
                              } else {
                                _selectedApplicationOfUse.remove(vtype);
                              }
                            });
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),

                    // CONFIG
                    ExpansionTile(
                      title: Text(
                        'By Config',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      children: _configOptions.map((cfg) {
                        return CheckboxListTile(
                          title: Text(
                            cfg,
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                          value: _selectedConfigs.contains(cfg),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (cfg == 'All') {
                                  _selectedConfigs.clear();
                                }
                                if (_selectedConfigs.contains('All')) {
                                  _selectedConfigs.remove('All');
                                }
                                _selectedConfigs.add(cfg);
                              } else {
                                _selectedConfigs.remove(cfg);
                              }
                            });
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),

                    // VEHICLE TYPE
                    ExpansionTile(
                      title: Text(
                        'By Vehicle Type',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                      children: _vehicleTypeOptions.map((type) {
                        return CheckboxListTile(
                          title: Text(
                            type,
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                          value: _selectedVehicleType.contains(type),
                          onChanged: (bool? value) {
                            setDialogState(() {
                              if (value == true) {
                                if (type == 'All') {
                                  _selectedVehicleType.clear();
                                }
                                if (_selectedVehicleType.contains('All')) {
                                  _selectedVehicleType.remove('All');
                                }
                                _selectedVehicleType.add(type);
                              } else {
                                _selectedVehicleType.remove(type);
                              }
                            });
                          },
                          checkColor: Colors.black,
                          activeColor: const Color(0xFFFF4E00),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Clear All',
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
              onPressed: () {
                setState(() {
                  _selectedYears.clear();
                  _selectedBrands.clear();
                  _selectedMakeModels.clear();
                  _selectedVehicleStatuses.clear();
                  _selectedTransmissions.clear();
                  _selectedCountries.clear();
                  _selectedProvinces.clear();
                  _selectedApplicationOfUse.clear();
                  _selectedConfigs.clear();
                  _selectedVehicleType.clear();
                  _provinceOptions = ['All'];
                });
                Navigator.pop(context);
                _loadInitialVehicles();
              },
            ),
            TextButton(
              child: Text(
                'Apply',
                style: GoogleFonts.montserrat(color: Color(0xFFFF4E00)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _loadInitialVehicles();
              },
            ),
          ],
        );
      },
    );
  }

  void _clearLikedAndDislikedVehicles() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.clearDislikedVehicles();
      await userProvider.clearLikedVehicles();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Liked and disliked vehicles have been cleared.'),
        ),
      );
      _loadInitialVehicles();
    } catch (e) {
      print('Error in _clearLikedAndDislikedVehicles: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to clear vehicles. Please try again.'),
        ),
      );
    }
  }

  TextStyle _customFont(double fontSize, FontWeight fontWeight, Color color) {
    return GoogleFonts.montserrat(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  void _markAsInterested(Vehicle vehicle) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.getLikedVehicles.contains(vehicle.id)) {
        await userProvider.unlikeVehicle(vehicle.id);
      } else {
        await userProvider.likeVehicle(vehicle.id);
      }
      setState(() {});
    } catch (e) {
      print('Error in _markAsInterested: $e');
    }
  }

  Widget _buildNoVehiclesAvailable() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "No Vehicles Available",
            style: _customFont(16, FontWeight.normal, Colors.white),
          ),
          const SizedBox(height: 16),
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 20.0),
          //   child: Text(
          //     "For TESTING PURPOSES ONLY the below button can be used to loop through all the trucks on the database",
          //     style: _customFont(16, FontWeight.normal, Colors.white),
          //     textAlign: TextAlign.center,
          //   ),
          // ),
          // const SizedBox(height: 16),
          // ElevatedButton(
          //   onPressed: _clearLikedAndDislikedVehicles,
          //   style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          //   child: Text(
          //     'Clear Liked & Disliked Vehicles',
          //     style: _customFont(14, FontWeight.bold, Colors.white),
          //   ),
          // ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool showBottomNav = !_isLargeScreen && !kIsWeb;
    final userProvider = Provider.of<UserProvider>(context);
    final userRole = userProvider.getUserRole;

    List<NavigationItem> navigationItems = userRole == 'dealer'
        ? [
            NavigationItem(title: 'Home', route: '/home'),
            NavigationItem(title: 'Search Trucks', route: '/truckPage'),
            NavigationItem(title: 'Wishlist', route: '/wishlist'),
            NavigationItem(title: 'Pending Offers', route: '/offers'),
          ]
        : [
            NavigationItem(title: 'Home', route: '/home'),
            NavigationItem(title: 'Your Trucks', route: '/transporterList'),
            NavigationItem(title: 'Your Offers', route: '/offers'),
            NavigationItem(title: 'In-Progress', route: '/in-progress'),
          ];

    return GradientBackground(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: kIsWeb
            ? PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: WebNavigationBar(
                  isCompactNavigation: _isCompactNavigation(context),
                  currentRoute: '/wishlist',
                  onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
              )
            : CustomAppBar(),
        drawer: (kIsWeb && _isCompactNavigation(context))
            ? Drawer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: const [Colors.black, Color(0xFF2F7FFD)],
                    ),
                  ),
                  child: Column(
                    children: [
                      DrawerHeader(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.white24, width: 1),
                          ),
                        ),
                        child: Center(
                          child: Image.network(
                            'https://firebasestorage.googleapis.com/v0/b/ctp-central-database.appspot.com/o/CTPLOGOWeb.png?alt=media&token=d85ec0b5-f2ba-4772-aa08-e9ac6d4c2253',
                            height: 50,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 50,
                                width: 50,
                                color: Colors.grey[900],
                                child: const Icon(Icons.local_shipping,
                                    color: Colors.white),
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          children: navigationItems.map((item) {
                            bool isActive = '/wishlist' == item.route;
                            return ListTile(
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  color: isActive
                                      ? const Color(0xFFFF4E00)
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              selected: isActive,
                              selectedTileColor: Colors.black12,
                              onTap: () {
                                Navigator.pop(context);
                                if (!isActive) {
                                  Navigator.pushNamed(context, item.route);
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            // Header section with the Wishlist title and image.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(height: screenSize.height * 0.05),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'lib/assets/HeartVector.png',
                          width: 30,
                          height: 30,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'WISHLIST',
                          style: TextStyle(
                            color: Color(0xFFFF4E00),
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    SizedBox(height: screenSize.height * 0.03),
                  ],
                ),
              ),
            ),
            // Sticky tab bar – using SliverPersistentHeader.
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabBarDelegate(
                minHeight: 60,
                maxHeight: 60,
                child: Container(
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTabButton('Trucks (${trucks.length})', 'Trucks'),
                      SizedBox(width: screenSize.width * 0.02),
                      _buildTabButton(
                          'Trailers (${trailers.length})', 'Trailers'),
                    ],
                  ),
                ),
              ),
            ),
            // Display loading, no vehicles message, or grid.
            if (_isLoading)
              SliverFillRemaining(
                child: Center(
                  child: Image.asset(
                    'lib/assets/Loading_Logo_CTP.gif',
                    width: 100,
                    height: 100,
                  ),
                ),
              )
            else if (currentList.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    "No vehicles found.",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _calculateCrossAxisCountUpdated(context),
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    mainAxisExtent: 600,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < displayedVehicles.length) {
                        return _buildWishCard(
                            displayedVehicles[index], screenSize);
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                    childCount:
                        displayedVehicles.length + (_isLoadingMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: (kIsWeb ||
                userRole == 'admin' ||
                userRole == 'sales representative')
            ? null
            : CustomBottomNavigation(
                selectedIndex: 3,
                onItemTapped: (index) {
                  // Handle bottom navigation taps.
                },
              ),
      ),
    );
  }

  Widget _buildTabButton(String title, String tab) {
    bool isSelected = _selectedTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tab;
          // Update displayedVehicles to match the selected tab.
          displayedVehicles = _selectedTab == 'Trucks' ? trucks : trailers;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange : Colors.black,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.blue,
            width: 1.0,
          ),
        ),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverTabBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => max(maxHeight, minHeight);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
