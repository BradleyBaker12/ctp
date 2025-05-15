class SuperlinkTrailer {
  final String? lengthA;
  final String? vinA;
  final String? registrationA;
  final String? makeA;
  final String? modelA;
  final String? yearA;
  final String? axlesA;
  final String? licenceDiskExpA;
  final String? absA;
  final String? suspensionA;
  final String? natisDoc1UrlA;
  final String? frontImageUrlA;
  final String? sideImageUrlA;
  final String? tyresImageUrlA;
  final String? chassisImageUrlA;
  final String? deckImageUrlA;
  final String? makersPlateImageUrlA;
  final String? hookPinImageUrlA;
  final String? roofImageUrlA;
  final String? tailBoardImageUrlA;
  final String? spareWheelImageUrlA;
  final String? landingLegImageUrlA;
  final String? hoseAndElecticalCableImageUrlA;
  final String? brakesAxle1ImageUrlA;
  final String? brakesAxle2ImageUrlA;
  final String? axle1ImageUrlA;
  final String? axle2ImageUrlA;

  final String? lengthB;
  final String? vinB;
  final String? registrationB;
  final String? makeB;
  final String? modelB;
  final String? yearB;
  final String? axlesB;
  final String? licenceDiskExpB;
  final String? absB;
  final String? suspensionB;
  final String? natisDoc1UrlB;
  final String? frontImageUrlB;
  final String? sideImageUrlB;
  final String? tyresImageUrlB;
  final String? chassisImageUrlB;
  final String? deckImageUrlB;
  final String? makersPlateImageUrlB;
  final String? hookPinImageUrlB;
  final String? roofImageUrlB;
  final String? tailBoardImageUrlB;
  final String? spareWheelImageUrlB;
  final String? landingLegImageUrlB;
  final String? hoseAndElecticalCableImageUrlB;
  final String? brakesAxle1ImageUrlB;
  final String? brakesAxle2ImageUrlB;
  final String? axle1ImageUrlB;
  final String? axle2ImageUrlB;

  final List<Map<String, dynamic>> additionalImagesA;
  final List<Map<String, dynamic>> additionalImagesB;
  final String? numberOfAxles;

  SuperlinkTrailer({
    this.lengthA,
    this.vinA,
    this.registrationA,
    this.makeA,
    this.modelA,
    this.yearA,
    this.axlesA,
    this.licenceDiskExpA,
    this.absA,
    this.suspensionA,
    this.natisDoc1UrlA,
    this.frontImageUrlA,
    this.sideImageUrlA,
    this.tyresImageUrlA,
    this.chassisImageUrlA,
    this.deckImageUrlA,
    this.makersPlateImageUrlA,
    this.hookPinImageUrlA,
    this.roofImageUrlA,
    this.tailBoardImageUrlA,
    this.spareWheelImageUrlA,
    this.landingLegImageUrlA,
    this.hoseAndElecticalCableImageUrlA,
    this.brakesAxle1ImageUrlA,
    this.brakesAxle2ImageUrlA,
    this.axle1ImageUrlA,
    this.axle2ImageUrlA,
    this.lengthB,
    this.vinB,
    this.registrationB,
    this.makeB,
    this.modelB,
    this.yearB,
    this.axlesB,
    this.licenceDiskExpB,
    this.absB,
    this.suspensionB,
    this.natisDoc1UrlB,
    this.frontImageUrlB,
    this.sideImageUrlB,
    this.tyresImageUrlB,
    this.chassisImageUrlB,
    this.deckImageUrlB,
    this.makersPlateImageUrlB,
    this.hookPinImageUrlB,
    this.roofImageUrlB,
    this.tailBoardImageUrlB,
    this.spareWheelImageUrlB,
    this.landingLegImageUrlB,
    this.hoseAndElecticalCableImageUrlB,
    this.brakesAxle1ImageUrlB,
    this.brakesAxle2ImageUrlB,
    this.axle1ImageUrlB,
    this.axle2ImageUrlB,
    this.additionalImagesA = const [],
    this.additionalImagesB = const [],
    this.numberOfAxles,
  });

  factory SuperlinkTrailer.fromJson(Map<String, dynamic> json) {
    final trailerA = json['trailerA'] ?? {};
    final trailerB = json['trailerB'] ?? {};

    return SuperlinkTrailer(
      // Trailer A fields
      lengthA: trailerA['length'],
      vinA: trailerA['vin'],
      registrationA: trailerA['registration'],
      makeA: trailerA['make'],
      modelA: trailerA['model'],
      yearA: trailerA['year'],
      axlesA: trailerA['axles']?.toString(), // <-- Ensure string conversion
      licenceDiskExpA: trailerA['licenceExp'],
      absA: trailerA['abs'],
      suspensionA: trailerA['suspension'],
      natisDoc1UrlA: trailerA['natisDoc1Url'],
      frontImageUrlA: trailerA['frontImageUrl'],
      sideImageUrlA: trailerA['sideImageUrl'],
      tyresImageUrlA: trailerA['tyresImageUrl'],
      chassisImageUrlA: trailerA['chassisImageUrl'],
      deckImageUrlA: trailerA['deckImageUrl'],
      makersPlateImageUrlA: trailerA['makersPlateImageUrl'],
      hookPinImageUrlA: trailerA['hookPinImageUrl'],
      roofImageUrlA: trailerA['roofImageUrl'],
      tailBoardImageUrlA: trailerA['tailBoardImageUrl'],
      spareWheelImageUrlA: trailerA['spareWheelImageUrl'],
      landingLegImageUrlA: trailerA['landingLegImageUrl'],
      hoseAndElecticalCableImageUrlA: trailerA['hoseAndElecticalCableImageUrl'],
      brakesAxle1ImageUrlA: trailerA['brakesAxle1ImageUrl'],
      brakesAxle2ImageUrlA: trailerA['brakesAxle2ImageUrl'],
      axle1ImageUrlA: trailerA['axle1ImageUrl'],
      axle2ImageUrlA: trailerA['axle2ImageUrl'],
      additionalImagesA: List<Map<String, dynamic>>.from(
          trailerA['trailerAAdditionalImages'] ?? []),

      // Trailer B fields
      lengthB: trailerB['length'],
      vinB: trailerB['vin'],
      registrationB: trailerB['registration'],
      makeB: trailerB['make'],
      modelB: trailerB['model'],
      yearB: trailerB['year'],
      axlesB: trailerB['axles']?.toString(), // <-- Ensure string conversion
      licenceDiskExpB: trailerB['licenceExp'],
      absB: trailerB['abs'],
      suspensionB: trailerB['suspension'],
      natisDoc1UrlB: trailerB['natisDoc1Url'],
      frontImageUrlB: trailerB['frontImageUrl'],
      sideImageUrlB: trailerB['sideImageUrl'],
      tyresImageUrlB: trailerB['tyresImageUrl'],
      chassisImageUrlB: trailerB['chassisImageUrl'],
      deckImageUrlB: trailerB['deckImageUrl'],
      makersPlateImageUrlB: trailerB['makersPlateImageUrl'],
      hookPinImageUrlB: trailerB['hookPinImageUrl'],
      roofImageUrlB: trailerB['roofImageUrl'],
      tailBoardImageUrlB: trailerB['tailBoardImageUrl'],
      spareWheelImageUrlB: trailerB['spareWheelImageUrl'],
      landingLegImageUrlB: trailerB['landingLegImageUrl'],
      hoseAndElecticalCableImageUrlB: trailerB['hoseAndElecticalCableImageUrl'],
      brakesAxle1ImageUrlB: trailerB['brakesAxle1ImageUrl'],
      brakesAxle2ImageUrlB: trailerB['brakesAxle2ImageUrl'],
      axle1ImageUrlB: trailerB['axle1ImageUrl'],
      axle2ImageUrlB: trailerB['axle2ImageUrl'],
      additionalImagesB: List<Map<String, dynamic>>.from(
          trailerB['trailerBAdditionalImages'] ?? []),
      numberOfAxles:
          json['numberOfAxles']?.toString() ?? json['axles']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trailerA': {
        'length': lengthA,
        'vin': vinA,
        'registration': registrationA,
        'make': makeA,
        'model': modelA,
        'year': yearA,
        'axles': axlesA,
        'licenceExp': licenceDiskExpA,
        'abs': absA,
        'suspension': suspensionA,
        'natisDoc1Url': natisDoc1UrlA,
        'frontImageUrl': frontImageUrlA,
        'sideImageUrl': sideImageUrlA,
        'tyresImageUrl': tyresImageUrlA,
        'chassisImageUrl': chassisImageUrlA,
        'deckImageUrl': deckImageUrlA,
        'makersPlateImageUrl': makersPlateImageUrlA,
        'hookPinImageUrl': hookPinImageUrlA,
        'roofImageUrl': roofImageUrlA,
        'tailBoardImageUrl': tailBoardImageUrlA,
        'spareWheelImageUrl': spareWheelImageUrlA,
        'landingLegImageUrl': landingLegImageUrlA,
        'hoseAndElecticalCableImageUrl': hoseAndElecticalCableImageUrlA,
        'brakesAxle1ImageUrl': brakesAxle1ImageUrlA,
        'brakesAxle2ImageUrl': brakesAxle2ImageUrlA,
        'axle1ImageUrl': axle1ImageUrlA,
        'axle2ImageUrl': axle2ImageUrlA,
        'trailerAAdditionalImages': additionalImagesA,
      },
      'trailerB': {
        'length': lengthB,
        'vin': vinB,
        'registration': registrationB,
        'make': makeB,
        'model': modelB,
        'year': yearB,
        'axles': axlesB,
        'licenceExp': licenceDiskExpB,
        'abs': absB,
        'suspension': suspensionB,
        'natisDoc1Url': natisDoc1UrlB,
        'frontImageUrl': frontImageUrlB,
        'sideImageUrl': sideImageUrlB,
        'tyresImageUrl': tyresImageUrlB,
        'chassisImageUrl': chassisImageUrlB,
        'deckImageUrl': deckImageUrlB,
        'makersPlateImageUrl': makersPlateImageUrlB,
        'hookPinImageUrl': hookPinImageUrlB,
        'roofImageUrl': roofImageUrlB,
        'tailBoardImageUrl': tailBoardImageUrlB,
        'spareWheelImageUrl': spareWheelImageUrlB,
        'landingLegImageUrl': landingLegImageUrlB,
        'hoseAndElecticalCableImageUrl': hoseAndElecticalCableImageUrlB,
        'brakesAxle1ImageUrl': brakesAxle1ImageUrlB,
        'brakesAxle2ImageUrl': brakesAxle2ImageUrlB,
        'axle1ImageUrl': axle1ImageUrlB,
        'axle2ImageUrl': axle2ImageUrlB,
        'trailerBAdditionalImages': additionalImagesB,
      },
      'numberOfAxles': numberOfAxles,
    };
  }

  Map<String, dynamic> toMap() => toJson();
}
