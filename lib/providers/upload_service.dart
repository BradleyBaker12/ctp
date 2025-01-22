// // services/upload_service.dart
// import 'package:firebase_storage/firebase_storage.dart';
// import 'dart:io';

// class UploadService {
//   final FirebaseStorage _storage = FirebaseStorage.instance;

//   /// Uploads a file to the specified [folderName] in Firebase Storage.
//   /// Returns the download URL of the uploaded file.
//   Future<String> uploadFile(File file, String folderName) async {
//     try {
//       String fileName =
//           "${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}";
//       Reference ref = _storage.ref().child('$folderName/$fileName');
//       UploadTask uploadTask = ref.putFile(file);
//       TaskSnapshot snapshot = await uploadTask.whenComplete(() => {});
//       String downloadUrl = await snapshot.ref.getDownloadURL();
//       return downloadUrl;
//     } catch (e) {
//       throw Exception('Error uploading file: $e');
//     }
//   }

//   /// Optionally, implement methods for uploading multiple files.
// }
