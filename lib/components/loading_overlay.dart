import 'package:flutter/material.dart';
import 'constants.dart';

class LoadingOverlay extends StatelessWidget {
  final double progress;
  final String status;
  final bool isVisible;
  final String? title;

  const LoadingOverlay({
    super.key,
    required this.progress,
    required this.status,
    required this.isVisible,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32.0),
            margin: const EdgeInsets.symmetric(horizontal: 32.0),
            decoration: BoxDecoration(
              color: Color(0xFF0E4CAF).withOpacity(0.6),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: AppColors.orange,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress indicator with animation
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: progress > 0 ? progress : null,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.orange,
                        ),
                        strokeWidth: 6,
                      ),
                    ),
                    if (progress > 0)
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        // decoration: BoxDecoration(
                        //   color: Colors.grey.shade100,
                        //   borderRadius: BorderRadius.circular(20),
                        // ),
                        child: Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(221, 255, 255, 255),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  title ?? (status.isNotEmpty ? status : 'Processing...'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(221, 255, 255, 255),
                    fontFamily: 'Montserrat',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  // decoration: BoxDecoration(
                  //   color: AppColors.orange.withOpacity(0.1),
                  //   borderRadius: BorderRadius.circular(20),
                  //   border: Border.all(
                  //     color: AppColors.orange.withOpacity(0.3),
                  //     width: 1,
                  //   ),
                  // ),
                  child: Text(
                    'This will only take a moment',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Montserrat',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A more customizable loading overlay with additional options
class CustomLoadingOverlay extends StatelessWidget {
  final double progress;
  final String status;
  final bool isVisible;
  final String? title;
  final String? subtitle;
  final Color? progressColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? size;

  const CustomLoadingOverlay({
    super.key,
    required this.progress,
    required this.status,
    required this.isVisible,
    this.title,
    this.subtitle,
    this.progressColor,
    this.backgroundColor,
    this.borderColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final effectiveSize = size ?? 100.0;
    final effectiveProgressColor = progressColor ?? AppColors.orange;
    final effectiveBackgroundColor = backgroundColor ?? Colors.white;
    final effectiveBorderColor = borderColor ?? AppColors.orange;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32.0),
            margin: const EdgeInsets.symmetric(horizontal: 32.0),
            decoration: BoxDecoration(
              color: effectiveBackgroundColor,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: effectiveBorderColor,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress indicator with animation
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: effectiveSize,
                      height: effectiveSize,
                      child: CircularProgressIndicator(
                        value: progress > 0 ? progress : null,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          effectiveProgressColor,
                        ),
                        strokeWidth: 6,
                      ),
                    ),
                    if (progress > 0)
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(221, 255, 255, 255),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  title ?? (status.isNotEmpty ? status : 'Processing...'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Montserrat',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: effectiveProgressColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: effectiveProgressColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    subtitle ?? 'This will only take a moment',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Montserrat',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple loading overlay for basic use cases
class SimpleLoadingOverlay extends StatelessWidget {
  final bool isVisible;
  final String message;

  const SimpleLoadingOverlay({
    super.key,
    required this.isVisible,
    this.message = 'Loading...',
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24.0),
            margin: const EdgeInsets.symmetric(horizontal: 32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: AppColors.orange,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.orange,
                    ),
                    strokeWidth: 4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontFamily: 'Montserrat',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
