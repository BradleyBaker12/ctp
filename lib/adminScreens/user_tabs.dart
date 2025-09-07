// lib/adminScreens/user_tabs.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/constants.dart';
import 'package:ctp/components/custom_text_field.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user_detail_page.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

// import 'package:auto_route/auto_route.dart';

// @RoutePage()
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
  final int _limit = 50; // Changed from 20 to 50 for lazy loading/pagination
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
  String _sortField = 'createdAt'; // Default sort field
  bool _sortAscending = false; // Changed default to false (descending)

  // Filter-related variables
  final List<String> _selectedFilters = [];
  // Update the filter options with groups
  final List<String> _filterOptions = [
    'All Users',
    'User Roles', // Header
    'Dealers',
    'Transporters',
    'Admin',
    'Sales Representatives',
    'Account Status', // Header
    'Active Users',
    'Pending Users',
    'Suspended Users',
    'Verification Status', // Header
    'Verified Users',
    'Pending Verification',
  ];

  // Add a flag to track initial loading
  bool _isInitialLoading = true;

  // Add new state variable for filter loading
  bool _isFilterLoading = false;

  // Currently selected tab for user roles
  String _selectedRoleTab = 'Dealers';

  @override
  void initState() {
    super.initState();
    _sortField = 'createdAt'; // Set default sort to creation date
    _sortAscending = false; // Set default to descending (newest first)
    _initializeSecondaryApp();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 500) {
        // Increased threshold
        if (!_isLoading && _hasMore) {
          _fetchUsers();
        }
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

  // _matchesSearch was unused; removed for cleanliness.

  bool _matchesFiltersAndSearch(Map<String, dynamic> userData) {
    // Only do text-based matching here.
    if (_searchQuery.isEmpty) return true;
    String searchText = _searchQuery.toLowerCase();
    return (userData['firstName'] ?? '').toLowerCase().contains(searchText) ||
        (userData['lastName'] ?? '').toLowerCase().contains(searchText) ||
        (userData['email'] ?? '').toLowerCase().contains(searchText) ||
        (userData['userRole'] ?? '').toLowerCase().contains(searchText) ||
        (userData['accountStatus'] ?? '').toLowerCase().contains(searchText) ||
        (userData['companyName'] ?? '').toLowerCase().contains(searchText) ||
        (userData['tradingAs'] ?? '').toLowerCase().contains(searchText);
  }

  /// Fixed _fetchUsers method:
  /// - Builds filtering conditions using arrays and whereIn clauses so that
  ///   sorting is always applied regardless of filters.
  Future<void> _fetchUsers() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _isFilterLoading = true; // Set filter loading state
    });

    try {
      Query query = usersCollection;

      // Only apply filters if "All Users" is NOT selected.
      if (!(_selectedFilters.isEmpty ||
          _selectedFilters.contains('All Users'))) {
        // Build user role filters
        List<String> roleFilters = [];
        if (_selectedFilters.contains('Dealers')) {
          roleFilters.add('dealer');
        }
        if (_selectedFilters.contains('Transporters')) {
          roleFilters.add('transporter');
        }
        if (_selectedFilters.contains('Admin')) {
          roleFilters.add('admin');
        }
        if (_selectedFilters.contains('Sales Representatives')) {
          roleFilters.add('sales representative');
        }
        if (roleFilters.isNotEmpty) {
          if (roleFilters.length == 1) {
            query = query.where('userRole', isEqualTo: roleFilters.first);
          } else {
            query = query.where('userRole', whereIn: roleFilters);
          }
        }

        // Build account status filters
        List<String> statusFilters = [];
        if (_selectedFilters.contains('Active Users')) {
          statusFilters.add('active');
        }
        if (_selectedFilters.contains('Pending Users')) {
          statusFilters.add('pending');
        }
        if (_selectedFilters.contains('Suspended Users')) {
          statusFilters.add('suspended');
        }
        if (statusFilters.isNotEmpty) {
          if (statusFilters.length == 1) {
            query =
                query.where('accountStatus', isEqualTo: statusFilters.first);
          } else {
            query = query.where('accountStatus', whereIn: statusFilters);
          }
        }

        // Apply verification filters
        if (_selectedFilters.contains('Verified Users') &&
            !_selectedFilters.contains('Pending Verification')) {
          query = query.where('isVerified', isEqualTo: true);
        } else if (_selectedFilters.contains('Pending Verification') &&
            !_selectedFilters.contains('Verified Users')) {
          query = query.where('isVerified', isEqualTo: false);
        }
      }

      // Apply sorting
      if (_sortField == 'createdAt') {
        query = query.orderBy('createdAt', descending: !_sortAscending);
      } else {
        query = query
            .orderBy(_sortField, descending: !_sortAscending)
            .orderBy('createdAt', descending: true);
      }

      // Apply pagination
      query = query.limit(_limit);
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot querySnapshot = await query.get();
      List<DocumentSnapshot> docs = querySnapshot.docs;

      if (docs.isNotEmpty) {
        setState(() {
          _lastDocument = docs.last;
          _users.addAll(docs);
          _hasMore = docs.length >= _limit;
          _isLoading = false;
          _isFilterLoading = false;
          _isInitialLoading = false;
        });
      } else {
        setState(() {
          _hasMore = false;
          _isLoading = false;
          _isFilterLoading = false;
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching users: $e');
      setState(() {
        _isLoading = false;
        _isFilterLoading = false;
        _isInitialLoading = false;
      });
    }
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
          value: 'createdAt',
          child: Row(
            children: [
              const Icon(Icons.access_time, color: Color(0xFFFF4E00)),
              const SizedBox(width: 8),
              Text(
                'Creation Date',
                style: GoogleFonts.montserrat(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'divider',
          enabled: false,
          child: Divider(color: Colors.white30),
        ),
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

  @override
  Widget build(BuildContext context) {
    // Get current user role and id.
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String currentUserRole = userProvider.getUserRole;
    final bool isAdmin = currentUserRole == 'admin';
    // currentUserId not used in this widget; remove to avoid analyzer warnings.

    List<DocumentSnapshot> filteredUsers = _users.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      // Exclude archived users
      if ((data['accountStatus'] as String?)?.toLowerCase() == 'archived') {
        return false;
      }
      // Filter by role tab
      switch (_selectedRoleTab) {
        case 'Dealers':
          // Only active or non-pending dealers
          if ((data['userRole'] as String?)?.toLowerCase() != 'dealer' ||
              (data['accountStatus'] as String?)?.toLowerCase() == 'pending') {
            return false;
          }
          break;
        case 'Transporters':
          // Only active or non-pending transporters
          if ((data['userRole'] as String?)?.toLowerCase() != 'transporter' ||
              (data['accountStatus'] as String?)?.toLowerCase() == 'pending') {
            return false;
          }
          break;
        case 'OEM':
          if ((data['userRole'] as String?)?.toLowerCase() != 'oem' ||
              (data['accountStatus'] as String?)?.toLowerCase() == 'pending') {
            return false;
          }
          break;
        case 'Pending':
          if ((data['accountStatus'] as String?)?.toLowerCase() != 'pending') {
            return false;
          }
          break;
      }
      return _matchesFiltersAndSearch(data);
    }).toList();

    return Scaffold(
      body: GradientBackground(
        child: DefaultTabController(
          length: isAdmin ? 4 : 2,
          child: Column(
            children: [
              // Search, Sort, and Filter Row.
              Padding(
                padding: const EdgeInsets.all(16.0),
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
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (context) {
                            return StatefulBuilder(
                              builder: (context, setStateDialog) {
                                return AlertDialog(
                                  backgroundColor: Colors.grey[900],
                                  title: Text('Filter Users',
                                      style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: _filterOptions.map((filter) {
                                        bool isHeader =
                                            filter == 'User Roles' ||
                                                filter == 'Account Status' ||
                                                filter == 'Verification Status';

                                        if (isHeader) {
                                          return Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                16, 16, 16, 8),
                                            child: Text(
                                              filter,
                                              style: GoogleFonts.montserrat(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        }

                                        return Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 4.0),
                                          child: Material(
                                            color: _selectedFilters
                                                    .contains(filter)
                                                ? const Color(0xFFFF4E00)
                                                : Colors.grey[800],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: InkWell(
                                              onTap: () {
                                                setStateDialog(() {
                                                  if (filter == 'All Users') {
                                                    _selectedFilters.clear();
                                                    if (!_selectedFilters
                                                        .contains(filter)) {
                                                      _selectedFilters
                                                          .add(filter);
                                                    }
                                                  } else {
                                                    if (_selectedFilters
                                                        .contains(
                                                            'All Users')) {
                                                      _selectedFilters.clear();
                                                    }
                                                    if (_selectedFilters
                                                        .contains(filter)) {
                                                      _selectedFilters
                                                          .remove(filter);
                                                    } else {
                                                      _selectedFilters
                                                          .add(filter);
                                                    }
                                                  }
                                                });
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                                child: Text(
                                                  filter,
                                                  style: GoogleFonts.montserrat(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: _selectedFilters
                                                            .contains(filter)
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text('Clear',
                                          style: GoogleFonts.montserrat(
                                              color: Colors.white70)),
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
                                          style: GoogleFonts.montserrat(
                                              color: const Color(0xFFFF4E00))),
                                      onPressed: () {
                                        setState(() {
                                          _users.clear();
                                          _lastDocument = null;
                                          _hasMore = true;
                                          _isFilterLoading = true;
                                        });
                                        Navigator.pop(context);
                                        _fetchUsers();
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                      tooltip: 'Filter Users',
                    ),
                    if (isAdmin)
                      IconButton(
                        icon: const Icon(Icons.upgrade, color: Colors.white),
                        tooltip: 'Make all OEM users managers',
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Colors.grey[900],
                              title: Text('Elevate OEM Users',
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white)),
                              content: Text(
                                'This will set isOemManager=true for all OEM users. Continue?',
                                style: GoogleFonts.montserrat(
                                    color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text('Cancel',
                                      style: GoogleFonts.montserrat(
                                          color: Colors.white70)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: Text('Confirm',
                                      style: GoogleFonts.montserrat(
                                          color: const Color(0xFFFF4E00))),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true) return;
                          try {
                            final callable = FirebaseFunctions.instance
                                .httpsCallable('elevateAllOemToManagers');
                            final result = await callable.call();
                            final updated = (result.data is Map &&
                                    result.data['updated'] is int)
                                ? result.data['updated'] as int
                                : null;
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    updated != null
                                        ? 'Updated $updated OEM users.'
                                        : 'OEM users elevated.',
                                    style: GoogleFonts.montserrat(),
                                  ),
                                ),
                              );
                              setState(() {
                                _users.clear();
                                _lastDocument = null;
                                _hasMore = true;
                              });
                              _fetchUsers();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e',
                                      style: GoogleFonts.montserrat()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                  ],
                ),
              ),
              // Custom-styled role tabs matching offer tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildUserTabButton('Dealers'),
                    const SizedBox(width: 12),
                    _buildUserTabButton('Transporters'),
                    if (isAdmin) ...[
                      const SizedBox(width: 12),
                      _buildUserTabButton('OEM'),
                      const SizedBox(width: 12),
                      _buildUserTabButton('Pending'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Users List.
              Expanded(
                child: _isInitialLoading || _isFilterLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                        color: AppColors.orange,
                      ))
                    : filteredUsers.isEmpty
                        ? Center(
                            child: Text(
                              'No users found.',
                              style:
                                  GoogleFonts.montserrat(color: Colors.white),
                            ),
                          )
                        : ListView.builder(
                            key: const PageStorageKey('users_list'),
                            controller: _scrollController,
                            itemCount:
                                filteredUsers.length + (_hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == filteredUsers.length) {
                                if (_isLoading) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }
                              var userData = filteredUsers[index].data()
                                  as Map<String, dynamic>;
                              String userId = filteredUsers[index].id;
                              String firstName =
                                  userData['firstName'] ?? 'No Name';
                              String lastName = userData['lastName'] ?? '';
                              String email = userData['email'] ?? 'No Email';
                              String role = userData['userRole'] ?? 'user';
                              String companyName =
                                  userData['companyName'] ?? 'No Company';
                              String tradingAs =
                                  userData['tradingAs'] ?? 'No Trading As';
                              var accountStatus = userData['accountStatus'];
                              var isVerified = userData['isVerified'] ?? false;
                              String status;
                              Color statusColor;
                              String statusText;

                              // Determine status color and text
                              if (accountStatus == 'suspended') {
                                status = 'suspended';
                                statusColor = Colors.red;
                                statusText = 'Suspended';
                              } else if (!isVerified) {
                                status = 'pending';
                                statusColor = Colors.amber;
                                statusText = 'Pending Verification';
                              } else if (accountStatus != 'active') {
                                status = 'inactive';
                                statusColor = Colors.orange;
                                statusText = 'Inactive';
                              } else {
                                status = 'active';
                                statusColor = Colors.transparent;
                                statusText = '';
                              }

                              return Card(
                                color: status != 'active'
                                    ? statusColor.withOpacity(0.2)
                                    : Colors.grey[900],
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                child: Stack(
                                  children: [
                                    ListTile(
                                      leading: Stack(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Colors.blueAccent,
                                            child: Text(
                                              firstName.isNotEmpty
                                                  ? firstName[0].toUpperCase()
                                                  : 'U',
                                              style: GoogleFonts.montserrat(
                                                  color: Colors.white),
                                            ),
                                          ),
                                          if (status != 'active')
                                            Positioned(
                                              right: -2,
                                              top: -2,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: statusColor,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.grey[900]!,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Icon(
                                                  status == 'suspended'
                                                      ? Icons.block
                                                      : status == 'pending'
                                                          ? Icons.warning
                                                          : Icons.warning_amber,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '$firstName $lastName',
                                              style: GoogleFonts.montserrat(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          if (status != 'active')
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: statusColor,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                statusText,
                                                style: GoogleFonts.montserrat(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        '$email\nRole: $role\nStatus: $status\nCompany: $companyName\nTrading As: $tradingAs',
                                        style: GoogleFonts.montserrat(
                                            color: Colors.white70),
                                      ),
                                      isThreeLine: false,
                                      trailing: const Icon(
                                          Icons.arrow_forward_ios,
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
                                    if (status != 'active')
                                      Positioned(
                                        top: 0,
                                        bottom: 0,
                                        left: 0,
                                        child: Container(
                                          width: 4,
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(4),
                                              bottomLeft: Radius.circular(4),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
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
    // OEM brand input (only used when role is OEM)
    final oemBrandController = TextEditingController();
    // OEM org fields
    // Company ID is now auto-generated for OEM managers; no manual input needed.
    bool isOemManagerFlag = false;
    String? selectedOemManagerId;

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
      roles = ['admin', 'transporter', 'dealer', 'sales representative', 'oem'];
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
    List<String> selectedEmployeeIds = <String>[];

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
                      // OEM org controls
                      if (isAdmin && selectedRole == 'oem') ...[
                        SwitchListTile(
                          value: isOemManagerFlag,
                          onChanged: (v) {
                            setStateDialog(() {
                              isOemManagerFlag = v;
                              if (v) selectedOemManagerId = null;
                            });
                          },
                          title: Text('Is OEM Manager?',
                              style:
                                  GoogleFonts.montserrat(color: Colors.white)),
                          activeColor: const Color(0xFFFF4E00),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 8),
                        if (isOemManagerFlag)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              'This account will be created as an OEM manager.',
                              style:
                                  GoogleFonts.montserrat(color: Colors.white70),
                            ),
                          )
                        else
                          FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .where('userRole', isEqualTo: 'oem')
                                .where('isOemManager', isEqualTo: true)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              }
                              final docs = snapshot.data?.docs ?? [];
                              if (docs.isEmpty) {
                                return Text(
                                  'No OEM Managers available. Create a manager first.',
                                  style: GoogleFonts.montserrat(
                                      color: Colors.white),
                                );
                              }
                              final items = docs.map((d) {
                                final data = d.data() as Map<String, dynamic>;
                                final name = ((data['firstName'] ?? '') +
                                        ' ' +
                                        (data['lastName'] ?? ''))
                                    .trim();
                                return DropdownMenuItem<String>(
                                  value: d.id,
                                  child: Text(
                                    name.isEmpty ? d.id : name,
                                    style: GoogleFonts.montserrat(
                                        color: Colors.white),
                                  ),
                                );
                              }).toList();
                              return DropdownButtonFormField<String>(
                                value: selectedOemManagerId,
                                dropdownColor: Colors.grey[850],
                                style:
                                    GoogleFonts.montserrat(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Assign OEM Manager',
                                  labelStyle: GoogleFonts.montserrat(
                                      color: Colors.white),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.white70),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Color(0xFFFF4E00)),
                                  ),
                                ),
                                items: items,
                                onChanged: (v) => setStateDialog(
                                    () => selectedOemManagerId = v),
                                validator: (v) {
                                  if (!isOemManagerFlag &&
                                      (v == null || v.isEmpty)) {
                                    return 'Select an OEM manager for employee accounts';
                                  }
                                  return null;
                                },
                              );
                            },
                          ),
                        const SizedBox(height: 16),
                      ],
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
                      if (isAdmin && selectedRole == 'oem')
                        CustomTextField(
                          hintText: 'OEM BRAND',
                          controller: oemBrandController,
                        ),
                      const SizedBox(height: 16),
                      if (isAdmin && selectedRole == 'oem' && isOemManagerFlag)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assign employees to this manager (optional):',
                              style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder<QuerySnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .where('userRole', isEqualTo: 'oem')
                                  .where('isOemManager', isEqualTo: false)
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                }
                                final docs = snapshot.data?.docs ?? [];
                                if (docs.isEmpty) {
                                  return Text(
                                    'No OEM employees available.',
                                    style: GoogleFonts.montserrat(
                                        color: Colors.white70),
                                  );
                                }
                                return ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxHeight: 220),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: docs.length,
                                    itemBuilder: (context, idx) {
                                      final d = docs[idx];
                                      final data =
                                          d.data() as Map<String, dynamic>;
                                      final name = ((data['firstName'] ?? '') +
                                              ' ' +
                                              (data['lastName'] ?? ''))
                                          .trim();
                                      final email =
                                          (data['email'] ?? '').toString();
                                      final id = d.id;
                                      final isSelected =
                                          selectedEmployeeIds.contains(id);
                                      return CheckboxListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        value: isSelected,
                                        onChanged: (val) {
                                          setStateDialog(() {
                                            if (val == true) {
                                              if (!selectedEmployeeIds
                                                  .contains(id)) {
                                                selectedEmployeeIds.add(id);
                                              }
                                            } else {
                                              selectedEmployeeIds.remove(id);
                                            }
                                          });
                                        },
                                        title: Text(
                                          name.isEmpty ? email : name,
                                          style: GoogleFonts.montserrat(
                                              color: Colors.white),
                                        ),
                                        subtitle: email.isNotEmpty
                                            ? Text(email,
                                                style: GoogleFonts.montserrat(
                                                    color: Colors.white70))
                                            : null,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      if (isAdmin &&
                          (selectedRole == 'transporter' ||
                              selectedRole == 'dealer' ||
                              selectedRole == 'oem'))
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
                                        selectedRole == 'dealer' ||
                                        selectedRole == 'oem') &&
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
                            selectedRole == 'dealer' ||
                            selectedRole == 'oem') &&
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

                      if (selectedRole == 'oem') {
                        final brand = oemBrandController.text.trim();
                        if (brand.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please enter an OEM Brand for the account.',
                                style: GoogleFonts.montserrat(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        newUserData['oemBrand'] = brand;

                        // Manager/employee assignment
                        if (isAdmin) {
                          if (isOemManagerFlag) {
                            // Create OEM manager without companyId field
                            newUserData['isOemManager'] = true;
                            newUserData['managerId'] = null;
                          } else {
                            if (selectedOemManagerId == null ||
                                selectedOemManagerId!.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please select an OEM Manager for this employee.',
                                    style: GoogleFonts.montserrat(),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            // No company linkage persisted; just set managerId
                            newUserData['isOemManager'] = false;
                            newUserData['managerId'] = selectedOemManagerId;
                          }
                        }
                      }

                      if (selectedRole == 'transporter' ||
                          selectedRole == 'dealer' ||
                          selectedRole == 'oem') {
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

                      // If OEM manager created and employees selected, assign them
                      if (selectedRole == 'oem' &&
                          isOemManagerFlag &&
                          selectedEmployeeIds.isNotEmpty) {
                        final batch = FirebaseFirestore.instance.batch();
                        for (final empId in selectedEmployeeIds) {
                          final ref = FirebaseFirestore.instance
                              .collection('users')
                              .doc(empId);
                          batch.update(ref, {
                            'managerId': userCredential.user!.uid,
                            'isOemManager': false,
                          });
                        }
                        await batch.commit();
                      }

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

  Widget _buildUserTabButton(String tab) {
    bool isSelected = _selectedRoleTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _selectedRoleTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF4E00) : Colors.black,
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(
            color: isSelected ? Colors.black : const Color(0xFF0E4CAF),
            width: 1.0,
          ),
        ),
        child: Text(
          tab.toUpperCase(),
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
