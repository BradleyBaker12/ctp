import 'package:ctp/components/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'thank_you_page.dart'; // Import the ThankYouPage
import 'package:file_picker/file_picker.dart'; // For file picking
import 'package:firebase_storage/firebase_storage.dart'; // For file storage
import 'dart:io'; // For File operations
import 'package:ctp/utils/navigation.dart';

class ReportVehicleIssuePage extends StatefulWidget {
  final String vehicleId; // Use vehicleId instead of offerId

  const ReportVehicleIssuePage({super.key, required this.vehicleId});

  @override
  _ReportVehicleIssuePageState createState() => _ReportVehicleIssuePageState();
}

class _ReportVehicleIssuePageState extends State<ReportVehicleIssuePage> {
  // Adjust the default issue and radio options as needed for vehicles
  String _selectedIssue = 'FALSE INFORMATION ABOUT VEHICLE';
  final TextEditingController _controller = TextEditingController();
  File? _mediaFile; // For storing the selected image or video file

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  Image.asset('lib/assets/CTPLogo.png', height: 100),
                  const SizedBox(height: 20),
                  const Text(
                    'REPORT A VEHICLE ISSUE',
                    style: TextStyle(
                      color: Color(0xFFFF4E00),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We value our customers experience.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'If your experience with the vehicle was not up to standard, please report any issues to us so that we may take the necessary steps for future experiences.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  // Radio options adjusted for vehicle issues
                  _buildCustomRadioButton('FALSE INFORMATION ABOUT VEHICLE'),
                  _buildCustomRadioButton('VEHICLE DID NOT SHOW UP'),
                  _buildCustomRadioButton('INCORRECT VEHICLE INFORMATION'),
                  _buildCustomRadioButton('VEHICLE CONDITION WAS POOR'),
                  _buildCustomRadioButton('FELT UNSAFE'),
                  _buildCustomRadioButton('OTHER'),
                  const SizedBox(height: 20),
                  if (_selectedIssue == 'OTHER') ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'OTHER REASONING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controller,
                      cursorColor: Color(0xFFFF4E00),
                      decoration: const InputDecoration(
                        hintText: 'Please describe issue',
                        hintStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFF4E00)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 15.0, horizontal: 10.0),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Media upload section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'UPLOAD IMAGE OR VIDEO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _pickMedia,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2F7FFF).withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Choose File',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (_mediaFile != null) ...[
                        const SizedBox(height: 10),
                        if (_isImageFile(_mediaFile!.path))
                          Image.file(
                            _mediaFile!,
                            height: 200,
                          )
                        else
                          Text(
                            'Selected File: ${_mediaFile!.path.split('/').last}',
                            style: const TextStyle(color: Colors.white),
                          ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      // Handle form submission
                      await _submitComplaint();
                      // Navigate to the Thank You Page
                      await MyNavigator.pushReplacement(
                        context,
                        const ThankYouPage(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF4E00),
                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'SUBMIT',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickMedia() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov', 'avi'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _mediaFile = File(result.files.single.path!);
      });
    }
  }

  bool _isImageFile(String path) {
    final extension = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png'].contains(extension);
  }

  Future<void> _submitComplaint() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Retrieve the current status of the vehicle
        DocumentSnapshot vehicleSnapshot = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.vehicleId)
            .get();
        String? currentStatus = vehicleSnapshot['vehicleStatus'];

        String? mediaUrl;

        if (_mediaFile != null) {
          // Upload the file to Firebase Storage
          String fileName = _mediaFile!.path.split('/').last;
          Reference ref = FirebaseStorage.instance
              .ref()
              .child('complaint_media')
              .child('${widget.vehicleId}/$fileName');
          UploadTask uploadTask = ref.putFile(_mediaFile!);

          TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
          mediaUrl = await taskSnapshot.ref.getDownloadURL();
        }

        // Save the complaint with the previous status and media URL
        await FirebaseFirestore.instance.collection('complaints').add({
          'userId': user.uid,
          'vehicleId': widget.vehicleId, // Save the vehicleId
          'selectedIssue': _selectedIssue,
          'description': _selectedIssue == 'OTHER' ? _controller.text : '',
          'timestamp': FieldValue.serverTimestamp(),
          'complaintStatus': 'Issue Submitted', // Complaint status field
          'previousStatus': currentStatus, // Save the current vehicle status
          if (mediaUrl != null)
            'mediaUrl': mediaUrl, // Include mediaUrl if exists
        });

        // Update the vehicle status to "Issue reported"
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.vehicleId)
            .update({
          'vehicleStatus': 'Issue reported',
        });

        print('Complaint submitted and vehicle status updated successfully.');
      } catch (e) {
        print('Error submitting complaint or updating vehicle status: $e');
      }
    }
  }

  Widget _buildCustomRadioButton(String title) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      leading: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIssue = title;
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            if (_selectedIssue == title)
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(0xFFFF4E00),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
