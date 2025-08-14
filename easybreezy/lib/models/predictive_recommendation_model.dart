import 'weather_data.dart';

class PredictiveRecommendation {
  final DateTime time;
  final String action; // "open", "close", "keep_open", "keep_closed"
  final String reason;
  final int flowScore;
  final double temperature;
  final String priority; // "high", "medium", "low"
  final Duration timeUntil;
  final double potentialSavings;

  PredictiveRecommendation({
    required this.time,
    required this.action,
    required this.reason,
    required this.flowScore,
    required this.temperature,
    required this.priority,
    required this.timeUntil,
    required this.potentialSavings,
  });

  String get actionIcon {
    switch (action) {
      case 'open':
        return '🪟✅';
      case 'close':
        return '🪟❌';
      case 'keep_open':
        return '🪟🔄';
      case 'keep_closed':
        return '🪟🔒';
      default:
        return '🪟';
    }
  }

  String get priorityColor {
    switch (priority) {
      case 'high':
        return 'red';
      case 'medium':
        return 'orange';
      case 'low':
        return 'green';
      default:
        return 'grey';
    }
  }
}

class PredictiveRecommendationModel {
  final List<PredictiveRecommendation> recommendations;
  final String nextActionSummary;
  final Duration timeToNextAction;
  final double totalPotentialSavings;
  final int optimalHoursToday;

  PredictiveRecommendationModel({
    required this.recommendations,
    required this.nextActionSummary,
    required this.timeToNextAction,
    required this.totalPotentialSavings,
    required this.optimalHoursToday,
  });

  /// Generate predictive recommendations from weather forecast data
  factory PredictiveRecommendationModel.fromForecast({
    required List<WeatherData> forecastData,
    required String homeOrientation,
    required bool isCelsius,
  }) {
    final List<PredictiveRecommendation> recommendations = [];
    final DateTime now = DateTime.now();
    double totalSavings = 0.0;
    int optimalHours = 0;

    // Analyze each forecast period (typically 3-hour intervals)
    for (int i = 0; i < forecastData.length && i < 16; i++) { // Next 48 hours
      final forecast = forecastData[i];
      final forecastTime = forecast.dateTime;
      
      // Skip past hours
      if (forecastTime.isBefore(now)) continue;

      // Extract weather data from WeatherData object
      final temp = forecast.temperature;
      final humidity = forecast.humidity;
      final windSpeed = forecast.windSpeed;
      final weatherMain = forecast.weatherMain;
      
      // Convert temperature to Celsius for calculations
      final tempCelsius = isCelsius ? temp : (temp - 32) * 5/9;
      
      // Calculate flow score for this period
      final flowScore = _calculateFlowScore(
        temperature: tempCelsius,
        humidity: humidity,
        windSpeed: windSpeed,
        weather: weatherMain,
        homeOrientation: homeOrientation,
      );

      // Determine recommendation
      final recommendation = _generateRecommendation(
        time: forecastTime,
        flowScore: flowScore,
        temperature: tempCelsius,
        weather: weatherMain,
        previousRecommendations: recommendations,
      );

      if (recommendation != null) {
        recommendations.add(recommendation);
        totalSavings += recommendation.potentialSavings;
        
        // Count optimal hours (flow score >= 50)
        if (flowScore >= 50) {
          optimalHours += 3; // Each forecast period is ~3 hours
        }
      }
    }

    // Generate next action summary
    final nextAction = recommendations.isNotEmpty 
      ? recommendations.first
      : null;
    
    final nextActionSummary = nextAction != null
      ? "${nextAction.actionIcon} ${nextAction.action.toUpperCase()} windows ${nextAction.reason}"
      : "No immediate actions needed";
    
    final timeToNext = nextAction?.timeUntil ?? Duration.zero;

    return PredictiveRecommendationModel(
      recommendations: recommendations.take(8).toList(), // Show next 8 recommendations
      nextActionSummary: nextActionSummary,
      timeToNextAction: timeToNext,
      totalPotentialSavings: totalSavings,
      optimalHoursToday: optimalHours,
    );
  }

  static int _calculateFlowScore({
    required double temperature,
    required double humidity,
    required double windSpeed,
    required String weather,
    required String homeOrientation,
  }) {
    int score = 0;

    // Temperature scoring (optimal 16-26°C)
    if (temperature >= 16 && temperature <= 26) {
      score += 40;
    } else if (temperature >= 12 && temperature <= 30) {
      score += 20;
    }

    // Humidity scoring (optimal 30-70%)
    if (humidity >= 30 && humidity <= 70) {
      score += 25;
    } else if (humidity >= 20 && humidity <= 80) {
      score += 15;
    }

    // Wind scoring (optimal 5-20 km/h, convert from m/s)
    final windKmh = windSpeed * 3.6;
    if (windKmh >= 5 && windKmh <= 20) {
      score += 25;
    } else if (windKmh >= 2 && windKmh <= 30) {
      score += 15;
    }

    // Weather condition penalty
    if (weather.toLowerCase().contains('rain') || 
        weather.toLowerCase().contains('storm')) {
      score -= 30;
    } else if (weather.toLowerCase().contains('snow')) {
      score -= 40;
    }

    // Air quality bonus (assume good for now)
    score += 10;

    return score.clamp(0, 100);
  }

  static PredictiveRecommendation? _generateRecommendation({
    required DateTime time,
    required int flowScore,
    required double temperature,
    required String weather,
    required List<PredictiveRecommendation> previousRecommendations,
  }) {
    final now = DateTime.now();
    final timeUntil = time.difference(now);
    
    // Skip if too far in the future (beyond 48 hours)
    if (timeUntil.inHours > 48) return null;

    String action;
    String reason;
    String priority;
    double savings = 0.0;

    // Determine current window state (simplified - assume closed by default)
    final bool currentlyOpen = previousRecommendations.isNotEmpty
      ? previousRecommendations.last.action.contains('open')
      : false;

    // Decision logic
    if (weather.toLowerCase().contains('rain') || 
        weather.toLowerCase().contains('storm')) {
      action = 'close';
      reason = 'due to incoming precipitation';
      priority = 'high';
    } else if (temperature < 10) {
      action = 'close';
      reason = 'too cold outside (${temperature.toStringAsFixed(1)}°C)';
      priority = 'medium';
    } else if (temperature > 30) {
      action = 'close';
      reason = 'too hot outside (${temperature.toStringAsFixed(1)}°C)';
      priority = 'medium';
    } else if (flowScore >= 70) {
      action = currentlyOpen ? 'keep_open' : 'open';
      reason = 'excellent conditions (score: $flowScore)';
      priority = 'low';
      savings = 2.50; // Estimate $2.50/3hr period
    } else if (flowScore >= 50) {
      action = currentlyOpen ? 'keep_open' : 'open';
      reason = 'good conditions (score: $flowScore)';
      priority = 'low';
      savings = 1.25; // Estimate $1.25/3hr period
    } else {
      action = currentlyOpen ? 'close' : 'keep_closed';
      reason = 'poor conditions (score: $flowScore)';
      priority = 'medium';
    }

    return PredictiveRecommendation(
      time: time,
      action: action,
      reason: reason,
      flowScore: flowScore,
      temperature: temperature,
      priority: priority,
      timeUntil: timeUntil,
      potentialSavings: savings,
    );
  }

  /// Get the most urgent recommendation
  PredictiveRecommendation? get urgentRecommendation {
    return recommendations
        .where((r) => r.priority == 'high')
        .isNotEmpty
      ? recommendations.firstWhere((r) => r.priority == 'high')
      : recommendations.isNotEmpty
        ? recommendations.first
        : null;
  }

  /// Get recommendations for the next 6 hours
  List<PredictiveRecommendation> get next6Hours {
    final sixHoursLater = DateTime.now().add(const Duration(hours: 6));
    return recommendations
        .where((r) => r.time.isBefore(sixHoursLater))
        .toList();
  }
}
