import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Notification types for your app - matching settings page categories
enum NotificationType {
  // Ventilation Alerts
  openWindowsAlert,
  closeWindowsAlert,
  windAlignmentAlert,
  
  // Weather Warnings
  rainAlert,
  stormWarning,
  highWindAdvisory,
  
  // Forecast-Based Notifications
  ventilationOpportunity,
  poorAirQuality,
  highPollenAlert,
  smokeAdvisory,
  
  // Daily Summary
  dailyMorningSummary,
  weeklyReport,
  
  // System & Efficiency
  energyTip,
  costSaving,
  systemStatus,
  maintenanceReminder,
}

class NotificationData {
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  NotificationData({
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.timestamp,
  });

  factory NotificationData.fromRemoteMessage(RemoteMessage message) {
    final typeString = message.data['type'] ?? 'openWindowsAlert';
    final type = NotificationType.values.firstWhere(
      (e) => e.toString().split('.').last == typeString,
      orElse: () => NotificationType.openWindowsAlert,
    );

    return NotificationData(
      type: type,
      title: message.notification?.title ?? message.data['title'] ?? 'EasyBreezy',
      body: message.notification?.body ?? message.data['body'] ?? 'New notification',
      data: message.data,
      timestamp: DateTime.now(),
    );
  }
}

class FirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static Function(NotificationData)? _onNotificationReceived;
  static Function(NotificationData)? _onNotificationTapped;

  /// Initialize Firebase Messaging
  static Future<void> initialize() async {
    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        print('Firebase apps is empty - Firebase not initialized');
        return;
      }
      
      print('Firebase Messaging: Initializing local notifications...');
      await _initializeLocalNotifications();
      
      print('Firebase Messaging: Requesting permission...');
      
      // Request permission for notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission for notifications');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('User granted provisional permission for notifications');
      } else {
        print('User declined or has not accepted permission for notifications');
      }

      // Get the token
      print('Firebase Messaging: Getting FCM token...');
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📱 Received foreground message: ${message.notification?.title}');
        final notificationData = NotificationData.fromRemoteMessage(message);
        _handleForegroundMessage(notificationData);
      });

      // Handle background messages when app is opened
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('🔄 App opened from notification: ${message.notification?.title}');
        final notificationData = NotificationData.fromRemoteMessage(message);
        _handleNotificationTap(notificationData);
      });

      // Handle initial message (when app is opened from terminated state)
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        print('🚀 App opened from terminated state via notification');
        final notificationData = NotificationData.fromRemoteMessage(initialMessage);
        _handleNotificationTap(notificationData);
      }

      // Subscribe to default topics
      await _subscribeToDefaultTopics();

    } catch (e) {
      print('Error initializing Firebase Messaging: $e');
      rethrow;
    }
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        print('Local notification tapped: ${details.payload}');
        // Handle local notification tap
      },
    );
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(NotificationData data) {
    print('🔔 Processing foreground notification: ${data.type}');
    
    // Show local notification
    _showLocalNotification(data);
    
    // Notify listeners
    _onNotificationReceived?.call(data);
  }

  /// Handle notification tap
  static void _handleNotificationTap(NotificationData data) {
    print('👆 Processing notification tap: ${data.type}');
    _onNotificationTapped?.call(data);
  }

  /// Show local notification
  static Future<void> _showLocalNotification(NotificationData data) async {
    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'easybreezy_channel',
      'EasyBreezy Notifications',
      channelDescription: 'Notifications for wind alerts, energy tips, and more',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notificationId,
      data.title,
      data.body,
      details,
      payload: data.type.toString(),
    );
  }

  /// Subscribe to default topics
  static Future<void> _subscribeToDefaultTopics() async {
    final topics = [
      'wind_alerts',
      'energy_tips',
      'weather_updates',
      'all_users',
    ];

    for (final topic in topics) {
      await subscribeToTopic(topic);
    }
  }

  /// Set notification listeners
  static void setNotificationListeners({
    Function(NotificationData)? onReceived,
    Function(NotificationData)? onTapped,
  }) {
    _onNotificationReceived = onReceived;
    _onNotificationTapped = onTapped;
  }

  /// Send a test notification (for development)
  static Future<void> sendTestNotification(NotificationType type) async {
    final testData = _getTestNotificationData(type);
    final notificationData = NotificationData(
      type: type,
      title: testData['title']!,
      body: testData['body']!,
      data: testData,
      timestamp: DateTime.now(),
    );
    
    print('🧪 Sending test notification: ${type.toString()}');
    await _showLocalNotification(notificationData);
    _onNotificationReceived?.call(notificationData);
  }

  /// Get test notification data
  static Map<String, String> _getTestNotificationData(NotificationType type) {
    switch (type) {
      // VENTILATION ALERTS
      case NotificationType.openWindowsAlert:
        return {
          'title': '🌬️ Perfect Time to Open Windows!',
          'body': 'Outdoor temp: 68°F, gentle breeze from SW. Open windows now to save 20% on cooling!',
          'type': 'openWindowsAlert',
          'temperature': '68',
          'windSpeed': '8',
          'direction': 'SW',
          'savings': '20',
        };
      case NotificationType.closeWindowsAlert:
        return {
          'title': '🚪 Time to Close Windows',
          'body': 'Temperature rising to 85°F with strong winds. Close windows to maintain efficiency.',
          'type': 'closeWindowsAlert',
          'temperature': '85',
          'windSpeed': '25',
          'reason': 'heat_wind',
        };
      case NotificationType.windAlignmentAlert:
        return {
          'title': '🧭 Optimal Wind Alignment Detected',
          'body': 'Wind is perfectly aligned with your home orientation. Open north and south windows for maximum cross-ventilation!',
          'type': 'windAlignmentAlert',
          'windDirection': '180',
          'homeOrientation': 'north_south',
          'efficiency': '95',
        };

      // WEATHER WARNINGS
      case NotificationType.rainAlert:
        return {
          'title': '🌧️ Rain Alert - Close Windows!',
          'body': 'Rain expected in 15 minutes. Close all windows to protect your home.',
          'type': 'rainAlert',
          'timeToRain': '15',
          'intensity': 'moderate',
          'duration': '45',
        };
      case NotificationType.stormWarning:
        return {
          'title': '⛈️ Storm Warning - Secure Windows',
          'body': 'Severe storm approaching with 45mph winds. Close and secure all windows immediately.',
          'type': 'stormWarning',
          'windSpeed': '45',
          'severity': 'severe',
          'timeToArrival': '30',
        };
      case NotificationType.highWindAdvisory:
        return {
          'title': '💨 High Wind Advisory',
          'body': 'Sustained winds 30+ mph expected. Consider closing windows to prevent drafts and debris.',
          'type': 'highWindAdvisory',
          'windSpeed': '32',
          'duration': '3',
          'gusts': '45',
        };

      // FORECAST-BASED NOTIFICATIONS
      case NotificationType.ventilationOpportunity:
        return {
          'title': '⭐ Premium Ventilation Window',
          'body': 'Next 4 hours perfect for natural cooling! Outdoor: 65°F, Indoor: 78°F. Potential savings: \$12',
          'type': 'ventilationOpportunity',
          'outdoorTemp': '65',
          'indoorTemp': '78',
          'duration': '4',
          'savings': '12',
        };
      case NotificationType.poorAirQuality:
        return {
          'title': '😷 Poor Air Quality Alert',
          'body': 'AQI: 165 (Unhealthy). Keep windows closed and use air filtration instead.',
          'type': 'poorAirQuality',
          'aqi': '165',
          'level': 'unhealthy',
          'pollutant': 'PM2.5',
        };
      case NotificationType.highPollenAlert:
        return {
          'title': '🌸 High Pollen Alert',
          'body': 'Tree pollen very high today (8.5/10). Keep windows closed if you have allergies.',
          'type': 'highPollenAlert',
          'pollenCount': '8.5',
          'type_detail': 'tree',
          'recommendation': 'close_windows',
        };
      case NotificationType.smokeAdvisory:
        return {
          'title': '� Smoke Advisory',
          'body': 'Wildfire smoke detected in area. Keep windows closed and use air purification.',
          'type': 'smokeAdvisory',
          'source': 'wildfire',
          'distance': '25',
          'aqi': '145',
        };

      // DAILY SUMMARY
      case NotificationType.dailyMorningSummary:
        return {
          'title': '☀️ Daily EasyBreezy Summary',
          'body': 'Good morning! Today\'s forecast: Great ventilation 2-6pm. Yesterday you saved \$8.50 with smart window management.',
          'type': 'dailyMorningSummary',
          'yesterdaySavings': '8.50',
          'optimalWindow': '2pm-6pm',
          'easyFlowScore': '87',
        };
      case NotificationType.weeklyReport:
        return {
          'title': '📊 Weekly EasyBreezy Report',
          'body': 'This week: \$34 saved, 67% efficiency score. You opened windows optimally 5/7 days. Trend: ⬆️',
          'type': 'weeklyReport',
          'weeklySavings': '34',
          'efficiencyScore': '67',
          'optimalDays': '5',
          'trend': 'up',
        };

      // SYSTEM & EFFICIENCY
      case NotificationType.energyTip:
        return {
          'title': '💡 Smart Energy Tip',
          'body': 'Pro tip: Opening windows 30 minutes before sunset can pre-cool your home for the night. Try it today!',
          'type': 'energyTip',
          'category': 'timing',
          'difficulty': 'easy',
          'potentialSavings': '15',
        };
      case NotificationType.costSaving:
        return {
          'title': '💰 You\'re Saving Money!',
          'body': 'This month: \$127 saved vs traditional AC usage. You\'re in the top 20% of EasyBreezy users!',
          'type': 'costSaving',
          'monthlySavings': '127',
          'percentile': '20',
          'comparison': 'traditional_ac',
        };
      case NotificationType.systemStatus:
        return {
          'title': '⚙️ System Health Check',
          'body': 'All systems optimal! EasyFlow Score: 94%. Last calibration: 2 days ago. Next check: Tomorrow.',
          'type': 'systemStatus',
          'easyFlowScore': '94',
          'lastCalibration': '2',
          'nextCheck': 'tomorrow',
        };
      case NotificationType.maintenanceReminder:
        return {
          'title': '🔧 Maintenance Reminder',
          'body': 'Time for your monthly window seal inspection. Clean seals improve efficiency by up to 12%.',
          'type': 'maintenanceReminder',
          'task': 'window_seals',
          'frequency': 'monthly',
          'efficiency_impact': '12',
        };
    }
  }

  /// Get the FCM token
  static Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic $topic: $e');
    }
  }
}
