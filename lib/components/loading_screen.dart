import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  final Color backgroundColor;
  final Color indicatorColor;

  const LoadingScreen({
    super.key,
    this.backgroundColor = Colors.black,
    this.indicatorColor = const Color(0xFFFF4E00),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundColor.withOpacity(0.5),
      child: Center(
        child: CircularProgressIndicator(
          color: indicatorColor,
        ),
      ),
    );
  }
}
