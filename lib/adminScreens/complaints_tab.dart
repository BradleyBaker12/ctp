import 'package:ctp/components/gradient_background.dart';
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
  // **Search Variables**
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // **Sorting Variables**
  String _sortField = 'timestamp'; // Default sort field
  bool _sortAscending = false; // Default sort direction

  // **Filter Variables**
  final List<String> _selectedFilters = [];
  final List<String> _filterOptions = [
    'All Complaints',
    'Open',
    'Resolved',
    'Dismissed',
  ];

  @override
  void initState() {
    super.initState();
    // Fetch complaints when the widget is first built.
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

  /// **Helper Method: Filter and Search Matching**
  /// This method checks if a given complaint matches the search query and filter options.
  bool _matchesFiltersAndSearch(Complaint complaint) {
    // Convert relevant fields to lowercase for case-insensitive searching.
    String description = complaint.description.toLowerCase();
    String status = complaint.complaintStatus.toLowerCase();

    // 1) Does it match the search query?
    bool matchesSearch = _searchQuery.isEmpty ||
        description.contains(_searchQuery.toLowerCase()) ||
        status.contains(_searchQuery.toLowerCase());

    // 2) Does it match the selected filters?
    // If no filters are selected OR "All Complaints" is selected, show everything.
    if (_selectedFilters.isEmpty ||
        _selectedFilters.contains('All Complaints')) {
      return matchesSearch;
    } else {
      bool matchesFilter = false;

      // "Open" = not resolved, not dismissed.
      if (_selectedFilters.contains('Open') &&
          (status != 'resolved' && status != 'dismissed')) {
        matchesFilter = true;
      }

      // "Resolved" = exactly resolved.
      if (_selectedFilters.contains('Resolved') && status == 'resolved') {
        matchesFilter = true;
      }

      // "Dismissed" = exactly dismissed.
      if (_selectedFilters.contains('Dismissed') && status == 'dismissed') {
        matchesFilter = true;
      }

      return matchesSearch && matchesFilter;
    }
  }

  /// **Helper Method: Capitalize First Letter**
  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return "${s[0].toUpperCase()}${s.substring(1)}";
  }

  @override
  Widget build(BuildContext context) {
    // Access the UserProvider and ComplaintsProvider.
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final complaintsProvider = Provider.of<ComplaintsProvider>(context);

    // **Apply Sorting**
    List<Complaint> sortedComplaints = List.from(complaintsProvider.complaints);
    sortedComplaints.sort((a, b) {
      int comparison = 0;
      switch (_sortField) {
        case 'timestamp':
          comparison = a.timestamp.compareTo(b.timestamp);
          break;
        case 'status':
          comparison = a.complaintStatus.compareTo(b.complaintStatus);
          break;
        // If needed, you can add additional sort fields (e.g., userName).
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });

    // **Apply Additional Filtering for Sales Representatives**
    // If the current user is a sales rep, only display complaints related to
    // their vehicles or accounts. In this example, we assume that each complaint
    // has an 'assignedSalesRepId' field that can be matched with the current user ID.
    final String currentUserRole = userProvider.getUserRole;
    final String? currentUserId = userProvider.userId;

    List<Complaint> filteredComplaints = sortedComplaints.where((complaint) {
      // If the user is a sales representative, filter complaints based on the related sales rep.
      if (currentUserRole.toLowerCase() == 'sales representative') {
        // NOTE: Adjust 'assignedSalesRepId' if your complaint model uses a different field.
        if (complaint.assignedSalesRepId != currentUserId) {
          return false;
        }
      }
      return _matchesFiltersAndSearch(complaint);
    }).toList();

    return Scaffold(
      body: GradientBackground(
        // Ensure you have a GradientBackground widget.
        child: Column(
          children: [
            // **Search, Sort, and Filter Row**
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  // **Search Bar**
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.montserrat(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search complaints...',
                          hintStyle:
                              GoogleFonts.montserrat(color: Colors.white54),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white54),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // **Sort Button**
                  IconButton(
                    icon: const Icon(Icons.sort, color: Colors.white),
                    onPressed: _showSortMenu,
                    tooltip: 'Sort by: ${_sortField.replaceAll('_', ' ')}',
                  ),
                  // **Sort Direction Button**
                  IconButton(
                    icon: Icon(
                      _sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _sortAscending = !_sortAscending;
                      });
                    },
                    tooltip:
                        _sortAscending ? 'Sort Ascending' : 'Sort Descending',
                  ),
                  // **Filter Button**
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onPressed: _showFilterDialog,
                    tooltip: 'Filter Complaints',
                  ),
                ],
              ),
            ),
            // **Expanded ListView**
            Expanded(
              child: filteredComplaints.isEmpty
                  ? Center(
                      child: Text(
                        'No complaints found.',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredComplaints.length,
                      itemBuilder: (context, index) {
                        var complaint = filteredComplaints[index];
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

                            // **Apply Additional Search Filtering if Necessary**
                            if (!_matchesFiltersAndSearch(complaint)) {
                              return const SizedBox.shrink();
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
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white70),
                                ),
                                isThreeLine: true,
                                onTap: () {
                                  // Navigate to the complaint details screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ComplaintDetailPage(
                                        complaint:
                                            complaint, // Pass the complaint data.
                                      ),
                                    ),
                                  );
                                },
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert,
                                      color: Colors.white),
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
                                                Navigator.of(context)
                                                    .pop(false),
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
                                          try {
                                            complaintsProvider
                                                .updateComplaintStatus(
                                                    complaintId, 'resolved')
                                                .then((success) {
                                              if (!success) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Failed to resolve complaint'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    backgroundColor:
                                                        Colors.black87,
                                                    content: Text(
                                                      'Complaint resolved successfully.',
                                                      style: GoogleFonts
                                                          .montserrat(),
                                                    ),
                                                  ),
                                                );
                                              }
                                            });
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text('Error: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                          break;
                                        case 'Dismiss':
                                          try {
                                            complaintsProvider
                                                .updateComplaintStatus(
                                                    complaintId, 'dismissed')
                                                .then((success) {
                                              if (!success) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Failed to dismiss complaint'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    backgroundColor:
                                                        Colors.black87,
                                                    content: Text(
                                                      'Complaint dismissed successfully.',
                                                      style: GoogleFonts
                                                          .montserrat(),
                                                    ),
                                                  ),
                                                );
                                              }
                                            });
                                          } catch (e) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text('Error: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                          break;
                                      }
                                      // **Show Feedback**
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
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
        ),
      ),
    );
  }

  /// **Method: Show Sort Menu**
  Future<void> _showSortMenu() async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    await showMenu(
      context: context,
      position: position,
      color: Colors.grey[900],
      items: [
        PopupMenuItem(
          value: 'timestamp',
          child:
              Text('Date', style: GoogleFonts.montserrat(color: Colors.white)),
        ),
        PopupMenuItem(
          value: 'status',
          child: Text('Status',
              style: GoogleFonts.montserrat(color: Colors.white)),
        ),
        PopupMenuItem(
          value: 'userName',
          child: Text('User Name',
              style: GoogleFonts.montserrat(color: Colors.white)),
        ),
      ],
    ).then((value) {
      if (value != null) {
        setState(() {
          _sortField = value;
        });
      }
    });
  }

  /// **Method: Show Filter Dialog**
  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Filter Complaints',
              style: GoogleFonts.montserrat(color: Colors.white)),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _filterOptions.map((filter) {
                    return CheckboxListTile(
                      title: Text(filter,
                          style: GoogleFonts.montserrat(color: Colors.white)),
                      value: _selectedFilters.contains(filter),
                      checkColor: Colors.black,
                      activeColor: const Color(0xFFFF4E00),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedFilters.add(filter);
                          } else {
                            _selectedFilters.remove(filter);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              child: Text('Clear All',
                  style: GoogleFonts.montserrat(color: Colors.white)),
              onPressed: () {
                setState(() {
                  _selectedFilters.clear();
                });
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('Apply',
                  style:
                      GoogleFonts.montserrat(color: const Color(0xFFFF4E00))),
              onPressed: () {
                Navigator.pop(context);
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }
}

/// **Extension Method: Capitalize First Letter (Optional)**
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
