import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/location_model.dart';
import '../providers/weather_provider.dart';

class LocationProvider extends ChangeNotifier {
  List<LocationModel> _locations = [];
  LocationModel? _currentLocation;
  final int _maxLocations = 2; // Free tier limit
  
  List<LocationModel> get locations => _locations;
  LocationModel? get currentLocation => _currentLocation;
  int get maxLocations => _maxLocations;
  bool get canAddLocation => _locations.length < _maxLocations;
  
  /// Initialize the provider with saved locations
  Future<void> initialize() async {
    await _loadLocations();
    notifyListeners();
  }

  /// Ensure home location exists in saved locations
  Future<void> ensureHomeLocationExists({
    required String name,
    required String city,
    required String province,
    required double latitude,
    required double longitude,
  }) async {
    // Check if we already have a home location (isCurrentLocation = true)
    final hasHomeLocation = _locations.any((location) => location.isCurrentLocation);
    
    if (!hasHomeLocation && _locations.length < _maxLocations) {
      await addLocation(
        name: name,
        city: city,
        province: province,
        latitude: latitude,
        longitude: longitude,
        isCurrentLocation: true,
      );
    } else if (hasHomeLocation) {
      // Check if we need to update the name to include street address
      final homeLocation = _locations.firstWhere((location) => location.isCurrentLocation);
      if (homeLocation.name == "Home" && name != "Home" && name.isNotEmpty) {
        await _updateLocationName(homeLocation.id, name);
      }
    }
  }

  /// Update location name by ID
  Future<void> _updateLocationName(String locationId, String newName) async {
    final locationIndex = _locations.indexWhere((location) => location.id == locationId);
    if (locationIndex != -1) {
      final location = _locations[locationIndex];
      final updatedLocation = LocationModel(
        id: location.id,
        name: newName,
        city: location.city,
        province: location.province,
        latitude: location.latitude,
        longitude: location.longitude,
        isCurrentLocation: location.isCurrentLocation,
        createdAt: location.createdAt,
      );
      _locations[locationIndex] = updatedLocation;
      
      // Update current location if it's the same
      if (_currentLocation?.id == locationId) {
        _currentLocation = updatedLocation;
      }
      
      await _saveLocations();
      notifyListeners();
    }
  }
  
  /// Load locations from SharedPreferences
  Future<void> _loadLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson = prefs.getStringList('saved_locations') ?? [];
      final currentLocationId = prefs.getString('current_location_id');
      
      _locations = locationsJson
          .map((json) => LocationModel.fromJson(jsonDecode(json)))
          .toList();
      
      // Set current location
      if (currentLocationId != null) {
        try {
          _currentLocation = _locations.firstWhere(
            (location) => location.id == currentLocationId,
          );
        } catch (e) {
          // If location not found, use first available location
          if (_locations.isNotEmpty) {
            _currentLocation = _locations.first;
          }
        }
      } else if (_locations.isNotEmpty) {
        _currentLocation = _locations.first;
      }
    } catch (e) {
      print('Error loading locations: $e');
      _locations = [];
      _currentLocation = null;
    }
  }
  
  /// Save locations to SharedPreferences
  Future<void> _saveLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson = _locations
          .map((location) => jsonEncode(location.toJson()))
          .toList();
      
      await prefs.setStringList('saved_locations', locationsJson);
      if (_currentLocation != null) {
        await prefs.setString('current_location_id', _currentLocation!.id);
      }
    } catch (e) {
      print('Error saving locations: $e');
    }
  }
  
  /// Add a new location
  Future<bool> addLocation({
    required String name,
    required String city,
    required String province,
    required double latitude,
    required double longitude,
    bool isCurrentLocation = false,
  }) async {
    // If this is the first location being added and we don't have the current weather location saved,
    // automatically save the current weather location first
    if (_locations.isEmpty && _currentLocation == null) {
      await _saveCurrentWeatherLocationIfNeeded();
    }
    
    if (!canAddLocation) {
      return false; // Reached max locations limit
    }
    
    final newLocation = LocationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      city: city,
      province: province,
      latitude: latitude,
      longitude: longitude,
      isCurrentLocation: isCurrentLocation,
      createdAt: DateTime.now(),
    );
    
    _locations.add(newLocation);
    
    // If this is the first location or marked as current, set it as current
    if (_currentLocation == null || isCurrentLocation) {
      _currentLocation = newLocation;
    }
    
    await _saveLocations();
    notifyListeners();
    return true;
  }

  /// Automatically save the current weather location when adding the first manual location
  Future<void> _saveCurrentWeatherLocationIfNeeded() async {
    try {
      // We need to access the current weather provider to get the current location details
      // This is a bit tricky since we don't have direct access to WeatherProvider here
      // For now, we'll implement this in the UI layer where we have access to both providers
    } catch (e) {
      print('Error saving current weather location: $e');
    }
  }
  
  /// Remove a location
  Future<bool> removeLocation(String locationId) async {
    final locationIndex = _locations.indexWhere((loc) => loc.id == locationId);
    if (locationIndex == -1) return false;
    
    final removedLocation = _locations.removeAt(locationIndex);
    
    // If we removed the current location, switch to the first available
    if (_currentLocation?.id == locationId) {
      _currentLocation = _locations.isNotEmpty ? _locations.first : null;
    }
    
    await _saveLocations();
    notifyListeners();
    return true;
  }
  
  /// Switch to a different location
  Future<void> switchToLocation(String locationId, WeatherProvider weatherProvider) async {
    LocationModel? location;
    try {
      location = _locations.firstWhere(
        (loc) => loc.id == locationId,
      );
    } catch (e) {
      // Location not found
      return;
    }
    
    if (location == null) return;
    
    _currentLocation = location;
    await _saveLocations();
    
    // Update weather data for the new location
    await weatherProvider.fetchWeatherDataForLocation(
      latitude: location.latitude,
      longitude: location.longitude,
      city: location.city,
      province: location.province,
    );
    
    notifyListeners();
  }
  
  /// Update current location data from GPS
  Future<void> updateCurrentLocationData({
    required String city,
    required String province,
    required double latitude,
    required double longitude,
  }) async {
    // Check if we have a "Current Location" entry
    final currentLocationIndex = _locations.indexWhere(
      (loc) => loc.isCurrentLocation,
    );
    
    if (currentLocationIndex != -1) {
      // Update existing current location
      _locations[currentLocationIndex] = _locations[currentLocationIndex].copyWith(
        city: city,
        province: province,
        latitude: latitude,
        longitude: longitude,
      );
    } else if (canAddLocation) {
      // Add new current location
      await addLocation(
        name: 'Current Location',
        city: city,
        province: province,
        latitude: latitude,
        longitude: longitude,
        isCurrentLocation: true,
      );
    }
    
    await _saveLocations();
    notifyListeners();
  }
}
