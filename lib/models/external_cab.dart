// lib/models/external_cab.dart

import 'damage.dart';
import 'additional_feature.dart';

class ExternalCab {
  final String condition;
  final String damagesCondition;
  final String additionalFeaturesCondition;
  final Map<String, PhotoData> images;
  final List<Damage> damages;
  final List<AdditionalFeature> additionalFeatures;

  ExternalCab({
    required this.condition,
    required this.damagesCondition,
    required this.additionalFeaturesCondition,
    required this.images,
    required this.damages,
    required this.additionalFeatures,
  });

  factory ExternalCab.fromMap(Map<String, dynamic> data) {
    return ExternalCab(
      condition: data['condition'] ?? '',
      damagesCondition: data['damagesCondition'] ?? '',
      additionalFeaturesCondition: data['additionalFeaturesCondition'] ?? '',
      images: _parseImages(data['images'] as Map<String, dynamic>? ?? {}),
      damages: (data['damages'] as List<dynamic>?)
              ?.map((d) => Damage.fromMap(d as Map<String, dynamic>))
              .toList() ??
          [],
      additionalFeatures: (data['additionalFeatures'] as List<dynamic>?)
              ?.map((a) => AdditionalFeature.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'condition': condition,
      'damagesCondition': damagesCondition,
      'additionalFeaturesCondition': additionalFeaturesCondition,
      'images': _imagesToMap(),
      'damages': damages.map((d) => d.toMap()).toList(),
      'additionalFeatures': additionalFeatures.map((a) => a.toMap()).toList(),
    };
  }

  static Map<String, PhotoData> _parseImages(Map<String, dynamic> imagesData) {
    Map<String, PhotoData> result = {};
    imagesData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result[key] = PhotoData.fromMap(value);
      }
    });
    return result;
  }

  Map<String, dynamic> _imagesToMap() {
    Map<String, dynamic> result = {};
    images.forEach((key, value) {
      result[key] = value.toMap();
    });
    return result;
  }

  factory ExternalCab.empty() {
    return ExternalCab(
      condition: '',
      damagesCondition: '',
      additionalFeaturesCondition: '',
      images: {},
      damages: [],
      additionalFeatures: [],
    );
  }
}

class PhotoData {
  final bool isNew;
  final String path;

  PhotoData({
    required this.isNew,
    required this.path,
  });

  factory PhotoData.fromMap(Map<String, dynamic> data) {
    return PhotoData(
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
