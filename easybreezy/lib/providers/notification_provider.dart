import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_messaging_service.dart';

class NotificationProvider extends ChangeNotifier {
  // Notification preference keys
  static const String _notificationsEnabledKey = 'notifications_enabled';
  
  // Ventilation Alerts
  static const String _openWindowsAlertKey = 'open_windows_alert';
  static const String _closeWindowsAlertKey = 'close_windows_alert';
  static const String _windAlignmentAlertKey = 'wind_alignment_alert';
  
  // Weather Warnings
  static const String _rainAlertKey = 'rain_alert';
  static const String _stormWarningKey = 'storm_warning';
  static const String _highWindAdvisoryKey = 'high_wind_advisory';
  
  // Forecast-Based Notifications
  static const String _ventilationOpportunityKey = 'ventilation_opportunity';
  static const String _poorAirQualityKey = 'poor_air_quality';
  static const String _highPollenAlertKey = 'high_pollen_alert';
  static const String _smokeAdvisoryKey = 'smoke_advisory';
  
  // Daily Summary
  static const String _dailyMorningSummaryKey = 'daily_morning_summary';
  static const String _weeklyReportKey = 'weekly_report';
  
  // System & Efficiency
  static const String _energyTipKey = 'energy_tip';
  static const String _costSavingKey = 'cost_saving';
  static const String _systemStatusKey = 'system_status';
  static const String _maintenanceReminderKey = 'maintenance_reminder';

  // Current state
  bool _notificationsEnabled = true;
  bool _isLoading = true;
  String? _fcmToken;
  
  // Ventilation Alerts
  bool _openWindowsAlert = true;
  bool _closeWindowsAlert = true;
  bool _windAlignmentAlert = true;
  
  // Weather Warnings
  bool _rainAlert = true;
  bool _stormWarning = true;
  bool _highWindAdvisory = true;
  
  // Forecast-Based Notifications
  bool _ventilationOpportunity = true;
  bool _poorAirQuality = true;
  bool _highPollenAlert = false;
  bool _smokeAdvisory = true;
  
  // Daily Summary
  bool _dailyMorningSummary = true;
  bool _weeklyReport = true;
  
  // System & Efficiency
  bool _energyTip = true;
  bool _costSaving = true;
  bool _systemStatus = false;
  bool _maintenanceReminder = true;

  // Getters
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isLoading => _isLoading;
  String? get fcmToken => _fcmToken;

  /// Refresh FCM token
  Future<String?> refreshFCMToken() async {
    try {
      print('🔄 Refreshing FCM token...');
      _fcmToken = await FirebaseMessagingService.getToken(maxRetries: 3);
      
      if (_fcmToken == null) {
        print('⚠️ FCM token refresh failed, trying test token');
        _fcmToken = await FirebaseMessagingService.getTestToken();
      }
      
      print('✅ FCM token refreshed: ${_fcmToken?.substring(0, 20) ?? 'null'}...');
      notifyListeners();
      return _fcmToken;
    } catch (e) {
      print('❌ Error refreshing FCM token: $e');
      return null;
    }
  }
  
  // Ventilation Alerts
  bool get openWindowsAlert => _openWindowsAlert;
  bool get closeWindowsAlert => _closeWindowsAlert;
  bool get windAlignmentAlert => _windAlignmentAlert;
  
  // Weather Warnings
  bool get rainAlert => _rainAlert;
  bool get stormWarning => _stormWarning;
  bool get highWindAdvisory => _highWindAdvisory;
  
  // Forecast-Based Notifications
  bool get ventilationOpportunity => _ventilationOpportunity;
  bool get poorAirQuality => _poorAirQuality;
  bool get highPollenAlert => _highPollenAlert;
  bool get smokeAdvisory => _smokeAdvisory;
  
  // Daily Summary
  bool get dailyMorningSummary => _dailyMorningSummary;
  bool get weeklyReport => _weeklyReport;
  
  // System & Efficiency
  bool get energyTip => _energyTip;
  bool get costSaving => _costSaving;
  bool get systemStatus => _systemStatus;
  bool get maintenanceReminder => _maintenanceReminder;

  /// Initialize notification preferences
  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _loadPreferences();
      await _initializeFirebaseMessaging();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error initializing NotificationProvider: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
    
    // Ventilation Alerts
    _openWindowsAlert = prefs.getBool(_openWindowsAlertKey) ?? true;
    _closeWindowsAlert = prefs.getBool(_closeWindowsAlertKey) ?? true;
    _windAlignmentAlert = prefs.getBool(_windAlignmentAlertKey) ?? true;
    
    // Weather Warnings
    _rainAlert = prefs.getBool(_rainAlertKey) ?? true;
    _stormWarning = prefs.getBool(_stormWarningKey) ?? true;
    _highWindAdvisory = prefs.getBool(_highWindAdvisoryKey) ?? true;
    
    // Forecast-Based Notifications
    _ventilationOpportunity = prefs.getBool(_ventilationOpportunityKey) ?? true;
    _poorAirQuality = prefs.getBool(_poorAirQualityKey) ?? true;
    _highPollenAlert = prefs.getBool(_highPollenAlertKey) ?? false;
    _smokeAdvisory = prefs.getBool(_smokeAdvisoryKey) ?? true;
    
    // Daily Summary
    _dailyMorningSummary = prefs.getBool(_dailyMorningSummaryKey) ?? true;
    _weeklyReport = prefs.getBool(_weeklyReportKey) ?? true;
    
    // System & Efficiency
    _energyTip = prefs.getBool(_energyTipKey) ?? true;
    _costSaving = prefs.getBool(_costSavingKey) ?? true;
    _systemStatus = prefs.getBool(_systemStatusKey) ?? false;
    _maintenanceReminder = prefs.getBool(_maintenanceReminderKey) ?? true;
  }

  /// Initialize Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    try {
      print('🔔 Initializing Firebase Messaging in NotificationProvider...');
      
      // Check if Firebase is initialized
      if (!FirebaseMessagingService.isInitialized()) {
        print('❌ Firebase not initialized, skipping messaging setup');
        return;
      }
      
      // Set up notification listeners
      FirebaseMessagingService.setNotificationListeners(
        onReceived: _onNotificationReceived,
        onTapped: _onNotificationTapped,
      );
      
      // Get FCM token with retries
      print('🔄 Getting FCM token...');
      _fcmToken = await FirebaseMessagingService.getToken(maxRetries: 3);
      
      if (_fcmToken == null) {
        print('⚠️ FCM token is null, trying test token');
        _fcmToken = await FirebaseMessagingService.getTestToken();
      }
      
      print('✅ FCM token obtained: ${_fcmToken?.substring(0, 20) ?? 'null'}...');
      
      // Subscribe to relevant topics based on preferences
      await _updateTopicSubscriptions();
      
    } catch (e) {
      print('❌ Error initializing Firebase Messaging in provider: $e');
      // Use a fallback token for testing
      _fcmToken = 'error_fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Handle received notifications
  void _onNotificationReceived(NotificationData data) {
    print('📱 Notification received in provider: ${data.type}');
    // You can add custom handling here, like updating app state
    // or triggering specific actions based on notification type
  }

  /// Handle notification taps
  void _onNotificationTapped(NotificationData data) {
    print('👆 Notification tapped in provider: ${data.type}');
    // Handle navigation or specific actions when user taps notification
    // This could trigger navigation to specific screens based on notification type
  }

  /// Update topic subscriptions based on current preferences
  Future<void> _updateTopicSubscriptions() async {
    if (!_notificationsEnabled) {
      // Unsubscribe from all topics if notifications are disabled
      await _unsubscribeFromAllTopics();
      return;
    }

    // Subscribe/unsubscribe based on individual preferences
    await _updateTopicSubscription('wind_alerts', _openWindowsAlert || _closeWindowsAlert || _windAlignmentAlert);
    await _updateTopicSubscription('weather_warnings', _rainAlert || _stormWarning || _highWindAdvisory);
    await _updateTopicSubscription('air_quality', _poorAirQuality || _smokeAdvisory);
    await _updateTopicSubscription('energy_tips', _energyTip || _costSaving);
    await _updateTopicSubscription('daily_reports', _dailyMorningSummary || _weeklyReport);
    await _updateTopicSubscription('system_alerts', _systemStatus || _maintenanceReminder);
    
    // Always subscribe to critical alerts if notifications are enabled
    await FirebaseMessagingService.subscribeToTopic('critical_alerts');
  }

  /// Subscribe or unsubscribe from a topic
  Future<void> _updateTopicSubscription(String topic, bool shouldSubscribe) async {
    if (shouldSubscribe) {
      await FirebaseMessagingService.subscribeToTopic(topic);
    } else {
      await FirebaseMessagingService.unsubscribeFromTopic(topic);
    }
  }

  /// Unsubscribe from all topics
  Future<void> _unsubscribeFromAllTopics() async {
    final topics = [
      'wind_alerts',
      'weather_warnings', 
      'air_quality',
      'energy_tips',
      'daily_reports',
      'system_alerts',
      'critical_alerts',
      'all_users'
    ];
    
    for (final topic in topics) {
      await FirebaseMessagingService.unsubscribeFromTopic(topic);
    }
  }

  /// Toggle main notifications setting
  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    await _savePreference(_notificationsEnabledKey, enabled);
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  /// Toggle individual notification types
  Future<void> toggleOpenWindowsAlert(bool enabled) async {
    _openWindowsAlert = enabled;
    await _savePreference(_openWindowsAlertKey, enabled);
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  Future<void> toggleCloseWindowsAlert(bool enabled) async {
    _closeWindowsAlert = enabled;
    await _savePreference(_closeWindowsAlertKey, enabled);
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  Future<void> toggleWindAlignmentAlert(bool enabled) async {
    _windAlignmentAlert = enabled;
    await _savePreference(_windAlignmentAlertKey, enabled);
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  Future<void> toggleRainAlert(bool enabled) async {
    _rainAlert = enabled;
    await _savePreference(_rainAlertKey, enabled);
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  Future<void> toggleStormWarning(bool enabled) async {
    _stormWarning = enabled;
    await _savePreference(_stormWarningKey, enabled);
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  Future<void> toggleHighWindAdvisory(bool enabled) async {
    _highWindAdvisory = enabled;
    await _savePreference(_highWindAdvisoryKey, enabled);
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  Future<void> toggleVentilationOpportunity(bool enabled) async {
    _ventilationOpportunity = enabled;
    await _savePreference(_ventilationOpportunityKey, enabled);
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  Future<void> togglePoorAirQuality(bool enabled) async {
    _poorAirQuality = enabled;
    await _savePreference(_poorAirQualityKey, enabled);
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  Future<void> toggleHighPollenAlert(bool enabled) async {
    _highPollenAlert = enabled;
    await _savePreference(_highPollenAlertKey, enabled);
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  Future<void> toggleSmokeAdvisory(bool enabled) async {
    _smokeAdvisory = enabled;
    await _savePreference(_smokeAdvisoryKey, enabled);
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  Future<void> toggleDailyMorningSummary(bool enabled) async {
    _dailyMorningSummary = enabled;
    await _savePreference(_dailyMorningSummaryKey, enabled);
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  Future<void> toggleWeeklyReport(bool enabled) async {
    _weeklyReport = enabled;
    await _savePreference(_weeklyReportKey, enabled);
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  Future<void> toggleEnergyTip(bool enabled) async {
    _energyTip = enabled;
    await _savePreference(_energyTipKey, enabled);
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  Future<void> toggleCostSaving(bool enabled) async {
    _costSaving = enabled;
    await _savePreference(_costSavingKey, enabled);
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  Future<void> toggleSystemStatus(bool enabled) async {
    _systemStatus = enabled;
    await _savePreference(_systemStatusKey, enabled);
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  Future<void> toggleMaintenanceReminder(bool enabled) async {
    _maintenanceReminder = enabled;
    await _savePreference(_maintenanceReminderKey, enabled);
    await _updateTopicSubscriptions();
    notifyListeners();
  }

  /// Save individual preference
  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// Send test notification for specific type
  Future<void> sendTestNotification(NotificationType type) async {
    if (!_notificationsEnabled) {
      print('❌ Cannot send test notification - notifications are disabled');
      return;
    }
    
    await FirebaseMessagingService.sendTestNotification(type);
  }

  /// Check if device notifications are enabled
  Future<bool> checkNotificationPermissions() async {
    return await FirebaseMessagingService.areNotificationsEnabled();
  }

  /// Open device notification settings
  Future<void> openNotificationSettings() async {
    await FirebaseMessagingService.openNotificationSettings();
  }
}
