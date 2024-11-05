import 'package:ctp/models/vehicle.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:flutter/material.dart';

class HonestyBarWidget extends StatelessWidget {
  final Vehicle vehicle;
  final double heightFactor;

  const HonestyBarWidget({
    super.key,
    required this.vehicle,
    this.heightFactor = 0.38, // Default height factor
  });

  double _calculateHonestyPercentage() {
    int totalFields = 35 + 18; // Total fields and photos
    int filledFields = 0;

    try {
      final fieldsToCheck = [
        vehicle.application,
        vehicle.damageDescription,
        vehicle.engineNumber,
        vehicle.expectedSellingPrice,
        vehicle.hydraluicType,
        // vehicle.maintenance,
        vehicle.makeModel,
        vehicle.mileage,
        vehicle.registrationNumber,
        vehicle.suspensionType,
        vehicle.transmissionType,

        vehicle.userId,
        vehicle.vinNumber,
        vehicle.warrentyType,

        vehicle.year,
        vehicle.vehicleType,
      ];

      for (var field in fieldsToCheck) {
        if (field.isNotEmpty) {
          filledFields++;
        }
      }

      final nullableFieldsToCheck = [
        vehicle.dashboardPhoto,
        vehicle.faultCodesPhoto,
        vehicle.licenceDiskUrl,
        vehicle.mileageImage,
        vehicle.rc1NatisFile,
      ];

      for (var field in nullableFieldsToCheck) {
        filledFields++;
            }

      for (var photo in vehicle.photos) {
        if (photo != null && photo.isNotEmpty) {
          filledFields++;
        }
      }

      double honestyPercentage = (filledFields / totalFields) * 100;

      return honestyPercentage;
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double honestyPercentage = _calculateHonestyPercentage();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: size.height * 0.018,
          height: size.height * heightFactor,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(0),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: ((size.height * heightFactor) * honestyPercentage) /
                        100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F7FFF),
                      borderRadius: BorderRadius.circular(0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "${honestyPercentage.toStringAsFixed(0)}/100",
          style: TextStyle(
            fontSize: size.height * 0.015,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
