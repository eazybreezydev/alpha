import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/weather_provider.dart';

/// Service to handle automatic data refresh at regular intervals
class AutoRefreshService with WidgetsBindingObserver {
  static final AutoRefreshService _instance = AutoRefreshService._internal();
  factory AutoRefreshService() => _instance;
  AutoRefreshService._internal();

  Timer? _refreshTimer;
  bool _isEnabled = true;
  bool _isRefreshing = false;
  bool _isAppActive = true;
  BuildContext? _context;
  
  // 15 minutes in seconds
  static const int _refreshIntervalSeconds = 15 * 60;
  static const String _preferenceKey = 'auto_refresh_enabled';
  
  /// Initialize the auto-refresh service with a build context
  void initialize(BuildContext context) async {
    _context = context;
    // Add this service as a lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    // Load saved preference
    await _loadPreference();
    if (_isEnabled) {
      _startAutoRefresh();
    }
  }
  
  /// Load the auto-refresh preference from SharedPreferences
  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_preferenceKey) ?? true; // Default to enabled
      
      if (kDebugMode) {
        print('[AutoRefreshService] Loaded preference: auto-refresh ${_isEnabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AutoRefreshService] Failed to load preference: $e');
      }
      _isEnabled = true; // Default to enabled on error
    }
  }
  
  /// Save the auto-refresh preference to SharedPreferences
  Future<void> _savePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_preferenceKey, _isEnabled);
      
      if (kDebugMode) {
        print('[AutoRefreshService] Saved preference: auto-refresh ${_isEnabled ? 'enabled' : 'disabled'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AutoRefreshService] Failed to save preference: $e');
      }
    }
  }

  /// Start the auto-refresh timer
  void _startAutoRefresh() {
    if (!_isEnabled || !_isAppActive) return;
    
    // Cancel any existing timer
    _refreshTimer?.cancel();
    
    // Create a new periodic timer
    _refreshTimer = Timer.periodic(
      const Duration(seconds: _refreshIntervalSeconds),
      (timer) => _performAutoRefresh(),
    );
    
    if (kDebugMode) {
      print('[AutoRefreshService] Auto-refresh started - will refresh every 15 minutes');
    }
  }

  /// Perform the actual refresh operation
  Future<void> _performAutoRefresh() async {
    if (!_isEnabled || _isRefreshing || _context == null || !_isAppActive) {
      return;
    }

    try {
      _isRefreshing = true;
      
      if (kDebugMode) {
        print('[AutoRefreshService] Starting automatic data refresh...');
      }

      // Get the weather provider and refresh data using background method
      final weatherProvider = Provider.of<WeatherProvider>(_context!, listen: false);
      await weatherProvider.backgroundRefresh(_context!);
      
      if (kDebugMode) {
        print('[AutoRefreshService] Automatic refresh completed successfully');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('[AutoRefreshService] Auto-refresh failed: $e');
      }
    } finally {
      _isRefreshing = false;
    }
  }

  /// Enable auto-refresh functionality
  void enable() async {
    if (_isEnabled) return;
    
    _isEnabled = true;
    await _savePreference();
    _startAutoRefresh();
    
    if (kDebugMode) {
      print('[AutoRefreshService] Auto-refresh enabled');
    }
  }

  /// Disable auto-refresh functionality
  void disable() async {
    if (!_isEnabled) return;
    
    _isEnabled = false;
    await _savePreference();
    _refreshTimer?.cancel();
    _refreshTimer = null;
    
    if (kDebugMode) {
      print('[AutoRefreshService] Auto-refresh disabled');
    }
  }

  /// Manual refresh that respects the auto-refresh state
  Future<void> manualRefresh() async {
    if (_context == null) return;
    
    try {
      if (kDebugMode) {
        print('[AutoRefreshService] Manual refresh triggered');
      }
      
      final weatherProvider = Provider.of<WeatherProvider>(_context!, listen: false);
      await weatherProvider.fetchWeatherData(_context!);
      
      // Reset the timer to avoid duplicate refresh shortly after manual refresh
      if (_isEnabled) {
        _refreshTimer?.cancel();
        _startAutoRefresh();
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('[AutoRefreshService] Manual refresh failed: $e');
      }
      rethrow;
    }
  }
  
  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App is back in foreground
        _isAppActive = true;
        if (_isEnabled) {
          _startAutoRefresh();
          // Also trigger an immediate refresh when app comes back to foreground
          _performAutoRefresh();
        }
        if (kDebugMode) {
          print('[AutoRefreshService] App resumed - auto-refresh reactivated');
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is going to background
        _isAppActive = false;
        _refreshTimer?.cancel();
        _refreshTimer = null;
        if (kDebugMode) {
          print('[AutoRefreshService] App paused - auto-refresh paused to save battery');
        }
        break;
    }
  }

  /// Get the current auto-refresh status
  bool get isEnabled => _isEnabled;
  
  /// Get the refresh interval in minutes
  int get refreshIntervalMinutes => _refreshIntervalSeconds ~/ 60;
  
  /// Get the next refresh time (approximate)
  DateTime? get nextRefreshTime {
    if (!_isEnabled || _refreshTimer == null) return null;
    
    return DateTime.now().add(
      Duration(seconds: _refreshIntervalSeconds),
    );
  }

  /// Dispose of the service and clean up resources
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _context = null;
    _isRefreshing = false;
    
    if (kDebugMode) {
      print('[AutoRefreshService] Service disposed');
    }
  }

  /// Update the context reference (useful when navigating between screens)
  void updateContext(BuildContext context) {
    _context = context;
  }
}
