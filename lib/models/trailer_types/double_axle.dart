class DoubleAxleTrailer {
  final String? length;
  final String? vin;
  final String? registration;
  final String? make;
  final String? year;
  final String? numberOfAxles;
  final List<Map<String, dynamic>>? additionalImages;

  DoubleAxleTrailer({
    this.length,
    this.vin,
    this.registration,
    this.make,
    this.year,
    this.numberOfAxles,
    this.additionalImages,
  });

  factory DoubleAxleTrailer.fromJson(Map<String, dynamic> json) {
    return DoubleAxleTrailer(
      length: json['length'],
      vin: json['vin'],
      registration: json['registration'],
      make: json['make'],
      year: json['year'],
      numberOfAxles:
          json['numberOfAxles']?.toString() ?? json['axles']?.toString(),
      additionalImages:
          List<Map<String, dynamic>>.from(json['additionalImages'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'length': length,
      'vin': vin,
      'registration': registration,
      'make': make,
      'year': year,
      'numberOfAxles': numberOfAxles,
      'additionalImages': additionalImages,
    };
  }

  Map<String, dynamic> toMap() => toJson();
}
