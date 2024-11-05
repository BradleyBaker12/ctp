import 'package:ctp/components/custom_radio_button.dart';
import 'package:ctp/components/custom_text_field.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InternalCabForm extends StatefulWidget {
  final Map<String, dynamic> formData;
  const InternalCabForm({super.key, required this.formData});

  @override
  State<InternalCabForm> createState() => _InternalCabFormState();
}

class _InternalCabFormState extends State<InternalCabForm> {
  String? cabCondition;
  bool? hasDamages;
  bool? hasAdditionalFeatures;
  bool? hasFaultCodes;
  final TextEditingController _damageController = TextEditingController();
  final TextEditingController _featureController = TextEditingController();
  final TextEditingController _faultCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            // Top navigation buttons
            Container(
              color: const Color(0xFF2F7FFF),
              padding: const EdgeInsets.only(top: 50, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                      widget.formData['referenceNumber']?.toString() ?? 'N/A',
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
                      widget.formData['makeModel']?.toString() ?? 'N/A',
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
                    child: widget.formData['coverPhotoUrl']?.isNotEmpty == true
                        ? CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(
                              widget.formData['coverPhotoUrl']!,
                            ),
                            onBackgroundImageError: (_, __) {
                              // Handle error silently
                            },
                            child: widget.formData['coverPhotoUrl']!.isEmpty
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
                mainAxisAlignment: MainAxisAlignment.center,
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
            Container(
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/external-cab');
                      },
                      child: Container(
                        color: const Color(0xFF4CAF50),
                        alignment: Alignment.center,
                        child: Text(
                          'External Cab',
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
                        Navigator.pushNamed(context, '/internal-cab');
                      },
                      child: Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: Text(
                          'Internal Cab',
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
                        Navigator.pushNamed(context, '/drive-train');
                      },
                      child: Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: Text(
                          'Drive Train',
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
                        Navigator.pushNamed(context, '/chassis');
                      },
                      child: Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: Text(
                          'Chassis',
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
                        Navigator.pushNamed(context, '/tyres');
                      },
                      child: Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: Text(
                          'Tyres',
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
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title and Condition
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'INTERNAL CAB',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'CONDITION OF THE INTERNAL CAB',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomRadioButton(
                                  label: 'POOR',
                                  value: 'POOR',
                                  groupValue: cabCondition ?? '',
                                  onChanged: (value) => setState(
                                      () => cabCondition = value ?? 'POOR'),
                                ),
                                const SizedBox(width: 32),
                                CustomRadioButton(
                                  label: 'GOOD',
                                  value: 'GOOD',
                                  groupValue: cabCondition ?? '',
                                  onChanged: (value) => setState(
                                      () => cabCondition = value ?? 'GOOD'),
                                ),
                                const SizedBox(width: 32),
                                CustomRadioButton(
                                  label: 'EXCELLENT',
                                  value: 'EXCELLENT',
                                  groupValue: cabCondition ?? '',
                                  onChanged: (value) => setState(() =>
                                      cabCondition = value ?? 'EXCELLENT'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Front Side of Cab
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'FRONT SIDE OF CAB',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      padding: const EdgeInsets.all(16),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildImageUploadBox('STEERING WHEEL'),
                        _buildImageUploadBox('LEFT PANEL'),
                        _buildImageUploadBox('METER CLUSTER\nSERVICE COMPUTER'),
                        _buildImageUploadBox('FULL VIEW'),
                        _buildImageUploadBox('AIR VENTS'),
                        _buildImageUploadBox('STORAGE CONSOLE'),
                        _buildImageUploadBox('PEDALS'),
                        _buildImageUploadBox('CENTER CONSOLE'),
                      ],
                    ),

                    // Left Side of Cab
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'LEFT SIDE OF CAB',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      padding: const EdgeInsets.all(16),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildImageUploadBox('DOOR PANEL'),
                        _buildImageUploadBox('SEAT'),
                      ],
                    ),

                    // Rear Side of Cab
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'REAR SIDE OF CAB',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      padding: const EdgeInsets.all(16),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildImageUploadBox('BUNK'),
                        _buildImageUploadBox('BUNK BEDS'),
                        _buildImageUploadBox('BUNK PANEL'),
                      ],
                    ),

                    // Right Side of Cab
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'RIGHT SIDE OF CAB',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      padding: const EdgeInsets.all(16),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildImageUploadBox('DOOR PANEL'),
                        _buildImageUploadBox('SEAT'),
                      ],
                    ),

                    // Additional Info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'ADDITIONAL INFO',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    _buildYesNoSection(
                      'ARE THERE ANY DAMAGES ON THE CAB',
                      hasDamages,
                      (value) => setState(() => hasDamages = value),
                      _damageController,
                      'DESCRIBE DAMAGE',
                      'CLEAR PICTURE OF DAMAGE',
                      'ADD ADDITIONAL\nDAMAGE',
                    ),

                    _buildYesNoSection(
                      'ARE THERE ANY ADDITIONAL FEATURES ON THE CAB',
                      hasAdditionalFeatures,
                      (value) => setState(() => hasAdditionalFeatures = value),
                      _featureController,
                      'DESCRIBE FEATURES',
                      'CLEAR PICTURE OF FEATURES',
                      'ADD ADDITIONAL\nFEATURE',
                    ),

                    _buildYesNoSection(
                      'ARE THERE ANY FAULT CODES',
                      hasFaultCodes,
                      (value) => setState(() => hasFaultCodes = value),
                      _faultCodeController,
                      'DESCRIBE FAULT CODES',
                      'CLEAR PICTURE OF FAULT CODES',
                      'ADD ADDITIONAL\nFAULT CODE',
                    ),

                    // Cancel and Continue buttons
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'CANCEL',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // Handle continue
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFFFF4E00).withOpacity(0.25),
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Color(0xFFFF4E00),
                                  width: 2.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'CONTINUE',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(String text, bool isActive) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? Colors.green : Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(text),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildImageUploadBox(String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildYesNoSection(
    String title,
    bool? value,
    Function(bool?) onChanged,
    TextEditingController controller,
    String textFieldLabel,
    String uploadLabel,
    String addButtonLabel,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomRadioButton(
                label: 'YES',
                value: true.toString(),
                groupValue: value?.toString() ?? '',
                onChanged: (val) => onChanged(val == 'true'),
              ),
              const SizedBox(width: 32),
              CustomRadioButton(
                label: 'NO',
                value: false.toString(),
                groupValue: value?.toString() ?? '',
                onChanged: (val) => onChanged(val == 'true'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (value == true) ...[
            CustomTextField(
              controller: controller,
              hintText: textFieldLabel,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                // Your upload logic here
              },
              borderRadius: BorderRadius.circular(10.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E4CAF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: const Color(0xFF0E4CAF),
                    width: 2.0,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.drive_folder_upload_outlined,
                      color: Colors.white,
                      size: 50.0,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      uploadLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                // Handle add additional
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                addButtonLabel,
                style: GoogleFonts.montserrat(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _damageController.dispose();
    _featureController.dispose();
    _faultCodeController.dispose();
    super.dispose();
  }
}
