import 'package:flutter/material.dart';
import '../models/weather_data.dart';
import '../models/home_config.dart';

class WindowRecommendation {
  final bool shouldOpenWindows;
  final bool airConditioningRecommended;
  final String reasonText;
  final RecommendationType type;
  final List<WindowDirection> recommendedWindows;

  WindowRecommendation({
    required this.shouldOpenWindows,
    required this.airConditioningRecommended,
    required this.reasonText,
    required this.type,
    required this.recommendedWindows,
  });
}

enum RecommendationType {
  ideal,
  good,
  fair,
  poor,
  notRecommended,
}

class RecommendationEngine {
  // Main recommendation function
  WindowRecommendation getRecommendation(
      WeatherData weatherData, HomeConfig homeConfig) {
    // Step 1: Check if temperature is within comfort range
    final bool tempInRange = _isTemperatureInComfortRange(
        weatherData.temperature, homeConfig);

    // Step 2: Check if there are any external factors that would make opening windows undesirable
    final bool externalFactorsOk = _checkExternalFactors(weatherData);

    // Step 3: Check if wind direction is optimal for the home's window configuration
    final List<WindowDirection> optimalWindows =
        _getOptimalWindowsForAirflow(weatherData, homeConfig);

    // Step 4: Generate the recommendation based on the above checks
    return _generateRecommendation(
      weatherData,
      homeConfig,
      tempInRange,
      externalFactorsOk,
      optimalWindows,
    );
  }

  // Check if temperature is within user's comfort range
  bool _isTemperatureInComfortRange(double temperature, HomeConfig homeConfig) {
    return temperature >= homeConfig.comfortTempMin &&
        temperature <= homeConfig.comfortTempMax;
  }

  // Check if external factors allow opening windows
  bool _checkExternalFactors(WeatherData weatherData) {
    // Conditions where opening windows is not recommended
    final weatherCondition = weatherData.weatherMain.toLowerCase();

    // Don't open windows during rain, storm, snow, etc.
    if (weatherCondition.contains('rain') ||
        weatherCondition.contains('storm') ||
        weatherCondition.contains('snow') ||
        weatherCondition.contains('thunderstorm')) {
      return false;
    }

    // Don't open if it's very windy (wind speed > 20 mph is generally uncomfortable)
    if (weatherData.windSpeed > 20) {
      return false;
    }

    // Don't open if humidity is very high (> 80%)
    if (weatherData.humidity > 80) {
      return false;
    }

    return true;
  }

  // Determine which windows would provide optimal airflow based on wind direction
  List<WindowDirection> _getOptimalWindowsForAirflow(
      WeatherData weatherData, HomeConfig homeConfig) {
    // Get wind direction as degrees (0-360)
    final int windDegree = weatherData.windDegree;
    
    // Convert wind direction to window direction
    final WindowDirection incomingWindDirection = _degreeToWindowDirection(windDegree);
    
    // Find opposite window direction for cross-ventilation
    final WindowDirection oppositeDirection = _getOppositeDirection(incomingWindDirection);
    
    // List to store recommended windows
    final List<WindowDirection> recommendedWindows = [];
    
    // Check if user has windows in the incoming wind direction
    if (homeConfig.hasWindowInDirection(incomingWindDirection)) {
      recommendedWindows.add(incomingWindDirection);
    }
    
    // Check if user has windows in the opposite direction for cross-ventilation
    if (homeConfig.hasWindowInDirection(oppositeDirection)) {
      recommendedWindows.add(oppositeDirection);
    }
    
    // If no optimal windows are found but other windows exist, recommend those
    if (recommendedWindows.isEmpty) {
      // Try perpendicular windows
      final List<WindowDirection> perpendicular = _getPerpendicularDirections(incomingWindDirection);
      for (var direction in perpendicular) {
        if (homeConfig.hasWindowInDirection(direction)) {
          recommendedWindows.add(direction);
        }
      }
    }
    
    return recommendedWindows;
  }
  
  // Convert wind degree to WindowDirection
  WindowDirection _degreeToWindowDirection(int degree) {
    if (degree >= 315 || degree < 45) {
      return WindowDirection.south; // Wind from North means windows facing South will catch it
    } else if (degree >= 45 && degree < 135) {
      return WindowDirection.west; // Wind from East means windows facing West will catch it
    } else if (degree >= 135 && degree < 225) {
      return WindowDirection.north; // Wind from South means windows facing North will catch it
    } else {
      return WindowDirection.east; // Wind from West means windows facing East will catch it
    }
  }
  
  // Get opposite window direction
  WindowDirection _getOppositeDirection(WindowDirection direction) {
    switch (direction) {
      case WindowDirection.north:
        return WindowDirection.south;
      case WindowDirection.east:
        return WindowDirection.west;
      case WindowDirection.south:
        return WindowDirection.north;
      case WindowDirection.west:
        return WindowDirection.east;
    }
  }
  
  // Get perpendicular window directions
  List<WindowDirection> _getPerpendicularDirections(WindowDirection direction) {
    switch (direction) {
      case WindowDirection.north:
      case WindowDirection.south:
        return [WindowDirection.east, WindowDirection.west];
      case WindowDirection.east:
      case WindowDirection.west:
        return [WindowDirection.north, WindowDirection.south];
    }
  }

  // Generate the final recommendation based on all factors
  WindowRecommendation _generateRecommendation(
      WeatherData weatherData,
      HomeConfig homeConfig,
      bool tempInRange,
      bool externalFactorsOk,
      List<WindowDirection> optimalWindows) {
    
    // Case 1: External factors make opening windows undesirable
    if (!externalFactorsOk) {
      return WindowRecommendation(
        shouldOpenWindows: false,
        airConditioningRecommended: true,
        reasonText: 'Current weather conditions are not suitable for open windows.',
        type: RecommendationType.notRecommended,
        recommendedWindows: [],
      );
    }
    
    // Case 2: Temperature outside comfort range
    if (!tempInRange) {
      final bool tooHot = weatherData.temperature > homeConfig.comfortTempMax;
      final String tempMessage = tooHot 
        ? 'It\'s too hot outside for open windows.'
        : 'It\'s too cold outside for open windows.';
        
      return WindowRecommendation(
        shouldOpenWindows: false,
        airConditioningRecommended: tooHot,
        reasonText: tempMessage,
        type: RecommendationType.notRecommended,
        recommendedWindows: [],
      );
    }
    
    // Case 3: No optimal windows available
    if (optimalWindows.isEmpty) {
      return WindowRecommendation(
        shouldOpenWindows: false,
        airConditioningRecommended: false,
        reasonText: 'Current wind direction is not optimal for your window configuration.',
        type: RecommendationType.poor,
        recommendedWindows: [],
      );
    }
    
    // Case 4: Ideal conditions - temperature good, external factors good, optimal windows available
    if (tempInRange && externalFactorsOk && optimalWindows.length >= 2) {
      return WindowRecommendation(
        shouldOpenWindows: true,
        airConditioningRecommended: false,
        reasonText: 'Perfect conditions for cross-ventilation! Open windows on the ${_formatWindowDirections(optimalWindows)} sides.',
        type: RecommendationType.ideal,
        recommendedWindows: optimalWindows,
      );
    }
    
    // Case 5: Good conditions - temperature good, external factors good, some airflow possible
    return WindowRecommendation(
      shouldOpenWindows: true,
      airConditioningRecommended: false,
      reasonText: 'Good conditions for fresh air. Open windows on the ${_formatWindowDirections(optimalWindows)} side.',
      type: RecommendationType.good,
      recommendedWindows: optimalWindows,
    );
  }
  
  // Helper method to format window directions for display
  String _formatWindowDirections(List<WindowDirection> directions) {
    if (directions.isEmpty) return '';
    if (directions.length == 1) return directions.first.name;
    
    final directionNames = directions.map((dir) => dir.name).toList();
    return '${directionNames.sublist(0, directionNames.length - 1).join(', ')} and ${directionNames.last}';
  }
}