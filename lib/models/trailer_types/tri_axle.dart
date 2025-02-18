class TriAxleTrailer {
  final String length;
  final String vin;
  final String registration;
  final String? frontImageUrl;
  final String? sideImageUrl;
  final String? tyresImageUrl;
  final String? chassisImageUrl;
  final String? deckImageUrl;
  final String? makersPlateImageUrl;
  final List<Map<String, dynamic>> additionalImages;

  TriAxleTrailer({
    required this.length,
    required this.vin,
    required this.registration,
    this.frontImageUrl,
    this.sideImageUrl,
    this.tyresImageUrl,
    this.chassisImageUrl,
    this.deckImageUrl,
    this.makersPlateImageUrl,
    this.additionalImages = const [],
  });

  factory TriAxleTrailer.fromJson(Map<String, dynamic> json) {
    return TriAxleTrailer(
      length: json['lengthTrailer'] ?? '',
      vin: json['vin'] ?? '',
      registration: json['registration'] ?? '',
      frontImageUrl: json['frontImageUrl'],
      sideImageUrl: json['sideImageUrl'],
      tyresImageUrl: json['tyresImageUrl'],
      chassisImageUrl: json['chassisImageUrl'],
      deckImageUrl: json['deckImageUrl'],
      makersPlateImageUrl: json['makersPlateImageUrl'],
      additionalImages:
          List<Map<String, dynamic>>.from(json['additionalImages'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lengthTrailer': length,
      'vin': vin,
      'registration': registration,
      'frontImageUrl': frontImageUrl,
      'sideImageUrl': sideImageUrl,
      'tyresImageUrl': tyresImageUrl,
      'chassisImageUrl': chassisImageUrl,
      'deckImageUrl': deckImageUrl,
      'makersPlateImageUrl': makersPlateImageUrl,
      'additionalImages': additionalImages,
    };
  }

  Map<String, dynamic> toMap() => toJson();
}
