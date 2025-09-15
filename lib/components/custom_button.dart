import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final Color borderColor;
  final bool? isLoading;
  final VoidCallback? onPressed; // Nullable enables disabled state

  const CustomButton({
    super.key,
    required this.text,
    required this.borderColor,
    required this.onPressed,
    this.isLoading = false,
    MaterialColor disabledColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    var loading = isLoading ?? false;
    return FractionallySizedBox(
      widthFactor: 1, // 90% of the available width
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: ElevatedButton(
          // Disabled when loading or onPressed is null
          onPressed: (loading || onPressed == null) ? null : onPressed,
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: borderColor.withOpacity(0.17),
            padding:
                EdgeInsets.symmetric(vertical: 15.0), // Padding inside button
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0), // Rounded corners
              side: BorderSide(color: borderColor), // Border color
            ),
          ),
          child: loading
              ? Transform.scale(
                  scale: 0.8,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.blue),
                  ),
                )
              : Center(
                  child: Text(
                    text,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white, // Text color
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
      ),
    );
  }
}
