# 📊 Firebase Analytics Implementation Guide

## ✅ **What's Been Implemented**

### 🔧 **Core Analytics Service**
- **File**: `lib/services/firebase_analytics_service.dart`
- **Features**: 
  - Event logging with custom parameters
  - User properties management
  - Screen view tracking
  - Error logging
  - Session management

### 🚀 **App Integration**
- **Main App**: Analytics initialized in `main.dart` with navigation observer
- **Splash Screen**: App launch tracking and navigation analytics
- **Dependencies**: Firebase Analytics v11.3.3 added to `pubspec.yaml`

## 📱 **Analytics Events Being Tracked**

### 🎯 **App Lifecycle Events**
```dart
// App launch tracking
await FirebaseAnalyticsService.logEvent('app_launch', {
  'launch_time': DateTime.now().toIso8601String(),
});

// Navigation tracking (automatic with FirebaseAnalyticsObserver)
await FirebaseAnalyticsService.logScreenView('splash_screen');
```

### 🔔 **Notification Events**
```dart
// Notification provider initialization
await FirebaseAnalyticsService.logEvent('notification_provider_initialized', {
  'success': true,
});

// Notification interactions
await FirebaseAnalyticsService.logNotificationEvent('notification_opened', {
  'notification_type': 'wind_alerts',
  'fcm_token': tokenUsed,
});
```

### 🌤️ **Weather Data Events**
```dart
// Weather data tracking
await FirebaseAnalyticsService.logWeatherEvent('weather_data_viewed', {
  'temperature': temperature,
  'wind_speed': windSpeed,
  'air_quality_index': aqi,
  'location': location,
});
```

### ⚙️ **Settings & Configuration**
```dart
// Settings changes
await FirebaseAnalyticsService.logSettingsChange('notification_toggle', {
  'setting_name': 'wind_alerts',
  'enabled': true,
});

// Feature usage
await FirebaseAnalyticsService.logFeatureUsage('notification_test', {
  'feature': 'test_notification',
  'notification_type': 'wind_alerts',
});
```

## 🛠️ **How to Add Analytics to New Screens**

### 1. Import the Service
```dart
import '../services/firebase_analytics_service.dart';
```

### 2. Add Screen Tracking
```dart
@override
void initState() {
  super.initState();
  // Track screen view
  FirebaseAnalyticsService.logScreenView('your_screen_name');
}
```

### 3. Track User Actions
```dart
void onButtonPressed() {
  // Track button press
  FirebaseAnalyticsService.logEvent('button_pressed', {
    'button_name': 'refresh_weather',
    'screen': 'home_screen',
  });
  
  // Your button logic here
}
```

## 📊 **Available Analytics Methods**

### 🎯 **Basic Event Logging**
```dart
// Custom events
await FirebaseAnalyticsService.logEvent('custom_event', {
  'parameter1': 'value1',
  'parameter2': 123,
});

// Screen views
await FirebaseAnalyticsService.logScreenView('screen_name');
```

### 👤 **User Properties**
```dart
// Set user properties
await FirebaseAnalyticsService.setUserProperty('user_type', 'premium');
await FirebaseAnalyticsService.setUserId('user_123');
```

### 🔔 **Notification Analytics**
```dart
// Track notification events
await FirebaseAnalyticsService.logNotificationEvent('notification_received', {
  'notification_type': 'weather_alert',
  'topic': 'wind_alerts',
});
```

### 🌤️ **Weather Analytics**
```dart
// Track weather interactions
await FirebaseAnalyticsService.logWeatherEvent('forecast_viewed', {
  'forecast_type': 'hourly',
  'location': 'Toronto',
});
```

### 💨 **Ventilation Analytics**
```dart
// Track ventilation actions
await FirebaseAnalyticsService.logVentilationAction('window_opened', {
  'method': 'manual',
  'air_quality': 'good',
});
```

### ⚙️ **Settings Analytics**
```dart
// Track settings changes
await FirebaseAnalyticsService.logSettingsChange('preference_updated', {
  'setting_type': 'notifications',
  'old_value': false,
  'new_value': true,
});
```

### ❌ **Error Tracking**
```dart
// Log errors
await FirebaseAnalyticsService.logError('api_error', {
  'error_message': error.toString(),
  'api_endpoint': '/weather',
});
```

## 🔍 **Firebase Console Analytics**

### 📊 **Where to View Analytics**
1. **Firebase Console**: https://console.firebase.google.com/
2. **Project**: `easy-breezy-73c80`
3. **Analytics Section**: View events, users, and engagement

### 📈 **Key Metrics to Monitor**
- **App Launches**: Track user engagement
- **Screen Views**: Popular screens and user flow
- **Notification Interactions**: FCM effectiveness
- **Weather Data Views**: Feature usage
- **Error Rates**: App stability

### 🎯 **Custom Dimensions**
- **Notification Types**: Track which alerts users prefer
- **Weather Conditions**: Correlate usage with weather
- **Location Data**: Geographic usage patterns
- **Feature Usage**: Most popular app features

## 🚨 **Testing Analytics**

### 🧪 **Debug Mode**
Firebase Analytics has a debug mode for testing:
```bash
# Enable debug mode
adb shell setprop debug.firebase.analytics.app com.easybreezy.app

# View real-time events in Firebase Console > DebugView
```

### ✅ **Verification Checklist**
- [ ] Firebase Analytics initialized successfully
- [ ] Navigation observer tracking screen views
- [ ] Custom events logging properly
- [ ] User properties being set
- [ ] Error tracking functional
- [ ] Debug events visible in Firebase Console

## 🔮 **Next Steps**

### 🎯 **Additional Analytics to Implement**
1. **Weather API Performance**: Track response times
2. **Smart Home Integration**: Track device interactions
3. **User Onboarding**: Track completion rates
4. **App Performance**: Track load times and crashes
5. **A/B Testing**: Test different UI variations

### 📊 **Advanced Features**
1. **Conversion Tracking**: Track goal completions
2. **Audience Segmentation**: Create user segments
3. **Predictive Analytics**: Use Firebase ML
4. **Custom Dashboards**: Create business-specific views

---

## 🎉 **Status: Analytics Ready!**

✅ **Firebase Analytics is now fully integrated** into your EasyBreezy app!

The analytics service is tracking:
- App launches and navigation
- Notification interactions
- Weather data usage
- Settings changes
- Feature usage
- Error events

You can now monitor user behavior and app performance in the Firebase Console.
