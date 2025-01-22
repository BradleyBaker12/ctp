// import 'package:ctp/components/custom_text_field.dart';
// import 'package:ctp/components/gradient_background.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import '../../providers/vehicle_form_provider.dart';

// class TyresForm extends StatefulWidget {
//   final Map<String, dynamic> formData;

//   const TyresForm({super.key, required this.formData});

//   @override
//   State<TyresForm> createState() => _TyresFormState();
// }

// class _TyresFormState extends State<TyresForm> {
//   late TextEditingController _damageController;
//   String? overallCondition;
//   Map<int, String> tyreConditions = {};
//   Map<int, String> rimTypes = {};
//   bool? hasDamages;

//   @override
//   void initState() {
//     super.initState();
//     _damageController = TextEditingController();
//   }

//   void _saveForm() {
//     // Get the form provider
//     final formProvider = Provider.of<VehicleFormProvider>(context, listen: false);
    
//     // Save the tyres data to the provider
//     formProvider.updateTyresData({
//       'overallCondition': overallCondition,
//       'tyreConditions': tyreConditions,
//       'rimTypes': rimTypes,
//       'hasDamages': hasDamages,
//       'damageDescription': _damageController.text,
//     });

//     // Navigate to the next screen
//     Navigator.pushNamed(context, '/next-screen'); // Replace with your next route
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: GradientBackground(
//         child: Column(
//           children: [
//             // Top navigation buttons
//             Container(
//               color: const Color(0xFF2F7FFF),
//               padding: const EdgeInsets.only(top: 50, bottom: 16),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.only(left: 16),
//                     child: ElevatedButton(
//                       onPressed: () => Navigator.pop(context),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.black,
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 16, vertical: 8),
//                         shape: const RoundedRectangleBorder(
//                           borderRadius: BorderRadius.zero,
//                         ),
//                       ),
//                       child: Text(
//                         'BACK',
//                         style: GoogleFonts.montserrat(
//                           color: Colors.white,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     flex: 4,
//                     child: Container(),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: Text(
//                       widget.formData['referenceNumber']?.toString() ?? 'N/A',
//                       style: GoogleFonts.montserrat(
//                         color: Colors.white,
//                         fontSize: 12,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                   Expanded(
//                     flex: 2,
//                     child: Text(
//                       widget.formData['makeModel']?.toString() ?? 'N/A',
//                       style: GoogleFonts.montserrat(
//                         color: Colors.white,
//                         fontSize: 12,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Padding(
//                     padding: const EdgeInsets.only(right: 16),
//                     child: widget.formData['coverPhotoUrl']?.isNotEmpty == true
//                         ? CircleAvatar(
//                             radius: 30,
//                             backgroundImage: NetworkImage(
//                               widget.formData['coverPhotoUrl']!,
//                             ),
//                             onBackgroundImageError: (_, __) {
//                               // Handle error silently
//                             },
//                             child: widget.formData['coverPhotoUrl']!.isEmpty
//                                 ? const Text('N/A')
//                                 : null,
//                           )
//                         : const CircleAvatar(
//                             radius: 30,
//                             backgroundColor: Colors.grey,
//                             child: Text(
//                               'N/A',
//                               style: TextStyle(color: Colors.white),
//                             ),
//                           ),
//                   ),
//                 ],
//               ),
//             ),
//             Container(
//               height: 50,
//               decoration: const BoxDecoration(
//                 color: Colors.black,
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Expanded(
//                     child: InkWell(
//                       onTap: () {
//                         // Navigate to maintenance tab
//                         Navigator.pushNamed(
//                             context, '/maintenance'); // Update with your route
//                       },
//                       child: Container(
//                         color: const Color(0xFF4CAF50),
//                         alignment: Alignment.center,
//                         child: Text(
//                           'MAINTENANCE\nCOMPLETE',
//                           textAlign: TextAlign.center,
//                           style: GoogleFonts.montserrat(
//                             color: Colors.white,
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: InkWell(
//                       onTap: () {
//                         // Navigate to admin tab
//                         Navigator.pushNamed(
//                             context, '/admin'); // Update with your route
//                       },
//                       child: Container(
//                         color: Colors.black,
//                         alignment: Alignment.center,
//                         child: Text(
//                           'ADMIN',
//                           style: GoogleFonts.montserrat(
//                             color: Colors.white,
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: InkWell(
//                       onTap: () {
//                         // Navigate to truck condition tab
//                         Navigator.pushNamed(context,
//                             '/truck-condition'); // Update with your route
//                       },
//                       child: Container(
//                         color: Colors.black,
//                         alignment: Alignment.center,
//                         child: Text(
//                           'TRUCK CONDITION',
//                           style: GoogleFonts.montserrat(
//                             color: Colors.white,
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Container(
//               height: 50,
//               decoration: const BoxDecoration(
//                 color: Colors.black,
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Expanded(
//                     child: InkWell(
//                       onTap: () {
//                         Navigator.pushNamed(context, '/external-cab');
//                       },
//                       child: Container(
//                         color: const Color(0xFF4CAF50),
//                         alignment: Alignment.center,
//                         child: Text(
//                           'External Cab',
//                           textAlign: TextAlign.center,
//                           style: GoogleFonts.montserrat(
//                             color: Colors.white,
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: InkWell(
//                       onTap: () {
//                         Navigator.pushNamed(context, '/internal-cab');
//                       },
//                       child: Container(
//                         color: Colors.black,
//                         alignment: Alignment.center,
//                         child: Text(
//                           'Internal Cab',
//                           textAlign: TextAlign.center,
//                           style: GoogleFonts.montserrat(
//                             color: Colors.white,
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: InkWell(
//                       onTap: () {
//                         Navigator.pushNamed(context, '/drive-train');
//                       },
//                       child: Container(
//                         color: Colors.black,
//                         alignment: Alignment.center,
//                         child: Text(
//                           'Drive Train',
//                           textAlign: TextAlign.center,
//                           style: GoogleFonts.montserrat(
//                             color: Colors.white,
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: InkWell(
//                       onTap: () {
//                         Navigator.pushNamed(context, '/chassis');
//                       },
//                       child: Container(
//                         color: Colors.black,
//                         alignment: Alignment.center,
//                         child: Text(
//                           'Chassis',
//                           textAlign: TextAlign.center,
//                           style: GoogleFonts.montserrat(
//                             color: Colors.white,
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: InkWell(
//                       onTap: () {
//                         Navigator.pushNamed(context, '/tyres');
//                       },
//                       child: Container(
//                         color: Colors.black,
//                         alignment: Alignment.center,
//                         child: Text(
//                           'Tyres',
//                           textAlign: TextAlign.center,
//                           style: GoogleFonts.montserrat(
//                             color: Colors.white,
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             Expanded(
//               child: SingleChildScrollView(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Overall Tyres Condition
//                     _buildConditionSection(
//                       'TYRES',
//                       overallCondition,
//                       (value) => setState(() => overallCondition = value),
//                     ),

//                     // Individual Tyre Positions
//                     for (int i = 1; i <= 6; i++)
//                       _buildTyrePositionSection(
//                         'TYRE POS $i',
//                         i,
//                       ),

//                     // Additional Info
//                     _buildAdditionalInfo(),

//                     // Cancel Button
//                     Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: TextButton(
//                         onPressed: () {},
//                         child: const Text(
//                           'CANCEL',
//                           style: TextStyle(color: Colors.white),
//                         ),
//                       ),
//                     ),

//                     // Continue Button
//                     Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: ElevatedButton(
//                         onPressed: _saveForm,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.brown,
//                           minimumSize: const Size(double.infinity, 48),
//                         ),
//                         child: const Text('CONTINUE'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             // Bottom navigation
//             _buildBottomNavigation(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNavButton(String text, Color color, VoidCallback onPressed) {
//     return Expanded(
//       child: Padding(
//         padding: const EdgeInsets.all(4),
//         child: ElevatedButton(
//           onPressed: onPressed,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: color,
//             padding: const EdgeInsets.symmetric(vertical: 12),
//           ),
//           child: Text(text),
//         ),
//       ),
//     );
//   }

//   Widget _buildConditionSection(
//     String title,
//     String? selectedCondition,
//     Function(String?) onChanged,
//   ) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       color: Colors.transparent,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               _buildRadioOption('POOR', selectedCondition, onChanged),
//               _buildRadioOption('GOOD', selectedCondition, onChanged),
//               _buildRadioOption('EXCELLENT', selectedCondition, onChanged),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTyrePositionSection(String title, int position) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       color: Colors.transparent,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(color: Colors.white, fontSize: 18),
//           ),
//           const SizedBox(height: 16),
//           _buildImageUploadBox(),
//           const SizedBox(height: 16),
//           _buildConditionSection(
//             'CONDITION OF THE CHASSIS',
//             tyreConditions[position],
//             (value) => setState(() => tyreConditions[position] = value!),
//           ),
//           const SizedBox(height: 16),
//           // Add heading for Tyre Type
//           const Text(
//             'TYRE TYPE',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               _buildRadioOption(
//                 'VIRGIN',
//                 rimTypes[position],
//                 (value) => setState(() => rimTypes[position] = value!),
//               ),
//               _buildRadioOption(
//                 'RECAP',
//                 rimTypes[position],
//                 (value) => setState(() => rimTypes[position] = value!),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           // Add heading for Rim Type
//           const Text(
//             'RIM TYPE',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               _buildRadioOption(
//                 'ALUMINIUM',
//                 rimTypes[position],
//                 (value) => setState(() => rimTypes[position] = value!),
//               ),
//               _buildRadioOption(
//                 'STEEL',
//                 rimTypes[position],
//                 (value) => setState(() => rimTypes[position] = value!),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRadioOption(
//     String text,
//     String? groupValue,
//     Function(String?) onChanged,
//   ) {
//     return Expanded(
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 4),
//         child: ElevatedButton(
//           onPressed: () => onChanged(text),
//           style: ElevatedButton.styleFrom(
//             backgroundColor:
//                 groupValue == text ? Colors.deepOrange : Colors.grey[800],
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(4),
//             ),
//             padding: const EdgeInsets.symmetric(vertical: 12),
//           ),
//           child: Text(
//             text,
//             style: TextStyle(
//               color: groupValue == text ? Colors.white : Colors.grey[400],
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildImageUploadBox() {
//     return Container(
//       height: 120,
//       decoration: BoxDecoration(
//         color: Colors.blue[800],
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: const Center(
//         child: Icon(Icons.add, color: Colors.white, size: 40),
//       ),
//     );
//   }

//   Widget _buildAdditionalInfo() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'ADDITIONAL INFO',
//             style: GoogleFonts.montserrat(
//               color: Colors.white,
//               fontSize: 18,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               _buildRadioOption(
//                 'YES',
//                 hasDamages == true ? 'YES' : 'NO',
//                 (value) => setState(() => hasDamages = value == 'YES'),
//               ),
//               _buildRadioOption(
//                 'NO',
//                 hasDamages == true ? 'YES' : 'NO',
//                 (value) => setState(() => hasDamages = value == 'YES'),
//               ),
//             ],
//           ),
//           if (hasDamages == true) ...[
//             const SizedBox(height: 16),
//             CustomTextField(
//               controller: _damageController,
//               hintText: 'DESCRIBE DAMAGE',
//             ),
//             const SizedBox(height: 16),
//             InkWell(
//               onTap: () {
//                 // Your upload logic here
//               },
//               borderRadius: BorderRadius.circular(10.0),
//               child: Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(16.0),
//                 margin: const EdgeInsets.symmetric(horizontal: 16.0),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF0E4CAF).withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(10.0),
//                   border: Border.all(
//                     color: const Color(0xFF0E4CAF),
//                     width: 2.0,
//                   ),
//                 ),
//                 child: Column(
//                   children: const [
//                     Icon(
//                       Icons.drive_folder_upload_outlined,
//                       color: Colors.white,
//                       size: 50.0,
//                     ),
//                     SizedBox(height: 10),
//                     Text(
//                       'CLEAR PICTURE OF DAMAGE',
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.white70,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextButton.icon(
//               onPressed: () {
//                 // Handle add additional
//               },
//               icon: const Icon(Icons.add, color: Colors.white),
//               label: Text(
//                 'ADD ADDITIONAL DAMAGE',
//                 style: GoogleFonts.montserrat(color: Colors.white),
//                 textAlign: TextAlign.center,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildBottomNavigation() {
//     return Container(
//       color: Colors.blue,
//       padding: const EdgeInsets.symmetric(vertical: 16),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: const [
//           Icon(Icons.home, color: Colors.white),
//           Icon(Icons.local_shipping, color: Colors.white),
//           Icon(Icons.favorite, color: Colors.white),
//           Icon(Icons.person, color: Colors.white),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _damageController.dispose();
//     super.dispose();
//   }
// }
