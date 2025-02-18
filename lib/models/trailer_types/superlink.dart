class SuperlinkTrailer {
  final String lengthA;
  final String vinA;
  final String registrationA;
  final String lengthB;
  final String vinB;
  final String registrationB;

  // Images for Trailer A
  final String? frontImageAUrl;
  final String? sideImageAUrl;
  final String? tyresImageAUrl;
  final String? chassisImageAUrl;
  final String? deckImageAUrl;
  final String? makersPlateImageAUrl;
  final List<Map<String, dynamic>> additionalImagesA;

  // Images for Trailer B
  final String? frontImageBUrl;
  final String? sideImageBUrl;
  final String? tyresImageBUrl;
  final String? chassisImageBUrl;
  final String? deckImageBUrl;
  final String? makersPlateImageBUrl;
  final List<Map<String, dynamic>> additionalImagesB;

  SuperlinkTrailer({
    required this.lengthA,
    required this.vinA,
    required this.registrationA,
    required this.lengthB,
    required this.vinB,
    required this.registrationB,
    this.frontImageAUrl,
    this.sideImageAUrl,
    this.tyresImageAUrl,
    this.chassisImageAUrl,
    this.deckImageAUrl,
    this.makersPlateImageAUrl,
    this.frontImageBUrl,
    this.sideImageBUrl,
    this.tyresImageBUrl,
    this.chassisImageBUrl,
    this.deckImageBUrl,
    this.makersPlateImageBUrl,
    this.additionalImagesA = const [],
    this.additionalImagesB = const [],
  });

  factory SuperlinkTrailer.fromJson(Map<String, dynamic> json) {
    final trailerA = json['trailerA'] as Map<String, dynamic>? ?? {};
    final trailerB = json['trailerB'] as Map<String, dynamic>? ?? {};

    return SuperlinkTrailer(
      lengthA: trailerA['length'] ?? '',
      vinA: trailerA['vin'] ?? '',
      registrationA: trailerA['registration'] ?? '',
      lengthB: trailerB['length'] ?? '',
      vinB: trailerB['vin'] ?? '',
      registrationB: trailerB['registration'] ?? '',
      frontImageAUrl: trailerA['frontImageUrl'],
      sideImageAUrl: trailerA['sideImageUrl'],
      tyresImageAUrl: trailerA['tyresImageUrl'],
      chassisImageAUrl: trailerA['chassisImageUrl'],
      deckImageAUrl: trailerA['deckImageUrl'],
      makersPlateImageAUrl: trailerA['makersPlateImageUrl'],
      frontImageBUrl: trailerB['frontImageUrl'],
      sideImageBUrl: trailerB['sideImageUrl'],
      tyresImageBUrl: trailerB['tyresImageUrl'],
      chassisImageBUrl: trailerB['chassisImageUrl'],
      deckImageBUrl: trailerB['deckImageUrl'],
      makersPlateImageBUrl: trailerB['makersPlateImageUrl'],
      additionalImagesA:
          List<Map<String, dynamic>>.from(trailerA['additionalImages'] ?? []),
      additionalImagesB:
          List<Map<String, dynamic>>.from(trailerB['additionalImages'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trailerA': {
        'length': lengthA,
        'vin': vinA,
        'registration': registrationA,
        'frontImageUrl': frontImageAUrl,
        'sideImageUrl': sideImageAUrl,
        'tyresImageUrl': tyresImageAUrl,
        'chassisImageUrl': chassisImageAUrl,
        'deckImageUrl': deckImageAUrl,
        'makersPlateImageUrl': makersPlateImageAUrl,
        'additionalImages': additionalImagesA,
      },
      'trailerB': {
        'length': lengthB,
        'vin': vinB,
        'registration': registrationB,
        'frontImageUrl': frontImageBUrl,
        'sideImageUrl': sideImageBUrl,
        'tyresImageUrl': tyresImageBUrl,
        'chassisImageUrl': chassisImageBUrl,
        'deckImageUrl': deckImageBUrl,
        'makersPlateImageUrl': makersPlateImageBUrl,
        'additionalImages': additionalImagesB,
      },
    };
  }

  // Add toMap for compatibility
  Map<String, dynamic> toMap() => toJson();
}
