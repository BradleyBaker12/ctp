import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import '../providers/complaints_provider.dart';
import '../providers/user_provider.dart';
import '../components/custom_button.dart'; // Import your CustomButton component
import '../components/gradient_background.dart'; // Import your GradientBackground component

class ComplaintDetailPage extends StatelessWidget {
  final Complaint complaint; // Using the Complaint model

  const ComplaintDetailPage({super.key, required this.complaint});

  @override
  Widget build(BuildContext context) {
    final complaintsProvider = Provider.of<ComplaintsProvider>(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    String complaintId = complaint.offerId;
    String userId = complaint.userId;
    String message = complaint.description;
    String status = complaint.complaintStatus;
    Timestamp timestamp = complaint.timestamp;

    // Convert Timestamp to DateTime and format it
    DateTime dateTime = timestamp.toDate();
    String formattedDate = DateFormat('MMMM d, yyyy').format(dateTime);

    return Scaffold(
      extendBodyBehindAppBar: true, // To extend the gradient behind the appbar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Complaint Details',
          style: GoogleFonts.montserrat(color: Colors.white),
        ),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height, // Full height of the device
        child: GradientBackground(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<String>(
                future: userProvider.getUserNameById(userId),
                builder: (context, userSnapshot) {
                  String userName = 'Loading...';

                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    userName = 'Loading...';
                  } else if (userSnapshot.hasError) {
                    userName = 'Unknown User';
                  } else {
                    userName = userSnapshot.data ?? 'Unknown User';
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          height: 100), // Spacer to push content below appbar
                      // User Info
                      Text(
                        'Complaint from $userName',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Issue:',
                        style: GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        complaint.selectedIssue,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Message:',
                        style: GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        message,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Status: $status',
                        style: GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Time: $formattedDate',
                        style: GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Action Buttons
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (status != 'resolved')
                              Expanded(
                                child: CustomButton(
                                  text: 'Resolve',
                                  borderColor: Colors.green,
                                  onPressed: () {
                                    complaintsProvider.updateComplaintStatus(
                                        complaintId, 'resolved');
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            if (status != 'dismissed') SizedBox(width: 20),
                            if (status != 'dismissed')
                              Expanded(
                                child: CustomButton(
                                  text: 'Dismiss',
                                  borderColor: Colors.red,
                                  onPressed: () {
                                    complaintsProvider.updateComplaintStatus(
                                        complaintId, 'dismissed');
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 40), // Extra space at the bottom
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
