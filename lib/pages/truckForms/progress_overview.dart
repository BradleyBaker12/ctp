import 'package:ctp/pages/truckForms/admin_form.dart';
import 'package:ctp/pages/truckForms/basic_information.dart';
import 'package:ctp/pages/truckForms/maintenance_form.dart';
import 'package:ctp/pages/truckForms/truck_condition_form.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ctp/utils/navigation.dart';

class ProgressOverviewPage extends StatefulWidget {
  final Map<String, dynamic> formData;
  final String listingId;

  const ProgressOverviewPage({
    super.key,
    required this.formData,
    required this.listingId,
  });

  @override
  State<ProgressOverviewPage> createState() => _ProgressOverviewPageState();
}

class _ProgressOverviewPageState extends State<ProgressOverviewPage> {
  void _navigateToSection(BuildContext context, String section) async {
    switch (section) {
      case 'BASIC':
        await MyNavigator.push(
          context,
          BasicInformationForm(formData: widget.formData),
        );
        break;
      case 'CONDITION':
        await MyNavigator.push(
          context,
          TruckConditionForm(formData: widget.formData),
        );
        break;
      case 'MAINTENANCE':
        await MyNavigator.push(
          context,
          MaintenanceForm(formData: widget.formData),
        );
        break;
      case 'ADMIN':
        await MyNavigator.push(context, AdminForm(formData: widget.formData));
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
                  // Back button
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero, // Sharp corners
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
                    flex: 4, // Increased to push content more to the right
                    child: Container(),
                  ),
                  Expanded(
                    flex: 2, // Reduced flex to bring texts closer
                    child: Text(
                      '${widget.formData['referenceNumber'] ?? 'N/A'}',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2, // Reduced flex to bring texts closer
                    child: Text(
                      '${widget.formData['makeModel'] ?? 'N/A'}',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8), // Small gap before avatar
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: widget.formData['coverPhotoUrl'] != null
                        ? CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(
                              widget.formData['coverPhotoUrl'],
                            ),
                          )
                        : const CircleAvatar(
                            radius: 20,
                            child: Text(
                              'NO',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                  ),
                ],
              ),
            ),

            // Message
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              color: Colors.transparent,
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              color: Colors.blue[700],
              width: double.infinity,
              child: Text(
                'COMPLETE ALL STEPS AS\nPOSSIBLE TO RECIEVE\nBETTER OFFERS',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Updated progress sections
            InkWell(
              onTap: () => _navigateToSection(context, 'BASIC'),
              child: _buildProgressSection(
                'BASIC\nINFORMATION',
                'PROGRESS: 10 OF 20 STEPS\nCOMPLETED',
              ),
            ),
            InkWell(
              onTap: () => _navigateToSection(context, 'CONDITION'),
              child: _buildProgressSection(
                'TRUCK CONDITION',
                'PROGRESS: 10 OF 20 STEPS\nCOMPLETED',
              ),
            ),
            InkWell(
              onTap: () => _navigateToSection(context, 'MAINTENANCE'),
              child: _buildProgressSection(
                'MAINTENCE\nAND WARRENTY',
                'PROGRESS: 10 OF 20 STEPS\nCOMPLETED',
              ),
            ),
            InkWell(
              onTap: () => _navigateToSection(context, 'ADMIN'),
              child: _buildProgressSection(
                'ADMIN',
                'PROGRESS: 10 OF 20 STEPS\n5/10 MANDATORY FILLED IN\nCOMPLETED',
                isAdmin: true,
              ),
            ),

            const Spacer(),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        elevation: 0, // Removes shadow
                        padding: const EdgeInsets.symmetric(
                            vertical: 12), // Adjust padding
                      ),
                      child: Text(
                        'Save and exit',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        elevation: 0, // Removes shadow
                        padding: const EdgeInsets.symmetric(
                            vertical: 12), // Adjust padding
                      ),
                      child: Text(
                        'Save and continue',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _buildProgressSection(String title, String progress,
      {bool isAdmin = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.blue,
      margin: const EdgeInsets.only(top: 1),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            progress,
            style: GoogleFonts.montserrat(
              color: isAdmin ? Colors.red : Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
