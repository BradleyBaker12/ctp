import 'dart:io'; // For file handling
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart'; // For selecting images
import 'package:firebase_storage/firebase_storage.dart'; // For uploading images
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path; // For getting file names
import 'package:ctp/components/gradient_background.dart'; // Import your GradientBackground widget
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // For opening URLs

class EditVehiclePage extends StatefulWidget {
  final Vehicle vehicle;

  const EditVehiclePage({Key? key, required this.vehicle}) : super(key: key);

  @override
  _EditVehiclePageState createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<EditVehiclePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker(); // Image picker instance

  // Controllers for text fields
  late TextEditingController _makeModelController;
  late TextEditingController _transmissionController;
  late TextEditingController _yearController;
  late TextEditingController _mileageController;
  late TextEditingController _applicationController;
  late TextEditingController _bookValueController;
  late TextEditingController _damageDescriptionController;
  late TextEditingController _engineNumberController;
  late TextEditingController _expectedSellingPriceController;
  late TextEditingController _hydraulicsController;
  late TextEditingController _listDamagesController;
  late TextEditingController _registrationNumberController;
  late TextEditingController _settlementAmountController;
  late TextEditingController _spareTyreController;
  late TextEditingController _suspensionController;
  late TextEditingController _tyreTypeController;
  late TextEditingController _vinNumberController;
  late TextEditingController _warrantyTypeController;
  late TextEditingController _weightClassController;

  // Radio Button Values
  String? _maintenance;
  String? _warranty;
  String? _firstOwner;
  String? _accidentFree;
  String? _roadWorthy;
  String? _settleBeforeSelling;
  String? _rc1NatisFile;
  String? _vehicleStatus;

  // Settlement Letter
  String? _settlementLetterFileUrl;

  // List of photo URLs
  late List<String?> _photoUrls;
  final NumberFormat _numberFormat = NumberFormat('#,##0', 'en_US');

  @override
  void initState() {
    super.initState();
    print(widget.vehicle.id);
    _tabController = TabController(length: 7, vsync: this); // Updated to 7 tabs

    // Initialize controllers with existing values
    _makeModelController =
        TextEditingController(text: widget.vehicle.makeModel);
    _transmissionController =
        TextEditingController(text: widget.vehicle.transmission);
    _yearController = TextEditingController(text: widget.vehicle.year);
    _mileageController = TextEditingController(text: widget.vehicle.mileage);
    _applicationController =
        TextEditingController(text: widget.vehicle.application);
    _bookValueController =
        TextEditingController(text: widget.vehicle.bookValue);
    _damageDescriptionController =
        TextEditingController(text: widget.vehicle.damageDescription);
    _engineNumberController =
        TextEditingController(text: widget.vehicle.engineNumber);
    _expectedSellingPriceController =
        TextEditingController(text: widget.vehicle.expectedSellingPrice);
    _hydraulicsController =
        TextEditingController(text: widget.vehicle.hydraulics);
    _listDamagesController =
        TextEditingController(text: widget.vehicle.listDamages);
    _registrationNumberController =
        TextEditingController(text: widget.vehicle.registrationNumber);
    _settlementAmountController =
        TextEditingController(text: widget.vehicle.settlementAmount);
    _spareTyreController =
        TextEditingController(text: widget.vehicle.spareTyre);
    _suspensionController =
        TextEditingController(text: widget.vehicle.suspension);
    _tyreTypeController = TextEditingController(text: widget.vehicle.tyreType);
    _vinNumberController =
        TextEditingController(text: widget.vehicle.vinNumber);
    _warrantyTypeController =
        TextEditingController(text: widget.vehicle.warrantyType);
    _weightClassController =
        TextEditingController(text: widget.vehicle.weightClass);
    _rc1NatisFile = widget.vehicle.rc1NatisFile; // Initialize Natis URL

    // Initialize radio button values
    _maintenance = widget.vehicle.maintenance;
    _warranty = widget.vehicle.warranty;
    _firstOwner = widget.vehicle.firstOwner;
    _accidentFree = widget.vehicle.accidentFree;
    _roadWorthy = widget.vehicle.roadWorthy;
    _settleBeforeSelling = widget.vehicle.settleBeforeSelling;
    _settlementLetterFileUrl = widget.vehicle.settlementLetterFile;
    _vehicleStatus = widget.vehicle.vehicleStatus ?? 'Pending';

    // Initialize the photo URLs
    _photoUrls = [
      widget.vehicle.mainImageUrl,
      widget.vehicle.damagePhotos.isNotEmpty
          ? widget.vehicle.damagePhotos[0]
          : null, // first damage photo as an example
      widget.vehicle.dashboardPhoto,
      widget.vehicle.faultCodesPhoto,
      widget.vehicle.licenceDiskUrl,
      widget.vehicle.mileageImage,
      widget.vehicle.treadLeft,
      widget.vehicle.bed_bunk,
      widget.vehicle.dashboard,
      widget.vehicle.door_panels,
      widget.vehicle.front_tyres_tread,
      widget.vehicle.front_view,
      widget.vehicle.left_front_45,
      widget.vehicle.left_rear_45,
      widget.vehicle.left_side_view,
      widget.vehicle.license_disk,
      widget.vehicle.rear_tyres_tread,
      widget.vehicle.rear_view,
      widget.vehicle.right_front_45,
      widget.vehicle.right_rear_45,
      widget.vehicle.right_side_view,
      widget.vehicle.roof,
      widget.vehicle.seats,
      widget.vehicle.spare_wheel,
      widget.vehicle.tyrePhoto1,
      widget.vehicle.tyrePhoto2
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _makeModelController.dispose();
    _transmissionController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _applicationController.dispose();
    _bookValueController.dispose();
    _damageDescriptionController.dispose();
    _engineNumberController.dispose();
    _expectedSellingPriceController.dispose();
    _hydraulicsController.dispose();
    _listDamagesController.dispose();
    _registrationNumberController.dispose();
    _settlementAmountController.dispose();
    _spareTyreController.dispose();
    _suspensionController.dispose();
    _tyreTypeController.dispose();
    _vinNumberController.dispose();
    _warrantyTypeController.dispose();
    _weightClassController.dispose();
    super.dispose();
  }

  Future<void> _uploadImage(int index) async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      final pickedFile = await _picker.pickImage(source: source);

      if (pickedFile != null) {
        String fileName = path.basename(pickedFile.path);
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('vehicles/${widget.vehicle.id}/$fileName');

        try {
          File file = File(pickedFile.path);
          await storageRef.putFile(file);
          String imageUrl = await storageRef.getDownloadURL();

          // Update the URL for the respective photo
          setState(() {
            _photoUrls[index] = imageUrl;
          });
        } catch (e) {
          print("Error uploading image: $e");
        }
      }
    }
  }

  Future<void> _uploadSettlementLetterFile() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      String fileName = path.basename(pickedFile.path);
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('vehicles/${widget.vehicle.id}/settlement_letter/$fileName');

      try {
        File file = File(pickedFile.path);
        await storageRef.putFile(file);
        String fileUrl = await storageRef.getDownloadURL();

        setState(() {
          _settlementLetterFileUrl = fileUrl;
        });
      } catch (e) {
        print("Error uploading settlement letter: $e");
      }
    }
  }

  Widget _buildSettlementLetterField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Settlement Letter',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center, // Center the heading
        ),
        const SizedBox(height: 8),
        if (_settlementLetterFileUrl != null &&
            _settlementLetterFileUrl!.isNotEmpty)
          Column(
            children: [
              const Text(
                'Document Uploaded',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center, // Center the heading
              ),
              CustomButton(
                text: 'View Document',
                borderColor: const Color(0xFFFF4E00),
                onPressed: () async {
                  if (await canLaunch(_settlementLetterFileUrl!)) {
                    await launch(_settlementLetterFileUrl!);
                  } else {
                    print("Cannot open the document");
                  }
                },
              ),
            ],
          )
        else
          const Text(
            'No document uploaded',
            style: TextStyle(color: Colors.white),
            textAlign: TextAlign.center, // Center the heading
          ),
        const SizedBox(height: 8),
        CustomButton(
          text: "Upload Settlement Letter",
          borderColor: const Color(0xFFFF4E00),
          onPressed: _uploadSettlementLetterFile,
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = true,
    bool isCurrency = false, // Added to handle currency inputs
    List<TextInputFormatter>? inputFormatter, // Added input formatters
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align labels to the left
      children: [
        Text(
          label, // Heading for the input field
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white, // White text color for the label
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8), // Small space between the heading and input
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          cursorColor: const Color(0xFFFF4E00), // Orange cursor color
          decoration: InputDecoration(
            hintText: hint ?? label,
            prefixText: isCurrency ? 'R ' : '',
            prefixStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            hintStyle: const TextStyle(color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: const BorderSide(
                color: Color(0xFFFF4E00), // Orange border when focused
                width: 2.0,
              ),
            ),
          ),
          style: const TextStyle(color: Colors.white),
          inputFormatters: inputFormatter, // Apply input formatters if provided
          onChanged: isCurrency
              ? (value) {
                  if (value.isNotEmpty) {
                    try {
                      final formattedValue = _numberFormat
                          .format(int.parse(value.replaceAll(" ", "")))
                          .replaceAll(",", " ");
                      controller.value = TextEditingValue(
                        text: formattedValue,
                        selection: TextSelection.collapsed(
                            offset: formattedValue.length),
                      );
                    } catch (e) {
                      print("Error formatting amount: $e");
                    }
                  }
                }
              : null,
        ),
        const SizedBox(height: 16), // Space after the input field
      ],
    );
  }

  Widget _buildStyledRadioButton(
    String label,
    String value, {
    required String? groupValue,
    required Function(String?) onChanged,
  }) {
    bool isSelected = groupValue == value;

    return InkWell(
      onTap: () {
        onChanged(value); // Trigger the onChanged callback
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF4E00)
              : Colors.transparent, // Orange background if selected
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF4E00)
                : Colors.white54, // Orange border if selected, white otherwise
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors
                        .white70, // White text if selected, slightly faded otherwise
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledRadioField({
    required String label,
    required String? groupValue,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.white),
          textAlign: TextAlign.center, // Center the heading
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStyledRadioButton(
              'Yes', // Label for the first option
              'yes',
              groupValue: groupValue,
              onChanged: onChanged,
            ),
            const SizedBox(width: 20),
            _buildStyledRadioButton(
              'No', // Label for the second option
              'no',
              groupValue: groupValue,
              onChanged: onChanged,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettlementTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStyledRadioField(
            label: 'Settle Before Selling',
            groupValue: _settleBeforeSelling,
            onChanged: (value) {
              setState(() {
                _settleBeforeSelling = value;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildFormField(
            label: 'Settlement Amount',
            controller: _settlementAmountController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildSettlementLetterField(),
        ],
      ),
    );
  }

  Widget _buildImageField(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getPhotoLabel(index),
          style: GoogleFonts.lato(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center, // Center the heading
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[300], // Grey background for empty state
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: Colors.white,
                width: 2), // Border styling similar to VehicleUploadTabs
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _photoUrls[index] != null && _photoUrls[index]!.isNotEmpty
                ? Image.network(_photoUrls[index]!, fit: BoxFit.cover)
                : const Center(
                    child: Text(
                      'No image available',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        CustomButton(
          text: "Change Image",
          borderColor: const Color(0xFFFF4E00), // Orange color
          onPressed: () => _uploadImage(index),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _getPhotoLabel(int index) {
    switch (index) {
      case 0:
        return 'Main Image';
      case 1:
        return 'Damage Photo';
      case 2:
        return 'Dashboard Photo';
      case 3:
        return 'Fault Codes Photo';
      case 4:
        return 'License Disk';
      case 5:
        return 'Mileage Image';
      case 6:
        return 'Tread Left';
      case 7:
        return 'Bed Bunk';
      case 8:
        return 'Dashboard';
      case 9:
        return 'Door Panels';
      case 10:
        return 'Front Tyres Tread';
      case 11:
        return 'Front View';
      case 12:
        return '45° Left Front View';
      case 13:
        return '45° Left Rear View';
      case 14:
        return 'Left Side View';
      case 15:
        return 'License Disk';
      case 16:
        return 'Rear Tyres Tread';
      case 17:
        return 'Rear View';
      case 18:
        return '45° Right Front View';
      case 19:
        return '45° Right Rear View';
      case 20:
        return 'Right Side View';
      case 21:
        return 'Roof';
      case 22:
        return 'Seats';
      case 23:
        return 'Spare Wheel';
      case 24:
        return 'Tyre Photo 1';
      case 25:
        return 'Tyre Photo 2';
      default:
        return 'Unknown Label';
    }
  }

  void _saveForm() async {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      try {
        // Create an updated Vehicle object using the collected data from form fields
        Vehicle updatedVehicle = widget.vehicle.copyWith(
          makeModel: _makeModelController.text != widget.vehicle.makeModel
              ? _makeModelController.text
              : null,
          transmission:
              _transmissionController.text != widget.vehicle.transmission
                  ? _transmissionController.text
                  : null,
          year: _yearController.text != widget.vehicle.year
              ? _yearController.text
              : null,
          mileage: _mileageController.text != widget.vehicle.mileage
              ? _mileageController.text
              : null,
          application: _applicationController.text != widget.vehicle.application
              ? _applicationController.text
              : null,
          bookValue: _bookValueController.text != widget.vehicle.bookValue
              ? _bookValueController.text
              : null,
          damageDescription: _damageDescriptionController.text !=
                  widget.vehicle.damageDescription
              ? _damageDescriptionController.text
              : null,
          engineNumber:
              _engineNumberController.text != widget.vehicle.engineNumber
                  ? _engineNumberController.text
                  : null,
          expectedSellingPrice: _expectedSellingPriceController.text !=
                  widget.vehicle.expectedSellingPrice
              ? _expectedSellingPriceController.text
              : null,
          hydraulics: _hydraulicsController.text != widget.vehicle.hydraulics
              ? _hydraulicsController.text
              : null,
          listDamages: _listDamagesController.text != widget.vehicle.listDamages
              ? _listDamagesController.text
              : null,
          registrationNumber: _registrationNumberController.text !=
                  widget.vehicle.registrationNumber
              ? _registrationNumberController.text
              : null,
          settlementAmount: _settlementAmountController.text !=
                  widget.vehicle.settlementAmount
              ? _settlementAmountController.text
              : null,
          spareTyre: _spareTyreController.text != widget.vehicle.spareTyre
              ? _spareTyreController.text
              : null,
          suspension: _suspensionController.text != widget.vehicle.suspension
              ? _suspensionController.text
              : null,
          tyreType: _tyreTypeController.text != widget.vehicle.tyreType
              ? _tyreTypeController.text
              : null,
          vinNumber: _vinNumberController.text != widget.vehicle.vinNumber
              ? _vinNumberController.text
              : null,
          warrantyType:
              _warrantyTypeController.text != widget.vehicle.warrantyType
                  ? _warrantyTypeController.text
                  : null,
          weightClass: _weightClassController.text != widget.vehicle.weightClass
              ? _weightClassController.text
              : null,
          vehicleStatus: _vehicleStatus != widget.vehicle.vehicleStatus
              ? _vehicleStatus
              : null,
          // Radio Button Values
          maintenance:
              _maintenance != widget.vehicle.maintenance ? _maintenance : null,
          warranty: _warranty != widget.vehicle.warranty ? _warranty : null,
          firstOwner:
              _firstOwner != widget.vehicle.firstOwner ? _firstOwner : null,
          accidentFree: _accidentFree != widget.vehicle.accidentFree
              ? _accidentFree
              : null,
          roadWorthy:
              _roadWorthy != widget.vehicle.roadWorthy ? _roadWorthy : null,
          settleBeforeSelling:
              _settleBeforeSelling != widget.vehicle.settleBeforeSelling
                  ? _settleBeforeSelling
                  : null,
          rc1NatisFile: _rc1NatisFile != widget.vehicle.rc1NatisFile
              ? _rc1NatisFile
              : null,
          settlementLetterFile:
              _settlementLetterFileUrl != widget.vehicle.settlementLetterFile
                  ? _settlementLetterFileUrl
                  : null,
          // Images
          mainImageUrl: _photoUrls[0] != widget.vehicle.mainImageUrl
              ? _photoUrls[0]
              : null,
          damagePhotos: _photoUrls[1] != null &&
                  _photoUrls[1] != widget.vehicle.damagePhotos.first
              ? [_photoUrls[1]!]
              : null,
          dashboardPhoto: _photoUrls[2] != widget.vehicle.dashboardPhoto
              ? _photoUrls[2]
              : null,
          faultCodesPhoto: _photoUrls[3] != widget.vehicle.faultCodesPhoto
              ? _photoUrls[3]
              : null,
          licenceDiskUrl: _photoUrls[4] != widget.vehicle.licenceDiskUrl
              ? _photoUrls[4]
              : null,
          mileageImage: _photoUrls[5] != widget.vehicle.mileageImage
              ? _photoUrls[5]
              : null,
          // Add similar checks for the rest of your image URLs
          bed_bunk:
              _photoUrls[7] != widget.vehicle.bed_bunk ? _photoUrls[7] : null,
          dashboard:
              _photoUrls[8] != widget.vehicle.dashboard ? _photoUrls[8] : null,
          door_panels: _photoUrls[9] != widget.vehicle.door_panels
              ? _photoUrls[9]
              : null,
          front_tyres_tread: _photoUrls[10] != widget.vehicle.front_tyres_tread
              ? _photoUrls[10]
              : null,
          front_view: _photoUrls[11] != widget.vehicle.front_view
              ? _photoUrls[11]
              : null,
          left_front_45: _photoUrls[12] != widget.vehicle.left_front_45
              ? _photoUrls[12]
              : null,
          left_rear_45: _photoUrls[13] != widget.vehicle.left_rear_45
              ? _photoUrls[13]
              : null,
          left_side_view: _photoUrls[14] != widget.vehicle.left_side_view
              ? _photoUrls[14]
              : null,
          license_disk: _photoUrls[15] != widget.vehicle.license_disk
              ? _photoUrls[15]
              : null,
          rear_tyres_tread: _photoUrls[16] != widget.vehicle.rear_tyres_tread
              ? _photoUrls[16]
              : null,
          rear_view: _photoUrls[17] != widget.vehicle.rear_view
              ? _photoUrls[17]
              : null,
          right_front_45: _photoUrls[18] != widget.vehicle.right_front_45
              ? _photoUrls[18]
              : null,
          right_rear_45: _photoUrls[19] != widget.vehicle.right_rear_45
              ? _photoUrls[19]
              : null,
          right_side_view: _photoUrls[20] != widget.vehicle.right_side_view
              ? _photoUrls[20]
              : null,
          roof: _photoUrls[21] != widget.vehicle.roof ? _photoUrls[21] : null,
          seats: _photoUrls[22] != widget.vehicle.seats ? _photoUrls[22] : null,
          spare_wheel: _photoUrls[23] != widget.vehicle.spare_wheel
              ? _photoUrls[23]
              : null,
          tyrePhoto1: _photoUrls[24] != widget.vehicle.tyrePhoto1
              ? _photoUrls[24]
              : null,
          tyrePhoto2: _photoUrls[25] != widget.vehicle.tyrePhoto2
              ? _photoUrls[25]
              : null,
        );

        // Call the provider method to update the vehicle in Firestore
        await Provider.of<VehicleProvider>(context, listen: false)
            .updateVehicle(updatedVehicle);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle updated successfully!')),
        );

        // Optionally, you can navigate back or reset the form
        Navigator.of(context).pop();
      } catch (e) {
        print("Error updating vehicle: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error saving vehicle. Please try again.')),
        );
      }
    }
  }

  // Natis upload method
  Future<void> _uploadNatisDocument() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      String fileName = path.basename(pickedFile.path);
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('vehicles/${widget.vehicle.id}/natis/$fileName');

      try {
        File file = File(pickedFile.path);
        await storageRef.putFile(file);
        String fileUrl = await storageRef.getDownloadURL();

        setState(() {
          _rc1NatisFile = fileUrl;
        });
      } catch (e) {
        print("Error uploading Natis document: $e");
      }
    }
  }

  // Tab for Natis document
  Widget _buildNatisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNatisField(),
        ],
      ),
    );
  }

  Widget _buildDamagesAndFaultsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Damage description field
          _buildFormField(
            label: 'Damage Description',
            controller: _damageDescriptionController,
          ),
          const SizedBox(height: 16),

          // Fault codes photo field
          _buildFaultCodesPhotoField(),

          // List Damages field
          _buildFormField(
            label: 'List Damages',
            controller: _listDamagesController,
          ),
          const SizedBox(height: 16),

          // More fields related to faults and damages can be added here as needed
        ],
      ),
    );
  }

  Widget _buildFaultCodesPhotoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          // Center the heading
          child: Text(
            'Fault Codes Photo',
            style: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        if (widget.vehicle.faultCodesPhoto != null &&
            widget.vehicle.faultCodesPhoto!.isNotEmpty)
          Column(
            children: [
              Image.network(widget.vehicle.faultCodesPhoto!, height: 150),
              const SizedBox(height: 8),
              CustomButton(
                text: "Change Fault Codes Photo",
                borderColor: const Color(0xFFFF4E00), // Orange color
                onPressed: () => _uploadFaultCodesPhoto(),
              ),
            ],
          )
        else
          CustomButton(
            text: "Upload Fault Codes Photo",
            borderColor: const Color(0xFFFF4E00), // Orange color
            onPressed: () => _uploadFaultCodesPhoto(),
          ),
      ],
    );
  }

  Widget _buildNatisField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          // Center the heading
          child: Text(
            'Natis Document',
            style: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        if (_rc1NatisFile != null && _rc1NatisFile!.isNotEmpty)
          Column(
            children: [
              if (_rc1NatisFile!.endsWith('.jpg') ||
                  _rc1NatisFile!.endsWith('.png'))
                Column(
                  children: [
                    const Center(
                      // Center the heading
                      child: Text(
                        'NATIS Image Preview:',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Image.network(_rc1NatisFile!,
                        height: 150, fit: BoxFit.cover),
                  ],
                )
              else
                Column(
                  children: [
                    const Center(
                      // Center the heading
                      child: Text(
                        'NATIS PDF Document Uploaded',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomButton(
                      text: "View PDF Document",
                      borderColor: const Color(0xFFFF4E00), // Orange color
                      onPressed: () async {
                        if (await canLaunch(_rc1NatisFile!)) {
                          await launch(_rc1NatisFile!);
                        } else {
                          print("Cannot open the document");
                        }
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              CustomButton(
                text: "Replace Natis Document",
                borderColor: const Color(0xFFFF4E00), // Orange color
                onPressed: _uploadNatisDocument,
              ),
            ],
          )
        else
          Column(
            children: [
              const Center(
                // Center the heading
                child: Text(
                  'No document uploaded',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              CustomButton(
                text: "Upload Natis Document",
                borderColor: const Color(0xFFFF4E00), // Orange color
                onPressed: _uploadNatisDocument,
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _uploadFaultCodesPhoto() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      String fileName = path.basename(pickedFile.path);
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('vehicles/${widget.vehicle.id}/fault_codes/$fileName');

      try {
        File file = File(pickedFile.path);
        await storageRef.putFile(file);
        String imageUrl = await storageRef.getDownloadURL();

        // Update the state
        setState(() {
          _photoUrls[3] = imageUrl; // Update the fault codes photo URL
        });
      } catch (e) {
        print("Error uploading fault codes photo: $e");
      }
    }
  }

  Widget _buildTyresTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageField(24), // Tyre Photo 1
          _buildImageField(25), // Tyre Photo 2
          _buildFormField(
            label: 'Front Left Tyre Tread',
            controller: _tyreTypeController, // Use appropriate controller
          ),
          const SizedBox(height: 16),
          _buildFormField(
            label: 'Front Right Tyre Tread',
            controller: _tyreTypeController, // Use appropriate controller
          ),
          const SizedBox(height: 16),
          _buildFormField(
            label: 'Rear Tyre Tread',
            controller: _tyreTypeController, // Use appropriate controller
          ),
          const SizedBox(height: 16),
          _buildFormField(
            label: 'Spare Tyre',
            controller: _spareTyreController,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSpecificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Adding the radio buttons to the specifications tab
          _buildStyledRadioField(
            label: 'Accident Free',
            groupValue: _accidentFree,
            onChanged: (value) {
              setState(() {
                _accidentFree = value;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildStyledRadioField(
            label: 'Road Worthy',
            groupValue: _roadWorthy,
            onChanged: (value) {
              setState(() {
                _roadWorthy = value;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildStyledRadioField(
            label: 'First Owner',
            groupValue: _firstOwner,
            onChanged: (value) {
              setState(() {
                _firstOwner = value;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildStyledRadioField(
            label: 'Maintenance',
            groupValue: _maintenance,
            onChanged: (value) {
              setState(() {
                _maintenance = value;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildStyledRadioField(
            label: 'Settle Before Selling',
            groupValue: _settleBeforeSelling,
            onChanged: (value) {
              setState(() {
                _settleBeforeSelling = value;
              });
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildVehicleStatusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Vehicle Status',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        DropdownButton<String>(
          value: _vehicleStatus,
          dropdownColor: Colors.blue[900],
          iconEnabledColor: Colors.white, // Dropdown arrow color
          items: <String>['Live', 'Draft', 'Pending'] // Corrected here
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: _onStatusChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _onStatusChanged(String? newValue) {
    setState(() {
      _vehicleStatus = newValue!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Vehicle',
          style: GoogleFonts.montserrat(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            color: Colors.white,
            onPressed: _saveForm,
          ),
        ],
        backgroundColor: Colors.blue[900],
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: GradientBackground(
        child: SizedBox.expand(
          child: Form(
            key: _formKey, // Move the Form here
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[500],
                  isScrollable: true, // Make the tabs scrollable
                  tabs: const [
                    Tab(text: 'Details'),
                    Tab(text: 'Specifications'),
                    Tab(text: 'Images'),
                    Tab(text: 'Settlement'),
                    Tab(text: 'Natis'),
                    Tab(text: 'Damages and Faults'), // New tab added
                    Tab(text: 'Tyres'), // New tab added
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Vehicle Details
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildVehicleStatusField(),
                            _buildFormField(
                              label: 'Make & Model',
                              controller: _makeModelController,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'Year',
                              controller: _yearController,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'Mileage',
                              controller: _mileageController,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'VIN Number',
                              controller: _vinNumberController,
                              keyboardType: TextInputType.text,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'Book Values',
                              controller: _bookValueController,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'Application Of Use',
                              controller: _applicationController,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'Transmission',
                              controller: _transmissionController,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'Engine No.',
                              controller: _engineNumberController,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'Suspension',
                              controller: _suspensionController,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'Registration No.',
                              controller: _registrationNumberController,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'Hydraulics',
                              controller: _hydraulicsController,
                            ),
                            const SizedBox(height: 16),
                            _buildFormField(
                              label: 'Expected Selling Price',
                              controller: _expectedSellingPriceController,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      _buildSpecificationsTab(),
                      // Tab 3: Images
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload and manage vehicle images',
                              style: GoogleFonts.lato(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center, // Center the heading
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing:
                                  16.0, // Horizontal space between image fields
                              runSpacing:
                                  16.0, // Vertical space between image fields
                              children: List.generate(
                                _photoUrls.length,
                                (index) => SizedBox(
                                  width: MediaQuery.of(context).size.width / 2 -
                                      24, // Adjust the size to fit two images per row
                                  child: _buildImageField(index),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tab 4: Settlement
                      _buildSettlementTab(),
                      // Tab 5: Natis
                      _buildNatisTab(),
                      _buildDamagesAndFaultsTab(),
                      // Tab 7: Tyres (New Tab)
                      _buildTyresTab(), // Newly added Tyres tab
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
