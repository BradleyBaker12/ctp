// custom_text_field.dart
import 'package:ctp/components/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isCurrency;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatter;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.isCurrency = false,
    this.keyboardType,
    this.inputFormatter,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  }) : super(key: key);

  String _capitalizeHintText(String hint) {
    if (hint.isEmpty) return hint;
    return hint[0].toUpperCase() + hint.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat _numberFormat = NumberFormat("#,##0", "en_US");

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
      child: Center(
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType ?? TextInputType.text,
          textCapitalization: textCapitalization,
          cursorColor: AppColors.orange,
          decoration: InputDecoration(
            hintText: _capitalizeHintText(hintText),
            prefixText: isCurrency ? 'R ' : '',
            prefixStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            hintStyle: const TextStyle(color: Colors.white70),
            filled: false, // Removed fill color from TextFormField
            border: InputBorder.none, // Removed all borders
            contentPadding: EdgeInsets.zero, // Removed additional padding
          ),
          style: const TextStyle(color: Colors.white),
          inputFormatters: inputFormatter,
          validator: validator,
          onChanged: isCurrency
              ? (value) {
                  if (value.isNotEmpty) {
                    try {
                      final formattedValue = _numberFormat
                          .format(int.parse(value.replaceAll(" ", "")))
                          .replaceAll(",", " ");
                      controller.value = TextEditingValue(
                        text: formattedValue,
                        selection: TextSelection.collapsed(
                            offset: formattedValue.length),
                      );
                    } catch (e) {
                      print("Error formatting amount: $e");
                    }
                  }
                }
              : null,
        ),
      ),
    );
  }
}
