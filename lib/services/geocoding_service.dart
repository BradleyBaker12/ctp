import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_geocoding_api/google_geocoding_api.dart';

class GeocodingService {
  static const String _googleApiKey =
      'AIzaSyDyE6Oqb-T0B1x-iqaQUejLexXKwoe7NoU'; // Replace with your API key
  static final _api = GoogleGeocodingApi(_googleApiKey, isLogged: kDebugMode);

  // Default coordinates for South Africa
  static const LatLng _defaultSouthAfrica = LatLng(-30.5595, 22.9375);

  // South African province mappings
  static const Map<String, String> _provinceAbbreviations = {
    'gauteng': 'GP',
    'western cape': 'WC',
    'eastern cape': 'EC',
    'kwazulu-natal': 'KZN',
    'free state': 'FS',
    'mpumalanga': 'MP',
    'limpopo': 'LP',
    'north west': 'NW',
    'northern cape': 'NC',
  };

  static String _formatAddress(String address) {
    // Convert to lowercase for comparison
    String formattedAddress = address.toLowerCase().trim();

    // Add South Africa if not present
    if (!formattedAddress.contains('south africa')) {
      formattedAddress += ', south africa';
    }

    // Replace province abbreviations with full names
    _provinceAbbreviations.forEach((full, abbr) {
      formattedAddress = formattedAddress.replaceAll(
        RegExp('\\b$abbr\\b', caseSensitive: false),
        full,
      );
    });

    return formattedAddress;
  }

  static Future<LatLng?> getCoordinates(String address) async {
    try {
      print('Original address: $address');
      final formattedAddress = _formatAddress(address);
      print('Formatted address: $formattedAddress');

      final searchResults = await _api.search(
        formattedAddress,
        language: 'en',
        region: 'za', // Restrict to South Africa
        components: 'country:za', // Additional restriction to South Africa
      );

      if (searchResults.status == "OK" && searchResults.results.isNotEmpty) {
        final location = searchResults.results.first.geometry!.location;
        print('Found coordinates: ${location.lat}, ${location.lng}');
        return LatLng(location.lat, location.lng);
      }

      // If no results, try with just the city/town name
      final simplifiedAddress =
          '${formattedAddress.split(',').first}, south africa';
      print('Trying simplified address: $simplifiedAddress');

      final fallbackResults = await _api.search(
        simplifiedAddress,
        language: 'en',
        region: 'za',
      );

      if (fallbackResults.status == "OK" &&
          fallbackResults.results.isNotEmpty) {
        final location = fallbackResults.results.first.geometry!.location;
        print(
            'Found coordinates with simplified address: ${location.lat}, ${location.lng}');
        return LatLng(location.lat, location.lng);
      }

      print('No coordinates found for address');
      return _defaultSouthAfrica;
    } catch (e) {
      print('Error in geocoding: $e');
      return _defaultSouthAfrica;
    }
  }
}
