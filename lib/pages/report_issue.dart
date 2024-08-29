import 'package:ctp/components/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'thank_you_page.dart'; // Import the ThankYouPage

class ReportIssuePage extends StatefulWidget {
  final String offerId; // Add offerId as a required parameter

  const ReportIssuePage({super.key, required this.offerId});

  @override
  _ReportIssuePageState createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  String _selectedIssue = 'FALSE INFORMATION FROM TRANSPORTER';
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Container(
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
                  ElevatedButton(
                    onPressed: () async {
                      // Handle form submission
                      await _submitComplaint();
                      // Navigate to Thank You Page
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ThankYouPage(),
                        ),
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

        // Save the complaint with the previous step information
        await FirebaseFirestore.instance.collection('complaints').add({
          'userId': user.uid,
          'offerId': widget.offerId, // Save the offerId
          'selectedIssue': _selectedIssue,
          'description': _selectedIssue == 'OTHER' ? _controller.text : '',
          'timestamp': FieldValue.serverTimestamp(),
          'complaintStatus': 'Issue Submitted', // Add complaintStatus
          'previousStep': currentStep, // Save the current step as previousStep
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
