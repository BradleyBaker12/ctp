import 'package:ctp/pages/truckForms/chassis_form.dart';
import 'package:ctp/pages/truckForms/drive_train_form.dart';
import 'package:ctp/pages/truckForms/external_cab_form.dart';
import 'package:ctp/pages/truckForms/internal_cab_form.dart';
import 'package:ctp/pages/truckForms/tyres_form.dart';
import 'package:ctp/utils/navigation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ctp/components/gradient_background.dart';

class TruckConditionForm extends StatelessWidget {
  final Map<String, dynamic> formData;

  const TruckConditionForm({super.key, required this.formData});

  void _navigateToSection(BuildContext context, String section) async {
    switch (section) {
      case 'EXTERNAL':
        await MyNavigator.push(context, ExternalCabForm(formData: formData));
        break;
      case 'INTERNAL':
        await MyNavigator.push(context, InternalCabForm(formData: formData));
        break;
      case 'DRIVE_TRAIN':
        await MyNavigator.push(context, DriveTrainForm(formData: formData));
        break;
      case 'CHASSIS':
        await MyNavigator.push(context, ChassisForm(formData: formData));
        break;
      case 'TYRES':
        await MyNavigator.push(context, TyresForm(formData: formData));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            // Header with vehicle info
            Container(
              color: const Color(0xFF2F7FFF),
              padding: const EdgeInsets.only(top: 50, bottom: 16),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      child: Text(
                        'BACK',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      formData['referenceNumber']?.toString() ?? 'N/A',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      formData['makeModel']?.toString() ?? 'N/A',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: formData['coverPhotoUrl']?.isNotEmpty == true
                        ? CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(
                              formData['coverPhotoUrl']!,
                            ),
                            onBackgroundImageError: (_, __) {
                              // Handle error silently
                            },
                            child: formData['coverPhotoUrl']!.isEmpty
                                ? const Text('N/A')
                                : null,
                          )
                        : const CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey,
                            child: Text(
                              'N/A',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Container(
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        // Navigate to maintenance tab
                        Navigator.pushNamed(
                            context, '/maintenance'); // Update with your route
                      },
                      child: Container(
                        color: const Color(0xFF4CAF50),
                        alignment: Alignment.center,
                        child: Text(
                          'MAINTENANCE\nCOMPLETE',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        // Navigate to admin tab
                        Navigator.pushNamed(
                            context, '/admin'); // Update with your route
                      },
                      child: Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: Text(
                          'ADMIN',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        // Navigate to truck condition tab
                        Navigator.pushNamed(context,
                            '/truck-condition'); // Update with your route
                      },
                      child: Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: Text(
                          'TRUCK CONDITION',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'TRUCK CONDITION',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Progress sections
            _buildProgressSection(
              context,
              'EXTERNAL CAB',
              'PROGRESS: 10 OF 20 STEPS COMPLETED',
              'EXTERNAL',
            ),
            _buildProgressSection(
              context,
              'INTERNAL CAB',
              'PROGRESS: 10 OF 20 STEPS COMPLETED',
              'INTERNAL',
            ),
            _buildProgressSection(
              context,
              'DRIVE TRAIN',
              'PROGRESS: 10 OF 20 STEPS COMPLETED',
              'DRIVE_TRAIN',
            ),
            _buildProgressSection(
              context,
              'CHASSIS',
              'PROGRESS: 10 OF 20 STEPS COMPLETED',
              'CHASSIS',
            ),
            _buildProgressSection(
              context,
              'TYRES',
              'PROGRESS: 10 OF 20 STEPS COMPLETED',
              'TYRES',
            ),

            const Spacer(),

            // Cancel button at bottom
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'CANCEL',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String text, bool isActive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: isActive ? const Color(0xFF2F7FFF) : Colors.black,
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildProgressSection(
    BuildContext context,
    String title,
    String progress,
    String section,
  ) {
    return InkWell(
      onTap: () => _navigateToSection(context, section),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        color: const Color(0xFF2F7FFF),
        margin: const EdgeInsets.only(bottom: 1),
        child: Column(
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              progress,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
