import 'package:flutter/material.dart';

class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final String fallbackAssetPath;
  final BoxFit fit;
  final double? width;
  final double? height;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.fallbackAssetPath = 'lib/assets/default_vehicle_image.png',
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Image.asset(
        fallbackAssetPath,
        fit: fit,
        width: width,
        height: height,
      );
    }

    return Image.network(
      imageUrl!,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          fallbackAssetPath,
          fit: fit,
          width: width,
          height: height,
        );
      },
      // Add headers for CORS
      headers: const {
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'no-cache',
      },
    );
  }
}
