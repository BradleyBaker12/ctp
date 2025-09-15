import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;
  final Color color;

  const CustomBackButton({super.key, this.onPressed, this.size = 24, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      iconSize: size,
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      icon: Icon(Icons.arrow_back_ios_new, color: color, size: size),
    );
  }
}
