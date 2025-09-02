import '../models/weather_data.dart';

/// Represents the health status of an HVAC system based on smart thermostat data
class SystemHealthModel {
  final double overallHealthScore; // 0-100
  final List<HealthAlert> alerts;
  final List<MaintenanceRecommendation> recommendations;
  final EfficiencyMetrics efficiency;
  final SystemDiagnostics diagnostics;
  final DateTime lastUpdated;

  const SystemHealthModel({
    required this.overallHealthScore,
    required this.alerts,
    required this.recommendations,
    required this.efficiency,
    required this.diagnostics,
    required this.lastUpdated,
  });

  /// Creates system health analysis from smart thermostat data
  factory SystemHealthModel.fromThermostatData({
    required ThermostatSystemData systemData,
    required WeatherData weatherData,
    required double homeSquareFootage,
  }) {
    final diagnostics = _analyzeDiagnostics(systemData, weatherData, homeSquareFootage);
    final efficiency = _calculateEfficiencyMetrics(systemData, weatherData);
    final alerts = _generateHealthAlerts(diagnostics, efficiency);
    final recommendations = _generateMaintenanceRecommendations(diagnostics, systemData);
    final healthScore = _calculateOverallHealth(diagnostics, efficiency, alerts);

    return SystemHealthModel(
      overallHealthScore: healthScore,
      alerts: alerts,
      recommendations: recommendations,
      efficiency: efficiency,
      diagnostics: diagnostics,
      lastUpdated: DateTime.now(),
    );
  }

  static SystemDiagnostics _analyzeDiagnostics(
    ThermostatSystemData systemData,
    WeatherData weatherData,
    double homeSquareFootage,
  ) {
    // Analyze system performance vs expected performance
    final expectedRuntime = _calculateExpectedRuntime(
      weatherData.temperature,
      systemData.targetTemperature,
      homeSquareFootage,
      weatherData.humidity,
    );

    final runtimeEfficiency = systemData.actualRuntime / expectedRuntime;
    final cycleHealth = _analyzeCyclePatterns(systemData.cycleData);
    final temperatureStability = _analyzeTemperatureStability(systemData.temperatureHistory);

    return SystemDiagnostics(
      runtimeEfficiency: runtimeEfficiency,
      cycleHealth: cycleHealth,
      temperatureStability: temperatureStability,
      filterCondition: systemData.filterCondition,
      systemAge: systemData.systemAge,
      lastMaintenanceDate: systemData.lastMaintenanceDate,
      errorCodes: systemData.recentErrorCodes,
    );
  }

  static EfficiencyMetrics _calculateEfficiencyMetrics(
    ThermostatSystemData systemData,
    WeatherData weatherData,
  ) {
    // Calculate system efficiency based on real performance vs ideal
    final energyEfficiency = _calculateEnergyEfficiency(systemData);
    final temperatureControl = _calculateTemperatureControlEfficiency(systemData);
    final humidityControl = _calculateHumidityControlEfficiency(systemData);

    return EfficiencyMetrics(
      energyEfficiency: energyEfficiency,
      temperatureControl: temperatureControl,
      humidityControl: humidityControl,
      seasonalPerformance: _calculateSeasonalPerformance(systemData, weatherData),
    );
  }

  static List<HealthAlert> _generateHealthAlerts(
    SystemDiagnostics diagnostics,
    EfficiencyMetrics efficiency,
  ) {
    final alerts = <HealthAlert>[];

    // Critical system issues
    if (diagnostics.runtimeEfficiency > 1.3) {
      alerts.add(HealthAlert(
        severity: AlertSeverity.critical,
        title: 'System Overworking',
        description: 'HVAC system running ${(diagnostics.runtimeEfficiency * 100 - 100).toStringAsFixed(0)}% longer than expected',
        recommendation: 'Check for air leaks, dirty filters, or refrigerant issues',
        estimatedCost: 150.0,
        urgency: 'Schedule service within 3 days',
      ));
    }

    // Filter maintenance
    if (diagnostics.filterCondition < 30) {
      alerts.add(HealthAlert(
        severity: AlertSeverity.warning,
        title: 'Filter Replacement Needed',
        description: 'Air filter is ${diagnostics.filterCondition}% effective',
        recommendation: 'Replace air filter to maintain system efficiency',
        estimatedCost: 25.0,
        urgency: 'Replace within 1 week',
      ));
    }

    // Efficiency degradation
    if (efficiency.energyEfficiency < 0.75) {
      alerts.add(HealthAlert(
        severity: AlertSeverity.warning,
        title: 'Efficiency Decline',
        description: 'System efficiency dropped to ${(efficiency.energyEfficiency * 100).toStringAsFixed(0)}%',
        recommendation: 'Professional maintenance recommended',
        estimatedCost: 200.0,
        urgency: 'Schedule within 2 weeks',
      ));
    }

    return alerts;
  }

  static List<MaintenanceRecommendation> _generateMaintenanceRecommendations(
    SystemDiagnostics diagnostics,
    ThermostatSystemData systemData,
  ) {
    final recommendations = <MaintenanceRecommendation>[];

    // Seasonal maintenance
    final monthsSinceLastMaintenance = DateTime.now()
        .difference(diagnostics.lastMaintenanceDate)
        .inDays / 30;

    if (monthsSinceLastMaintenance > 6) {
      recommendations.add(MaintenanceRecommendation(
        type: MaintenanceType.seasonal,
        title: 'Seasonal Tune-Up Due',
        description: 'Professional system inspection and cleaning',
        estimatedCost: 150.0,
        estimatedSavings: 25.0,
        frequency: 'Every 6 months',
        priority: Priority.high,
      ));
    }

    // Duct cleaning based on cycle patterns
    if (diagnostics.cycleHealth < 0.8) {
      recommendations.add(MaintenanceRecommendation(
        type: MaintenanceType.cleaning,
        title: 'Duct System Cleaning',
        description: 'Poor airflow detected - duct cleaning recommended',
        estimatedCost: 300.0,
        estimatedSavings: 40.0,
        frequency: 'Every 3-5 years',
        priority: Priority.medium,
      ));
    }

    return recommendations;
  }

  static double _calculateOverallHealth(
    SystemDiagnostics diagnostics,
    EfficiencyMetrics efficiency,
    List<HealthAlert> alerts,
  ) {
    double score = 100.0;

    // Deduct for runtime inefficiency
    if (diagnostics.runtimeEfficiency > 1.0) {
      score -= (diagnostics.runtimeEfficiency - 1.0) * 50;
    }

    // Deduct for poor efficiency
    score *= efficiency.energyEfficiency;

    // Deduct for critical alerts
    for (final alert in alerts) {
      switch (alert.severity) {
        case AlertSeverity.critical:
          score -= 20;
          break;
        case AlertSeverity.warning:
          score -= 10;
          break;
        case AlertSeverity.info:
          score -= 5;
          break;
      }
    }

    return score.clamp(0.0, 100.0);
  }

  static double _calculateExpectedRuntime(
    double outsideTemp,
    double targetTemp,
    double homeSquareFootage,
    double humidity,
  ) {
    // Industry-standard calculation for expected HVAC runtime
    final tempDifference = (outsideTemp - targetTemp).abs();
    final baseRuntime = tempDifference * 0.15; // 15 minutes per degree difference
    final sizeAdjustment = homeSquareFootage / 2000; // Adjust for home size
    final humidityAdjustment = humidity > 60 ? 1.2 : 1.0; // High humidity increases runtime
    
    return baseRuntime * sizeAdjustment * humidityAdjustment;
  }

  static double _analyzeCyclePatterns(List<CycleData> cycleData) {
    if (cycleData.isEmpty) return 1.0;

    // Analyze for short cycling (bad) vs optimal cycle lengths
    final avgCycleLength = cycleData
        .map((cycle) => cycle.duration.inMinutes)
        .reduce((a, b) => a + b) / cycleData.length;

    // Optimal cycle length is 15-20 minutes
    if (avgCycleLength < 10) return 0.6; // Short cycling
    if (avgCycleLength > 30) return 0.7; // Long cycles might indicate issues
    return 1.0; // Optimal
  }

  static double _analyzeTemperatureStability(List<TemperatureReading> history) {
    if (history.length < 2) return 1.0;

    // Calculate temperature variance - stable systems have low variance
    final temps = history.map((reading) => reading.temperature).toList();
    final average = temps.reduce((a, b) => a + b) / temps.length;
    final variance = temps
        .map((temp) => (temp - average) * (temp - average))
        .reduce((a, b) => a + b) / temps.length;

    // Lower variance = better stability
    return (1.0 / (1.0 + variance)).clamp(0.0, 1.0);
  }

  static double _calculateEnergyEfficiency(ThermostatSystemData systemData) {
    // Compare actual energy usage to theoretical optimal
    return systemData.theoreticalOptimalEnergy / systemData.actualEnergyUsage;
  }

  static double _calculateTemperatureControlEfficiency(ThermostatSystemData systemData) {
    // How well the system maintains target temperature
    final deviations = systemData.temperatureHistory
        .map((reading) => (reading.temperature - systemData.targetTemperature).abs())
        .toList();
    
    final avgDeviation = deviations.reduce((a, b) => a + b) / deviations.length;
    return (1.0 / (1.0 + avgDeviation)).clamp(0.0, 1.0);
  }

  static double _calculateHumidityControlEfficiency(ThermostatSystemData systemData) {
    // Humidity control efficiency (if available)
    if (systemData.humidityHistory.isEmpty) return 1.0;
    
    final targetHumidity = 45.0; // Optimal indoor humidity
    final deviations = systemData.humidityHistory
        .map((reading) => (reading.humidity - targetHumidity).abs())
        .toList();
    
    final avgDeviation = deviations.reduce((a, b) => a + b) / deviations.length;
    return (1.0 / (1.0 + avgDeviation * 0.1)).clamp(0.0, 1.0);
  }

  static double _calculateSeasonalPerformance(
    ThermostatSystemData systemData,
    WeatherData weatherData,
  ) {
    // Seasonal performance factor based on outside conditions
    final season = _getCurrentSeason();
    final performance = systemData.seasonalEfficiency[season] ?? 1.0;
    return performance;
  }

  static Season _getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return Season.spring;
    if (month >= 6 && month <= 8) return Season.summer;
    if (month >= 9 && month <= 11) return Season.fall;
    return Season.winter;
  }
}

/// Smart thermostat system data structure
class ThermostatSystemData {
  final double actualRuntime; // Hours per day
  final double targetTemperature;
  final List<CycleData> cycleData;
  final List<TemperatureReading> temperatureHistory;
  final List<HumidityReading> humidityHistory;
  final double filterCondition; // 0-100%
  final int systemAge; // Years
  final DateTime lastMaintenanceDate;
  final List<String> recentErrorCodes;
  final double actualEnergyUsage; // kWh
  final double theoreticalOptimalEnergy; // kWh
  final Map<Season, double> seasonalEfficiency;

  const ThermostatSystemData({
    required this.actualRuntime,
    required this.targetTemperature,
    required this.cycleData,
    required this.temperatureHistory,
    required this.humidityHistory,
    required this.filterCondition,
    required this.systemAge,
    required this.lastMaintenanceDate,
    required this.recentErrorCodes,
    required this.actualEnergyUsage,
    required this.theoreticalOptimalEnergy,
    required this.seasonalEfficiency,
  });
}

class CycleData {
  final Duration duration;
  final DateTime startTime;
  final String mode; // heating/cooling
  
  const CycleData({
    required this.duration,
    required this.startTime,
    required this.mode,
  });
}

class TemperatureReading {
  final double temperature;
  final DateTime timestamp;
  
  const TemperatureReading({
    required this.temperature,
    required this.timestamp,
  });
}

class HumidityReading {
  final double humidity;
  final DateTime timestamp;
  
  const HumidityReading({
    required this.humidity,
    required this.timestamp,
  });
}

enum Season { spring, summer, fall, winter }

class SystemDiagnostics {
  final double runtimeEfficiency;
  final double cycleHealth;
  final double temperatureStability;
  final double filterCondition;
  final int systemAge;
  final DateTime lastMaintenanceDate;
  final List<String> errorCodes;

  const SystemDiagnostics({
    required this.runtimeEfficiency,
    required this.cycleHealth,
    required this.temperatureStability,
    required this.filterCondition,
    required this.systemAge,
    required this.lastMaintenanceDate,
    required this.errorCodes,
  });
}

class EfficiencyMetrics {
  final double energyEfficiency;
  final double temperatureControl;
  final double humidityControl;
  final double seasonalPerformance;

  const EfficiencyMetrics({
    required this.energyEfficiency,
    required this.temperatureControl,
    required this.humidityControl,
    required this.seasonalPerformance,
  });
}

class HealthAlert {
  final AlertSeverity severity;
  final String title;
  final String description;
  final String recommendation;
  final double estimatedCost;
  final String urgency;

  const HealthAlert({
    required this.severity,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.estimatedCost,
    required this.urgency,
  });
}

enum AlertSeverity { critical, warning, info }

class MaintenanceRecommendation {
  final MaintenanceType type;
  final String title;
  final String description;
  final double estimatedCost;
  final double estimatedSavings;
  final String frequency;
  final Priority priority;

  const MaintenanceRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.estimatedCost,
    required this.estimatedSavings,
    required this.frequency,
    required this.priority,
  });
}

enum MaintenanceType { seasonal, cleaning, repair, replacement, optimization }
enum Priority { low, medium, high, critical }
