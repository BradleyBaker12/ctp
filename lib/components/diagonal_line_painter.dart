import 'package:flutter/material.dart';

class SingleDiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;

    // Draw a single diagonal line
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
