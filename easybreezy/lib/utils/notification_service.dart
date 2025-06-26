import 'package:flutter/material.dart'; // this gives you Colors and Color
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/weather_data.dart';
import '../models/home_config.dart';
import '../utils/recommendation_engine.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon'); // Make sure this icon exists in android/app/src/main/res/drawable

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
        // Handle notification tap action
      },
    );

    // Request permission (for iOS)
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
  // iOS permission request only
  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
}


  Future<void> showWindowOpenNotification(
      WeatherData weatherData, String recommendationText) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'open_window_channel',
      'Window Opening Recommendations',
      channelDescription: 'Notifications for when to open your windows',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      color: Colors.blue,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await notificationsPlugin.show(
      0, // Notification ID
      'Good Time to Open Windows!',
      recommendationText,
      platformChannelSpecifics,
    );
  }

  Future<void> showWindowCloseNotification(
      WeatherData weatherData, String reasonText) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'close_window_channel',
      'Window Closing Recommendations',
      channelDescription: 'Notifications for when to close your windows',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      color: Colors.red,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await notificationsPlugin.show(
      1, // Different notification ID
      'Time to Close Your Windows',
      reasonText,
      platformChannelSpecifics,
    );
  }

  Future<void> scheduleRecommendationCheck(
      WeatherData weatherData, HomeConfig homeConfig) async {
    // Get recommendation
    final recommendationEngine = RecommendationEngine();
    final recommendation = recommendationEngine.getRecommendation(
      weatherData,
      homeConfig,
    );

    // Show appropriate notification based on recommendation
    if (homeConfig.notificationsEnabled) {
      if (recommendation.shouldOpenWindows) {
        await showWindowOpenNotification(
            weatherData, recommendation.reasonText);
      } else if (recommendation.airConditioningRecommended) {
        await showWindowCloseNotification(
            weatherData, "AC recommended: ${recommendation.reasonText}");
      }
    }
  }
}

