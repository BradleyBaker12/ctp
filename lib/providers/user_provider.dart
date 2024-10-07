import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/models/inspection_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  List<String> _preferredBrands = [];
  String _userRole = 'guest'; // Default role
  String? _profileImageUrl;
  List<String> _offers = [];
  List<String> _offersMade = [];
  List<String> _likedVehicles = [];
  List<String> _dislikedVehicles = [];
  String _userName = 'Guest';
  String _userEmail = 'user@example.com';
  bool _isLoading = true;

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

  // Add saved inspection details
  List<InspectionDetail> _savedInspectionDetails = [];

  UserProvider() {
    _checkAuthState();
    FirebaseAuth.instance.authStateChanges().listen((User? newUser) {
      if (newUser != null) {
        _user = newUser;
        fetchUserData();
      } else {
        _clearUserData();
      }
    });
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
    try {
      if (_user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .get();
        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          _preferredBrands = List<String>.from(data['preferredBrands'] ?? []);
          _userRole = data['userRole'] ?? 'guest';
          _profileImageUrl = data['profileImageUrl'];
          _offers = List<String>.from(data['offers'] ?? []);
          _offersMade = List<String>.from(data['offersMade'] ?? []);
          _likedVehicles = List<String>.from(data['likedVehicles'] ?? []);
          _dislikedVehicles = List<String>.from(data['dislikedVehicles'] ?? []);
          _userName = data['firstName'] ?? 'Guest';
          _userEmail = data['email'] ?? 'user@example.com';
          _companyName = data['companyName'];
          _tradingName = data['tradingName'];
          _registrationNumber = data['registrationNumber'];
          _vatNumber = data['vatNumber'];
          _addressLine1 = data['addressLine1'];
          _addressLine2 = data['addressLine2'];
          _city = data['city'];
          _state = data['state'];
          _postalCode = data['postalCode'];
          _firstName = data['firstName'];
          _middleName = data['middleName'];
          _lastName = data['lastName'];
          _phoneNumber = data['phoneNumber'];
          _agreedToHouseRules = data['agreedToHouseRules'];
          _bankConfirmationUrl = data['bankConfirmationUrl'];
          _brncUrl = data['brncUrl'];
          _cipcCertificateUrl = data['cipcCertificateUrl'];
          _proxyUrl = data['proxyUrl'];
          _createdAt = data['createdAt'];
          _isLoading = false;

          // Fetch saved inspection details
          _savedInspectionDetails = [];
          if (data['savedInspectionDetails'] != null) {
            _savedInspectionDetails = (data['savedInspectionDetails'] as List)
                .map((item) =>
                    InspectionDetail.fromMap(Map<String, dynamic>.from(item)))
                .toList();
          }

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

  Future<String> uploadFile(File file) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_images/${_user!.uid}/${file.path.split('/').last}');
    final uploadTask = storageRef.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    _clearUserData();
  }

  void _clearUserData() {
    _preferredBrands = [];
    _userRole = 'guest';
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
    _isLoading = false;
    notifyListeners();
  }

  Future<void> likeVehicle(String vehicleId) async {
    if (_user != null) {
      if (!_likedVehicles.contains(vehicleId)) {
        _likedVehicles.add(vehicleId);
        print('Adding vehicleId: $vehicleId to likedVehicles list');

        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .update({'likedVehicles': _likedVehicles});
          print('Updated likedVehicles in Firestore successfully');
          notifyListeners();
        } catch (e) {
          print('Error updating likedVehicles in Firestore: $e');
        }
      } else {
        print('VehicleId: $vehicleId already in likedVehicles list');
      }
    } else {
      print('User is not authenticated');
    }
  }

  Future<void> dislikeVehicle(String vehicleId) async {
    if (_user != null) {
      if (!_dislikedVehicles.contains(vehicleId)) {
        _dislikedVehicles.add(vehicleId);
        print('Adding vehicleId: $vehicleId to dislikedVehicles list');

        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .update({
            'dislikedVehicles': FieldValue.arrayUnion([vehicleId]),
          });
          print('Updated dislikedVehicles in Firestore successfully');
          notifyListeners();
        } catch (e) {
          print('Error updating dislikedVehicles in Firestore: $e');
        }
      } else {
        print('VehicleId: $vehicleId already in dislikedVehicles list');
      }
    } else {
      print('User is not authenticated');
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

  Future<void> removeLikedVehicle(String vehicleId) async {
    if (_user != null) {
      if (_likedVehicles.contains(vehicleId)) {
        _likedVehicles.remove(vehicleId);
        print('Removing vehicleId: $vehicleId from likedVehicles list');

        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .update({'likedVehicles': _likedVehicles});
          print('Updated likedVehicles in Firestore successfully');
          notifyListeners();
        } catch (e) {
          print('Error updating likedVehicles in Firestore: $e');
        }
      } else {
        print('VehicleId: $vehicleId not found in likedVehicles list');
      }
    } else {
      print('User is not authenticated');
    }
  }

  Future<void> removeDislikedVehicle(String vehicleId) async {
    if (_user != null) {
      if (_dislikedVehicles.contains(vehicleId)) {
        _dislikedVehicles.remove(vehicleId);
        print('Removing vehicleId: $vehicleId from dislikedVehicles list');

        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .update({'dislikedVehicles': _dislikedVehicles});
          print('Updated dislikedVehicles in Firestore successfully');
          notifyListeners();
        } catch (e) {
          print('Error updating dislikedVehicles in Firestore: $e');
        }
      } else {
        print('VehicleId: $vehicleId not found in dislikedVehicles list');
      }
    } else {
      print('User is not authenticated');
    }
  }

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

  // Add method to save an inspection detail
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

  // Getter for saved inspection details
  List<InspectionDetail> get getSavedInspectionDetails =>
      _savedInspectionDetails;

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

  // Add the userId getter
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

  // Add a method to set the user
  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  // Getters for liked and disliked vehicles
  List<String> get getLikedVehicles => _likedVehicles;
  List<String> get getDislikedVehicles => _dislikedVehicles;
}
