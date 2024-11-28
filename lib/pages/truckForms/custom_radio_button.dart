// custom_radio_button.dart
import 'package:ctp/components/constants.dart';
import 'package:flutter/material.dart';

class CustomRadioButton extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final void Function(String?) onChanged;
  final bool enabled;

  const CustomRadioButton({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = groupValue == value;

    return InkWell(
      onTap: enabled ? () => onChanged(value) : null,
      child: Container(
        width: 150.0, // Set fixed width
        height: 50.0, // Set fixed height
        decoration: BoxDecoration(
          color: isSelected ? AppColors.orange : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.orange : Colors.white54,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(0.0), // Removed rounded corners
        ),
        alignment: Alignment.center, // Center the content
        child: Text(
          label,
          textAlign: TextAlign.center, // Center the text
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
