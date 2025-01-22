// import 'package:flutter/material.dart';

// class LoadingOverlay extends StatelessWidget {
//   final bool isLoading;
//   final Widget child;
//   final String? message;

//   const LoadingOverlay({
//     super.key,
//     required this.isLoading,
//     required this.child,
//     this.message,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         child,
//         if (isLoading)
//           Container(
//             color: Colors.black54,
//             child: Center(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const CircularProgressIndicator(),
//                   if (message != null)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 16),
//                       child: Text(
//                         message!,
//                         style: const TextStyle(color: Colors.white),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }
