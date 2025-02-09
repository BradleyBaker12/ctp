import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/utils/navigation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'thank_you_page.dart'; // Import the ThankYouPage
import 'package:file_picker/file_picker.dart'; // Add this import
import 'package:firebase_storage/firebase_storage.dart'; // Add this import
import 'dart:io'; // Add this import

class ReportIssuePage extends StatefulWidget {
  final String offerId; // Add offerId as a required parameter

  const ReportIssuePage({super.key, required this.offerId});

  @override
  _ReportIssuePageState createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  String _selectedIssue = 'FALSE INFORMATION FROM TRANSPORTER';
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
                  SizedBox(
                    height: 50,
                  ),
                  Image.asset('lib/assets/CTPLogo.png', height: 100),
                  const SizedBox(height: 20),
                  const Text(
                    'REPORT AN ISSUE',
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
                    'If your experience with a transporter was not up to standard, please report any issues to us so that we may take the necessary steps for future experiences.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _buildCustomRadioButton('FALSE INFORMATION FROM TRANSPORTER'),
                  _buildCustomRadioButton('TRIED TO BYPASS CTP PROTOCOLS'),
                  _buildCustomRadioButton('TRANSPORTER DID NOT ARRIVE'),
                  _buildCustomRadioButton('INCORRECT LOCATION INFORMATION'),
                  _buildCustomRadioButton('FELT UNSAFE'),
                  _buildCustomRadioButton('AGGRESSIVE TRANSPORTER'),
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
                  // Add media upload section
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
                              color: Color(0xFFFFFFFF),
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
                      // Navigate to Thank You Page
                      await MyNavigator.pushReplacement(
                          context, const ThankYouPage());
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
        // Retrieve the current step/status of the offer
        DocumentSnapshot offerSnapshot = await FirebaseFirestore.instance
            .collection('offers')
            .doc(widget.offerId)
            .get();
        String? currentStep = offerSnapshot['offerStatus'];

        String? mediaUrl;

        if (_mediaFile != null) {
          // Upload the file to Firebase Storage
          String fileName = _mediaFile!.path.split('/').last;
          Reference ref = FirebaseStorage.instance
              .ref()
              .child('complaint_media')
              .child('${widget.offerId}/$fileName');
          UploadTask uploadTask = ref.putFile(_mediaFile!);

          TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
          mediaUrl = await taskSnapshot.ref.getDownloadURL();
        }

        // Save the complaint with the previous step information and media URL
        await FirebaseFirestore.instance.collection('complaints').add({
          'userId': user.uid,
          'offerId': widget.offerId, // Save the offerId
          'selectedIssue': _selectedIssue,
          'description': _selectedIssue == 'OTHER' ? _controller.text : '',
          'timestamp': FieldValue.serverTimestamp(),
          'complaintStatus': 'Issue Submitted', // Add complaintStatus
          'previousStep': currentStep, // Save the current step as previousStep
          if (mediaUrl != null)
            'mediaUrl': mediaUrl, // Include mediaUrl if exists
        });

        // Update the offer status to "Issue reported"
        await FirebaseFirestore.instance
            .collection('offers')
            .doc(widget.offerId)
            .update({
          'offerStatus': 'Issue reported',
        });

        // Show a success message or perform additional actions if needed
        print('Complaint submitted and offer status updated successfully.');
      } catch (e) {
        // Handle any errors that occur during the process
        print('Error submitting complaint or updating offer status: $e');
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
