import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/offer_card.dart';
import 'package:ctp/models/admin_data.dart';
import 'package:ctp/models/chassis.dart';
import 'package:ctp/models/drive_train.dart';
import 'package:ctp/models/external_cab.dart';
import 'package:ctp/models/internal_cab.dart';
import 'package:ctp/models/maintenance.dart';
import 'package:ctp/models/truck_conditions.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/editTruckForms/basic_information_edit.dart';
import 'package:ctp/pages/editTruckForms/edit_form_navigation.dart';
import 'package:ctp/pages/editTruckForms/maintenance_edit_section.dart';
import 'package:ctp/pages/editTruckForms/truck_conditions_tabs_edit_page.dart';
import 'package:ctp/pages/trailerForms/edit_trailer_upload_screen.dart';
import 'package:ctp/pages/truckForms/vehilce_upload_screen.dart'
    as truck_upload;
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:ctp/components/web_navigation_bar.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Add this getter for consistent breakpoint
  bool _isCompactNavigation(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1100;

  Vehicle? _vehicle;
  Vehicle get vehicle => _vehicle ?? widget.vehicle;
  set vehicle(Vehicle value) {
    setState(() {
      _vehicle = value;
    });
  }

  // Basic flags
  bool isInspectionComplete = false;
  bool isCollectionComplete = false;

  // Offer-related
  final TextEditingController _controller = TextEditingController();
  double _offerAmount = 0.0;
  double _totalCost = 0.0;
  bool _hasMadeOffer = false;
  String _offerStatus = 'in-progress';
  bool _canMakeOffer = true;
  bool _isLoading = false;

  // To check if the accepted offer belongs to the current dealer
  bool _isAcceptedOfferMine = false;

  // Image gallery
  List<PhotoItem> allPhotos = [];
  int _currentImageIndex = 0;
  late PageController _pageController;

  // For admin/sales picking a dealer
  Dealer? _selectedDealer;
  bool _isDealersLoading = false;

  // Add new state variable
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;

    // Clear image cache to prevent stale images
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    // 1. Check if the vehicle is accepted => can or cannot make an offer
    _checkOfferAvailability();

    // 2. Check if the logged-in user has an existing offer
    _checkIfOfferMade();

    // 3. If accepted, see if that acceptedOfferId belongs to this user
    _checkIfMyOfferAccepted();

    // 4. Admin/sales => fetch dealers
    _fetchAllDealers();

    // 5. Check if inspection/collection complete
    _checkSetupStatus();

    // 6. Prepare photos
    WidgetsBinding.instance.addPostFrameCallback((_) => _preparePhotos());
    _pageController = PageController();

    // Remove the _checkIfLiked() call since we'll use UserProvider instead
    // _checkIfLiked();
  }

  // ---------------------------------------------------------------------------
  //  FETCH & REFRESH LOGIC
  // ---------------------------------------------------------------------------
  Future<void> _refreshVehicleData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicle.id)
          .get();
      if (doc.exists) {
        setState(() {
          vehicle = Vehicle.fromDocument(doc);
        });
      }
    } catch (e) {
      debugPrint('Error refreshing vehicle data: $e');
    }
  }

  // (1) If the vehicle doc has isAccepted == true => _canMakeOffer = false
  Future<void> _checkOfferAvailability() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicle.id)
          .get();
      if (doc.exists) {
        bool isAcceptedFromDoc = doc.data()?['isAccepted'] ?? false;
        if (isAcceptedFromDoc) {
          setState(() => _canMakeOffer = false);
        }
      }
    } catch (e) {
      debugPrint('Error checking vehicle acceptance: $e');
    }
  }

  // (2) Check if the current user (dealer) already made an offer
  Future<void> _checkIfOfferMade() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('dealerId', isEqualTo: user.uid)
          .where('vehicleId', isEqualTo: widget.vehicle.id)
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _hasMadeOffer = true;
          _offerStatus = snapshot.docs.first['offerStatus'] ?? 'in-progress';
        });
      }
    } catch (e) {
      debugPrint('Error checking if offer is made: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to check offer status.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // (3) If the vehicle is accepted => check if that acceptedOfferId belongs
  //     to the currently logged-in user (dealer).
  Future<void> _checkIfMyOfferAccepted() async {
    try {
      if (!widget.vehicle.isAccepted) return; // skip if not accepted

      final acceptedOfferId = widget.vehicle.acceptedOfferId;
      if (acceptedOfferId == null || acceptedOfferId.isEmpty) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Fetch the acceptedOffer doc
      final doc = await FirebaseFirestore.instance
          .collection('offers')
          .doc(acceptedOfferId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final offerDealerId = data['dealerId'] ?? '';
          // If that dealerId matches me => the accepted offer is mine
          if (offerDealerId == user.uid) {
            setState(() => _isAcceptedOfferMine = true);
          }
        }
      }
    } catch (e) {
      debugPrint('Error in _checkIfMyOfferAccepted: $e');
    }
  }

  // (4) If admin/sales => fetch dealers
  Future<void> _fetchAllDealers() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() => _isDealersLoading = true);

    try {
      await userProvider.fetchDealers();
      if (userProvider.dealers.isNotEmpty) {
        setState(() {
          _selectedDealer = userProvider.dealers.first;
        });
      }
    } catch (e) {
      debugPrint('Error fetching dealers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load dealers.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isDealersLoading = false);
    }
  }

  // (5) Check inspection/collection flags
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
      debugPrint('Error checking setup status: $e');
    }
  }

  // (6) Prepare photos (main + damage + single shots)
  void _preparePhotos() {
    try {
      allPhotos = [];
      // Main
      if (widget.vehicle.mainImageUrl != null &&
          widget.vehicle.mainImageUrl!.isNotEmpty) {
        allPhotos.add(
          PhotoItem(url: widget.vehicle.mainImageUrl!, label: 'Main Image'),
        );
      }
      // Damages
      for (int i = 0; i < widget.vehicle.damagePhotos.length; i++) {
        _addPhotoIfExists(
          widget.vehicle.damagePhotos[i],
          'Damage Photo ${i + 1}',
        );
      }
      // Singles
      _addPhotoIfExists(widget.vehicle.dashboardPhoto, 'Dashboard Photo');
      _addPhotoIfExists(widget.vehicle.faultCodesPhoto, 'Fault Codes Photo');
      _addPhotoIfExists(widget.vehicle.licenceDiskUrl, 'Licence Disk Photo');
      _addPhotoIfExists(widget.vehicle.mileageImage, 'Mileage Image');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error Loading Vehicle Details.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addPhotoIfExists(String? photoUrl, String label) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      allPhotos.add(PhotoItem(url: photoUrl, label: label));
    }
  }

  // Add method to check if vehicle is liked
  Future<void> _checkIfLiked() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('favorites')
          .doc('${userId}_${vehicle.id}')
          .get();

      setState(() {
        _isLiked = doc.exists;
      });
    } catch (e) {
      debugPrint('Error checking if vehicle is liked: $e');
    }
  }

  // ---------------------------------------------------------------------------
  //  ADMIN-ONLY: Update vehicle status
  // ---------------------------------------------------------------------------
  Future<void> _updateVehicleStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicle.id)
          .update({'vehicleStatus': newStatus});

      await _refreshVehicleData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vehicle status changed to $newStatus.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error updating vehicle status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  //  TRANSPORTER-ONLY: Simple Toggle
  // ---------------------------------------------------------------------------
  Future<void> _toggleVehicleStatus() async {
    try {
      final currentStatus = vehicle.vehicleStatus.toLowerCase() ?? 'draft';
      String newStatus = currentStatus;

      if (currentStatus == 'draft') {
        newStatus = 'pending';
      } else if (currentStatus == 'live') {
        newStatus = 'Draft';
      }
      // If 'pending', do nothing special or define your logic

      if (newStatus != currentStatus) {
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(vehicle.id)
            .update({'vehicleStatus': newStatus});

        await _refreshVehicleData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle status changed to $newStatus.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling vehicle status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error toggling status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  //  MAKE AN OFFER
  // ---------------------------------------------------------------------------
  Future<void> _makeOffer() async {
    // If isAccepted => no new offers
    if (!_canMakeOffer || vehicle.isAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This vehicle is already accepted.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String role = userProvider.getUserRole;
    final bool isAdmin = (role == 'admin');
    final bool isSalesRep = (role == 'sales representative');
    final bool isDealer = (role == 'dealer');

    // Validate offer
    if (_offerAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Offer Amount. Please Enter a Valid Number.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If admin/sales => must pick dealer
    if ((isAdmin || isSalesRep) && _selectedDealer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a dealer.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If dealer => ensure docs are uploaded & verified
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
          Navigator.pushNamed(context, '/profile');
          return;
        }
      }
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      String dealerId =
          (isAdmin || isSalesRep) ? _selectedDealer!.id : user.uid;
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

      // Reset
      _controller.clear();
      setState(() {
        _hasMadeOffer = true;
        _offerStatus = 'in-progress';
        _offerAmount = 0.0;
        _totalCost = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error making offer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting offer: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  //  OFFERS, FORMATTING, ETC.
  // ---------------------------------------------------------------------------
  double _calculateTotalCost(double basePrice) {
    const double vatRate = 0.15;
    const double flatRateFee = 12500.0;
    double subTotal = basePrice + flatRateFee;
    double vat = subTotal * vatRate;
    return subTotal + vat;
  }

  String _formatNumberWithSpaces(String number) {
    return number.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  Future<List<Offer>> _fetchOffersForVehicle() async {
    try {
      OfferProvider offerProvider =
          Provider.of<OfferProvider>(context, listen: false);
      return await offerProvider.fetchOffersForVehicle(widget.vehicle.id);
    } catch (e) {
      debugPrint('Error fetching offers: $e');
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
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching offers'));
        }
        if (snapshot.data == null || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No offers available for this vehicle',
                style: TextStyle(color: Colors.white)),
          );
        }

        List<Offer> offers = snapshot.data!;
        // Sort offers by createdAt descending
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
            return OfferCard(offer: offers[index]);
          },
        );
      },
    );
  }

  String getDisplayStatus(String? status) {
    switch (status?.toLowerCase()) {
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
        return status ?? 'Unknown';
    }
  }

  TextStyle _customFont(double size, FontWeight weight, Color color) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  // ---------------------------------------------------------------------------
  //  NAVIGATIONS
  // ---------------------------------------------------------------------------
  Future<void> _navigateToEditPage() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isAdmin = (userProvider.getUserRole == 'admin');
    final bool isSalesRep =
        (userProvider.getUserRole == 'sales representative');
    final bool isAdminOrSalesRep = isAdmin || isSalesRep;

    if (vehicle.vehicleType.toLowerCase() == 'trailer') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditTrailerUploadScreen(
            isDuplicating: false,
            isNewUpload: false,
            isAdminUpload: isAdminOrSalesRep,
            vehicle: vehicle,
          ),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditFormNavigation(vehicle: vehicle),
        ),
      );
    }
    setState(() {});
  }

  void _navigateToDuplicatePage() {
    try {
      debugPrint('=== Starting Vehicle Duplication ===');
      debugPrint('Source Vehicle ID: ${vehicle.id}');

      // Create duplicate vehicle with only the specified fields
      Vehicle dup = Vehicle(
        // Required empty/new fields
        id: '',
        isAccepted: false,
        acceptedOfferId: '',
        mileage: '',
        vinNumber: '',
        engineNumber: '',
        registrationNumber: '',
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
        vehicleType: '',
        warrantyDetails: '',
        createdAt: DateTime.now(),
        vehicleStatus: '',
        vehicleAvailableImmediately: 'false',
        availableDate: DateTime.now().toIso8601String(),
        trailerType: '',
        axles: '',
        trailerLength: '',
        warrentyType: '',
        maintenance: Maintenance(
          maintenanceSelection: '',
          warrantySelection: '',
          oemInspectionType: '',
          oemReason: '',
          maintenanceDocUrl: '',
          warrantyDocUrl: '',
          vehicleId: '',
        ),
        length: '',
        vinTrailer: '',
        damagesDescription: '',
        additionalFeatures: '',

        // Fields to copy for duplication
        application: vehicle.application,
        brands: vehicle.brands,
        config: vehicle.config,
        country: vehicle.country,
        hydraluicType: vehicle.hydraluicType,
        makeModel: vehicle.makeModel,
        province: vehicle.province,
        suspensionType: vehicle.suspensionType,
        transmissionType: vehicle.transmissionType,
        year: vehicle.year,

        // Required model objects
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
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => truck_upload.VehicleUploadScreen(
            vehicle: dup,
            isDuplicating: true,
          ),
        ),
      );

      debugPrint('=== Duplication Complete ===');
    } catch (e, stackTrace) {
      debugPrint('=== Error During Duplication ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error duplicating vehicle'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  //  FULLSCREEN IMAGES
  // ---------------------------------------------------------------------------
  void _showFullScreenImage(BuildContext context, int initialIndex) {
    _pageController = PageController(initialPage: initialIndex);
    showDialog(
      context: context,
      builder: (_) => Dialog(
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
                        errorBuilder: (ctx, error, st) {
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
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              left: 10,
              top: MediaQuery.of(context).size.height / 2 - 25,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () {
                  if (_pageController.hasClients) {
                    int prevIndex = _pageController.page!.toInt() - 1;
                    if (prevIndex >= 0) {
                      _pageController.animateToPage(
                        prevIndex,
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
                icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  IMAGE INDICATORS
  // ---------------------------------------------------------------------------
  Widget _buildImageIndicators(int count) {
    var screenSize = MediaQuery.of(context).size;
    double availableWidth =
        screenSize.width - (MediaQuery.of(context).size.height * 0.07);
    double indicatorWidth = (availableWidth / (count * 2)).clamp(3.0, 20.0);
    return SizedBox(
      width: availableWidth,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
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

  // ---------------------------------------------------------------------------
  //  SPECS CONTAINER
  // ---------------------------------------------------------------------------
  Widget _buildInfoContainer(String title, String? value) {
    var screenSize = MediaQuery.of(context).size;
    String normalized = (value ?? '').trim().toLowerCase();
    String displayValue;
    if (title == 'Gearbox') {
      if (normalized.contains('auto')) {
        displayValue = 'AUTO';
      } else if (normalized.contains('manual')) {
        displayValue = 'MANUAL';
      } else {
        displayValue = (value ?? '').toUpperCase();
      }
    } else {
      displayValue = (value ?? 'N/A').toUpperCase();
    }
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

  // Example placeholders for progress
  int _calculateBasicInfoProgress() => 3;
  int _calculateTruckConditionsProgress() => 10;
  int _calculateMaintenanceProgress() => 2;

  // For trailer
  Widget _buildTrailerSection() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isAdminOrSalesRep = (userProvider.getUserRole == 'admin' ||
        userProvider.getUserRole == 'sales representative');

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditTrailerUploadScreen(
              isDuplicating: false,
              isNewUpload: false,
              isAdminUpload: isAdminOrSalesRep,
              vehicle: vehicle,
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
        child: const Center(
          child: Text(
            'TRAILER INFORMATION',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Generic section block
  Widget _buildSection(BuildContext ctx, String title, String progress) {
    return GestureDetector(
      onTap: () async {
        if (title.contains('BASIC')) {
          var updated = await Navigator.push<Vehicle>(
            ctx,
            MaterialPageRoute(
              builder: (_) => BasicInformationEdit(vehicle: vehicle),
            ),
          );
          if (updated != null) {
            setState(() {
              vehicle = updated;
            });
          }
        } else if (title.contains('TRUCK CONDITIONS')) {
          await Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => TruckConditionsTabsEditPage(
                initialIndex: 0,
                vehicleId: vehicle.id,
                mainImageUrl: vehicle.mainImageUrl,
                referenceNumber: vehicle.referenceNumber ?? 'REF',
                isEditing: true,
              ),
            ),
          );
          setState(() {});
        } else if (title.contains('MAINTENANCE')) {
          await Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => MaintenanceEditSection(
                vehicleId: vehicle.id,
                isUploading: false,
                isEditing: true,
                onMaintenanceFileSelected: (file) {},
                onWarrantyFileSelected: (file) {},
                oemInspectionType:
                    vehicle.maintenance.oemInspectionType ?? 'yes',
                oemInspectionExplanation: vehicle.maintenance.oemReason ?? '',
                onProgressUpdate: () => setState(() {}),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              progress,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // === COLUMN for TRANSPORTER
  Widget _buildTransporterActionButtonsColumn() {
    const Color orangeColor = Color(0xFFFF4E00);
    final String? vehicleStatus = vehicle.vehicleStatus.toLowerCase();
    bool isPending = (vehicleStatus == 'pending');
    bool isDraft = (vehicleStatus == 'draft');
    bool isLive = (vehicleStatus == 'live');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Edit (disable if pending)
          CustomButton(
            text: 'Edit Vehicle',
            borderColor: orangeColor,
            onPressed: isPending ? null : _navigateToEditPage,
          ),
          // Delete (disable if pending)
          CustomButton(
            text: 'Delete Vehicle',
            borderColor: orangeColor,
            onPressed: isPending
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete Vehicle'),
                        content: const Text(
                          'Are you sure you want to delete this vehicle?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('vehicles')
                                    .doc(vehicle.id)
                                    .update({
                                  'vehicleStatus': 'Archived',
                                });
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Error archiving vehicle: $e'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
          ),

          // Duplicate (always)
          CustomButton(
            text: 'Duplicate Vehicle',
            borderColor: orangeColor,
            onPressed: _navigateToDuplicatePage,
          ),

          // If draft => "Submit for Approval"
          // If pending => "Submitted"
          // If live => "Move to Draft"
          if (isDraft)
            CustomButton(
              text: 'Submit for Approval',
              borderColor: Colors.green,
              onPressed: _toggleVehicleStatus,
            )
          else if (isPending)
            CustomButton(
              text: 'Submitted',
              borderColor: Colors.blueAccent,
              onPressed: null, // disabled
            )
          else if (isLive)
            CustomButton(
              text: 'Move to Draft',
              borderColor: Colors.redAccent,
              onPressed: _toggleVehicleStatus,
            ),
        ],
      ),
    );
  }

  // === COLUMN for ADMIN (or SALES) Action Buttons
  // Admin sees edit, delete, duplicate at all times
  // If pending => Approve for Live
  // If live => push to draft
  // If draft => no extra button
  Widget _buildAdminActionButtonsColumn() {
    final String? vehicleStatus = vehicle.vehicleStatus.toLowerCase();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isAdmin = (userProvider.getUserRole == 'admin');

    bool isPending = (vehicleStatus == 'pending');
    bool isLive = (vehicleStatus == 'live');
    bool isDraft = (vehicleStatus == 'draft');

    const Color orangeColor = Color(0xFFFF4E00);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Edit (always)
          CustomButton(
            text: 'Edit Vehicle',
            borderColor: orangeColor,
            onPressed: _navigateToEditPage,
          ),
          // Delete (always)
          CustomButton(
            text: 'Delete Vehicle',
            borderColor: orangeColor,
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Vehicle'),
                  content: const Text(
                    'Are you sure you want to delete this vehicle?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        try {
                          await FirebaseFirestore.instance
                              .collection('vehicles')
                              .doc(vehicle.id)
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
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),

          // Duplicate (always)
          CustomButton(
            text: 'Duplicate Vehicle',
            borderColor: orangeColor,
            onPressed: _navigateToDuplicatePage,
          ),

          // If admin & pending => Approve for live
          if (isAdmin && isPending)
            CustomButton(
              text: 'Approve for Live',
              borderColor: Colors.green,
              onPressed: () => _updateVehicleStatus('Live'),
            ),

          // If admin & live => push to draft
          if (isAdmin && isLive)
            CustomButton(
              text: 'Move to Draft',
              borderColor: Colors.redAccent,
              onPressed: () => _updateVehicleStatus('Draft'),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  Action Button for close/favorite
  // ---------------------------------------------------------------------------
  Widget _buildActionButton(IconData icon, Color backgroundColor) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isAdmin = (userProvider.getUserRole == 'admin');

    if (isAdmin) {
      return const SizedBox.shrink();
    }

    bool isLiked = userProvider.getLikedVehicles.contains(vehicle.id);

    // Only show close button if liked
    if (icon == Icons.close && !isLiked) {
      return const SizedBox.shrink();
    }

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId == null) return;

          if (icon == Icons.close) {
            // Remove from favorites
            try {
              await userProvider.unlikeVehicle(vehicle.id);
              // ScaffoldMessenger.of(context).showSnackBar(
              //   const SnackBar(
              //     content: Text('Removed from favorites'),
              //     backgroundColor: Color(0xFFFF4E00),
              //   ),
              // );
            } catch (e) {
              debugPrint('Error removing from favorites: $e');
            }
          } else if (icon == Icons.favorite && !isLiked) {
            // Add to favorites if not already liked
            try {
              await userProvider.likeVehicle(vehicle.id);
              // ScaffoldMessenger.of(context).showSnackBar(
              //   const SnackBar(
              //     content: Text('Added to favorites'),
              //     backgroundColor: Color(0xFFFF4E00),
              //   ),
              // );
            } catch (e) {
              debugPrint('Error adding to favorites: $e');
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon == Icons.favorite && isLiked ? Icons.favorite : icon,
            color: Colors.black,
            size: 24,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  //  BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    // ...existing user role definitions...

    final size = MediaQuery.of(context).size;
    final bool isTrailer = (vehicle.vehicleType.toLowerCase() == 'trailer');
    const bool isWeb = kIsWeb;

    List<NavigationItem> navigationItems = userProvider.getUserRole == 'dealer'
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      appBar: isWeb
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: WebNavigationBar(
                isCompactNavigation: _isCompactNavigation(context),
                currentRoute: '/offers',
                onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            )
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: Color(0xFFFF4E00), size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${vehicle.brands.join(', ')} '
                      '${vehicle.makeModel.toUpperCase()} '
                      '${vehicle.year}',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2F7FFF),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.verified,
                      color: Color(0xFFFF4E00), size: 24),
                ],
              ),
            ),
      drawer: _isCompactNavigation(context) && isWeb
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
                          bool isActive = '/offers' == item.route;
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
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // === Image Gallery
                Stack(
                  children: [
                    SizedBox(
                      height: size.height * 0.32,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: allPhotos.length,
                        onPageChanged: (index) {
                          setState(() => _currentImageIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _showFullScreenImage(context, index),
                            child: Stack(
                              children: [
                                Image.network(
                                  allPhotos[index].url,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: size.height * 0.32,
                                  // Add cacheWidth to optimize memory usage
                                  cacheWidth:
                                      (MediaQuery.of(context).size.width * 2)
                                          .toInt(),
                                  // Add key to force rebuild when URL changes
                                  key: ValueKey(allPhotos[index].url),
                                  errorBuilder: (ctx, error, st) {
                                    return Image.asset(
                                      'assets/default_vehicle_image.png',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: size.height * 0.32,
                                    );
                                  },
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
                            ),
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

                // === Details and Offer Info
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Basic specs row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInfoContainer('Year', vehicle.year),
                          const SizedBox(width: 5),
                          _buildInfoContainer('Mileage', vehicle.mileage),
                          const SizedBox(width: 5),
                          _buildInfoContainer(
                              'Gearbox', vehicle.transmissionType),
                          const SizedBox(width: 5),
                          _buildInfoContainer('Config', vehicle.config),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // === TRANSPORTER Buttons (stacked) if isTransporter
                      if (userProvider.getUserRole == 'transporter') ...[
                        _buildTransporterActionButtonsColumn(),
                        const SizedBox(height: 20),
                      ],

                      // === ADMIN/SALES => special actions
                      if (userProvider.getUserRole == 'admin' ||
                          userProvider.getUserRole ==
                              'sales representative') ...[
                        _buildAdminActionButtonsColumn(),
                        const SizedBox(height: 20),
                      ],

                      // ========== If Admin/Sales/Dealer, handle offer logic
                      if (userProvider.getUserRole == 'admin' ||
                          userProvider.getUserRole == 'sales representative' ||
                          userProvider.getUserRole == 'dealer') ...[
                        if (vehicle.isAccepted) ...[
                          if (_isAcceptedOfferMine) ...[
                            // If it's MY accepted offer => show normal Offer Status
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Offer Status: ',
                                    style: _customFont(
                                        20, FontWeight.bold, Colors.white),
                                  ),
                                  Text(
                                    'Accepted',
                                    style: _customFont(
                                        20, FontWeight.bold, Color(0xFFFF4E00)),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Another dealer's offer is accepted
                            Center(
                              child: Text(
                                'Another dealer’s offer has already been accepted.\n'
                                'No new offers can be made.',
                                style: _customFont(
                                    18, FontWeight.normal, Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ] else if (_hasMadeOffer &&
                            _offerStatus != 'rejected') ...[
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Offer Status: ',
                                  style: _customFont(
                                      20, FontWeight.bold, Colors.white),
                                ),
                                Text(
                                  getDisplayStatus(_offerStatus),
                                  style: _customFont(
                                      20, FontWeight.bold, Color(0xFFFF4E00)),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // If not accepted + not made an offer or was rejected => Make an Offer
                          // Hide X and Heart if user is admin
                          if (!(userProvider.getUserRole == 'admin' ||
                              userProvider.getUserRole ==
                                      'sales representative' &&
                                  userProvider.getUserRole ==
                                      'admin')) // or just isAdmin
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton(
                                    Icons.close, const Color(0xFF2F7FFF)),
                                const SizedBox(width: 16),
                                _buildActionButton(
                                    Icons.favorite, const Color(0xFFFF4E00)),
                              ],
                            ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'Make an Offer',
                              style: _customFont(
                                  20, FontWeight.bold, Colors.white),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // If Admin/Sales => pick a dealer
                          if (userProvider.getUserRole == 'admin' ||
                              userProvider.getUserRole ==
                                  'sales representative') ...[
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
                              builder: (ctx, userProv, child) {
                                if (userProv.dealers.isEmpty) {
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
                                  items: userProv.dealers.map((Dealer dealer) {
                                    return DropdownMenuItem<Dealer>(
                                      value: dealer,
                                      child: Text(dealer.email),
                                    );
                                  }).toList(),
                                  onChanged: (Dealer? newDealer) {
                                    setState(() => _selectedDealer = newDealer);
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

                          // TextField for offer
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
                            style:
                                _customFont(20, FontWeight.bold, Colors.white),
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
                                        'R${_formatNumberWithSpaces(numericValue)}';
                                    _controller.value =
                                        _controller.value.copyWith(
                                      text: formattedValue,
                                      selection: TextSelection.collapsed(
                                        offset: formattedValue.length,
                                      ),
                                    );
                                  } catch (e) {
                                    debugPrint('Error: $e');
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

                          // Breakdown
                          Center(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'R${_formatNumberWithSpaces(_totalCost.toStringAsFixed(0))}',
                                  style: _customFont(
                                      18, FontWeight.bold, Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Including Commission and VAT',
                                  style: _customFont(
                                      15, FontWeight.normal, Colors.white),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Breakdown:',
                                  style: _customFont(
                                      16, FontWeight.bold, Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Base Price: R ${_formatNumberWithSpaces(_offerAmount.toStringAsFixed(0))}',
                                  style: _customFont(
                                      14, FontWeight.normal, Colors.white),
                                ),
                                Text(
                                  'Flat Rate Fee: R 12 500',
                                  style: _customFont(
                                      14, FontWeight.normal, Colors.white),
                                ),
                                Text(
                                  'Subtotal: R ${_formatNumberWithSpaces(
                                    (_offerAmount + 12500.0).toStringAsFixed(0),
                                  )}',
                                  style: _customFont(
                                      14, FontWeight.normal, Colors.white),
                                ),
                                Text(
                                  'VAT (15%): R ${_formatNumberWithSpaces(
                                    (((_offerAmount + 12500.0) * 0.15)
                                        .toStringAsFixed(0)),
                                  )}',
                                  style: _customFont(
                                      14, FontWeight.normal, Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total Cost: R ${_formatNumberWithSpaces(
                                    _totalCost.toStringAsFixed(0),
                                  )}',
                                  style: _customFont(
                                      14, FontWeight.bold, Colors.white),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // If dealer => doc check
                          StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(userProvider.userId)
                                .snapshots(),
                            builder: (ctx, snapshot) {
                              if (snapshot.hasData &&
                                  userProvider.getUserRole == 'dealer') {
                                Map<String, dynamic> userData = snapshot.data!
                                    .data() as Map<String, dynamic>;
                                bool hasDocuments = userData[
                                                'cipcCertificateUrl']
                                            ?.isNotEmpty ==
                                        true &&
                                    userData['brncUrl']?.isNotEmpty == true &&
                                    userData['bankConfirmationUrl']
                                            ?.isNotEmpty ==
                                        true &&
                                    userData['proxyUrl']?.isNotEmpty == true;
                                bool isVerified =
                                    userData['isVerified'] ?? false;
                                bool isApproved = isVerified;

                                if (!hasDocuments || !isApproved) {
                                  return Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'Please upload all required documents '
                                      '(CIPC, BRNC, Bank Confirmation, Proxy) '
                                      'and wait for account approval before making offers.',
                                      style: _customFont(
                                          16, FontWeight.normal, Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }
                              }
                              return Container();
                            },
                          ),

                          // MAKE AN OFFER button
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
                                    20, FontWeight.bold, Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ],

                      // Spacing
                      const SizedBox(height: 40),

                      // If it's a trailer & user is a dealer => single trailer block
                      if (isTrailer && userProvider.getUserRole == 'dealer')
                        _buildTrailerSection()
                      else ...[
                        if (userProvider.getUserRole == 'admin' ||
                            userProvider.getUserRole ==
                                'sales representative' ||
                            userProvider.getUserRole == 'dealer')
                          _buildSection(
                            context,
                            'BASIC INFORMATION',
                            '${_calculateBasicInfoProgress()} OF 11 STEPS\nCOMPLETED',
                          ),
                        if (userProvider.getUserRole == 'admin' ||
                            userProvider.getUserRole ==
                                'sales representative' ||
                            userProvider.getUserRole == 'dealer')
                          _buildSection(
                            context,
                            'TRUCK CONDITIONS',
                            '${_calculateTruckConditionsProgress()} OF 35 STEPS\nCOMPLETED',
                          ),
                        if (userProvider.getUserRole == 'admin' ||
                            userProvider.getUserRole ==
                                'sales representative' ||
                            userProvider.getUserRole == 'dealer')
                          _buildSection(
                            context,
                            'MAINTENANCE AND WARRANTY',
                            '${_calculateMaintenanceProgress()} OF 4 STEPS\nCOMPLETED',
                          ),
                      ],

                      const SizedBox(height: 30),

                      // If transporter => Show the offers
                      if (userProvider.getUserRole == 'transporter') ...[
                        Text(
                          'Offers Made on This Vehicle (${vehicle.referenceNumber}):',
                          style: _customFont(
                            20,
                            FontWeight.bold,
                            const Color(0xFFFF4E00),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildOffersList(),
                      ],

                      const SizedBox(height: 24),
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

      // Only show bottom nav if not admin/sales
      bottomNavigationBar: (!kIsWeb &&
              !(userProvider.getUserRole == 'admin' ||
                  userProvider.getUserRole == 'sales representative') &&
              userProvider.getUserRole == 'dealer')
          ? CustomBottomNavigation(
              selectedIndex: 1,
              onItemTapped: (index) {
                setState(() {});
              },
            )
          : null,
    );
  }
  // ...existing code...
}
