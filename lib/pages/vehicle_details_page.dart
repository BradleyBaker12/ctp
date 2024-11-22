import 'dart:io';

import 'package:ctp/models/admin_data.dart';
import 'package:ctp/models/chassis.dart';
import 'package:ctp/models/drive_train.dart';
import 'package:ctp/models/external_cab.dart';
import 'package:ctp/models/internal_cab.dart';
import 'package:ctp/models/truck_conditions.dart';
import 'package:ctp/models/tyres.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/editTruckForms/edit_form_navigation.dart';
import 'package:ctp/pages/truckForms/vehilce_upload_screen.dart';
import 'package:flutter/material.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/components/offer_card.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

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
  bool _isMaintenanceInfoExpanded =
      false; // State to track the maintenance info expansion

  List<Widget> maintenanceWidgets = []; // Define maintenanceWidgets here

  bool _isAdminDataExpanded = false; // State to track the admin data expansion

  @override
  void initState() {
    super.initState();
    _checkIfOfferMade();
    _fetchAllDealers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        allPhotos = [];

        // Add main image
        if (widget.vehicle.mainImageUrl != null &&
            widget.vehicle.mainImageUrl!.isNotEmpty) {
          allPhotos.add(PhotoItem(
              url: widget.vehicle.mainImageUrl!, label: 'Main Image'));
        }

        // Add damage photos
        if (widget.vehicle.damagePhotos.isNotEmpty) {
          for (int i = 0; i < widget.vehicle.damagePhotos.length; i++) {
            _addPhotoIfExists(
                widget.vehicle.damagePhotos[i], 'Damage Photo ${i + 1}');
          }
        }

        // Additional photos
        _addPhotoIfExists(widget.vehicle.dashboardPhoto, 'Dashboard Photo');
        _addPhotoIfExists(widget.vehicle.faultCodesPhoto, 'Fault Codes Photo');
        _addPhotoIfExists(widget.vehicle.licenceDiskUrl, 'Licence Disk Photo');
        _addPhotoIfExists(widget.vehicle.mileageImage, 'Mileage Image');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error loading vehicle photos. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
    _pageController = PageController();
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
            child: Text(
              'No offers available for this vehicle',
              style: TextStyle(color: Colors.white),
            ),
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
        builder: (context) => EditFormNavigation(
          vehicle: widget.vehicle,
        ),
      ),
    );
  }

  void _navigateToDuplicatePage() {
    // Create a new vehicle object with only the required fields for duplication
    Vehicle duplicatedVehicle = Vehicle(
      id: '', // New ID will be generated
      brands: widget.vehicle.brands,
      makeModel: widget.vehicle.makeModel,
      year: widget.vehicle.year,
      mileage: '', // Reset mileage
      config: widget.vehicle.config,
      application: widget.vehicle.application,
      transmissionType: widget.vehicle.transmissionType,
      hydraluicType: widget.vehicle.hydraluicType,
      suspensionType: widget.vehicle.suspensionType,
      warrentyType: widget.vehicle.warrentyType,
      maintenance: widget.vehicle.maintenance,
      // Reset specific fields
      vinNumber: '',
      registrationNumber: '',
      engineNumber: '',
      mainImageUrl: '',
      damagePhotos: [],
      damageDescription: '',
      expectedSellingPrice: '',
      userId: FirebaseAuth.instance.currentUser?.uid ?? '', // Current user
      referenceNumber: '', // New reference number will be generated
      dashboardPhoto: '',
      faultCodesPhoto: '',
      licenceDiskUrl: '',
      mileageImage: '',
      photos: [],
      rc1NatisFile: '',
      vehicleType: '',
      warrantyDetails: '',
      createdAt: DateTime.now(),
      vehicleStatus: '',
      vehicleAvailableImmediately: 'false',
      availableDate: DateTime.now().toIso8601String(),
      trailerType: '',
      axles: '',
      trailerLength: '',
      adminData: AdminData(
          settlementAmount: '',
          natisRc1Url: '',
          licenseDiskUrl: '',
          settlementLetterUrl: ''), // Initialize with an empty AdminData object
      truckConditions: TruckConditions(
          externalCab: ExternalCab(
              condition: '',
              damagesCondition: '',
              additionalFeaturesCondition: '',
              images: {},
              damages: [],
              additionalFeatures: []),
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
              images: {},
              damages: [],
              additionalFeatures: [],
              faultCodes: []),
          tyres: {}),
      country: '',
      province: '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleUploadScreen(
          vehicle: duplicatedVehicle,
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
    final bool isTransporter =
        userRole == 'transporter'; // Check if the user is a dealer

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
      case 'rejected':
        return 'Rejected'; // Add rejected status here
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

    void addInfo(String title, dynamic value) {
      if (value != null &&
          value.toString().isNotEmpty &&
          value.toString().toLowerCase() != 'unknown') {
        switch (title) {
          case 'Photos':
            if (value is List<String>) {
              String photosList = value.join('\n');
              infoWidgets.add(_buildInfoRow(title, photosList));
            }
            break;
          case 'Damage Description':
            infoWidgets.add(_buildInfoRowWithIcon(title, value.toString()));
            break;
          default:
            infoWidgets.add(_buildInfoRow(title, value.toString()));
        }
      }
    }

    try {
      // Vehicle Information
      addInfo('Make Model', widget.vehicle.makeModel);
      addInfo('Year', widget.vehicle.year);
      addInfo('Mileage', widget.vehicle.mileage);
      addInfo('VIN Number', widget.vehicle.vinNumber);
      addInfo('Registration Number', widget.vehicle.registrationNumber);

      // Technical Details
      addInfo('Engine Number', widget.vehicle.engineNumber);
      addInfo('Transmission', widget.vehicle.transmissionType);
      addInfo('Configuration', widget.vehicle.config);
      addInfo('Application', widget.vehicle.application);

      // Additional Features
      addInfo('Hydraulics', widget.vehicle.hydraluicType);
      addInfo('Suspension', widget.vehicle.suspensionType);
      addInfo('Warranty', widget.vehicle.warrentyType);

      // Inspection & Maintenance
      addInfo('OEM Inspection', widget.vehicle.maintenance.oemInspectionType);
      addInfo('Damage Description', widget.vehicle.damageDescription);

      // Documentation
      if (widget.vehicle.rc1NatisFile != null &&
          widget.vehicle.rc1NatisFile!.isNotEmpty) {
        infoWidgets.add(_buildInfoRowWithButton(
            'RC1 Natis File', widget.vehicle.rc1NatisFile!));
      }

      // Financial Information
      addInfo('Expected Selling Price', widget.vehicle.expectedSellingPrice);
      addInfo('Settlement Amount', widget.vehicle.adminData.settlementAmount);

      // Photos (if any)
      if (widget.vehicle.photos.isNotEmpty) {
        addInfo('Photos', widget.vehicle.photos);
      }
    } catch (e) {
      print('Error building additional info: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error loading vehicle details. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ...infoWidgets,
        const SizedBox(height: 16),
      ],
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
    // Remove brackets if present
    String displayValue =
        value?.replaceAll('[', '').replaceAll(']', '') ?? 'Unknown';

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
            displayValue,
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

  Widget _buildMaintenanceSection() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String userRole = userProvider.getUserRole;
    final bool isAdmin = userRole == 'admin'; // Check if the user is an admin
    final bool isDealer = userRole == 'dealer'; // Check if the user is a dealer
    final bool isTransporter = userRole == 'transporter';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDealer)
          GestureDetector(
            onTap: () {
              setState(() {
                _isMaintenanceInfoExpanded = !_isMaintenanceInfoExpanded;
              });
            },
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _isMaintenanceInfoExpanded ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.arrow_right,
                    color: const Color(0xFFFF4E00),
                    size: MediaQuery.of(context).size.height * 0.04,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'MAINTENANCE INFO',
                  style: _customFont(20, FontWeight.bold, Colors.blue),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        if (_isMaintenanceInfoExpanded)
          _buildMaintenanceInfo(), // Show maintenance info if expanded
      ],
    );
  }

  Widget _buildMaintenanceInfo() {
    maintenanceWidgets.clear();

    final maintenanceData = widget.vehicle.maintenance;

    // Debug prints for all maintenance data fields
    // print('=== MAINTENANCE DATA DEBUG ===');
    // print('Vehicle ID: ${maintenanceData.vehicleId}');
    // print('OEM Inspection Type: ${maintenanceData.oemInspectionType}');
    // print('Maintenance Selection: ${maintenanceData.maintenanceSelection}');
    // print('Warranty Selection: ${maintenanceData.warrantySelection}');
    // print('Maintenance Doc URL: ${maintenanceData.maintenanceDocUrl}');
    // print('Warranty Doc URL: ${maintenanceData.warrantyDocUrl}');
    // print('Last Updated: ${maintenanceData.lastUpdated}');
    // print('=== END MAINTENANCE DEBUG ===');

    // Add inspection type info
    if (maintenanceData.oemInspectionType != null) {
      print('Adding Inspection Type to widgets');
      maintenanceWidgets.add(
          _buildInfoRow('Inspection Type', maintenanceData.oemInspectionType!));
    }

    // Add maintenance selection info
    if (maintenanceData.maintenanceSelection != null) {
      print('Adding Maintenance Selection to widgets');
      maintenanceWidgets.add(_buildInfoRow(
          'Maintenance Selection', maintenanceData.maintenanceSelection!));
    }

    // Add warranty selection info
    if (maintenanceData.warrantySelection != null) {
      print('Adding Warranty Selection to widgets');
      maintenanceWidgets.add(_buildInfoRow(
          'Warranty Selection', maintenanceData.warrantySelection!));
    }

    // Add maintenance document link
    if (maintenanceData.maintenanceDocUrl?.isNotEmpty ?? false) {
      print('Adding Maintenance Document URL to widgets');
      maintenanceWidgets.add(_buildInfoRowWithButton(
          'Maintenance Document', maintenanceData.maintenanceDocUrl!));
    }

    // Add warranty document link
    if (maintenanceData.warrantyDocUrl?.isNotEmpty ?? false) {
      print('Adding Warranty Document URL to widgets');
      maintenanceWidgets.add(_buildInfoRowWithButton(
          'Warranty Document', maintenanceData.warrantyDocUrl!));
    }

    print('Total maintenance widgets created: ${maintenanceWidgets.length}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: maintenanceWidgets,
    );
  }

  void _viewDocument(String url) async {
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      // Get temporary directory to store the PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'document_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';

      // Download the PDF file
      final response = await http.get(Uri.parse(url));
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Hide loading indicator
      setState(() {
        _isLoading = false;
      });

      // Navigate to PDF viewer
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFView(
              filePath: filePath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoRowWithButton(String title, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: _customFont(14, FontWeight.normal, Colors.white),
          ),
          TextButton(
            onPressed: () {
              _viewDocument(url); // Call the method to view the document
            },
            child: const Text(
              'View',
              style: TextStyle(
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminDataSection() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String userRole = userProvider.getUserRole;
    final bool isAdmin = userRole == 'admin'; // Check if the user is an admin
    final bool isDealer = userRole == 'dealer'; // Check if the user is a dealer

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDealer)
          GestureDetector(
            onTap: () {
              setState(() {
                _isAdminDataExpanded = !_isAdminDataExpanded;
              });
            },
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _isAdminDataExpanded ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.arrow_right,
                    color: const Color(0xFFFF4E00),
                    size: MediaQuery.of(context).size.height * 0.04,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'ADMIN INFO',
                  style: _customFont(20, FontWeight.bold, Colors.blue),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        if (_isAdminDataExpanded)
          _buildAdminDataInfo(), // Show admin data if expanded
      ],
    );
  }

  Widget _buildAdminDataInfo() {
    List<Widget> adminDataWidgets = [];

    void addAdminData(String title, String? value, {bool isDocument = false}) {
      if (value != null && value.isNotEmpty) {
        adminDataWidgets.add(
          _buildInfoRowWithButton(title, value), // Use the button row for URLs
        );
      }
    }

    try {
      addAdminData(
          'Settlement Amount', widget.vehicle.adminData.settlementAmount);
      addAdminData('Natis RC1 URL', widget.vehicle.adminData.natisRc1Url,
          isDocument: true);
      addAdminData(
          'Settlement Letter URL', widget.vehicle.adminData.settlementLetterUrl,
          isDocument: true);
      addAdminData('License Disk URL', widget.vehicle.adminData.licenseDiskUrl,
          isDocument: true);
    } catch (e) {
      print('Error building admin data info: $e'); // Debug statement
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error loading admin data. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: adminDataWidgets, // Use the populated list here
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    final userProvider = Provider.of<UserProvider>(context);
    final String userRole = userProvider.getUserRole;
    final bool isAdmin = userRole == 'admin'; // Check if the user is an admin
    final bool isDealer = userRole == 'dealer'; // Check if the user is a dealer
    final bool isTransporter =
        userRole == 'transporter'; // Check if the user is a dealer

    var blue = const Color(0xFF2F7FFF);

    final size = MediaQuery.of(context).size;

    // Debug statement to check if user is admin
    print('Is Admin: $isAdmin');
    print('Is Dealer: $isDealer');

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
                "${widget.vehicle.brands.join(', ')} ${widget.vehicle.makeModel.toString().toUpperCase()} ${widget.vehicle.year}",
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
                _navigateToDuplicatePage();
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
                          _buildInfoContainer(
                              'YEAR', widget.vehicle.year.toString()),
                          const SizedBox(width: 5),
                          _buildInfoContainer(
                              'MILEAGE', widget.vehicle.mileage),
                          const SizedBox(width: 5),
                          _buildInfoContainer(
                              'GEARBOX', widget.vehicle.transmissionType),
                          const SizedBox(width: 5),
                          _buildInfoContainer('CONFIG', widget.vehicle.config),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if ((isAdmin || isDealer) &&
                          (!_hasMadeOffer ||
                              _offerStatus ==
                                  'rejected')) // Allow making another offer if rejected
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
                      else if ((isAdmin || isDealer) && !_hasMadeOffer)
                        Center(
                          child: Text(
                            "Offer Status: ${getDisplayStatus(_offerStatus)}",
                            style: _customFont(
                                20, FontWeight.bold, const Color(0xFFFF4E00)),
                          ),
                        ),
                      const SizedBox(height: 40),
                      if (isDealer)
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
                      // if (isDealer)
                      if (_isAdditionalInfoExpanded) _buildAdditionalInfo(),
                      _buildMaintenanceSection(),
                      _buildAdminDataSection(),
                      _buildTruckConditionsSection(),
                      const SizedBox(height: 30),
                      if (isTransporter)
                        Column(children: [
                          Text(
                            "Offers Made on This Vehicle (${widget.vehicle.referenceNumber}):",
                            style: _customFont(
                                20, FontWeight.bold, const Color(0xFFFF4E00)),
                          ),
                          const SizedBox(height: 10),
                          _buildOffersList(), // Display all offers for transporters
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
          : isDealer
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

  // Update the indicator sizing in _buildImageIndicators method
  Widget _buildImageIndicators(int numImages) {
    var screenSize = MediaQuery.of(context).size;
    // Calculate available width within the carousel area
    double availableWidth =
        screenSize.width - (MediaQuery.of(context).size.height * 0.07);
    // Dynamic width calculation based on number of images
    double indicatorWidth = (availableWidth / (numImages * 2));
    // Tighter constraints for minimum and maximum widths
    indicatorWidth = indicatorWidth.clamp(3.0, 20.0);

    return SizedBox(
      width: availableWidth,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(numImages, (index) {
          return Container(
            width: indicatorWidth,
            height: screenSize.height * 0.003,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: index == _currentImageIndex
                  ? Colors.deepOrange
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.white, width: 1),
            ),
          );
        }),
      ),
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

  bool _isTruckConditionsExpanded =
      false; // Add this with other state variables

  Widget _buildTruckConditionsSection() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String userRole = userProvider.getUserRole;
    final bool isDealer = userRole == 'dealer';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDealer)
          GestureDetector(
            onTap: () {
              setState(() {
                _isTruckConditionsExpanded = !_isTruckConditionsExpanded;
              });
            },
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _isTruckConditionsExpanded ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.arrow_right,
                    color: const Color(0xFFFF4E00),
                    size: MediaQuery.of(context).size.height * 0.04,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'TRUCK CONDITIONS',
                  style: _customFont(20, FontWeight.bold, Colors.blue),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
        if (_isTruckConditionsExpanded) _buildTruckConditionsInfo(),
      ],
    );
  }

  bool _isExternalCabExpanded = false;
  bool _isInternalCabExpanded = false;
  bool _isChassisExpanded = false;
  bool _isDriveTrainExpanded = false;
  bool _isTyresExpanded = false;

  Widget _buildTruckConditionsInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // External Cab Section
        _buildSubSection(
          'External Cab',
          _isExternalCabExpanded,
          () =>
              setState(() => _isExternalCabExpanded = !_isExternalCabExpanded),
          _buildExternalCabInfo(),
        ),

        // Internal Cab Section
        _buildSubSection(
          'Internal Cab',
          _isInternalCabExpanded,
          () =>
              setState(() => _isInternalCabExpanded = !_isInternalCabExpanded),
          _buildInternalCabInfo(),
        ),

        // Chassis Section
        _buildSubSection(
          'Chassis',
          _isChassisExpanded,
          () => setState(() => _isChassisExpanded = !_isChassisExpanded),
          _buildChassisInfo(),
        ),

        // Drive Train Section
        _buildSubSection(
          'Drive Train',
          _isDriveTrainExpanded,
          () => setState(() => _isDriveTrainExpanded = !_isDriveTrainExpanded),
          _buildDriveTrainInfo(),
        ),

        // Tyres Section
        _buildSubSection(
          'Tyres',
          _isTyresExpanded,
          () => setState(() => _isTyresExpanded = !_isTyresExpanded),
          _buildTyresInfo(),
        ),
      ],
    );
  }

  Widget _buildSubSection(
      String title, bool isExpanded, VoidCallback onTap, Widget content) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                const SizedBox(width: 20),
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.arrow_right,
                      color: Color(0xFFFF4E00), size: 24),
                ),
                const SizedBox(width: 8),
                Text(title,
                    style: _customFont(
                        16, FontWeight.bold, const Color(0xFF2F7FFF))),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: content,
          ),
      ],
    );
  }

  // Update the _buildExternalCabInfo() method
  // Update the _buildExternalCabInfo() method
  Widget _buildExternalCabInfo() {
    List<Widget> widgets = [];
    final externalCab = widget.vehicle.truckConditions.externalCab;

    // Add condition information first
    widgets.add(_buildInfoRow('Condition', externalCab.condition));
    widgets.add(_buildInfoRow('Damages', externalCab.damagesCondition));
    widgets.add(_buildInfoRow(
        'Additional Features', externalCab.additionalFeaturesCondition));

    // Add damages section
    if (externalCab.damages.isNotEmpty) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(Text('Damages:',
          style: _customFont(16, FontWeight.bold, Colors.white)));
      for (var damage in externalCab.damages) {
        widgets.add(_buildInfoRow('Location', damage.imageUrl));
        widgets.add(_buildInfoRow('Description', damage.description));
      }
    }

    // Add additional features section
    if (externalCab.additionalFeatures.isNotEmpty) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(Text('Additional Features:',
          style: _customFont(16, FontWeight.bold, Colors.white)));
      for (var feature in externalCab.additionalFeatures) {
        widgets.add(_buildInfoRow('Feature', feature.description));
      }
    }

    // Add image carousel at the bottom
    if (externalCab.images.isNotEmpty) {
      List<PhotoItem> externalPhotos = [];
      externalCab.images.forEach((key, photoData) {
        if (photoData.path.isNotEmpty && File(photoData.path).existsSync()) {
          externalPhotos.add(PhotoItem(url: photoData.path, label: key));
        }
      });

      if (externalPhotos.isNotEmpty) {
        widgets.add(const SizedBox(height: 20));
        widgets.add(
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Stack(
              children: [
                // Blue box on the left edge of screen
                // Positioned(
                //   left: 0,
                //   top: 0,
                //   bottom: 0,
                //   child: ClipRRect(
                //     borderRadius: const BorderRadius.only(
                //       topRight: Radius.circular(10.0),
                //       bottomRight: Radius.circular(10.0),
                //     ),
                //     child: Container(
                //       width: MediaQuery.of(context).size.height * 0.025,
                //       color: const Color(0xFF2F7FFF),
                //     ),
                //   ),
                // ),
                // // Blue box on the right edge of screen
                // Positioned(
                //   right: 0,
                //   top: 0,
                //   bottom: 0,
                //   child: ClipRRect(
                //     borderRadius: const BorderRadius.only(
                //       topLeft: Radius.circular(10.0),
                //       bottomLeft: Radius.circular(10.0),
                //     ),
                //     child: Container(
                //       width: MediaQuery.of(context).size.height * 0.025,
                //       color: const Color(0xFF2F7FFF),
                //     ),
                //   ),
                // ),
                // Carousel with padding
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.height * 0.025,
                  ),
                  child: SizedBox(
                    height: 200,
                    child: Stack(
                      children: [
                        PageView.builder(
                          itemCount: externalPhotos.length,
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
                                    externalPhotos[index].url,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/default_vehicle_image.png',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
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
                                      externalPhotos[index].label,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: _buildImageIndicators(externalPhotos.length),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _buildInternalCabInfo() {
    List<Widget> widgets = [];
    final internalCab = widget.vehicle.truckConditions.internalCab;

    // Add condition information first
    widgets.add(_buildInfoRow('Condition', internalCab.condition));
    widgets
        .add(_buildInfoRow('Damages Condition', internalCab.damagesCondition));
    widgets.add(_buildInfoRow('Additional Features Condition',
        internalCab.additionalFeaturesCondition));
    widgets.add(_buildInfoRow(
        'Fault Codes Condition', internalCab.faultCodesCondition));

    // Add damages section
    if (internalCab.damages.isNotEmpty) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(Text('Damages:',
          style: _customFont(16, FontWeight.bold, Colors.white)));
      for (var damage in internalCab.damages) {
        widgets.add(_buildInfoRow('Location', damage.imageUrl));
        widgets.add(_buildInfoRow('Description', damage.description));
      }
    }

    // Add additional features section
    if (internalCab.additionalFeatures.isNotEmpty) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(Text('Additional Features:',
          style: _customFont(16, FontWeight.bold, Colors.white)));
      for (var feature in internalCab.additionalFeatures) {
        widgets.add(_buildInfoRow('Feature', feature.description));
      }
    }

    // Add fault codes section
    if (internalCab.faultCodes.isNotEmpty) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(Text('Fault Codes:',
          style: _customFont(16, FontWeight.bold, Colors.white)));
      for (var code in internalCab.faultCodes) {
        widgets.add(_buildInfoRow('Code', code.toString()));
      }
    }

    // Inside _buildInternalCabInfo() method:

// Add image carousel at the bottom
    if (internalCab.viewImages.isNotEmpty) {
      List<PhotoItem> internalPhotos = [];
      internalCab.viewImages.forEach((key, photoData) {
        if (photoData.path.isNotEmpty) {
          internalPhotos.add(PhotoItem(url: photoData.path, label: key));
        }
      });

      if (internalPhotos.isNotEmpty) {
        widgets.add(const SizedBox(height: 20));
        widgets.add(
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Stack(
              children: [
                // Blue box on the left edge of screen
                // Positioned(
                //   left: 0,
                //   top: 0,
                //   bottom: 0,
                //   child: ClipRRect(
                //     borderRadius: const BorderRadius.only(
                //       topRight: Radius.circular(10.0),
                //       bottomRight: Radius.circular(10.0),
                //     ),
                //     child: Container(
                //       width: MediaQuery.of(context).size.height * 0.025,
                //       color: const Color(0xFF2F7FFF),
                //     ),
                //   ),
                // ),
                // // Blue box on the right edge of screen
                // Positioned(
                //   right: 0,
                //   top: 0,
                //   bottom: 0,
                //   child: ClipRRect(
                //     borderRadius: const BorderRadius.only(
                //       topLeft: Radius.circular(10.0),
                //       bottomLeft: Radius.circular(10.0),
                //     ),
                //     child: Container(
                //       width: MediaQuery.of(context).size.height * 0.025,
                //       color: const Color(0xFF2F7FFF),
                //     ),
                //   ),
                // ),
                // Carousel with padding
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.height * 0.025,
                  ),
                  child: SizedBox(
                    height: 200,
                    child: Stack(
                      children: [
                        PageView.builder(
                          itemCount: internalPhotos.length,
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
                                    internalPhotos[index].url,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/default_vehicle_image.png',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
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
                                      internalPhotos[index].label,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width *
                                  0.8, // Limit width to 80% of screen
                              child:
                                  _buildImageIndicators(internalPhotos.length),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _buildChassisInfo() {
    List<Widget> widgets = [];
    final chassis = widget.vehicle.truckConditions.chassis;

    // Add basic condition information
    widgets.add(_buildInfoRow('Condition', chassis.condition));
    widgets.add(_buildInfoRow('Damages Condition', chassis.damagesCondition));
    widgets.add(_buildInfoRow(
        'Additional Features', chassis.additionalFeaturesCondition));

    // Add damages section if present
    if (chassis.damages.isNotEmpty) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(Text('Damages:',
          style: _customFont(16, FontWeight.bold, Colors.white)));
      for (var damage in chassis.damages) {
        widgets.add(_buildInfoRow('Location', damage.imageUrl));
        widgets.add(_buildInfoRow('Description', damage.description));
      }
    }

    // Add additional features section if present
    if (chassis.additionalFeatures.isNotEmpty) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(Text('Additional Features:',
          style: _customFont(16, FontWeight.bold, Colors.white)));
      for (var feature in chassis.additionalFeatures) {
        widgets.add(_buildInfoRow('Feature', feature.description));
      }
    }

    // Add chassis images carousel
    if (chassis.images.isNotEmpty) {
      List<PhotoItem> chassisPhotos = [];
      chassis.images.forEach((key, imageData) {
        if (imageData.path.isNotEmpty) {
          chassisPhotos.add(PhotoItem(url: imageData.path, label: key));
        }
      });

      if (chassisPhotos.isNotEmpty) {
        widgets.add(const SizedBox(height: 20));
        widgets.add(
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.height * 0.025,
                  ),
                  child: SizedBox(
                    height: 200,
                    child: Stack(
                      children: [
                        PageView.builder(
                          itemCount: chassisPhotos.length,
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
                                    chassisPhotos[index].url,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/default_vehicle_image.png',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
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
                                      chassisPhotos[index].label,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: _buildImageIndicators(chassisPhotos.length),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _buildDriveTrainInfo() {
    List<Widget> widgets = [];
    final driveTrain = widget.vehicle.truckConditions.driveTrain;

    void addInfo(String title, String? value) {
      if (value != null && value.isNotEmpty) {
        widgets.add(_buildInfoRow(title, value));
      }
    }

    // Damages section
    if (driveTrain.damages.isNotEmpty) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(Text('Damages:',
          style: _customFont(16, FontWeight.bold, Colors.white)));
      for (var damage in driveTrain.damages) {
        widgets.add(_buildInfoRow('Location', damage.imageUrl));
        widgets.add(_buildInfoRow('Description', damage.description));
      }
    }

    // Additional features section
    if (driveTrain.additionalFeatures.isNotEmpty) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(Text('Additional Features:',
          style: _customFont(16, FontWeight.bold, Colors.white)));
      for (var feature in driveTrain.additionalFeatures) {
        widgets.add(_buildInfoRow('Feature', feature.description));
      }
    }

    // Images carousel
    // Update the images check in _buildDriveTrainInfo
    if (driveTrain.images.isNotEmpty) {
      List<PhotoItem> driveTrainPhotos = [];
      driveTrain.images.forEach((key, imageData) {
        if (imageData is Map &&
            imageData['path'] != null &&
            imageData['path'].toString().isNotEmpty) {
          driveTrainPhotos
              .add(PhotoItem(url: imageData['path'].toString(), label: key));
        }
      });

      if (driveTrainPhotos.isNotEmpty) {
        widgets.add(
          SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.height * 0.025,
                  ),
                  child: SizedBox(
                    height: 200,
                    child: Stack(
                      children: [
                        PageView.builder(
                          itemCount: driveTrainPhotos.length,
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
                                    driveTrainPhotos[index].url,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/default_vehicle_image.png',
                                        fit: BoxFit.cover,
                                        width: double.infinity,
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
                                      driveTrainPhotos[index].label,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child:
                                _buildImageIndicators(driveTrainPhotos.length),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        widgets.add(const SizedBox(height: 20));
      }
    }

    // Basic condition information
    widgets.add(_buildInfoRow('Condition', driveTrain.condition));
    widgets.add(
        _buildInfoRow('Oil Leak Engine', driveTrain.oilLeakConditionEngine));
    widgets.add(_buildInfoRow(
        'Water Leak Engine', driveTrain.waterLeakConditionEngine));
    widgets.add(_buildInfoRow('Blowby Condition', driveTrain.blowbyCondition));
    widgets.add(
        _buildInfoRow('Oil Leak Gearbox', driveTrain.oilLeakConditionGearbox));
    widgets
        .add(_buildInfoRow('Retarder Condition', driveTrain.retarderCondition));

    // Damages section
    if (driveTrain.damages.isNotEmpty) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(Text('Damages:',
          style: _customFont(16, FontWeight.bold, Colors.white)));
      for (var damage in driveTrain.damages) {
        widgets.add(_buildInfoRow('Location', damage.imageUrl));
        widgets.add(_buildInfoRow('Description', damage.description));
      }
    }

    // Additional features section
    if (driveTrain.additionalFeatures.isNotEmpty) {
      widgets.add(const SizedBox(height: 16));
      widgets.add(Text('Additional Features:',
          style: _customFont(16, FontWeight.bold, Colors.white)));
      for (var feature in driveTrain.additionalFeatures) {
        widgets.add(_buildInfoRow('Feature', feature.description));
      }
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _buildTyresInfo() {
    List<Widget> widgets = [];
    print(
        "DEBUG - Truck Conditions Tyres: ${widget.vehicle.truckConditions.tyres}");
    print(
        "DEBUG - Tyres Data: ${widget.vehicle.truckConditions.tyres['tyres']}");
    print(
        "DEBUG - Tyres Positions: ${widget.vehicle.truckConditions.tyres['tyres']?.positions}");

    Map<String, Tyres> tyresMap = widget.vehicle.truckConditions.tyres;
    if (tyresMap.isEmpty || !tyresMap.containsKey('tyres')) {
      return const Center(
        child: Text(
          'No tyre information available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    Tyres tyresData = tyresMap['tyres']!;
    List<PhotoItem> tyrePhotos = [];

    tyresData.positions.forEach((positionKey, tyrePosition) {
      print("DEBUG - Processing position: $positionKey");
      print("DEBUG - Position data: $tyrePosition");

      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            positionKey.replaceAll('_', ' '),
            style: _customFont(18, FontWeight.bold, const Color(0xFF2F7FFF)),
          ),
        ),
      );

      widgets.add(
          _buildInfoRow('Chassis Condition', tyrePosition.chassisCondition));
      widgets.add(_buildInfoRow('Rim Type', tyrePosition.rimType));
      widgets.add(_buildInfoRow('Virgin/Recap', tyrePosition.virginOrRecap));
      widgets.add(_buildInfoRow('New Tyre', tyrePosition.isNew));

      if (tyrePosition.imagePath.isNotEmpty) {
        tyrePhotos
            .add(PhotoItem(url: tyrePosition.imagePath, label: positionKey));

        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            height: 200,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () =>
                      _showFullScreenImage(context, tyrePhotos.length - 1),
                  child: Image.network(
                    tyrePosition.imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/default_vehicle_image.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: Colors.black54,
                    child: Text(
                      positionKey,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      widgets.add(const Divider(color: Colors.grey));
    });

    if (widgets.isEmpty) {
      return const Center(
        child: Text(
          'No tyre positions found',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
