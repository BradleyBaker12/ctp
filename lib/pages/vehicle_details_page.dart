import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

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
  List<String> allPhotos = [];
  late PageController _pageController;
  String _offerStatus = 'in-progress'; // default status for the offer

  @override
  void initState() {
    super.initState();
    _checkIfOfferMade();

    try {
      allPhotos = [];

      // Ensure the main image is added first
      if (widget.vehicle.mainImageUrl != null &&
          widget.vehicle.mainImageUrl!.isNotEmpty) {
        allPhotos.add(widget.vehicle.mainImageUrl!);
        print('Main Image Added: ${widget.vehicle.mainImageUrl}');
      }

      // Additional photo fields
      _addPhotoIfExists(widget.vehicle.bed_bunk, 'Bed Bunk Photo');
      _addPhotoIfExists(widget.vehicle.dashboard, 'Dashboard Photo');
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
  void _addPhotoIfExists(String? photoUrl, String photoType) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      allPhotos.add(photoUrl);
      print('$photoType Added: $photoUrl');
    } else {
      print('$photoType is null or empty');
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

  TextStyle _customFont(double fontSize, FontWeight fontWeight, Color color) {
    return GoogleFonts.montserrat(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  double _calculateTotalCost(double basePrice) {
    const double vatRate = 0.15;
    const double flatRateFee = 12500.0;
    double subTotal = basePrice + flatRateFee;
    double vat = subTotal * vatRate;
    return subTotal + vat;
  }

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

  Widget _buildInfoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: _customFont(14, FontWeight.normal, Colors.white)),
          Text(value ?? 'Unknown',
              style: _customFont(14, FontWeight.bold, Colors.white)),
        ],
      ),
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
              Text(title,
                  style: _customFont(14, FontWeight.normal, Colors.white)),
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

  String _formatNumberWithSpaces(String number) {
    return number.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }

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

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    final userProvider = Provider.of<UserProvider>(context);
    final bool isTransporter = userProvider.getUserRole == 'transporter';
    var blue = const Color(0xFF2F7FFF);

    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // Set the background color to white
        elevation: 0, // Remove the shadow under the AppBar
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  widget.vehicle.makeModel.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 20, // Adjust the font size as needed
                    fontWeight: FontWeight.bold,
                    color: blue, // Set the color to blue as in the image
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.verified,
                    color: Color(0xFFFF4E00), size: 24), // Verified icon
              ],
            ),
            const Icon(Icons.arrow_drop_down,
                color: Color(0xFFFF4E00), size: 40), // Right aligned arrow
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFFFF4E00), size: 20), // Custom back arrow color
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
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
                                  allPhotos[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: size.height * 0.45,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/default_vehicle_image.png', // Correct path
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
                          SizedBox(
                            width: 5,
                          ),
                          _buildInfoContainer(
                              'MILEAGE', widget.vehicle.mileage),
                          SizedBox(
                            width: 5,
                          ),
                          _buildInfoContainer(
                              'GEARBOX', widget.vehicle.transmission),
                          SizedBox(
                            width: 5,
                          ),
                          _buildInfoContainer('CONFIG', widget.vehicle.config),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!_hasMadeOffer && !isTransporter)
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
                                      // Format the input value
                                      String formattedValue =
                                          _formatNumberWithSpaces(value);
                                      _controller.value =
                                          _controller.value.copyWith(
                                        text: formattedValue,
                                        selection: TextSelection.collapsed(
                                            offset: formattedValue.length),
                                      );

                                      // Remove spaces for calculation
                                      _offerAmount = double.parse(
                                          value.replaceAll(' ', ''));
                                      _totalCost =
                                          _calculateTotalCost(_offerAmount);
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
                      else if (!isTransporter)
                        Center(
                          child: Text(
                            "Offer Status: ${getDisplayStatus(_offerStatus)}", // Display offer status
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
                      SizedBox(height: 30),
                      Text(
                        "Discover the Power and Performance You Need: Our Semi Trucks Are Built to Drive Your Success Forward!",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5),
                      ),
                      SizedBox(height: 25),
                      Text(
                        "Looking for reliability, efficiency, and cutting-edge technology in your next semi-truck purchase? Look no further! Our fleet of semi trucks offers top-of-the-line performance to meet the demands of your toughest routes and deliver your cargo on time, every time.",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                            fontSize: 13.5),
                      )
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
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: 1,
        onItemTapped: (index) {
          setState(() {});
        },
      ),
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
                  screenSize.height * 0.017, FontWeight.bold, Colors.white),
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
    _pageController = PageController(
        initialPage: initialIndex); // Ensure PageController is initialized here

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
                  return InteractiveViewer(
                    child: Image.network(
                      allPhotos[index],
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  );
                },
              ),
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
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
