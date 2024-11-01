// lib/models/damage.dart

class Damage {
  final String description;
  final String imageUrl;

  Damage({required this.description, required this.imageUrl});

  factory Damage.fromMap(Map<String, dynamic> data) {
    return Damage(
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
