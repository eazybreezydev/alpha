import '../services/firebase_messaging_service.dart';
import '../models/weather_data.dart';

/// Utility class for triggering smart notifications based on weather conditions
class WeatherNotificationHelper {
  
  /// Check weather conditions and trigger appropriate notifications
  static Future<void> checkAndNotify(WeatherData? weatherData) async {
    if (weatherData == null) return;
    
    final windSpeed = weatherData.windSpeed;
    final temperature = weatherData.temperature;
    final humidity = weatherData.humidity;
    
    // Check for perfect ventilation opportunities
    await _checkVentilationOpportunity(temperature, windSpeed, humidity);
    
    // Check for weather warnings
    await _checkWeatherWarnings(weatherData);
    
    // Check for wind-related alerts
    await _checkWindAlerts(windSpeed, weatherData.windDirection);
  }
  
  /// Check for perfect ventilation opportunities
  static Future<void> _checkVentilationOpportunity(double temp, double windSpeed, double humidity) async {
    // Perfect conditions: comfortable temp, gentle breeze, low humidity
    if (temp >= 65 && temp <= 75 && windSpeed >= 3 && windSpeed <= 15 && humidity < 60) {
      print('🌟 Perfect ventilation opportunity detected!');
      // You can send notification here when backend is ready
      // await _sendNotification(NotificationType.ventilationOpportunity, {...});
    }
  }
  
  /// Check for weather warnings
  static Future<void> _checkWeatherWarnings(WeatherData weather) async {
    // High wind warning
    if (weather.windSpeed > 25) {
      print('💨 High wind advisory triggered: ${weather.windSpeed} mph');
      // await _sendNotification(NotificationType.highWindAdvisory, {...});
    }
    
    // Temperature-based alerts
    if (weather.temperature > 85) {
      print('🔥 Hot temperature - recommend closing windows');
      // await _sendNotification(NotificationType.closeWindowsAlert, {...});
    }
  }
  
  /// Check for wind alignment opportunities
  static Future<void> _checkWindAlerts(double windSpeed, String windDirection) async {
    // Gentle breeze perfect for cross-ventilation
    if (windSpeed >= 5 && windSpeed <= 12) {
      print('🧭 Perfect wind conditions for cross-ventilation');
      // Check if wind direction aligns with home orientation
      // await _sendNotification(NotificationType.windAlignmentAlert, {...});
    }
    
    // Very light winds - good for opening windows
    if (windSpeed >= 2 && windSpeed <= 8) {
      print('🌬️ Gentle breeze - perfect for opening windows');
      // await _sendNotification(NotificationType.openWindowsAlert, {...});
    }
  }
  
  /// Send notification (placeholder for when backend is ready)
  static Future<void> _sendNotification(NotificationType type, Map<String, String> data) async {
    // This would typically send to your backend server which then sends FCM
    // For now, we can trigger local test notifications
    await FirebaseMessagingService.sendTestNotification(type);
  }
  
  /// Check air quality and send alerts
  static Future<void> checkAirQuality(int aqi, String category) async {
    if (aqi > 100) {
      print('😷 Poor air quality detected: AQI $aqi');
      // await _sendNotification(NotificationType.poorAirQuality, {...});
    }
  }
  
  /// Trigger daily morning summary
  static Future<void> sendMorningSummary(Map<String, dynamic> summaryData) async {
    print('☀️ Sending daily morning summary');
    await FirebaseMessagingService.sendTestNotification(NotificationType.dailyMorningSummary);
  }
  
  /// Energy saving tip based on current conditions
  static Future<void> sendEnergyTip(double potentialSavings) async {
    if (potentialSavings > 10) {
      print('💡 Energy saving opportunity: \$${potentialSavings.toStringAsFixed(2)}');
      await FirebaseMessagingService.sendTestNotification(NotificationType.energyTip);
    }
  }
}
