class EnergyEstimationModel {
  final double potentialDailySavings;
  final double potentialMonthlySavings;
  final double potentialYearlySavings;
  final int hoursOfNaturalVentilation;
  final double acAvoidancePercentage;
  final String currentRecommendation;
  final bool isOptimalConditions;
  final double currentTemperature;
  final double energyCostPerKwh;

  EnergyEstimationModel({
    required this.potentialDailySavings,
    required this.potentialMonthlySavings,
    required this.potentialYearlySavings,
    required this.hoursOfNaturalVentilation,
    required this.acAvoidancePercentage,
    required this.currentRecommendation,
    required this.isOptimalConditions,
    required this.currentTemperature,
    required this.energyCostPerKwh,
  });

  /// Calculate energy estimation based on current weather conditions and flow score
  factory EnergyEstimationModel.fromWeatherData({
    required double temperature,
    required double humidity,
    required double windSpeed,
    required String airQuality,
    required int flowScore,
    required String recommendation,
    double energyCostPerKwh = 0.12, // Average US energy cost per kWh
  }) {
    // Determine if conditions are optimal for natural ventilation
    final bool isOptimal = flowScore >= 50 && 
                          temperature >= 16 && temperature <= 26.1 &&
                          windSpeed <= 25 &&
                          airQuality.toLowerCase() == 'good';

    // Calculate potential hours of natural ventilation per day
    int hoursOfVentilation = 0;
    if (isOptimal) {
      // Estimate based on flow score - higher score = more hours suitable
      if (flowScore >= 80) {
        hoursOfVentilation = 8; // Excellent conditions
      } else if (flowScore >= 65) {
        hoursOfVentilation = 6; // Good conditions
      } else if (flowScore >= 50) {
        hoursOfVentilation = 4; // Moderate conditions
      }
    }

    // Calculate AC avoidance percentage based on natural ventilation hours
    final double acAvoidance = (hoursOfVentilation / 12.0) * 100; // Assume 12 hours/day AC usage

    // Industry-standard energy consumption calculations
    // Average home AC uses 3-5 kWh per hour, we'll use 3.5 kWh
    const double avgAcKwhPerHour = 3.5;
    
    // Calculate potential savings
    final double dailyKwhSaved = hoursOfVentilation * avgAcKwhPerHour;
    final double dailySavings = dailyKwhSaved * energyCostPerKwh;
    final double monthlySavings = dailySavings * 30;
    final double yearlySavings = dailySavings * 365;

    return EnergyEstimationModel(
      potentialDailySavings: dailySavings,
      potentialMonthlySavings: monthlySavings,
      potentialYearlySavings: yearlySavings,
      hoursOfNaturalVentilation: hoursOfVentilation,
      acAvoidancePercentage: acAvoidance.clamp(0, 100),
      currentRecommendation: recommendation,
      isOptimalConditions: isOptimal,
      currentTemperature: temperature,
      energyCostPerKwh: energyCostPerKwh,
    );
  }

  /// Get a descriptive message about the current energy saving opportunity
  String get savingsMessage {
    if (potentialDailySavings <= 0) {
      return "Current conditions aren't ideal for energy savings through natural ventilation.";
    } else if (potentialDailySavings < 1.0) {
      return "Small energy savings possible today with natural ventilation.";
    } else if (potentialDailySavings < 3.0) {
      return "Moderate energy savings available today!";
    } else {
      return "Excellent energy savings opportunity today!";
    }
  }

  /// Get energy efficiency rating based on current conditions
  String get efficiencyRating {
    if (acAvoidancePercentage >= 60) return "Excellent";
    if (acAvoidancePercentage >= 40) return "Good";
    if (acAvoidancePercentage >= 20) return "Fair";
    return "Poor";
  }

  /// Get the color for the efficiency rating
  int get efficiencyColor {
    if (acAvoidancePercentage >= 60) return 0xFF4CAF50; // Green
    if (acAvoidancePercentage >= 40) return 0xFF8BC34A; // Light Green
    if (acAvoidancePercentage >= 20) return 0xFFFF9800; // Orange
    return 0xFFF44336; // Red
  }
}
