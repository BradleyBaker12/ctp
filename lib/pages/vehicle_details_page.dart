// vehicle_details_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/offer_card.dart';
import 'package:ctp/models/admin_data.dart';
import 'package:ctp/models/chassis.dart';
import 'package:ctp/models/drive_train.dart';
import 'package:ctp/models/external_cab.dart';
import 'package:ctp/models/internal_cab.dart';
import 'package:ctp/models/truck_conditions.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/editTruckForms/basic_information_edit.dart';
import 'package:ctp/pages/editTruckForms/edit_form_navigation.dart';
import 'package:ctp/pages/editTruckForms/maintenance_edit_section.dart';
import 'package:ctp/pages/editTruckForms/truck_conditions_tabs_edit_page.dart';
import 'package:ctp/pages/setup_collection.dart';
import 'package:ctp/pages/setup_inspection.dart';
import 'package:ctp/pages/trailerForms/edit_trailer_upload_screen.dart';
import 'package:ctp/pages/truckForms/vehilce_upload_screen.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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
  Vehicle? _vehicle;
  Vehicle get vehicle => _vehicle ?? widget.vehicle;
  set vehicle(Vehicle value) {
    setState(() {
      _vehicle = value;
    });
  }

  bool isInspectionComplete = false;
  bool isCollectionComplete = false;

  final TextEditingController _controller = TextEditingController();
  double _totalCost = 0.0;
  int _currentImageIndex = 0;
  bool _isLoading = false;
  double _offerAmount = 0.0;
  bool _hasMadeOffer = false;
  bool _canMakeOffer = true; // <-- Controls whether a new offer can be made

  final bool _isAdditionalInfoExpanded = true; // Not currently used in UI
  List<PhotoItem> allPhotos = [];
  late PageController _pageController;
  String _offerStatus = 'in-progress'; // Default status for the offer

  // New state variables for admin functionality
  Dealer? _selectedDealer;
  bool _isDealersLoading = false;

  // Example expansions (if you need them in the future, uncomment them):
  // bool _isMaintenanceInfoExpanded = false;
  // bool _isAdminDataExpanded = false;
  // bool _isTruckConditionsExpanded = false;
  // bool _isExternalCabExpanded = false;
  // bool _isInternalCabExpanded = false;
  // bool _isChassisExpanded = false;
  // bool _isDriveTrainExpanded = false;
  // bool _isTyresExpanded = false;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;

    // Check if this vehicle has already been accepted => No new offers allowed
    _checkOfferAvailability();

    // Check if the logged-in user (dealer) has already made an offer
    _checkIfOfferMade();

    // If admin/sales, we fetch all dealers (for making an offer on their behalf)
    _fetchAllDealers();

    // Check if the vehicle's inspection/collection setup is complete
    _checkSetupStatus();

    // Prepare photos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        allPhotos = [];

        // Add main image
        if (widget.vehicle.mainImageUrl != null &&
            widget.vehicle.mainImageUrl!.isNotEmpty) {
          allPhotos.add(
            PhotoItem(url: widget.vehicle.mainImageUrl!, label: 'Main Image'),
          );
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

        // Additional single photos
        _addPhotoIfExists(widget.vehicle.dashboardPhoto, 'Dashboard Photo');
        _addPhotoIfExists(widget.vehicle.faultCodesPhoto, 'Fault Codes Photo');
        _addPhotoIfExists(widget.vehicle.licenceDiskUrl, 'Licence Disk Photo');
        _addPhotoIfExists(widget.vehicle.mileageImage, 'Mileage Image');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error Loading Vehicle Details. Please Try Again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
    _pageController = PageController();
  }

  // Check if the vehicle has been accepted (meaning no new offers allowed)
  Future<void> _checkOfferAvailability() async {
    try {
      final vehicleDoc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicle.id)
          .get();

      if (vehicleDoc.exists) {
        final bool isAccepted = vehicleDoc.data()?['isAccepted'] ?? false;
        if (isAccepted) {
          setState(() {
            _canMakeOffer = false;
          });
        }
      }
    } catch (e) {
      print('Error checking vehicle acceptance: $e');
    }
  }

  // Check if the logged-in dealer made an offer on this vehicle
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
          _offerStatus =
              offersSnapshot.docs.first['offerStatus'] ?? 'in-progress';
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

  // Fetch all dealers (admin/sales can make an offer on behalf of these dealers)
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

  // Helper function: add photo to gallery if it's not empty
  void _addPhotoIfExists(String? photoUrl, String photoLabel) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      allPhotos.add(PhotoItem(url: photoUrl, label: photoLabel));
      print('$photoLabel Added: $photoUrl');
    } else {
      print('$photoLabel is null or empty');
    }
  }

  // For transporters: retrieve all offers on this vehicle
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

  // Renders the list of offers made for this vehicle
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

        // Sort offers by createdAt (descending)
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

  // Apply Montserrat style to text
  TextStyle _customFont(double fontSize, FontWeight fontWeight, Color color) {
    return GoogleFonts.montserrat(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // Navigate to the relevant edit pages
  Future<void> _navigateToEditPage() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isAdmin = (userProvider.getUserRole == 'admin');
    final bool isSalesRep =
        (userProvider.getUserRole == 'sales representative');
    final bool isAdminOrSalesRep = isAdmin || isSalesRep;

    // If the vehicle is a trailer, go to EditTrailerUploadScreen
    if (widget.vehicle.vehicleType.toLowerCase() == 'trailer') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditTrailerUploadScreen(
            isDuplicating: false,
            isNewUpload: false,
            isAdminUpload: isAdminOrSalesRep,
            vehicle: widget.vehicle,
          ),
        ),
      );
    } else {
      // Otherwise, go to the regular truck edit forms
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditFormNavigation(vehicle: widget.vehicle),
        ),
      );
    }

    setState(() {}); // Refresh the page after returning
  }

  // Return a more "human-friendly" status label
  String getDisplayStatus(String? offerStatus) {
    switch (offerStatus?.toLowerCase()) {
      case 'in-progress':
        return 'Offer Made';
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

  // Duplicates a vehicle (for Transporters)
  void _navigateToDuplicatePage() {
    // Create a new vehicle object with only the required fields for duplication
    Vehicle duplicatedVehicle = Vehicle(
      id: '',
      isAccepted: widget.vehicle.isAccepted,
      acceptedOfferId: widget.vehicle.acceptedOfferId,
      brands: widget.vehicle.brands,
      makeModel: widget.vehicle.makeModel,
      year: widget.vehicle.year,
      mileage: '',
      config: widget.vehicle.config,
      application: widget.vehicle.application,
      transmissionType: widget.vehicle.transmissionType,
      hydraluicType: widget.vehicle.hydraluicType,
      suspensionType: widget.vehicle.suspensionType,
      warrentyType: widget.vehicle.warrentyType,
      maintenance: widget.vehicle.maintenance,
      vinNumber: '',
      registrationNumber: '',
      engineNumber: '',
      mainImageUrl: '',
      damagePhotos: [],
      damageDescription: '',
      expectedSellingPrice: '',
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      referenceNumber: '',
      dashboardPhoto: '',
      faultCodesPhoto: '',
      licenceDiskUrl: '',
      mileageImage: '',
      photos: [],
      rc1NatisFile: '',
      vehicleType: '', // Will remain blank if duplicating
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
        settlementLetterUrl: '',
      ),
      truckConditions: TruckConditions(
        externalCab: ExternalCab(
          condition: '',
          damagesCondition: '',
          additionalFeaturesCondition: '',
          images: {},
          damages: [],
          additionalFeatures: [],
        ),
        internalCab: InternalCab(
          condition: '',
          damagesCondition: '',
          additionalFeaturesCondition: '',
          faultCodesCondition: '',
          viewImages: {},
          damages: [],
          additionalFeatures: [],
          faultCodes: [],
        ),
        chassis: Chassis(
          condition: '',
          damagesCondition: '',
          additionalFeaturesCondition: '',
          images: {},
          damages: [],
          additionalFeatures: [],
        ),
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
          faultCodes: [],
        ),
        tyres: {},
      ),
      country: '',
      province: '',
      length: '',
      vinTrailer: '',
      damagesDescription: '',
      additionalFeatures: '',
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

  // Calculation logic for final cost (incl. commission and VAT)
  double _calculateTotalCost(double basePrice) {
    const double vatRate = 0.15;
    const double flatRateFee = 12500.0;
    double subTotal = basePrice + flatRateFee;
    double vat = subTotal * vatRate;
    return subTotal + vat;
  }

  // Utility to format large numbers with spaces
  String _formatNumberWithSpaces(String number) {
    return number.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  // Action buttons at the top row (close/favorite icons)
  Widget _buildActionButton(IconData icon, Color backgroundColor) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (icon == Icons.close) {
            Navigator.pop(context);
          } else if (icon == Icons.favorite) {
            // Add to favorites
            FirebaseFirestore.instance
                .collection('favorites')
                .doc(
                  '${FirebaseAuth.instance.currentUser?.uid}_${widget.vehicle.id}',
                )
                .set({
              'userId': FirebaseAuth.instance.currentUser?.uid,
              'vehicleId': widget.vehicle.id,
              'createdAt': DateTime.now(),
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Added to favorites'),
                backgroundColor: Color(0xFFFF4E00),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.black,
            size: 24,
          ),
        ),
      ),
    );
  }

  // Making an offer
  Future<void> _makeOffer() async {
    // If vehicle is already accepted, prevent new offer
    if (!_canMakeOffer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'This vehicle is already accepted. Cannot make a new offer.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String userRole = userProvider.getUserRole;
    final bool isAdmin = userRole == 'admin';
    final bool isSalesRep = userRole == 'sales representative';
    final bool isDealer = userRole == 'dealer';

    // Validate offer amount
    if (_offerAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Offer Amount. Please Enter a Valid Number.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Ensure dealer is selected if user is admin or sales rep
    if ((isAdmin || isSalesRep) && _selectedDealer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please select a dealer to make an offer on behalf of.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check dealer’s docs/verification if dealer is making the offer
    if (isDealer) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot dealerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (!dealerDoc.exists) return;

        bool isVerified = dealerDoc.get('isVerified') ?? false;
        bool hasDocuments =
            await userProvider.hasDealerUploadedRequiredDocuments(user.uid);
        String accountStatus =
            dealerDoc.get('accountStatus')?.toString().toLowerCase() ?? '';

        if (!isVerified || !hasDocuments || accountStatus != 'active') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Please upload all required documents and wait for account approval.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pushNamed(context, '/profile'); // Navigate to doc upload
          return;
        }
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Prepare offer details
      String dealerId = (isAdmin || isSalesRep)
          ? _selectedDealer!.id
          : isDealer
              ? user.uid
              : '';
      String vehicleId = widget.vehicle.id;
      String transporterId = widget.vehicle.userId;
      DateTime createdAt = DateTime.now();

      // Add offer to Firestore
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

      // Reset offer state and notify user
      _controller.clear();
      setState(() {
        _totalCost = 0.0;
        _offerAmount = 0.0;
        _hasMadeOffer = true;
        _offerStatus = 'in-progress';
        if (isAdmin || isSalesRep) {
          final dealers = userProvider.dealers;
          _selectedDealer = dealers.isNotEmpty ? dealers.first : null;
        }
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

  // Setup inspection steps
  Future<void> _setupInspection() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetupInspectionPage(
          vehicleId: widget.vehicle.id,
        ),
      ),
    );
  }

  // Setup collection steps
  Future<void> _setupCollection() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetupCollectionPage(
          vehicleId: widget.vehicle.id,
        ),
      ),
    );
  }

  // Check if the vehicle’s inspection/collection is completed
  Future<void> _checkSetupStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicle.id)
          .get();

      if (doc.exists) {
        setState(() {
          isInspectionComplete = doc.data()?['isInspectionComplete'] ?? false;
          isCollectionComplete = doc.data()?['isCollectionComplete'] ?? false;
        });
      }
    } catch (e) {
      print('Error checking setup status: $e');
    }
  }

  // Example placeholders for progress calculations
  int _calculateBasicInfoProgress() {
    int completedSteps = 0;
    if (vehicle.mainImageUrl != null && vehicle.mainImageUrl!.isNotEmpty) {
      completedSteps++;
    }
    // Add more checks if needed...
    completedSteps += 3; // Placeholder
    return completedSteps;
  }

  int _calculateMaintenanceProgress() {
    int completedSteps = 0;
    if (vehicle.maintenance.maintenanceDocUrl != null &&
        vehicle.maintenance.maintenanceDocUrl!.isNotEmpty) {
      completedSteps++;
    }
    // Suppose 4 total steps...
    return completedSteps;
  }

  int _calculateTruckConditionsProgress() {
    return _calculateExternalCabProgress() +
        _calculateInternalCabProgress() +
        _calculateDriveTrainProgress() +
        _calculateChassisProgress() +
        _calculateTyresProgress();
  }

  int _calculateExternalCabProgress() {
    int completedSteps = 0;
    final externalCab = vehicle.truckConditions.externalCab;
    if (externalCab.condition.isNotEmpty) completedSteps++;
    return completedSteps;
  }

  int _calculateInternalCabProgress() {
    int completedSteps = 0;
    final internalCab = vehicle.truckConditions.internalCab;
    if (internalCab.condition.isNotEmpty) completedSteps++;
    return completedSteps;
  }

  int _calculateDriveTrainProgress() {
    int completedSteps = 0;
    final driveTrain = vehicle.truckConditions.driveTrain;
    if (driveTrain.condition.isNotEmpty) completedSteps++;
    return completedSteps;
  }

  int _calculateChassisProgress() {
    int completedSteps = 0;
    final chassis = vehicle.truckConditions.chassis;
    if (chassis.condition.isNotEmpty) completedSteps++;
    return completedSteps;
  }

  int _calculateTyresProgress() {
    int completedSteps = 0;
    final tyresMap = vehicle.truckConditions.tyres;
    // Extend logic as needed...
    return completedSteps;
  }

  // If the vehicle is a trailer, we show a single trailer block
  Widget _buildTrailerSection(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isAdminOrSalesRep = (userProvider.getUserRole == 'admin' ||
        userProvider.getUserRole == 'sales representative');

    return GestureDetector(
      onTap: () async {
        // Go to the EditTrailerUploadScreen
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditTrailerUploadScreen(
              isDuplicating: false,
              isNewUpload: false,
              isAdminUpload: isAdminOrSalesRep,
              vehicle: widget.vehicle,
            ),
          ),
        );
        setState(() {});
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          children: [
            Text(
              'TRAILER INFORMATION',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Generic container to display a section with a progress count
  Widget _buildSection(BuildContext context, String title, String progress) {
    return GestureDetector(
      onTap: () async {
        if (title.contains('MAINTENANCE')) {
          // Show MaintenanceEditSection
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) => MaintenanceEditSection(
                vehicleId: vehicle.id,
                isUploading: false,
                isEditing: true,
                onMaintenanceFileSelected: (file) {},
                onWarrantyFileSelected: (file) {},
                oemInspectionType:
                    vehicle.maintenance.oemInspectionType ?? 'yes',
                oemInspectionExplanation: vehicle.maintenance.oemReason ?? '',
                onProgressUpdate: () {
                  setState(() {});
                },
                maintenanceSelection:
                    vehicle.maintenance.maintenanceSelection ?? 'yes',
                warrantySelection:
                    vehicle.maintenance.warrantySelection ?? 'yes',
                maintenanceDocUrl: vehicle.maintenance.maintenanceDocUrl,
                warrantyDocUrl: vehicle.maintenance.warrantyDocUrl,
              ),
            ),
          );
          setState(() {});
        } else if (title.contains('BASIC')) {
          // Basic Info
          var updatedVehicle = await Navigator.of(context).push<Vehicle>(
            MaterialPageRoute(
              builder: (BuildContext context) => BasicInformationEdit(
                vehicle: vehicle,
              ),
            ),
          );
          if (updatedVehicle != null) {
            setState(() {
              vehicle = updatedVehicle;
            });
          }
        } else if (title.contains('TRUCK CONDITIONS')) {
          // Truck Conditions
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) => TruckConditionsTabsEditPage(
                initialIndex: 0,
                vehicleId: vehicle.id,
                mainImageUrl: vehicle.mainImageUrl,
                referenceNumber: vehicle.referenceNumber ?? 'REF',
                isEditing: true,
              ),
            ),
          );
          setState(() {});
        } else if (title.contains('ADMIN')) {
          // Additional admin data UI if needed
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              progress,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Small data block for Year/Mileage/Gearbox/etc.
  Widget _buildInfoContainer(String title, String? value) {
    var screenSize = MediaQuery.of(context).size;
    String normalizedValue = value?.trim().toLowerCase() ?? '';
    String displayValue = (title == 'Gearbox' && value != null)
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
                screenSize.height * 0.012,
                FontWeight.w500,
                Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              displayValue,
              style: _customFont(
                screenSize.height * 0.014,
                FontWeight.bold,
                Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Image dots indicator
  Widget _buildImageIndicators(int numImages) {
    var screenSize = MediaQuery.of(context).size;
    double availableWidth =
        screenSize.width - (MediaQuery.of(context).size.height * 0.07);
    double indicatorWidth = (availableWidth / (numImages * 2)).clamp(3.0, 20.0);

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

  // Show a fullscreen image gallery when user taps on an image
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
                            horizontal: 8,
                            vertical: 4,
                          ),
                          color: Colors.black54,
                          child: Text(
                            allPhotos[index].label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final String userRole = userProvider.getUserRole;
    final bool isAdmin = userRole == 'admin';
    final bool isSalesRep = userRole == 'sales representative';
    final bool isAdminOrSalesRep = isAdmin || isSalesRep;
    final bool isDealer = userRole == 'dealer';
    final bool isTransporter = userRole == 'transporter';

    var blue = const Color(0xFF2F7FFF);
    final size = MediaQuery.of(context).size;
    final bool isTrailer = (vehicle.vehicleType.toLowerCase() == 'trailer');

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
            Expanded(
              child: Text(
                "${widget.vehicle.brands.join(', ')} "
                "${widget.vehicle.makeModel.toString().toUpperCase()} "
                "${widget.vehicle.year}",
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
          if (isTransporter || isAdminOrSalesRep)
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: Color(0xFFFF4E00),
                size: 24,
              ),
              onPressed: _navigateToEditPage,
            ),
          if (isTransporter || isAdminOrSalesRep)
            IconButton(
              icon: const Icon(
                Icons.delete,
                color: Color(0xFFFF4E00),
                size: 24,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Delete Vehicle'),
                      content: const Text(
                        'Are you sure you want to delete this vehicle?',
                      ),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        TextButton(
                          child: const Text('Delete'),
                          onPressed: () async {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('vehicles')
                                  .doc(widget.vehicle.id)
                                  .update({
                                'vehicleStatus': 'Archived',
                              });
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error archiving vehicle: $e'),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          if (isTransporter)
            IconButton(
              icon: const Icon(
                Icons.copy,
                color: Color(0xFFFF4E00),
                size: 24,
              ),
              onPressed: _navigateToDuplicatePage,
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                //=== IMAGE GALLERY ===
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

                //=== DETAILS & OFFERS ===
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // Basic specs row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInfoContainer(
                            'Year',
                            vehicle.year.toString(),
                          ),
                          const SizedBox(width: 5),
                          _buildInfoContainer('Mileage', vehicle.mileage),
                          const SizedBox(width: 5),
                          _buildInfoContainer(
                            'Gearbox',
                            vehicle.transmissionType,
                          ),
                          const SizedBox(width: 5),
                          _buildInfoContainer('Config', vehicle.config),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // If the user is Dealer/Admin/Sales, show "Make an offer" or Offer Status
                      if ((isAdminOrSalesRep || isDealer) &&
                          (!_hasMadeOffer || _offerStatus == 'rejected')) ...[
                        // Row of "X" and "Favorite"
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(Icons.close, blue),
                            const SizedBox(width: 16),
                            _buildActionButton(
                              Icons.favorite,
                              const Color(0xFFFF4E00),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Make an Offer',
                            style:
                                _customFont(20, FontWeight.bold, Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // If Admin or Sales Rep, let them pick a dealer
                        if (isAdminOrSalesRep) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Select Dealer',
                              style: _customFont(
                                16,
                                FontWeight.bold,
                                Colors.white,
                              ),
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
                                isExpanded: true,
                                items:
                                    userProvider.dealers.map((Dealer dealer) {
                                  return DropdownMenuItem<Dealer>(
                                    value: dealer,
                                    child: Text(dealer.email),
                                  );
                                }).toList(),
                                onChanged: (Dealer? newDealer) {
                                  setState(() {
                                    _selectedDealer = newDealer;
                                  });
                                },
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey[800],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide: BorderSide.none,
                                  ),
                                  hintText: 'Choose a dealer',
                                  hintStyle: _customFont(
                                    16,
                                    FontWeight.normal,
                                    Colors.grey,
                                  ),
                                ),
                                dropdownColor: Colors.grey[800],
                                style: _customFont(
                                  16,
                                  FontWeight.normal,
                                  Colors.white,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Enter offer text field
                        TextField(
                          controller: _controller,
                          cursorColor: const Color(0xFFFF4E00),
                          decoration: InputDecoration(
                            hintText: 'R 102 000 000',
                            hintStyle:
                                _customFont(24, FontWeight.normal, Colors.grey),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFFF4E00)),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 15.0),
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
                                  String numericValue = value
                                      .replaceAll(' ', '')
                                      .replaceAll('R', '');
                                  _offerAmount = double.parse(numericValue);
                                  _totalCost =
                                      _calculateTotalCost(_offerAmount);

                                  String formattedValue =
                                      "R${_formatNumberWithSpaces(numericValue)}";
                                  _controller.value =
                                      _controller.value.copyWith(
                                    text: formattedValue,
                                    selection: TextSelection.collapsed(
                                      offset: formattedValue.length,
                                    ),
                                  );
                                } catch (e) {
                                  print('Error parsing offer amount: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Invalid Offer Amount. '
                                        'Please Enter a Valid Number.',
                                      ),
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

                        // Offer breakdown
                        Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "R${_formatNumberWithSpaces(_totalCost.toStringAsFixed(0))}",
                                style: _customFont(
                                  18,
                                  FontWeight.bold,
                                  Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Including Commission and VAT",
                                style: _customFont(
                                  15,
                                  FontWeight.normal,
                                  Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Breakdown:",
                                style: _customFont(
                                  16,
                                  FontWeight.bold,
                                  Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Base Price: R ${_formatNumberWithSpaces(_offerAmount.toStringAsFixed(0))}",
                                style: _customFont(
                                  14,
                                  FontWeight.normal,
                                  Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                "Flat Rate Fee: R 12 500",
                                style: _customFont(
                                  14,
                                  FontWeight.normal,
                                  Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                "Subtotal: R ${_formatNumberWithSpaces(
                                  (_offerAmount + 12500.0).toStringAsFixed(0),
                                )}",
                                style: _customFont(
                                  14,
                                  FontWeight.normal,
                                  Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                "VAT (15%): R ${_formatNumberWithSpaces(
                                  (((_offerAmount + 12500.0) * 0.15)
                                      .toStringAsFixed(0)),
                                )}",
                                style: _customFont(
                                  14,
                                  FontWeight.normal,
                                  Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Total Cost: R ${_formatNumberWithSpaces(
                                  _totalCost.toStringAsFixed(0),
                                )}",
                                style: _customFont(
                                  14,
                                  FontWeight.bold,
                                  Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // If the user is a dealer, ensure they've been verified & doc is uploaded
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(userProvider.userId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData &&
                                isDealer &&
                                !isAdminOrSalesRep) {
                              Map<String, dynamic> userData =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              bool hasDocuments = userData['cipcCertificateUrl']
                                          ?.isNotEmpty ==
                                      true &&
                                  userData['brncUrl']?.isNotEmpty == true &&
                                  userData['bankConfirmationUrl']?.isNotEmpty ==
                                      true &&
                                  userData['proxyUrl']?.isNotEmpty == true;

                              bool isVerified = userData['isVerified'] ?? false;
                              bool isApproved = isVerified;

                              if (!hasDocuments || !isApproved) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'Please upload all required documents '
                                    '(CIPC, BRNC, Bank Confirmation, Proxy) '
                                    'and wait for account approval before making offers.',
                                    style: _customFont(
                                      16,
                                      FontWeight.normal,
                                      Colors.red,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                              return Container();
                            }
                            return Container();
                          },
                        ),

                        // "Make an offer" button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _makeOffer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF4E00),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'MAKE AN OFFER',
                              style: _customFont(
                                20,
                                FontWeight.bold,
                                Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ] else if ((isAdminOrSalesRep || isDealer) &&
                          _hasMadeOffer &&
                          _offerStatus != 'rejected')
                        // Offer status for a dealer who has already made an offer
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Offer Status: ',
                                style: _customFont(
                                  20,
                                  FontWeight.bold,
                                  Colors.white,
                                ),
                              ),
                              Text(
                                getDisplayStatus(_offerStatus),
                                style: _customFont(
                                  20,
                                  FontWeight.bold,
                                  const Color(0xFFFF4E00),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 40),

                      // If it's a trailer AND the user is a dealer => single trailer block
                      if (isTrailer && isDealer)
                        _buildTrailerSection(context)
                      else
                        // Otherwise, show the standard truck sections
                        Column(
                          children: [
                            // Basic Info block
                            if (isDealer || isAdminOrSalesRep)
                              _buildSection(
                                context,
                                'BASIC INFORMATION',
                                '${_calculateBasicInfoProgress()} OF 11 STEPS\nCOMPLETED',
                              ),
                            // Truck Conditions block
                            if (isDealer || isAdminOrSalesRep)
                              _buildSection(
                                context,
                                'TRUCK CONDITIONS',
                                '${_calculateTruckConditionsProgress()} OF 35 STEPS\nCOMPLETED',
                              ),
                            // Maintenance & Warranty
                            if (isTransporter || isDealer || isAdminOrSalesRep)
                              _buildSection(
                                context,
                                'MAINTENANCE AND WARRANTY',
                                '${_calculateMaintenanceProgress()} OF 4 STEPS\nCOMPLETED',
                              ),
                          ],
                        ),
                      const SizedBox(height: 30),

                      // If transporter => Show the offers made on this vehicle
                      if (isTransporter) ...[
                        Text(
                          "Offers Made on This Vehicle (${vehicle.referenceNumber}):",
                          style: _customFont(
                            20,
                            FontWeight.bold,
                            const Color(0xFFFF4E00),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildOffersList(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF4E00)),
              ),
            ),
        ],
      ),
      // Bottom nav for dealers (selectedIndex=1 if that's your “vehicles” page)
      bottomNavigationBar: (isAdminOrSalesRep)
          ? null
          : isDealer
              ? CustomBottomNavigation(
                  selectedIndex: 1,
                  onItemTapped: (index) {
                    setState(() {});
                  },
                )
              : null,
    );
  }
}
