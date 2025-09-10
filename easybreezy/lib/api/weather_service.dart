import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';
import '../models/air_quality_data.dart';
import 'package:geolocator/geolocator.dart';

class WeatherService {
  // Replace with your actual API key when implementing
  static const String apiKey = 'ada0f2af67b3dd1d9824bb6e33750983';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Get current weather by location coordinates
  Future<WeatherData> getCurrentWeather(double lat, double lon, {String units = 'imperial'}) async {
    final url = '$baseUrl/weather?lat=$lat&lon=$lon&units=$units&appid=$apiKey';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return WeatherData.fromJson(jsonData);
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }

  // Get weather forecast for the next few days
  Future<WeatherForecast> getForecast(double lat, double lon, {String units = 'imperial'}) async {
    final url = '$baseUrl/forecast?lat=$lat&lon=$lon&units=$units&appid=$apiKey';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> forecastList = jsonData['list'];
        
        // Process hourly forecast (every 3 hours for 5 days)
        final List<WeatherData> hourlyForecast = forecastList
            .take(8) // Take next 24 hours (8 slots of 3 hours each)
            .map((item) => WeatherData.fromJson(item))
            .toList();
            
        // Process daily forecast (one entry per day)
        final Map<int, WeatherData> dailyMap = {};
        for (var item in forecastList) {
          final weather = WeatherData.fromJson(item);
          final day = DateTime.fromMillisecondsSinceEpoch(weather.timestamp * 1000).day;
          
          if (!dailyMap.containsKey(day)) {
            dailyMap[day] = weather;
          }
        }
        
        final List<WeatherData> dailyForecast = dailyMap.values.toList();
        
        return WeatherForecast(
          hourlyForecast: hourlyForecast,
          dailyForecast: dailyForecast,
        );
      } else {
        throw Exception('Failed to load forecast data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching forecast data: $e');
    }
  }

  // Get current location of the user
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Check location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Get the current position
    return await Geolocator.getCurrentPosition();
  }

  // Get severe weather alerts (OpenWeatherMap One Call API)
  Future<List<Map<String, dynamic>>> getSevereWeatherAlerts(double lat, double lon) async {
    final url = 'https://api.openweathermap.org/data/3.0/onecall?lat=$lat&lon=$lon&appid=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['alerts'] != null) {
          return List<Map<String, dynamic>>.from(jsonData['alerts']);
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load weather alerts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather alerts: $e');
    }
  }

  // Get current air pollution data (OpenWeatherMap Air Pollution API)
  Future<AirQualityData> getAirQuality(double lat, double lon) async {
    final url = 'https://api.openweathermap.org/data/2.5/air_pollution?lat=$lat&lon=$lon&appid=$apiKey';
    
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['list'] != null && jsonData['list'].isNotEmpty) {
          return AirQualityData.fromJson(jsonData['list'][0]);
        } else {
          throw Exception('No air quality data available');
        }
      } else {
        throw Exception('Failed to load air quality data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching air quality data: $e');
    }
  }

  // Get current UV index (OpenWeatherMap One Call API)
  Future<double> getUvIndex(double lat, double lon) async {
    final url = 'https://api.openweathermap.org/data/3.0/onecall?lat=$lat&lon=$lon&exclude=minutely,hourly,daily,alerts&appid=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // The UV index is in the 'current' object as 'uvi'
        if (jsonData['current'] != null && jsonData['current']['uvi'] != null) {
          return (jsonData['current']['uvi'] as num).toDouble();
        } else {
          throw Exception('No UV index data available');
        }
      } else {
        throw Exception('Failed to load UV index data: \\${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching UV index data: $e');
    }
  }
}