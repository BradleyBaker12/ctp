import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_text_field.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_detail_page.dart';

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
  final int _limit = 10;
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  final List<DocumentSnapshot> _users = [];

  final ScrollController _scrollController = ScrollController();

  // Secondary Firebase App and Auth instances
  FirebaseApp? _secondaryApp;
  FirebaseAuth? _secondaryAuth;
  bool _isSecondaryAuthReady = false;

  @override
  void initState() {
    super.initState();
    _initializeSecondaryApp();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchUsers();
      }
    });
  }

  Future<void> _initializeSecondaryApp() async {
    _secondaryApp = await Firebase.initializeApp(
      name: 'secondaryApp',
      options: Firebase.app().options,
    );

    _secondaryAuth = FirebaseAuth.instanceFor(app: _secondaryApp!);

    setState(() {
      _isSecondaryAuthReady = true;
    });

    // Now that secondary auth is ready, fetch users.
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _matchesSearch(Map<String, dynamic> userData) {
    if (_searchQuery.isEmpty) return true;

    String firstName = userData['firstName']?.toString().toLowerCase() ?? '';
    String lastName = userData['lastName']?.toString().toLowerCase() ?? '';
    String email = userData['email']?.toString().toLowerCase() ?? '';
    String role = userData['userRole']?.toString().toLowerCase() ?? '';
    String status = userData['accountStatus']?.toString().toLowerCase() ?? '';
    String companyName =
        userData['companyName']?.toString().toLowerCase() ?? '';
    String tradingAs = userData['tradingAs']?.toString().toLowerCase() ?? '';

    return firstName.contains(_searchQuery.toLowerCase()) ||
        lastName.contains(_searchQuery.toLowerCase()) ||
        email.contains(_searchQuery.toLowerCase()) ||
        role.contains(_searchQuery.toLowerCase()) ||
        status.contains(_searchQuery.toLowerCase()) ||
        companyName.contains(_searchQuery.toLowerCase()) ||
        tradingAs.contains(_searchQuery.toLowerCase());
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
    List<DocumentSnapshot> filteredUsers = _users.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return _matchesSearch(data);
    }).toList();

    return Scaffold(
      body: GradientBackground(
        child: Column(
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
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: Colors.transparent,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Color(0xFFFF4E00)),
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
                      ? const Center(child: CircularProgressIndicator())
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
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
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
                        String companyName =
                            userData['companyName'] ?? 'No Company';
                        String tradingAs =
                            userData['tradingAs'] ?? 'No Trading As';

                        var accountStatus = userData['accountStatus'];
                        String status;
                        if (accountStatus is String) {
                          status = accountStatus;
                        } else if (accountStatus is bool) {
                          status = accountStatus ? 'active' : 'inactive';
                        } else {
                          status = 'active';
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
                                style:
                                    GoogleFonts.montserrat(color: Colors.white),
                              ),
                            ),
                            title: Text(firstName,
                                style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            subtitle: Text(
                                '$email\nRole: $role\nStatus: $status\nCompany: $companyName\nTrading As: $tradingAs',
                                style: GoogleFonts.montserrat(
                                    color: Colors.white70)),
                            isThreeLine: false,
                            trailing: const Icon(Icons.arrow_forward_ios,
                                color: Colors.white),
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
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isSecondaryAuthReady
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFF0E4CAF),
              icon: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              label: Text(
                'Add User',
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
              onPressed: () => _showCreateUserDialog(),
            )
          : null,
    );
  }

  Future<void> _showCreateUserDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final firstNameController = TextEditingController();
    final companyNameController = TextEditingController();
    final tradingAsController = TextEditingController();

    String? selectedRole = 'Admin';
    final roles = ['Admin', 'Transporter', 'Dealer'];

    // Check if _secondaryAuth is initialized
    if (_secondaryAuth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Secondary Auth not ready yet. Please wait a moment and try again.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Create New User',
          style: GoogleFonts.montserrat(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                hintText: 'FIRST NAME',
                controller: firstNameController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                hintText: 'COMPANY NAME',
                controller: companyNameController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                hintText: 'TRADING AS',
                controller: tradingAsController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                hintText: 'EMAIL',
                controller: emailController,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                hintText: 'PASSWORD',
                controller: passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                dropdownColor: Colors.grey[850],
                style: GoogleFonts.montserrat(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'User Role',
                  labelStyle: GoogleFonts.montserrat(color: Colors.white),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFF4E00)),
                  ),
                ),
                items: roles.map((role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(
                      role,
                      style: GoogleFonts.montserrat(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedRole = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(
                color: Colors.white70,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(
              'Create',
              style: GoogleFonts.montserrat(
                color: const Color(0xFFFF4E00),
              ),
            ),
            onPressed: () async {
              try {
                final secondaryAuth = _secondaryAuth!;
                UserCredential userCredential =
                    await secondaryAuth.createUserWithEmailAndPassword(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                );

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(userCredential.user!.uid)
                    .set({
                  'firstName': firstNameController.text.trim(),
                  'companyName': companyNameController.text.trim(),
                  'tradingAs': tradingAsController.text.trim(),
                  'email': userCredential.user!.email,
                  'createdAt': FieldValue.serverTimestamp(),
                  'userRole': selectedRole,
                  'accountStatus': 'active',
                  'createdBy': 'admin',
                });

                Navigator.pop(context);
                // Refresh the list
                _users.clear();
                _lastDocument = null;
                _hasMore = true;
                _fetchUsers();
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error creating user: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
