// lib/models/chassis.dart

import 'additional_feature.dart';
import 'damage.dart';

class Chassis {
  final String condition;
  final String damagesCondition;
  final String additionalFeaturesCondition;
  final Map<String, ChassisImage> images;
  final List<Damage> damages;
  final List<AdditionalFeature> additionalFeatures;

  const Chassis({
    required this.condition,
    required this.damagesCondition,
    required this.additionalFeaturesCondition,
    required this.images,
    required this.damages,
    required this.additionalFeatures,
  });

  factory Chassis.fromMap(Map<String, dynamic>? data) {
    if (data == null) return Chassis.empty();

    final imagesMap = <String, ChassisImage>{};
    final rawImages = data['images'] as Map<String, dynamic>?;

    if (rawImages != null) {
      rawImages.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          imagesMap[key] = ChassisImage.fromMap(value);
        }
      });
    }

    return Chassis(
      condition: data['condition'] as String? ?? '',
      damagesCondition: data['damagesCondition'] as String? ?? '',
      additionalFeaturesCondition:
          data['additionalFeaturesCondition'] as String? ?? '',
      images: imagesMap,
      damages: List<Damage>.from(
        (data['damages'] as List<dynamic>? ?? []).map(
          (x) => Damage.fromMap(x as Map<String, dynamic>),
        ),
      ),
      additionalFeatures: List<AdditionalFeature>.from(
        (data['additionalFeatures'] as List<dynamic>? ?? []).map(
          (x) => AdditionalFeature.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  factory Chassis.empty() {
    return const Chassis(
      condition: '',
      damagesCondition: '',
      additionalFeaturesCondition: '',
      images: {},
      damages: [],
      additionalFeatures: [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'condition': condition,
      'damagesCondition': damagesCondition,
      'additionalFeaturesCondition': additionalFeaturesCondition,
      'images': images.map((key, value) => MapEntry(key, value.toMap())),
      'damages': damages.map((d) => d.toMap()).toList(),
      'additionalFeatures': additionalFeatures.map((a) => a.toMap()).toList(),
    };
  }
}

class ChassisImage {
  final bool isNew;
  final String path;

  ChassisImage({
    required this.isNew,
    required this.path,
  });

  factory ChassisImage.fromMap(Map<String, dynamic> data) {
    return ChassisImage(
      isNew: data['isNew'] ?? false,
      path: data['path'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isNew': isNew,
      'path': path,
    };
  }
}
