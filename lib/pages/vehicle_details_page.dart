import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/offer_card.dart';
import 'package:ctp/models/admin_data.dart';
import 'package:ctp/models/chassis.dart';
import 'package:ctp/models/drive_train.dart';
import 'package:ctp/models/external_cab.dart';
import 'package:ctp/models/internal_cab.dart';
import 'package:ctp/models/maintenance.dart';
import 'package:ctp/models/trailer.dart';
import 'package:ctp/models/truck_conditions.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/editTruckForms/basic_information_edit.dart';
import 'package:ctp/pages/editTruckForms/chassis_edit_page.dart';
import 'package:ctp/pages/editTruckForms/drive_train_edit_page.dart';
import 'package:ctp/pages/editTruckForms/edit_form_navigation.dart';
import 'package:ctp/pages/editTruckForms/external_cab_edit_page.dart';
import 'package:ctp/pages/editTruckForms/internal_cab_edit_page.dart';
import 'package:ctp/pages/editTruckForms/maintenance_edit_section.dart';
import 'package:ctp/pages/editTruckForms/tyres_edit_page.dart';
import 'package:ctp/pages/trailerForms/edit_trailer_upload_screen.dart';
import 'package:ctp/pages/trailerForms/trailer_upload_screen.dart';
import 'package:ctp/pages/truckForms/vehilce_upload_screen.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:ctp/components/web_navigation_bar.dart';
// Add this import
import 'package:ctp/pages/vehicles_list.dart';
import 'package:ctp/utils/navigation.dart';
import 'package:ctp/pages/editTruckForms/admin_edit_section.dart'; // Add this import
// Update the admin navbar import to avoid conflict:
import 'package:ctp/components/admin_web_navigation_bar.dart'
    hide NavigationItem; // New import for admin navbar

// Define the PhotoItem class to hold both the image URL and its label
class PhotoItem {
  final String url;
  final String label;

  PhotoItem({required this.url, required this.label});
}

class VehicleDetailsPage extends StatefulWidget {
  final Vehicle vehicle;
  final Trailer? trailer;

  const VehicleDetailsPage({super.key, required this.vehicle, this.trailer});

  @override
  _VehicleDetailsPageState createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Add this getter for consistent breakpoint
  bool _isCompactNavigation(BuildContext context) =>
      MediaQuery.of(context).size.width <= 1100;

  Vehicle? _vehicle;
  Trailer? _trailer;
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

  // Add these state variables
  bool _isTruckConditionsExpanded = false;

  // Add these new fields
  final Map<String, double> _sectionProgress = {
    'basic': 0,
    'maintenance': 0,
    'external': 0,
    'internal': 0,
    'chassis': 0,
    'driveTrain': 0,
    'tyres': 0,
  };

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
    _trailer = widget.trailer;
    if (widget.vehicle.vehicleType.toLowerCase() == 'trailer') {
      debugPrint("DEBUG: Trailer data: ${widget.trailer.toString()}");
    }
    // 3. If accepted, see if that acceptedOfferId belongs to this user
    _checkIfMyOfferAccepted();

    // 4. Admin/sales => fetch dealers
    _fetchAllDealers();

    // 5. Check if inspection/collection complete
    _checkSetupStatus();

    // 6. Prepare photos
    WidgetsBinding.instance.addPostFrameCallback((_) => _preparePhotos());
    _pageController = PageController();
  }

  // ---------------------------------------------------------------------------
  //  Helper: Get verification status from dealer document.
  // ---------------------------------------------------------------------------
  bool getIsVerified(DocumentSnapshot dealerDoc) {
    return dealerDoc.get('isVerified') ?? false;
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

  Future<void> _checkIfMyOfferAccepted() async {
    try {
      if (!widget.vehicle.isAccepted) return;

      final acceptedOfferId = widget.vehicle.acceptedOfferId;
      if (acceptedOfferId == null || acceptedOfferId.isEmpty) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('offers')
          .doc(acceptedOfferId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final offerDealerId = data['dealerId'] ?? '';
          if (offerDealerId == user.uid) {
            setState(() => _isAcceptedOfferMine = true);
          }
        }
      }
    } catch (e) {
      debugPrint('Error in _checkIfMyOfferAccepted: $e');
    }
  }

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

  void _preparePhotos() {
    try {
      allPhotos = [];
      if (widget.vehicle.mainImageUrl != null &&
          widget.vehicle.mainImageUrl!.isNotEmpty) {
        allPhotos.add(
          PhotoItem(url: widget.vehicle.mainImageUrl!, label: 'Main Image'),
        );
      }
      for (int i = 0; i < widget.vehicle.damagePhotos.length; i++) {
        _addPhotoIfExists(
          widget.vehicle.damagePhotos[i],
          'Damage Photo ${i + 1}',
        );
      }
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

  Future<void> _toggleVehicleStatus() async {
    try {
      final currentStatus = vehicle.vehicleStatus.toLowerCase() ?? 'draft';
      String newStatus = currentStatus;

      if (currentStatus == 'draft') {
        newStatus = 'pending';
      } else if (currentStatus == 'live') {
        newStatus = 'Draft';
      }

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

  Future<void> _makeOffer() async {
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

    if (_offerAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Offer Amount. Please Enter a Valid Number.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if ((isAdmin || isSalesRep) && _selectedDealer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a dealer.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isAdmin || isSalesRep) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('vehicleId', isEqualTo: widget.vehicle.id)
          .where('dealerId', isEqualTo: _selectedDealer!.id)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'An offer has already been made for this dealer on this vehicle.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (isDealer) {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot dealerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (!dealerDoc.exists) return;

        bool isVerified = getIsVerified(dealerDoc);
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

  Future<void> _navigateToEditPage() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (vehicle.vehicleType.toLowerCase() == 'trailer') {
      await MyNavigator.push(
        context,
        EditTrailerScreen(
          vehicle: widget.vehicle,
        ),
      );
    } else {
      await MyNavigator.push(
          context, EditFormNavigation(vehicle: widget.vehicle));
    }
    setState(() {});
  }

  void _navigateToDuplicatePage() async {
    try {
      // debugPrint('=== Starting Vehicle Duplication ===');
      // debugPrint('Source Vehicle ID: ${vehicle.id}');

      if (vehicle.vehicleType.toLowerCase() == 'trailer') {
        // For trailers, navigate to the TrailerUploadScreen.
        await MyNavigator.push(
          context,
          TrailerUploadScreen(
            vehicle: widget.vehicle,
            isDuplicating: true,
            // You can pass other parameters if needed (e.g. isNewUpload, isAdminUpload)
          ),
        );
      } else {
        // For trucks, duplicate using the existing logic.
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
          damagesDescription: '',
          additionalFeatures: '',
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

        await MyNavigator.push(
          context,
          VehicleUploadScreen(
            vehicle: dup,
            isDuplicating: true,
          ),
        );
      }
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

  // Trailer section: Only shown when vehicle is a trailer.
  Widget _buildTrailerInfoSection() {
    // Debug print trailer details when building the section.
    if (widget.trailer != null) {
      debugPrint(
          "DEBUG: Building Trailer Info Section - Type: ${widget.trailer!.trailerType}, Axles: ${widget.trailer!.axles}, Length: ${widget.trailer!.length}");
    }
    String trailerInfoText = 'TRAILER INFORMATION';
    if (widget.trailer != null &&
        widget.trailer!.trailerType.trim().isNotEmpty) {
      trailerInfoText =
          '${widget.trailer!.trailerType.toUpperCase()} TRAILER INFORMATION';
    }

    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;
    final containerWidth = isLargeScreen ? 942.0 : size.width * 0.9;
    final containerPadding = isLargeScreen ? 37.31 : 20.0;
    const borderSideWidth = 0.93;
    const borderRadius = 20.0;
    const borderColor = Color(0xFF2F7FFF);
    final titleBoxHeight = isLargeScreen ? 76.48 : 45.0;
    final titleBoxPadding = isLargeScreen
        ? const EdgeInsets.symmetric(horizontal: 48.50, vertical: 18.65)
        : const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0);
    const titleBoxRadius = 6.0;
    final titleFontSize = isLargeScreen ? 20.0 : 16.0;
    final titleLetterSpace = isLargeScreen ? 1.87 : 1.0;

    return GestureDetector(
      onTap: () async {
        await MyNavigator.push(
          context,
          EditTrailerScreen(
            vehicle: widget.vehicle,
          ),
        );
        setState(() {});
      },
      child: Container(
        width: containerWidth,
        padding: EdgeInsets.all(containerPadding),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: ShapeDecoration(
          color: const Color(0x332F7FFF),
          shape: RoundedRectangleBorder(
            side: BorderSide(width: borderSideWidth, color: borderColor),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: titleBoxHeight,
              padding: titleBoxPadding,
              decoration: ShapeDecoration(
                color: borderColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(titleBoxRadius),
                ),
              ),
              child: Center(
                child: Text(
                  trailerInfoText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleFontSize,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w800,
                    letterSpacing: titleLetterSpace,
                  ),
                ),
              ),
            ),
            // (Optional) You can add a progress row here if needed.
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String progress) {
    final size = MediaQuery.of(context).size;
    final parts = progress.split('/');
    final current = int.tryParse(parts[0]) ?? 0;
    final total = int.tryParse(parts.length > 1 ? parts[1] : '1') ?? 1;
    final progressRatio = total == 0 ? 0.0 : (current / total);
    final isLargeScreen = size.width > 600;
    final containerWidth = isLargeScreen ? 942.0 : size.width * 0.9;
    final containerPadding = isLargeScreen ? 37.31 : 20.0;
    const borderSideWidth = 0.93;
    const borderRadius = 20.0;
    const borderColor = Color(0xFF2F7FFF);
    final titleBoxHeight = isLargeScreen ? 76.48 : 45.0;
    final titleBoxPadding = isLargeScreen
        ? const EdgeInsets.symmetric(horizontal: 48.50, vertical: 18.65)
        : const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0);
    const titleBoxRadius = 6.0;
    final titleFontSize = isLargeScreen ? 20.0 : 16.0;
    final titleLetterSpace = isLargeScreen ? 1.87 : 1.0;
    final progressFontSize = isLargeScreen ? 14.0 : 12.0;
    final progressLetterSp = isLargeScreen ? 2.24 : 1.0;
    final gapHeight = isLargeScreen ? 20.98 : 20.0;
    const progressBarHeight = 5.0;
    final progressSpacing = isLargeScreen ? 0.0 : 20.0;
    final displayProgress =
        title.contains('ADMIN') ? _calculateAdminProgressString() : progress;

    List<String> progressValues = progress.split('/');
    double first = double.parse(progressValues[0]);
    double second = double.parse(progressValues[1]);
    double progressValue = first / second;

    return GestureDetector(
      onTap: () {
        switch (title.replaceAll('\n', ' ').trim()) {
          case 'BASIC INFORMATION':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BasicInformationEdit(vehicle: vehicle),
              ),
            );
            break;
          case 'MAINTENANCE AND WARRANTY':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MaintenanceEditSection(
                  vehicleId: vehicle.id,
                  isUploading: false,
                  onMaintenanceFileSelected: (file) {},
                  onWarrantyFileSelected: (file) {},
                  oemInspectionType:
                      vehicle.maintenance.oemInspectionType ?? '',
                  oemInspectionExplanation: vehicle.maintenance.oemReason ?? '',
                  onProgressUpdate: () {},
                  maintenanceSelection:
                      vehicle.maintenance.maintenanceSelection ?? '',
                  warrantySelection:
                      vehicle.maintenance.warrantySelection ?? '',
                  isFromAdmin: Provider.of<UserProvider>(context, listen: false)
                          .getUserRole ==
                      'admin',
                  isFromTransporter: true,
                ),
              ),
            );
            break;
          case 'ADMIN':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminEditSection(
                  vehicle: vehicle,
                  isUploading: false,
                  isEditing: true,
                  onAdminDoc1Selected: (file, name) {},
                  onAdminDoc2Selected: (file, name) {},
                  onAdminDoc3Selected: (file, name) {},
                  requireToSettleType: vehicle.requireToSettleType ?? 'no',
                  settlementAmount: vehicle.adminData.settlementAmount,
                  natisRc1Url: vehicle.adminData.natisRc1Url,
                  licenseDiskUrl: vehicle.adminData.licenseDiskUrl,
                  settlementLetterUrl: vehicle.adminData.settlementLetterUrl,
                ),
              ),
            );
            break;
          default:
            if (title.contains('TRUCK')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExternalCabEditPage(
                    vehicleId: vehicle.id,
                    onProgressUpdate: () {
                      setState(() {});
                    },
                  ),
                ),
              );
            }
            break;
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 10).copyWith(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Prevents infinite height issues
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.green),
                      backgroundColor: Colors.grey.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    progress,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (title.contains('TRUCK CONDITION')) ...[
              subFields("EXTERNAL CAB", '${_calculateExternalCabProgress()}/7'),
              subFields(
                  "INTERNAL CAB", '${_calculateInternalCabProgress()}/20'),
              subFields("CHASSIS", '${_calculateChassisProgress()}/17'),
              subFields("DRIVE TRAIN", '${_calculateDriveTrainProgress()}/21'),
              subFields("TYRES", '${_calculateTyresProgress()}/24'),
            ],
          ],
        ),
      ),
    );
  }

  Widget subFields(String title, String progress) {
    List<String> progressValues = progress.split('/');
    double first = double.parse(progressValues[0]);
    double second = double.parse(progressValues[1]);
    // Clamp the value to be between 0.0 and 1.0
    double progressValue = (first / second).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Container(
          width: MediaQuery.of(context).size.width / 1.6,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.green),
                    backgroundColor: Colors.grey.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                progress,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransporterActionButtonsColumn() {
    const Color orangeColor = Color(0xFFFF4E00);
    final String vehicleStatus = vehicle.vehicleStatus.toLowerCase();
    bool isPending = (vehicleStatus == 'pending');
    bool isDraft = (vehicleStatus == 'draft');
    bool isLive = (vehicleStatus == 'live');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          CustomButton(
            text: 'Edit Vehicle',
            borderColor: orangeColor,
            onPressed: isPending ? null : _navigateToEditPage,
          ),
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
                                await MyNavigator.pushReplacement(
                                    context, VehiclesListPage());
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
          CustomButton(
            text: 'Duplicate Vehicle',
            borderColor: orangeColor,
            onPressed: _navigateToDuplicatePage,
          ),
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
              onPressed: null,
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

  Widget _buildAdminActionButtonsColumn() {
    final String vehicleStatus = vehicle.vehicleStatus.toLowerCase();
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
          CustomButton(
            text: 'Edit Vehicle',
            borderColor: orangeColor,
            onPressed: _navigateToEditPage,
          ),
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
                      onPressed: () => Navigator.pop(context),
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
                          Navigator.pop(context);
                          Navigator.pop(context);
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
          CustomButton(
            text: 'Duplicate Vehicle',
            borderColor: orangeColor,
            onPressed: _navigateToDuplicatePage,
          ),
          if (isAdmin && isDraft)
            CustomButton(
              text: 'Push to Live',
              borderColor: Colors.green,
              onPressed: () => _updateVehicleStatus('Live'),
            ),
          if (isAdmin && isPending)
            CustomButton(
              text: 'Approve for Live',
              borderColor: Colors.green,
              onPressed: () => _updateVehicleStatus('Live'),
            ),
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

  Widget _buildActionButton(IconData icon, Color backgroundColor) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool isAdmin = (userProvider.getUserRole == 'admin');

    if (isAdmin) {
      return const SizedBox.shrink();
    }

    bool isLiked = userProvider.getLikedVehicles.contains(vehicle.id);

    if (icon == Icons.close && !isLiked) {
      return const SizedBox.shrink();
    }

    return Expanded(
      child: GestureDetector(
        onTap: () async {
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId == null) return;

          if (icon == Icons.close) {
            try {
              await userProvider.unlikeVehicle(vehicle.id);
            } catch (e) {
              debugPrint('Error removing from favorites: $e');
            }
          } else if (icon == Icons.favorite && !isLiked) {
            try {
              await userProvider.likeVehicle(vehicle.id);
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

  int _calculateTruckConditionsProgress() {
    return _calculateExternalCabProgress() +
        _calculateInternalCabProgress() +
        _calculateDriveTrainProgress() +
        _calculateChassisProgress() +
        _calculateTyresProgress();
  }

  Widget _buildTruckConditionsSection(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;
    final containerWidth = isLargeScreen ? 942.0 : size.width * 0.9;
    final containerPadding = isLargeScreen ? 37.31 : 20.0;
    const borderSideWidth = 0.93;
    const borderRadius = 20.0;
    const borderColor = Color(0xFF2F7FFF);
    final titleBoxHeight = isLargeScreen ? 76.48 : 45.0;
    final titleBoxPadding = isLargeScreen
        ? const EdgeInsets.symmetric(horizontal: 48.50, vertical: 18.65)
        : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
    const titleBoxRadius = 6.0;
    final titleFontSize = isLargeScreen ? 20.0 : 14.0;
    final titleLetterSpace = isLargeScreen ? 1.87 : 0.5;
    final progressFontSize = isLargeScreen ? 22.38 : 12.0;
    final progressLetterSp = isLargeScreen ? 2.24 : 0.5;
    final gapHeight = isLargeScreen ? 27.98 : 16.0;
    const progressBarHeight = 5.0;
    final progressSpacing = isLargeScreen ? 26.11 : 12.0;

    int subSectionTotal = 35;
    int subSectionCompleted = _calculateTruckConditionsProgress();
    double topRatio =
        subSectionTotal == 0 ? 0 : (subSectionCompleted / subSectionTotal);

    return Container(
      width: containerWidth,
      padding: EdgeInsets.all(containerPadding),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: ShapeDecoration(
        color: const Color(0x332F7FFF),
        shape: RoundedRectangleBorder(
          side: BorderSide(width: borderSideWidth, color: borderColor),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isTruckConditionsExpanded = !_isTruckConditionsExpanded;
              });
            },
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: titleBoxHeight,
                  padding: titleBoxPadding,
                  decoration: ShapeDecoration(
                    color: borderColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(titleBoxRadius),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'TRUCK CONDITIONS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleFontSize,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w800,
                          height: 1.10,
                          letterSpacing: titleLetterSpace,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: gapHeight),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: progressBarHeight,
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: progressBarHeight,
                              decoration: const BoxDecoration(
                                color: Color(0x7F526584),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: topRatio,
                              child: Container(
                                height: progressBarHeight,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF39BB36),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: progressSpacing),
                    Text(
                      '$subSectionCompleted/$subSectionTotal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: progressFontSize,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w400,
                        height: 1.40,
                        letterSpacing: progressLetterSp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isTruckConditionsExpanded) ...[
            const SizedBox(height: 20),
            // _buildSubSectionItem(
            //   context: context,
            //   containerWidth: containerWidth,
            //   title: 'EXTERNAL CAB',
            //   onTap: () => MyNavigator.push(
            //     context,
            //     ExternalCabEditPage(
            //       vehicleId: widget.vehicle.id,
            //       onProgressUpdate: () {
            //         setState(() {
            //           _refreshVehicleData();
            //         });
            //       },
            //       isEditing: true,
            //     ),
            //   ),
            //   progressString: _calculateExternalCabProgressString(),
            //   progressRatio: _calculateExternalCabProgressPercentage(),
            //   titleBoxHeight: titleBoxHeight,
            //   titleBoxPadding: titleBoxPadding,
            //   borderColor: borderColor,
            //   gapHeight: gapHeight,
            //   progressBarHeight: progressBarHeight,
            //   progressSpacing: progressSpacing,
            //   titleFontSize: titleFontSize,
            //   titleLetterSpace: titleLetterSpace,
            //   progressFontSize: progressFontSize,
            //   progressLetterSp: progressLetterSp,
            //   titleBoxRadius: titleBoxRadius,
            // ),
            // _buildSubSectionItem(
            //   context: context,
            //   containerWidth: containerWidth,
            //   title: 'INTERNAL CAB',
            //   onTap: () => MyNavigator.push(
            //     context,
            //     InternalCabEditPage(
            //       vehicleId: widget.vehicle.id,
            //       onProgressUpdate: () {},
            //       isEditing: true,
            //     ),
            //   ),
            //   titleBoxHeight: titleBoxHeight,
            //   titleBoxPadding: titleBoxPadding,
            //   borderColor: borderColor,
            //   gapHeight: gapHeight,
            //   progressBarHeight: progressBarHeight,
            //   progressSpacing: progressSpacing,
            //   titleFontSize: titleFontSize,
            //   titleLetterSpace: titleLetterSpace,
            //   progressFontSize: progressFontSize,
            //   progressLetterSp: progressLetterSp,
            //   titleBoxRadius: titleBoxRadius,
            // ),
            // _buildSubSectionItem(
            //   context: context,
            //   containerWidth: containerWidth,
            //   title: 'CHASSIS',
            //   onTap: () => MyNavigator.push(
            //     context,
            //     ChassisEditPage(
            //       vehicleId: widget.vehicle.id,
            //       onProgressUpdate: () {},
            //       isEditing: true,
            //     ),
            //   ),
            //   progressString: _calculateChassisProgressString(),
            //   progressRatio: _calculateChassisProgressPercentage(),
            //   titleBoxHeight: titleBoxHeight,
            //   titleBoxPadding: titleBoxPadding,
            //   borderColor: borderColor,
            //   gapHeight: gapHeight,
            //   progressBarHeight: progressBarHeight,
            //   progressSpacing: progressSpacing,
            //   titleFontSize: titleFontSize,
            //   titleLetterSpace: titleLetterSpace,
            //   progressFontSize: progressFontSize,
            //   progressLetterSp: progressLetterSp,
            //   titleBoxRadius: titleBoxRadius,
            // ),
            // _buildSubSectionItem(
            //   context: context,
            //   containerWidth: containerWidth,
            //   title: 'DRIVE TRAIN',
            //   onTap: () => MyNavigator.push(
            //     context,
            //     DriveTrainEditPage(
            //       vehicleId: widget.vehicle.id,
            //       onProgressUpdate: () {},
            //       isEditing: true,
            //     ),
            //   ),
            //   progressString: _calculateDriveTrainProgressString(),
            //   progressRatio: _calculateDriveTrainProgressPercentage(),
            //   titleBoxHeight: titleBoxHeight,
            //   titleBoxPadding: titleBoxPadding,
            //   borderColor: borderColor,
            //   gapHeight: gapHeight,
            //   progressBarHeight: progressBarHeight,
            //   progressSpacing: progressSpacing,
            //   titleFontSize: titleFontSize,
            //   titleLetterSpace: titleLetterSpace,
            //   progressFontSize: progressFontSize,
            //   progressLetterSp: progressLetterSp,
            //   titleBoxRadius: titleBoxRadius,
            // ),
            // _buildSubSectionItem(
            //   context: context,
            //   containerWidth: containerWidth,
            //   title: 'TYRES',
            //   onTap: () => MyNavigator.push(
            //     context,
            //     TyresEditPage(
            //       vehicleId: widget.vehicle.id,
            //       onProgressUpdate: () {},
            //       isEditing: true,
            //     ),
            //   ),
            //   progressString: _calculateTyresProgressString(),
            //   progressRatio: _calculateTyresProgressPercentage(),
            //   titleBoxHeight: titleBoxHeight,
            //   titleBoxPadding: titleBoxPadding,
            //   borderColor: borderColor,
            //   gapHeight: gapHeight,
            //   progressBarHeight: progressBarHeight,
            //   progressSpacing: progressSpacing,
            //   titleFontSize: titleFontSize,
            //   titleLetterSpace: titleLetterSpace,
            //   progressFontSize: progressFontSize,
            //   progressLetterSp: progressLetterSp,
            //   titleBoxRadius: titleBoxRadius,
            // ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubSectionItem({
    required BuildContext context,
    required double containerWidth,
    required String title,
    required VoidCallback onTap,
    required String progressString,
    required double progressRatio,
    required double titleBoxHeight,
    required EdgeInsets titleBoxPadding,
    required Color borderColor,
    required double gapHeight,
    required double progressBarHeight,
    required double progressSpacing,
    required double titleFontSize,
    required double titleLetterSpace,
    required double progressFontSize,
    required double progressLetterSp,
    required double titleBoxRadius,
  }) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;
    final progressBarWidth = isLargeScreen
        ? (containerWidth * 0.6).clamp(0.0, 600.0)
        : containerWidth * 0.7;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 15),
        width: containerWidth * 0.8,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: progressBarWidth,
              height: titleBoxHeight,
              padding: titleBoxPadding,
              decoration: ShapeDecoration(
                color: borderColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(titleBoxRadius),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      title.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w800,
                        letterSpacing: titleLetterSpace,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: gapHeight),
            Container(
              width: progressBarWidth,
              constraints: BoxConstraints(maxWidth: 600),
              child: Row(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(2.5),
                          child: SizedBox(
                            height: progressBarHeight,
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: progressBarHeight,
                                  color: const Color(0x7F526584),
                                ),
                                Container(
                                  width: constraints.maxWidth *
                                      progressRatio.clamp(0.0, 1.0),
                                  height: progressBarHeight,
                                  color: const Color(0xFF39BB36),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: progressSpacing),
                  SizedBox(
                    width: 60,
                    child: Text(
                      progressString,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: progressFontSize,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w400,
                        height: 1.40,
                        letterSpacing: progressLetterSp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Helper to wrap an existing section widget inside a tap handler.
  Widget _buildEditableSection(
      BuildContext context, String title, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: _buildSection(context, title, '...progress...'),
    );
  }

  // ---------------------------------------------------------------------------
  //  BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final String userRole = userProvider.getUserRole.toLowerCase() ?? '';
    final size = MediaQuery.of(context).size;
    final bool isTrailer = (vehicle.vehicleType.toLowerCase() == 'trailer');
    const bool isWeb = kIsWeb;
    // Define the roles
    final bool isAdmin = userRole.toLowerCase() == 'admin';
    final bool isSalesRep = userRole.toLowerCase() == 'sales representative';
    final bool isDealer = userRole.toLowerCase() == 'dealer';
    final bool isTransporter = userRole.toLowerCase() == 'transporter';

    List<NavigationItem> navigationItems;
    if (userProvider.getUserRole == 'dealer') {
      navigationItems = [
        NavigationItem(title: 'Home', route: '/home'),
        NavigationItem(title: 'Search Trucks', route: '/truckPage'),
        NavigationItem(title: 'Wishlist', route: '/wishlist'),
        NavigationItem(title: 'Pending Offers', route: '/offers'),
      ];
    } else if (userProvider.getUserRole == 'admin' ||
        userProvider.getUserRole == 'sales representative') {
      navigationItems = [
        NavigationItem(title: 'Users', route: '/adminUsers'),
        NavigationItem(title: 'Offers', route: '/adminOffers'),
        NavigationItem(title: 'Complaints', route: '/adminComplaints'),
        NavigationItem(title: 'Vehicles', route: '/adminVehicles'),
      ];
    } else {
      navigationItems = [
        NavigationItem(title: 'Home', route: '/home'),
        NavigationItem(title: 'Your Trucks', route: '/transporterList'),
        NavigationItem(title: 'Your Offers', route: '/offers'),
        NavigationItem(title: 'In-Progress', route: '/in-progress'),
      ];
    }

    // Build offer–related widgets into a separate list
    List<Widget> offerWidgets = [];
    if (vehicle.isAccepted) {
      if (_isAcceptedOfferMine) {
        offerWidgets.add(
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Offer Status: ',
                  style: _customFont(20, FontWeight.bold, Colors.white),
                ),
                Text(
                  'Accepted',
                  style:
                      _customFont(20, FontWeight.bold, const Color(0xFFFF4E00)),
                ),
              ],
            ),
          ),
        );
      } else {
        offerWidgets.add(
          Center(
            child: Text(
              'Another dealer’s offer has already been accepted.\nNo new offers can be made.',
              style: _customFont(18, FontWeight.normal, Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
    } else if (_hasMadeOffer && _offerStatus != 'rejected') {
      offerWidgets.add(
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Offer Status: ',
                style: _customFont(20, FontWeight.bold, Colors.white),
              ),
              Text(
                getDisplayStatus(_offerStatus),
                style:
                    _customFont(20, FontWeight.bold, const Color(0xFFFF4E00)),
              ),
            ],
          ),
        ),
      );
    } else {
      // Only dealers should see the make offer section.
      if (userProvider.getUserRole == 'dealer') {
        // For dealers who can make a new offer
        List<Widget> makeOfferWidgets = [];
        if (!(userProvider.getUserRole == 'admin' ||
            userProvider.getUserRole == 'sales representative')) {
          makeOfferWidgets.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(Icons.close, const Color(0xFF2F7FFF)),
                const SizedBox(width: 16),
                _buildActionButton(Icons.favorite, const Color(0xFFFF4E00)),
              ],
            ),
          );
        }
        makeOfferWidgets.add(const SizedBox(height: 16));
        makeOfferWidgets.add(
          Center(
            child: Text(
              'Make an Offer',
              style: _customFont(20, FontWeight.bold, Colors.white),
            ),
          ),
        );
        makeOfferWidgets.add(const SizedBox(height: 8));
        if (userProvider.getUserRole == 'admin' ||
            userProvider.getUserRole == 'sales representative') {
          makeOfferWidgets.add(
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Dealer',
                style: _customFont(16, FontWeight.bold, Colors.white),
              ),
            ),
          );
          makeOfferWidgets.add(const SizedBox(height: 8));
          makeOfferWidgets.add(
            Consumer<UserProvider>(
              builder: (ctx, userProv, child) {
                if (userProv.dealers.isEmpty) {
                  return const Text(
                    'No dealers available.',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  );
                }
                List<Dealer> sortedDealers = List.from(userProv.dealers);
                sortedDealers.sort((a, b) {
                  String nameA = (a.firstName.trim().isNotEmpty &&
                          a.lastName.trim().isNotEmpty)
                      ? '${a.firstName} ${a.lastName}'
                      : a.email;
                  String nameB = (b.firstName.trim().isNotEmpty &&
                          b.lastName.trim().isNotEmpty)
                      ? '${b.firstName} ${b.lastName}'
                      : b.email;
                  return nameA.toLowerCase().compareTo(nameB.toLowerCase());
                });
                return DropdownButtonFormField<Dealer>(
                  value: _selectedDealer,
                  isExpanded: true,
                  items: sortedDealers.map((Dealer dealer) {
                    String displayName = (dealer.firstName.trim().isNotEmpty &&
                            dealer.lastName.trim().isNotEmpty)
                        ? '${dealer.firstName} ${dealer.lastName}'
                        : dealer.email;
                    return DropdownMenuItem<Dealer>(
                      value: dealer,
                      child: Text(displayName),
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
                    hintStyle: _customFont(16, FontWeight.normal, Colors.grey),
                  ),
                  dropdownColor: Colors.grey[800],
                  style: _customFont(16, FontWeight.normal, Colors.white),
                );
              },
            ),
          );
          makeOfferWidgets.add(const SizedBox(height: 16));
        }
        makeOfferWidgets.add(
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
              contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
            ),
            textAlign: TextAlign.center,
            style: _customFont(20, FontWeight.bold, Colors.white),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              setState(() {
                if (value.isNotEmpty) {
                  try {
                    String numericValue =
                        value.replaceAll(' ', '').replaceAll('R', '');
                    _offerAmount = double.parse(numericValue);
                    _totalCost = _calculateTotalCost(_offerAmount);
                    String formattedValue =
                        'R${_formatNumberWithSpaces(numericValue)}';
                    _controller.value = _controller.value.copyWith(
                      text: formattedValue,
                      selection: TextSelection.collapsed(
                          offset: formattedValue.length),
                    );
                  } catch (e) {
                    debugPrint('Error: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Invalid Offer Amount. Please Enter a Valid Number.'),
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
        );
        makeOfferWidgets.add(const SizedBox(height: 8));
        makeOfferWidgets.add(
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'R${_formatNumberWithSpaces(_totalCost.toStringAsFixed(0))}',
                  style: _customFont(18, FontWeight.bold, Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Including Commission and VAT',
                  style: _customFont(15, FontWeight.normal, Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Breakdown:',
                  style: _customFont(16, FontWeight.bold, Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Base Price: R ${_formatNumberWithSpaces(_offerAmount.toStringAsFixed(0))}',
                  style: _customFont(14, FontWeight.normal, Colors.white),
                ),
                Text(
                  'Flat Rate Fee: R 12 500',
                  style: _customFont(14, FontWeight.normal, Colors.white),
                ),
                Text(
                  'Subtotal: R ${_formatNumberWithSpaces((_offerAmount + 12500.0).toStringAsFixed(0))}',
                  style: _customFont(14, FontWeight.normal, Colors.white),
                ),
                Text(
                  'VAT (15%): R ${_formatNumberWithSpaces((((_offerAmount + 12500.0) * 0.15).toStringAsFixed(0)))}',
                  style: _customFont(14, FontWeight.normal, Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total Cost: R ${_formatNumberWithSpaces(_totalCost.toStringAsFixed(0))}',
                  style: _customFont(14, FontWeight.bold, Colors.white),
                ),
              ],
            ),
          ),
        );
        makeOfferWidgets.add(const SizedBox(height: 16));
        makeOfferWidgets.add(
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userProvider.userId)
                .snapshots(),
            builder: (ctx, snapshot) {
              if (snapshot.hasData && userProvider.getUserRole == 'dealer') {
                Map<String, dynamic> userData =
                    snapshot.data!.data() as Map<String, dynamic>;
                bool hasDocuments =
                    userData['cipcCertificateUrl']?.isNotEmpty == true &&
                        userData['brncUrl']?.isNotEmpty == true &&
                        userData['bankConfirmationUrl']?.isNotEmpty == true &&
                        userData['proxyUrl']?.isNotEmpty == true;
                bool isVerified = userData['isVerified'] ?? false;
                bool isApproved = isVerified;
                if (!hasDocuments || !isApproved) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Please upload all required documents (CIPC, BRNC, Bank Confirmation, Proxy) and wait for account approval before making offers.',
                      style: _customFont(16, FontWeight.normal, Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
              }
              return Container();
            },
          ),
        );
        makeOfferWidgets.add(
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
        );
        offerWidgets.addAll(makeOfferWidgets);
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      appBar: kIsWeb
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: (userRole == 'admin' || userRole == 'sales representative')
                  ? AdminWebNavigationBar(
                      isCompactNavigation: _isCompactNavigation(context),
                      currentRoute: ModalRoute.of(context)?.settings.name ??
                          '/vehicle_details',
                      onMenuPressed: () =>
                          _scaffoldKey.currentState?.openDrawer(),
                      onTabSelected: (index) {
                        switch (index) {
                          case 0:
                            Navigator.pushNamed(context, '/adminUsers');
                            break;
                          case 1:
                            Navigator.pushNamed(context, '/adminOffers');
                            break;
                          case 2:
                            Navigator.pushNamed(context, '/adminComplaints');
                            break;
                          case 3:
                            Navigator.pushNamed(context, '/adminVehicles');
                            break;
                        }
                      },
                    )
                  : WebNavigationBar(
                      isCompactNavigation: _isCompactNavigation(context),
                      currentRoute: ModalRoute.of(context)?.settings.name ??
                          '/vehicle_details',
                      onMenuPressed: () =>
                          _scaffoldKey.currentState?.openDrawer(),
                    ),
            )
          : (userRole == 'admin' || userRole == 'sales representative')
              ? AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${vehicle.brands.join(', ')} ${vehicle.makeModel.toUpperCase()} ${vehicle.year}',
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2F7FFF),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.menu,
                        color: Color(0xFFFF4E00), size: 24),
                    onPressed: () => _showNavigationDrawer(navigationItems),
                  ),
                )
              : AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.menu,
                        color: Color(0xFFFF4E00), size: 24),
                    onPressed: () => _showNavigationDrawer(navigationItems),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${vehicle.brands.join(', ')} ${vehicle.makeModel.toUpperCase()} ${vehicle.year}',
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
      drawer: (_isCompactNavigation(context) && isWeb)
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
                      child: Center(),
                    ),
                    Expanded(
                      child: ListView(
                        children: navigationItems.map((item) {
                          bool isActive =
                              ModalRoute.of(context)?.settings.name ==
                                  item.route;
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Stack(
                        children: <Widget>[
                          SingleChildScrollView(
                            child: Column(
                              children: <Widget>[
                                // === Image Gallery
                                Stack(
                                  children: [
                                    SizedBox(
                                      height: size.height * 0.32,
                                      child: PageView.builder(
                                        controller: _pageController,
                                        itemCount: allPhotos.length,
                                        onPageChanged: (index) {
                                          setState(
                                              () => _currentImageIndex = index);
                                        },
                                        itemBuilder: (context, index) {
                                          return GestureDetector(
                                            onTap: () => _showFullScreenImage(
                                                context, index),
                                            child: Stack(
                                              children: [
                                                Image.network(
                                                  allPhotos[index].url,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: size.height * 0.32,
                                                  cacheWidth: kIsWeb
                                                      ? null
                                                      : (MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              2)
                                                          .toInt(),
                                                  key: ValueKey(
                                                      '${allPhotos[index].url}-${MediaQuery.of(context).size.width}'),
                                                  errorBuilder:
                                                      (ctx, error, st) {
                                                    return Image.asset(
                                                      'assets/default_vehicle_image.png',
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      height:
                                                          size.height * 0.32,
                                                    );
                                                  },
                                                ),
                                                IgnorePointer(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                        colors: [
                                                          Colors.black
                                                              .withOpacity(0.3),
                                                          Colors.black
                                                              .withOpacity(1),
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
                                        child: _buildImageIndicators(
                                            allPhotos.length),
                                      ),
                                    ),
                                  ],
                                ),
                                // === Details and Offer Info
                                Container(
                                  width: double.infinity,
                                  constraints:
                                      const BoxConstraints(maxWidth: 800),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: widget.vehicle.vehicleType
                                                      .toLowerCase() ==
                                                  'trailer'
                                              ? [
                                                  _buildInfoContainer(
                                                      'Trailer Type',
                                                      widget.vehicle
                                                              .trailerType ??
                                                          'N/A'),
                                                  const SizedBox(width: 5),
                                                  _buildInfoContainer(
                                                      'Length',
                                                      widget.vehicle.trailer
                                                              ?.length ??
                                                          'N/A'),
                                                  const SizedBox(width: 5),
                                                  _buildInfoContainer(
                                                      'Axles',
                                                      widget.vehicle.trailer
                                                              ?.axles ??
                                                          'N/A'),
                                                ]
                                              : [
                                                  _buildInfoContainer(
                                                      'Year', vehicle.year),
                                                  const SizedBox(width: 5),
                                                  _buildInfoContainer('Mileage',
                                                      vehicle.mileage),
                                                  const SizedBox(width: 5),
                                                  _buildInfoContainer('Gearbox',
                                                      vehicle.transmissionType),
                                                  const SizedBox(width: 5),
                                                  _buildInfoContainer(
                                                      'Config', vehicle.config),
                                                ],
                                        ),
                                        const SizedBox(height: 16),
                                        if (offerWidgets.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Column(
                                              children: offerWidgets,
                                            ),
                                          ),
                                        // Action Buttons Section:
                                        userProvider.getUserRole ==
                                                'transporter'
                                            ? _buildTransporterActionButtonsColumn()
                                            : (userProvider.getUserRole ==
                                                        'admin' ||
                                                    userProvider.getUserRole ==
                                                        'sales representative')
                                                ? _buildAdminActionButtonsColumn()
                                                : Container(),
                                        const SizedBox(height: 16),
                                        if (isTrailer)
                                          _buildTrailerInfoSection()
                                        else
                                          Column(
                                            children: [
                                              _buildSection(
                                                context,
                                                'BASIC INFORMATION',
                                                '${_calculateBasicInfoProgress()}/21',
                                              ),
                                              // Truck Conditions block
                                              if (isDealer ||
                                                  isAdmin ||
                                                  isSalesRep)
                                                _buildSection(
                                                  context,
                                                  'TRUCK CONDITIONS',
                                                  '${_calculateTruckConditionsProgress()}/86',
                                                ),
                                              // Maintenance & Warranty
                                              if (isDealer ||
                                                  isAdmin ||
                                                  isSalesRep)
                                                _buildSection(
                                                  context,
                                                  'MAINTENANCE AND WARRANTY',
                                                  '${_calculateMaintenanceProgress()}/4',
                                                ),
                                            ],
                                          ),
                                        const SizedBox(height: 30),
                                        if (userProvider.getUserRole ==
                                            'transporter')
                                          Column(
                                            children: [
                                              Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 10.0),
                                                child: vehicle.isAccepted ==
                                                        true
                                                    ? Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(16.0),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.red
                                                              .withOpacity(0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                          border: Border.all(
                                                              color:
                                                                  Colors.red),
                                                        ),
                                                        child: Column(
                                                          children: [
                                                            const Icon(
                                                                Icons
                                                                    .warning_amber_rounded,
                                                                color:
                                                                    Colors.red,
                                                                size: 40),
                                                            const SizedBox(
                                                                height: 8),
                                                            Text(
                                                              "This vehicle has an accepted offer",
                                                              style:
                                                                  _customFont(
                                                                      20,
                                                                      FontWeight
                                                                          .bold,
                                                                      Colors
                                                                          .red),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                            Text(
                                                              "No new offers can be placed",
                                                              style: _customFont(
                                                                  16,
                                                                  FontWeight
                                                                      .normal,
                                                                  Colors.red),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    : Container(),
                                              ),
                                              Text(
                                                'Offers Made on This Vehicle (${vehicle.referenceNumber}):',
                                                style: _customFont(
                                                    20,
                                                    FontWeight.bold,
                                                    const Color(0xFFFF4E00)),
                                              ),
                                              const SizedBox(height: 10),
                                              _buildOffersList(),
                                            ],
                                          ),
                                        const SizedBox(height: 24),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isLoading)
                            Container(
                              color: Colors.black54,
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFFFF4E00)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

  bool isNotEmpty(String? value) {
    return value != null && value != "N/A";
  }

  int _calculateBasicInfoProgress() {
    int completedSteps = 9;
    const totalSteps = 15; // Total number of possible fields

    // Main image
    if (isNotEmpty(vehicle.mainImageUrl)) completedSteps++;
    // Vehicle status
    // if (isNotEmpty(vehicle?.vehicleStatus)) completedSteps++;
    // Reference number
    // if (isNotEmpty(vehicle?.referenceNumber)) completedSteps++;
    // RC1/NATIS file
    if (isNotEmpty(vehicle.rc1NatisFile)) completedSteps++;
    // Vehicle type (truck/trailer)
    if (isNotEmpty(vehicle.vehicleType)) completedSteps++;
    // Year
    if (isNotEmpty(vehicle.year)) completedSteps++;
    // Make/Model
    if (isNotEmpty(vehicle.makeModel)) completedSteps++;
    // Variant
    if (isNotEmpty(vehicle.variant)) completedSteps++;
    // Country
    if (isNotEmpty(vehicle.country)) completedSteps++;
    // Mileage
    if (isNotEmpty(vehicle.mileage)) completedSteps++;
    // Configuration
    if (isNotEmpty(vehicle.config)) completedSteps++;
    // Application
    if (vehicle.application.isNotEmpty == true) completedSteps++;
    // VIN Number
    // if (isNotEmpty(vehicle?.vinNumber)) completedSteps++;
    // Engine Number
    if (isNotEmpty(vehicle.engineNumber)) completedSteps++;
    // Registration Number
    if (isNotEmpty(vehicle.registrationNumber)) completedSteps++;
    return completedSteps;
  }

  String _calculateBasicInfoProgressString() {
    final basicFields = [
      widget.vehicle.mainImageUrl!.isNotEmpty,
      widget.vehicle.year.toString(),
      widget.vehicle.brands,
      widget.vehicle.makeModel,
      widget.vehicle.variant,
      widget.vehicle.country,
      widget.vehicle.mileage,
      widget.vehicle.config,
      widget.vehicle.application,
      widget.vehicle.suspensionType,
      widget.vehicle.transmissionType,
      widget.vehicle.hydraluicType,
      widget.vehicle.warrentyType,
      widget.vehicle.maintenance,
      widget.vehicle.requireToSettleType,
    ];
    int total = basicFields.length;
    int completed = basicFields
        .where((field) => field != null && field.toString().trim().isNotEmpty)
        .length;
    return "$completed/$total";
  }

  int _calculateMaintenanceProgress() {
    int completedSteps = 0;
    const totalSteps = 4; // Total possible fields

    // Check maintenance document
    if (vehicle.maintenance.maintenanceDocUrl != null) completedSteps++;
    // Check warranty document
    if (vehicle.maintenance.warrantyDocUrl != null) completedSteps++;
    // Check OEM inspection type
    if (vehicle.maintenance.oemInspectionType != null) completedSteps++;
    // Check OEM reason if inspection type is 'no'
    if (vehicle.maintenance.oemInspectionType == 'no' &&
        vehicle.maintenance.oemReason?.isNotEmpty == true) {
      completedSteps++;
    }

    return completedSteps;
  }

  String _calculateMaintenanceProgressString() {
    final maintenanceFields = [
      widget.vehicle.maintenance.maintenanceDocUrl,
      widget.vehicle.maintenance.oemInspectionType,
      widget.vehicle.maintenance.warrantyDocUrl,
    ];
    int total = maintenanceFields.length;
    int completed = maintenanceFields
        .where((field) => field != null && field.toString().trim().isNotEmpty)
        .length;
    return "$completed/$total";
  }

  String _calculateExternalCabProgressString() {
    final ext = vehicle.truckConditions.externalCab;
    List<bool> completedFields = [];
    completedFields.add(_isNotEmpty(ext.condition));
    completedFields.add(_isNotEmpty(ext.damagesCondition));
    completedFields.add(_isNotEmpty(ext.additionalFeaturesCondition));
    final requiredImageKeys = [
      "FRONT VIEW",
      "LEFT SIDE VIEW",
      "REAR VIEW",
      "RIGHT SIDE VIEW"
    ];
    for (String key in requiredImageKeys) {
      var photoData = ext.images[key];
      bool hasImage = false;
      if (photoData != null) {
        bool hasPath = photoData.path.isNotEmpty;
        bool hasUrl = (photoData.imageUrl ?? '').isNotEmpty;
        hasImage = hasPath || hasUrl;
      }
      completedFields.add(hasImage);
    }
    int total = completedFields.length;
    int completed = completedFields.where((field) => field).length;
    return "$completed/$total";
  }

  int _calculateExternalCabProgress() {
    int completedSteps = 0;
    int totalSteps = 6; // Base fields: condition, damages, additional features

    final externalCab = vehicle.truckConditions.externalCab;

    // Check main condition
    if (externalCab.condition.isNotEmpty == true) completedSteps++;

    // Check images
    // if (externalCab?.images.isNotEmpty == true) completedSteps++;
    completedSteps += externalCab.images.length ?? 0;

    // Check damages section
    if (externalCab.damagesCondition.isNotEmpty == true) {
      completedSteps++;
    }

    // Check additional features section
    if (externalCab.additionalFeaturesCondition.isNotEmpty == true) {
      completedSteps++;
    }

    return completedSteps;
  }

  int _calculateInternalCabProgress() {
    int completedSteps = 0;
    int totalSteps =
        19; // Base fields: condition, damages, additional features, fault codes, view images

    final internalCab = vehicle.truckConditions.internalCab;

    // Check main condition
    if (internalCab.condition.isNotEmpty == true) completedSteps++;

    // Check view images
    // if (internalCab?.viewImages.isNotEmpty == true) completedSteps++;
    completedSteps += internalCab.viewImages.length ?? 0;
    print("InternalCabImages: ${internalCab.viewImages.length}");

    // Check damages section
    if (internalCab.damagesCondition.isNotEmpty == true) completedSteps++;

    // Check additional features section
    if (internalCab.additionalFeaturesCondition.isNotEmpty == true) {
      completedSteps++;
    }

    // Check fault codes section
    if (internalCab.faultCodesCondition.isNotEmpty == true) completedSteps++;

    return completedSteps;
  }

  int _calculateDriveTrainProgress() {
    int completedSteps = 0;
    int totalSteps = 20; // All fields from the DriveTrain model

    final driveTrain = vehicle.truckConditions.driveTrain;

    // Check main condition
    if (driveTrain.condition.isNotEmpty == true) completedSteps++;

    // Check engine conditions
    if (driveTrain.oilLeakConditionEngine.isNotEmpty == true) completedSteps++;
    if (driveTrain.waterLeakConditionEngine.isNotEmpty == true) {
      completedSteps++;
    }
    if (driveTrain.blowbyCondition.isNotEmpty == true) completedSteps++;

    // Check gearbox and retarder conditions
    if (driveTrain.oilLeakConditionGearbox.isNotEmpty == true) {
      completedSteps++;
    }
    if (driveTrain.retarderCondition.isNotEmpty == true) completedSteps++;

    // Check images
    // if (driveTrain?.images.isNotEmpty == true) completedSteps++;
    completedSteps += driveTrain.images.length ?? 0;

    // Check damages
    if (driveTrain.damages.isNotEmpty == true) completedSteps++;

    // Check additional features
    if (driveTrain.additionalFeatures.isNotEmpty == true) completedSteps++;

    // Check fault codes
    if (driveTrain.faultCodes.isNotEmpty == true) completedSteps++;
    // completedSteps += driveTrain?.faultCodes.length ?? 0;

    return completedSteps;
  }

  int _calculateChassisProgress() {
    int completedSteps = 0;
    int totalSteps =
        16; // Base fields: condition, images, damages, additional features

    final chassis = vehicle.truckConditions.chassis;

    // Check main condition
    if (chassis.condition.isNotEmpty == true) completedSteps++;

    // Check images
    // if (chassis?.images.isNotEmpty == true) completedSteps++;
    completedSteps += chassis.images.length ?? 0;

    // Check damages section
    if (chassis.damagesCondition.isNotEmpty == true) completedSteps++;

    // Check additional features section
    if (chassis.additionalFeaturesCondition.isNotEmpty == true) {
      completedSteps++;
    }

    return completedSteps;
  }

  int _calculateTyresProgress() {
    int completedSteps = 0;
    int totalSteps = 24;

    final tyresMap = vehicle.truckConditions.tyres;
    tyresMap.forEach((key, tyres) {
      // Loop through tyre positions
      for (int pos = 1; pos <= 6; pos++) {
        String posKey = 'Tyre_Pos_$pos';
        final tyreData =
            tyres.positions[posKey]; // Access `positions` from `Tyres`

        if (tyreData?.chassisCondition != null &&
            tyreData!.chassisCondition.isNotEmpty) {
          completedSteps++;
        }
        if (tyreData?.virginOrRecap != null &&
            tyreData!.virginOrRecap.isNotEmpty) {
          completedSteps++;
        }
        if (tyreData?.imagePath != null && tyreData!.imagePath.isNotEmpty) {
          completedSteps++;
        }
        if (tyreData?.rimType != null && tyreData!.rimType.isNotEmpty) {
          completedSteps++;
        }
      }
    });

    return completedSteps;
  }

  bool _isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  String _calculateAdminProgressString() {
    int completed = 0;
    int total = 3;
    if (widget.vehicle.adminData.natisRc1Url.isNotEmpty ?? false) {
      completed++;
    }
    if (widget.vehicle.adminData.licenseDiskUrl.isNotEmpty ?? false) {
      completed++;
    }
    if (widget.vehicle.requireToSettleType == 'yes') {
      total++;
      if (widget.vehicle.adminData.settlementLetterUrl.isNotEmpty ?? false) {
        completed++;
      }
      if (widget.vehicle.adminData.settlementAmount.isNotEmpty ?? false) {
        completed++;
      }
    }
    return "$completed/$total";
  }

  int _calculateAdminProgress() {
    int completedSteps = 0;
    const totalSteps = 4; // Total possible fields

    // NATIS/RC1 document
    completedSteps++;
    // License disk
    completedSteps++;
    // Settlement letter (if required)
    if (vehicle.requireToSettleType == 'yes') {
      completedSteps++;
      if (vehicle.adminData.settlementAmount.isNotEmpty == true) {
        completedSteps++;
      }
    }

    return completedSteps;
  }

  void _showNavigationDrawer(List<NavigationItem> items) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final currentRoute =
            ModalRoute.of(context)?.settings.name ?? '/vehicle_details';
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black54),
            ),
            Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.black, Color(0xFF2F7FFD)],
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 20,
                        bottom: 20,
                        left: 16,
                        right: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white24),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: items.map((item) {
                          bool isActive =
                              ModalRoute.of(context)?.settings.name ==
                                  item.route;
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
            ),
          ],
        );
      },
    );
  }
}
