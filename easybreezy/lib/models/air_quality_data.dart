class AirQualityData {
  final int aqi;
  final String category;
  final String description;
  final DateTime timestamp;
  final AirQualityComponents components;

  AirQualityData({
    required this.aqi,
    required this.category,
    required this.description,
    required this.timestamp,
    required this.components,
  });

  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    final main = json['main'];
    final components = json['components'];
    final aqi = main['aqi'] ?? 1;
    
    return AirQualityData(
      aqi: aqi,
      category: _getAqiCategory(aqi),
      description: _getAqiDescription(aqi),
      timestamp: DateTime.fromMillisecondsSinceEpoch((json['dt'] ?? 0) * 1000),
      components: AirQualityComponents.fromJson(components ?? {}),
    );
  }

  static String _getAqiCategory(int aqi) {
    switch (aqi) {
      case 1:
        return 'Good';
      case 2:
        return 'Fair';
      case 3:
        return 'Moderate';
      case 4:
        return 'Poor';
      case 5:
        return 'Very Poor';
      default:
        return 'Unknown';
    }
  }

  static String _getAqiDescription(int aqi) {
    switch (aqi) {
      case 1:
        return 'Air quality is satisfactory, and air pollution poses little or no risk.';
      case 2:
        return 'Air quality is acceptable for most people. However, sensitive individuals may experience minor respiratory symptoms.';
      case 3:
        return 'Members of sensitive groups may experience health effects. The general public is less likely to be affected.';
      case 4:
        return 'Some members of the general public may experience health effects; members of sensitive groups may experience more serious health effects.';
      case 5:
        return 'Health alert: The risk of health effects is increased for everyone.';
      default:
        return 'Air quality information is not available.';
    }
  }

  // Helper method to get color based on AQI level
  static int getAqiColor(int aqi) {
    switch (aqi) {
      case 1:
        return 0xFF4CAF50; // Green
      case 2:
        return 0xFF8BC34A; // Light Green
      case 3:
        return 0xFFFF9800; // Orange
      case 4:
        return 0xFFF44336; // Red
      case 5:
        return 0xFF9C27B0; // Purple
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  // Helper method to determine if it's safe to open windows
  bool get isSafeForVentilation => aqi <= 2; // Good or Fair
}

class AirQualityComponents {
  final double co;    // Carbon monoxide (μg/m³)
  final double no;    // Nitrogen monoxide (μg/m³)
  final double no2;   // Nitrogen dioxide (μg/m³)
  final double o3;    // Ozone (μg/m³)
  final double so2;   // Sulphur dioxide (μg/m³)
  final double pm2_5; // Fine particles matter (μg/m³)
  final double pm10;  // Coarse particulate matter (μg/m³)
  final double nh3;   // Ammonia (μg/m³)

  AirQualityComponents({
    required this.co,
    required this.no,
    required this.no2,
    required this.o3,
    required this.so2,
    required this.pm2_5,
    required this.pm10,
    required this.nh3,
  });

  factory AirQualityComponents.fromJson(Map<String, dynamic> json) {
    return AirQualityComponents(
      co: (json['co'] ?? 0.0).toDouble(),
      no: (json['no'] ?? 0.0).toDouble(),
      no2: (json['no2'] ?? 0.0).toDouble(),
      o3: (json['o3'] ?? 0.0).toDouble(),
      so2: (json['so2'] ?? 0.0).toDouble(),
      pm2_5: (json['pm2_5'] ?? 0.0).toDouble(),
      pm10: (json['pm10'] ?? 0.0).toDouble(),
      nh3: (json['nh3'] ?? 0.0).toDouble(),
    );
  }

  // Get the most concerning pollutant
  String getPrimaryPollutant() {
    final Map<String, double> pollutants = {
      'PM2.5': pm2_5,
      'PM10': pm10,
      'O3': o3,
      'NO2': no2,
      'SO2': so2,
      'CO': co,
    };

    final highest = pollutants.entries.reduce((a, b) => a.value > b.value ? a : b);
    return highest.key;
  }
}
