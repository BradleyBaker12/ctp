import 'package:flutter/material.dart';
import 'package:ctp/components/blurry_app_bar.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_back_button.dart';
import 'package:ctp/components/loading_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';

class HouseRulesPage extends StatefulWidget {
  const HouseRulesPage({super.key});

  @override
  _HouseRulesPageState createState() => _HouseRulesPageState();
}

class _HouseRulesPageState extends State<HouseRulesPage> {
  bool _isLoading = false;

  Future<void> _handleAgree(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    final String userId =
        Provider.of<UserProvider>(context, listen: false).userId!;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    await firestore.collection('users').doc(userId).update({
      'agreedToHouseRules': true,
    });

    setState(() {
      _isLoading = false;
    });

    Navigator.pushReplacementNamed(context, '/tradingInterests');
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
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),
                              const Text(
                                'WELCOME TO',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Image.asset('lib/assets/CTPLogo.png',
                                  height: 200), // Adjust the height as needed
                              const SizedBox(height: 50),
                              const Text(
                                'Please follow these House Rules',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Be Yourself,',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: orange,
                                      ),
                                    ),
                                    const TextSpan(
                                      text:
                                          '\nMake sure your details are accurate to ensure the approval of your trading application.\n\n',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Stay Safe,',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: orange,
                                      ),
                                    ),
                                    const TextSpan(
                                      text:
                                          '\nUse strong passwords and avoid sharing personal information.\n\n',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Play it cool.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: orange,
                                      ),
                                    ),
                                    const TextSpan(
                                      text:
                                          '\nRespect others and treat them how you want to be treated.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 50),
                              CustomButton(
                                text: 'I AGREE',
                                borderColor: blue,
                                onPressed: () => _handleAgree(context),
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
