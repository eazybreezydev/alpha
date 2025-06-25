import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';
import 'package:geolocator/geolocator.dart';

class WeatherService {
  // Replace with your actual API key when implementing
  static const String apiKey = 'YOUR_OPENWEATHERMAP_API_KEY';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Get current weather by location coordinates
  Future<WeatherData> getCurrentWeather(double lat, double lon) async {
    final url = '$baseUrl/weather?lat=$lat&lon=$lon&units=imperial&appid=$apiKey';
    
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
  Future<WeatherForecast> getForecast(double lat, double lon) async {
    final url = '$baseUrl/forecast?lat=$lat&lon=$lon&units=imperial&appid=$apiKey';
    
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
}