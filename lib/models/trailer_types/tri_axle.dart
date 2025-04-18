class TriAxleTrailer {
  final String? length;
  final String? vin;
  final String? registration;
  final String? make;
  final String? year;
  final List<Map<String, dynamic>>? additionalImages;

  TriAxleTrailer({
    this.length,
    this.vin,
    this.registration,
    this.make,
    this.year,
    this.additionalImages,
  });

  factory TriAxleTrailer.fromJson(Map<String, dynamic> json) {
    return TriAxleTrailer(
      length: json['length'],
      vin: json['vin'],
      registration: json['registration'],
      make: json['make'],
      year: json['year'],
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
      'additionalImages': additionalImages,
    };
  }

  Map<String, dynamic> toMap() => toJson();
}
