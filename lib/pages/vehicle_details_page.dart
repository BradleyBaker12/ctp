import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ctp/pages/home_page.dart';
import 'package:ctp/pages/profile_page.dart';
import 'package:ctp/pages/truck_page.dart';
import 'package:ctp/pages/wishlist_offers_page.dart';

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

  @override
  void initState() {
    super.initState();
    _checkIfOfferMade();
  }

  Future<void> _checkIfOfferMade() async {
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
      _hasMadeOffer = offersSnapshot.docs.isNotEmpty;
    });
  }

  TextStyle _customFont(double fontSize, FontWeight fontWeight, Color color) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFamily: 'Montserrat',
    );
  }

  double _calculateTotalCost(double basePrice) {
    const double vatRate = 0.15;
    const double flatRateFee = 12000.0;
    double vat = basePrice * vatRate;
    return basePrice + vat + flatRateFee;
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
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer submitted successfully!'),
          backgroundColor: Colors.green, // Set the background color to green
        ),
      );
    } catch (e) {
      print('Error making offer: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error submitting offer. Please try again.'),
          backgroundColor:
              Colors.red, // Set the background color to red for errors
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
        infoWidgets.add(_buildInfoRow(title, value));
      }
    }

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    List<String> allPhotos = [
      if (widget.vehicle.mainImageUrl != null) widget.vehicle.mainImageUrl!,
      ...widget.vehicle.photos.where((photo) => photo != null).cast<String>(),
      if (widget.vehicle.dashboardPhoto != null) widget.vehicle.dashboardPhoto!,
      if (widget.vehicle.faultCodesPhoto != null)
        widget.vehicle.faultCodesPhoto!,
      if (widget.vehicle.licenceDiskUrl != null) widget.vehicle.licenceDiskUrl!,
      if (widget.vehicle.tyrePhoto1 != null) widget.vehicle.tyrePhoto1!,
      if (widget.vehicle.tyrePhoto2 != null) widget.vehicle.tyrePhoto2!,
      ...widget.vehicle.damagePhotos
          .where((photo) => photo != null)
          .cast<String>(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicle.makeModel ?? 'Unknown',
            style: _customFont(20, FontWeight.bold, Colors.white)),
        backgroundColor: Colors.black,
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
                      height: size.height * 0.3,
                      child: PageView.builder(
                        itemCount: allPhotos.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Image.network(
                            allPhotos[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: size.height * 0.3,
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
                      Text(widget.vehicle.makeModel ?? 'Unknown',
                          style:
                              _customFont(24, FontWeight.bold, Colors.white)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInfoContainer('YEAR', widget.vehicle.year),
                          const SizedBox(width: 8),
                          _buildInfoContainer(
                              'MILEAGE', widget.vehicle.mileage),
                          const SizedBox(width: 8),
                          _buildInfoContainer(
                              'TRANSMISSION', widget.vehicle.transmission),
                          const SizedBox(width: 8),
                          _buildInfoContainer('CONFIG', '6X4'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!_hasMadeOffer)
                        Column(
                          children: [
                            Text('Make an Offer',
                                style: _customFont(
                                    20, FontWeight.bold, Colors.white)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _controller,
                              cursorColor: const Color(0xFFFF4E00),
                              decoration: InputDecoration(
                                hintText: '102 000 000',
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
                              onChanged: (value) {
                                setState(() {
                                  if (value.isNotEmpty) {
                                    _offerAmount = double.parse(value
                                        .replaceAll(' ', '')
                                        .replaceAll(',', ''));
                                    _totalCost =
                                        _calculateTotalCost(_offerAmount);
                                  } else {
                                    _offerAmount = 0.0;
                                    _totalCost = 0.0;
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                "R ${_totalCost.toStringAsFixed(2)} inc VAT plus comm",
                                style: _customFont(
                                    18, FontWeight.bold, Colors.white),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _makeOffer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF4E00),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text('MAKE AN OFFER',
                                    style: _customFont(
                                        24, FontWeight.bold, Colors.white)),
                              ),
                            ),
                          ],
                        )
                      else
                        Center(
                          child: Text(
                            "Offer Pending",
                            style: _customFont(
                                20, FontWeight.bold, Color(0xFFFF4E00)),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.play_arrow,
                              color: Color(0xFFFF4E00)),
                          Text('ADDITIONAL INFO',
                              style: _customFont(
                                  20, FontWeight.bold, Colors.blue)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildAdditionalInfo(),
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
                child: CircularProgressIndicator(),
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
    return Flexible(
      child: Container(
        height: 90,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: _customFont(12, FontWeight.bold, Colors.grey)),
            const SizedBox(height: 4),
            Text(value ?? 'Unknown',
                style: _customFont(16, FontWeight.bold, Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageIndicators(int numImages) {
    double indicatorWidth = 50.0;
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
          height: 10,
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
}
