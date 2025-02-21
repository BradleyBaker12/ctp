// lib/providers/user_provider.dart

import 'dart:async'; // Add this import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/models/inspection_details.dart'; // Ensure this model exists
import 'package:ctp/models/user_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  String _accountStatus = 'active'; // Default status
  List<String> _preferredBrands = [];
  String _userRole = 'dealer'; // Default role
  String? _profileImageUrl;
  bool _isLoading = true;
  bool _hasNotifications = false; // Add this field to track notifications

  // Add verification field
  bool _isVerified = false;

  // Add this line with the other field declarations
  String? _taxCertificateUrl;

  // Add getter
  bool get isVerified => _isVerified;

  // User details
  String? _companyName;
  String? _tradingName;
  String? _registrationNumber;
  String? _vatNumber;
  String? _addressLine1;
  String? _addressLine2;
  String? _city;
  String? _state;
  String? _postalCode;
  String? _firstName;
  String? _middleName;
  String? _lastName;
  String? _phoneNumber;
  bool? _agreedToHouseRules;
  String? _bankConfirmationUrl;
  String? _brncUrl;
  String? _cipcCertificateUrl;
  String? _proxyUrl;
  Timestamp? _createdAt;

  // Admin approval status
  bool? _adminApproval;

  // Saved inspection details
  List<InspectionDetail> _savedInspectionDetails = [];

  // Liked and disliked vehicles
  List<String> _likedVehicles = [];
  List<String> _dislikedVehicles = [];

  // Offers
  List<String> _offers = [];
  List<String> _offersMade = [];

  // User display information
  String _userName = 'Guest';
  String _userEmail = 'user@example.com';

  // Cache for userId to userName mapping
  final Map<String, String> _userNameCache = {};

  // New field to store dealer accounts
  List<Dealer> _dealers = [];

  // Getter for dealers
  List<Dealer> get dealers => _dealers;

  // Getter for notifications
  bool get hasNotifications => _hasNotifications;
  String? _fcmToken;

  StreamSubscription? _statusSubscription;

  bool _hasAcceptedTerms = false;

  bool get hasAcceptedTerms => _hasAcceptedTerms;

  Future<void> setTermsAcceptance(bool accepted) async {
    try {
      if (_user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({
          'hasAcceptedTerms': accepted,
        });
        _hasAcceptedTerms = accepted;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating terms acceptance: $e');
      rethrow;
    }
  }

  Future<void> loadTermsAcceptance() async {
    try {
      if (_user != null) {
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get();
        _hasAcceptedTerms = userData.data()?['hasAcceptedTerms'] ?? false;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading terms acceptance: $e');
      rethrow;
    }
  }

  UserProvider() {
    _checkAuthState();
    FirebaseAuth.instance.authStateChanges().listen((User? newUser) async {
      if (newUser != null) {
        _user = newUser;
        try {
          await fetchUserData();
        } catch (e) {
          print('Error fetching user data: $e');
          _clearUserData();
        }
        notifyListeners();
      }
    });
  }

  // Add this method inside the UserProvider class
  Future<void> updateUserRole(String role) async {
    if (_user != null) {
      try {
        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'userRole': role, 'isFirstLogin': false});

        // Update local state
        _userRole = role;
        notifyListeners();
      } catch (e) {
        print('Error updating user role: $e');
        rethrow;
      }
    } else {
      throw Exception('No user logged in');
    }
  }

  Future<bool> hasDealerUploadedRequiredDocuments(String dealerId) async {
    try {
      // Fetch the dealer's document from Firestore
      DocumentSnapshot dealerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(dealerId)
          .get();

      // If the document doesn't exist, return false
      if (!dealerDoc.exists) {
        print('Dealer document does not exist.');
        return false;
      }

      // Extract data from the document
      Map<String, dynamic> data = dealerDoc.data() as Map<String, dynamic>;

      // Directly access the required document URLs from the top-level fields
      String? cipcCertificateUrl = data['cipcCertificateUrl'] as String?;
      String? brncUrl = data['brncUrl'] as String?;
      String? bankConfirmationUrl = data['bankConfirmationUrl'] as String?;
      String? proxyUrl = data['proxyUrl'] as String?;

      // Check if all required documents are present and non-empty
      bool hasAllDocuments = (cipcCertificateUrl?.isNotEmpty ?? false) &&
          (brncUrl?.isNotEmpty ?? false) &&
          (bankConfirmationUrl?.isNotEmpty ?? false) &&
          (proxyUrl?.isNotEmpty ?? false);

      // Check the account's verification status
      bool isVerified = data['isVerified'] == true;

      // Debugging Statements
      print('Dealer ID: $dealerId');
      print('CIPC Certificate URL: $cipcCertificateUrl');
      print('BRNC URL: $brncUrl');
      print('Bank Confirmation URL: $bankConfirmationUrl');
      print('Proxy URL: $proxyUrl');
      print('Has All Documents: $hasAllDocuments');
      print('Is Verified: $isVerified');

      // Return true only if all documents are present and the account is verified
      return hasAllDocuments && isVerified;
    } catch (e) {
      // Log any errors encountered during the process
      print('Error checking dealer documents: $e');
      return false;
    }
  }

  Future<UserDetails> getUserDetailsById(String userId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        return UserDetails.fromFirestore(doc);
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      print('Error fetching user details for userId $userId: $e');
      rethrow; // Propagate the error to be handled in the UI
    }
  }

  // New Convenience Method to get the assigned sales rep's account details.
  Future<UserDetails> getAssignedSalesRepAccount(
      String assignedSalesRepId) async {
    // This uses your existing getUserDetailsById method.
    return await getUserDetailsById(assignedSalesRepId);
  }

  // Method to check for notifications
  Future<void> checkForNotifications() async {
    if (_user != null) {
      // Example logic: fetch notifications from Firestore or any other logic
      QuerySnapshot notificationSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: _user!.uid)
          .where('isRead',
              isEqualTo: false) // Assuming you store notification read status
          .get();

      _hasNotifications = notificationSnapshot.docs.isNotEmpty;
      notifyListeners();
    }
  }

  Future<void> _checkAuthState() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      await fetchUserData();
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> getUserData() {
    return {
      'firstName': _firstName,
      'middleName': _middleName,
      'lastName': _lastName,
      'tradingName': _tradingName,
      'registrationNumber': _registrationNumber,
      'vatNumber': _vatNumber,
      'addressLine1': _addressLine1,
      'addressLine2': _addressLine2,
      'city': _city,
      'state': _state,
      'postalCode': _postalCode,
      'savedInspectionDetails':
          _savedInspectionDetails.map((item) => item.toMap()).toList(),
    };
  }

  Future<void> fetchUserData() async {
    print("DEBUG: Fetching user data");
    try {
      if (_user != null) {
        print("DEBUG: Fetching for user: ${_user!.uid}");
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get();
        print("DEBUG: User doc exists: ${userDoc.exists}");
        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          _userRole = data['userRole'] ?? 'dealer';
          _adminApproval = data['adminApproval'] ?? false;
          _accountStatus =
              data['accountStatus'] ?? 'active'; // Fetch account status

          // Fetch profile image URL
          _profileImageUrl = data['profileImageUrl'];

          // Fetch preferred brands
          _preferredBrands = List<String>.from(data['preferredBrands'] ?? []);

          // Fetch offers
          _offers = List<String>.from(data['offers'] ?? []);
          _offersMade = List<String>.from(data['offersMade'] ?? []);

          // Fetch liked and disliked vehicles
          _likedVehicles = List<String>.from(data['likedVehicles'] ?? []);
          _dislikedVehicles = List<String>.from(data['dislikedVehicles'] ?? []);

          // Fetch user basic information
          _userName = data['firstName'] ?? 'Guest';
          _userEmail = data['email'] ?? 'user@example.com';
          _phoneNumber = data['phoneNumber'];

          // Fetch company information
          _companyName = data['companyName'];
          _tradingName = data['tradingName'];
          _registrationNumber = data['registrationNumber'];
          _vatNumber = data['vatNumber'];
          _addressLine1 = data['addressLine1'];
          _addressLine2 = data['addressLine2'];
          _city = data['city'];
          _state = data['state'];
          _postalCode = data['postalCode'];

          // Fetch personal information
          _firstName = data['firstName'];
          _middleName = data['middleName'];
          _lastName = data['lastName'];
          _agreedToHouseRules = data['agreedToHouseRules'];

          // Fetch document URLs
          _bankConfirmationUrl = data['bankConfirmationUrl'];
          _brncUrl = data['brncUrl'];
          _cipcCertificateUrl = data['cipcCertificateUrl'];
          _proxyUrl = data['proxyUrl'];
          _createdAt = data['createdAt'];

          // Fetch saved inspection details
          _savedInspectionDetails = [];
          if (data['savedInspectionDetails'] != null) {
            _savedInspectionDetails = (data['savedInspectionDetails'] as List)
                .map((item) =>
                    InspectionDetail.fromMap(Map<String, dynamic>.from(item)))
                .toList();
          }

          _isVerified = data['isVerified'] ?? false;
          _taxCertificateUrl = data['taxCertificateUrl'];

          _isLoading = false;
          await checkForNotifications();
          await loadTermsAcceptance();
          notifyListeners();
        } else {
          _clearUserData();
        }
      } else {
        _clearUserData();
      }
    } catch (e) {
      print('Error fetching user data: $e');
      _clearUserData();
    }
  }

  /// Fetches all user accounts with userRole == 'dealer'
  Future<void> fetchDealers() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userRole', isEqualTo: 'dealer')
          .get();

      _dealers = querySnapshot.docs.map((doc) {
        return Dealer.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      notifyListeners();
    } catch (e) {
      print('Error fetching dealers: $e');
      // Optionally handle errors (e.g., set an error state, show a message)
    }
  }

  Future<void> fetchAdmins() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userRole', whereIn: ['admin', 'sales representative']).get();

      _dealers = querySnapshot.docs.map((doc) {
        return Dealer.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      notifyListeners();
    } catch (e) {
      print('Error fetching Admins and Sales Reps: $e');
      // Optionally, handle errors (e.g., set an error state or show a message)
    }
  }

  Future<void> saveFcmToken() async {
    if (_user != null) {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != _fcmToken) {
        _fcmToken = token;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'fcmToken': token});
      }
    }
  }

  Map<String, dynamic> getUserDataForUpdate() {
    return {
      'firstName': _firstName,
      'middleName': _middleName,
      'lastName': _lastName,
      'tradingName': _tradingName,
      'registrationNumber': _registrationNumber,
      'vatNumber': _vatNumber,
      'addressLine1': _addressLine1,
      'addressLine2': _addressLine2,
      'city': _city,
      'state': _state,
      'postalCode': _postalCode,
      'savedInspectionDetails':
          _savedInspectionDetails.map((item) => item.toMap()).toList(),
    };
  }

  String get getAccountStatus => _accountStatus;

  Future<String> uploadFile(Uint8List file, String nameFile) async {
    String fileName = '${Uuid().v4()} $nameFile';
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_images/${_user!.uid}/$fileName');
    // final storageRef = FirebaseStorage.instance
    //     .ref()
    //     .child('profile_images/${_user!.uid}/${file.path.split('/').last}');
    await storageRef.putData(file);
    // final snapshot = await uploadTask;
    return await storageRef.getDownloadURL();
  }

  Future<String> uploadBytes(Uint8List bytes) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_images/${_user!.uid}/profile.jpg');
    final uploadTask = storageRef.putData(bytes);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _clearUserData();
  }

  void _clearUserData() {
    _preferredBrands = [];
    _userRole = 'dealer';
    _profileImageUrl = null;
    _offers = [];
    _offersMade = [];
    _likedVehicles = [];
    _dislikedVehicles = [];
    _savedInspectionDetails = [];
    _userName = 'Guest';
    _companyName = null;
    _tradingName = null;
    _registrationNumber = null;
    _vatNumber = null;
    _addressLine1 = null;
    _addressLine2 = null;
    _city = null;
    _state = null;
    _postalCode = null;
    _firstName = null;
    _middleName = null;
    _lastName = null;
    _phoneNumber = null;
    _agreedToHouseRules = null;
    _bankConfirmationUrl = null;
    _brncUrl = null;
    _cipcCertificateUrl = null;
    _proxyUrl = null;
    _createdAt = null;
    _adminApproval = null;
    _taxCertificateUrl = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<String?> getUserEmailById(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        return data['email'] ?? 'Unknown';
      } else {
        return 'Unknown';
      }
    } catch (e) {
      print('Error fetching email for userId $userId: $e');
      return 'Unknown';
    }
  }

  // Methods for liked vehicles
  Future<void> likeVehicle(String vehicleId) async {
    if (_user != null) {
      if (!_likedVehicles.contains(vehicleId)) {
        _likedVehicles.add(vehicleId);
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .update({'likedVehicles': _likedVehicles});
          notifyListeners();
        } catch (e) {
          print('Error updating likedVehicles in Firestore: $e');
        }
      }
    }
  }

  Future<void> unlikeVehicle(String vehicleId) async {
    if (_user != null) {
      _likedVehicles.remove(vehicleId);
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'likedVehicles': _likedVehicles});
        notifyListeners();
      } catch (e) {
        print('Error removing vehicle from likedVehicles in Firestore: $e');
      }
    }
  }

  Future<void> clearLikedVehicles() async {
    if (_user != null) {
      _likedVehicles.clear();
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'likedVehicles': []});
        notifyListeners();
      } catch (e) {
        print('Error clearing likedVehicles in Firestore: $e');
      }
    }
  }

  // Methods for disliked vehicles
  Future<void> dislikeVehicle(String vehicleId) async {
    if (_user != null) {
      if (!_dislikedVehicles.contains(vehicleId)) {
        _dislikedVehicles.add(vehicleId);
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .update({'dislikedVehicles': _dislikedVehicles});
          notifyListeners();
        } catch (e) {
          print('Error updating dislikedVehicles in Firestore: $e');
        }
      }
    }
  }

  Future<void> removeDislikedVehicle(String vehicleId) async {
    if (_user != null) {
      if (_dislikedVehicles.contains(vehicleId)) {
        _dislikedVehicles.remove(vehicleId);
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .update({'dislikedVehicles': _dislikedVehicles});
          notifyListeners();
        } catch (e) {
          print('Error updating dislikedVehicles in Firestore: $e');
        }
      }
    }
  }

  Future<void> clearDislikedVehicles() async {
    if (_user != null) {
      _dislikedVehicles.clear();
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'dislikedVehicles': []});
        notifyListeners();
      } catch (e) {
        print('Error clearing dislikedVehicles in Firestore: $e');
      }
    }
  }

  // Methods for preferred brands
  void addPreferredBrand(String brand) {
    if (!_preferredBrands.contains(brand)) {
      _preferredBrands.add(brand);
      _updatePreferredBrandsInFirestore();
      notifyListeners();
    }
  }

  void removePreferredBrand(String brand) {
    if (_preferredBrands.contains(brand)) {
      _preferredBrands.remove(brand);
      _updatePreferredBrandsInFirestore();
      notifyListeners();
    }
  }

  Future<void> updatePreferredBrands(List<String> brands) async {
    _preferredBrands = brands;
    if (_user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({'preferredBrands': _preferredBrands});
    }
    notifyListeners();
  }

  Future<void> _updatePreferredBrandsInFirestore() async {
    if (_user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({'preferredBrands': _preferredBrands});
    }
  }

  // Method to save inspection details
  Future<void> saveInspectionDetail(InspectionDetail detail) async {
    if (_user != null) {
      _savedInspectionDetails.add(detail);
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({
          'savedInspectionDetails':
              _savedInspectionDetails.map((item) => item.toMap()).toList(),
        });
        notifyListeners();
      } catch (e) {
        print('Error saving inspection detail: $e');
      }
    }
  }

  // Method to update user profile
  Future<void> updateUserProfile({
    required String firstName,
    required String middleName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String companyName,
    required String tradingName,
    required String addressLine1,
    required String addressLine2,
    required String city,
    required String state,
    required String postalCode,
    String? profileImageUrl,
    String? bankConfirmationUrl,
    String? cipcCertificateUrl,
    String? proxyUrl,
    String? brncUrl,
    // Add other required fields as needed
  }) async {
    if (_user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'companyName': companyName,
        'tradingName': tradingName,
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'city': city,
        'state': state,
        'postalCode': postalCode,
        'profileImageUrl': profileImageUrl,
        'bankConfirmationUrl': bankConfirmationUrl,
        'cipcCertificateUrl': cipcCertificateUrl,
        'proxyUrl': proxyUrl,
        'brncUrl': brncUrl,
        // Update other fields as needed
      });
      _firstName = firstName;
      _middleName = middleName;
      _lastName = lastName;
      _userEmail = email;
      _phoneNumber = phoneNumber;
      _companyName = companyName;
      _tradingName = tradingName;
      _addressLine1 = addressLine1;
      _addressLine2 = addressLine2;
      _city = city;
      _state = state;
      _postalCode = postalCode;
      _profileImageUrl = profileImageUrl;
      _bankConfirmationUrl = bankConfirmationUrl;
      _cipcCertificateUrl = cipcCertificateUrl;
      _proxyUrl = proxyUrl;
      _brncUrl = brncUrl;
      notifyListeners();
    }
  }

  // **New Method: Update Any User's Details (Admin Only)**
  Future<void> updateUserDetails({
    required String userId,
    required String firstName,
    required String middleName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String companyName,
    required String tradingName,
    required String addressLine1,
    required String addressLine2,
    required String city,
    required String state,
    required String postalCode,
    String? profileImageUrl,
    String? bankConfirmationUrl,
    String? cipcCertificateUrl,
    String? proxyUrl,
    String? brncUrl,
    // Add other required fields as needed
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'companyName': companyName,
        'tradingName': tradingName,
        'addressLine1': addressLine1,
        'addressLine2': addressLine2,
        'city': city,
        'state': state,
        'postalCode': postalCode,
        'profileImageUrl': profileImageUrl,
        'bankConfirmationUrl': bankConfirmationUrl,
        'cipcCertificateUrl': cipcCertificateUrl,
        'proxyUrl': proxyUrl,
        'brncUrl': brncUrl,
        // Update other fields as needed
      });

      // If the edited user is the current user, update local data
      if (_user != null && _user!.uid == userId) {
        _firstName = firstName;
        _middleName = middleName;
        _lastName = lastName;
        _userEmail = email;
        _phoneNumber = phoneNumber;
        _companyName = companyName;
        _tradingName = tradingName;
        _addressLine1 = addressLine1;
        _addressLine2 = addressLine2;
        _city = city;
        _state = state;
        _postalCode = postalCode;
        _profileImageUrl = profileImageUrl;
        _bankConfirmationUrl = bankConfirmationUrl;
        _cipcCertificateUrl = cipcCertificateUrl;
        _proxyUrl = proxyUrl;
        _brncUrl = brncUrl;
        notifyListeners();
      }

      print('User $userId details updated successfully.');
    } catch (e) {
      print('Error updating user details: $e');
      rethrow; // Rethrow to handle in UI
    }
  }

  // **New Method: Update User Account Status (Admin Only)**
  Future<void> updateUserAccountStatus(String userId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'accountStatus': newStatus});

      // If the updated user is the current user, update local status
      if (_user != null && _user!.uid == userId) {
        _accountStatus = newStatus;
        notifyListeners();
      }

      print('User $userId account status updated to $newStatus.');
    } catch (e) {
      print('Error updating user account status: $e');
      rethrow; // Rethrow to handle in UI
    }
  }

  // Add method to update verification status (admin only)
  Future<void> updateUserVerificationStatus(
      String userId, bool isVerified) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'isVerified': isVerified});

      if (_user?.uid == userId) {
        _isVerified = isVerified;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating verification status: $e');
      rethrow;
    }
  }

  // Getter methods
  User? get getUser => _user;
  String get getProfileImageUrl => _profileImageUrl ?? '';
  String get getUserRole => _userRole;
  List<String> get getPreferredBrands => _preferredBrands;
  List<String> get getOffers =>
      _userRole == 'transporter' ? _offersMade : _offers;
  String get getUserName => _userName;
  String get getUserEmail => _userEmail;
  String? get getPhoneNumber => _phoneNumber;
  bool get getIsLoading => _isLoading;
  String? get userId => _user?.uid;

  // Getters for user details
  String? get getCompanyName => _companyName;
  String? get getTradingName => _tradingName;
  String? get getRegistrationNumber => _registrationNumber;
  String? get getVatNumber => _vatNumber;
  String? get getAddressLine1 => _addressLine1;
  String? get getAddressLine2 => _addressLine2;
  String? get getCity => _city;
  String? get getState => _state;
  String? get getPostalCode => _postalCode;
  String? get getFirstName => _firstName;
  String? get getMiddleName => _middleName;
  String? get getLastName => _lastName;
  bool? get getAgreedToHouseRules => _agreedToHouseRules;
  String? get getBankConfirmationUrl => _bankConfirmationUrl;
  String? get getBrncUrl => _brncUrl;
  String? get getCipcCertificateUrl => _cipcCertificateUrl;
  String? get getProxyUrl => _proxyUrl;
  Timestamp? get getCreatedAt => _createdAt;

  // Getters for admin approval
  bool? get getAdminApproval => _adminApproval;
  String get userRole => _userRole;

  // Getter for saved inspection details
  List<InspectionDetail> get getSavedInspectionDetails =>
      _savedInspectionDetails;

  // Getters for liked and disliked vehicles
  List<String> get getLikedVehicles => _likedVehicles;
  List<String> get getDislikedVehicles => _dislikedVehicles;

  // Method to set the user
  void setUser(User? user) {
    print("DEBUG: Setting user in provider: ${user?.uid}");
    _user = user;
    notifyListeners();
    // Remove fetchUserData from here since it's handled by auth state listener
  }

  // New Method to Get User's Full Name by userId
  Future<String> getUserNameById(String userId) async {
    // Check if the userId exists in the cache
    if (_userNameCache.containsKey(userId)) {
      return _userNameCache[userId]!;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        String firstName = data['firstName'] ?? '';
        String lastName = data['lastName'] ?? '';
        String fullName = '$firstName $lastName'.trim();
        if (fullName.isEmpty) {
          fullName = 'Unknown User';
        }
        // Cache the result
        _userNameCache[userId] = fullName;
        return fullName;
      } else {
        // User document does not exist
        _userNameCache[userId] = 'Unknown User';
        return 'Unknown User';
      }
    } catch (e) {
      print('Error fetching user name for userId $userId: $e');
      _userNameCache[userId] = 'Unknown User';
      return 'Unknown User';
    }
  }

  // Add this getter
  User? get user => _user;

  Future<void> initializeStatusListener() async {
    if (_statusSubscription != null) return;

    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _statusSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        _accountStatus = snapshot.data()?['accountStatus'] ?? 'active';
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  // Add this method
  int getUserCount() {
    return _dealers.length;
  }

  // Add getter
  String? get getTaxCertificateUrl => _taxCertificateUrl;

  bool get hasCompletedRegistration {
    // Check if user has completed registration forms
    // by verifying required fields are present
    return _vatNumber != null &&
        !_vatNumber!.isEmpty &&
        _registrationNumber != null &&
        !_registrationNumber!.isEmpty;
  }
}

class Dealer {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? profileImageUrl;
  final String? companyName;
  final String? tradingName;
  final String? phoneNumber;
  final Timestamp? createdAt;

  Dealer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.profileImageUrl,
    this.companyName,
    this.tradingName,
    this.phoneNumber,
    this.createdAt,
  });

  factory Dealer.fromMap(Map<String, dynamic> data, String documentId) {
    return Dealer(
      id: documentId,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      companyName: data['companyName'],
      tradingName: data['tradingName'],
      phoneNumber: data['phoneNumber'],
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'companyName': companyName,
      'tradingName': tradingName,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt,
    };
  }
}
