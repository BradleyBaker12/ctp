import 'package:flutter/material.dart';

class CustomRadioButton extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final Function(String?) onChanged;
  final Color selectedColor;
  final Color unselectedColor;
  final Color textColor;
  final bool enabled; // Add this parameter

  const CustomRadioButton({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.selectedColor = const Color(0xFFFF4E00),
    this.unselectedColor = Colors.transparent,
    this.textColor = Colors.white,
    this.enabled = true, // Default to true
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = groupValue == value;

    return InkWell(
      onTap:
          enabled ? () => onChanged(value) : null, // Only allow tap if enabled
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          border: Border.all(
            color: isSelected ? selectedColor : Colors.white54,
            width: 2.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Text(
          label,
          style: TextStyle(
            color: enabled
                ? (isSelected ? Colors.white : textColor)
                : Colors.grey, // Grey out text when disabled
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
