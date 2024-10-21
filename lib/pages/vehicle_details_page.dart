// lib/pages/vehicle_details_page.dart

import 'package:ctp/pages/truckForms/vehilce_upload_tabs.dart';
import 'package:flutter/material.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/components/offer_card.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_vehicle.dart';

// Define the PhotoItem class to hold both the image URL and its label
class PhotoItem {
  final String url;
  final String label;

  PhotoItem({required this.url, required this.label});
}

class VehicleDetailsPage extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailsPage({super.key, required this.vehicle});

  @override
  _VehicleDetailsPageState createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {
  final TextEditingController _controller = TextEditingController();
  double _totalCost = 0.0;
  int _currentImageIndex = 0;
  bool _isLoading = false;
  double _offerAmount = 0.0;
  bool _hasMadeOffer = false;
  bool _isAdditionalInfoExpanded = true; // State to track the dropdown
  List<PhotoItem> allPhotos = [];
  late PageController _pageController;
  String _offerStatus = 'in-progress'; // Default status for the offer

  // New state variables for admin functionality
  Dealer? _selectedDealer;
  bool _isDealersLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfOfferMade();
    _fetchAllDealers(); // Fetch dealers when the page initializes

    try {
      allPhotos = [];

      // Ensure the main image is added first
      if (widget.vehicle.mainImageUrl != null &&
          widget.vehicle.mainImageUrl!.isNotEmpty) {
        allPhotos.add(
            PhotoItem(url: widget.vehicle.mainImageUrl!, label: 'Main Image'));
        print('Main Image Added: ${widget.vehicle.mainImageUrl}');
      }

      // Add damage photos
      if (widget.vehicle.damagePhotos.isNotEmpty) {
        for (int i = 0; i < widget.vehicle.damagePhotos.length; i++) {
          _addPhotoIfExists(
              widget.vehicle.damagePhotos[i], 'Damage Photo ${i + 1}');
        }
      }

      // Additional photo fields
      _addPhotoIfExists(widget.vehicle.dashboardPhoto, 'Dashboard Photo');
      _addPhotoIfExists(widget.vehicle.faultCodesPhoto, 'Fault Codes Photo');
      _addPhotoIfExists(widget.vehicle.treadLeft, 'Tread Left Photo');
      _addPhotoIfExists(widget.vehicle.tyrePhoto1, 'Tyre Photo 1');
      _addPhotoIfExists(widget.vehicle.tyrePhoto2, 'Tyre Photo 2');
      _addPhotoIfExists(widget.vehicle.bed_bunk, 'Bed Bunk Photo');
      _addPhotoIfExists(widget.vehicle.dashboard, 'Dashboard');
      _addPhotoIfExists(widget.vehicle.door_panels, 'Door Panels Photo');
      _addPhotoIfExists(
          widget.vehicle.front_tyres_tread, 'Front Tyres Tread Photo');
      _addPhotoIfExists(widget.vehicle.front_view, 'Front View Photo');
      _addPhotoIfExists(widget.vehicle.left_front_45, 'Left Front 45° Photo');
      _addPhotoIfExists(widget.vehicle.left_rear_45, 'Left Rear 45° Photo');
      _addPhotoIfExists(widget.vehicle.left_side_view, 'Left Side View Photo');
      _addPhotoIfExists(widget.vehicle.licenceDiskUrl, 'Licence Disk Photo');
      _addPhotoIfExists(widget.vehicle.license_disk, 'License Disk Photo');
      _addPhotoIfExists(widget.vehicle.mileageImage, 'Mileage Image');
      _addPhotoIfExists(
          widget.vehicle.rear_tyres_tread, 'Rear Tyres Tread Photo');
      _addPhotoIfExists(widget.vehicle.rear_view, 'Rear View Photo');
      _addPhotoIfExists(widget.vehicle.right_front_45, 'Right Front 45° Photo');
      _addPhotoIfExists(widget.vehicle.right_rear_45, 'Right Rear 45° Photo');
      _addPhotoIfExists(
          widget.vehicle.right_side_view, 'Right Side View Photo');
      _addPhotoIfExists(widget.vehicle.roof, 'Roof Photo');
      _addPhotoIfExists(widget.vehicle.seats, 'Seats Photo');
      _addPhotoIfExists(widget.vehicle.spare_wheel, 'Spare Wheel Photo');

      print('Total photos added: ${allPhotos.length}');

      _pageController = PageController();
    } catch (e) {
      print('Error loading vehicle photos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error loading vehicle photos. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper function to add photo if it exists
  void _addPhotoIfExists(String? photoUrl, String photoLabel) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      allPhotos.add(PhotoItem(url: photoUrl, label: photoLabel));
      print('$photoLabel Added: $photoUrl');
    } else {
      print('$photoLabel is null or empty');
    }
  }

  // New method to fetch all dealers using UserProvider
  Future<void> _fetchAllDealers() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _isDealersLoading = true;
    });

    try {
      await userProvider.fetchDealers();
      if (userProvider.dealers.isNotEmpty) {
        setState(() {
          _selectedDealer = userProvider.dealers.first;
        });
      }
      print('Fetched ${userProvider.dealers.length} dealers.');
    } catch (e) {
      print('Error fetching dealers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load dealers. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isDealersLoading = false;
      });
    }
  }

  Future<void> _checkIfOfferMade() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String dealerId = user.uid;
      String vehicleId = widget.vehicle.id;

      QuerySnapshot offersSnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('dealerId', isEqualTo: dealerId)
          .where('vehicleId', isEqualTo: vehicleId)
          .get();

      setState(() {
        if (offersSnapshot.docs.isNotEmpty) {
          _hasMadeOffer = true;
          _offerStatus = offersSnapshot.docs.first['offerStatus'] ?? 'pending';
        }
      });
    } catch (e) {
      print('Error checking if offer is made: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to check offer status. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<Offer>> _fetchOffersForVehicle() async {
    try {
      OfferProvider offerProvider =
          Provider.of<OfferProvider>(context, listen: false);
      List<Offer> offers =
          await offerProvider.fetchOffersForVehicle(widget.vehicle.id);
      return offers;
    } catch (e) {
      print('Error fetching offers: $e');
      return [];
    }
  }

  Widget _buildOffersList() {
    return FutureBuilder<List<Offer>>(
      future: _fetchOffersForVehicle(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF4E00)),
          );
        } else if (snapshot.hasError) {
          return const Center(
            child: Text('Error fetching offers'),
          );
        } else if (snapshot.data == null || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No offers available for this vehicle'),
          );
        }

        List<Offer> offers = snapshot.data!;

        // Sort offers by createdAt in descending order (latest first)
        offers.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: offers.length,
          itemBuilder: (context, index) {
            Offer offer = offers[index];

            // Use the custom OfferCard widget here
            return OfferCard(
              offer: offer,
            );
          },
        );
      },
    );
  }

  TextStyle _customFont(double fontSize, FontWeight fontWeight, Color color) {
    return GoogleFonts.montserrat(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  void _navigateToEditPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditVehiclePage(vehicle: widget.vehicle),
      ),
    );
  }

  void _navigateToDuplicatePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleUploadTabs(
          vehicle: widget.vehicle,
          isDuplicating: true,
        ),
      ),
    );
  }

  double _calculateTotalCost(double basePrice) {
    const double vatRate = 0.15;
    const double flatRateFee = 12500.0;
    double subTotal = basePrice + flatRateFee;
    double vat = subTotal * vatRate;
    return subTotal + vat;
  }

  String _formatNumberWithSpaces(String number) {
    return number.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }

  Widget _buildActionButton(IconData icon, Color backgroundColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Colors.black, // Icon color set to black as in the image
          size: 24,
        ),
      ),
    );
  }

  Future<void> _makeOffer() async {
    // Access user role
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String userRole = userProvider.getUserRole;
    final bool isAdmin = userRole == 'admin'; // Check if the user is an admin
    final bool isDealer = userRole == 'dealer'; // Check if the user is a dealer

    print('User Role: $userRole'); // Debug statement

    // Validate offer amount
    if (_offerAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid offer amount.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If user is admin, ensure a dealer is selected
    if (isAdmin && _selectedDealer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please select a dealer to make an offer on behalf of.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      String dealerId = isAdmin
          ? _selectedDealer!.id
          : isDealer
              ? user.uid
              : ''; // Use selected dealer for admin, own userId for dealer
      String vehicleId = widget.vehicle.id;
      String transporterId = widget.vehicle.userId;
      DateTime createdAt = DateTime.now();

      DocumentReference docRef =
          FirebaseFirestore.instance.collection('offers').doc();
      String offerId = docRef.id;

      await docRef.set({
        'offerId': offerId,
        'dealerId': dealerId,
        'vehicleId': vehicleId,
        'transporterId': transporterId,
        'createdAt': createdAt,
        'collectionDates': null,
        'collectionLocation': null,
        'inspectionDates': null,
        'inspectionLocation': null,
        'dealerSelectedInspectionDate': null,
        'dealerSelectedCollectionDate': null,
        'paymentStatus': 'pending',
        'offerStatus': 'in-progress',
        'offerAmount': _offerAmount,
        'dealerInspectionComplete': false,
        'transporterInspectionComplete': false,
      });

      _controller.clear();
      setState(() {
        _totalCost = 0.0;
        _offerAmount = 0.0;
        _hasMadeOffer = true;
        _offerStatus = 'in-progress';
        if (isAdmin) {
          _selectedDealer = userProvider.dealers.isNotEmpty
              ? userProvider.dealers.first
              : null;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error making offer: $e'); // Debug statement
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting offer: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String getDisplayStatus(String? offerStatus) {
    switch (offerStatus?.toLowerCase()) {
      case 'in-progress':
        return 'In Progress';
      case 'select location and time':
        return 'Set Location and Time';
      case 'accepted':
        return 'Accepted';
      case 'set location and time':
        return 'Setup Inspection';
      case 'confirm location':
        return 'Confirm Location';
      case 'inspection pending':
        return 'Inspection Pending';
      case '3/4':
        return 'Step 3 of 4';
      case 'paid':
        return 'Paid';
      case 'issue reported':
        return 'Issue Reported';
      case 'resolved':
        return 'Resolved';
      case 'done':
        return 'Done';
      default:
        return offerStatus ?? 'Unknown';
    }
  }

  Widget _buildAdditionalInfo() {
    List<Widget> infoWidgets = [];

    void addInfo(String title, String? value) {
      if (value != null &&
          value.isNotEmpty &&
          value.toLowerCase() != 'unknown') {
        if (title == 'Damage Description') {
          infoWidgets.add(_buildInfoRowWithIcon(title, value));
        } else {
          infoWidgets.add(_buildInfoRow(title, value));
        }
      }
    }

    try {
      addInfo('Accident Free', widget.vehicle.accidentFree);
      addInfo('Application', widget.vehicle.application);
      addInfo('Book Value', widget.vehicle.bookValue);
      addInfo('Damage Description', widget.vehicle.damageDescription);
      addInfo('Engine Number', widget.vehicle.engineNumber);
      addInfo('First Owner', widget.vehicle.firstOwner);
      addInfo('Hydraulics', widget.vehicle.hydraulics);
      addInfo('List Damages', widget.vehicle.listDamages);
      addInfo('Maintenance', widget.vehicle.maintenance);
      addInfo('OEM Inspection', widget.vehicle.oemInspection);
      addInfo('Registration Number', widget.vehicle.registrationNumber);
      addInfo('Road Worthy', widget.vehicle.roadWorthy);
      addInfo('Settle Before Selling', widget.vehicle.settleBeforeSelling);
      addInfo('Settlement Amount', widget.vehicle.settlementAmount);
      addInfo('Spare Tyre', widget.vehicle.spareTyre);
      addInfo('Suspension', widget.vehicle.suspension);
      addInfo('Tread Left', widget.vehicle.treadLeft);
      addInfo('Tyre Type', widget.vehicle.tyreType);
      addInfo('VIN Number', widget.vehicle.vinNumber);
      addInfo('Warranty', widget.vehicle.warranty);
      addInfo('Warranty Type', widget.vehicle.warrantyType);
      addInfo('Weight Class', widget.vehicle.weightClass);
    } catch (e) {
      print('Error building additional info: $e'); // Debug statement
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error loading vehicle details. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: infoWidgets,
    );
  }

  Widget _buildInfoRowWithIcon(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: _customFont(14, FontWeight.normal, Colors.white),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  _showDamageDescriptionDialog(value);
                },
                child: const Icon(Icons.info_outline, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: _customFont(14, FontWeight.normal, Colors.white),
          ),
          Text(
            value ?? 'Unknown',
            style: _customFont(14, FontWeight.bold, Colors.white),
          ),
        ],
      ),
    );
  }

  void _showDamageDescriptionDialog(String? description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Damage Description',
              style: _customFont(18, FontWeight.bold, Colors.black)),
          content: Text(description ?? 'No damage description available.',
              style: _customFont(16, FontWeight.normal, Colors.black)),
          actions: <Widget>[
            TextButton(
              child: Text('CLOSE',
                  style: _customFont(14, FontWeight.bold, Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    final userProvider = Provider.of<UserProvider>(context);
    final String userRole = userProvider.getUserRole;
    final bool isAdmin = userRole == 'admin'; // Check if the user is an admin
    final bool isTransporter =
        userRole == 'transporter'; // Check if the user is a dealer
    var blue = const Color(0xFF2F7FFF);

    final size = MediaQuery.of(context).size;

    // Debug statement to check if user is admin
    print('Is Admin: $isAdmin');
    print('Is Dealer: $isTransporter');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFFFF4E00),
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            // Wrap the Text widget with Expanded to prevent overflow
            Expanded(
              child: Text(
                widget.vehicle.makeModel.toUpperCase(),
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: blue,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.verified,
              color: Color(0xFFFF4E00),
              size: 24,
            ),
          ],
        ),
        actions: [
          // Updated condition to show Edit button for both Dealers and Admins
          if (isTransporter || isAdmin)
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: Color(0xFFFF4E00),
                size: 24,
              ),
              onPressed: () {
                _navigateToEditPage();
              },
            ),
          if (isTransporter)
            IconButton(
              icon: const Icon(
                Icons.copy,
                color: Color(0xFFFF4E00),
                size: 24,
              ), // Duplicate button
              onPressed: () {
                _navigateToDuplicatePage(context);
              },
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Image carousel and other vehicle details
                Stack(
                  children: [
                    SizedBox(
                      height: size.height * 0.32,
                      child: PageView.builder(
                        itemCount: allPhotos.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    _showFullScreenImage(context, index),
                                child: Image.network(
                                  allPhotos[index].url,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: size.height * 0.45,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/default_vehicle_image.png',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: size.height * 0.45,
                                    );
                                  },
                                ),
                              ),
                              IgnorePointer(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.3),
                                        Colors.black.withOpacity(1),
                                      ],
                                      stops: const [0.5, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              // Overlay label on top left corner
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  color: Colors.black54,
                                  child: Text(
                                    allPhotos[index].label,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildImageIndicators(allPhotos.length),
                      ),
                    ),
                  ],
                ),
                // Vehicle details and offers
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInfoContainer('YEAR', widget.vehicle.year),
                          const SizedBox(width: 5),
                          _buildInfoContainer(
                              'MILEAGE', widget.vehicle.mileage),
                          const SizedBox(width: 5),
                          _buildInfoContainer(
                              'GEARBOX', widget.vehicle.transmission),
                          const SizedBox(width: 5),
                          _buildInfoContainer('CONFIG', widget.vehicle.config),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if ((isAdmin || isTransporter) && !_hasMadeOffer)
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton(Icons.close, blue),
                                const SizedBox(width: 16),
                                _buildActionButton(
                                    Icons.favorite, const Color(0xFFFF4E00)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text('Make an Offer',
                                style: _customFont(
                                    20, FontWeight.bold, Colors.white)),
                            const SizedBox(height: 8),

                            // Dealer Selection Dropdown for Admins at the Top
                            if (isAdmin) ...[
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Select Dealer',
                                  style: _customFont(
                                      16, FontWeight.bold, Colors.white),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Consumer<UserProvider>(
                                builder: (context, userProvider, child) {
                                  if (userProvider.dealers.isEmpty) {
                                    return const Text(
                                      'No dealers available.',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 16,
                                      ),
                                    );
                                  }

                                  return DropdownButtonFormField<Dealer>(
                                    value: _selectedDealer,
                                    isExpanded: true, // Ensures full width
                                    items: userProvider.dealers
                                        .map((Dealer dealer) {
                                      return DropdownMenuItem<Dealer>(
                                        value: dealer,
                                        child: Text(dealer.email),
                                      );
                                    }).toList(),
                                    onChanged: (Dealer? newDealer) {
                                      setState(() {
                                        _selectedDealer = newDealer;
                                        print(
                                            'Selected Dealer: ${_selectedDealer?.email}');
                                      });
                                    },
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.grey[800],
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        borderSide: BorderSide.none,
                                      ),
                                      hintText: 'Choose a dealer',
                                      hintStyle: _customFont(
                                          16, FontWeight.normal, Colors.grey),
                                    ),
                                    dropdownColor: Colors.grey[800],
                                    style: _customFont(
                                        16, FontWeight.normal, Colors.white),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Offer Input Field
                            TextField(
                              controller: _controller,
                              cursorColor: const Color(0xFFFF4E00),
                              decoration: InputDecoration(
                                hintText: 'R 102 000 000',
                                hintStyle: _customFont(
                                    24, FontWeight.normal, Colors.grey),
                                enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Color(0xFFFF4E00)),
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 15.0),
                              ),
                              textAlign: TextAlign.center,
                              style: _customFont(
                                  20, FontWeight.bold, Colors.white),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                setState(() {
                                  if (value.isNotEmpty) {
                                    try {
                                      // Remove spaces before parsing
                                      String numericValue =
                                          value.replaceAll(' ', '');
                                      _offerAmount = double.parse(numericValue);
                                      _totalCost =
                                          _calculateTotalCost(_offerAmount);

                                      // Format the input value with spaces
                                      String formattedValue =
                                          _formatNumberWithSpaces(numericValue);
                                      _controller.value =
                                          _controller.value.copyWith(
                                        text: formattedValue,
                                        selection: TextSelection.collapsed(
                                            offset: formattedValue.length),
                                      );
                                    } catch (e) {
                                      print('Error parsing offer amount: $e');
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Invalid offer amount. Please enter a valid number.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } else {
                                    _offerAmount = 0.0;
                                    _totalCost = 0.0;
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "R ${_formatNumberWithSpaces(_totalCost.toStringAsFixed(0))}",
                                  style: _customFont(
                                      18, FontWeight.bold, Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "including commission and VAT",
                                  style: _customFont(
                                      15, FontWeight.normal, Colors.white),
                                ),
                                const SizedBox(height: 8),
                                // Breakdown of the total cost
                                Text(
                                  "Breakdown:",
                                  style: _customFont(
                                      16, FontWeight.bold, Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Base Price: R ${_formatNumberWithSpaces(_offerAmount.toStringAsFixed(0))}",
                                  style: _customFont(
                                      14, FontWeight.normal, Colors.white),
                                ),
                                Text(
                                  "Flat Rate Fee: R 12 500",
                                  style: _customFont(
                                      14, FontWeight.normal, Colors.white),
                                ),
                                Text(
                                  "Subtotal: R ${_formatNumberWithSpaces((_offerAmount + 12500.0).toStringAsFixed(0))}",
                                  style: _customFont(
                                      14, FontWeight.normal, Colors.white),
                                ),
                                Text(
                                  "VAT (15%): R ${_formatNumberWithSpaces(((_offerAmount + 12500.0) * 0.15).toStringAsFixed(0))}",
                                  style: _customFont(
                                      14, FontWeight.normal, Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Total Cost: R ${_formatNumberWithSpaces(_totalCost.toStringAsFixed(0))}",
                                  style: _customFont(
                                      14, FontWeight.bold, Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _makeOffer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF4E00),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text('MAKE AN OFFER',
                                    style: _customFont(
                                        20, FontWeight.bold, Colors.white)),
                              ),
                            ),
                          ],
                        )
                      else if ((isAdmin || isTransporter) && !_hasMadeOffer)
                        Center(
                          child: Text(
                            "Offer Status: ${getDisplayStatus(_offerStatus)}",
                            style: _customFont(
                                20, FontWeight.bold, const Color(0xFFFF4E00)),
                          ),
                        ),
                      const SizedBox(height: 40),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isAdditionalInfoExpanded =
                                !_isAdditionalInfoExpanded;
                          });
                        },
                        child: Row(
                          children: [
                            AnimatedRotation(
                              turns: _isAdditionalInfoExpanded ? 0.25 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                Icons.arrow_right,
                                color: const Color(0xFFFF4E00),
                                size: screenSize.height * 0.04,
                              ),
                            ),
                            const SizedBox(width: 0),
                            Text('ADDITIONAL INFO',
                                style: _customFont(
                                    20, FontWeight.bold, Colors.blue)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_isAdditionalInfoExpanded) _buildAdditionalInfo(),
                      const SizedBox(height: 30),
                      if (isTransporter)
                        Column(children: [
                          Text(
                            "Offers Made on This Vehicle:",
                            style: _customFont(
                                20, FontWeight.bold, const Color(0xFFFF4E00)),
                          ),
                          const SizedBox(height: 10),
                          _buildOffersList(), // Display all offers
                        ])
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF4E00)),
              ),
            ),
        ],
      ),
      // Conditionally render the bottom navigation bar
      bottomNavigationBar: isAdmin
          ? null // Hide the bottom navigation bar for admin users
          : isTransporter
              ? CustomBottomNavigation(
                  selectedIndex: 1,
                  onItemTapped: (index) {
                    setState(() {});
                  },
                )
              : null, // Optionally handle other roles
    );
  }

  Widget _buildInfoContainer(String title, String? value) {
    var screenSize = MediaQuery.of(context).size;

    String normalizedValue = value?.trim().toLowerCase() ?? '';

    String displayValue = (title == 'GEARBOX' && value != null)
        ? (normalizedValue.contains('auto')
            ? 'AUTO'
            : normalizedValue.contains('manual')
                ? 'MANUAL'
                : value.toUpperCase())
        : value?.toUpperCase() ?? 'N/A';

    return Flexible(
      child: Container(
        height: screenSize.height * 0.07,
        width: screenSize.width * 0.22,
        padding: EdgeInsets.symmetric(
          vertical: screenSize.height * 0.005,
          horizontal: screenSize.width * 0.01,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: _customFont(
                  screenSize.height * 0.012, FontWeight.w500, Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              displayValue,
              style: _customFont(
                  screenSize.height * 0.014, FontWeight.bold, Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageIndicators(int numImages) {
    var screenSize = MediaQuery.of(context).size;
    double indicatorWidth = screenSize.width * 0.1;
    double totalWidth = numImages * indicatorWidth + (numImages - 1) * 8;
    if (totalWidth > MediaQuery.of(context).size.width) {
      indicatorWidth =
          (MediaQuery.of(context).size.width - (numImages - 1) * 8) / numImages;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(numImages, (index) {
        return Container(
          width: indicatorWidth,
          height: screenSize.height * 0.004,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color:
                index == _currentImageIndex ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.white, width: 1),
          ),
        );
      }),
    );
  }

  void _showFullScreenImage(BuildContext context, int initialIndex) {
    _pageController = PageController(initialPage: initialIndex);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: allPhotos.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      InteractiveViewer(
                        child: Image.network(
                          allPhotos[index].url,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/default_vehicle_image.png',
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          color: Colors.black54,
                          child: Text(
                            allPhotos[index].label,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              Positioned(
                left: 10,
                top: MediaQuery.of(context).size.height / 2 - 25,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () {
                    if (_pageController.hasClients) {
                      int previousIndex = _pageController.page!.toInt() - 1;
                      if (previousIndex >= 0) {
                        _pageController.animateToPage(
                          previousIndex,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    }
                  },
                ),
              ),
              Positioned(
                right: 10,
                top: MediaQuery.of(context).size.height / 2 - 25,
                child: IconButton(
                  icon:
                      const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onPressed: () {
                    if (_pageController.hasClients) {
                      int nextIndex = _pageController.page!.toInt() + 1;
                      if (nextIndex < allPhotos.length) {
                        _pageController.animateToPage(
                          nextIndex,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
