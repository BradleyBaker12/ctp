import 'dart:convert';

import 'package:ctp/services/places_data_model.dart';
import 'package:http/http.dart' as http;

class PlacesService {
  static const String _proxyUrl =
      "https://europe-west3-ctp-central-database.cloudfunctions.net/placesAutocomplete";

  static Future<List<PlacesData>> getSuggestions(String query) async {
    if (query.isEmpty) return [];
    final Uri url = Uri.parse(_proxyUrl).replace(queryParameters: {
      'input': query,
    });

    try {
      final response = await http
          .get(url, headers: { 'Accept': 'application/json' })
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = response.body;
        // Debug: log first 300 chars
        // ignore: avoid_print
        print("PlacesService.getSuggestions OK (${body.length}b): ${body.substring(0, body.length > 300 ? 300 : body.length)}");
        final data = json.decode(body);
        final predictions = (data["predictions"] as List? ?? []);
        return predictions
            .whereType<Map>()
            .map((p) => PlacesData.fromJson(Map<String, dynamic>.from(p)))
            .toList();
      } else {
        // ignore: avoid_print
        print("PlacesService.getSuggestions HTTP ${response.statusCode}: ${response.body}");
        return [];
      }
    } catch (e) {
      // ignore: avoid_print
      print("PlacesService.getSuggestions error: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> getPlaceLatLng(String placeId) async {
    // Use the same Cloud Function region as autocomplete for consistency
    final url = Uri.parse(
      "https://europe-west3-ctp-central-database.cloudfunctions.net/getPlaceDetails",
    ).replace(queryParameters: { 'placeId': placeId });
    final response = await http
        .get(url, headers: { 'Accept': 'application/json' })
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final body = response.body;
      // ignore: avoid_print
      print("PlacesService.getPlaceLatLng OK: ${body.substring(0, body.length > 300 ? 300 : body.length)}");
      final data = json.decode(body) as Map<String, dynamic>;
      // ignore: avoid_print
      print("Location Data: $data");
      return {
        "lat": data["lat"],
        "lng": data["lng"],
        "formattedAddress": data["formattedAddress"],
        "streetNumber": data["streetNumber"],
        "route": data["route"],
        "suburb": data["suburb"],
        "city": data["city"],
        "state": data["state"],
        "postalCode": data["postalCode"],
      };
      // return LatLng(location["lat"], location["lng"]);
      // return GeoPoint(location["lat"], location["lng"]);
    } else {
      // ignore: avoid_print
      print("PlacesService.getPlaceLatLng HTTP ${response.statusCode}: ${response.body}");
      throw Exception("Failed to fetch place details (${response.statusCode})");
    }
  }
}
