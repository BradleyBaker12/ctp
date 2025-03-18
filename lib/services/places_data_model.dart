class PlacesData {
  String? description;
  // List<MatchedSubstrings>? matchedSubstrings;
  String? placeId;
  String? reference;
  // StructuredFormatting? structuredFormatting;
  List<Terms>? terms;
  List<String>? types;

  PlacesData(
      {this.description,
      // this.matchedSubstrings,
      this.placeId,
      this.reference,
      // this.structuredFormatting,
      this.terms,
      this.types});

  PlacesData.fromJson(Map<String, dynamic> json) {
    description = json['description'];
    // if (json['matched_substrings'] != null) {
    //   matchedSubstrings = <MatchedSubstrings>[];
    //   json['matched_substrings'].forEach((v) {
    //     matchedSubstrings!.add(new MatchedSubstrings.fromJson(v));
    //   });
    // }
    placeId = json['place_id'];
    reference = json['reference'];
    // structuredFormatting = json['structured_formatting'] != null
    //     ? new StructuredFormatting.fromJson(json['structured_formatting'])
    //     : null;
    if (json['terms'] != null) {
      terms = <Terms>[];
      json['terms'].forEach((v) {
        terms!.add(Terms.fromJson(v));
      });
    }
    types = json['types'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['description'] = description;
    // if (this.matchedSubstrings != null) {
    //   data['matched_substrings'] =
    //       this.matchedSubstrings!.map((v) => v.toJson()).toList();
    // }
    data['place_id'] = placeId;
    data['reference'] = reference;
    // if (this.structuredFormatting != null) {
    //   data['structured_formatting'] = this.structuredFormatting!.toJson();
    // }
    if (terms != null) {
      data['terms'] = terms!.map((v) => v.toJson()).toList();
    }
    data['types'] = types;
    return data;
  }
}

class MatchedSubstrings {
  int? length;
  int? offset;

  MatchedSubstrings({this.length, this.offset});

  MatchedSubstrings.fromJson(Map<String, dynamic> json) {
    length = json['length'];
    offset = json['offset'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['length'] = length;
    data['offset'] = offset;
    return data;
  }
}

// class StructuredFormatting {
//   String? mainText;
//   List<MainTextMatchedSubstrings>? mainTextMatchedSubstrings;
//   String? secondaryText;
//
//   StructuredFormatting(
//       {this.mainText, this.mainTextMatchedSubstrings, this.secondaryText});
//
//   StructuredFormatting.fromJson(Map<String, dynamic> json) {
//     mainText = json['main_text'];
//     if (json['main_text_matched_substrings'] != null) {
//       mainTextMatchedSubstrings = <MainTextMatchedSubstrings>[];
//       json['main_text_matched_substrings'].forEach((v) {
//         mainTextMatchedSubstrings!
//             .add(new MainTextMatchedSubstrings.fromJson(v));
//       });
//     }
//     secondaryText = json['secondary_text'];
//   }
//
//   Map<String, dynamic> toJson() {
//     final Map<String, dynamic> data = new Map<String, dynamic>();
//     data['main_text'] = this.mainText;
//     if (this.mainTextMatchedSubstrings != null) {
//       data['main_text_matched_substrings'] =
//           this.mainTextMatchedSubstrings!.map((v) => v.toJson()).toList();
//     }
//     data['secondary_text'] = this.secondaryText;
//     return data;
//   }
// }

class Terms {
  int? offset;
  String? value;

  Terms({this.offset, this.value});

  Terms.fromJson(Map<String, dynamic> json) {
    offset = json['offset'];
    value = json['value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['offset'] = offset;
    data['value'] = value;
    return data;
  }
}
