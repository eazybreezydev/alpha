import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics service for tracking user interactions and app usage
class FirebaseAnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver _observer = FirebaseAnalyticsObserver(analytics: _analytics);
  
  /// Get the analytics observer for navigation tracking
  static FirebaseAnalyticsObserver get observer => _observer;
  
  /// Initialize Firebase Analytics
  static Future<void> initialize() async {
    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        print('❌ Firebase not initialized, skipping analytics setup');
        return;
      }
      
      // Enable analytics collection (enabled by default)
      await _analytics.setAnalyticsCollectionEnabled(true);
      
      print('✅ Firebase Analytics initialized successfully');
      
      // Log app open event with default parameters
      await logAppOpen();
      
    } catch (e) {
      print('❌ Error initializing Firebase Analytics: $e');
    }
  }
  
  /// Log app open event
  static Future<void> logAppOpen() async {
    try {
      await _analytics.logAppOpen();
      
      // Add default app parameters as a custom event
      await _analytics.logEvent(
        name: 'app_info',
        parameters: {
          'app_version': '1.0.0',
          'platform': defaultTargetPlatform.name,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      print('📊 Analytics: App opened with platform info');
    } catch (e) {
      print('❌ Error logging app open: $e');
    }
  }
  
  /// Log user login
  static Future<void> logLogin(String loginMethod) async {
    try {
      await _analytics.logLogin(loginMethod: loginMethod);
      print('📊 Analytics: User login - $loginMethod');
    } catch (e) {
      print('❌ Error logging login: $e');
    }
  }
  
  /// Log screen view
  static Future<void> logScreenView(String screenName, {String? screenClass}) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      print('📊 Analytics: Screen view - $screenName');
    } catch (e) {
      print('❌ Error logging screen view: $e');
    }
  }
  
  /// Log custom event
  static Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      print('📊 Analytics: Custom event - $name');
    } catch (e) {
      print('❌ Error logging custom event: $e');
    }
  }
  
  /// Log notification interaction
  static Future<void> logNotificationEvent(String action, String notificationType) async {
    try {
      await _analytics.logEvent(
        name: 'notification_interaction',
        parameters: {
          'action': action, // 'enabled', 'disabled', 'test_sent'
          'notification_type': notificationType,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      print('📊 Analytics: Notification event - $action for $notificationType');
    } catch (e) {
      print('❌ Error logging notification event: $e');
    }
  }
  
  /// Log weather data view
  static Future<void> logWeatherDataView(String location, String dataType) async {
    try {
      await _analytics.logEvent(
        name: 'weather_data_view',
        parameters: {
          'location': location,
          'data_type': dataType, // 'current', 'forecast', 'history'
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      print('📊 Analytics: Weather data view - $dataType for $location');
    } catch (e) {
      print('❌ Error logging weather data view: $e');
    }
  }
  
  /// Log ventilation action
  static Future<void> logVentilationAction(String action, Map<String, dynamic>? context) async {
    try {
      await _analytics.logEvent(
        name: 'ventilation_action',
        parameters: {
          'action': action, // 'open_windows', 'close_windows', 'check_alignment'
          'wind_speed': context?['wind_speed'],
          'wind_direction': context?['wind_direction'],
          'air_quality': context?['air_quality'],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      print('📊 Analytics: Ventilation action - $action');
    } catch (e) {
      print('❌ Error logging ventilation action: $e');
    }
  }
  
  /// Log settings change
  static Future<void> logSettingsChange(String setting, dynamic oldValue, dynamic newValue) async {
    try {
      await _analytics.logEvent(
        name: 'settings_change',
        parameters: {
          'setting_name': setting,
          'old_value': oldValue?.toString() ?? 'null',
          'new_value': newValue?.toString() ?? 'null',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      print('📊 Analytics: Settings change - $setting: $oldValue → $newValue');
    } catch (e) {
      print('❌ Error logging settings change: $e');
    }
  }
  
  /// Log error event
  static Future<void> logError(String errorType, String errorMessage, {String? stackTrace}) async {
    try {
      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error_type': errorType,
          'error_message': errorMessage.length > 100 ? errorMessage.substring(0, 100) : errorMessage,
          'has_stack_trace': stackTrace != null,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      print('📊 Analytics: Error logged - $errorType');
    } catch (e) {
      print('❌ Error logging error event: $e');
    }
  }
  
  /// Log feature usage
  static Future<void> logFeatureUsage(String featureName, {Map<String, dynamic>? context}) async {
    try {
      final parameters = <String, Object>{
        'feature_name': featureName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      if (context != null) {
        context.forEach((key, value) {
          if (value != null) {
            parameters[key] = value.toString();
          }
        });
      }
      
      await _analytics.logEvent(
        name: 'feature_usage',
        parameters: parameters,
      );
      print('📊 Analytics: Feature usage - $featureName');
    } catch (e) {
      print('❌ Error logging feature usage: $e');
    }
  }
  
  /// Set user properties
  static Future<void> setUserProperties({
    String? userId,
    String? userType,
    String? location,
    String? deviceType,
  }) async {
    try {
      if (userId != null) {
        await _analytics.setUserId(id: userId);
      }
      
      await _analytics.setUserProperty(name: 'user_type', value: userType ?? 'regular');
      await _analytics.setUserProperty(name: 'location', value: location ?? 'unknown');
      await _analytics.setUserProperty(name: 'device_type', value: deviceType ?? defaultTargetPlatform.name);
      
      print('📊 Analytics: User properties set');
    } catch (e) {
      print('❌ Error setting user properties: $e');
    }
  }
  
  /// Log session start
  static Future<void> logSessionStart() async {
    try {
      await _analytics.logEvent(
        name: 'session_start',
        parameters: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'platform': defaultTargetPlatform.name,
        },
      );
      print('📊 Analytics: Session started');
    } catch (e) {
      print('❌ Error logging session start: $e');
    }
  }
  
  /// Log session end
  static Future<void> logSessionEnd(Duration sessionDuration) async {
    try {
      await _analytics.logEvent(
        name: 'session_end',
        parameters: {
          'session_duration_seconds': sessionDuration.inSeconds,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      print('📊 Analytics: Session ended - ${sessionDuration.inMinutes} minutes');
    } catch (e) {
      print('❌ Error logging session end: $e');
    }
  }
}
