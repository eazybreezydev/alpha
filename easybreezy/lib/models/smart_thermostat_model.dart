class SmartThermostatModel {
  final double indoorTemp;
  final double targetTemp;
  final bool isCooling;
  final bool windowsOpen;

  const SmartThermostatModel({
    required this.indoorTemp,
    required this.targetTemp,
    required this.isCooling,
    required this.windowsOpen,
  });

  /// Factory constructor to create a mock instance for testing
  factory SmartThermostatModel.mock() {
    return const SmartThermostatModel(
      indoorTemp: 22.0,
      targetTemp: 20.0,
      isCooling: true,
      windowsOpen: true,
    );
  }

  /// Calculate suggested target temperature for energy efficiency
  double get suggestedTargetTemp {
    if (windowsOpen && isCooling) {
      // If windows are open and A/C is cooling, suggest raising temp to save energy
      return (targetTemp + 2.0).clamp(18.0, 28.0);
    } else if (windowsOpen && !isCooling) {
      // If windows are open and heating, suggest lowering temp to save energy
      return (targetTemp - 2.0).clamp(18.0, 28.0);
    } else {
      // No windows open, maintain current target
      return targetTemp;
    }
  }

  /// Get energy efficiency tip based on current state
  String get energyTip {
    if (windowsOpen && isCooling) {
      return "Set your thermostat to ${suggestedTargetTemp.toInt()}°C while windows are open to reduce A/C load.";
    } else if (windowsOpen && !isCooling) {
      return "Lower your thermostat to ${suggestedTargetTemp.toInt()}°C while windows are open to reduce heating load.";
    } else if (!windowsOpen && isCooling && indoorTemp > targetTemp + 2) {
      return "Close windows and let your A/C efficiently cool to ${targetTemp.toInt()}°C.";
    } else if (!windowsOpen && !isCooling && indoorTemp < targetTemp - 2) {
      return "Close windows and let your heating system efficiently warm to ${targetTemp.toInt()}°C.";
    } else {
      return "Your HVAC settings are optimized for current conditions.";
    }
  }

  /// Check if there's potential energy savings
  bool get hasEnergySavingOpportunity {
    return windowsOpen && (isCooling || !isCooling) && (suggestedTargetTemp != targetTemp);
  }

  /// Estimate potential energy savings percentage
  int get potentialSavingsPercentage {
    if (!hasEnergySavingOpportunity) return 0;
    final tempDifference = (suggestedTargetTemp - targetTemp).abs();
    return (tempDifference * 8).toInt().clamp(0, 30); // Rough estimate: 8% per degree
  }
}
