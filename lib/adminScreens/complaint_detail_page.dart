import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/models/user_details.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:provider/provider.dart';

import '../components/custom_button.dart'; // Import your CustomButton component
import '../components/gradient_background.dart'; // Import your GradientBackground component
import '../providers/complaints_provider.dart';
import '../providers/user_provider.dart';

class ComplaintDetailPage extends StatelessWidget {
  final Complaint complaint; // Using the Complaint model

  const ComplaintDetailPage({
    super.key,
    required this.complaint,
  });

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
              child: FutureBuilder<UserDetails>(
                future: userProvider.getUserDetailsById(userId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (userSnapshot.hasError) {
                    return Text(
                      'Error fetching user details',
                      style: GoogleFonts.montserrat(color: Colors.red),
                    );
                  } else if (!userSnapshot.hasData) {
                    return Text(
                      'User details not available',
                      style: GoogleFonts.montserrat(color: Colors.red),
                    );
                  }

                  UserDetails userDetails = userSnapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                          height: 100), // Spacer to push content below appbar
                      // User Info
                      Text(
                        'Complaint from ${userDetails.name}',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(height: 10),
                      // Issue
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
                      // Message
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
                      // Status
                      Text(
                        'Status: $status',
                        style: GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Time
                      Text(
                        'Time: $formattedDate',
                        style: GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Additional User Details
                      Text(
                        'Name: ${userDetails.name}',
                        style: GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 20),
                      // Additional User Details
                      Text(
                        'Email: ${userDetails.email}',
                        style: GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Phone: ${userDetails.phone}',
                        style: GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 10),
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
                                  onPressed: () async {
                                    try {
                                      String previousStep =
                                          complaint.previousStep;

                                      // 1. Update complaint status
                                      await complaintsProvider
                                          .updateComplaintStatus(
                                              complaint.complaintId,
                                              'resolved');

                                      // 2. Update offer status
                                      await FirebaseFirestore.instance
                                          .collection('offers')
                                          .doc(complaint.offerId)
                                          .update({
                                        'offerStatus': previousStep,
                                      });

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Complaint resolved successfully'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );

                                      Navigator.pop(context);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Error resolving complaint: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            if (status != 'dismissed') SizedBox(width: 20),
                            if (status != 'dismissed')
                              Expanded(
                                child: CustomButton(
                                  text: 'Dismiss',
                                  borderColor: Colors.red,
                                  onPressed: () async {
                                    try {
                                      String previousStep =
                                          complaint.previousStep;

                                      // Update complaint status
                                      await complaintsProvider
                                          .updateComplaintStatus(
                                              complaint.complaintId,
                                              'dismissed');

                                      // Update offer status back to previous step
                                      await FirebaseFirestore.instance
                                          .collection('offers')
                                          .doc(complaint.offerId)
                                          .update({
                                        'offerStatus': previousStep,
                                      });

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Complaint dismissed successfully'),
                                          backgroundColor: Colors.grey,
                                        ),
                                      );

                                      Navigator.pop(context);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Error dismissing complaint: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
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
