import 'package:ctp/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/loading_screen.dart';
import 'package:ctp/components/progress_bar.dart';
import 'package:provider/provider.dart';

class FirstNamePage extends StatefulWidget {
  const FirstNamePage({super.key});

  @override
  _FirstNamePageState createState() => _FirstNamePageState();
}

class _FirstNamePageState extends State<FirstNamePage> {
  final TextEditingController _firstNameController = TextEditingController();
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _saveFirstName(String userId, String firstName) async {
    if (userId.isNotEmpty) {
      final userDoc = _firestore.collection('users').doc(userId);

      try {
        // Check if the document exists
        DocumentSnapshot docSnapshot = await userDoc.get();
        if (!docSnapshot.exists) {
          print('FirstNamePage: Document does not exist for userId: $userId');
          throw Exception('Document does not exist');
        }

        await userDoc.update({'firstName': firstName});
        print('FirstNamePage: First name saved for UID: $userId'); // Debugging
      } catch (e) {
        print('FirstNamePage: Error updating first name: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save first name. Please try again.')),
        );
      }
    } else {
      print('FirstNamePage: User ID is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID is not available.')),
      );
    }
  }

  void _continue() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String? userId = userProvider.userId;

    print('FirstNamePage: Current User UID: $userId'); // Debugging

    if (userId == null) {
      print('FirstNamePage: User ID is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID is not available.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    String firstName = _firstNameController.text.trim();

    if (firstName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your first name')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    await _saveFirstName(userId, firstName);
    setState(() {
      _isLoading = false;
    });

    // Navigate to the next page
    Navigator.pushNamed(context, '/tradingCategory');
  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var blue = const Color(0xFF2F7FFF);
    var orange = const Color(0xFFFF4E00);

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
                              const SizedBox(height: 50),
                              const ProgressBar(progress: 0.30),
                              const SizedBox(height: 30),
                              const Text(
                                'MY FIRST NAME IS',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _firstNameController,
                                textAlign: TextAlign.center,
                                cursorColor: orange,
                                decoration: InputDecoration(
                                  hintText: '',
                                  hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.7)),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: blue),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: blue),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16.0, horizontal: 16.0),
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'This is the name that will appear to other users in the app',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () {
                                  // Handle name changes approval info
                                },
                                child: const Text(
                                  'Name changes will have to be approved',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 150),
                              CustomButton(
                                text: 'CONTINUE',
                                borderColor: blue,
                                onPressed: _continue,
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                        const Positioned(
                          top: 40,
                          left: 16,
                          child: CustomBackButton(),
                        ),
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
