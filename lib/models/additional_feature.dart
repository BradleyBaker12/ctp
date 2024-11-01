// lib/models/additional_feature.dart

class AdditionalFeature {
  final String description;
  final String imageUrl;

  AdditionalFeature({required this.description, required this.imageUrl});

  factory AdditionalFeature.fromMap(Map<String, dynamic> data) {
    return AdditionalFeature(
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}
