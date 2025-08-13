class EasyFlowScoreModel {
  final double windSpeed;
  final String windDirection;
  final double temperature;
  final double humidity;
  final String airQualityLevel;
  final String homeOrientation;
  final int forecastHoursClear;
  final bool isCelsius;

  EasyFlowScoreModel({
    required this.windSpeed,
    required this.windDirection,
    required this.temperature,
    required this.humidity,
    required this.airQualityLevel,
    required this.homeOrientation,
    this.forecastHoursClear = 6, // Default to 6 hours
    this.isCelsius = false, // Default to imperial units
  });

  // Calculate dynamic score based on optimal window opening conditions
  int calculateScore() {
    int score = 0;

    // Convert wind speed to consistent units for scoring (km/h)
    double windSpeedKmh;
    if (isCelsius) {
      // Metric units: wind speed is in m/s, convert to km/h
      windSpeedKmh = windSpeed * 3.6;
    } else {
      // Imperial units: wind speed is in mph, convert to km/h
      windSpeedKmh = windSpeed * 1.60934;
    }

    // Convert temperature to Celsius for consistent scoring
    double tempCelsius;
    if (isCelsius) {
      tempCelsius = temperature;
    } else {
      // Convert Fahrenheit to Celsius
      tempCelsius = (temperature - 32) * 5 / 9;
    }

    // Wind speed scoring (4-16 km/h is optimal)
    if (windSpeedKmh >= 4 && windSpeedKmh <= 16) {
      score += 30; // Maximum wind score
    } else if (windSpeedKmh >= 2 && windSpeedKmh < 4) {
      score += 20; // Light wind
    } else if (windSpeedKmh > 16 && windSpeedKmh <= 25) {
      score += 15; // Moderate wind
    } else if (windSpeedKmh > 25) {
      score += 5; // Too windy
    }
    // No points for no wind (0-2 km/h)

    // Wind direction alignment with home orientation
    if (_isWindDirectionOptimal(windDirection, homeOrientation)) {
      score += 25; // Optimal cross-ventilation
    } else if (_isWindDirectionGood(windDirection, homeOrientation)) {
      score += 15; // Good airflow
    } else {
      score += 5; // Some airflow
    }

    // Temperature scoring (16°C - 26°C is ideal)
    if (tempCelsius >= 16 && tempCelsius <= 26) {
      score += 25; // Perfect temperature
    } else if (tempCelsius >= 12 && tempCelsius < 16) {
      score += 15; // Cool but acceptable
    } else if (tempCelsius > 26 && tempCelsius <= 30) {
      score += 5; // Warm but not ideal - reduced from 15 to 5
    } else if (tempCelsius > 30 && tempCelsius <= 35) {
      score += 0; // Too warm - no points
    } else if (tempCelsius < 12) {
      score += 0; // Too cool - no points
    }
    // No points for extreme temperatures

    // Apply penalties for poor conditions that should override other factors
    bool hasTemperaturePenalty = tempCelsius > 26.1 || tempCelsius < 16; // Same thresholds as RecommendationCard
    bool hasWindPenalty = windSpeedKmh > 25;
    bool hasAirQualityPenalty = airQualityLevel.toLowerCase() != 'good';
    
    // Cap score if key conditions aren't met
    if (hasTemperaturePenalty || hasWindPenalty || hasAirQualityPenalty) {
      score = (score * 0.6).round(); // Reduce score by 40% for poor conditions
    }

    // Air quality scoring
    switch (airQualityLevel.toLowerCase()) {
      case 'good':
        score += 15;
        break;
      case 'moderate':
        score += 10;
        break;
      case 'unhealthy for sensitive groups':
        score += 5;
        break;
      default:
        score += 0; // Poor air quality
    }

    // Humidity scoring (30% - 60% is ideal)
    if (humidity >= 30 && humidity <= 60) {
      score += 5; // Optimal humidity
    } else if (humidity >= 20 && humidity < 30) {
      score += 3; // Low humidity
    } else if (humidity > 60 && humidity <= 80) {
      score += 3; // High humidity
    }
    // No points for extreme humidity

    print('  Final score: $score');
    return score.clamp(0, 100); // Ensure score stays between 0-100
  }

  // Check if wind direction is optimal for cross-ventilation
  bool _isWindDirectionOptimal(String windDir, String homeOrientation) {
    // Optimal when wind is perpendicular to home orientation for cross-ventilation
    Map<String, List<String>> optimalWinds = {
      'N': ['E', 'W', 'NE', 'NW'],
      'S': ['E', 'W', 'SE', 'SW'],
      'E': ['N', 'S', 'NE', 'SE'],
      'W': ['N', 'S', 'NW', 'SW'],
      'NE': ['NW', 'SE'],
      'NW': ['NE', 'SW'],
      'SE': ['NE', 'SW'],
      'SW': ['NW', 'SE'],
    };
    
    return optimalWinds[homeOrientation]?.contains(windDir) ?? false;
  }

  // Check if wind direction is good (some benefit)
  bool _isWindDirectionGood(String windDir, String homeOrientation) {
    // Any wind direction that's not directly opposing
    Map<String, List<String>> opposingWinds = {
      'N': ['S'],
      'S': ['N'],
      'E': ['W'],
      'W': ['E'],
      'NE': ['SW'],
      'NW': ['SE'],
      'SE': ['NW'],
      'SW': ['NE'],
    };
    
    return !(opposingWinds[homeOrientation]?.contains(windDir) ?? false);
  }

  // Get status message based on score
  String getStatusMessage() {
    int score = calculateScore();
    
    // Convert temperature to Celsius for consistent checking
    double tempCelsius;
    if (isCelsius) {
      tempCelsius = temperature;
    } else {
      tempCelsius = (temperature - 32) * 5 / 9;
    }
    
    // Convert wind speed to km/h
    double windSpeedKmh;
    if (isCelsius) {
      windSpeedKmh = windSpeed * 3.6;
    } else {
      windSpeedKmh = windSpeed * 1.60934;
    }
    
    // Check for specific poor conditions first (override score-based messaging)
    if (airQualityLevel.toLowerCase() != 'good') {
      return "Keep windows closed - poor air quality";
    } else if (tempCelsius > 26.1) { // Same as RecommendationCard hot threshold
      return "Keep windows closed - too hot outside";
    } else if (tempCelsius < 16) { // Same as RecommendationCard cold threshold
      return "Keep windows closed - too cold outside";
    } else if (windSpeedKmh > 25) {
      return "Keep windows closed - too windy";
    }
    
    // If no specific poor conditions, use score-based messaging
    String message;
    if (score >= 80) {
      message = "Perfect airflow right now!";
    } else if (score >= 65) {
      message = "Excellent conditions for fresh air!";
    } else if (score >= 50) {
      message = "Good time to open windows!";
    } else if (score >= 35) {
      message = "Moderate conditions - consider opening windows";
    } else {
      message = "Keep windows closed for now";
    }
    
    print('  Status message: $message (score: $score)');
    return message;
  }

  // Get smart, adaptive status message for main display
  String getSmartStatusMessage() {
    // Convert temperature to Celsius for consistent checking
    double tempCelsius;
    if (isCelsius) {
      tempCelsius = temperature;
    } else {
      tempCelsius = (temperature - 32) * 5 / 9;
    }
    
    // Convert wind speed to km/h
    double windSpeedKmh;
    if (isCelsius) {
      windSpeedKmh = windSpeed * 3.6;
    } else {
      windSpeedKmh = windSpeed * 1.60934;
    }
    
    // Priority-based smart messaging
    if (airQualityLevel.toLowerCase() != 'good') {
      return "Air quality concerns - keep closed";
    } else if (tempCelsius > 28) {
      return "Too hot - stay cool indoors";
    } else if (tempCelsius < 14) {
      return "Too cold - keep warmth inside";
    } else if (windSpeedKmh > 25) {
      return "Too windy - avoid drafts";
    } else if (tempCelsius >= 16 && tempCelsius <= 26 && windSpeedKmh >= 4 && windSpeedKmh <= 16) {
      return "Perfect conditions - open wide!";
    } else if (tempCelsius >= 14 && tempCelsius <= 28 && windSpeedKmh <= 25) {
      return "Good time for fresh air!";
    } else {
      return "Moderate conditions - your choice";
    }
  }

  // Default/placeholder values
  static EasyFlowScoreModel placeholder({bool isCelsius = false}) {
    return EasyFlowScoreModel(
      windSpeed: 8.0,
      windDirection: "NW",
      temperature: isCelsius ? 22.0 : 72.0, // 22°C ≈ 72°F
      humidity: 45.0,
      airQualityLevel: "Good",
      homeOrientation: "E",
      forecastHoursClear: 6,
      isCelsius: isCelsius,
    );
  }

  // Generate intelligent, personalized ventilation advice
  String generateVentilationHint() {
    // Convert temperature to Celsius for consistent messaging
    double tempCelsius;
    if (isCelsius) {
      tempCelsius = temperature;
    } else {
      // Convert Fahrenheit to Celsius
      tempCelsius = (temperature - 32) * 5 / 9;
    }

    // Convert wind speed to km/h for consistent messaging
    double windSpeedKmh;
    if (isCelsius) {
      // Metric units: wind speed is in m/s, convert to km/h
      windSpeedKmh = windSpeed * 3.6;
    } else {
      // Imperial units: wind speed is in mph, convert to km/h
      windSpeedKmh = windSpeed * 1.60934;
    }

    // Check air quality first (highest priority)
    if (airQualityLevel.toLowerCase() == 'poor' || 
        airQualityLevel.toLowerCase() == 'unhealthy' ||
        airQualityLevel.toLowerCase() == 'very unhealthy' ||
        airQualityLevel.toLowerCase() == 'hazardous') {
      return "Air quality is currently not ideal. We recommend keeping windows closed to maintain indoor air quality.";
    }
    
    if (airQualityLevel.toLowerCase() == 'moderate' || 
        airQualityLevel.toLowerCase() == 'unhealthy for sensitive groups') {
      return "Air quality is moderate. Consider keeping windows closed if you have respiratory sensitivities.";
    }

    // Check for extreme wind conditions (using km/h thresholds)
    if (windSpeedKmh > 40) { // ~25 mph
      String windDirectionName = _getWindDirectionName(windDirection);
      return "It's too windy to open windows. Strong gusts from the $windDirectionName may cause discomfort or drafts.";
    }

    // Check temperature conditions (using Celsius thresholds)
    if (tempCelsius < 14) {
      return "It's a bit chilly outside. You can open your windows briefly for fresh air, but keep ventilation limited.";
    }

    if (tempCelsius > 28 && humidity > 70) {
      return "It's hot and humid outside. Keep windows closed to retain cooler indoor conditions.";
    }

    if (tempCelsius > 29) { // Lowered from 30 to 29
      return "It's quite hot outside. Consider keeping windows closed during peak heat and opening them during cooler evening hours.";
    }

    // Handle warm but manageable temperatures (26-29°C)
    if (tempCelsius > 26 && tempCelsius <= 29) {
      if (humidity > 70) {
        return "It's warm and humid outside. Brief ventilation might help, but keep it minimal to maintain indoor comfort.";
      } else {
        return "It's getting warm outside. Consider opening windows briefly for fresh air, but you may want to close them during peak heat.";
      }
    }

    // Check for optimal conditions
    if (airQualityLevel.toLowerCase() == 'good' && 
        windSpeedKmh >= 8 && windSpeedKmh <= 24 && // ~5-15 mph converted to km/h
        tempCelsius >= 18 && tempCelsius <= 25) {
      
      List<String> optimalWindows = _getOptimalWindows();
      if (optimalWindows.isNotEmpty) {
        String windowsText = optimalWindows.length == 2 
            ? "${optimalWindows[0]} and ${optimalWindows[1]} facing windows"
            : "${optimalWindows[0]} facing windows";
        
        String hoursText = forecastHoursClear > 1 
            ? "for the next $forecastHoursClear hours"
            : "for the next hour";
            
        return "Perfect conditions for cross-ventilation $hoursText! Open your $windowsText.";
      }
    }

    // Check for good but not perfect conditions
    if (airQualityLevel.toLowerCase() == 'good' && 
        windSpeedKmh >= 5 && windSpeedKmh <= 32 && // ~3-20 mph converted to km/h
        tempCelsius >= 16 && tempCelsius <= 27) {
      
      List<String> recommendedWindows = _getOptimalWindows();
      if (recommendedWindows.isNotEmpty) {
        String windowsText = recommendedWindows.length == 2 
            ? "${recommendedWindows[0]} and ${recommendedWindows[1]} facing windows"
            : "${recommendedWindows[0]} facing windows";
            
        return "Good conditions for fresh air! Consider opening your $windowsText for natural ventilation.";
      }
      
      return "Good conditions for opening windows! Fresh air will help improve indoor air quality.";
    }

    // Light wind conditions
    if (windSpeedKmh < 5 && tempCelsius >= 18 && tempCelsius <= 28) { // Extended from 25 to 28
      if (tempCelsius > 26) {
        return "Light winds today, but it's getting warm. Consider opening windows briefly during cooler parts of the day.";
      } else {
        return "Light winds today. Opening multiple windows will help create gentle air circulation throughout your home.";
      }
    }

    // High humidity but good temperature
    if (humidity > 80 && tempCelsius >= 20 && tempCelsius <= 26) {
      return "It's quite humid outside. Brief ventilation can help, but avoid prolonged window opening.";
    }

    // Moderate conditions
    if (airQualityLevel.toLowerCase() == 'good' && tempCelsius >= 15 && tempCelsius <= 28) {
      return "Moderate conditions for ventilation. Consider opening windows based on your comfort preferences.";
    }

    // Default fallback
    return "Conditions are being analyzed... Please wait.";
  }

  // Get optimal windows to open based on wind direction and home orientation
  List<String> _getOptimalWindows() {
    // Cross-ventilation is best when wind is perpendicular to home orientation
    Map<String, Map<String, List<String>>> crossVentilationMap = {
      'N': {
        'optimal': ['E', 'W', 'NE', 'NW'], // Wind from these directions, open E/W windows
        'windows': ['East', 'West']
      },
      'S': {
        'optimal': ['E', 'W', 'SE', 'SW'],
        'windows': ['East', 'West']
      },
      'E': {
        'optimal': ['N', 'S', 'NE', 'SE'],
        'windows': ['North', 'South']
      },
      'W': {
        'optimal': ['N', 'S', 'NW', 'SW'],
        'windows': ['North', 'South']
      },
      'NE': {
        'optimal': ['NW', 'SE', 'W', 'S'],
        'windows': ['Northwest', 'Southeast']
      },
      'NW': {
        'optimal': ['NE', 'SW', 'E', 'S'],
        'windows': ['Northeast', 'Southwest']
      },
      'SE': {
        'optimal': ['NE', 'SW', 'N', 'W'],
        'windows': ['Northeast', 'Southwest']
      },
      'SW': {
        'optimal': ['NW', 'SE', 'N', 'E'],
        'windows': ['Northwest', 'Southeast']
      },
    };

    Map<String, List<String>>? orientationData = crossVentilationMap[homeOrientation];
    if (orientationData != null && 
        orientationData['optimal']!.contains(windDirection)) {
      return orientationData['windows']!;
    }

    // Fallback: suggest windows based on home orientation
    switch (homeOrientation) {
      case 'N':
      case 'S':
        return ['East', 'West'];
      case 'E':
      case 'W':
        return ['North', 'South'];
      default:
        return ['primary'];
    }
  }

  // Convert wind direction abbreviation to readable name
  String _getWindDirectionName(String direction) {
    Map<String, String> directionNames = {
      'N': 'North',
      'NE': 'Northeast', 
      'E': 'East',
      'SE': 'Southeast',
      'S': 'South',
      'SW': 'Southwest',
      'W': 'West',
      'NW': 'Northwest',
    };
    return directionNames[direction] ?? direction;
  }
}
