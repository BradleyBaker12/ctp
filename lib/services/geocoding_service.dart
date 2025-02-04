import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeocodingService {
  // South African cities coordinates database
  static final Map<String, LatLng> _saCoordinates = {
    'meyerton': LatLng(-26.5577, 28.0169),
    'henley on klip': LatLng(-26.5477, 28.0769),
    'gauteng': LatLng(-26.2708, 28.1123),
    // Add more cities as needed
  };

  static Future<LatLng?> getCoordinates(String address) async {
    try {
      // Clean and normalize the address
      final normalizedAddress = _normalizeAddress(address);

      // Try exact match first
      final result = await _tryExactGeocoding(normalizedAddress);
      if (result != null) return result;

      // Try known city matching
      final cityMatch = await _tryKnownCityMatch(normalizedAddress);
      if (cityMatch != null) return cityMatch;

      // Try progressive fallback
      return await _tryProgressiveFallback(normalizedAddress);
    } catch (e) {
      print('Final geocoding error: $e');
      return null;
    }
  }

  static String _normalizeAddress(String address) {
    return address
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s,]'), '');
  }

  static Future<LatLng?> _tryExactGeocoding(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
    } catch (e) {
      print('Exact geocoding failed: $e');
    }
    return null;
  }

  static Future<LatLng?> _tryKnownCityMatch(String address) async {
    for (final city in _saCoordinates.keys) {
      if (address.contains(city)) {
        print('Found known city match: $city');
        return _saCoordinates[city];
      }
    }
    return null;
  }

  static Future<LatLng?> _tryProgressiveFallback(String address) async {
    final parts = address.split(',').map((e) => e.trim()).toList();

    // Try different combinations of address parts
    for (var i = parts.length - 1; i >= 0; i--) {
      for (var j = i - 1; j >= 0; j--) {
        try {
          final testAddress = '${parts[j]}, ${parts[i]}';
          print('Trying combination: $testAddress');
          final locations = await locationFromAddress(testAddress);
          if (locations.isNotEmpty) {
            return LatLng(locations.first.latitude, locations.first.longitude);
          }
        } catch (e) {
          print('Combination failed: $e');
          continue;
        }
      }
    }

    // If all else fails, try individual parts
    for (final part in parts.reversed) {
      try {
        if (part.length > 3) {
          // Avoid too short terms
          final locations = await locationFromAddress(part);
          if (locations.isNotEmpty) {
            return LatLng(locations.first.latitude, locations.first.longitude);
          }
        }
      } catch (e) {
        print('Individual part failed: $e');
        continue;
      }
    }

    return null;
  }
}
