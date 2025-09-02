import '../models/weather_data.dart';

class CarbonFootprintModel {
  final double dailyCarbonKg; // kg CO2 per day
  final double monthlyCarbonKg; // kg CO2 current month
  final double yearlyProjectionKg; // kg CO2 projected for year
  final double energyUsageKwh; // Daily energy usage
  final double carbonIntensity; // kg CO2 per kWh (varies by region/grid)
  final String gridMix; // Primary energy source
  final List<EcoRecommendation> recommendations;
  final MonthlyReport monthlyReport;
  final CarbonComparison comparison;
  final String impactLevel; // "Low", "Medium", "High"
  final double treesEquivalent; // Trees needed to offset daily carbon
  final ThermostatIntegration? thermostatIntegration; // Smart thermostat connection
  
  CarbonFootprintModel({
    required this.dailyCarbonKg,
    required this.monthlyCarbonKg,
    required this.yearlyProjectionKg,
    required this.energyUsageKwh,
    required this.carbonIntensity,
    required this.gridMix,
    required this.recommendations,
    required this.monthlyReport,
    required this.comparison,
    required this.impactLevel,
    required this.treesEquivalent,
    this.thermostatIntegration,
  });

  /// Create carbon footprint data from current weather and usage patterns
  static CarbonFootprintModel fromWeatherData({
    required WeatherData weatherData,
    required bool isCelsius,
    required double homeSquareFootage,
    String? region, // For grid carbon intensity
    bool? hasThermostatConnected, // Smart thermostat connection status
    double? currentThermostatTemp, // Current thermostat setting
  }) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    
    // Calculate energy usage based on weather conditions
    final energyUsage = _calculateEnergyUsage(
      weatherData: weatherData,
      isCelsius: isCelsius,
      homeSize: homeSquareFootage,
      season: _getSeason(currentMonth),
    );
    
    // Get regional carbon intensity (kg CO2 per kWh)
    final carbonIntensity = _getRegionalCarbonIntensity(region);
    final gridMix = _getRegionalGridMix(region);
    
    // Calculate carbon emissions
    final dailyCarbon = energyUsage * carbonIntensity;
    final monthlyCarbon = dailyCarbon * now.day; // Current month progress
    final yearlyProjection = dailyCarbon * 365;
    
    // Generate recommendations with thermostat integration
    final recommendations = _generateEcoRecommendations(
      weatherData: weatherData,
      energyUsage: energyUsage,
      carbonFootprint: dailyCarbon,
      season: _getSeason(currentMonth),
      hasThermostat: hasThermostatConnected ?? false,
      currentThermostatTemp: currentThermostatTemp,
    );
    
    // Create monthly report
    final monthlyReport = _generateMonthlyReport(
      currentDay: now.day,
      daysInMonth: daysInMonth,
      dailyCarbon: dailyCarbon,
      monthlyCarbon: monthlyCarbon,
    );
    
    // Create comparison data
    final comparison = _generateComparison(dailyCarbon, homeSquareFootage);
    
    // Determine impact level
    final impactLevel = _determineImpactLevel(dailyCarbon);
    
    // Calculate trees equivalent
    final treesEquivalent = dailyCarbon / 22.0; // 1 tree absorbs ~22kg CO2/year
    
    // Create thermostat integration if connected
    final thermostatIntegration = hasThermostatConnected == true
        ? CarbonFootprintModelExtension._createThermostatIntegration(
            weatherData: weatherData,
            currentTemp: currentThermostatTemp ?? 72.0,
            carbonFootprint: dailyCarbon,
            isCelsius: isCelsius,
          )
        : null;
    
    return CarbonFootprintModel(
      dailyCarbonKg: dailyCarbon,
      monthlyCarbonKg: monthlyCarbon,
      yearlyProjectionKg: yearlyProjection,
      energyUsageKwh: energyUsage,
      carbonIntensity: carbonIntensity,
      gridMix: gridMix,
      recommendations: recommendations,
      monthlyReport: monthlyReport,
      comparison: comparison,
      impactLevel: impactLevel,
      treesEquivalent: treesEquivalent,
      thermostatIntegration: thermostatIntegration,
    );
  }

  /// Calculate energy usage based on weather conditions
  static double _calculateEnergyUsage({
    required WeatherData weatherData,
    required bool isCelsius,
    required double homeSize,
    required String season,
  }) {
    // Convert to Celsius if needed
    final tempC = isCelsius ? weatherData.temperature : (weatherData.temperature - 32) * 5/9;
    
    // Base energy usage per square foot
    double baseUsagePerSqFt = 0.03; // kWh per sq ft per day
    
    // Weather-based adjustments
    double weatherMultiplier = 1.0;
    
    // Heating/cooling load based on temperature
    if (tempC < 18) { // Cold - heating needed
      weatherMultiplier += (18 - tempC) * 0.04; // Heating multiplier
    } else if (tempC > 26) { // Hot - cooling needed
      weatherMultiplier += (tempC - 26) * 0.06; // Cooling multiplier
    }
    
    // Humidity adjustment
    if (weatherData.humidity > 70) {
      weatherMultiplier += 0.1; // AC works harder in high humidity
    }
    
    // Wind adjustment (less heating/cooling needed)
    if (weatherData.windSpeed > 15) {
      weatherMultiplier -= 0.05;
    }
    
    // Seasonal adjustments
    switch (season) {
      case 'winter':
        weatherMultiplier += 0.2; // More heating
        break;
      case 'summer':
        weatherMultiplier += 0.15; // More cooling
        break;
      case 'spring':
      case 'fall':
        weatherMultiplier -= 0.1; // Mild weather
        break;
    }
    
    return homeSize * baseUsagePerSqFt * weatherMultiplier;
  }

  /// Get carbon intensity by region (kg CO2 per kWh)
  static double _getRegionalCarbonIntensity(String? region) {
    switch (region?.toLowerCase()) {
      case 'california':
      case 'ca':
        return 0.28; // Clean grid with renewables
      case 'texas':
      case 'tx':
        return 0.45; // Natural gas heavy
      case 'west virginia':
      case 'wv':
        return 0.75; // Coal heavy
      case 'washington':
      case 'wa':
        return 0.12; // Hydro power
      case 'florida':
      case 'fl':
        return 0.52; // Natural gas
      case 'new york':
      case 'ny':
        return 0.31; // Mixed grid
      default:
        return 0.42; // US average
    }
  }

  /// Get regional grid mix description
  static String _getRegionalGridMix(String? region) {
    switch (region?.toLowerCase()) {
      case 'california':
      case 'ca':
        return 'Clean Grid (Solar & Wind)';
      case 'texas':
      case 'tx':
        return 'Natural Gas + Renewables';
      case 'west virginia':
      case 'wv':
        return 'Coal Powered Grid';
      case 'washington':
      case 'wa':
        return 'Hydroelectric Power';
      case 'florida':
      case 'fl':
        return 'Natural Gas Grid';
      case 'new york':
      case 'ny':
        return 'Mixed Energy Grid';
      default:
        return 'Regional Power Grid';
    }
  }

  /// Get current season
  static String _getSeason(int month) {
    switch (month) {
      case 12:
      case 1:
      case 2:
        return 'winter';
      case 3:
      case 4:
      case 5:
        return 'spring';
      case 6:
      case 7:
      case 8:
        return 'summer';
      case 9:
      case 10:
      case 11:
        return 'fall';
      default:
        return 'spring';
    }
  }

  /// Generate eco-friendly recommendations
  static List<EcoRecommendation> _generateEcoRecommendations({
    required WeatherData weatherData,
    required double energyUsage,
    required double carbonFootprint,
    required String season,
    bool hasThermostat = false,
    double? currentThermostatTemp,
  }) {
    List<EcoRecommendation> recommendations = [];
    
    final tempC = weatherData.temperature > 50 
        ? (weatherData.temperature - 32) * 5/9 
        : weatherData.temperature;
    
    // Smart Thermostat Temperature-based recommendations
    if (hasThermostat && currentThermostatTemp != null) {
      if (tempC > 26) { // Hot weather
        final currentTempF = currentThermostatTemp;
        if (currentTempF < 76) {
          recommendations.add(EcoRecommendation(
            title: 'Smart Thermostat: Eco Mode',
            description: 'Automatically adjust to 78°F to reduce carbon footprint by 18%',
            impact: 'High',
            carbonSavingsKg: carbonFootprint * 0.18,
            icon: '🌡️',
            category: 'Smart Thermostat',
            isAutomatable: true,
            thermostatAction: ThermostatAction(
              recommendedTemp: 78.0,
              mode: 'cool',
              autoApply: true,
              savingsPerDay: carbonFootprint * 0.18,
            ),
          ));
        }
      } else if (tempC < 18) { // Cold weather
        final currentTempF = currentThermostatTemp;
        if (currentTempF > 70) {
          recommendations.add(EcoRecommendation(
            title: 'Smart Thermostat: Heat Optimization',
            description: 'Lower to 68°F and use smart scheduling to save energy',
            impact: 'High',
            carbonSavingsKg: carbonFootprint * 0.15,
            icon: '🔥',
            category: 'Smart Thermostat',
            isAutomatable: true,
            thermostatAction: ThermostatAction(
              recommendedTemp: 68.0,
              mode: 'heat',
              autoApply: true,
              savingsPerDay: carbonFootprint * 0.15,
            ),
          ));
        }
      }
      
      // Smart scheduling recommendation
      recommendations.add(EcoRecommendation(
        title: 'Smart Thermostat: Eco Schedule',
        description: 'Enable automatic temperature scheduling based on occupancy',
        impact: 'Medium',
        carbonSavingsKg: carbonFootprint * 0.12,
        icon: '📅',
        category: 'Smart Thermostat',
        isAutomatable: true,
        thermostatAction: ThermostatAction(
          recommendedTemp: currentThermostatTemp,
          mode: 'auto',
          autoApply: false,
          savingsPerDay: carbonFootprint * 0.12,
          enableScheduling: true,
        ),
      ));
    } else {
      // Manual temperature recommendations for non-smart thermostat users
      if (tempC > 26) {
        recommendations.add(EcoRecommendation(
          title: 'Optimize Cooling',
          description: 'Raise thermostat to 78°F to reduce carbon footprint by 15%',
          impact: 'High',
          carbonSavingsKg: carbonFootprint * 0.15,
          icon: '❄️',
          category: 'Temperature',
          isAutomatable: false,
        ));
      } else if (tempC < 18) {
        recommendations.add(EcoRecommendation(
          title: 'Smart Heating',
          description: 'Lower thermostat to 68°F and use layers to save energy',
          impact: 'High',
          carbonSavingsKg: carbonFootprint * 0.12,
          icon: '🔥',
          category: 'Temperature',
          isAutomatable: false,
        ));
      }
    }
    
    // Wind-based recommendations
    if (weatherData.windSpeed > 10) {
      recommendations.add(EcoRecommendation(
        title: 'Natural Ventilation',
        description: 'Open windows to use natural airflow instead of AC',
        impact: 'Medium',
        carbonSavingsKg: carbonFootprint * 0.08,
        icon: '🌬️',
        category: 'Ventilation',
        isAutomatable: false,
      ));
    }
    
    // General energy-saving tips
    recommendations.add(EcoRecommendation(
      title: 'LED Light Switch',
      description: 'Replace remaining incandescent bulbs with LEDs',
      impact: 'Medium',
      carbonSavingsKg: 2.5,
      icon: '💡',
      category: 'Lighting',
      isAutomatable: false,
    ));
    
    // Seasonal recommendations
    if (season == 'summer') {
      recommendations.add(EcoRecommendation(
        title: 'Solar Opportunity',
        description: 'Peak solar generation time - run appliances now',
        impact: 'Low',
        carbonSavingsKg: 1.2,
        icon: '☀️',
        category: 'Timing',
        isAutomatable: false,
      ));
    }
    
    return recommendations;
  }

  /// Generate monthly sustainability report
  static MonthlyReport _generateMonthlyReport({
    required int currentDay,
    required int daysInMonth,
    required double dailyCarbon,
    required double monthlyCarbon,
  }) {
    final projectedMonthlyCarbon = dailyCarbon * daysInMonth;
    final lastMonthCarbon = projectedMonthlyCarbon * 1.08; // Assume 8% improvement
    final percentChange = ((monthlyCarbon - (lastMonthCarbon * currentDay / daysInMonth)) / 
                          (lastMonthCarbon * currentDay / daysInMonth)) * 100;
    
    return MonthlyReport(
      currentMonthKg: monthlyCarbon,
      projectedMonthKg: projectedMonthlyCarbon,
      lastMonthKg: lastMonthCarbon,
      percentChange: percentChange,
      daysTracked: currentDay,
      totalDays: daysInMonth,
      trend: percentChange < 0 ? 'improving' : 'increasing',
    );
  }

  /// Generate comparison data
  static CarbonComparison _generateComparison(double dailyCarbon, double homeSize) {
    // Average US household: 16 metric tons CO2/year = ~44 kg/day
    final nationalAverage = 44.0;
    final similarHomesAverage = nationalAverage * (homeSize / 2000); // Adjust for home size
    
    return CarbonComparison(
      nationalAverage: nationalAverage,
      similarHomes: similarHomesAverage,
      yourFootprint: dailyCarbon,
      percentBetter: ((similarHomesAverage - dailyCarbon) / similarHomesAverage) * 100,
      ranking: _calculateRanking(dailyCarbon, similarHomesAverage),
    );
  }

  /// Calculate environmental ranking
  static String _calculateRanking(double yourCarbon, double average) {
    final ratio = yourCarbon / average;
    if (ratio < 0.7) return 'Excellent';
    if (ratio < 0.85) return 'Very Good';
    if (ratio < 1.0) return 'Good';
    if (ratio < 1.2) return 'Average';
    return 'Needs Improvement';
  }

  /// Determine impact level
  static String _determineImpactLevel(double dailyCarbon) {
    if (dailyCarbon < 30) return 'Low';
    if (dailyCarbon < 50) return 'Medium';
    return 'High';
  }

  // Computed properties
  String get impactColor {
    switch (impactLevel) {
      case 'Low':
        return '#4CAF50'; // Green
      case 'Medium':
        return '#FF9800'; // Orange
      case 'High':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  String get impactIcon {
    switch (impactLevel) {
      case 'Low':
        return '🌱';
      case 'Medium':
        return '🌿';
      case 'High':
        return '🌡️';
      default:
        return '🌍';
    }
  }

  double get dailyCarbonPounds => dailyCarbonKg * 2.20462; // Convert to pounds
  double get monthlyCarbonPounds => monthlyCarbonKg * 2.20462;
}

class EcoRecommendation {
  final String title;
  final String description;
  final String impact; // "High", "Medium", "Low"
  final double carbonSavingsKg;
  final String icon;
  final String category;
  final bool isAutomatable; // Can be automatically applied via smart thermostat
  final ThermostatAction? thermostatAction; // Smart thermostat action details

  EcoRecommendation({
    required this.title,
    required this.description,
    required this.impact,
    required this.carbonSavingsKg,
    required this.icon,
    required this.category,
    this.isAutomatable = false,
    this.thermostatAction,
  });

  String get impactColor {
    switch (impact) {
      case 'High':
        return '#4CAF50'; // Green
      case 'Medium':
        return '#FF9800'; // Orange
      case 'Low':
        return '#2196F3'; // Blue
      default:
        return '#9E9E9E'; // Grey
    }
  }
}

class MonthlyReport {
  final double currentMonthKg;
  final double projectedMonthKg;
  final double lastMonthKg;
  final double percentChange;
  final int daysTracked;
  final int totalDays;
  final String trend; // "improving", "increasing", "stable"

  MonthlyReport({
    required this.currentMonthKg,
    required this.projectedMonthKg,
    required this.lastMonthKg,
    required this.percentChange,
    required this.daysTracked,
    required this.totalDays,
    required this.trend,
  });

  String get trendIcon {
    switch (trend) {
      case 'improving':
        return '📉';
      case 'increasing':
        return '📈';
      default:
        return '📊';
    }
  }

  String get trendColor {
    switch (trend) {
      case 'improving':
        return '#4CAF50'; // Green
      case 'increasing':
        return '#F44336'; // Red
      default:
        return '#FF9800'; // Orange
    }
  }
}

class CarbonComparison {
  final double nationalAverage;
  final double similarHomes;
  final double yourFootprint;
  final double percentBetter;
  final String ranking;

  CarbonComparison({
    required this.nationalAverage,
    required this.similarHomes,
    required this.yourFootprint,
    required this.percentBetter,
    required this.ranking,
  });

  String get rankingColor {
    switch (ranking) {
      case 'Excellent':
        return '#4CAF50'; // Green
      case 'Very Good':
        return '#8BC34A'; // Light Green
      case 'Good':
        return '#CDDC39'; // Lime
      case 'Average':
        return '#FF9800'; // Orange
      default:
        return '#F44336'; // Red
    }
  }

  String get rankingIcon {
    switch (ranking) {
      case 'Excellent':
        return '🏆';
      case 'Very Good':
        return '🥇';
      case 'Good':
        return '🥈';
      case 'Average':
        return '🥉';
      default:
        return '📊';
    }
  }
}

class ThermostatAction {
  final double recommendedTemp;
  final String mode; // 'heat', 'cool', 'auto'
  final bool autoApply; // Can be automatically applied
  final double savingsPerDay; // kg CO2 saved per day
  final bool enableScheduling; // Enable smart scheduling

  ThermostatAction({
    required this.recommendedTemp,
    required this.mode,
    required this.autoApply,
    required this.savingsPerDay,
    this.enableScheduling = false,
  });
}

class ThermostatIntegration {
  final bool isConnected;
  final String? brand; // 'Nest', 'Ecobee', 'Honeywell', etc.
  final double currentTemp;
  final double targetTemp;
  final String mode;
  final CarbonSavings savings;
  final List<EcoRecommendation> automatableRecommendations;
  final DateTime lastOptimization;

  ThermostatIntegration({
    required this.isConnected,
    this.brand,
    required this.currentTemp,
    required this.targetTemp,
    required this.mode,
    required this.savings,
    required this.automatableRecommendations,
    required this.lastOptimization,
  });

  String get statusIcon {
    if (!isConnected) return '❌';
    if (automatableRecommendations.isNotEmpty) return '🔄';
    return '✅';
  }

  String get statusMessage {
    if (!isConnected) return 'Thermostat Disconnected';
    if (automatableRecommendations.isNotEmpty) {
      return '${automatableRecommendations.length} eco optimizations available';
    }
    return 'Thermostat optimized for carbon efficiency';
  }
}

class CarbonSavings {
  final double dailySavingsKg;
  final double monthlySavingsKg;
  final double yearlyProjectionKg;
  final double costSavings; // Dollar savings
  final int treesEquivalent; // Trees saved equivalent

  CarbonSavings({
    required this.dailySavingsKg,
    required this.monthlySavingsKg,
    required this.yearlyProjectionKg,
    required this.costSavings,
    required this.treesEquivalent,
  });
}

// Add the missing factory method for thermostat integration
extension CarbonFootprintModelExtension on CarbonFootprintModel {
  static ThermostatIntegration _createThermostatIntegration({
    required WeatherData weatherData,
    required double currentTemp,
    required double carbonFootprint,
    required bool isCelsius,
  }) {
    final now = DateTime.now();
    
    // Get automatable recommendations
    final automatableRecs = <EcoRecommendation>[];
    
    final tempC = weatherData.temperature > 50 
        ? (weatherData.temperature - 32) * 5/9 
        : weatherData.temperature;
    
    // Add smart thermostat specific recommendations
    if (tempC > 26 && currentTemp < 76) {
      automatableRecs.add(EcoRecommendation(
        title: 'Auto-Optimize Cooling',
        description: 'Adjust to 78°F automatically for optimal carbon efficiency',
        impact: 'High',
        carbonSavingsKg: carbonFootprint * 0.18,
        icon: '🌡️',
        category: 'Smart Thermostat',
        isAutomatable: true,
        thermostatAction: ThermostatAction(
          recommendedTemp: 78.0,
          mode: 'cool',
          autoApply: true,
          savingsPerDay: carbonFootprint * 0.18,
        ),
      ));
    }
    
    // Calculate current savings from thermostat optimization
    final dailySavings = automatableRecs.fold(0.0, (sum, rec) => sum + rec.carbonSavingsKg);
    final savings = CarbonSavings(
      dailySavingsKg: dailySavings,
      monthlySavingsKg: dailySavings * 30,
      yearlyProjectionKg: dailySavings * 365,
      costSavings: dailySavings * 0.42 * 0.12, // kg CO2 * energy rate * cost per kWh
      treesEquivalent: (dailySavings * 365 / 22).round(), // Trees saved per year
    );
    
    return ThermostatIntegration(
      isConnected: true,
      brand: 'Smart Thermostat', // Could be dynamic
      currentTemp: currentTemp,
      targetTemp: currentTemp,
      mode: tempC > 26 ? 'cool' : tempC < 18 ? 'heat' : 'auto',
      savings: savings,
      automatableRecommendations: automatableRecs,
      lastOptimization: now.subtract(Duration(hours: 2)), // Demo: last optimized 2 hours ago
    );
  }
}
