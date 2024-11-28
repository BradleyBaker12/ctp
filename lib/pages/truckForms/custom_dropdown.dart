// custom_dropdown.dart
import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final String hintText;
  final String? value;
  final List<String> items;
  final void Function(String?) onChanged;
  final String? Function(String?)? validator;
  final Widget Function(BuildContext, String)? itemBuilder;
  final bool enabled;
  final bool isTransporter;

  const CustomDropdown({
    super.key,
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isTransporter = true,
    this.validator,
    this.itemBuilder,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final validValue =
        (value?.isNotEmpty == true && items.contains(value)) ? value : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        border: Border(
          left: BorderSide(
            color: Colors.white.withOpacity(0.5),
            width: 1.0,
          ),
          right: BorderSide(
            color: Colors.white.withOpacity(0.5),
            width: 1.0,
          ),
        ),
        borderRadius: BorderRadius.circular(0.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      height: 60.0,
      child: DropdownButtonFormField<String>(
        value: validValue,
        onChanged: enabled ? onChanged : null,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white70),
          filled: false,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          enabledBorder: InputBorder.none,
        ),
        style: const TextStyle(
            color: Colors.white), // Text color for enabled state
        dropdownColor: Colors.grey.withOpacity(0.8),
        items: items
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: itemBuilder?.call(context, item) ??
                      Text(
                        item,
                        style: const TextStyle(
                            color: Colors.white), // Enforce white text
                      ),
                ))
            .toList(),
        disabledHint: validValue != null
            ? Text(
                validValue,
                style:
                    const TextStyle(color: Colors.white), // Enforce white text
              )
            : null,
        icon: isTransporter
            ? const Icon(
                Icons.arrow_drop_down,
                color: Colors.white,
              )
            : Icon(
                Icons.arrow_drop_down,
                color: Colors.grey.withOpacity(0),
              ),
      ),
    );
  }
}
