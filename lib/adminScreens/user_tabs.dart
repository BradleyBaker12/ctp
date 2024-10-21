// lib/pages/admin_users_tab.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart'; // Uncomment if needed
// Ensure this is used if needed
import 'user_detail_page.dart'; // Import the UserDetailPage

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  _UsersTabState createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Pagination variables
  final int _limit = 10; // Number of documents to fetch per page
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  final List<DocumentSnapshot> _users = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchUsers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Method to update user status (No longer needed here if handled in UserProvider)
  // Future<void> updateUserStatus(String userId, String newStatus) async {
  //   try {
  //     await usersCollection.doc(userId).update({'accountStatus': newStatus});
  //     print('User $userId status updated to $newStatus');
  //   } catch (e) {
  //     print('Error updating user status: $e');
  //   }
  // }

  // Helper method to filter users based on search query
  bool _matchesSearch(Map<String, dynamic> userData) {
    if (_searchQuery.isEmpty) return true;

    String firstName = userData['firstName']?.toString().toLowerCase() ?? '';
    String lastName = userData['lastName']?.toString().toLowerCase() ?? '';
    String email = userData['email']?.toString().toLowerCase() ?? '';
    String role = userData['userRole']?.toString().toLowerCase() ?? '';
    String status = userData['accountStatus']?.toString().toLowerCase() ?? '';

    return firstName.contains(_searchQuery.toLowerCase()) ||
        lastName.contains(_searchQuery.toLowerCase()) ||
        email.contains(_searchQuery.toLowerCase()) ||
        role.contains(_searchQuery.toLowerCase()) ||
        status.contains(_searchQuery.toLowerCase());
  }

  Future<void> _fetchUsers() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    Query query = usersCollection.orderBy('createdAt').limit(_limit);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    try {
      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        _users.addAll(querySnapshot.docs);
        if (querySnapshot.docs.length < _limit) {
          _hasMore = false;
        }
      } else {
        _hasMore = false;
      }
    } catch (e) {
      print('Error fetching users: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Apply filtering based on search query
    List<DocumentSnapshot> filteredUsers = _users.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return _matchesSearch(data);
    }).toList();

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.montserrat(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Search Users',
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
                _users.clear();
                _lastDocument = null;
                _hasMore = true;
              });
              _fetchUsers();
            },
          ),
        ),
        // Expanded ListView
        Expanded(
          child: filteredUsers.isEmpty
              ? _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Center(
                      child: Text(
                        'No users found.',
                        style: GoogleFonts.montserrat(color: Colors.white),
                      ),
                    )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: filteredUsers.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == filteredUsers.length) {
                      // Show a loading indicator at the bottom
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    var userData =
                        filteredUsers[index].data() as Map<String, dynamic>;
                    String userId = filteredUsers[index].id;
                    String firstName = userData['firstName'] ?? 'No Name';
                    String email = userData['email'] ?? 'No Email';
                    String role = userData['userRole'] ?? 'user';

                    // **Handling accountStatus which might be a bool or a String**
                    var accountStatus = userData['accountStatus'];
                    String status;

                    if (accountStatus is String) {
                      status = accountStatus;
                    } else if (accountStatus is bool) {
                      status = accountStatus
                          ? 'active'
                          : 'inactive'; // Adjust as needed
                    } else {
                      status = 'active'; // Default status
                    }

                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Text(
                            firstName.isNotEmpty
                                ? firstName[0].toUpperCase()
                                : 'U',
                            style: GoogleFonts.montserrat(color: Colors.white),
                          ),
                        ),
                        title: Text(firstName,
                            style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        subtitle: Text('$email\nRole: $role\nStatus: $status',
                            style:
                                GoogleFonts.montserrat(color: Colors.white70)),
                        isThreeLine: true,
                        trailing:
                            Icon(Icons.arrow_forward_ios, color: Colors.white),
                        onTap: () {
                          // Navigate to UserDetailPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserDetailPage(
                                userId: userId,
                              ),
                            ),
                          );
                        },
                        // Uncomment the following block if you want to include the PopupMenuButton
                        /*
                        trailing: PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: Colors.white),
                          onSelected: (value) async {
                            bool? confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Confirm $value',
                                    style: GoogleFonts.montserrat()),
                                content: Text(
                                    'Are you sure you want to $value this user?',
                                    style: GoogleFonts.montserrat()),
                                backgroundColor: Colors.grey[800],
                                actions: [
                                  TextButton(
                                    child: Text('Cancel',
                                        style: GoogleFonts.montserrat(
                                            color: Colors.white)),
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                  ),
                                  TextButton(
                                    child: Text('Confirm',
                                        style: GoogleFonts.montserrat(
                                            color: Colors.red)),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              String newStatus;
                              switch (value) {
                                case 'Put on Hold':
                                  newStatus = 'on_hold';
                                  break;
                                case 'Suspend':
                                  newStatus = 'suspended';
                                  break;
                                case 'Activate':
                                  newStatus = 'active';
                                  break;
                                default:
                                  newStatus = 'active';
                              }
                              await updateUserStatus(userId, newStatus);

                              // Show feedback
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.black87,
                                  content: Text(
                                    'User status updated to $newStatus.',
                                    style: GoogleFonts.montserrat(),
                                  ),
                                ),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            return <PopupMenuEntry<String>>[
                              if (status.toLowerCase() != 'on_hold')
                                PopupMenuItem<String>(
                                  value: 'Put on Hold',
                                  child: Text('Put on Hold',
                                      style: GoogleFonts.montserrat()),
                                ),
                              if (status.toLowerCase() != 'suspended')
                                PopupMenuItem<String>(
                                  value: 'Suspend',
                                  child: Text('Suspend',
                                      style: GoogleFonts.montserrat()),
                                ),
                              if (status.toLowerCase() != 'active')
                                PopupMenuItem<String>(
                                  value: 'Activate',
                                  child: Text('Activate',
                                      style: GoogleFonts.montserrat()),
                                ),
                            ];
                          },
                        ),
                        */
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
