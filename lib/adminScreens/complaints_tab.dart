import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/complaints_provider.dart';
import 'complaint_detail_page.dart'; // Import the complaint details screen

class ComplaintsTab extends StatefulWidget {
  const ComplaintsTab({super.key});

  @override
  _ComplaintsTabState createState() => _ComplaintsTabState();
}

class _ComplaintsTabState extends State<ComplaintsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Fetch complaints when the widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ComplaintsProvider>(context, listen: false)
          .fetchAllComplaints();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper method to filter complaints based on search query
  bool _matchesSearch(Complaint complaint, String userNameLower) {
    if (_searchQuery.isEmpty) return true;

    String message = complaint.description.toLowerCase();
    String status = complaint.complaintStatus.toLowerCase();

    return userNameLower.contains(_searchQuery.toLowerCase()) ||
        message.contains(_searchQuery.toLowerCase()) ||
        status.contains(_searchQuery.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    // Access the UserProvider and ComplaintsProvider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final complaintsProvider = Provider.of<ComplaintsProvider>(context);

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.montserrat(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Search Complaints',
              labelStyle: GoogleFonts.montserrat(color: Colors.white),
              prefixIcon: Icon(Icons.search, color: Colors.white),
              filled: true,
              fillColor: Colors.transparent,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Color(0xFFFF4E00)),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        // Expanded ListView
        Expanded(
          child: complaintsProvider.complaints.isEmpty
              ? Center(
                  child: Text(
                    'No complaints found.',
                    style: GoogleFonts.montserrat(color: Colors.white),
                  ),
                )
              : ListView.builder(
                  itemCount: complaintsProvider.complaints.length,
                  itemBuilder: (context, index) {
                    var complaint = complaintsProvider.complaints[index];
                    String complaintId = complaint.offerId;
                    String userId = complaint.userId;
                    String message = complaint.description;
                    String status = complaint.complaintStatus;

                    return FutureBuilder<String>(
                      future: userProvider.getUserNameById(userId),
                      builder: (context, userSnapshot) {
                        String userName = 'Loading...';

                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          userName = 'Loading...';
                        } else if (userSnapshot.hasError) {
                          userName = 'Unknown User';
                        } else {
                          userName = userSnapshot.data ?? 'Unknown User';
                        }

                        // Apply filtering
                        if (!_matchesSearch(
                            complaint, userName.toLowerCase())) {
                          return SizedBox.shrink();
                        }

                        return Card(
                          color: Colors.grey[900],
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          child: ListTile(
                            leading: const Icon(
                              Icons.warning,
                              color: Colors.redAccent,
                            ),
                            title: Text(
                              'Complaint from $userName',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            subtitle: Text(
                              '$message\nStatus: $status',
                              style:
                                  GoogleFonts.montserrat(color: Colors.white70),
                            ),
                            isThreeLine: true,
                            onTap: () {
                              // Navigate to the complaint details screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ComplaintDetailPage(
                                    complaint:
                                        complaint, // Pass the complaint data
                                  ),
                                ),
                              );
                            },
                            trailing: PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: Colors.white),
                              onSelected: (value) async {
                                bool? confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      'Confirm $value',
                                      style: GoogleFonts.montserrat(),
                                    ),
                                    content: Text(
                                      'Are you sure you want to $value this complaint?',
                                      style: GoogleFonts.montserrat(),
                                    ),
                                    backgroundColor: Colors.grey[800],
                                    actions: [
                                      TextButton(
                                        child: Text(
                                          'Cancel',
                                          style: GoogleFonts.montserrat(
                                              color: Colors.white),
                                        ),
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                      ),
                                      TextButton(
                                        child: Text(
                                          'Confirm',
                                          style: GoogleFonts.montserrat(
                                              color: Colors.red),
                                        ),
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  switch (value) {
                                    case 'Resolve':
                                      await complaintsProvider
                                          .updateComplaintStatus(
                                              complaintId, 'resolved');
                                      break;
                                    case 'Dismiss':
                                      await complaintsProvider
                                          .updateComplaintStatus(
                                              complaintId, 'dismissed');
                                      break;
                                  }

                                  // Show feedback
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.black87,
                                      content: Text(
                                        'Complaint $value successfully.',
                                        style: GoogleFonts.montserrat(),
                                      ),
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (BuildContext context) {
                                return <PopupMenuEntry<String>>[
                                  if (status.toLowerCase() != 'resolved')
                                    PopupMenuItem<String>(
                                      value: 'Resolve',
                                      child: Text(
                                        'Resolve',
                                        style: GoogleFonts.montserrat(),
                                      ),
                                    ),
                                  if (status.toLowerCase() != 'dismissed')
                                    PopupMenuItem<String>(
                                      value: 'Dismiss',
                                      child: Text(
                                        'Dismiss',
                                        style: GoogleFonts.montserrat(
                                            color: Colors.red),
                                      ),
                                    ),
                                ];
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
