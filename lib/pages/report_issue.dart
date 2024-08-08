import 'package:ctp/components/gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'thank_you_page.dart'; // Import the ThankYouPage

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});

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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('lib/assets/CTPLogo.png', height: 100),
                const SizedBox(height: 20),
                const Text(
                  'REPORT AN ISSUE',
                  style: TextStyle(
                    color: Colors.orange,
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
                _buildRadioButton('FALSE INFORMATION FROM TRANSPORTER'),
                _buildRadioButton('TRIED TO BYPASS CTP PROTOCOLS'),
                _buildRadioButton('TRANSPORTER DID NOT ARRIVE'),
                _buildRadioButton('INCORRECT LOCATION INFORMATION'),
                _buildRadioButton('FELT UNSAFE'),
                _buildRadioButton('AGGRESSIVE TRANSPORTER'),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'OTHER:',
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
                  cursorColor: Colors.orange,
                  decoration: const InputDecoration(
                    hintText: 'Please describe issue',
                    hintStyle: TextStyle(color: Colors.grey),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    // Handle form submission
                    await _submitComplaint();
                    // Navigate to Thank You Page
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ThankYouPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
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
    );
  }

  Future<void> _submitComplaint() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('complaints').add({
        'userId': user.uid,
        'selectedIssue': _selectedIssue,
        'description': _controller.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Widget _buildRadioButton(String title) {
    return RadioListTile<String>(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      value: title,
      groupValue: _selectedIssue,
      onChanged: (value) {
        setState(() {
          _selectedIssue = value!;
        });
      },
      activeColor: Colors.orange,
    );
  }
}
