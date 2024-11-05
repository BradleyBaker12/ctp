import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/custom_text_field.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/loading_screen.dart';
import 'package:ctp/components/progress_bar.dart';
import 'package:ctp/pages/crop_photo_page.dart';
import 'package:ctp/pages/dealer_reg.dart';
import 'package:ctp/pages/transporter_reg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'dart:convert';
import 'dart:io';

class SignUpFormPage extends StatefulWidget {
  const SignUpFormPage({super.key});

  @override
  _SignUpFormPageState createState() => _SignUpFormPageState();
}

class _SignUpFormPageState extends State<SignUpFormPage> {
  // Form controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // Form state
  int _currentStep = 0;
  bool _isLoading = false;
  String _selectedCountryCode = 'ZA +27';
  List<Map<String, dynamic>> _countryCodes = [];
  final String _errorMessage = '';
  String? _selectedProfileImage;
  final Set<String> selectedBrands = {};

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // Add these variables
  String? _verificationId;
  int? _resendToken;
  bool _codeSent = false;

  // Add trading category state
  String? _selectedTradingCategory;

  @override
  void initState() {
    super.initState();
    _loadCountryCodes();
    _phoneController.addListener(_formatPhoneNumber);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_formatPhoneNumber);
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // Validation methods
  bool _isEmailValid(String email) {
    final RegExp emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    bool isValid = emailRegExp.hasMatch(email);
    print('Email validation for $email: $isValid');
    return isValid;
  }

  bool _isPasswordValid(String password) {
    final RegExp passwordRegExp = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*?&\-])[A-Za-z\d@$!%*?&\-]{8,}$',
    );
    bool isValid = passwordRegExp.hasMatch(password);
    print('Password validation result: $isValid');
    return isValid;
  }

  Future<bool> _validatePhoneNumber(String phone) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length < 9) {
      _showError('Please enter a valid phone number');
      return false;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: _formatPhoneNumberForStorage(_phoneController.text),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on Android
          await _linkPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          _showError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _codeSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
      );

      return true;
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to verify phone number: $e');
      return false;
    }
  }

  Future<bool> _verifyOTP(String otp) async {
    if (_verificationId == null) return false;

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await _linkPhoneCredential(credential);
      return true;
    } catch (e) {
      _showError('Invalid OTP. Please try again.');
      return false;
    }
  }

  Future<void> _linkPhoneCredential(PhoneAuthCredential credential) async {
    try {
      await _auth.currentUser?.linkWithCredential(credential);
    } catch (e) {
      _showError('Failed to verify phone number: $e');
    }
  }

  // Continue to next step
  void _continue() async {
    if (_currentStep == 1 && _codeSent) {
      // Verify OTP before moving to next step
      if (await _verifyOTP(_otpController.text)) {
        setState(() => _currentStep++);
      }
      return;
    }

    print('Attempting to continue from step $_currentStep');
    bool canContinue = await _validateCurrentStep();
    print('Step $_currentStep validation result: $canContinue');

    if (canContinue) {
      // Special handling for different steps
      if (_currentStep == 3) {
        // After trading category selection
        setState(() {
          if (_selectedTradingCategory == 'dealer') {
            _currentStep = 5; // Dealers go to preferred brands
          } else {
            _currentStep = 4; // Transporters go directly to profile photo
          }
        });
      } else if (_currentStep == 5) {
        // After preferred brands, dealers go to profile photo
        setState(() {
          _currentStep = 4;
        });
      } else if (_currentStep == 4) {
        // Submit form after profile photo step
        _submitForm();
      } else {
        // Normal progression
        setState(() {
          _currentStep++;
        });
      }
      print('Moved to step $_currentStep');
    }
  }

  // Step validation
  Future<bool> _validateCurrentStep() async {
    switch (_currentStep) {
      case 0: // Email/Password
        return _validateCredentials();
      case 1: // Phone
        return _validatePhoneNumber(_phoneController.text);
      case 2: // First Name
        return _validateFirstName();
      case 3: // Trading Category
        return _validateTradingCategory();
      case 4: // Profile Photo
        return true; // Optional step
      case 5: // Preferred Brands
        return true; // Optional step
      default:
        return false;
    }
  }

  // Individual validation methods
  bool _validateCredentials() {
    if (!_isEmailValid(_emailController.text)) {
      _showError('Please enter a valid email address.');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return false;
    }
    if (!_isPasswordValid(_passwordController.text)) {
      _showError(
          'Password must be at least 8 characters long, include a number, and a special character.');
      return false;
    }
    return true;
  }

  bool _validateFirstName() {
    if (_firstNameController.text.trim().isEmpty) {
      _showError('Please enter your first name');
      return false;
    }
    return true;
  }

  // Add trading category validation
  bool _validateTradingCategory() {
    if (_selectedTradingCategory == null) {
      _showError('Please select a trading category');
      return false;
    }
    return true;
  }

  // Helper methods
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Form submission
  Future<void> _submitForm() async {
    print('Starting form submission...');
    setState(() {
      _isLoading = true;
    });

    try {
      print(
          'Attempting to create user account with email: ${_emailController.text}');
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      User? user = userCredential.user;
      if (user != null) {
        print('User created successfully with UID: ${user.uid}');

        // Prepare user data with all collected information
        Map<String, dynamic> userData = {
          'email': user.email,
          'phoneNumber': _formatPhoneNumberForStorage(_phoneController.text),
          'firstName': _firstNameController.text,
          'profileImageUrl': _selectedProfileImage ?? '',
          'userType': _selectedTradingCategory,
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Only add preferred brands for dealers
        if (_selectedTradingCategory == 'dealer' && selectedBrands.isNotEmpty) {
          userData['preferredBrands'] = selectedBrands.toList();
        }

        print('Saving user data: $userData');

        // Save user data
        await _firestore.collection('users').doc(user.uid).set(userData);
        print('User data saved successfully');

        // Update provider
        if (mounted) {
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);
          userProvider.setUser(user);
          await userProvider.fetchUserData();
          print('User provider updated');

          // Navigate to appropriate page based on user type
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => _selectedTradingCategory == 'dealer'
                  ? const DealerRegPage()
                  : const TransporterRegistrationPage(),
            ),
          );
        }
      }
    } catch (e) {
      print('Error during form submission: $e');
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Form submission completed');
    }
  }

  // Build methods for each step
  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildCredentialsStep();
      case 1:
        return _buildPhoneStep();
      case 2:
        return _buildFirstNameStep();
      case 3:
        return _buildTradingCategoryStep();
      case 4:
        return _buildProfilePhotoStep();
      case 5:
        return _buildPreferredBrandsStep();
      default:
        return Container();
    }
  }

  Future<void> _loadCountryCodes() async {
    final String response =
        await rootBundle.loadString('lib/assets/CountryCodes.json');
    final List<dynamic> data = json.decode(response);
    setState(() {
      _countryCodes = data
          .map((e) => {
                'name': e['name'] as String,
                'dial_code': e['dial_code'] as String,
                'code': e['code'] as String
              })
          .toList();
    });
  }

  void _formatPhoneNumber() {
    String text = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (text.isNotEmpty) {
      text = text.replaceAllMapped(RegExp(r'(\d{3})(\d{3})(\d+)'),
          (Match m) => '${m[1]} ${m[2]} ${m[3]}');
    }

    if (text != _phoneController.text) {
      _phoneController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  String _formatPhoneNumberForStorage(String phone) {
    String countryCode = _selectedCountryCode.split(' ').last;
    return '$countryCode${phone.replaceAll(RegExp(r'[^\d]'), '')}';
  }

  Widget _buildPreferredBrandsStep() {
    var screenSize = MediaQuery.of(context).size;
    var blue = const Color(0xFF2F7FFF);
    var isPortrait = screenSize.height > screenSize.width;

    // Define the same truck brands as in the PreferredBrandsPage
    final List<Map<String, dynamic>> semiTruckBrands = [
      {'name': 'ASHOK LEYLAND', 'path': 'lib/assets/Logo/ASHOK LEYLAND.png'},
      {'name': 'CNHTC', 'path': 'lib/assets/Logo/CNHTC.png'},
      {'name': 'DAF', 'path': 'lib/assets/Logo/DAF.png'},
      {'name': 'DAYUN', 'path': 'lib/assets/Logo/DAYUN.png'},
      {'name': 'EICHER', 'path': 'lib/assets/Logo/EICHER.png'},
      {'name': 'FAW', 'path': 'lib/assets/Logo/FAW.png'},
      {'name': 'FIAT', 'path': 'lib/assets/Logo/FIAT.png'},
      {'name': 'FORD', 'path': 'lib/assets/Logo/FORD.png'},
      {'name': 'FOTON', 'path': 'lib/assets/Logo/FOTON.png'},
      {
        'name': 'FREIGHTLINER',
        'path': 'lib/assets/Freightliner-logo-6000x2000.png'
      },
      {'name': 'FUSO', 'path': 'lib/assets/Logo/FUSO.png'},
      {'name': 'HINO', 'path': 'lib/assets/Logo/HINO.png'},
      {'name': 'HYUNDAI', 'path': 'lib/assets/Logo/HYUNDAI.png'},
      {'name': 'ISUZU', 'path': 'lib/assets/Logo/ISUZU.png'},
      {'name': 'IVECO', 'path': null},
      {'name': 'JAC', 'path': 'lib/assets/Logo/JAC.png'},
      {'name': 'JOYLONG', 'path': 'lib/assets/Logo/JOYLONG.png'},
      {'name': 'MAN', 'path': 'lib/assets/Logo/MAN.png'},
      {'name': 'MERCEDES-BENZ', 'path': 'lib/assets/Logo/MERCEDES BENZ.png'},
      {'name': 'PEUGEOT', 'path': 'lib/assets/Logo/PEUGEOT.png'},
      {'name': 'POWERSTAR', 'path': 'lib/assets/Logo/POWERSTAR.png'},
      {'name': 'RENAULT', 'path': 'lib/assets/Logo/RENAULT.png'},
      {'name': 'SCANIA', 'path': 'lib/assets/Logo/SCANIA.png'},
      {'name': 'TATA', 'path': 'lib/assets/Logo/TATA.png'},
      {'name': 'TOYOTA', 'path': 'lib/assets/Logo/TOYOTA.png'},
      {'name': 'UD TRUCKS', 'path': 'lib/assets/Logo/UD TRUCKS.png'},
      {'name': 'US TRUCKS', 'path': null},
      {'name': 'VOLVO', 'path': 'lib/assets/Logo/VOLVO.png'},
      {'name': 'VW', 'path': 'lib/assets/Logo/VW.png'},
    ];

    return Column(
      children: [
        SizedBox(height: screenSize.height * 0.024),
        Image.asset(
          'lib/assets/CTPLogo.png',
          height: screenSize.height * 0.2,
          width: screenSize.height * 0.2,
          fit: BoxFit.cover,
        ),
        SizedBox(height: screenSize.height * 0.03),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64.0),
          child: ProgressBar(progress: 0.80),
        ),
        SizedBox(height: screenSize.height * 0.06),
        Text(
          'PREFERRED BRANDS',
          style: GoogleFonts.montserrat(
            fontSize: screenSize.height * 0.022,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: screenSize.height * 0.04),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.only(
              left: screenSize.width * 0.01,
              right: screenSize.width * 0.01,
              bottom: screenSize.height * 0.05,
            ),
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isPortrait ? 3 : 5,
              crossAxisSpacing: screenSize.width * 0.02,
              mainAxisSpacing: screenSize.height * 0.015,
              childAspectRatio: isPortrait ? 1.1 : 1.1,
            ),
            itemCount: semiTruckBrands.length,
            itemBuilder: (BuildContext context, int index) {
              final brand = semiTruckBrands[index]['name']!;
              final path = semiTruckBrands[index]['path'];
              final isSelected = selectedBrands.contains(brand);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedBrands.remove(brand);
                    } else {
                      selectedBrands.add(brand);
                    }
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: screenSize.height * 0.008,
                    horizontal: screenSize.width * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? blue.withOpacity(0.8)
                        : blue.withOpacity(0.3),
                    border: Border.all(color: blue),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: path != null
                            ? Image.asset(
                                path,
                                fit: BoxFit.contain,
                              )
                            : Icon(
                                Icons.local_shipping,
                                size: screenSize.height * 0.04,
                                color: Colors.white,
                              ),
                      ),
                      SizedBox(height: screenSize.height * 0.008),
                      Text(
                        brand,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: screenSize.height * 0.012,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePhotoStep() {
    var blue = const Color(0xFF2F7FFF);
    var screenSize = MediaQuery.of(context).size;

    return Container(
      width: screenSize.width,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          SizedBox(height: screenSize.height * 0.05),
          // Show either the selected image or the logo
          if (_selectedProfileImage != null)
            Container(
              height: screenSize.height * 0.2,
              width: screenSize.height * 0.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: blue, width: 2),
                image: DecorationImage(
                  image: FileImage(File(_selectedProfileImage!)),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Image.asset(
              'lib/assets/CTPLogo.png',
              height: screenSize.height * 0.2,
            ),
          SizedBox(height: screenSize.height * 0.1),
          Text(
            _selectedProfileImage != null
                ? 'CHANGE PROFILE PHOTO'
                : 'ADD A PROFILE PHOTO',
            style: GoogleFonts.montserrat(
              fontSize: screenSize.height * 0.028,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenSize.height * 0.12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPhotoOption(Icons.camera_alt, 'CAMERA', ImageSource.camera),
              SizedBox(width: screenSize.width * 0.2),
              _buildPhotoOption(
                  Icons.photo_library, 'GALLERY', ImageSource.gallery),
            ],
          ),
          SizedBox(height: screenSize.height * 0.08),
          TextButton(
            onPressed: () => _continue(),
            child: Text(
              'UPLOAD LATER',
              style: GoogleFonts.montserrat(
                fontSize: screenSize.height * 0.018,
                color: Colors.white,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoOption(IconData icon, String label, ImageSource source) {
    var blue = const Color(0xFF2F7FFF);
    var screenSize = MediaQuery.of(context).size;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: blue, width: 2.0),
            color: blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: IconButton(
            icon: Padding(
              padding: EdgeInsets.all(screenSize.height * 0.008),
              child: Icon(
                icon,
                size: screenSize.height * 0.05,
                color: Colors.white,
              ),
            ),
            onPressed: () async {
              print('Attempting to pick image from $source');
              try {
                // Set loading state
                setState(() => _isLoading = true);

                // Pick image
                final XFile? image = await _picker.pickImage(
                  source: source,
                  imageQuality: 70,
                );

                if (image == null) {
                  print('No image selected');
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                  return;
                }

                print('Image selected: ${image.path}');

                if (!mounted) return;

                // Navigate to CropPhotoPage and wait for result
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CropPhotoPage(
                      imageFile: image,
                      userData: {
                        'email': _emailController.text,
                        'phoneNumber':
                            _formatPhoneNumberForStorage(_phoneController.text),
                        'firstName': _firstNameController.text,
                        'userType': _selectedTradingCategory,
                        'createdAt': FieldValue.serverTimestamp(),
                        'preferredBrands': _selectedTradingCategory == 'dealer'
                            ? selectedBrands.toList()
                            : null,
                      },
                    ),
                  ),
                );

                if (!mounted) return;

                // Handle the result
                if (result != null && result is String) {
                  print('Cropped image path received: $result');
                  setState(() {
                    _selectedProfileImage = result;
                    _isLoading = false;
                  });

                  // Only continue if we have a valid image path
                  if (_selectedProfileImage != null &&
                      _selectedProfileImage!.isNotEmpty) {
                    _continue();
                  } else {
                    _showError('Invalid image path received');
                  }
                } else {
                  print('No valid result received from crop page');
                  setState(() => _isLoading = false);
                  _showError('Failed to process image');
                }
              } catch (e, stackTrace) {
                print('Error during image processing: $e');
                print('Stack trace: $stackTrace');
                if (mounted) {
                  setState(() => _isLoading = false);
                  _showError('Failed to process image: ${e.toString()}');
                }
              }
            },
          ),
        ),
        SizedBox(height: screenSize.height * 0.02),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 24,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFirstNameStep() {
    var blue = const Color(0xFF2F7FFF);
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          SizedBox(height: screenHeight * 0.05),
          Image.asset(
            'lib/assets/CTPLogo.png',
            height: screenHeight * 0.2,
          ),
          SizedBox(height: screenHeight * 0.08),
          Text(
            'MY FIRST NAME IS',
            style: GoogleFonts.montserrat(
              fontSize: screenHeight * 0.028,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          SizedBox(height: screenHeight * 0.05),
          TextField(
            controller: _firstNameController,
            textAlign: TextAlign.center,
            cursorColor: const Color(0xFFFF4E00),
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: screenHeight * 0.02,
            ),
            decoration: InputDecoration(
              hintStyle: GoogleFonts.montserrat(
                color: Colors.white.withOpacity(0.7),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: blue),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: blue),
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.04),
          Text(
            'This is the name that will appear to other users in the app',
            style: GoogleFonts.montserrat(
              fontSize: screenHeight * 0.015,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneStep() {
    var blue = const Color(0xFF2F7FFF);
    var orange = const Color(0xFFFF4E00);

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Image.asset(
            'lib/assets/CTPLogo.png',
            height: MediaQuery.of(context).size.height * 0.2,
          ),
          const SizedBox(height: 60),
          Text(
            'MY NUMBER IS',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 50),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                  width: 90,
                  child: DropdownButtonFormField<String>(
                    value: _selectedCountryCode,
                    icon:
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                    iconSize: 18,
                    elevation: 16,
                    style: GoogleFonts.montserrat(
                        fontSize: 14, color: Colors.white),
                    dropdownColor: Colors.black,
                    decoration: InputDecoration(
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: blue),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: blue),
                      ),
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCountryCode = newValue!;
                      });
                    },
                    items: _countryCodes.map<DropdownMenuItem<String>>(
                        (Map<String, dynamic> value) {
                      return DropdownMenuItem<String>(
                        value: '${value['code']} ${value['dial_code']}',
                        child: Center(
                          child: Text(
                            '${value['code']} ${value['dial_code']}',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }).toList()
                      ..sort(
                          (a, b) => (a.value ?? '').compareTo(b.value ?? '')),
                  )),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  cursorColor: orange,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.montserrat(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '00 000 0000',
                    hintStyle: GoogleFonts.montserrat(
                      color: Colors.white.withOpacity(0.7),
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: blue),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: blue),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 16.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_codeSent) ...[
            const SizedBox(height: 30),
            CustomTextField(
              controller: _otpController,
              hintText: 'Enter OTP',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
          const SizedBox(height: 40),
          Text(
            _codeSent
                ? 'Enter the verification code sent to your phone.'
                : 'We will send you a text with a verification code. Message and data rates may apply.',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsStep() {
    const orange = Color(0xFFFF4E00);

    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Text(
            'WELCOME TO',
            style: GoogleFonts.montserrat(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: orange,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Image.asset(
            'lib/assets/CTPLogo.png',
            height: MediaQuery.of(context).size.height * 0.2,
          ),
          const SizedBox(height: 60),
          Text(
            'SIGN-UP',
            style: GoogleFonts.montserrat(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),
          CustomTextField(
            controller: _emailController,
            hintText: 'USERNAME OR EMAIL',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 30),
          CustomTextField(
            controller: _passwordController,
            hintText: 'PASSWORD',
            obscureText: true,
          ),
          const SizedBox(height: 30),
          CustomTextField(
            controller: _confirmPasswordController,
            hintText: 'CONFIRM PASSWORD',
            obscureText: true,
          ),
        ],
      ),
    );
  }

  // Add trading category step
  Widget _buildTradingCategoryStep() {
    var screenSize = MediaQuery.of(context).size;
    var blue = const Color(0xFF2F7FFF);
    var orange = const Color(0xFFFF4E00);

    return Container(
      width: screenSize.width,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          SizedBox(height: screenSize.height * 0.02),
          Image.asset(
            'lib/assets/CTPLogo.png',
            height: screenSize.height * 0.2,
          ),
          SizedBox(height: screenSize.height * 0.15),
          Text(
            'Welcome to CTP where trading trucks and trailers is made easy!',
            style: GoogleFonts.montserrat(
              fontSize: screenSize.height * 0.02,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Please select your trading category:',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Transporters are users who sell trucks.\nDealers are users who buy trucks.',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),
          CustomButton(
            text: 'TRANSPORTER',
            borderColor: blue,
            onPressed: () {
              setState(() {
                _selectedTradingCategory = 'transporter';
              });
              _continue();
            },
          ),
          CustomButton(
            text: 'DEALER',
            borderColor: orange,
            onPressed: () {
              setState(() {
                _selectedTradingCategory = 'dealer';
              });
              _continue();
            },
          ),
        ],
      ),
    );
  }

  // Update the back navigation logic
  void _back() {
    if (_currentStep > 0) {
      setState(() {
        if (_currentStep == 4) {
          // If coming back from profile photo
          if (_selectedTradingCategory == 'dealer') {
            _currentStep = 5; // Dealers go back to preferred brands
          } else {
            _currentStep = 3; // Transporters go back to trading category
          }
        } else {
          _currentStep--;
        }
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFFF4E00);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BlurryAppBar(
          // Add leading back button
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _back,
          ),
        ),
        body: _isLoading
            ? const LoadingScreen()
            : SafeArea(
                child: Column(
                  children: [
                    ProgressBar(
                      progress: _currentStep / 5,
                    ),
                    Expanded(
                      child: _buildCurrentStep(),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 20.0,
                        left: 16.0,
                        right: 16.0,
                      ),
                      child: CustomButton(
                        onPressed: _continue,
                        text: _currentStep == 5 ? 'Submit' : 'Continue',
                        borderColor: orange,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
