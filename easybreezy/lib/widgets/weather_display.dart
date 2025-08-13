import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/weather_data.dart';
import '../providers/home_provider.dart';
import '../providers/weather_provider.dart';

class WeatherDisplay extends StatelessWidget {
  final WeatherData weatherData;

  const WeatherDisplay({
    Key? key,
    required this.weatherData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCelsius = Provider.of<HomeProvider>(context).isCelsius;
    final tempUnit = isCelsius ? '°C' : '°F';
    // Get city/town from WeatherProvider
    final city = Provider.of<WeatherProvider>(context).city;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getBackgroundColors(weatherData.weatherMain),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (city != null && city.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        city,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Temperature and condition
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weatherData.temperature.toStringAsFixed(0)}$tempUnit',
                          style: const TextStyle(
                            fontSize: 48, 
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Feels like ${weatherData.feelsLike.toStringAsFixed(0)}$tempUnit',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                
                // Weather icon
                Column(
                  children: [
                    _getWeatherIcon(weatherData.weatherMain),
                    const SizedBox(height: 4),
                    Text(
                      weatherData.weatherDescription.toCapitalized(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Wind and humidity info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn(
                  Icons.air,
                  'Wind',
                  '${weatherData.windSpeed.toStringAsFixed(1)} mph',
                  weatherData.windDirection,
                ),
                _buildInfoColumn(
                  Icons.water_drop_outlined,
                  'Humidity',
                  '${weatherData.humidity.toStringAsFixed(0)}%',
                  '',
                ),
                _buildInfoColumn(
                  Icons.compress,
                  'Pressure',
                  '${weatherData.pressure} hPa',
                  '',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String label, String value, String subvalue) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        if (subvalue.isNotEmpty)
          Text(
            subvalue,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
      ],
    );
  }

  Widget _getWeatherIcon(String condition) {
    IconData iconData;
    double size = 54;
    
    condition = condition.toLowerCase();
    
    if (condition.contains('clear')) {
      iconData = Icons.wb_sunny_rounded;
    } else if (condition.contains('cloud')) {
      iconData = Icons.cloud_rounded;
    } else if (condition.contains('rain')) {
      iconData = Icons.grain_rounded;
    } else if (condition.contains('snow')) {
      iconData = Icons.ac_unit_rounded;
    } else if (condition.contains('thunder')) {
      iconData = Icons.flash_on_rounded;
    } else if (condition.contains('mist') || condition.contains('fog')) {
      iconData = Icons.cloud_queue_rounded;
    } else {
      iconData = Icons.help_outline_rounded;
    }
    
    return Icon(iconData, size: size, color: Colors.white);
  }

  List<Color> _getBackgroundColors(String condition) {
    condition = condition.toLowerCase();
    
    if (condition.contains('clear')) {
      return [
        Colors.blue,
        Colors.lightBlue,
      ];
    } else if (condition.contains('cloud')) {
      return [
        Colors.blueGrey,
        Colors.grey.shade500,
      ];
    } else if (condition.contains('rain')) {
      return [
        Colors.indigo,
        Colors.blueGrey,
      ];
    } else if (condition.contains('snow')) {
      return [
        Colors.lightBlue.shade300,
        Colors.blue.shade100,
      ];
    } else if (condition.contains('thunder')) {
      return [
        Colors.deepPurple,
        Colors.indigo,
      ];
    } else {
      return [
        Colors.blue,
        Colors.cyan,
      ];
    }
  }
}

extension StringExtension on String {
  String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
}