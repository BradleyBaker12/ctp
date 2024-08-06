import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final double progress;

  const ProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    var blue = const Color(0xFF2F7FFF);

    return LinearProgressIndicator(
      value: progress,
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      valueColor: AlwaysStoppedAnimation<Color>(blue),
    );
  }
}
