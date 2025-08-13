import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SmartHomeApiService {
  static const String _baseUrl = 'http://localhost:3000';
  
  // Get unique user ID from device or generate one
  static Future<String> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    
    if (userId == null) {
      // Generate a simple user ID based on device/timestamp
      userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('user_id', userId);
    }
    
    return userId;
  }

  // Start OAuth flow for a provider
  static Future<Map<String, dynamic>?> startOAuthFlow(String provider) async {
    try {
      final userId = await _getUserId();
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/$provider/start?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('OAuth start failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error starting OAuth flow: $e');
      return null;
    }
  }

  // Check provider connection status
  static Future<Map<String, dynamic>?> checkProviderStatus(String provider) async {
    try {
      final userId = await _getUserId();
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/$provider/status?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Status check failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error checking provider status: $e');
      return null;
    }
  }

  // Disconnect a provider
  static Future<bool> disconnectProvider(String provider) async {
    try {
      final userId = await _getUserId();
      final response = await http.delete(
        Uri.parse('$_baseUrl/auth/$provider/disconnect?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error disconnecting provider: $e');
      return false;
    }
  }

  // Get user's connected devices
  static Future<List<Map<String, dynamic>>> getDevices({String provider = 'smartthings'}) async {
    try {
      final userId = await _getUserId();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/devices?userId=$userId&provider=$provider'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['devices'] ?? []);
      } else if (response.statusCode == 401) {
        // User not connected to provider
        return [];
      } else {
        print('Get devices failed: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting devices: $e');
      return [];
    }
  }

  // Turn on AC
  static Future<bool> turnOnAC(String deviceId, {
    String provider = 'smartthings',
    double temperature = 22.0,
    String fanMode = 'auto'
  }) async {
    try {
      final userId = await _getUserId();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/devices/$deviceId/turn-on'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'provider': provider,
          'temperature': temperature,
          'fanMode': fanMode,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        print('Turn on AC failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error turning on AC: $e');
      return false;
    }
  }

  // Turn off AC
  static Future<bool> turnOffAC(String deviceId, {String provider = 'smartthings'}) async {
    try {
      final userId = await _getUserId();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/devices/$deviceId/turn-off'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'provider': provider,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        print('Turn off AC failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error turning off AC: $e');
      return false;
    }
  }

  // Set AC temperature
  static Future<bool> setACTemperature(String deviceId, double temperature, {String provider = 'smartthings'}) async {
    try {
      final userId = await _getUserId();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/devices/$deviceId/temperature'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'temperature': temperature,
          'provider': provider,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      } else {
        print('Set temperature failed: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error setting AC temperature: $e');
      return false;
    }
  }

  // Get device status
  static Future<Map<String, dynamic>?> getDeviceStatus(String deviceId, {String provider = 'smartthings'}) async {
    try {
      final userId = await _getUserId();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/devices/$deviceId/status?userId=$userId&provider=$provider'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['deviceStatus'];
      } else {
        print('Get device status failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting device status: $e');
      return null;
    }
  }
}
