import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../api/weather_service.dart';
import '../models/weather_data.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  
  WeatherData? _currentWeather;
  WeatherForecast? _forecast;
  Position? _currentLocation;
  bool _isLoading = false;
  String? _error;

  WeatherData? get currentWeather => _currentWeather;
  WeatherForecast? get forecast => _forecast;
  Position? get currentLocation => _currentLocation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch current weather based on user's location
  Future<void> fetchCurrentWeather() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get current location
      final position = await _weatherService.getCurrentLocation();
      _currentLocation = position;
      
      // Fetch current weather data
      final weatherData = await _weatherService.getCurrentWeather(
        position.latitude, 
        position.longitude,
      );
      
      _currentWeather = weatherData;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Fetch forecast data
  Future<void> fetchForecast() async {
    try {
      if (_currentLocation == null) {
        _currentLocation = await _weatherService.getCurrentLocation();
      }
      
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Fetch forecast data
      final forecastData = await _weatherService.getForecast(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );
      
      _forecast = forecastData;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Fetch both current weather and forecast
  Future<void> fetchWeatherData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get current location only once
      final position = await _weatherService.getCurrentLocation();
      _currentLocation = position;
      
      // Fetch both current weather and forecast data
      final weatherData = await _weatherService.getCurrentWeather(
        position.latitude, 
        position.longitude,
      );
      
      final forecastData = await _weatherService.getForecast(
        position.latitude,
        position.longitude,
      );
      
      _currentWeather = weatherData;
      _forecast = forecastData;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Refresh weather data
  Future<void> refreshWeatherData() async {
    _error = null;
    await fetchWeatherData();
  }
}