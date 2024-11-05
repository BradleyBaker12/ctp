// custom_dropdown.dart
import 'package:ctp/components/constants.dart';
import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final String hintText;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;

  const CustomDropdown({
    super.key,
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3), // Gray background
        border: Border(
          left: BorderSide(
            color: Colors.white.withOpacity(0.5), // Left border color
            width: 1.0, // Left border width
          ),
          right: BorderSide(
            color: Colors.white.withOpacity(0.5), // Right border color
            width: 1.0, // Right border width
          ),
        ),
        borderRadius: BorderRadius.circular(0.0), // Sharp corners
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 8.0), // Horizontal padding
      height: 60.0, // Fixed height for square-like appearance
      child: DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white70),
          filled: false, // No fill color
          border: InputBorder.none, // No borders
          contentPadding: EdgeInsets.zero, // No padding
        ),
        style: const TextStyle(color: Colors.white),
        dropdownColor:
            Colors.grey.withOpacity(0.8), // Dropdown background color
        items: items
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              ),
            )
            .toList(),
        icon: const Icon(
          Icons.arrow_drop_down,
          color: Colors.white,
        ),
      ),
    );
  }
}
