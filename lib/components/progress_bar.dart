import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final double progress; // Progress should be a value between 0.0 and 1.0

  const ProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 3.0, // Adjust height as needed
          decoration: BoxDecoration(
            color: Colors.white, // Background color of the progress bar
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
        Container(
          height: 3.0,
          width: MediaQuery.of(context).size.width * progress,
          decoration: BoxDecoration(
            gradient: progress < 1.0
                ? LinearGradient(
                    colors: [
                      Color(0xFF2F7FFF), // Solid blue at the start
                      Color(0xFF2F7FFF)
                          .withOpacity(0.4), // Semi-transparent blue
                      Colors.white, // Transition to white
                    ],
                    stops: const [
                      0.0,
                      0.8,
                      1.0
                    ], // Positions of the colors in the gradient
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null, // No gradient if progress is 1.0
            color: progress == 1.0
                ? Color(0xFF2F7FFF)
                : null, // Solid color if progress is 1.0
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
      ],
    );
  }
}
