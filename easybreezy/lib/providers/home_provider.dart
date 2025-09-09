// Needed import
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/home_config.dart';

class HomeProvider extends ChangeNotifier {
  HomeConfig _homeConfig = HomeConfig.defaultConfig();
  bool _isOnboardingCompleted = false;
  bool _isCelsius = true;
  bool _isPremiumUser = false; // Add premium status
  bool _isInitialized = false; // Track initialization status
  String? _selectedCountry; // Add country field

  HomeConfig get homeConfig => _homeConfig;
  bool get isOnboardingCompleted => _isOnboardingCompleted;
  bool get isCelsius => _isCelsius;
  bool get isPremiumUser => _isPremiumUser; // Getter for premium status
  bool get isInitialized => _isInitialized; // Getter for initialization status
  String? get selectedCountry => _selectedCountry; // Getter for country

  // Constructor loads data from shared preferences when initialized
  HomeProvider() {
    _initializeProvider();
  }

  // Initialize provider with proper async handling
  Future<void> _initializeProvider() async {
    await _loadHomeConfig();
    _isInitialized = true;
    notifyListeners();
  }

  // Load home configuration from shared preferences
  Future<void> _loadHomeConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final homeConfigJson = prefs.getString('homeConfig');
    final onboardingCompleted = prefs.getBool('onboardingCompleted') ?? false;
    final isCelsiusPref = prefs.getBool('isCelsius');
    final isPremiumPref = prefs.getBool('isPremiumUser') ?? false; // Load premium status
    final selectedCountryPref = prefs.getString('selectedCountry'); // Load country
    print('DEBUG: HomeProvider loading country from SharedPreferences: $selectedCountryPref');
    
    if (homeConfigJson != null) {
      try {
        _homeConfig = HomeConfig.fromJson(
          Map<String, dynamic>.from(
            Map<String, dynamic>.from(
              _parseJsonMap(homeConfigJson),
            ),
          ),
        );
      } catch (e) {
        debugPrint('Error parsing home config: $e');
        _homeConfig = HomeConfig.defaultConfig();
      }
    }
    
    _isOnboardingCompleted = onboardingCompleted;
    _isPremiumUser = isPremiumPref; // Set premium status
    _selectedCountry = selectedCountryPref; // Set country
    print('DEBUG: HomeProvider set selectedCountry to: $_selectedCountry');
    if (isCelsiusPref != null) {
      _isCelsius = isCelsiusPref;
    }
    notifyListeners();
  }

  // Parse JSON string to Map
  Map<String, dynamic> _parseJsonMap(String jsonString) {
    return Map<String, dynamic>.from(
      Map<String, dynamic>.from(
        jsonDecode(jsonString) as Map<dynamic, dynamic>,
      ),
    );
  }

  // Save home configuration to shared preferences
  Future<void> _saveHomeConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final homeConfigJson = jsonEncode(_homeConfig.toJson());
    await prefs.setString('homeConfig', homeConfigJson);
    await prefs.setBool('onboardingCompleted', _isOnboardingCompleted);
    await prefs.setBool('isCelsius', _isCelsius);
    await prefs.setBool('isPremiumUser', _isPremiumUser); // Save premium status
    if (_selectedCountry != null) {
      await prefs.setString('selectedCountry', _selectedCountry!); // Save country
    }
  }

  // Update home orientation
  void updateHomeOrientation(HomeOrientation orientation) {
    _homeConfig = _homeConfig.copyWith(orientation: orientation);
    _saveHomeConfig();
    notifyListeners();
  }

  // Update windows configuration
  void updateWindows(Map<WindowDirection, bool> windows) {
    _homeConfig = _homeConfig.copyWith(windows: windows);
    _saveHomeConfig();
    notifyListeners();
  }

  // Update a specific window direction
  void toggleWindow(WindowDirection direction, bool isPresent) {
    final updatedWindows = Map<WindowDirection, bool>.from(_homeConfig.windows);
    updatedWindows[direction] = isPresent;
    
    _homeConfig = _homeConfig.copyWith(windows: updatedWindows);
    _saveHomeConfig();
    notifyListeners();
  }

  // Update comfort temperature range
  void updateComfortTemperature(double min, double max) {
    _homeConfig = _homeConfig.copyWith(
      comfortTempMin: min,
      comfortTempMax: max,
    );
    _saveHomeConfig();
    notifyListeners();
  }

  // Toggle notifications
  void toggleNotifications(bool enabled) {
    _homeConfig = _homeConfig.copyWith(notificationsEnabled: enabled);
    _saveHomeConfig();
    notifyListeners();
  }

  // Mark onboarding as completed
  void completeOnboarding() {
    _isOnboardingCompleted = true;
    _saveHomeConfig();
    notifyListeners();
  }

  // Check if user has completed initial setup (onboarding + has location data)
  Future<bool> hasCompletedInitialSetup() async {
    if (!_isOnboardingCompleted) return false;
    
    // Check if location data exists
    final prefs = await SharedPreferences.getInstance();
    final hasLocationData = prefs.containsKey('saved_latitude') && 
                           prefs.containsKey('saved_longitude');
    
    return hasLocationData;
  }

  // Add method to toggle temperature unit
  void toggleTemperatureUnit() {
    _isCelsius = !_isCelsius;
    _saveHomeConfig();
    notifyListeners();
  }

  // Update address
  void updateAddress(String address) {
    _homeConfig = _homeConfig.copyWith(address: address);
    _saveHomeConfig();
    notifyListeners();
  }

  // Update address and coordinates
  void updateAddressWithCoords(String address, double? latitude, double? longitude) {
    _homeConfig = _homeConfig.copyWith(address: address, latitude: latitude, longitude: longitude);
    _saveHomeConfig();
    notifyListeners();
  }

  // Update selected country
  void updateCountry(String country) {
    print('DEBUG: HomeProvider updateCountry called with: $country');
    _selectedCountry = country;
    _saveHomeConfig();
    notifyListeners();
    print('DEBUG: HomeProvider selectedCountry updated to: $_selectedCountry');
  }

  // Upgrade to premium
  void upgradeToPremium() {
    _isPremiumUser = true;
    _saveHomeConfig();
    notifyListeners();
  }

  // Reset premium status (for testing)
  void resetPremiumStatus() {
    _isPremiumUser = false;
    _saveHomeConfig();
    notifyListeners();
  }

  // Full reset: clear onboarding and home config
  Future<void> resetOnboardingAndConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('homeConfig');
    await prefs.setBool('onboardingCompleted', false);
    _homeConfig = HomeConfig.defaultConfig();
    _isOnboardingCompleted = false;
    notifyListeners();
  }

  // Helper method for JSON encoding/decoding
  dynamic jsonDecode(String source) {
    return json.decode(source);
  }

  dynamic jsonEncode(Object? object) {
    return json.encode(object);
  }
}

