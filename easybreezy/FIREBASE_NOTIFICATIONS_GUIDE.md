# Firebase Notifications Implementation Guide

## 🎯 Overview
This implementation provides a complete Firebase Cloud Messaging (FCM) notification system for the EasyBreezy app, with smart weather-based alerts and user preference management.

## 🔧 System Components

### 1. FirebaseMessagingService (`lib/services/firebase_messaging_service.dart`)
**Core notification handling service**

#### Key Features:
- ✅ APNS token handling for iOS
- ✅ FCM token management and refresh
- ✅ Topic-based subscriptions
- ✅ Background and foreground message handling
- ✅ Local notification display

#### Usage:
```dart
// Initialize (called automatically in main.dart)
await FirebaseMessagingService.initialize();

// Send test notification
await FirebaseMessagingService.sendTestNotification(NotificationType.openWindowsAlert);

// Subscribe to topics
await FirebaseMessagingService.subscribeToTopic('wind_alerts');
```

### 2. NotificationProvider (`lib/providers/notification_provider.dart`)
**State management for notification preferences**

#### Features:
- 🎯 14 different notification types
- 💾 Persistent user preferences
- 🏷️ Smart topic subscription management
- 🔄 Real-time settings updates

#### Usage:
```dart
// Access in widget
final notificationProvider = context.read<NotificationProvider>();

// Toggle notification type
await notificationProvider.toggleOpenWindowsAlert(true);

// Send test notification
await notificationProvider.sendTestNotification(NotificationType.rainAlert);
```

### 3. NotificationsSettingsScreen (`lib/screens/notifications_settings_screen.dart`)
**User interface for managing notification preferences**

#### Features:
- 🎨 Modern, categorized UI
- 🧪 Individual test buttons
- 🔧 Developer FCM token display
- ⚙️ System settings integration

## 📱 Notification Types

### 🌬️ Ventilation Alerts
- **Open Windows Alert**: Perfect conditions for opening windows
- **Close Windows Alert**: Conditions require closing windows  
- **Wind Alignment Alert**: Optimal wind direction detected

### ⛈️ Weather Warnings
- **Rain Alert**: Rain approaching - close windows
- **Storm Warning**: Severe weather incoming
- **High Wind Advisory**: Strong winds detected

### 🔮 Forecast-Based Notifications
- **Ventilation Opportunity**: Perfect natural cooling windows
- **Poor Air Quality**: AQI alerts and recommendations
- **High Pollen Alert**: Allergy-related air quality
- **Smoke Advisory**: Wildfire smoke detection

### 📊 Daily Summary
- **Morning Summary**: Daily forecast and savings summary
- **Weekly Report**: Weekly efficiency and cost report

### ⚙️ System & Efficiency
- **Energy Tip**: Smart energy-saving recommendations
- **Cost Saving**: Money savings achievements
- **System Status**: EasyBreezy system health
- **Maintenance Reminder**: Home maintenance tasks

## 🏷️ Topic Subscriptions

The system automatically manages these FCM topics based on user preferences:

```dart
'wind_alerts'        // Window management notifications
'weather_warnings'   // Storm and rain alerts
'air_quality'        // AQI and smoke advisories  
'energy_tips'        // Cost savings and efficiency
'daily_reports'      // Summaries and reports
'system_alerts'      // System status and maintenance
'critical_alerts'    // Always subscribed when notifications enabled
```

## 🔧 iOS Configuration

### Info.plist Changes Made:
```xml
<!-- Firebase Messaging -->
<key>FirebaseMessagingAutoInitEnabled</key>
<true/>

<!-- Background App Refresh -->
<key>UIBackgroundModes</key>
<array>
    <string>background-fetch</string>
    <string>remote-notification</string>
</array>

<!-- Location Permission -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>EasyBreezy uses your location to provide accurate weather data and wind forecasts for your area.</string>
```

## 🚀 Getting Started

### 1. Navigate to Notifications Settings
- Open EasyBreezy app
- Go to Settings → **Notification Preferences**
- Configure your preferred notification types

### 2. Test Notifications
- In Notification Preferences, tap the ▶️ button next to any notification type
- Or go to Settings → **Test Notifications** for the development testing screen

### 3. Monitor FCM Token
- In Notification Preferences, expand **🔧 Developer Info**
- Copy FCM token for testing with Firebase Console

## 🎯 Testing Notifications

### Local Testing (Available Now):
1. **Settings → Notification Preferences**
2. Tap ▶️ next to any notification type
3. Should see local notification immediately

### Firebase Console Testing:
1. Copy FCM token from app
2. Go to Firebase Console → Cloud Messaging
3. Send test message to specific token

## 📊 Integration Points

### Weather Provider Integration:
```dart
// In weather_provider.dart, you can trigger notifications:
import '../utils/weather_notification_helper.dart';

// After fetching weather data:
await WeatherNotificationHelper.checkAndNotify(weatherData);
```

### Manual Notification Triggers:
```dart
// Trigger specific notifications based on app logic:
await WeatherNotificationHelper.sendEnergyTip(25.50); // $25.50 savings
await WeatherNotificationHelper.checkAirQuality(165, 'Unhealthy');
await WeatherNotificationHelper.sendMorningSummary(summaryData);
```

## 🔐 Backend Integration (Next Steps)

When you're ready to send notifications from a server:

1. **Token Management**: Sync FCM tokens to your backend
2. **Send API**: Use Firebase Admin SDK to send notifications
3. **Triggers**: Set up cron jobs or weather API webhooks
4. **Personalization**: Send location-specific notifications

### Example Backend Integration:
```dart
// In NotificationProvider._saveTokenToDatabase():
// Replace placeholder with actual HTTP request:
await http.post(
  Uri.parse('https://your-backend.com/api/fcm-token'),
  headers: {'Authorization': 'Bearer $userToken'},
  body: json.encode({
    'fcm_token': token,
    'user_id': userId,
    'preferences': getNotificationPreferences(),
  }),
);
```

## 🐛 Troubleshooting

### Common Issues:

1. **APNS Token Error** (iOS):
   - Fixed with enhanced token handling
   - App now waits for APNS token before FCM

2. **Notifications Not Showing**:
   - Check device notification permissions
   - Verify Firebase project configuration
   - Ensure FCM token is valid

3. **Topic Subscriptions**:
   - Check console logs for subscription confirmations
   - Verify notification preferences are enabled

### Debug Information:
- FCM token displayed in Notification Preferences
- Console logs show all Firebase messaging activity
- Test notifications provide immediate feedback

## 📈 Next Steps

1. **Backend Setup**: Implement server-side notification sending
2. **Weather Integration**: Connect notifications to real weather alerts
3. **Personalization**: Location-based notification timing
4. **Analytics**: Track notification engagement
5. **A/B Testing**: Optimize notification content and timing

The notification system is now fully implemented and ready for testing! 🎉
