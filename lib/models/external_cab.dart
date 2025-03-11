// lib/models/external_cab.dart

import 'package:flutter/material.dart';

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
    // debugPrint('=== ExternalCab fromMap ===');
    // debugPrint('Raw data: $data');
    // debugPrint('condition: ${data['condition']}');
    // debugPrint('damagesCondition: ${data['damagesCondition']}');
    // debugPrint(
    //     'additionalFeaturesCondition: ${data['additionalFeaturesCondition']}');
    // debugPrint('images: ${data['images']}');

    final result = ExternalCab(
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

    // debugPrint('=== Created ExternalCab ===');
    // debugPrint('Final condition: ${result.condition}');
    // debugPrint('Final images count: ${result.images.length}');

    return result;
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
    // debugPrint('=== Parsing Images ===');
    // debugPrint('Raw images data: $imagesData');

    Map<String, PhotoData> result = {};
    imagesData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result[key] = PhotoData.fromMap(value);
        debugPrint(
            'Parsed image for $key: {path: ${result[key]?.path}, imageUrl: ${result[key]?.imageUrl}}');
      }
    });
    debugPrint('Finished parsing images. Count: ${result.length}');
    return result;
  }

  Map<String, dynamic> _imagesToMap() {
    Map<String, dynamic> result = {};
    images.forEach((key, value) {
      result[key] = {
        'isNew': value.isNew,
        'path': value.path,
        'url': value.imageUrl,
      };
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
  final String? imageUrl; // Add URL field

  PhotoData({
    this.isNew = false,
    this.path = '',
    this.imageUrl,
  });

  factory PhotoData.fromMap(Map<String, dynamic> data) {
    debugPrint('PhotoData.fromMap input: $data');
    final result = PhotoData(
      isNew: data['isNew'] ?? false,
      path: data['path'] ?? '',
      imageUrl: data['url'] ?? '', // Try 'url' first for back-compat
    );
    debugPrint(
        'PhotoData.fromMap result: {path: ${result.path}, imageUrl: ${result.imageUrl}}');
    return result;
  }

  Map<String, dynamic> toMap() {
    return {
      'isNew': isNew,
      'path': path,
      'url': imageUrl,
    };
  }

  @override
  String toString() => 'PhotoData(path: $path, imageUrl: $imageUrl)';
}
