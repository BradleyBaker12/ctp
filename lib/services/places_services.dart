import 'dart:convert';

import 'package:ctp/services/places_data_model.dart';
import 'package:http/http.dart' as http;

class PlacesService {
  static const String _proxyUrl =
      "https://europe-west3-ctp-central-database.cloudfunctions.net/placesAutocomplete";

  static Future<List<PlacesData>> getSuggestions(String query) async {
    if (query.isEmpty) return [];

    final Uri url = Uri.parse("$_proxyUrl?input=$query");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions = data["predictions"] as List;
        print("Prediction: $predictions");
        return predictions.map((p) => PlacesData.fromJson(p)).toList();
      } else {
        throw Exception("Failed to load suggestions");
      }
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> getPlaceLatLng(String placeId) async {
    final url = Uri.parse(
      "https://getplacelatlng-wgqo2o4yuq-ey.a.run.app?placeId=$placeId",
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final location = data as Map<String, dynamic>;
      print("Location Data: $location");
      return {
        "lat": location["geometry"]["location"]["lat"],
        "lng": location["geometry"]["location"]["lng"],
        "city": location["city"],
        "state": location["state"],
        "postalCode": location["postalCode"],
      };
      // return LatLng(location["lat"], location["lng"]);
      // return GeoPoint(location["lat"], location["lng"]);
    } else {
      throw Exception("Failed to fetch place details");
    }
  }
}
