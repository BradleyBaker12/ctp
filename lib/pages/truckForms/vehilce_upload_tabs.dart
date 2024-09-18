import 'dart:io';
import 'package:ctp/components/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ctp/pages/setup_inspection.dart';
import 'package:ctp/pages/setup_collection.dart';
import 'package:ctp/providers/form_data_provider.dart';
import 'package:ctp/components/custom_button.dart'; // Import CustomButton

class VehicleUploadTabs extends StatefulWidget {
  @override
  _VehicleUploadTabsState createState() => _VehicleUploadTabsState();
}

class _VehicleUploadTabsState extends State<VehicleUploadTabs>
    with SingleTickerProviderStateMixin {
  File? _selectedMainImage;
  late TabController _tabController;
  PageController _pageController = PageController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _makeModelController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();
  final TextEditingController _vinNumberController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _applicationController = TextEditingController();
  final TextEditingController _engineNumberController = TextEditingController();
  final TextEditingController _registrationNumberController =
      TextEditingController();
  final TextEditingController _expectedSellingPriceController =
      TextEditingController();
  final TextEditingController _warrantyTypeController = TextEditingController();

  String? _selectedMileage;
  String _transmission = 'Manual';
  String _suspension = 'Steel';
  bool _isLoading = false;
  bool _isInspectionSetupComplete = false;
  bool _isCollectionSetupComplete = false;

  List<String>? _inspectionDates;
  List<Map<String, dynamic>>? _inspectionLocations;
  List<String>? _collectionDates;
  List<Map<String, dynamic>>? _collectionLocations;

  final NumberFormat _numberFormat = NumberFormat("#,##0", "en_US");
  bool _showCurrencySymbol = false;
  String _vehicleType = 'truck';
  String _weightClass = 'heavy';

  final List<String> _mileageOptions = [
    '0+',
    '10,001+',
    '20,001+',
    '50,001+',
    '100,001+',
    '200,001+',
    '500,001+',
    '1,000,001+'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // Method to upload/select the image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedMainImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.of(context).pop(); // Close the dialog
                    _pickImage(ImageSource.camera); // Pick image from camera
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.of(context).pop(); // Close the dialog
                    _pickImage(ImageSource.gallery); // Pick image from gallery
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Navigate to the Setup Inspection page and get the data back
  Future<void> _setupInspection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SetupInspectionPage(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _inspectionDates =
            result['dates'] != null ? List<String>.from(result['dates']) : [];
        _inspectionLocations = result['locations'] != null
            ? List<Map<String, dynamic>>.from(result['locations'])
            : [];
        _isInspectionSetupComplete = true;
      });

      // Save the inspection details to FormDataProvider
      Provider.of<FormDataProvider>(context, listen: false)
          .setInspectionDates(_inspectionDates);
      Provider.of<FormDataProvider>(context, listen: false)
          .setInspectionLocations(_inspectionLocations);
    }
  }

  // Navigate to the Setup Collection page and get the data back
  Future<void> _setupCollection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SetupCollectionPage(),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _collectionDates =
            result['dates'] != null ? List<String>.from(result['dates']) : [];
        _collectionLocations = result['locations'] != null
            ? List<Map<String, dynamic>>.from(result['locations'])
            : [];
        _isCollectionSetupComplete = true;
      });

      // Save the collection details to FormDataProvider
      Provider.of<FormDataProvider>(context, listen: false)
          .setCollectionDates(_collectionDates);
      Provider.of<FormDataProvider>(context, listen: false)
          .setCollectionLocations(_collectionLocations);
    }
  }

  @override
  Widget build(BuildContext context) {
    var orange = const Color(0xFFFF4E00);
    var blue = const Color(0xFF2F7FFF);
    var green = const Color(0xFF4CAF50);

    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Mandatory Section'),
            Tab(text: 'Section 2'),
            Tab(text: 'Section 3'),
            Tab(text: 'Section 4'),
            Tab(text: 'Section 5'),
            Tab(text: 'Section 6'),
            Tab(text: 'Section 7'),
          ],
        ),
      ),
      body: GradientBackground(
        child: Column(
          children: [
            // Fixed section for uploading the vehicle image
            Column(
              children: [
                const SizedBox(height: 1),
                _selectedMainImage == null
                    ? GestureDetector(
                        onTap: () => _showImageSourceDialog(),
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Icon(Icons.add_a_photo,
                              size: 50, color: Colors.grey),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Image.file(
                          _selectedMainImage!,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
              ],
            ),
            // PageView to create separate sections
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  _tabController.animateTo(index);
                },
                children: [
                  _buildSection1(orange, blue, green), // Styled Section 1
                  _buildSection2(orange, blue, green), // New Section 2
                  _buildSectionWithGradient(orange, blue, green,
                      _buildEmptySection("Section 3 - Mileage and Condition")),
                  _buildSectionWithGradient(orange, blue, green,
                      _buildEmptySection("Section 4 - Price")),
                  _buildSectionWithGradient(orange, blue, green,
                      _buildEmptySection("Section 5 - Warranty and Insurance")),
                  _buildSectionWithGradient(orange, blue, green,
                      _buildEmptySection("Section 6 - Ownership")),
                  _buildSectionWithGradient(orange, blue, green,
                      _buildEmptySection("Section 7 - Additional Information")),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionWithGradient(
      Color orange, Color blue, Color green, Widget sectionContent) {
    return GradientBackground(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: sectionContent,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomButton(
                text: 'Done',
                borderColor: orange,
                onPressed: _isLoading
                    ? null
                    : () {
                        // Define what happens when the button is pressed
                      },
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection1(Color orange, Color blue, Color green) {
    return _buildSectionWithGradient(
      orange,
      blue,
      green,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'MANDATORY INFORMATION',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Please fill out the required details below\nYour trusted partner on the road.',
                style: TextStyle(fontSize: 14, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRadioButton('Truck', 'truck'),
                const SizedBox(width: 20),
                _buildRadioButton('Trailer', 'trailer'),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildRadioButton('Heavy', 'heavy', isWeight: true),
                const SizedBox(width: 20),
                _buildRadioButton('Medium', 'medium', isWeight: true),
                const SizedBox(width: 20),
                _buildRadioButton('Light', 'light', isWeight: true),
              ],
            ),
            const SizedBox(height: 20),
            Form(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                            controller: _yearController, hintText: 'Year'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                            controller: _makeModelController,
                            hintText: 'Make/Model'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildMileageDropdown(),
                  const SizedBox(height: 15),
                  _buildSellingPriceTextField(
                      controller: _sellingPriceController,
                      hintText: 'Selling Price'),
                  const SizedBox(height: 15),
                  _buildVinTextField(
                      controller: _vinNumberController, hintText: 'VIN Number'),
                  const SizedBox(height: 30),
                  Center(
                    child: Column(
                      children: [
                        CustomButton(
                          text: _isInspectionSetupComplete
                              ? 'Inspection Setup Complete'
                              : 'Setup Inspection',
                          borderColor:
                              _isInspectionSetupComplete ? green : blue,
                          onPressed: _setupInspection,
                        ),
                        const SizedBox(height: 10),
                        CustomButton(
                          text: _isCollectionSetupComplete
                              ? 'Collection Setup Complete'
                              : 'Setup Collection',
                          borderColor:
                              _isCollectionSetupComplete ? green : blue,
                          onPressed: _setupCollection,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection2(Color orange, Color blue, Color green) {
    return _buildSectionWithGradient(
      orange,
      blue,
      green,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Form(
          key: GlobalKey<FormState>(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'TRUCK/TRAILER FORM',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextArea(
                controller: _applicationController,
                hintText: 'Application of Use',
                maxLines: 5,
              ),
              const SizedBox(height: 15),

              // Transmission Dropdown
              Text(
                "Transmission",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              _buildDropdown(
                value: _transmission,
                items: ['Manual', 'Automatic'],
                hintText: 'Transmission',
                onChanged: (value) {
                  setState(() {
                    _transmission = value!;
                  });
                },
              ),
              const SizedBox(height: 15),

              // Engine Number Field
              _buildTextField(
                controller: _engineNumberController,
                hintText: 'Engine No.',
                inputFormatter: [UpperCaseTextFormatter()],
              ),
              const SizedBox(height: 15),

              // Suspension Dropdown
              Text(
                "Suspension",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              _buildDropdown(
                value: _suspension,
                items: ['Steel', 'Air'],
                hintText: 'Suspension',
                onChanged: (value) {
                  setState(() {
                    _suspension = value!;
                  });
                },
              ),
              const SizedBox(height: 15),

              // Registration Number Field
              _buildTextField(
                controller: _registrationNumberController,
                hintText: 'Registration No.',
                inputFormatter: [UpperCaseTextFormatter()],
              ),
              const SizedBox(height: 15),

              // Expected Selling Price Field
              _buildSellingPriceTextField(
                controller: _expectedSellingPriceController,
                hintText: 'Expected Selling Price',
              ),
              const SizedBox(height: 15),

              // Warranty Type Field
              _buildTextField(
                controller: _warrantyTypeController,
                hintText: 'Warranty Type',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySection(String title) {
    return Center(
      child: Text(title,
          style: const TextStyle(fontSize: 18, color: Colors.white)),
    );
  }

  Widget _buildRadioButton(String label, String value,
      {bool isWeight = false}) {
    return Theme(
      data: ThemeData(
        unselectedWidgetColor:
            Colors.white, // White outer circle for unselected
      ),
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: isWeight ? _weightClass : _vehicleType,
            onChanged: (String? newValue) {
              setState(() {
                if (isWeight) {
                  _weightClass = newValue!;
                } else {
                  _vehicleType = newValue!;
                }
              });
            },
            activeColor: const Color(0xFFFF4E00), // Orange center for selected
          ),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    List<TextInputFormatter>? inputFormatter,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white54), // White hint text
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
              color: Color(0xFFFF4E00), width: 2.0), // Orange focused border
        ),
      ),
      style: const TextStyle(color: Colors.white),
      inputFormatters: inputFormatter,
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 5,
  }) {
    return TextFormField(
      controller: controller,
      cursorColor: const Color(0xFFFF4E00),
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: Color(0xFFFF4E00),
            width: 2.0,
          ),
        ),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildMileageDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedMileage,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[900],
        hintText: 'Mileage',
        hintStyle: const TextStyle(color: Colors.white54), // White hint text
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
              color: Color(0xFFFF4E00), width: 2.0), // Orange focused border
        ),
      ),
      dropdownColor: Colors.black,
      items: _mileageOptions.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedMileage = newValue;
          _mileageController.text = newValue!;
        });
      },
    );
  }

  Widget _buildSellingPriceTextField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white54), // White hint text
        prefixText: _showCurrencySymbol ? 'R ' : '',
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
              color: Color(0xFFFF4E00), width: 2.0), // Orange focused border
        ),
      ),
      style: const TextStyle(color: Colors.white),
      onChanged: (value) {
        setState(() {
          _showCurrencySymbol = value.isNotEmpty;
        });
        if (value.isNotEmpty) {
          final formattedValue = _numberFormat
              .format(int.parse(value.replaceAll(" ", "")))
              .replaceAll(",", " ");
          controller.value = TextEditingValue(
            text: formattedValue,
            selection: TextSelection.collapsed(offset: formattedValue.length),
          );
        }
      },
    );
  }

  Widget _buildVinTextField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white54), // White hint text
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
              color: Color(0xFFFF4E00), width: 2.0), // Orange focused border
        ),
      ),
      style: const TextStyle(color: Colors.white),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]'))
      ],
      onChanged: (value) {
        controller.value = controller.value.copyWith(
          text: value.toUpperCase(),
          selection: TextSelection.collapsed(offset: value.length),
        );
      },
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hintText,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value == '' || value == 'None' ? null : value,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(
            color: Color(0xFFFF4E00),
            width: 2.0,
          ),
        ),
      ),
      hint: Text(
        hintText,
        style: const TextStyle(color: Colors.white70),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      dropdownColor: Colors.black.withOpacity(0.7),
    );
  }
}

// Custom TextInputFormatter for uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
