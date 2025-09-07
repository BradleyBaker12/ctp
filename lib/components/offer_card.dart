import 'dart:ui';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/collectionPages/collection_confirmationPage.dart';
import 'package:ctp/pages/collectionPages/collection_details_page.dart';
import 'package:ctp/pages/payment_approved.dart';
import 'package:flutter/material.dart';
import 'package:ctp/pages/transport_offer_details_page.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ctp/pages/inspectionPages/final_inspection_approval_page.dart';
import 'package:ctp/pages/bulk_offer_details_page.dart';
import 'package:ctp/pages/inspectionPages/inspection_details_page.dart';
import 'package:ctp/pages/payment_options_page.dart';
import 'package:ctp/pages/payment_pending_page.dart';
import 'package:ctp/pages/inspectionPages/location_confirmation_page.dart';
import 'package:ctp/pages/inspectionPages/confirmation_page.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/providers/complaints_provider.dart';
import 'package:flutter/foundation.dart';

class OfferCard extends StatefulWidget {
  final Offer offer;
  final Function? onPop;

  const OfferCard({
    super.key,
    required this.offer,
    this.onPop,
  });

  @override
  _OfferCardState createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  // State variables for transmission, config, mileage, and vehicleYear.
  String? transmissionType;
  String? vehicleConfig;
  String? mileage;
  String? vehicleYear; // New state variable for the year
  // Bulk vehicles for bulk offers
  List<Vehicle>? _bulkVehicles;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForResolvedComplaints();
      _fetchVehicleDetails();
    });
  }

  Future<void> _checkForResolvedComplaints() async {
    final complaintsProvider =
        Provider.of<ComplaintsProvider>(context, listen: false);
    await complaintsProvider.fetchComplaints(widget.offer.offerId);
    final resolvedComplaint =
        complaintsProvider.getResolvedComplaint(widget.offer.offerId);

    if (resolvedComplaint != null &&
        widget.offer.offerStatus == 'Issue reported') {
      if (mounted) {
        setState(() {
          widget.offer.offerStatus = resolvedComplaint.previousStep;
        });
      }
    }
  }

  /// Fetch basic vehicle details from Firestore (including the year).
  Future<void> _fetchVehicleDetails() async {
    try {
      if (widget.offer.vehicleIds != null &&
          widget.offer.vehicleIds!.isNotEmpty) {
        // Bulk: fetch multiple
        final snap = await FirebaseFirestore.instance
            .collection('vehicles')
            .where(FieldPath.documentId, whereIn: widget.offer.vehicleIds)
            .get();
        if (mounted) {
          setState(() {
            _bulkVehicles =
                snap.docs.map((d) => Vehicle.fromDocument(d)).toList();
          });
        }
      } else {
        // Single
        // debugPrint(
        //     'Fetching vehicle details for ID: ${widget.offer.vehicleId}');
        final vehicleDoc = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.offer.vehicleId)
            .get();
        if (vehicleDoc.exists && mounted) {
          final data = vehicleDoc.data();
          setState(() {
            transmissionType = data?['transmissionType'];
            vehicleConfig = data?['config'];
            mileage = data?['mileage'];
            vehicleYear = data?['year']?.toString();
            final vehicleType = data?['vehicleType']?.toString().toLowerCase();
            if (vehicleType == 'trailer') {
              // For trailer offers, show make (from makeModel) and year.
              widget.offer.vehicleBrand = data?['makeModel']?.toString();
              widget.offer.variant = '';
            } else {
              // Existing logic for trucks
              if (data?['brands'] != null) {
                if (data?['brands'] is List) {
                  widget.offer.vehicleBrand =
                      (data?['brands'] as List).first.toString();
                } else {
                  widget.offer.vehicleBrand = data?['brands'].toString();
                }
              }
              widget.offer.variant = data?['variant']?.toString();
            }
            // debugPrint('Updated brand: ${widget.offer.vehicleBrand}');
            // debugPrint('Updated variant: ${widget.offer.variant}');
          });
        }
      }
    } catch (e) {
      // debugPrint('Error fetching vehicle details: $e');
    }
  }

  TextStyle customFont(double size, FontWeight weight, Color color) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  Color getStatusColor(String? status) {
    final normalizedStatus = (status ?? '').toLowerCase().trim();
    debugPrint('Getting status color for normalized status: $normalizedStatus');

    switch (normalizedStatus) {
      case 'sold':
        return Colors.red;
      // Success states - Green
      case 'accepted':
      case 'done':
      case 'paid':
      case 'successful':
      case 'completed':
      case 'inspection done':
      case 'payment approved':
        return Colors.green;
      // Failed states - Red
      case 'rejected':
        return Colors.red;
      // Warning states - Orange
      case 'issue reported':
        return Colors.orange;
      // Payment states - Purple
      case 'payment pending':
      case 'payment options':
        return Colors.purple;
      // Location states - Blue
      case 'set location and time':
      case 'confirm location':
      case 'collection location confirmation':
      case 'collection details':
      case 'confirm collection':
        return Colors.blue;
      // In-progress state - Gray
      case 'in-progress':
        return Colors.grey;
      // Default state - Light Blue
      case 'inspection pending':
      default:
        return const Color(0xFF2F7FFF);
    }
  }

  String formatOfferAmount(double? amount) {
    if (amount == null) return 'Unknown';
    final formattedAmount = NumberFormat.currency(
      locale: 'en_ZA',
      symbol: 'R',
      decimalDigits: 0,
    ).format(amount);
    return formattedAmount.replaceAll(',', ' ');
  }

  IconData getStatusIcon(String? status) {
    final normalizedStatus = (status ?? '').toLowerCase().trim();
    // debugPrint('Getting status icon for normalized status: $normalizedStatus');

    switch (normalizedStatus) {
      case 'sold':
        return Icons.sell;
      // Completed/Success states
      case 'accepted':
      case 'done':
      case 'paid':
      case 'successful':
      case 'completed':
      case 'payment approved':
      case 'awaiting collection':
        return Icons.check_circle;
      // Rejected/Failed states
      case 'rejected':
        return Icons.cancel;
      // Warning/Issue states
      case 'issue reported':
        return Icons.report_problem;
      // Payment states
      case 'payment pending':
      case 'payment options':
        return Icons.payments;
      // Inspection states
      case 'inspection pending':
      case 'inspection done':
        return Icons.check_box;
      // Location/Collection states
      case 'set location and time':
      case 'confirm location':
      case 'collection location confirmation':
      case 'collection details':
      case 'confirm collection':
        return Icons.location_on;
      // In-progress/Default state
      case 'in-progress':
        return Icons.sync;
      default:
        return Icons.sync;
    }
  }

  void navigateBasedOnStatus(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = userProvider.getUserRole;

    // If offer is marked as done or sold, always go to TransporterOfferDetailsPage
    if (widget.offer.offerStatus.toLowerCase() == 'done' ||
        widget.offer.offerStatus.toLowerCase() == 'sold') {
      _getVehicle().then((vehicle) async {
        if (vehicle != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransporterOfferDetailsPage(
                offer: widget.offer,
                vehicle: vehicle,
              ),
            ),
          );
          if (widget.onPop != null) {
            widget.onPop!();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle details could not be loaded.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
      return;
    }

    // Handle Payment Approved status
    if (widget.offer.offerStatus.toLowerCase() == 'payment approved') {
      String newStatus = 'awaiting collection';
      FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offer.offerId)
          .update({'offerStatus': newStatus}).then((_) {
        setState(() {
          widget.offer.offerStatus = newStatus;
        });
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentApprovedPage(
            offerId: widget.offer.offerId,
          ),
        ),
      );
      return;
    }

    if (userRole == 'transporter' || userRole == 'oem') {
      switch (widget.offer.offerStatus) {
        case 'inspection pending':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmationPage(
                offerId: widget.offer.offerId,
                location:
                    widget.offer.dealerSelectedInspectionLocation ?? 'Unknown',
                address:
                    widget.offer.dealerSelectedInspectionLocation ?? 'Unknown',
                date: widget.offer.dealerSelectedInspectionDate!,
                time: widget.offer.dealerSelectedInspectionTime ?? 'Unknown',
                latLng: LatLng(
                  widget.offer.latLng?.latitude ?? 0,
                  widget.offer.latLng?.longitude ?? 0,
                ),
                brand: widget.offer.vehicleBrand ?? '',
                variant: widget.offer.variant ?? '',
                offerAmount: formatOfferAmount(widget.offer.offerAmount),
                vehicleId: widget.offer.vehicleId,
              ),
            ),
          );
          return;
        case 'Inspection Done':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FinalInspectionApprovalPage(
                offerId: widget.offer.offerId,
                oldOffer: formatOfferAmount(widget.offer.offerAmount),
                vehicleName: widget.offer.vehicleMakeModel ?? 'Unknown',
              ),
            ),
          );
          return;
        case 'payment pending':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentPendingPage(
                offerId: widget.offer.offerId,
              ),
            ),
          );
          return;
        case 'Collection Location Confirmation':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CollectionConfirmationPage(
                offerId: widget.offer.offerId,
                location:
                    widget.offer.dealerSelectedInspectionLocation ?? 'Unknown',
                address: widget.offer.transporterDeliveryAddress ?? 'Unknown',
                date: widget.offer.dealerSelectedInspectionDate!,
                time: widget.offer.dealerSelectedInspectionTime ?? 'Unknown',
                latLng: widget.offer.latLng != null
                    ? LatLng(widget.offer.latLng!.latitude,
                        widget.offer.latLng!.longitude)
                    : null,
              ),
            ),
          );
          return;
        default:
          _getVehicle().then((vehicle) async {
            if (vehicle != null) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TransporterOfferDetailsPage(
                    offer: widget.offer,
                    vehicle: vehicle,
                  ),
                ),
              );
              if (widget.onPop != null) {
                widget.onPop!();
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vehicle details could not be loaded.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
          return;
      }
    }

    // Dealer Navigation
    switch (widget.offer.offerStatus) {
      case 'set location and time':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InspectionDetailsPage(
              offerId: widget.offer.offerId,
              offerAmount: formatOfferAmount(widget.offer.offerAmount),
              vehicleId: widget.offer.vehicleId,
              brand: widget.offer.vehicleBrand ?? 'Unknown',
              variant: widget.offer.variant ?? 'Unknown',
            ),
          ),
        );
        break;
      case 'confirm location':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LocationConfirmationPage(
              offerId: widget.offer.offerId,
              location:
                  widget.offer.dealerSelectedInspectionLocation ?? 'Unknown',
              address:
                  widget.offer.dealerSelectedInspectionLocation ?? 'Unknown',
              date: widget.offer.dealerSelectedInspectionDate!,
              time: widget.offer.dealerSelectedInspectionTime ?? 'Unknown',
              brand: widget.offer.vehicleBrand ?? 'Unknown',
              offerAmount: formatOfferAmount(widget.offer.offerAmount),
              vehicleId: widget.offer.vehicleId,
              variant: widget.offer.variant ?? "",
            ),
          ),
        );
        break;
      case 'Confirm Collection':
      case 'Collection Location Confirmation':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CollectionConfirmationPage(
              offerId: widget.offer.offerId,
              location:
                  widget.offer.dealerSelectedInspectionLocation ?? 'Unknown',
              address: widget.offer.transporterDeliveryAddress ?? 'Unknown',
              date: widget.offer.dealerSelectedInspectionDate!,
              time: widget.offer.dealerSelectedInspectionTime ?? 'Unknown',
              latLng: widget.offer.latLng != null
                  ? LatLng(widget.offer.latLng!.latitude,
                      widget.offer.latLng!.longitude)
                  : null,
            ),
          ),
        );
        break;
      case 'payment options':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentOptionsPage(
              offerId: widget.offer.offerId,
            ),
          ),
        );
        break;
      case 'accepted':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InspectionDetailsPage(
              offerId: widget.offer.offerId,
              offerAmount: formatOfferAmount(widget.offer.offerAmount),
              vehicleId: widget.offer.vehicleId,
              brand: widget.offer.vehicleBrand ?? 'Unknown',
              variant: widget.offer.variant ?? 'Unknown',
            ),
          ),
        );
        break;
      case 'inspection pending':
      case 'Inspection Done':
      case 'payment pending':
        _navigateToRespectivePage(userRole);
        break;
      case 'paid':
        if (userRole == 'dealer') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CollectionDetailsPage(
                offerId: widget.offer.offerId,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentApprovedPage(
                offerId: widget.offer.offerId,
              ),
            ),
          );
        }
        break;
      case 'collection details':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CollectionDetailsPage(
              offerId: widget.offer.offerId,
            ),
          ),
        );
        break;
      default:
        // Default for dealers: show Transporter Offer Details page
        _getVehicle().then((vehicle) async {
          if (vehicle != null) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransporterOfferDetailsPage(
                  offer: widget.offer,
                  vehicle: vehicle,
                ),
              ),
            );
            if (widget.onPop != null) {
              widget.onPop!();
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vehicle details could not be loaded.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
        break;
    }
  }

  /// Fallback to loading the vehicle if not found in the provider.
  Future<Vehicle?> _getVehicle() async {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    Vehicle? vehicle;

    try {
      vehicle = vehicleProvider.vehicles.firstWhere(
        (v) => v.id == widget.offer.vehicleId,
        orElse: () => throw Exception('Vehicle not found'),
      );
    } catch (e) {
      try {
        DocumentSnapshot vehicleSnapshot = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.offer.vehicleId)
            .get();

        if (vehicleSnapshot.exists) {
          vehicle = Vehicle.fromDocument(vehicleSnapshot);
          vehicleProvider.addVehicle(vehicle);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle details not found.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching vehicle details: $err'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    return vehicle;
  }

  void _navigateToRespectivePage(String userRole) {
    switch (widget.offer.offerStatus) {
      case 'inspection pending':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmationPage(
              offerId: widget.offer.offerId,
              location:
                  widget.offer.dealerSelectedInspectionLocation ?? 'Unknown',
              address:
                  widget.offer.dealerSelectedInspectionLocation ?? 'Unknown',
              date: widget.offer.dealerSelectedInspectionDate!,
              time: widget.offer.dealerSelectedInspectionTime ?? 'Unknown',
              latLng: LatLng(
                widget.offer.latLng?.latitude ?? 0,
                widget.offer.latLng?.longitude ?? 0,
              ),
              offerAmount: formatOfferAmount(widget.offer.offerAmount),
              vehicleId: widget.offer.vehicleId,
              brand: widget.offer.vehicleBrand ?? '',
              variant: widget.offer.variant ?? '',
            ),
          ),
        );
        break;
      case 'Inspection Done':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FinalInspectionApprovalPage(
              offerId: widget.offer.offerId,
              oldOffer: formatOfferAmount(widget.offer.offerAmount),
              vehicleName:
                  (widget.offer.vehicleMakeModel ?? 'Unknown').toUpperCase(),
            ),
          ),
        );
        break;
      case 'payment pending':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentPendingPage(
              offerId: widget.offer.offerId,
            ),
          ),
        );
        break;
      default:
        debugPrint(
            "Dealer - unhandled status in _navigateToRespectivePage: ${widget.offer.offerStatus}");
        break;
    }
  }

  /// Helper that builds a spec box if the value is valid.
  Widget _buildSpecBox(String value) {
    if (value.trim().isEmpty || value.toUpperCase() == 'N/A') {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Main Offer Card layout with debugging prints and borders.
  Widget _buildWebCard(Color statusColor, BoxConstraints constraints) {
    // debugPrint('Offer status in web card: ${widget.offer.offerStatus}');

    const bool isWeb = kIsWeb;
    final double cardWidth = isWeb ? 400 : constraints.maxWidth;
    // Increase cardHeight to allow for a larger gap without overflow.
    final double cardHeight = isWeb ? 600 : cardWidth * 1.4;
    // debugPrint('Card dimensions - Width: $cardWidth, Height: $cardHeight');

    return Center(
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: EdgeInsets.all(isWeb ? 8 : 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2F7FFF).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2F7FFF), width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, cardConstraints) {
            double cardW = cardConstraints.maxWidth;
            double cardH = cardConstraints.maxHeight;
            // debugPrint(
            //     'Inner card constraints - Width: $cardW, Height: $cardH');

            double titleFontSize = isWeb ? cardW * 0.045 : cardW * 0.04;
            double subtitleFontSize = isWeb ? cardW * 0.04 : cardW * 0.035;
            double paddingVal = isWeb ? cardW * 0.04 : cardW * 0.03;
            double specFontSize = isWeb ? cardW * 0.03 : cardW * 0.025;
            // debugPrint(
            //     'Calculated font sizes & padding - title: $titleFontSize, subtitle: $subtitleFontSize, padding: $paddingVal, specFontSize: $specFontSize');

            // Determine title text for bulk/single
            final String titleText;
            if (_bulkVehicles != null) {
              titleText = '${_bulkVehicles!.length} Vehicles';
            } else {
              final singleBrand = [
                widget.offer.vehicleBrand,
                widget.offer.variant,
              ]
                  .where((element) => element != null && element.isNotEmpty)
                  .join(' ');
              titleText = singleBrand.isEmpty
                  ? 'LOADING...'
                  : singleBrand.toUpperCase();
            }

            return Column(
              children: [
                // Image section with a debug border.
                SizedBox(
                  height: cardH * 0.55,
                  child: Stack(
                    children: [
                      // Bulk/single image logic
                      if (_bulkVehicles != null) ...[
                        (() {
                          final count = _bulkVehicles!.length;
                          // One image
                          if (count == 1) {
                            return ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(10)),
                              child: Image.network(
                                _bulkVehicles![0].mainImageUrl ?? '',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            );
                          }
                          // Two images
                          if (count == 2) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _bulkVehicles!
                                  .map((v) => Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(10)),
                                          child: Image.network(
                                              v.mainImageUrl ?? '',
                                              fit: BoxFit.cover),
                                        ),
                                      ))
                                  .toList(),
                            );
                          }
                          // Three images
                          if (count == 3) {
                            return Column(
                              children: [
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: _bulkVehicles!
                                        .sublist(0, 2)
                                        .map((v) => Expanded(
                                              child: ClipRRect(
                                                borderRadius: const BorderRadius
                                                    .vertical(
                                                    top: Radius.circular(10)),
                                                child: Image.network(
                                                    v.mainImageUrl ?? '',
                                                    fit: BoxFit.cover),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                                // remove spacing for seamless fill
                                Expanded(
                                  child: ClipRRect(
                                    child: Image.network(
                                        _bulkVehicles![2].mainImageUrl ?? '',
                                        fit: BoxFit.cover),
                                  ),
                                ),
                              ],
                            );
                          }
                          // Four or more
                          final extra = count > 4 ? count - 4 : 0;
                          final list = _bulkVehicles!.take(4).toList();
                          return GridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 0,
                            crossAxisSpacing: 0,
                            childAspectRatio: cardW / (cardH * 0.55),
                            physics: const NeverScrollableScrollPhysics(),
                            children: List.generate(4, (i) {
                              final v = list[i];
                              Widget img = ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(10)),
                                child: Image.network(v.mainImageUrl ?? '',
                                    fit: BoxFit.cover),
                              );
                              if (i == 3 && extra > 0) {
                                // blur + overlay
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 8, sigmaY: 8),
                                      child: img,
                                    ),
                                    Center(
                                      child: Text('+$extra',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                );
                              }
                              return img;
                            }),
                          );
                        })()
                      ] else ...[
                        // Single offer fallback
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10)),
                          child: Image.network(
                            widget.offer.vehicleMainImage ?? '',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                              'lib/assets/default_vehicle_image.png',
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                      Positioned(
                        top: paddingVal * 0.75,
                        right: paddingVal * 0.75,
                        child: _buildStatusBadge(widget.offer.offerStatus),
                      ),
                    ],
                  ),
                ),
                // Details section with debug border to show its boundaries.
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(paddingVal),
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vehicle details sub-section.
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  titleText,
                                  style: GoogleFonts.montserrat(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // Reference Number (from vehicle)
                                if (_bulkVehicles != null &&
                                    _bulkVehicles!.isNotEmpty) ...[
                                  Padding(
                                    padding: EdgeInsets.only(
                                        top: paddingVal * 0.15,
                                        bottom: paddingVal * 0.15),
                                    child: Row(
                                      children: [
                                        ...(() {
                                          final refs = _bulkVehicles!
                                              .map((v) => v.referenceNumber)
                                              .where((r) => r.isNotEmpty)
                                              .toList();
                                          final displayCount =
                                              refs.length > 4 ? 4 : refs.length;
                                          List<Widget> list = [];
                                          for (int i = 0;
                                              i < displayCount;
                                              i++) {
                                            list.add(Text(
                                              'Ref: ${refs[i]}',
                                              style: GoogleFonts.montserrat(
                                                fontSize: subtitleFontSize,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFFFF4E00),
                                              ),
                                            ));
                                            if (i < displayCount - 1) {
                                              list.add(
                                                  const SizedBox(width: 8));
                                            }
                                          }
                                          if (refs.length > 4) {
                                            list = list.sublist(0, 3);
                                            list.add(Text(
                                              'and more...',
                                              style: GoogleFonts.montserrat(
                                                fontSize: subtitleFontSize,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFFFF4E00),
                                              ),
                                            ));
                                          }
                                          return list;
                                        })(),
                                      ],
                                    ),
                                  ),
                                ] else if (vehicleYear != null) ...[
                                  Padding(
                                    padding: EdgeInsets.only(
                                        top: paddingVal * 0.15,
                                        bottom: paddingVal * 0.15),
                                    child: Text(
                                      'Ref: ${_bulkVehicles == null ? _getSingleVehicleReference() : ''}',
                                      style: GoogleFonts.montserrat(
                                        fontSize: subtitleFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFFF4E00),
                                      ),
                                    ),
                                  ),
                                ],
                                // Bulk preview: up to 4 vehicle names, else year for single
                                SizedBox(height: paddingVal * 0.25),
                                if (_bulkVehicles != null &&
                                    _bulkVehicles!.isNotEmpty) ...[
                                  // Show up to 4 names; if more than 4, show first 3 + "and more..."
                                  ...(() {
                                    final names = _bulkVehicles!
                                        .map((v) =>
                                            '${v.year} ${v.brands.join(', ')} ${v.makeModel} ${v.variant}')
                                        .toList();
                                    final displayCount =
                                        names.length > 4 ? 4 : names.length;
                                    List<Widget> list = [];
                                    for (int i = 0; i < displayCount; i++) {
                                      list.add(Text(
                                        names[i],
                                        style: GoogleFonts.montserrat(
                                          fontSize: subtitleFontSize,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white70,
                                        ),
                                      ));
                                    }
                                    if (names.length > 4) {
                                      // show only first 3 then "and more..."
                                      list = list.sublist(0, 3);
                                      list.add(Text(
                                        'and more...',
                                        style: GoogleFonts.montserrat(
                                          fontSize: subtitleFontSize,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white70,
                                        ),
                                      ));
                                    }
                                    return list;
                                  })(),
                                ] else ...[
                                  Text(
                                    vehicleYear ?? 'N/A',
                                    style: GoogleFonts.montserrat(
                                      fontSize: subtitleFontSize,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                                SizedBox(height: paddingVal * 0.5),
                                Text(
                                  'Offer of ${formatOfferAmount(widget.offer.offerAmount)}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                // Display lifespan if available
                                if (widget.offer.lifespanDays != null)
                                  Text(
                                    'Lifespan: ${widget.offer.lifespanDays} day${widget.offer.lifespanDays! > 1 ? 's' : ''}',
                                    style: GoogleFonts.montserrat(
                                      fontSize: subtitleFontSize,
                                      color: Colors.white70,
                                    ),
                                  )
                                else
                                  Text(
                                    'No Lifespan',
                                    style: GoogleFonts.montserrat(
                                      fontSize: subtitleFontSize,
                                      color: Colors.white70,
                                    ),
                                  ),
                                // Display expiration date if available
                                if (widget.offer.expirationDate != null)
                                  Text(
                                    'Expires: ${DateFormat('dd MMM yyyy').format(widget.offer.expirationDate!)}',
                                    style: GoogleFonts.montserrat(
                                      fontSize: subtitleFontSize,
                                      color: Colors.white70,
                                    ),
                                  )
                                else
                                  const SizedBox.shrink(),
                                if (_buildSpecBoxes(cardW).isNotEmpty) ...[
                                  SizedBox(height: paddingVal * 0.5),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: _buildSpecBoxes(cardW),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Fixed gap of 50 units (debug adjustable)
                          // const SizedBox(height: 25),
                          // View Details Button with a debug border.
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => navigateBasedOnStatus(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2F7FFF),
                                padding: EdgeInsets.symmetric(
                                    vertical: paddingVal * 0.75),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(paddingVal * 0.5),
                                ),
                              ),
                              child: Text(
                                'VIEW MORE DETAILS',
                                style: GoogleFonts.montserrat(
                                  fontSize: specFontSize + 2,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Helper method to build spec boxes.
  List<Widget> _buildSpecBoxes(double cardWidth) {
    List<Widget> specBoxes = [];
    double spacing = cardWidth * 0.015;

    if (mileage != null &&
        mileage!.trim().isNotEmpty &&
        mileage!.toUpperCase() != 'N/A') {
      specBoxes.add(Expanded(child: _buildSpecBox('${mileage!} km')));
    }
    if (transmissionType != null &&
        transmissionType!.trim().isNotEmpty &&
        transmissionType!.toUpperCase() != 'N/A') {
      if (specBoxes.isNotEmpty) specBoxes.add(SizedBox(width: spacing));
      specBoxes.add(Expanded(child: _buildSpecBox(transmissionType!)));
    }
    if (vehicleConfig != null &&
        vehicleConfig!.trim().isNotEmpty &&
        vehicleConfig!.toUpperCase() != 'N/A') {
      if (specBoxes.isNotEmpty) specBoxes.add(SizedBox(width: spacing));
      specBoxes.add(Expanded(child: _buildSpecBox(vehicleConfig!)));
    }

    return specBoxes;
  }

  Widget _buildStatusBadge(String status) {
    final normalizedStatus = status.toLowerCase().trim();
    // debugPrint(
    //     'Building status badge for normalized status: $normalizedStatus');

    final String displayText =
        status.isEmpty ? 'UNKNOWN' : status.toUpperCase();
    final icon = getStatusIcon(normalizedStatus);
    final bgColor = getStatusColor(normalizedStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            displayText,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(widget.offer.offerStatus);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: InkWell(
            onTap: () {
              if (widget.offer.vehicleIds != null &&
                  widget.offer.vehicleIds!.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BulkOfferDetailsPage(
                      offer: widget.offer,
                      vehicles: _bulkVehicles ?? [],
                    ),
                  ),
                );
              } else {
                navigateBasedOnStatus(context);
              }
            },
            child: _buildWebCard(statusColor, constraints),
          ),
        );
      },
    );
  }

  void navigateToVehicleDetails() async {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    Vehicle? vehicle;

    try {
      vehicle = vehicleProvider.vehicles.firstWhere(
        (v) => v.id == widget.offer.vehicleId,
        orElse: () => throw Exception('Vehicle not found'),
      );
    } catch (e) {
      try {
        DocumentSnapshot vehicleSnapshot = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.offer.vehicleId)
            .get();

        if (vehicleSnapshot.exists) {
          vehicle = Vehicle.fromDocument(vehicleSnapshot);
          vehicleProvider.addVehicle(vehicle);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle details not found.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading vehicle details: $err'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    if (mounted && vehicle != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VehicleDetailsPage(vehicle: vehicle!),
        ),
      );
    }
  }

  /// Helper to get reference number for single vehicle
  String _getSingleVehicleReference() {
    // If vehicle details have been fetched
    if (_bulkVehicles == null) {
      // Try to get from the fetched vehicle data
      // This info is fetched in _fetchVehicleDetails and stored in _bulkVehicles for bulk, but for single, we need to fetch from Firestore
      // Since we already fetch vehicleYear, we can also fetch referenceNumber
      // But for simplicity, let's just use the vehicleYear as a proxy for fetched data
      // If you want to cache the referenceNumber, you can add a state variable for it
      // For now, just return 'N/A' if not available
      // You can extend _fetchVehicleDetails to cache referenceNumber if needed
      return widget.offer.vehicleRef ?? 'N/A';
    }
    return 'N/A';
  }
}
