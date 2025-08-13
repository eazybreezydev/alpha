import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/weather_service.dart';
import '../models/weather_data.dart';
import '../models/wind_data.dart';
import 'home_provider.dart';
import '../utils/notification_service.dart';

class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  
  WeatherData? _currentWeather;
  WeatherForecast? _forecast;
  Position? _currentLocation;
  String? _city; // Added city property
  String? _province; // Add province/state property
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _alerts = [];
  List<WindData> _windForecast = [];
  bool _isInitialized = false; // Track initialization status

  // Constructor loads saved location data
  WeatherProvider() {
    _initializeProvider();
  }

  // Initialize provider with proper async handling
  Future<void> _initializeProvider() async {
    await _loadSavedLocationData();
    _isInitialized = true;
    notifyListeners();
  }

  WeatherData? get currentWeather => _currentWeather;
  WeatherForecast? get forecast => _forecast;
  Position? get currentLocation => _currentLocation;
  String? get city => _city; // City getter
  String? get province => _province; // Province getter
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get alerts => _alerts;
  List<WindData> get windForecast => _windForecast;
  bool get isInitialized => _isInitialized; // Getter for initialization status

  // Fetch current weather based on user's location
  Future<void> fetchCurrentWeather(BuildContext context) async {
    try {
      print('[WeatherProvider] Starting fetchCurrentWeather...');
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get current location
      final position = await _weatherService.getCurrentLocation();
      print('[WeatherProvider] Got location: \\${position.latitude}, \\${position.longitude}');
      _currentLocation = position;
      // Get user's preferred unit
      final isCelsius = Provider.of<HomeProvider>(context, listen: false).isCelsius;
      final units = isCelsius ? 'metric' : 'imperial';
      // Fetch current weather data
      final weatherData = await _weatherService.getCurrentWeather(
        position.latitude, 
        position.longitude,
        units: units,
      );
      print('[WeatherProvider] Weather data fetched: \\${weatherData.temperature}');
      _currentWeather = weatherData;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('[WeatherProvider] Error: \\${e.toString()}');
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Fetch forecast data
  Future<void> fetchForecast(BuildContext context) async {
    try {
      if (_currentLocation == null) {
        _currentLocation = await _weatherService.getCurrentLocation();
      }
      
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      // Get user's preferred unit
      final isCelsius = Provider.of<HomeProvider>(context, listen: false).isCelsius;
      final units = isCelsius ? 'metric' : 'imperial';
      // Fetch forecast data
      final forecastData = await _weatherService.getForecast(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        units: units,
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
  Future<void> fetchWeatherData(BuildContext context) async {
    try {
      print('[WeatherProvider] Starting fetchWeatherData...');
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Prefer home address coordinates if set, else use device location
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      double latitude;
      double longitude;
      if (homeProvider.homeConfig.latitude != null && homeProvider.homeConfig.longitude != null) {
        latitude = homeProvider.homeConfig.latitude!;
        longitude = homeProvider.homeConfig.longitude!;
        print('[WeatherProvider] Using home address coordinates: \\${latitude}, \\${longitude}');
      } else {
        final position = await _weatherService.getCurrentLocation();
        latitude = position.latitude;
        longitude = position.longitude;
        print('[WeatherProvider] Using device location: \\${latitude}, \\${longitude}');
        _currentLocation = position;
      }
      
      // Get user's city/town using reverse geocoding
      try {
        final placemarks = await placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          _city = placemarks.first.locality ?? placemarks.first.subAdministrativeArea ?? placemarks.first.administrativeArea;
          // Try to get the most descriptive province/state
          final admin = placemarks.first.administrativeArea ?? '';
          final subAdmin = placemarks.first.subAdministrativeArea ?? '';
          final country = placemarks.first.country ?? '';
          // Prefer subAdmin if it's more descriptive than admin
          if (subAdmin.isNotEmpty && subAdmin != _city && subAdmin != country) {
            _province = subAdmin;
          } else if (admin.isNotEmpty && admin != _city && admin != country) {
            _province = admin;
          } else {
            _province = admin.isNotEmpty ? admin : subAdmin;
          }
          print('[WeatherProvider] Placemark: ${placemarks.first}');
          print('[WeatherProvider] Detected city/town: $_city, province/state: $_province');
          
          // Save location data for persistence
          await _saveLocationData();
        }
      } catch (geoErr) {
        print('[WeatherProvider] Reverse geocoding failed: \\${geoErr.toString()}');
        _city = null;
        _province = null;
      }
      // Get user's preferred unit
      final isCelsius = homeProvider.isCelsius;
      final units = isCelsius ? 'metric' : 'imperial';
      // Fetch both current weather and forecast data
      final weatherData = await _weatherService.getCurrentWeather(
        latitude, 
        longitude,
        units: units,
      );
      print('[WeatherProvider] Weather data fetched: \\${weatherData.temperature}');
      final forecastData = await _weatherService.getForecast(
        latitude,
        longitude,
        units: units,
      );
      print('[WeatherProvider] Forecast data fetched');
      // TODO: Reactivate severe weather alerts fetching when API key is active
      // final alerts = await _weatherService.getSevereWeatherAlerts(
      //   position.latitude,
      //   position.longitude,
      // );
      // print('[WeatherProvider] Alerts fetched: count=\\${alerts.length}');
      _currentWeather = weatherData;
      _forecast = forecastData;
      // _alerts = alerts; // TODO: Reactivate when API key is active
      
      // Generate wind forecast data
      generateWindForecast();
      
      _isLoading = false;
      notifyListeners();
      // TODO: Reactivate severe weather notification when API key is active
      // _checkSevereWeatherAndNotify(context);
    } catch (e) {
      print('[WeatherProvider] Error: \\${e.toString()}');
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Background refresh method that doesn't show loading indicators
  Future<void> backgroundRefresh(BuildContext context) async {
    try {
      print('[WeatherProvider] Starting background refresh...');
      
      // Get the current error state to restore it if refresh fails
      final previousError = _error;
      _error = null;

      // Prefer home address coordinates if set, else use device location
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      double latitude;
      double longitude;
      if (homeProvider.homeConfig.latitude != null && homeProvider.homeConfig.longitude != null) {
        latitude = homeProvider.homeConfig.latitude!;
        longitude = homeProvider.homeConfig.longitude!;
      } else {
        final position = await _weatherService.getCurrentLocation();
        latitude = position.latitude;
        longitude = position.longitude;
        _currentLocation = position;
      }
      
      // Get user's preferred unit
      final isCelsius = homeProvider.isCelsius;
      final units = isCelsius ? 'metric' : 'imperial';
      
      // Fetch both current weather and forecast data
      final weatherData = await _weatherService.getCurrentWeather(
        latitude, 
        longitude,
        units: units,
      );
      
      final forecastData = await _weatherService.getForecast(
        latitude,
        longitude,
        units: units,
      );
      
      _currentWeather = weatherData;
      _forecast = forecastData;
      
      // Generate wind forecast data
      generateWindForecast();
      
      print('[WeatherProvider] Background refresh completed successfully');
      notifyListeners();
      
    } catch (e) {
      print('[WeatherProvider] Background refresh error: ${e.toString()}');
      // Don't update error state for background refresh failures
      // This prevents showing error messages during automatic updates
    }
  }

  // Generate wind forecast data using real API forecast data
  void generateWindForecast() {
    if (_forecast == null || _forecast!.hourlyForecast.isEmpty) {
      // Fallback to demo data if no forecast is available
      _generateDemoWindForecast();
      return;
    }

    // Use real forecast data to create wind forecast
    _windForecast = _forecast!.hourlyForecast.map((weatherData) {
      return WindData(
        timestamp: weatherData.dateTime,
        speed: weatherData.windSpeed,
      );
    }).toList();

    // If we have fewer than 6 hours of forecast data, supplement with extrapolated data
    if (_windForecast.length < 6) {
      final existingCount = _windForecast.length;
      final lastWindSpeed = _windForecast.isNotEmpty ? _windForecast.last.speed : (_currentWeather?.windSpeed ?? 10.0);
      final lastTimestamp = _windForecast.isNotEmpty ? _windForecast.last.timestamp : DateTime.now();

      for (int i = existingCount; i < 6; i++) {
        final hour = lastTimestamp.add(Duration(hours: (i - existingCount + 1) * 3));
        // Create gradual variations for extrapolated data
        final variation = (i - existingCount) * 1.5;
        final speed = (lastWindSpeed + variation).clamp(0.0, 50.0);
        
        _windForecast.add(WindData(
          timestamp: hour,
          speed: speed,
        ));
      }
    }

    // Limit to 6 hours of forecast
    if (_windForecast.length > 6) {
      _windForecast = _windForecast.take(6).toList();
    }

    print('[WeatherProvider] Generated wind forecast with ${_windForecast.length} entries from real API data');
    notifyListeners();
  }

  // Fallback method for demo wind forecast when API data is unavailable
  void _generateDemoWindForecast() {
    final now = DateTime.now();
    final currentWindSpeed = _currentWeather?.windSpeed ?? 10.0;
    _windForecast = List.generate(6, (index) {
      final hour = now.add(Duration(hours: index * 3)); // Every 3 hours to match API intervals
      // Create realistic wind speed variations based on current wind speed
      final baseSpeed = currentWindSpeed;
      final variation = (index * 2.0) - 5.0; // Add some variation
      final speed = (baseSpeed + variation).clamp(0.0, 50.0);
      
      return WindData(
        timestamp: hour,
        speed: speed,
      );
    });
    print('[WeatherProvider] Generated demo wind forecast as fallback');
    notifyListeners();
  }

  // Get peak wind start time (when wind speed is highest)
  DateTime? getPeakWindStartTime() {
    if (_windForecast.isEmpty) return null;
    
    // Find the highest wind speed
    double maxSpeed = _windForecast.map((w) => w.speed).reduce((a, b) => a > b ? a : b);
    
    // Find periods where wind is at least 80% of max speed
    final threshold = maxSpeed * 0.8;
    final peakPeriods = <WindData>[];
    
    for (final wind in _windForecast) {
      if (wind.speed >= threshold) {
        peakPeriods.add(wind);
      }
    }
    
    if (peakPeriods.isEmpty) return null;
    
    // Return start of peak period
    return peakPeriods.first.timestamp;
  }

  // Get peak wind end time (when wind speed is highest)
  DateTime? getPeakWindEndTime() {
    if (_windForecast.isEmpty) return null;
    
    // Find the highest wind speed
    double maxSpeed = _windForecast.map((w) => w.speed).reduce((a, b) => a > b ? a : b);
    
    // Find periods where wind is at least 80% of max speed
    final threshold = maxSpeed * 0.8;
    final peakPeriods = <WindData>[];
    
    for (final wind in _windForecast) {
      if (wind.speed >= threshold) {
        peakPeriods.add(wind);
      }
    }
    
    if (peakPeriods.isEmpty) return null;
    
    // Return end of peak period
    return peakPeriods.last.timestamp.add(const Duration(hours: 1));
  }

  // TODO: Reactivate this method call in fetchWeatherData when API key is active
  void _checkSevereWeatherAndNotify(BuildContext context) async {
    if (_alerts.isEmpty) return;
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final homeConfig = homeProvider.homeConfig;
    final anyWindowOpen = homeConfig.windows.values.any((open) => open);
    if (!anyWindowOpen || !homeConfig.notificationsEnabled) return;
    // Look for severe alerts (e.g., storm, wind, etc.)
    final severe = _alerts.firstWhere(
      (a) => (a['event']?.toString().toLowerCase().contains('storm') == true ||
              a['event']?.toString().toLowerCase().contains('wind') == true ||
              a['event']?.toString().toLowerCase().contains('warning') == true),
      orElse: () => {},
    );
    if (severe.isNotEmpty) {
      final reason = severe['description'] ?? severe['event'] ?? 'Severe weather alert';
      // Show notification to close windows
      await NotificationService().showWindowCloseNotification(
        _currentWeather!,
        'Severe weather: $reason. Please close your windows!'
      );
    }
  }

  // Refresh weather data
  Future<void> refreshWeatherData(BuildContext context) async {
    _error = null;
    await fetchWeatherData(context);
  }

  // Load saved location data from SharedPreferences
  Future<void> _loadSavedLocationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final latitude = prefs.getDouble('saved_latitude');
      final longitude = prefs.getDouble('saved_longitude');
      final savedCity = prefs.getString('saved_city');
      final savedProvince = prefs.getString('saved_province');
      
      if (latitude != null && longitude != null) {
        _currentLocation = Position(
          latitude: latitude,
          longitude: longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        _city = savedCity;
        _province = savedProvince;
        print('[WeatherProvider] Loaded saved location: $savedCity, $savedProvince');
        notifyListeners();
      }
    } catch (e) {
      print('[WeatherProvider] Error loading saved location: $e');
    }
  }

  // Save location data to SharedPreferences
  Future<void> _saveLocationData() async {
    if (_currentLocation != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('saved_latitude', _currentLocation!.latitude);
        await prefs.setDouble('saved_longitude', _currentLocation!.longitude);
        if (_city != null) await prefs.setString('saved_city', _city!);
        if (_province != null) await prefs.setString('saved_province', _province!);
        print('[WeatherProvider] Saved location data: $_city, $_province');
      } catch (e) {
        print('[WeatherProvider] Error saving location: $e');
      }
    }
  }

  // Clear saved location data (for testing or user logout)
  Future<void> clearSavedLocationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_latitude');
      await prefs.remove('saved_longitude');
      await prefs.remove('saved_city');
      await prefs.remove('saved_province');
      _currentLocation = null;
      _city = null;
      _province = null;
      print('[WeatherProvider] Cleared saved location data');
      notifyListeners();
    } catch (e) {
      print('[WeatherProvider] Error clearing location data: $e');
    }
  }

  // Check if saved location data exists
  Future<bool> hasSavedLocationData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('saved_latitude') && prefs.containsKey('saved_longitude');
  }
}

ThemeData easyBreezyTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF181A20),
  colorScheme: ColorScheme.dark(
    primary: const Color(0xFF98AF99),
    secondary: const Color(0xFFD6DDC0),
    background: const Color(0xFF181A20),
    surface: const Color(0xFF23272F),
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onBackground: Colors.white,
    onSurface: Colors.white,
  ),
  cardColor: const Color(0xFF23272F),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF98AF99),
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF23272F),
    foregroundColor: Color(0xFF98AF99),
    elevation: 4,
    titleTextStyle: TextStyle(
      color: Color(0xFF98AF99),
      fontWeight: FontWeight.bold,
      fontSize: 22,
    ),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF23272F),
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Color(0xFF98AF99)),
    bodyMedium: TextStyle(color: Color(0xFF98AF99)),
    titleLarge: TextStyle(color: Color(0xFF98AF99), fontWeight: FontWeight.bold),
  ),
);