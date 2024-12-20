import 'package:ctp/components/custom_radio_button.dart';
import 'package:ctp/components/custom_text_field.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DriveTrainForm extends StatefulWidget {
  final Map<String, dynamic> formData;
  const DriveTrainForm({super.key, required this.formData});

  @override
  State<DriveTrainForm> createState() => _DriveTrainFormState();
}

class _DriveTrainFormState extends State<DriveTrainForm> {
  String? cabCondition;
  bool? hasEngineLeaks;
  bool? hasOilLeaks;
  bool? isEngineBreaking;
  bool? isGearboxLeaking;
  bool? hasGearboxNoise;
  bool? hasDriveDamage;
  final TextEditingController _damageController = TextEditingController();
  String? driveTrainCondition;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                      child: widget.formData['coverPhotoUrl']?.isNotEmpty ==
                              true
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
                          Navigator.pushNamed(context,
                              '/maintenance'); // Update with your route
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Drive Train Title and Condition
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Colors.transparent,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'DRIVE TRAIN',
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

                      // Photos Section
                      _buildSectionTitle('PHOTO'),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        padding: const EdgeInsets.all(16),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          _buildImageUploadBox('LEFT'),
                          _buildImageUploadBox('RIGHT'),
                          _buildImageUploadBox('FRONT'),
                          _buildImageUploadBox('TOP'),
                        ],
                      ),

                      // Engine Section
                      _buildSectionTitle('ENGINE'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            _buildImageUploadBox('LEFT'),
                            _buildImageUploadBox('RIGHT'),
                          ],
                        ),
                      ),

                      // Engine Questions
                      _buildYesNoSection(
                        'ARE THERE ANY OIL LEAKS ON THE ENGINE',
                        hasEngineLeaks,
                        (value) => setState(() => hasEngineLeaks = value),
                        TextEditingController(),
                        'Describe the leak',
                        'PLEASE TAKE A PICTURE OF THE LEAK',
                        'ADD ADDITIONAL LEAK',
                      ),
                      _buildYesNoSection(
                        'ARE THERE ANY WATER LEAKS ON THE ENGINE',
                        hasOilLeaks,
                        (value) => setState(() => hasOilLeaks = value),
                        TextEditingController(),
                        'Describe the leak',
                        'PLEASE TAKE A PICTURE OF THE LEAK',
                        'ADD ADDITIONAL LEAK',
                      ),
                      _buildYesNoSection(
                        'IS THERE AN ENGINE BRAKE BREAKING',
                        isEngineBreaking,
                        (value) => setState(() => isEngineBreaking = value),
                        TextEditingController(),
                        'Describe the issue',
                        'PLEASE TAKE A PICTURE',
                        'ADD ADDITIONAL ISSUE',
                      ),

                      // Gearbox Section
                      _buildSectionTitle('GEARBOX'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              children: [
                                _buildImageUploadBox('TOP VIEW'),
                                _buildImageUploadBox('SIDE VIEW'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 150, // Adjust height as needed
                              child: _buildImageUploadBox('BACK VIEW'),
                            ),
                          ],
                        ),
                      ),

                      // Gearbox Questions
                      _buildYesNoSection(
                        'IS THE GEAR BOX LEAKING OIL?',
                        isGearboxLeaking,
                        (value) => setState(() => isGearboxLeaking = value),
                        TextEditingController(),
                        'Describe the leak',
                        'PICTURE OF LEAK',
                        'ADD ADDITIONAL LEAK',
                      ),
                      _buildYesNoSection(
                        'GEAR BOX NOISE WHEN IN NEUTRAL?',
                        hasGearboxNoise,
                        (value) => setState(() => hasGearboxNoise = value),
                        TextEditingController(),
                        'Describe the noise',
                        'PLEASE TAKE A VIDEO',
                        'ADD ADDITIONAL ISSUE',
                      ),

                      // Diffs Section
                      _buildSectionTitle('DIFFS (DIFFERENTIALS)'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            _buildImageUploadBox('FRONT DIFF OIL LEVEL'),
                            _buildImageUploadBox('FRONT DIFF CONDITION'),
                            _buildImageUploadBox('BACK DIFF OIL LEVEL'),
                            _buildImageUploadBox('BACK DIFF CONDITION'),
                          ],
                        ),
                      ),

                      // Additional Info
                      _buildSectionTitle('ADDITIONAL INFO'),
                      _buildDamageSection(),

                      // Buttons
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Center(
                              child: SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text(
                                    'CANCEL',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _saveForm,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF4E00)
                                        .withOpacity(0.25),
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
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom navigation
              Container(
                color: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    Icon(Icons.home, color: Colors.white),
                    Icon(Icons.local_shipping, color: Colors.white),
                    Icon(Icons.favorite, color: Colors.white),
                    Icon(Icons.person, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widgets...
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
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

  Widget _buildDamageSection() {
    return _buildYesNoSection(
      'ARE THERE ANY DAMAGES ON THE DRIVE TRAIN',
      hasDriveDamage,
      (value) => setState(() => hasDriveDamage = value),
      _damageController,
      'DESCRIBE DAMAGE',
      'PICTURE OF DAMAGE',
      'ADD ADDITIONAL DAMAGE',
    );
  }

  Future<void> _saveForm() async {
    final formData = {
      'condition': driveTrainCondition,
      'engineLeaks': hasEngineLeaks,
      'oilLeaks': hasOilLeaks,
      'engineBreaking': isEngineBreaking,
      'gearboxLeaking': isGearboxLeaking,
      'gearboxNoise': hasGearboxNoise,
      'damage': hasDriveDamage,
      'damageDescription': _damageController.text,
    };

    try {
      // Merge the drive train data with the existing form data
      widget.formData['driveTrain'] = formData;
      
      // Navigate to next form
      Navigator.pushNamed(context, '/chassis', arguments: widget.formData);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving form: $e')),
      );
    }
  }

  @override
  void dispose() {
    _damageController.dispose();
    super.dispose();
  }
}
