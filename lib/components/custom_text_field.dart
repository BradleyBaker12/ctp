import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController? controller;

  const CustomTextField({super.key, 
    required this.hintText,
    this.obscureText = false,
    this.controller,
  });

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    var orange = const Color(0xFFFF4E00);
    return Container(
      decoration: BoxDecoration(
        color: Colors.black
            .withOpacity(0.1), // Background color for the text input
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: TextField(
        controller: widget.controller,
        cursorColor: orange,
        decoration: InputDecoration(
          hintText: widget.hintText,
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
            borderSide: const BorderSide(color: Colors.white),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  onPressed: _toggleObscureText,
                )
              : null,
        ),
        style: const TextStyle(color: Colors.white),
        obscureText: _obscureText,
      ),
    );
  }
}
