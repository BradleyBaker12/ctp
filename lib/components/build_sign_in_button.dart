import 'package:flutter/material.dart';

class SignInButton extends StatelessWidget {
  final String text;
  final Color borderColor;
  final VoidCallback onPressed;

  const SignInButton({
    super.key,
    required this.text,
    required this.borderColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 1, // 90% of the available width
      child: Container(
        margin: const EdgeInsets.symmetric(
            vertical: 4.0), // Reduced vertical margin
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            foregroundColor: borderColor,
            backgroundColor: borderColor.withOpacity(0.17), // Text color
            padding: const EdgeInsets.symmetric(
                vertical: 15.0), // Padding inside button
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5), // Square corners
              side: BorderSide(color: borderColor), // Border color
            ),
          ),
          child: Text(
            text.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white, // Text color
            ),
          ),
        ),
      ),
    );
  }
}
