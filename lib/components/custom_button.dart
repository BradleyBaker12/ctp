import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final Color borderColor;
  final VoidCallback? onPressed; // Make this nullable

  const CustomButton({
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
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: borderColor.withOpacity(
                0.17), // Adjust opacity for disabled state if needed
            padding: const EdgeInsets.symmetric(
                vertical: 15.0), // Padding inside button
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0), // Rounded corners
              side: BorderSide(color: borderColor), // Border color
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white, // Text color
            ),
          ),
        ),
      ),
    );
  }
}
