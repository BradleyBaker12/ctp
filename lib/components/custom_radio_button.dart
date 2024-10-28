import 'package:flutter/material.dart';

class CustomRadioButton extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final Function(String?) onChanged;
  final Color selectedColor;
  final Color unselectedColor;
  final Color textColor;

  const CustomRadioButton({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.selectedColor = const Color(0xFFFF4E00),
    this.unselectedColor = Colors.transparent,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = groupValue == value;

    return InkWell(
      onTap: () => onChanged(value),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          border: Border.all(
            color: isSelected ? selectedColor : Colors.white54,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : textColor.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
