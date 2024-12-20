// // edit_vehicle_page.dart

// import 'dart:io'; // For file handling
// import 'package:ctp/components/custom_button.dart';
// import 'package:ctp/models/vehicle.dart';
// import 'package:ctp/pages/vehicles_list.dart';
// import 'package:ctp/providers/vehicles_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:image_picker/image_picker.dart'; // For selecting images
// import 'package:firebase_storage/firebase_storage.dart'; // For uploading images
// import 'package:intl/intl.dart';
// import 'package:path/path.dart' as path; // For getting file names
// import 'package:ctp/components/gradient_background.dart'; // Import your GradientBackground widget
// import 'package:provider/provider.dart';
// import 'package:url_launcher/url_launcher.dart'; // For opening URLs

// class EditVehiclePage extends StatefulWidget {
//   final Vehicle vehicle;

//   const EditVehiclePage({super.key, required this.vehicle});

//   @override
//   _EditVehiclePageState createState() => _EditVehiclePageState();
// }

// class _EditVehiclePageState extends State<EditVehiclePage>
//     with SingleTickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();
//   late TabController _tabController;
//   final ImagePicker _picker = ImagePicker(); // Image picker instance

//   // Controllers
//   late TextEditingController _yearController;
//   late TextEditingController _makeModelController;
//   late TextEditingController _mileageController;
//   late TextEditingController _vinNumberController;
//   late TextEditingController _engineNumberController;
//   late TextEditingController _registrationNumberController;
//   late TextEditingController _sellingPriceController;
//   late TextEditingController _warrantyDetailsController;

// // Radio Button Values
//   String? _vehicleType;
//   String? _suspension;
//   String? _transmissionType;
//   String? _hydraulics;
//   String? _maintenance;
//   String? _warranty;
//   String? _settleBeforeSelling;

// // Dropdown Values
//   String? _config;
//   String? _application;

// // Options Lists
//   final List<String> _vehicleTypes = ['Truck', 'Trailer'];
//   final List<String> _suspensionOptions = ['Spring', 'Coil'];
//   final List<String> _transmissionTypeOptions = ['Automatic', 'Manual'];
//   final List<String> _hydraulicsOptions = ['Yes', 'No'];
//   final List<String> _configOptions = ['6X4', '6X2', '4X2', '8X4'];
//   final List<String> _applicationOptions = [
//     'Tractor Units',
//     'Tipper Trucks',
//     'Box Trucks',
//     'Curtain Side Trucks',
//     'Chassis Cab Truck',
//     'Flatbed Truck',
//     'Refrigerated Truck',
//     'Crane Truck',
//     'Hook Loader Truck',
//     'Concrete Truck',
//     'Municipal Truck',
//     'Dismantled Truck',
//   ];

//   // Controllers for text fields
//   late TextEditingController _applicationController;
//   late TextEditingController _bookValueController;
//   late TextEditingController _damageDescriptionController;
//   late TextEditingController _expectedSellingPriceController;
//   late TextEditingController _listDamagesController;
//   late TextEditingController _settlementAmountController;
//   late TextEditingController _spareTyreController;
//   late TextEditingController _tyreTypeController;
//   late TextEditingController _warrantyTypeController;
//   late TextEditingController _vehicleAvailableImmediatelyController;
//   late TextEditingController _availableDateController;
//   late TextEditingController _treadLeftController;
//   late TextEditingController _oemInspectionController;

//   // Radio Button Values
//   String? _firstOwner;
//   String? _accidentFree;
//   String? _roadWorthy;
//   String? _vehicleStatus;
//   String? _vehicleAvailableImmediately;
//   String? _weightClass;

//   // Dropdown Values
//   String? _hydraluicType;

//   // Settlement Letter
//   String? _settlementLetterFileUrl;

//   // Natis document
//   String? _rc1NatisFile;

//   // List of photo URLs
//   late List<String?> _photoUrls;

//   final NumberFormat _numberFormat = NumberFormat('#,##0', 'en_US');

//   // Dropdown options and radio button options
//   final List<String> _transmission = ['AUTO', 'MANUAL'];
//   final List<String> _suspensionTypes = ['Air', 'Spring', 'Hydraulic'];
//   final List<String> _hydraluicTypeTypes = ['Yes', 'No'];
//   final List<String> _weightClasses = ['Light', 'Medium', 'Heavy'];

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 7, vsync: this);

//     _makeModelController =
//         TextEditingController(text: widget.vehicle.makeModel ?? '');
//     _yearController = TextEditingController(text: widget.vehicle.year ?? '');
//     _mileageController =
//         TextEditingController(text: widget.vehicle.mileage ?? '');
//     _vinNumberController =
//         TextEditingController(text: widget.vehicle.vinNumber ?? '');
//     _engineNumberController =
//         TextEditingController(text: widget.vehicle.engineNumber ?? '');
//     _registrationNumberController =
//         TextEditingController(text: widget.vehicle.registrationNumber ?? '');
//     _sellingPriceController =
//         TextEditingController(text: widget.vehicle.expectedSellingPrice ?? '');
//     _warrantyDetailsController =
//         TextEditingController(text: widget.vehicle.warrentyType ?? '');

//     _vehicleType = widget.vehicle.vehicleType;
//     _suspension = widget.vehicle.suspensionType;
//     _transmissionType = widget.vehicle.transmissionType;
//     _hydraulics = widget.vehicle.hydraluicType;
//     _warranty = widget.vehicle.warrentyType;
//     _settleBeforeSelling = widget.vehicle.adminData.settlementAmount;
//     _config = widget.vehicle.config;
//     _application = widget.vehicle.application;

//     // Initialize controllers with existing values
//     _makeModelController =
//         TextEditingController(text: widget.vehicle.makeModel ?? '');
//     _yearController = TextEditingController(text: widget.vehicle.year ?? '');
//     _mileageController =
//         TextEditingController(text: widget.vehicle.mileage ?? '');
//     _applicationController =
//         TextEditingController(text: widget.vehicle.application ?? '');
//     _damageDescriptionController =
//         TextEditingController(text: widget.vehicle.damageDescription ?? '');
//     _engineNumberController =
//         TextEditingController(text: widget.vehicle.engineNumber ?? '');
//     _expectedSellingPriceController =
//         TextEditingController(text: widget.vehicle.expectedSellingPrice ?? '');
//     _registrationNumberController =
//         TextEditingController(text: widget.vehicle.registrationNumber ?? '');
//     _vinNumberController =
//         TextEditingController(text: widget.vehicle.vinNumber ?? '');
//     _warrantyTypeController =
//         TextEditingController(text: widget.vehicle.warrentyType ?? '');
//     _vehicleAvailableImmediatelyController = TextEditingController(
//         text: widget.vehicle.vehicleAvailableImmediately ?? '');
//     _availableDateController =
//         TextEditingController(text: widget.vehicle.availableDate ?? '');
//     _bookValueController = TextEditingController(); // Initialize if needed
//     _listDamagesController = TextEditingController(); // Initialize if needed
//     _settlementAmountController =
//         TextEditingController(); // Initialize if needed
//     _spareTyreController = TextEditingController(); // Initialize if needed
//     _tyreTypeController = TextEditingController(); // Initialize if needed
//     _treadLeftController = TextEditingController(); // Initialize if needed

//     // Initialize OEM Inspection Controller
//     _oemInspectionController = TextEditingController(
//         text: widget.vehicle.maintenance.oemInspectionType ?? '');

//     // Initialize radio button values
//     // _maintenance = widget.vehicle.maintenance;
//     _vehicleStatus = widget.vehicle.vehicleStatus ?? 'Pending';
//     _vehicleType = widget.vehicle.vehicleType;
//     _vehicleAvailableImmediately = widget.vehicle.vehicleAvailableImmediately;

//     // Dropdown values
//     _transmissionType = widget.vehicle.transmissionType;
//     _hydraluicType = widget.vehicle.hydraluicType;
//     _suspension = widget.vehicle.suspensionType;
//     _config = widget.vehicle.config;

//     // Initialize the photo URLs with the correct number of elements
//     _photoUrls = List<String?>.filled(24, null);

//     // Assign values to each index
//     _photoUrls[0] = widget.vehicle.mainImageUrl;
//     _photoUrls[1] = widget.vehicle.damagePhotos.isNotEmpty
//         ? widget.vehicle.damagePhotos[0]
//         : null;
//     _photoUrls[2] = widget.vehicle.dashboardPhoto;
//     _photoUrls[3] = widget.vehicle.faultCodesPhoto;
//     _photoUrls[4] = widget.vehicle.licenceDiskUrl;
//     _photoUrls[5] = widget.vehicle.mileageImage;

//     // Initialize settlement letter and Natis file URLs
//     _rc1NatisFile = widget.vehicle.rc1NatisFile;
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _makeModelController.dispose();
//     _yearController.dispose();
//     _mileageController.dispose();
//     _applicationController.dispose();
//     _bookValueController.dispose();
//     _damageDescriptionController.dispose();
//     _engineNumberController.dispose();
//     _expectedSellingPriceController.dispose();
//     _listDamagesController.dispose();
//     _registrationNumberController.dispose();
//     _settlementAmountController.dispose();
//     _spareTyreController.dispose();
//     _tyreTypeController.dispose();
//     _vinNumberController.dispose();
//     _warrantyTypeController.dispose();
//     _vehicleAvailableImmediatelyController.dispose();
//     _availableDateController.dispose();
//     _treadLeftController.dispose();
//     _oemInspectionController.dispose(); // Dispose the controller
//     super.dispose();
//   }

//   // Upload Image Method
//   Future<void> _uploadImage(int index) async {
//     final ImageSource? source = await showDialog<ImageSource>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Select Image Source'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.camera_alt),
//                 title: const Text('Camera'),
//                 onTap: () => Navigator.of(context).pop(ImageSource.camera),
//               ),
//               ListTile(
//                 leading: const Icon(Icons.photo_library),
//                 title: const Text('Gallery'),
//                 onTap: () => Navigator.of(context).pop(ImageSource.gallery),
//               ),
//             ],
//           ),
//         );
//       },
//     );

//     if (source != null) {
//       final pickedFile = await _picker.pickImage(source: source);

//       if (pickedFile != null) {
//         String fileName = path.basename(pickedFile.path);
//         Reference storageRef = FirebaseStorage.instance
//             .ref()
//             .child('vehicles/${widget.vehicle.id}/$fileName');

//         try {
//           File file = File(pickedFile.path);
//           await storageRef.putFile(file);
//           String imageUrl = await storageRef.getDownloadURL();

//           // Update the URL for the respective photo
//           setState(() {
//             _photoUrls[index] = imageUrl;
//           });
//         } catch (e) {
//           print("Error uploading image: $e");
//         }
//       }
//     }
//   }

//   // Upload Settlement Letter
//   Future<void> _uploadSettlementLetterFile() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       String fileName = path.basename(pickedFile.path);
//       Reference storageRef = FirebaseStorage.instance
//           .ref()
//           .child('vehicles/${widget.vehicle.id}/settlement_letter/$fileName');

//       try {
//         File file = File(pickedFile.path);
//         await storageRef.putFile(file);
//         String fileUrl = await storageRef.getDownloadURL();

//         setState(() {
//           _settlementLetterFileUrl = fileUrl;
//         });
//       } catch (e) {
//         print("Error uploading settlement letter: $e");
//       }
//     }
//   }

//   // Upload Natis Document
//   Future<void> _uploadNatisDocument() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       String fileName = path.basename(pickedFile.path);
//       Reference storageRef = FirebaseStorage.instance
//           .ref()
//           .child('vehicles/${widget.vehicle.id}/natis/$fileName');

//       try {
//         File file = File(pickedFile.path);
//         await storageRef.putFile(file);
//         String fileUrl = await storageRef.getDownloadURL();

//         setState(() {
//           _rc1NatisFile = fileUrl;
//         });
//       } catch (e) {
//         print("Error uploading Natis document: $e");
//       }
//     }
//   }

//   // Upload Fault Codes Photo
//   Future<void> _uploadFaultCodesPhoto() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       String fileName = path.basename(pickedFile.path);
//       Reference storageRef = FirebaseStorage.instance
//           .ref()
//           .child('vehicles/${widget.vehicle.id}/fault_codes/$fileName');

//       try {
//         File file = File(pickedFile.path);
//         await storageRef.putFile(file);
//         String imageUrl = await storageRef.getDownloadURL();

//         // Update the state
//         setState(() {
//           _photoUrls[3] = imageUrl; // Update the fault codes photo URL
//         });
//       } catch (e) {
//         print("Error uploading fault codes photo: $e");
//       }
//     }
//   }

//   // Build Form Field
//   Widget _buildFormField({
//     required String label,
//     required TextEditingController controller,
//     String? hint,
//     TextInputType keyboardType = TextInputType.text,
//     bool isCurrency = false,
//     List<TextInputFormatter>? inputFormatter,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start, // Align labels to the left
//       children: [
//         Text(
//           label, // Heading for the input field
//           style: const TextStyle(
//             fontSize: 16,
//             color: Colors.white, // White text color for the label
//             fontWeight: FontWeight.bold,
//           ),
//           textAlign: TextAlign.start,
//         ),
//         const SizedBox(height: 8), // Small space between the heading and input
//         TextFormField(
//           controller: controller,
//           keyboardType: keyboardType,
//           cursorColor: const Color(0xFFFF4E00), // Orange cursor color
//           decoration: InputDecoration(
//             hintText: hint ?? label,
//             prefixText: isCurrency ? 'R ' : '',
//             prefixStyle: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//             ),
//             hintStyle: const TextStyle(color: Colors.white70),
//             filled: true,
//             fillColor: Colors.white.withOpacity(0.2),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10.0),
//               borderSide: BorderSide(
//                 color: Colors.white.withOpacity(0.5),
//               ),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10.0),
//               borderSide: const BorderSide(
//                 color: Color(0xFFFF4E00), // Orange border when focused
//                 width: 2.0,
//               ),
//             ),
//           ),
//           style: const TextStyle(color: Colors.white),
//           inputFormatters: inputFormatter,
//           onChanged: isCurrency
//               ? (value) {
//                   if (value.isNotEmpty) {
//                     try {
//                       final formattedValue = _numberFormat
//                           .format(int.parse(value.replaceAll(" ", "")))
//                           .replaceAll(",", " ");
//                       controller.value = TextEditingValue(
//                         text: formattedValue,
//                         selection: TextSelection.collapsed(
//                             offset: formattedValue.length),
//                       );
//                     } catch (e) {
//                       print("Error formatting amount: $e");
//                     }
//                   }
//                 }
//               : null,
//         ),
//         const SizedBox(height: 16), // Space after the input field
//       ],
//     );
//   }

//   // Build Dropdown
//   Widget _buildDropdown({
//     required String? value,
//     required List<String> items,
//     required String hintText,
//     required Function(String?) onChanged,
//   }) {
//     String? dropdownValue = items.contains(value) ? value : null;

//     return DropdownButtonFormField<String>(
//       value: dropdownValue,
//       onChanged: onChanged,
//       decoration: InputDecoration(
//         hintText: hintText,
//         hintStyle: const TextStyle(color: Colors.white70),
//         filled: true,
//         fillColor: Colors.white.withOpacity(0.2),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10.0),
//           borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10.0),
//           borderSide: const BorderSide(
//             color: Color(0xFFFF4E00),
//             width: 2.0,
//           ),
//         ),
//       ),
//       hint: Text(
//         hintText,
//         style: const TextStyle(color: Colors.white70),
//       ),
//       items: items.map((String item) {
//         return DropdownMenuItem<String>(
//           value: item,
//           child: Text(
//             item,
//             style: const TextStyle(color: Colors.white),
//           ),
//         );
//       }).toList(),
//       dropdownColor: Colors.black.withOpacity(0.7),
//     );
//   }

//   // Build Radio Button
//   Widget _buildRadioButton(
//     String label,
//     String value, {
//     String? groupValue,
//     Function(String?)? onChanged,
//     bool isWeight = false,
//   }) {
//     bool isSelected =
//         (groupValue ?? (isWeight ? _weightClass : _vehicleType)) == value;

//     return InkWell(
//       onTap: () {
//         if (onChanged != null) {
//           onChanged(value);
//         } else {
//           setState(() {
//             if (isWeight) {
//               _weightClass = value;
//             } else {
//               _vehicleType = value;
//             }
//           });
//         }
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           color: isSelected
//               ? const Color(0xFFFF4E00)
//               : Colors.transparent, // Orange background if selected
//           border: Border.all(
//             color: isSelected
//                 ? const Color(0xFFFF4E00)
//                 : Colors.white54, // Orange border if selected, white otherwise
//             width: 2.0,
//           ),
//           borderRadius: BorderRadius.circular(10.0),
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//         child: Text(
//           label,
//           style: TextStyle(
//             color: isSelected
//                 ? Colors.white
//                 : Colors
//                     .white70, // White text if selected, slightly faded otherwise
//             fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//           ),
//         ),
//       ),
//     );
//   }

//   // Build Styled Radio Field with multiple options
//   Widget _buildStyledRadioField({
//     required String label,
//     required List<String> options,
//     required String? groupValue,
//     required void Function(String?) onChanged,
//     bool isWeight = false,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center, // Align labels to the left
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 16, color: Colors.white),
//           textAlign: TextAlign.start,
//         ),
//         const SizedBox(height: 8),
//         Wrap(
//           spacing: 10,
//           alignment: WrapAlignment.start,
//           children: options.map((option) {
//             return _buildRadioButton(
//               option,
//               option,
//               groupValue: groupValue,
//               onChanged: onChanged,
//               isWeight: isWeight,
//             );
//           }).toList(),
//         ),
//         const SizedBox(height: 16),
//       ],
//     );
//   }

//   // Build Vehicle Status Field
//   Widget _buildVehicleStatusField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Vehicle Status',
//           style: TextStyle(fontSize: 16, color: Colors.white),
//         ),
//         const SizedBox(height: 8),
//         _buildDropdown(
//           value: _vehicleStatus,
//           items: ['Live', 'Draft', 'Pending'],
//           hintText: 'Select Vehicle Status',
//           onChanged: (newValue) {
//             setState(() {
//               _vehicleStatus = newValue!;
//             });
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildVehicleDetailsTab() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Vehicle Type Radio Buttons
//           _buildStyledRadioField(
//             label: 'Vehicle Type',
//             options: _vehicleTypes,
//             groupValue: _vehicleType,
//             onChanged: (value) {
//               setState(() {
//                 _vehicleType = value;
//               });
//             },
//           ),
//           const SizedBox(height: 16),
//           // Year and Make/Model Fields
//           Row(
//             children: [
//               Expanded(
//                 child: _buildFormField(
//                   label: 'Year',
//                   controller: _yearController,
//                   keyboardType: TextInputType.number,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: _buildFormField(
//                   label: 'Make/Model',
//                   controller: _makeModelController,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           // Mileage Field
//           _buildFormField(
//             label: 'Mileage',
//             controller: _mileageController,
//             keyboardType: TextInputType.number,
//           ),
//           const SizedBox(height: 16),
//           // Configuration Dropdown
//           _buildDropdown(
//             value: _config,
//             items: _configOptions,
//             hintText: 'Select Configuration',
//             onChanged: (value) {
//               setState(() {
//                 _config = value;
//               });
//             },
//           ),
//           const SizedBox(height: 16),
//           // Application of Use Dropdown
//           _buildDropdown(
//             value: _application,
//             items: _applicationOptions,
//             hintText: 'Select Application of Use',
//             onChanged: (value) {
//               setState(() {
//                 _application = value;
//               });
//             },
//           ),
//           const SizedBox(height: 16),
//           // VIN Number Field
//           _buildFormField(
//             label: 'VIN Number',
//             controller: _vinNumberController,
//           ),
//           const SizedBox(height: 16),
//           // Engine Number Field
//           _buildFormField(
//             label: 'Engine Number',
//             controller: _engineNumberController,
//           ),
//           const SizedBox(height: 16),
//           // Registration Number Field
//           _buildFormField(
//             label: 'Registration Number',
//             controller: _registrationNumberController,
//           ),
//           const SizedBox(height: 16),
//           // Selling Price Field
//           _buildFormField(
//             label: 'Selling Price',
//             controller: _sellingPriceController,
//             keyboardType: TextInputType.number,
//             isCurrency: true,
//           ),
//           const SizedBox(height: 16),
//           // Suspension Radio Buttons
//           _buildStyledRadioField(
//             label: 'Suspension',
//             options: _suspensionOptions,
//             groupValue: _suspension,
//             onChanged: (value) {
//               setState(() {
//                 _suspension = value;
//               });
//             },
//           ),
//           const SizedBox(height: 16),
//           // Transmission Radio Buttons
//           _buildStyledRadioField(
//             label: 'Transmission',
//             options: _transmissionTypeOptions,
//             groupValue: _transmissionType,
//             onChanged: (value) {
//               setState(() {
//                 _transmissionType = value;
//               });
//             },
//           ),
//           const SizedBox(height: 16),
//           // Hydraulics Radio Buttons
//           _buildStyledRadioField(
//             label: 'Hydraulics',
//             options: _hydraulicsOptions,
//             groupValue: _hydraulics,
//             onChanged: (value) {
//               setState(() {
//                 _hydraulics = value;
//               });
//             },
//           ),
//           const SizedBox(height: 16),
//           // Maintenance Radio Buttons
//           _buildStyledRadioField(
//             label: 'Maintenance',
//             options: ['Yes', 'No'],
//             groupValue: _maintenance,
//             onChanged: (value) {
//               setState(() {
//                 _maintenance = value;
//               });
//             },
//           ),
//           const SizedBox(height: 16),
//           // Warranty Radio Buttons
//           _buildStyledRadioField(
//             label: 'Warranty',
//             options: ['Yes', 'No'],
//             groupValue: _warranty,
//             onChanged: (value) {
//               setState(() {
//                 _warranty = value;
//               });
//             },
//           ),
//           const SizedBox(height: 16),
//           // Warranty Details Field (if Warranty is Yes)
//           if (_warranty == 'Yes')
//             _buildFormField(
//               label: 'Warranty Details',
//               controller: _warrantyDetailsController,
//             ),
//           const SizedBox(height: 16),
//           // Require to Settle Before Selling Radio Buttons
//           _buildStyledRadioField(
//             label: 'Require to Settle Before Selling',
//             options: ['Yes', 'No'],
//             groupValue: _settleBeforeSelling,
//             onChanged: (value) {
//               setState(() {
//                 _settleBeforeSelling = value;
//               });
//             },
//           ),
//           const SizedBox(height: 16),
//         ],
//       ),
//     );
//   }

//   // Build Specifications Tab
//   Widget _buildSpecificationsTab() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         children: [
//           _buildStyledRadioField(
//             label: 'Accident Free',
//             options: ['Yes', 'No'],
//             groupValue: _accidentFree,
//             onChanged: (value) {
//               setState(() {
//                 _accidentFree = value;
//               });
//             },
//           ),
//           _buildStyledRadioField(
//             label: 'Road Worthy',
//             options: ['Yes', 'No'],
//             groupValue: _roadWorthy,
//             onChanged: (value) {
//               setState(() {
//                 _roadWorthy = value;
//               });
//             },
//           ),
//           _buildStyledRadioField(
//             label: 'First Owner',
//             options: ['Yes', 'No'],
//             groupValue: _firstOwner,
//             onChanged: (value) {
//               setState(() {
//                 _firstOwner = value;
//               });
//             },
//           ),
//           _buildStyledRadioField(
//             label: 'Maintenance',
//             options: ['Yes', 'No'],
//             groupValue: _maintenance,
//             onChanged: (value) {
//               setState(() {
//                 _maintenance = value;
//               });
//             },
//           ),
//           // Tyre Type and other fields
//           _buildFormField(
//             label: 'Tyre Type',
//             controller: _tyreTypeController,
//           ),
//           _buildFormField(
//             label: 'Spare Tyre',
//             controller: _spareTyreController,
//           ),
//           _buildFormField(
//             label: 'Tread Left',
//             controller: _treadLeftController,
//           ),
//         ],
//       ),
//     );
//   }

//   // Build Date Picker Field
//   Widget _buildDatePickerField({
//     required String label,
//     required TextEditingController controller,
//     required String hintText,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start, // Align labels to the left
//       children: [
//         Text(
//           label, // Heading for the date picker
//           style: const TextStyle(
//             fontSize: 16,
//             color: Colors.white, // White text color for the label
//             fontWeight: FontWeight.bold,
//           ),
//           textAlign: TextAlign.start,
//         ),
//         const SizedBox(height: 8), // Small space between the heading and input
//         GestureDetector(
//           onTap: () async {
//             FocusScope.of(context).unfocus(); // Hide the keyboard
//             DateTime? pickedDate = await showDatePicker(
//               context: context,
//               initialDate: controller.text.isNotEmpty
//                   ? DateFormat('yyyy-MM-dd').parse(controller.text)
//                   : DateTime.now(),
//               firstDate: DateTime(2000),
//               lastDate: DateTime(2100),
//               builder: (BuildContext context, Widget? child) {
//                 return Theme(
//                   data: ThemeData.dark().copyWith(
//                     colorScheme: ColorScheme.dark(
//                       primary:
//                           const Color(0xFFFF4E00), // Header background color
//                       onPrimary: Colors.white, // Header text color
//                       surface: Colors.blueGrey, // Body background color
//                       onSurface: Colors.white, // Body text color
//                     ),
//                     dialogBackgroundColor: Colors.blueGrey,
//                   ),
//                   child: child!,
//                 );
//               },
//             );

//             if (pickedDate != null) {
//               String formattedDate =
//                   DateFormat('yyyy-MM-dd').format(pickedDate);
//               setState(() {
//                 controller.text = formattedDate;
//               });
//             }
//           },
//           child: AbsorbPointer(
//             child: TextFormField(
//               controller: controller,
//               decoration: InputDecoration(
//                 hintText: hintText,
//                 hintStyle: const TextStyle(color: Colors.white70),
//                 suffixIcon:
//                     const Icon(Icons.calendar_today, color: Colors.white),
//                 filled: true,
//                 fillColor: Colors.white.withOpacity(0.2),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10.0),
//                   borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10.0),
//                   borderSide: const BorderSide(
//                     color: Color(0xFFFF4E00), // Orange border when focused
//                     width: 2.0,
//                   ),
//                 ),
//               ),
//               style: const TextStyle(color: Colors.white),
//             ),
//           ),
//         ),
//         const SizedBox(height: 16), // Space after the input field
//       ],
//     );
//   }

//   // Build Settlement Tab
//   Widget _buildSettlementTab() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         children: [
//           _buildStyledRadioField(
//             label: 'Settle Before Selling',
//             options: ['Yes', 'No'],
//             groupValue: _settleBeforeSelling,
//             onChanged: (value) {
//               setState(() {
//                 _settleBeforeSelling = value;
//                 if (_settleBeforeSelling == 'No') {
//                   _settlementAmountController.text = '';
//                   _settlementLetterFileUrl = null;
//                 }
//               });
//             },
//           ),
//           if (_settleBeforeSelling == 'Yes')
//             _buildFormField(
//               label: 'Settlement Amount',
//               controller: _settlementAmountController,
//               keyboardType: TextInputType.number,
//             ),
//           if (_settleBeforeSelling == 'Yes') _buildSettlementLetterField(),
//         ],
//       ),
//     );
//   }

//   // Build Settlement Letter Field
//   Widget _buildSettlementLetterField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         const Text(
//           'Settlement Letter',
//           style: TextStyle(color: Colors.white),
//           textAlign: TextAlign.center, // Center the heading
//         ),
//         const SizedBox(height: 8),
//         if (_settlementLetterFileUrl != null &&
//             _settlementLetterFileUrl!.isNotEmpty)
//           Column(
//             children: [
//               const Text(
//                 'Document Uploaded',
//                 style: TextStyle(color: Colors.white),
//                 textAlign: TextAlign.center, // Center the heading
//               ),
//               CustomButton(
//                 text: 'View Document',
//                 borderColor: const Color(0xFFFF4E00),
//                 onPressed: () async {
//                   if (await canLaunchUrl(
//                       Uri.parse(_settlementLetterFileUrl!))) {
//                     await launchUrl(Uri.parse(_settlementLetterFileUrl!));
//                   } else {
//                     print("Cannot open the document");
//                   }
//                 },
//               ),
//             ],
//           )
//         else
//           const Text(
//             'No document uploaded',
//             style: TextStyle(color: Colors.white),
//             textAlign: TextAlign.center, // Center the heading
//           ),
//         const SizedBox(height: 8),
//         CustomButton(
//           text: "Upload Settlement Letter",
//           borderColor: const Color(0xFFFF4E00),
//           onPressed: _uploadSettlementLetterFile,
//         ),
//       ],
//     );
//   }

//   // Build Natis Tab
//   Widget _buildNatisTab() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         children: [
//           _buildNatisField(),
//         ],
//       ),
//     );
//   }

//   // Build Natis Field
//   Widget _buildNatisField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Center(
//           // Center the heading
//           child: Text(
//             'Natis Document',
//             style: TextStyle(color: Colors.white),
//           ),
//         ),
//         const SizedBox(height: 8),
//         if (_rc1NatisFile != null && _rc1NatisFile!.isNotEmpty)
//           Column(
//             children: [
//               if (_rc1NatisFile!.endsWith('.jpg') ||
//                   _rc1NatisFile!.endsWith('.png'))
//                 Column(
//                   children: [
//                     const Center(
//                       // Center the heading
//                       child: Text(
//                         'NATIS Image Preview:',
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Image.network(_rc1NatisFile!,
//                         height: 150, fit: BoxFit.cover),
//                   ],
//                 )
//               else
//                 Column(
//                   children: [
//                     const Center(
//                       // Center the heading
//                       child: Text(
//                         'NATIS PDF Document Uploaded',
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     CustomButton(
//                       text: "View PDF Document",
//                       borderColor: const Color(0xFFFF4E00), // Orange color
//                       onPressed: () async {
//                         if (await canLaunchUrl(Uri.parse(_rc1NatisFile!))) {
//                           await launchUrl(Uri.parse(_rc1NatisFile!));
//                         } else {
//                           print("Cannot open the document");
//                         }
//                       },
//                     ),
//                   ],
//                 ),
//               const SizedBox(height: 8),
//               CustomButton(
//                 text: "Replace Natis Document",
//                 borderColor: const Color(0xFFFF4E00), // Orange color
//                 onPressed: _uploadNatisDocument,
//               ),
//             ],
//           )
//         else
//           Column(
//             children: [
//               const Center(
//                 // Center the heading
//                 child: Text(
//                   'No document uploaded',
//                   style: TextStyle(color: Colors.white),
//                 ),
//               ),
//               const SizedBox(height: 8),
//               CustomButton(
//                 text: "Upload Natis Document",
//                 borderColor: const Color(0xFFFF4E00), // Orange color
//                 onPressed: _uploadNatisDocument,
//               ),
//             ],
//           ),
//       ],
//     );
//   }

//   // Build Damages and Faults Tab
//   Widget _buildDamagesAndFaultsTab() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         children: [
//           _buildFormField(
//             label: 'Damage Description',
//             controller: _damageDescriptionController,
//           ),
//           _buildFormField(
//             label: 'List Damages',
//             controller: _listDamagesController,
//           ),
//           _buildFaultCodesPhotoField(),
//         ],
//       ),
//     );
//   }

//   // Build Fault Codes Photo Field
//   Widget _buildFaultCodesPhotoField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Center(
//           // Center the heading
//           child: Text(
//             'Fault Codes Photo',
//             style: TextStyle(color: Colors.white),
//           ),
//         ),
//         const SizedBox(height: 8),
//         if (_photoUrls[3] != null && _photoUrls[3]!.isNotEmpty)
//           Column(
//             children: [
//               Image.network(_photoUrls[3]!, height: 150),
//               const SizedBox(height: 8),
//               CustomButton(
//                 text: "Change Fault Codes Photo",
//                 borderColor: const Color(0xFFFF4E00), // Orange color
//                 onPressed: _uploadFaultCodesPhoto,
//               ),
//             ],
//           )
//         else
//           CustomButton(
//             text: "Upload Fault Codes Photo",
//             borderColor: const Color(0xFFFF4E00), // Orange color
//             onPressed: _uploadFaultCodesPhoto,
//           ),
//       ],
//     );
//   }

//   // Build Tyres Tab
//   Widget _buildTyresTab() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         children: [
//           _buildImageField(22), // Tyre Photo 1
//           _buildImageField(23), // Tyre Photo 2
//           _buildFormField(
//             label: 'Front Left Tyre Tread',
//             controller: _tyreTypeController, // Use appropriate controller
//           ),
//           _buildFormField(
//             label: 'Front Right Tyre Tread',
//             controller: _tyreTypeController, // Use appropriate controller
//           ),
//           _buildFormField(
//             label: 'Rear Tyre Tread',
//             controller: _tyreTypeController, // Use appropriate controller
//           ),
//           _buildFormField(
//             label: 'Spare Tyre',
//             controller: _spareTyreController,
//           ),
//         ],
//       ),
//     );
//   }

//   // Build Images Tab
//   Widget _buildImagesTab() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Upload and manage vehicle images',
//             style: GoogleFonts.lato(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//             textAlign: TextAlign.center, // Center the heading
//           ),
//           const SizedBox(height: 16),
//           Wrap(
//             spacing: 16.0, // Horizontal space between image fields
//             runSpacing: 16.0, // Vertical space between image fields
//             children: List.generate(
//               _photoUrls.length,
//               (index) => SizedBox(
//                 width: MediaQuery.of(context).size.width / 2 -
//                     24, // Adjust the size to fit two images per row
//                 child: _buildImageField(index),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Build Image Field
//   Widget _buildImageField(int index) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           _getPhotoLabel(index),
//           style: GoogleFonts.lato(
//               color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
//           textAlign: TextAlign.center, // Center the heading
//         ),
//         const SizedBox(height: 8),
//         Container(
//           height: 150,
//           width: double.infinity,
//           decoration: BoxDecoration(
//             color: Colors.grey[300], // Grey background for empty state
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(
//                 color: Colors.white,
//                 width: 2), // Border styling similar to VehicleUploadTabs
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(10),
//             child: _photoUrls[index] != null && _photoUrls[index]!.isNotEmpty
//                 ? Image.network(_photoUrls[index]!, fit: BoxFit.cover)
//                 : const Center(
//                     child: Text(
//                       'No image available',
//                       style: TextStyle(color: Colors.black54),
//                     ),
//                   ),
//           ),
//         ),
//         const SizedBox(height: 8),
//         CustomButton(
//           text: "Change Image",
//           borderColor: const Color(0xFFFF4E00), // Orange color
//           onPressed: () => _uploadImage(index),
//         ),
//         const SizedBox(height: 16),
//       ],
//     );
//   }

//   // Get Photo Label
//   String _getPhotoLabel(int index) {
//     switch (index) {
//       case 0:
//         return 'Main Image';
//       case 1:
//         return 'Damage Photo';
//       case 2:
//         return 'Fault Codes Photo';
//       case 3:
//         return 'License Disk';
//       case 4:
//         return 'Mileage Image';
//       case 5:
//         return 'Tread Depth Image';
//       case 6:
//         return 'Bed Bunk';
//       case 7:
//         return 'Dashboard';
//       case 8:
//         return 'Door Panels';
//       case 9:
//         return 'Front Tyres Tread';
//       case 10:
//         return 'Front View';
//       case 11:
//         return '45° Left Front View';
//       case 12:
//         return '45° Left Rear View';
//       case 13:
//         return 'Left Side View';
//       case 14:
//         return 'Rear Tyres Tread';
//       case 15:
//         return 'Rear View';
//       case 16:
//         return '45° Right Front View';
//       case 17:
//         return '45° Right Rear View';
//       case 18:
//         return 'Right Side View';
//       case 19:
//         return 'Roof';
//       case 20:
//         return 'Seats';
//       case 21:
//         return 'Spare Wheel';
//       case 22:
//         return 'Tyre Photo 1';
//       case 23:
//         return 'Tyre Photo 2';
//       default:
//         return 'Unknown Label';
//     }
//   }

//   // Save Form
//   void _saveForm() async {
//     if (_formKey.currentState != null && _formKey.currentState!.validate()) {
//       try {
//         // Determine the new status based on your logic
//         // For example, set to 'Live' when saving
//         String newStatus = 'Live';

//         // Create an updated Vehicle object using the collected data from form fields

//         // Call the provider method to update the vehicle in Firestore

//         // Show success message
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Vehicle updated successfully!')),
//         );

//         // Navigate back or reset the form
//         Navigator.of(context).pop();
//       } catch (e) {
//         print("Error updating vehicle: $e");
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text('Error saving vehicle. Please try again.')),
//         );
//       }
//     }
//   }

//   // Add this method inside _EditVehiclePageState
//   Future<void> _deleteVehicle() async {
//     bool confirm = await _showDeleteConfirmationDialog();
//     if (confirm) {
//       try {
//         await Provider.of<VehicleProvider>(context, listen: false)
//             .deleteVehicle(widget.vehicle.id);

//         // Show success message
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Vehicle deleted successfully!')),
//         );

//         // Navigate back
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const VehiclesListPage()),
//         );
//       } catch (e) {
//         print("Error deleting vehicle: $e");
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text('Error deleting vehicle. Please try again.')),
//         );
//       }
//     }
//   }

//   Future<bool> _showDeleteConfirmationDialog() async {
//     return await showDialog<bool>(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: const Text('Delete Vehicle'),
//             content: const Text(
//                 'Are you sure you want to delete this vehicle? This action cannot be undone.'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(false),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(true),
//                 child: const Text(
//                   'Delete',
//                   style: TextStyle(color: Colors.red),
//                 ),
//               ),
//             ],
//           ),
//         ) ??
//         false;
//   }

//   // Add this method inside the _EditVehiclePageState class
//   Future<bool> _showExitConfirmationDialog() async {
//     return await showDialog<bool>(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: const Text('Discard changes?'),
//             content: const Text(
//                 'You have unsaved changes. Do you really want to exit?'),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(false),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(true),
//                 child: const Text('Discard'),
//               ),
//             ],
//           ),
//         ) ??
//         false;
//   }

//   // Build the main form
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Edit Vehicle',
//           style: GoogleFonts.montserrat(color: Colors.white),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.delete),
//             color: Colors.white,
//             onPressed: _deleteVehicle, // Delete button
//           ),
//           IconButton(
//             icon: const Icon(Icons.save),
//             color: Colors.white,
//             onPressed: _saveForm,
//           ),
//         ],
//         backgroundColor: Colors.blue[900],
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: GradientBackground(
//         child: SizedBox.expand(
//           child: Form(
//             key: _formKey, // Existing form key
//             child: WillPopScope(
//               onWillPop: () async {
//                 // Prompt the user to confirm exiting without saving
//                 bool shouldExit = await _showExitConfirmationDialog();
//                 return shouldExit;
//               },
//               child: Column(
//                 children: [
//                   TabBar(
//                     controller: _tabController,
//                     indicatorColor: Colors.white,
//                     labelColor: Colors.white,
//                     unselectedLabelColor: Colors.grey[500],
//                     isScrollable: true, // Make the tabs scrollable
//                     tabs: const [
//                       Tab(text: 'Details'),
//                       Tab(text: 'Specifications'),
//                       Tab(text: 'Images'),
//                       Tab(text: 'Settlement'),
//                       Tab(text: 'Natis'),
//                       Tab(text: 'Damages and Faults'),
//                       Tab(text: 'Tyres'),
//                     ],
//                   ),
//                   Expanded(
//                     child: TabBarView(
//                       controller: _tabController,
//                       children: [
//                         _buildVehicleDetailsTab(),
//                         _buildSpecificationsTab(),
//                         _buildImagesTab(),
//                         _buildSettlementTab(),
//                         _buildNatisTab(),
//                         _buildDamagesAndFaultsTab(),
//                         _buildTyresTab(),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
