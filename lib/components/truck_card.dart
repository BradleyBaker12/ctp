// lib/components/truck_card.dart

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../providers/user_provider.dart';
import '../pages/vehicle_details_page.dart';

class TruckCard extends StatelessWidget {
  final Vehicle vehicle;

  /// Callback when the heart (like) button is pressed.
  final Function(Vehicle) onInterested;

  const TruckCard({
    super.key,
    required this.vehicle,
    required this.onInterested,
  });

  /// Builds one of the small spec boxes (e.g., mileage, transmission, config).
  /// The fontSize parameter allows the spec box text to scale with the card.
  Widget _buildSpecBox(String value, double fontSize) {
    // If no data to display, return an empty widget.
    if (value.trim().isEmpty || value.toUpperCase() == 'N/A') {
      return const SizedBox.shrink();
    }
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: fontSize * 0.5, vertical: fontSize * 0.5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(fontSize * 0.4),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set fixed dimensions for the card.
    const double fixedWidth = 400;
    const double fixedHeight = 500;

    // Use a LayoutBuilder to calculate dimensions relative to the fixed card size.
    return Center(
      child: Container(
        width: fixedWidth,
        height: fixedHeight,
        margin: const EdgeInsets.all(8), // Uniform margin.
        decoration: BoxDecoration(
          color: const Color(0xFF2F7FFF).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2F7FFF),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Use the fixed dimensions from the constraints.
            double cardW = constraints.maxWidth; // 400
            double cardH = constraints.maxHeight; // 500

            // Calculate relative sizes.
            double titleFontSize = cardW * 0.045; // ~18 for a 400px wide card.
            double subtitleFontSize = cardW * 0.04; // ~16.
            double paddingVal = cardW * 0.04; // ~16.
            double specFontSize = cardW * 0.03; // ~12.

            // Prepare text strings.
            final String brandModel = [
              vehicle.brands.join(" "),
              vehicle.makeModel,
            ].where((element) => element.isNotEmpty).join(" ");
            final String year = vehicle.year.toString();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image section.
                SizedBox(
                  height: cardH * 0.55, // 55% of the card's height.
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10)),
                        child: Image.network(
                          vehicle.mainImageUrl ?? '',
                          width: cardW,
                          height: cardH * 0.55,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                            'lib/assets/default_vehicle_image.png',
                            width: cardW,
                            height: cardH * 0.55,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Heart button positioned in the top right.
                      Positioned(
                        top: paddingVal * 0.75,
                        right: paddingVal * 0.75,
                        child: Consumer<UserProvider>(
                          builder: (context, userProvider, child) {
                            bool isLiked = userProvider.getLikedVehicles
                                .contains(vehicle.id);
                            return IconButton(
                              icon: Icon(
                                isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isLiked ? Colors.red : Colors.white,
                                size: titleFontSize + 10,
                              ),
                              onPressed: () => onInterested(vehicle),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Details section.
                Padding(
                  padding: EdgeInsets.all(paddingVal),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand/model and year.
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              brandModel.isEmpty
                                  ? 'LOADING...'
                                  : brandModel.toUpperCase(),
                              style: GoogleFonts.montserrat(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          SizedBox(height: paddingVal * 0.25),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              year,
                              style: GoogleFonts.montserrat(
                                fontSize: subtitleFontSize,
                                fontWeight: FontWeight.w400,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: paddingVal),
                      // Row of spec boxes.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                              child: _buildSpecBox(
                                  '${vehicle.mileage ?? "N/A"} km',
                                  specFontSize)),
                          SizedBox(width: paddingVal * 0.3),
                          Expanded(
                              child: _buildSpecBox(
                                  vehicle.transmissionType ?? 'N/A',
                                  specFontSize)),
                          SizedBox(width: paddingVal * 0.3),
                          Expanded(
                              child: _buildSpecBox(
                                  vehicle.config ?? 'N/A', specFontSize)),
                        ],
                      ),
                    ],
                  ),
                ),
                // Spacer to push button to the bottom.
                // const Spacer(),
                Padding(
                  padding: EdgeInsets.only(
                      bottom: paddingVal, left: paddingVal, right: paddingVal),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              VehicleDetailsPage(vehicle: vehicle),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F7FFF),
                      padding:
                          EdgeInsets.symmetric(vertical: paddingVal * 0.75),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(paddingVal * 0.5),
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
            );
          },
        ),
      ),
    );
  }
}
