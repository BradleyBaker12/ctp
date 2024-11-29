// lib/models/internal_cab.dart

import 'damage.dart';
import 'additional_feature.dart';

class InternalCab {
  final String condition;
  final String damagesCondition;
  final String additionalFeaturesCondition;
  final String faultCodesCondition;
  final Map<String, PhotoData> viewImages;
  final List<Damage> damages;
  final List<AdditionalFeature> additionalFeatures;
  final List<dynamic> faultCodes;

  InternalCab({
    required this.condition,
    required this.damagesCondition,
    required this.additionalFeaturesCondition,
    required this.faultCodesCondition,
    required this.viewImages,
    required this.damages,
    required this.additionalFeatures,
    required this.faultCodes,
  });

  factory InternalCab.fromMap(Map<String, dynamic> data) {
    return InternalCab(
      condition: data['condition'] ?? '',
      damagesCondition: data['damagesCondition'] ?? '',
      additionalFeaturesCondition: data['additionalFeaturesCondition'] ?? '',
      faultCodesCondition: data['faultCodesCondition'] ?? '',
      viewImages:
          _parseViewImages(data['viewImages'] as Map<String, dynamic>? ?? {}),
      damages: (data['damages'] as List<dynamic>?)
              ?.map((d) => Damage.fromMap(d as Map<String, dynamic>))
              .toList() ??
          [],
      additionalFeatures: (data['additionalFeatures'] as List<dynamic>?)
              ?.map((a) => AdditionalFeature.fromMap(a as Map<String, dynamic>))
              .toList() ??
          [],
      faultCodes: data['faultCodes'] as List<dynamic>? ?? [],
    );
  }

  static Map<String, PhotoData> _parseViewImages(
      Map<String, dynamic> imagesData) {
    Map<String, PhotoData> result = {};
    imagesData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        result[key] = PhotoData.fromMap(value);
      }
    });
    return result;
  }

  Map<String, dynamic> toMap() {
    return {
      'condition': condition,
      'damagesCondition': damagesCondition,
      'additionalFeaturesCondition': additionalFeaturesCondition,
      'faultCodesCondition': faultCodesCondition,
      'viewImages': _imagesToMap(),
      'damages': damages.map((d) => d.toMap()).toList(),
      'additionalFeatures': additionalFeatures.map((a) => a.toMap()).toList(),
      'faultCodes': faultCodes,
    };
  }

  Map<String, dynamic> _imagesToMap() {
    Map<String, dynamic> result = {};
    viewImages.forEach((key, value) {
      result[key] = value.toMap();
    });
    return result;
  }

  factory InternalCab.empty() {
    return InternalCab(
      condition: '',
      damagesCondition: '',
      additionalFeaturesCondition: '',
      faultCodesCondition: '',
      viewImages: {},
      damages: [],
      additionalFeatures: [],
      faultCodes: [],
    );
  }
}

class PhotoData {
  final bool isNew;
  final String url; // This should store the Firebase Storage URL

  PhotoData({
    required this.isNew,
    required this.url,
  });

  factory PhotoData.fromMap(Map<String, dynamic> data) {
    return PhotoData(
      isNew: data['isNew'] ?? false,
      url: data['url'] ?? '', // Use url instead of path
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isNew': isNew,
      'url': url, // Use url instead of path
    };
  }
}
