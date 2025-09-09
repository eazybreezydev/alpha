import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/home_config.dart';

/// Service for detecting house orientation and building footprint from Google Maps
class HouseOrientationService {
  static const String _geocodingBaseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
  static const String _placesBaseUrl = 'https://maps.googleapis.com/maps/api/place';
  static const String _staticMapBaseUrl = 'https://maps.googleapis.com/maps/api/staticmap';

  /// Analyze building orientation based on address and coordinates
  static Future<HouseAnalysisResult> analyzeHouseOrientation({
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Get detailed address information
      final addressDetails = await _getDetailedAddressInfo(latitude, longitude);
      
      // Detect street direction
      final streetDirection = await _detectStreetDirection(latitude, longitude);
      
      // Estimate building orientation based on street layout
      final buildingOrientation = _estimateBuildingOrientation(streetDirection, addressDetails);
      
      // Get building footprint (simplified - in production would use Building API)
      final footprint = await _getBuildingFootprint(latitude, longitude);
      
      return HouseAnalysisResult(
        address: address,
        latitude: latitude,
        longitude: longitude,
        streetFacingDirection: streetDirection,
        estimatedOrientation: buildingOrientation,
        buildingFootprint: footprint,
        confidence: _calculateConfidence(addressDetails, streetDirection),
        addressDetails: addressDetails,
      );
      
    } catch (e) {
      print('Error analyzing house orientation: $e');
      return HouseAnalysisResult.fallback(address, latitude, longitude);
    }
  }

  /// Get detailed address information including street layout
  static Future<Map<String, dynamic>> _getDetailedAddressInfo(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('$_geocodingBaseUrl?latlng=$lat,$lng&result_type=street_address&key=$kGoogleApiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          return {
            'formatted_address': result['formatted_address'] ?? '',
            'address_components': result['address_components'] ?? [],
            'geometry': result['geometry'] ?? {},
            'place_id': result['place_id'] ?? '',
          };
        }
      }
    } catch (e) {
      print('Error getting address details: $e');
    }
    
    return {};
  }

  /// Detect street direction using nearby streets
  static Future<double> _detectStreetDirection(double lat, double lng) async {
    try {
      // Get nearby roads to determine street orientation
      // This is a simplified approach - real implementation would use Google Roads API
      
      // Sample nearby points to detect street direction
      final samplePoints = [
        {'lat': lat + 0.0001, 'lng': lng},      // North
        {'lat': lat - 0.0001, 'lng': lng},      // South
        {'lat': lat, 'lng': lng + 0.0001},      // East
        {'lat': lat, 'lng': lng - 0.0001},      // West
      ];
      
      // Find which direction has the most street-like characteristics
      double streetBearing = 0.0;
      
      for (int i = 0; i < samplePoints.length; i++) {
        final point = samplePoints[i];
        final hasStreet = await _hasStreetAt(point['lat']!, point['lng']!);
        
        if (hasStreet) {
          // Calculate bearing from center to this point
          streetBearing = _calculateBearing(lat, lng, point['lat']!, point['lng']!);
          break;
        }
      }
      
      return streetBearing;
      
    } catch (e) {
      print('Error detecting street direction: $e');
      return 0.0; // Default to north
    }
  }

  /// Check if there's a street at given coordinates
  static Future<bool> _hasStreetAt(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('$_geocodingBaseUrl?latlng=$lat,$lng&result_type=route&key=$kGoogleApiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'OK' && data['results'].isNotEmpty;
      }
    } catch (e) {
      // Ignore errors for street detection
    }
    
    return false;
  }

  /// Calculate bearing between two points
  static double _calculateBearing(double lat1, double lng1, double lat2, double lng2) {
    final dLng = (lng2 - lng1) * (pi / 180);
    final lat1Rad = lat1 * (pi / 180);
    final lat2Rad = lat2 * (pi / 180);
    
    final y = sin(dLng) * cos(lat2Rad);
    final x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLng);
    
    final bearing = atan2(y, x) * (180 / pi);
    return (bearing + 360) % 360; // Normalize to 0-360
  }

  /// Estimate building orientation based on street direction
  static HomeOrientation _estimateBuildingOrientation(double streetBearing, Map<String, dynamic> addressDetails) {
    // Most houses face the street, so the front door typically faces the street direction
    // Adjust bearing by 180 degrees to get the house-facing direction
    final houseFacingBearing = (streetBearing + 180) % 360;
    
    // Convert bearing to cardinal direction
    if (houseFacingBearing >= 315 || houseFacingBearing < 45) {
      return HomeOrientation.north;
    } else if (houseFacingBearing >= 45 && houseFacingBearing < 135) {
      return HomeOrientation.east;
    } else if (houseFacingBearing >= 135 && houseFacingBearing < 225) {
      return HomeOrientation.south;
    } else {
      return HomeOrientation.west;
    }
  }

  /// Get simplified building footprint
  static Future<List<Map<String, double>>> _getBuildingFootprint(double lat, double lng) async {
    // In a real implementation, this would use Google's Building API or similar
    // For now, return a generic rectangular footprint
    const double buildingSize = 0.0001; // Approximate building size in degrees
    
    return [
      {'lat': lat - buildingSize / 2, 'lng': lng - buildingSize / 2}, // SW corner
      {'lat': lat - buildingSize / 2, 'lng': lng + buildingSize / 2}, // SE corner
      {'lat': lat + buildingSize / 2, 'lng': lng + buildingSize / 2}, // NE corner
      {'lat': lat + buildingSize / 2, 'lng': lng - buildingSize / 2}, // NW corner
    ];
  }

  /// Calculate confidence level for the analysis
  static double _calculateConfidence(Map<String, dynamic> addressDetails, double streetBearing) {
    double confidence = 0.5; // Base confidence
    
    // Increase confidence if we have good address data
    if (addressDetails.isNotEmpty) {
      confidence += 0.2;
    }
    
    // Increase confidence if street bearing is reasonable
    if (streetBearing > 0) {
      confidence += 0.2;
    }
    
    // Increase confidence if we have detailed address components
    if (addressDetails['address_components'] != null && 
        addressDetails['address_components'].isNotEmpty) {
      confidence += 0.1;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Generate satellite map URL for the house
  static String getSatelliteMapUrl({
    required double latitude,
    required double longitude,
    int zoom = 19,
    int width = 300,
    int height = 300,
  }) {
    return '$_staticMapBaseUrl?'
        'center=$latitude,$longitude&'
        'zoom=$zoom&'
        'size=${width}x$height&'
        'scale=2&'
        'maptype=satellite&'
        'key=$kGoogleApiKey';
  }

  /// Generate street view URL for the house
  static String getStreetViewUrl({
    required double latitude,
    required double longitude,
    int width = 300,
    int height = 300,
    int fov = 90,
  }) {
    return 'https://maps.googleapis.com/maps/api/streetview?'
        'size=${width}x$height&'
        'location=$latitude,$longitude&'
        'fov=$fov&'
        'key=$kGoogleApiKey';
  }

  /// Suggest window locations based on house orientation and sun path
  static List<WindowDirection> suggestWindowLocations(HomeOrientation orientation) {
    switch (orientation) {
      case HomeOrientation.north:
        return [WindowDirection.south, WindowDirection.east]; // South for warmth, east for morning light
      case HomeOrientation.south:
        return [WindowDirection.north, WindowDirection.west]; // North for steady light, west for evening
      case HomeOrientation.east:
        return [WindowDirection.south, WindowDirection.west]; // South for warmth, west for evening light
      case HomeOrientation.west:
        return [WindowDirection.south, WindowDirection.east]; // South for warmth, east for morning light
    }
  }
}

/// Result of house orientation analysis
class HouseAnalysisResult {
  final String address;
  final double latitude;
  final double longitude;
  final double streetFacingDirection; // Bearing in degrees
  final HomeOrientation estimatedOrientation;
  final List<Map<String, double>> buildingFootprint;
  final double confidence; // 0.0 to 1.0
  final Map<String, dynamic> addressDetails;

  HouseAnalysisResult({
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.streetFacingDirection,
    required this.estimatedOrientation,
    required this.buildingFootprint,
    required this.confidence,
    required this.addressDetails,
  });

  /// Create a fallback result when analysis fails
  factory HouseAnalysisResult.fallback(String address, double lat, double lng) {
    return HouseAnalysisResult(
      address: address,
      latitude: lat,
      longitude: lng,
      streetFacingDirection: 0.0,
      estimatedOrientation: HomeOrientation.north,
      buildingFootprint: [
        {'lat': lat - 0.00005, 'lng': lng - 0.00005},
        {'lat': lat - 0.00005, 'lng': lng + 0.00005},
        {'lat': lat + 0.00005, 'lng': lng + 0.00005},
        {'lat': lat + 0.00005, 'lng': lng - 0.00005},
      ],
      confidence: 0.3,
      addressDetails: {},
    );
  }

  /// Get suggested window locations
  List<WindowDirection> get suggestedWindows => 
      HouseOrientationService.suggestWindowLocations(estimatedOrientation);

  /// Get satellite map URL
  String get satelliteMapUrl => HouseOrientationService.getSatelliteMapUrl(
        latitude: latitude,
        longitude: longitude,
      );

  /// Get street view URL
  String get streetViewUrl => HouseOrientationService.getStreetViewUrl(
        latitude: latitude,
        longitude: longitude,
      );

  @override
  String toString() {
    return 'HouseAnalysisResult(address: $address, orientation: $estimatedOrientation, confidence: ${(confidence * 100).toInt()}%)';
  }
}
