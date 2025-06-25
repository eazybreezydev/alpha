class WeatherData {
  final double temperature;
  final double feelsLike;
  final double windSpeed;
  final int windDegree;
  final String windDirection;
  final double humidity;
  final String weatherMain;
  final String weatherDescription;
  final String weatherIcon;
  final int timestamp;
  final DateTime dateTime;
  final int pressure;
  final double tempMin;
  final double tempMax;

  WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.windSpeed,
    required this.windDegree,
    required this.windDirection,
    required this.humidity,
    required this.weatherMain,
    required this.weatherDescription,
    required this.weatherIcon,
    required this.timestamp,
    required this.dateTime,
    required this.pressure,
    required this.tempMin,
    required this.tempMax,
  });

  // Create WeatherData from OpenWeatherMap API response
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'];
    final weather = json['weather'][0];
    final wind = json['wind'];
    
    // Convert wind degree to cardinal direction
    final windDirection = _getWindDirection(wind['deg']);
    
    return WeatherData(
      temperature: main['temp']?.toDouble() ?? 0.0,
      feelsLike: main['feels_like']?.toDouble() ?? 0.0,
      windSpeed: wind['speed']?.toDouble() ?? 0.0,
      windDegree: wind['deg']?.toInt() ?? 0,
      windDirection: windDirection,
      humidity: main['humidity']?.toDouble() ?? 0.0,
      weatherMain: weather['main'] ?? '',
      weatherDescription: weather['description'] ?? '',
      weatherIcon: weather['icon'] ?? '',
      timestamp: json['dt']?.toInt() ?? 0,
      dateTime: DateTime.fromMillisecondsSinceEpoch((json['dt'] ?? 0) * 1000),
      pressure: main['pressure']?.toInt() ?? 0,
      tempMin: main['temp_min']?.toDouble() ?? 0.0,
      tempMax: main['temp_max']?.toDouble() ?? 0.0,
    );
  }

  // Convert wind degrees to cardinal direction
  static String _getWindDirection(int degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((degrees + 22.5) % 360 / 45).floor();
    return directions[index];
  }

  // Convert to a format that can be saved in local storage
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'feelsLike': feelsLike,
      'windSpeed': windSpeed,
      'windDegree': windDegree,
      'windDirection': windDirection,
      'humidity': humidity,
      'weatherMain': weatherMain,
      'weatherDescription': weatherDescription,
      'weatherIcon': weatherIcon,
      'timestamp': timestamp,
      'pressure': pressure,
      'tempMin': tempMin,
      'tempMax': tempMax,
    };
  }
}

// Class to represent a weather forecast for multiple hours/days
class WeatherForecast {
  final List<WeatherData> hourlyForecast;
  final List<WeatherData> dailyForecast;

  WeatherForecast({
    required this.hourlyForecast,
    required this.dailyForecast,
  });
}