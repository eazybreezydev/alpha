// Needed import
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/home_config.dart';

class HomeProvider extends ChangeNotifier {
  HomeConfig _homeConfig = HomeConfig.defaultConfig();
  bool _isOnboardingCompleted = false;

  HomeConfig get homeConfig => _homeConfig;
  bool get isOnboardingCompleted => _isOnboardingCompleted;

  // Constructor loads data from shared preferences when initialized
  HomeProvider() {
    _loadHomeConfig();
  }

  // Load home configuration from shared preferences
  Future<void> _loadHomeConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final homeConfigJson = prefs.getString('homeConfig');
    final onboardingCompleted = prefs.getBool('onboardingCompleted') ?? false;
    
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
    await prefs.setString('homeConfig', jsonEncode(_homeConfig.toJson()));
    await prefs.setBool('onboardingCompleted', _isOnboardingCompleted);
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

  // Helper method for JSON encoding/decoding
  dynamic jsonDecode(String source) {
    return json.decode(source);
  }

  dynamic jsonEncode(Object? object) {
    return json.encode(object);
  }
}

