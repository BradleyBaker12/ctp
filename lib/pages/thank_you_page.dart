import 'package:ctp/components/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';

import 'package:auto_route/auto_route.dart';
@RoutePage()class ThankYouPage extends StatelessWidget {
  const ThankYouPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 150,
              ),
              Image.asset('lib/assets/CTPLogo.png', height: 200),
              const SizedBox(height: 20),
              const Text(
                'Thank You',
                style: TextStyle(
                  color: Color(0xFFFF4E00),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We Value Our Customer Experience',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Thank you for reporting your issue and making the CTP app a safer and honest platform for other users. We hope this experience does not impact your decision to use the app in the future.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CustomButton(
                    text: "Done",
                    borderColor: Color(0xFF2F7FFF),
                    onPressed: () {
                      Navigator.pushNamed(context, '/home');
                    }),
              )
            ],
          ),
        ),
      ),
    );
  }
}             