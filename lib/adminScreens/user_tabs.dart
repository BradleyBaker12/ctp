// lib/adminScreens/user_tabs.dart

// ignore_for_file: unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/custom_text_field.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_detail_page.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

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

  // Sorting variables
  String _sortField = 'firstName'; // Default sort field
  bool _sortAscending = true; // Default sort direction

  // Filter-related variables
  final List<String> _selectedFilters = [];
  final List<String> _filterOptions = [
    'All Users',
    'Dealers',
    'Transporters',
    'Admin',
    'Active Users',
    'Pending Users',
    'Suspended Users',
    'Has Company Name',
    'Has Trading As',
  ];

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

  /// Determines if a user document matches the search text and filters.
  bool _matchesSearch(Map<String, dynamic> userData) {
    String firstName = (userData['firstName'] ?? '').toLowerCase();
    String lastName = (userData['lastName'] ?? '').toLowerCase();
    String email = (userData['email'] ?? '').toLowerCase();
    String role = (userData['userRole'] ?? '').toLowerCase();
    String status = (userData['accountStatus'] ?? '').toLowerCase();
    String companyName = (userData['companyName'] ?? '').toLowerCase();
    String tradingAs = (userData['tradingAs'] ?? '').toLowerCase();

    bool matchesSearchText = _searchQuery.isEmpty
        ? true
        : (firstName.contains(_searchQuery.toLowerCase()) ||
            lastName.contains(_searchQuery.toLowerCase()) ||
            email.contains(_searchQuery.toLowerCase()) ||
            role.contains(_searchQuery.toLowerCase()) ||
            status.contains(_searchQuery.toLowerCase()) ||
            companyName.contains(_searchQuery.toLowerCase()) ||
            tradingAs.contains(_searchQuery.toLowerCase()));

    if (_selectedFilters.isEmpty || _selectedFilters.contains('All Users')) {
      return matchesSearchText;
    } else {
      bool matchesFilter = false;
      if (_selectedFilters.contains('Dealers') && role == 'dealer') {
        matchesFilter = true;
      }
      if (_selectedFilters.contains('Transporters') && role == 'transporter') {
        matchesFilter = true;
      }
      if (_selectedFilters.contains('Admin') && role == 'admin') {
        matchesFilter = true;
      }
      if (_selectedFilters.contains('Active Users') && status == 'active') {
        matchesFilter = true;
      }
      if (_selectedFilters.contains('Pending Users') && status == 'pending') {
        matchesFilter = true;
      }
      if (_selectedFilters.contains('Suspended Users') &&
          status == 'suspended') {
        matchesFilter = true;
      }
      if (_selectedFilters.contains('Has Company Name') &&
          companyName.isNotEmpty) {
        matchesFilter = true;
      }
      if (_selectedFilters.contains('Has Trading As') && tradingAs.isNotEmpty) {
        matchesFilter = true;
      }
      return matchesSearchText && matchesFilter;
    }
  }

  Future<void> _fetchUsers() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
    });

    // Get current user details from provider.
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String currentUserRole = userProvider.getUserRole;
    final bool isAdmin = currentUserRole == 'admin';
    final String? currentUserId = userProvider.userId; // Updated getter

    Query query = usersCollection
        .orderBy(_sortField, descending: !_sortAscending)
        .limit(_limit);

    // If current user is a sales rep, only fetch users assigned to them.
    if (!isAdmin) {
      query = query.where('assignedSalesRep', isEqualTo: currentUserId);
    }

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    try {
      QuerySnapshot querySnapshot = await query.get();

      // Debug: print how many documents were fetched.
      print("Fetched ${querySnapshot.docs.length} users.");
      for (var doc in querySnapshot.docs) {
        print("User ID: ${doc.id}");
      }

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
          value: 'firstName',
          child:
              Text('Name', style: GoogleFonts.montserrat(color: Colors.white)),
        ),
        PopupMenuItem(
          value: 'email',
          child:
              Text('Email', style: GoogleFonts.montserrat(color: Colors.white)),
        ),
        PopupMenuItem(
          value: 'userRole',
          child:
              Text('Role', style: GoogleFonts.montserrat(color: Colors.white)),
        ),
        PopupMenuItem(
          value: 'accountStatus',
          child: Text('Status',
              style: GoogleFonts.montserrat(color: Colors.white)),
        ),
        PopupMenuItem(
          value: 'companyName',
          child: Text('Company',
              style: GoogleFonts.montserrat(color: Colors.white)),
        ),
        PopupMenuItem(
          value: 'tradingAs',
          child: Text('Trading As',
              style: GoogleFonts.montserrat(color: Colors.white)),
        ),
      ],
    ).then((value) {
      if (value != null) {
        setState(() {
          _sortField = value;
          _users.clear();
          _lastDocument = null;
          _hasMore = true;
          _fetchUsers();
        });
      }
    });
  }

  /// Filter dialog.
  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text('Filter Users',
              style: GoogleFonts.montserrat(color: Colors.white)),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setDialogState) {
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
                        setDialogState(() {
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
                  style: GoogleFonts.montserrat(color: Colors.white70)),
              onPressed: () {
                setState(() {
                  _selectedFilters.clear();
                  _users.clear();
                  _lastDocument = null;
                  _hasMore = true;
                });
                Navigator.pop(context);
                _fetchUsers();
              },
            ),
            TextButton(
              child: Text('Apply',
                  style:
                      GoogleFonts.montserrat(color: const Color(0xFFFF4E00))),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _users.clear();
                  _lastDocument = null;
                  _hasMore = true;
                });
                _fetchUsers();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<DocumentSnapshot> filteredUsers = _users.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return _matchesSearch(data);
    }).toList();

    // Get current user role and id.
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String currentUserRole = userProvider.getUserRole;
    final bool isAdmin = currentUserRole == 'admin';
    final String? currentUserId = userProvider.userId;

    return Scaffold(
      body: GradientBackground(
        child: Column(
          children: [
            // Search, Sort, and Filter Row.
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
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
                          hintText: 'Search any field...',
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
                            _users.clear();
                            _lastDocument = null;
                            _hasMore = true;
                          });
                          _fetchUsers();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.sort, color: Colors.white),
                    onPressed: _showSortMenu,
                    tooltip: 'Sort by: ${_sortField.replaceAll('_', ' ')}',
                  ),
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
                        _users.clear();
                        _lastDocument = null;
                        _hasMore = true;
                      });
                      _fetchUsers();
                    },
                    tooltip:
                        _sortAscending ? 'Sort Ascending' : 'Sort Descending',
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.white),
                    onPressed: _showFilterDialog,
                    tooltip: 'Filter Users',
                  ),
                ],
              ),
            ),
            // Users List.
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
                        String lastName = userData['lastName'] ?? '';
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
                            title: Text(
                              '$firstName $lastName',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              '$email\nRole: $role\nStatus: $status\nCompany: $companyName\nTrading As: $tradingAs',
                              style:
                                  GoogleFonts.montserrat(color: Colors.white70),
                            ),
                            isThreeLine: false,
                            trailing: const Icon(Icons.arrow_forward_ios,
                                color: Colors.white),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UserDetailPage(userId: userId),
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
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Add User',
                style: GoogleFonts.montserrat(color: Colors.white),
              ),
              onPressed: _showCreateUserDialog,
            )
          : null,
    );
  }

  /// Displays a dialog to create a new user.
  ///
  /// - **Admins:** Can create users of any role. If creating a transporter or dealer,
  ///   they can assign a Sales Representative.
  /// - **Sales Representatives:** Can only create transporter or dealer users.
  ///   The Sales Representative is automatically assigned to themselves.
  Future<void> _showCreateUserDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final firstNameController = TextEditingController();
    final companyNameController = TextEditingController();
    final tradingAsController = TextEditingController();

    // Get current user's role and ID.
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String currentUserRole = userProvider.getUserRole;
    final bool isAdmin = currentUserRole == 'admin';
    final String? currentUserId = userProvider.userId;

    // Set default role based on current user's role.
    String? selectedRole = isAdmin ? 'dealer' : 'transporter';
    // This will hold the selected Sales Representative if needed.
    String? selectedSalesRep;

    // Define available roles based on current user's role.
    List<String> roles = [];
    if (isAdmin) {
      roles = ['admin', 'transporter', 'dealer', 'sales representative'];
    } else if (currentUserRole == 'sales representative') {
      roles = ['transporter', 'dealer'];
    }

    if (_secondaryAuth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Secondary Auth not ready yet. Please wait a moment and try again.'),
        ),
      );
      return;
    }

    final GlobalKey<FormState> createUserFormKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(
                'Create New User',
                style: GoogleFonts.montserrat(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: createUserFormKey,
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
                          labelStyle:
                              GoogleFonts.montserrat(color: Colors.white),
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
                              role.replaceAll('_', ' ').toUpperCase(),
                              style:
                                  GoogleFonts.montserrat(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            selectedRole = value;
                            if (!(selectedRole == 'transporter' ||
                                selectedRole == 'dealer')) {
                              selectedSalesRep = null;
                            }
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a user role';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (isAdmin &&
                          (selectedRole == 'transporter' ||
                              selectedRole == 'dealer'))
                        FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .where('userRole',
                                  isEqualTo: 'sales representative')
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Text(
                                'No Sales Representatives available.',
                                style:
                                    GoogleFonts.montserrat(color: Colors.white),
                              );
                            }
                            List<DropdownMenuItem<String>> salesRepItems =
                                snapshot.data!.docs.map((doc) {
                              Map<String, dynamic> repData =
                                  doc.data() as Map<String, dynamic>;
                              String repName =
                                  repData['firstName'] ?? 'No Name';
                              if (repData['lastName'] != null) {
                                repName += ' ${repData['lastName']}';
                              }
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(
                                  repName,
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white),
                                ),
                              );
                            }).toList();
                            return DropdownButtonFormField<String>(
                              value: selectedSalesRep,
                              dropdownColor: Colors.grey[850],
                              style:
                                  GoogleFonts.montserrat(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Assign Sales Rep',
                                labelStyle:
                                    GoogleFonts.montserrat(color: Colors.white),
                                enabledBorder: const UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white70),
                                ),
                                focusedBorder: const UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Color(0xFFFF4E00)),
                                ),
                              ),
                              items: salesRepItems,
                              onChanged: (value) {
                                setStateDialog(() {
                                  selectedSalesRep = value;
                                });
                              },
                              validator: (value) {
                                if ((selectedRole == 'transporter' ||
                                        selectedRole == 'dealer') &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please select a sales representative';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.montserrat(color: Colors.white70),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: Text(
                    'Create',
                    style:
                        GoogleFonts.montserrat(color: const Color(0xFFFF4E00)),
                  ),
                  onPressed: () async {
                    if (!createUserFormKey.currentState!.validate()) {
                      return;
                    }
                    if (isAdmin &&
                        (selectedRole == 'transporter' ||
                            selectedRole == 'dealer') &&
                        (selectedSalesRep == null ||
                            selectedSalesRep!.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please select a Sales Representative for the account.',
                            style: GoogleFonts.montserrat(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    if (!isAdmin &&
                        !(selectedRole == 'transporter' ||
                            selectedRole == 'dealer')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Sales Representatives can only create Transporters or Dealers.',
                            style: GoogleFonts.montserrat(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    try {
                      final secondaryAuth = _secondaryAuth!;
                      UserCredential userCredential =
                          await secondaryAuth.createUserWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );

                      Map<String, dynamic> newUserData = {
                        'firstName': firstNameController.text.trim(),
                        'companyName': companyNameController.text.trim(),
                        'tradingAs': tradingAsController.text.trim(),
                        'email': userCredential.user!.email,
                        'createdAt': FieldValue.serverTimestamp(),
                        'userRole': selectedRole,
                        'accountStatus': 'active',
                        'createdBy': isAdmin ? 'admin' : 'sales representative',
                      };

                      if (selectedRole == 'transporter' ||
                          selectedRole == 'dealer') {
                        if (isAdmin) {
                          newUserData['assignedSalesRep'] = selectedSalesRep;
                        } else if (currentUserRole == 'sales representative') {
                          newUserData['assignedSalesRep'] = currentUserId;
                        }
                      }

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userCredential.user!.uid)
                          .set(newUserData);

                      Navigator.pop(context);
                      setState(() {
                        _users.clear();
                        _lastDocument = null;
                        _hasMore = true;
                      });
                      _fetchUsers();
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error creating user: $e',
                            style: GoogleFonts.montserrat(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
