import 'package:flutter/material.dart';

class SignInButton extends StatelessWidget {
  final String text;
  final Color borderColor;
  final VoidCallback onPressed;

  const SignInButton({super.key, 
    required this.text,
    required this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.9, // 90% of the available width
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0), // Reduced vertical margin
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            foregroundColor: borderColor,
            backgroundColor: borderColor.withOpacity(0.25), // Text color
            padding:
                const EdgeInsets.symmetric(vertical: 15.0), // Padding inside button
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5), // Square corners
              side: BorderSide(color: borderColor), // Border color
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Text color
            ),
          ),
        ),
      ),
    );
  }
}
