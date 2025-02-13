import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final Function(bool)? onFocusChange;
  final Function(String)? onChanged; // Add this line

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.suffixIcon,
    this.onFocusChange,
    this.onChanged, // Add this line
  });

  @override
  Widget build(BuildContext context) {
    var orange = const Color(0xFFFF4E00);

    return Focus(
      onFocusChange: onFocusChange,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey
              .withOpacity(0.18), // Background color for the text input
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: TextField(
          controller: controller,
          cursorColor: orange,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            filled: true,
            fillColor: Colors.transparent, // Keep the fillColor transparent
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.white),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(color: Colors.white),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide:
                  BorderSide(color: orange), // Orange border when focused
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            suffixIcon:
                suffixIcon, // Replace the existing suffixIcon logic with this
          ),
          style: const TextStyle(color: Colors.white),
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged, // Add this line
        ),
      ),
    );
  }

  void _toggleObscureText() {
    // Implement your logic here to toggle the obscureText state
  }
}
