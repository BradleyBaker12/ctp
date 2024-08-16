import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final FractionalOffset begin;
  final FractionalOffset end;
  final List<double>? stops;

  const GradientBackground({
    super.key,
    required this.child,
    this.begin = const FractionalOffset(0.5, 0),
    this.end = const FractionalOffset(0.5, 0.5),
    this.stops,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0E4CAF), Colors.black],
          begin: begin,
          end: end,
          stops: stops,
        ),
      ),
      child: child,
    );
  }
}
