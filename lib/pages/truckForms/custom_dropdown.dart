// custom_dropdown.dart
import 'package:flutter/material.dart';
import 'dart:typed_data';

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
        color: Colors.grey.withAlpha(90),
        border: Border(
          left: BorderSide(
            color: Colors.white.withAlpha(128),
            width: 1.0,
          ),
          right: BorderSide(
            color: Colors.white.withAlpha(128),
            width: 1.0,
          ),
        ),
        borderRadius: BorderRadius.circular(0.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      height: 60.0,
      child: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.grey.withAlpha(120),
          hintColor: Colors.white,
        ),
        child: DropdownButtonFormField<String>(
          value: validValue,
          onChanged: enabled ? onChanged : null,
          validator: validator,
          dropdownColor: Colors.grey[900],
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.white),
            filled: false,
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            enabledBorder: InputBorder.none,
          ),
          items: items
              .map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: itemBuilder?.call(context, item) ??
                        Text(
                          item,
                          style: const TextStyle(color: Colors.white),
                        ),
                  ))
              .toList(),
          disabledHint: validValue != null
              ? Text(
                  validValue,
                  style: const TextStyle(color: Colors.white),
                )
              : null,
          icon: isTransporter
              ? const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                )
              : Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey.withAlpha(0),
                ),
        ),
      ),
    );
  }
}
