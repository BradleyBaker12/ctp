import 'package:flutter/material.dart';

class ImageUploadIndicator extends StatelessWidget {
  final bool isUploading;
  final Widget child;

  const ImageUploadIndicator({
    super.key,
    required this.isUploading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        if (isUploading)
          Container(
            color: Colors.black54,
            child: const CircularProgressIndicator(),
          ),
      ],
    );
  }
}
