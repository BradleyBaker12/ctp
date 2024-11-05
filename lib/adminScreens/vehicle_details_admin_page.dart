// lib/adminScreens/vehicle_details_admin_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/offer_card.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/edit_vehicle.dart';
import 'package:ctp/pages/truckForms/vehilce_upload_screen.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Define the PhotoItem class to hold both the image URL and its label
class PhotoItem {
  final String url;
  final String label;

  PhotoItem({required this.url, required this.label});
}

class VehicleDetailsPageAdmin extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailsPageAdmin({super.key, required this.vehicle});

  @override
  _VehicleDetailsPageAdminState createState() =>
      _VehicleDetailsPageAdminState();
}

class _VehicleDetailsPageAdminState extends State<VehicleDetailsPageAdmin> {
  // Define blue as a class-level constant for accessibility
  static const Color blue = Color(0xFF2F7FFF);

  final TextEditingController _controller = TextEditingController();
  double _totalCost = 0.0;
  int _currentImageIndex = 0;
  bool _isLoading = false;
  double _offerAmount = 0.0;
  bool _hasMadeOffer = false;
  final bool _isAdditionalInfoExpanded = true; // State to track the dropdown
  List<PhotoItem> allPhotos = [];
  late PageController _pageController;
  String _offerStatus = 'in-progress'; // Default status for the offer

  @override
  void initState() {
    super.initState();
    _checkIfOfferMade();
    _initializePhotos();
  }

  // Initialize the photos for the gallery
  void _initializePhotos() {
    try {
      allPhotos = [];

      // Ensure the main image is added first
      if (widget.vehicle.mainImageUrl != null &&
          widget.vehicle.mainImageUrl!.isNotEmpty) {
        allPhotos.add(
          PhotoItem(url: widget.vehicle.mainImageUrl!, label: 'Main Image'),
        );
        print('Main Image Added: ${widget.vehicle.mainImageUrl}');
      }

      // Add damage photos
      if (widget.vehicle.damagePhotos.isNotEmpty) {
        for (int i = 0; i < widget.vehicle.damagePhotos.length; i++) {
          _addPhotoIfExists(
            widget.vehicle.damagePhotos[i],
            'Damage Photo ${i + 1}',
          );
        }
      }

      // Additional photo fields
      _addPhotoIfExists(widget.vehicle.dashboardPhoto, 'Dashboard Photo');
      _addPhotoIfExists(widget.vehicle.faultCodesPhoto, 'Fault Codes Photo');
      _addPhotoIfExists(widget.vehicle.licenceDiskUrl, 'Licence Disk Photo');
      _addPhotoIfExists(widget.vehicle.mileageImage, 'Mileage Image');

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

  // Check if an offer has already been made for this vehicle by the current user
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

  // Fetch offers related to the vehicle
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

  // Build the list of offers
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
            return OfferCard(offer: offer);
          },
        );
      },
    );
  }

  // Custom font style using Google Fonts
  TextStyle _customFont(double fontSize, FontWeight fontWeight, Color color) {
    return GoogleFonts.montserrat(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // Navigate to the Edit Vehicle page
  void _navigateToEditPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditVehiclePage(vehicle: widget.vehicle),
      ),
    );
  }

  // Navigate to the Duplicate Vehicle page
  void _navigateToDuplicatePage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleUploadScreen(
          vehicle: widget.vehicle,
          isDuplicating: true,
        ),
      ),
    );
  }

  // Calculate the total cost including VAT and flat rate fee
  double _calculateTotalCost(double basePrice) {
    const double vatRate = 0.15;
    const double flatRateFee = 12500.0;
    double subTotal = basePrice + flatRateFee;
    double vat = subTotal * vatRate;
    return subTotal + vat;
  }

  // Format numbers with spaces for better readability
  String _formatNumberWithSpaces(String number) {
    return number.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  // Build action buttons (e.g., Close, Favorite)
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

  // Handle making an offer
  Future<void> _makeOffer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }

      String dealerId = user.uid;
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
        'transportId': transporterId,
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
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error making offer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error submitting offer. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Get display-friendly status text
  String getDisplayStatus(String? offerStatus) {
    switch (offerStatus) {
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
      case 'Issue reported':
        return 'Issue Reported';
      case 'resolved':
        return 'Resolved';
      case 'done':
      case 'Done':
        return 'Done';
      default:
        return offerStatus ?? 'Unknown';
    }
  }

  // Build additional vehicle information
  Widget _buildAdditionalInfo() {
    List<Widget> infoWidgets = [];

    void addInfo(String title, String? value) {
      if (value != null && value.isNotEmpty && value != 'Unknown') {
        if (title == 'Damage Description') {
          infoWidgets.add(_buildInfoRowWithIcon(title, value));
        } else {
          infoWidgets.add(_buildInfoRow(title, value));
        }
      }
    }

    try {
      addInfo('Application', widget.vehicle.application);
      addInfo('Damage Description', widget.vehicle.damageDescription);
      addInfo('Engine Number', widget.vehicle.engineNumber);
      addInfo('Hydraulics', widget.vehicle.hydraluicType);
      // addInfo('Maintenance', widget.vehicle.maintenance);
      addInfo('OEM Inspection', widget.vehicle.maintenance.oemInspectionType);
      addInfo('Registration Number', widget.vehicle.registrationNumber);
      addInfo('Settlement Amount', widget.vehicle.adminData.settlementAmount);
      addInfo('Suspension', widget.vehicle.suspensionType);
      addInfo('VIN Number', widget.vehicle.vinNumber);
      addInfo('Warranty', widget.vehicle.warrentyType);
    } catch (e) {
      print('Error building additional info: $e');
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

  // Build a single information row with an optional info icon
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
          Text(
            value ?? 'Unknown',
            style: _customFont(14, FontWeight.bold, Colors.white),
          ),
        ],
      ),
    );
  }

  // Build a single information row
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

  // Show dialog for damage description
  void _showDamageDescriptionDialog(String? description) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Damage Description',
            style: _customFont(18, FontWeight.bold, Colors.black),
          ),
          content: Text(
            description ?? 'No damage description available.',
            style: _customFont(16, FontWeight.normal, Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'CLOSE',
                style: _customFont(14, FontWeight.bold, Colors.blue),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Build the image gallery
  Widget _buildImageGallery() {
    return SizedBox(
      height: 300,
      child: PageView.builder(
        controller: _pageController,
        itemCount: allPhotos.length,
        onPageChanged: (index) {
          setState(() {
            _currentImageIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Column(
            children: [
              Expanded(
                child: Image.network(
                  allPhotos[index].url,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                allPhotos[index].label,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Build the offer section where users can make an offer
  Widget _buildOfferSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(Icons.close, blue),
            const SizedBox(width: 16),
            _buildActionButton(Icons.favorite, const Color(0xFFFF4E00)),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Make an Offer',
          style: _customFont(20, FontWeight.bold, Colors.white),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          cursorColor: const Color(0xFFFF4E00),
          decoration: InputDecoration(
            hintText: 'R 102 000 000',
            hintStyle: _customFont(24, FontWeight.normal, Colors.grey),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFFF4E00)),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
          ),
          textAlign: TextAlign.center,
          style: _customFont(20, FontWeight.bold, Colors.white),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (value) {
            setState(() {
              if (value.isNotEmpty) {
                try {
                  // Format the input value
                  String formattedValue = _formatNumberWithSpaces(value);
                  _controller.value = _controller.value.copyWith(
                    text: formattedValue,
                    selection:
                        TextSelection.collapsed(offset: formattedValue.length),
                  );

                  // Remove spaces for calculation
                  _offerAmount = double.parse(value.replaceAll(' ', ''));
                  _totalCost = _calculateTotalCost(_offerAmount);
                } catch (e) {
                  print('Error parsing offer amount: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
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
              style: _customFont(18, FontWeight.bold, Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              "including commission and VAT",
              style: _customFont(15, FontWeight.normal, Colors.white),
            ),
            const SizedBox(height: 8),
            // Breakdown of the total cost
            Text(
              "Breakdown:",
              style: _customFont(16, FontWeight.bold, Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              "Base Price: R ${_formatNumberWithSpaces(_offerAmount.toStringAsFixed(0))}",
              style: _customFont(14, FontWeight.normal, Colors.white),
            ),
            Text(
              "Flat Rate Fee: R 12 500",
              style: _customFont(14, FontWeight.normal, Colors.white),
            ),
            Text(
              "Subtotal: R ${_formatNumberWithSpaces((_offerAmount + 12500.0).toStringAsFixed(0))}",
              style: _customFont(14, FontWeight.normal, Colors.white),
            ),
            Text(
              "VAT (15%): R ${_formatNumberWithSpaces(((_offerAmount + 12500.0) * 0.15).toStringAsFixed(0))}",
              style: _customFont(14, FontWeight.normal, Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              "Total Cost: R ${_formatNumberWithSpaces(_totalCost.toStringAsFixed(0))}",
              style: _customFont(14, FontWeight.bold, Colors.white),
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
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'MAKE AN OFFER',
              style: _customFont(20, FontWeight.bold, Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  // Build the offer status display
  Widget _buildOfferStatus() {
    return Center(
      child: Text(
        "Offer Status: ${getDisplayStatus(_offerStatus)}",
        style: _customFont(20, FontWeight.bold, const Color(0xFFFF4E00)),
      ),
    );
  }

  // Build the offers section for transporters
  Widget _buildOffersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Offers Made on This Vehicle:",
          style: _customFont(20, FontWeight.bold, const Color(0xFFFF4E00)),
        ),
        const SizedBox(height: 10),
        _buildOffersList(), // Display all offers
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final bool isTransporter = userProvider.getUserRole == 'transporter';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.vehicle.makeModel.toUpperCase(),
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: blue,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1, // Ensures the text does not overflow
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditVehiclePage(vehicle: widget.vehicle),
                  ),
                );
              },
              icon: const Icon(
                Icons.edit,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        actions: [
          if (isTransporter) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFFFF4E00), size: 24),
              onPressed: _navigateToEditPage,
            ),
            IconButton(
              icon: const Icon(
                Icons.copy,
                color: Color(0xFFFF4E00),
                size: 24,
              ), // Duplicate button
              onPressed: () => _navigateToDuplicatePage(context),
            ),
          ],
        ],
      ),
      backgroundColor: blue,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                _buildImageGallery(), // Display the images
                const SizedBox(height: 16.0),
                _buildAdditionalInfo(), // Display additional info
                const SizedBox(height: 16.0),
                if (!_hasMadeOffer && !isTransporter) _buildOfferSection(),
                if (_hasMadeOffer && !isTransporter) _buildOfferStatus(),
                const SizedBox(height: 16.0),
                if (isTransporter) _buildOffersSection(),
              ],
            ),
            // Loading indicator overlay
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF4E00)),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: 1,
        onItemTapped: (index) {
          setState(() {});
        },
      ),
    );
  }
}
