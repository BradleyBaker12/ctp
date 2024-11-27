import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/loading_screen.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:provider/provider.dart';

class PhoneNumberPage extends StatefulWidget {
  const PhoneNumberPage({super.key});

  @override
  _PhoneNumberPageState createState() => _PhoneNumberPageState();
}

class _PhoneNumberPageState extends State<PhoneNumberPage> {
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountryCode = 'ZA +27';
  List<Map<String, dynamic>> _countryCodes = [];
  String _errorMessage = '';
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  void initState() {
    super.initState();
    print("DEBUG: PhoneNumberPage initState");
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    print("DEBUG: Current user ID: ${userProvider.userId}");
    print("DEBUG: Current user role: ${userProvider.getUserRole}");
  
    if (userProvider.userId == null) {
      print("DEBUG: No user ID found, redirecting to login");
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _phoneController.removeListener(_formatPhoneNumber);
    _phoneController.dispose();
    super.dispose();
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
    String text = _phoneController.text.replaceAll(RegExp(r'\s+'), '');
    TextSelection selection = _phoneController.selection;

    // Format only if necessary to avoid unnecessary updates
    if (text.length > 3) {
      final buffer = StringBuffer();
      for (int i = 0; i < text.length; i++) {
        buffer.write(text[i]);
        if (i == 2 || i == 5) {
          buffer.write(' '); // Adds a space after the 3rd and 6th digits
        }
      }

      String formattedText = buffer.toString();

      // Only update if the formatted text is different from the current text
      if (_phoneController.text != formattedText) {
        int newCursorPosition = selection.baseOffset;

        // Adjust the cursor position based on the added spaces
        if (newCursorPosition > 2) newCursorPosition += 1;
        if (newCursorPosition > 5) newCursorPosition += 1;

        _phoneController.value = TextEditingValue(
          text: formattedText,
          selection: TextSelection.collapsed(offset: newCursorPosition),
        );
      }
    }
  }

  bool _validatePhoneNumber(String phoneNumber) {
    final RegExp regex = RegExp(r'^\d+$');
    final String cleanedNumber = phoneNumber.replaceAll(' ', '');

    if (!regex.hasMatch(cleanedNumber)) {
      setState(() {
        _errorMessage = 'Number format is incorrect. Only digits are allowed.';
      });
      return false;
    }
    if (cleanedNumber.length == 10 && cleanedNumber.startsWith('0')) {
      setState(() {
        _errorMessage = '';
      });
      return true;
    }
    if (cleanedNumber.length == 9) {
      setState(() {
        _errorMessage = '';
      });
      return true;
    }
    setState(() {
      _errorMessage =
          'Number format is incorrect. Please enter a valid number.';
    });
    return false;
  }

  Future<void> _savePhoneNumber(String userId, String formattedNumber) async {
    if (userId.isNotEmpty) {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'phoneNumber': formattedNumber});
      print(
          'PhoneNumberPage: Phone number saved for UID: $userId'); // Debugging
    }
  }

  void _continue() async {
    setState(() {
      _isLoading = true;
    });

    final String userId =
        Provider.of<UserProvider>(context, listen: false).userId!;
    print('PhoneNumberPage: Current User UID: $userId'); // Debugging

    final String phoneNumber = _phoneController.text.replaceAll(' ', '');
    if (!_validatePhoneNumber(phoneNumber)) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    String formattedNumber = phoneNumber;
    String dialCode = _selectedCountryCode.split(' ').last;

    if (phoneNumber.length == 10 && phoneNumber.startsWith('0')) {
      formattedNumber = phoneNumber.substring(1);
    }

    formattedNumber = '$dialCode$formattedNumber';
    await _savePhoneNumber(userId, formattedNumber);

    // Start phone number verification with reCAPTCHA in the background
    await _auth.verifyPhoneNumber(
      phoneNumber: formattedNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.currentUser!.linkWithCredential(credential);
        Navigator.pushReplacementNamed(context, '/firstName');
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Verification failed. Please try again.";
        });
      },
      codeSent: (String verificationId, int? forceResendingToken) {
        setState(() {
          _isLoading = false;
        });
        Navigator.pushNamed(context, '/otp', arguments: {
          'verificationId': verificationId,
          'phoneNumber': formattedNumber,
          'userId': userId
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() {
          _isLoading = false;
        });
      },
      timeout: const Duration(seconds: 60),
      forceResendingToken: null,
    );

    setState(() {
      _isLoading = false;
    });
    print('Phone Number: $formattedNumber');
  }

  void _skip() {
    Navigator.pushNamed(context, "/firstName");
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var orange = const Color(0xFFFF4E00);
    var blue = const Color(0xFF2F7FFF);

    return Scaffold(
      body: Stack(
        children: [
          GradientBackground(
            child: Column(
              children: [
                const BlurryAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Stack(
                      children: [
                        Container(
                          width: screenSize.width,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              Image.asset('lib/assets/CTPLogo.png',
                                  height: 200), // Adjust the height as needed
                              const SizedBox(height: 100),
                              Text(
                                'MY NUMBER IS',
                                style: GoogleFonts.montserrat(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    width:
                                        90, // Adjust width to make it smaller
                                    child: Column(
                                      children: [
                                        Center(
                                          child:
                                              DropdownButtonFormField<String>(
                                            value: _selectedCountryCode,
                                            icon: const Icon(
                                                Icons.arrow_drop_down,
                                                color: Colors.white),
                                            iconSize: 18, // Smaller icon size
                                            elevation: 16,
                                            style: GoogleFonts.montserrat(
                                                fontSize: screenSize.height *
                                                    0.02, // Change font size here
                                                color: Colors.white),
                                            dropdownColor: Colors.black,
                                            decoration: InputDecoration(
                                              enabledBorder:
                                                  UnderlineInputBorder(
                                                borderSide:
                                                    BorderSide(color: blue),
                                              ),
                                              focusedBorder:
                                                  UnderlineInputBorder(
                                                borderSide:
                                                    BorderSide(color: blue),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                vertical:
                                                    16.0, // Adjust padding to match the TextField
                                              ),
                                            ),
                                            alignment: Alignment
                                                .center, // Center the text and icon
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                _selectedCountryCode =
                                                    newValue!;
                                              });
                                            },
                                            items: _countryCodes.map<
                                                    DropdownMenuItem<String>>(
                                                (Map<String, dynamic> value) {
                                              return DropdownMenuItem<String>(
                                                value:
                                                    '${value['code']} ${value['dial_code']}',
                                                child: Center(
                                                  child: Text(
                                                      '${value['code']} ${value['dial_code']}',
                                                      style: GoogleFonts
                                                          .montserrat(
                                                              fontSize:
                                                                  14, // Adjust dropdown text font size here
                                                              color: Colors
                                                                  .white)),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  SizedBox(
                                    width: screenSize.width *
                                        0.45, // Adjust the width of the phone number input
                                    child: TextField(
                                      cursorColor: orange,
                                      controller: _phoneController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly
                                      ],
                                      decoration: InputDecoration(
                                        hintText: '00 000 0000',
                                        hintStyle: GoogleFonts.montserrat(
                                            color:
                                                Colors.white.withOpacity(0.7)),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: blue),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: blue),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 16.0,
                                                horizontal: 16.0),
                                      ),
                                      style: GoogleFonts.montserrat(
                                          color: Colors.white),
                                      onChanged: (value) {
                                        if (_errorMessage.isNotEmpty) {
                                          setState(() {
                                            _errorMessage = '';
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              if (_errorMessage.isNotEmpty)
                                Text(
                                  _errorMessage,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    color: Colors.red,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: 300,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Text(
                                    'We will send you a text with a verification code. Message and data rates may apply.',
                                    style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.7),
                                        fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.justify,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 150),
                              CustomButton(
                                text: 'CONTINUE',
                                borderColor: blue,
                                onPressed: _continue,
                              ),
                              CustomButton(
                                text: 'SKIP',
                                borderColor: orange,
                                onPressed: _skip,
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                        // const Positioned(
                        //     top: 40, left: 16, child: CustomBackButton()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) const LoadingScreen()
        ],
      ),
    );
  }
}
