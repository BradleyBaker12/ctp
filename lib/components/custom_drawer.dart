// // custom_drawer.dart
// import 'dart:io';

// import 'package:flutter/material.dart';

// class CustomDrawer extends StatelessWidget {
//   final String docId;
//   final File? imageFile;

//   const CustomDrawer({super.key, required this.docId, this.imageFile});

//   @override
//   Widget build(BuildContext context) {
//     return Drawer(
//       child: ListView(
//         padding: EdgeInsets.zero,
//         children: [
//           const DrawerHeader(
//             decoration: BoxDecoration(
//               color: Colors.blue,
//             ),
//             child: Text('Navigation Menu'),
//           ),
//           _buildDrawerItem(
//             context,
//             title: 'Form 1: Truck Info',
//             route: '/firstForm',
//           ),
//           _buildDrawerItem(
//             context,
//             title: 'Form 2: Vehicle Details',
//             route: '/secondForm',
//           ),
//           _buildDrawerItem(
//             context,
//             title: 'Form 3: Bank Settlement',
//             route: '/thirdForm',
//           ),
//           _buildDrawerItem(
//             context,
//             title: 'Form 4: RC1/NATIS Upload',
//             route: '/fourthForm',
//           ),
//           _buildDrawerItem(
//             context,
//             title: 'Form 5: Damages and Faults',
//             route: '/fifthForm',
//           ),
//           _buildDrawerItem(
//             context,
//             title: 'Form 6: Tyres Details',
//             route: '/sixthForm',
//           ),
//           _buildDrawerItem(
//             context,
//             title: 'Form 7: Exterior & Interior Photos',
//             route: '/seventhForm',
//           ),
//         ],
//       ),
//     );
//   }

//   // Drawer Item Builder
//   Widget _buildDrawerItem(BuildContext context,
//       {required String title, required String route}) {
//     return ListTile(
//       title: Text(title),
//       onTap: () {
//         Navigator.pop(context); // Close the drawer
//         Navigator.pushNamed(context, route, arguments: {
//           'docId': docId,
//           'image': imageFile,
//         });
//       },
//     );
//   }
// }
