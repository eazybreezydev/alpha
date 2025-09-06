import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/weather_provider.dart';
import '../providers/home_provider.dart';
import '../providers/location_provider.dart';
import '../widgets/smart_tips_card.dart'; // Import SmartTipsCard
import '../widgets/local_ads_widget.dart'; // Import LocalAdsWidget
import '../widgets/easy_flow_score_card.dart'; // Import EasyFlowScoreCard
import '../widgets/wind_forecast_chart.dart'; // Import WindForecastChart
import '../widgets/wind_level_card.dart'; // Import WindLevelCard
import '../widgets/wind_flow_animation.dart'; // Import new wind flow system
import '../widgets/energy_estimation_widget.dart'; // Import EnergyEstimationWidget
import '../widgets/simple_location_display.dart'; // Import SimpleLocationDisplay
import '../models/easy_flow_score_model.dart'; // Import EasyFlowScoreModel
import '../models/energy_estimation_model.dart'; // Import EnergyEstimationModel
import '../models/air_quality_data.dart'; // Import AirQualityData

class HomeDashboard extends StatelessWidget {
  const HomeDashboard({Key? key}) : super(key: key);

  /// Determines if it's currently day time (6 AM to 6 PM)
  bool _isDayTime() {
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= 6 && hour < 18; // Day from 6 AM to 6 PM
  }

  /// Gets the appropriate background image path based on time
  String _getBackgroundImage() {
    return _isDayTime() 
        ? 'assets/images/backgrounds/dayv2.png'
        : 'assets/images/backgrounds/night.png';
  }

  /// Gets the appropriate text color based on time to contrast with background
  Color _getTextColor() {
    return _isDayTime() ? Colors.black87 : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<WeatherProvider, HomeProvider>(
      builder: (context, weatherProvider, homeProvider, _) {
        final weatherData = weatherProvider.currentWeather;
        final isCelsius = homeProvider.isCelsius;
        final tempUnit = isCelsius ? '°C' : '°F';
        final windSpeed = weatherData?.windSpeed ?? 0;
        final windDirection = weatherData?.windDirection ?? '--';
        final temperature = weatherData?.temperature ?? 0;
        
        // Get real air quality data from weather provider
        final airQuality = weatherProvider.airQuality;
        final aqiLevel = airQuality?.category ?? 'Unknown';
        final aqiColor = airQuality != null 
            ? Color(AirQualityData.getAqiColor(airQuality.aqi))
            : Colors.grey;
        
        // TODO: Replace with real pollen data
        final pollenLevel = 'Low';
        final pollenColor = Colors.green;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_getBackgroundImage()),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Simple Location Display with dropdown functionality
                                SimpleLocationDisplay(textColor: _getTextColor()),
                                const SizedBox(height: 8),
                                _LiveTimestamp(textColor: _getTextColor()),
                              ],
                            ),
                            // Refresh button
                            IconButton(
                              icon: Icon(Icons.refresh, color: _getTextColor()),
                              onPressed: () => weatherProvider.refreshWeatherData(context),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8), // Reduced spacing from 24 to 8
                      // Main content (no Center widget)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                            const SizedBox(height: 24), // Spacing before house image
                            // 3D-style house icon with wind flowing behind it
                            SizedBox(
                              width: 320,
                              height: 240,
                              child: Stack(
                                children: [
                                  // Wind flow overlay specifically behind the house
                                  Positioned.fill(
                                    child: Builder(
                                      builder: (context) {
                                        try {
                                          // Convert wind speed to km/h for consistent animation logic
                                          double windSpeedKmh = homeProvider.isCelsius 
                                            ? windSpeed * 3.6  // m/s to km/h
                                            : windSpeed * 1.60934; // mph to km/h
                                          
                                          // Debug output to verify correct wind speed conversion
                                          print('Wind Animation Debug: Raw=${windSpeed.toStringAsFixed(1)}, Converted=${windSpeedKmh.toStringAsFixed(1)} km/h, Units=${homeProvider.isCelsius ? "Celsius" : "Imperial"}');
                                          
                                          return WindFlowOverlay(
                                            windDirection: windDirection,
                                            windSpeed: windSpeedKmh,
                                            subtleMode: windSpeedKmh < 15, // Subtle mode for light winds
                                          );
                                        } catch (e) {
                                          // Fallback: return empty container if wind animation fails
                                          print('Wind animation error: $e');
                                          return Container();
                                        }
                                      },
                                    ),
                                  ),
                                  // House image with transparency allowing wind to show through
                                  Center(
                                    child: Image.asset(
                                      _shouldShowOpenWindows(
                                        aqiLevel, 
                                        temperature, 
                                        windSpeed, 
                                        homeProvider.isCelsius
                                      )
                                        ? 'assets/images/windows_openedv2.png'
                                        : 'assets/images/windows_closed.png',
                                      width: 320, // Increased from 240
                                      height: 240, // Increased from 180
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // EasyFlow Score Card
                            EasyFlowScoreCard(
                              isCelsius: homeProvider.isCelsius,
                              scoreModel: EasyFlowScoreModel(
                                windSpeed: weatherProvider.currentWeather?.windSpeed ?? 0,
                                windDirection: weatherProvider.currentWeather?.windDirection ?? 'N',
                                temperature: weatherProvider.currentWeather?.temperature ?? 0,
                                humidity: weatherProvider.currentWeather?.humidity ?? 45.0,
                                airQualityLevel: aqiLevel,
                                homeOrientation: homeProvider.homeConfig.orientation.name,
                                isCelsius: homeProvider.isCelsius,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Wind Level Card
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: WindLevelCard(
                                windSpeed: weatherProvider.currentWeather?.windSpeed ?? 0,
                                isCelsius: homeProvider.isCelsius,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Wind Forecast Chart
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: WindForecastChart(
                                windData: weatherProvider.windForecast,
                                peakStartTime: weatherProvider.getPeakWindStartTime(),
                                peakEndTime: weatherProvider.getPeakWindEndTime(),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Add LocalAdsWidget above tips
                            const LocalAdsWidget(),
                            const SizedBox(height: 24),
                            // Energy Estimation Widget
                            if (weatherData != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: EnergyEstimationWidget(
                                  estimationData: EnergyEstimationModel.fromWeatherData(
                                    temperature: isCelsius 
                                      ? weatherData.temperature 
                                      : (weatherData.temperature - 32) * 5/9, // Convert F to C for energy calculations
                                    humidity: weatherData.humidity,
                                    windSpeed: weatherData.windSpeed,
                                    airQuality: 'Good', // Default air quality - can be enhanced later with real AQI API
                                    flowScore: () {
                                      // Create EasyFlowScoreModel instance to calculate score
                                      final scoreModel = EasyFlowScoreModel(
                                        windSpeed: weatherData.windSpeed,
                                        windDirection: weatherData.windDirection,
                                        temperature: weatherData.temperature,
                                        humidity: weatherData.humidity,
                                        airQualityLevel: 'Good', // Default air quality
                                        homeOrientation: homeProvider.homeConfig?.orientation.toString().split('.').last ?? 'North', // Default orientation
                                        isCelsius: false, // WeatherData comes in user's preferred units
                                      );
                                      return scoreModel.calculateScore();
                                    }(),
                                    recommendation: homeProvider.homeConfig != null 
                                      ? 'Smart recommendation based on your home setup'
                                      : 'Set up your home configuration for personalized recommendations',
                                  ),
                                  onLearnMoreTapped: () {
                                    // This will be handled by the widget's info button
                                  },
                                ),
                              ),
                            if (weatherData != null) const SizedBox(height: 24),
                            // Smart Tips Card (no external padding to fix overflow)
                            SmartTipsCard(),
                            const SizedBox(height: 24),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
      },
    );
  }
}

// Weather stats row below house
class WeatherStatsRow extends StatelessWidget {
  final double temperature;
  final String tempUnit;
  final double windSpeed;
  final String windDirection;
  final String aqiLevel;
  final Color aqiColor;
  final String pollenLevel;
  final Color pollenColor;
  const WeatherStatsRow({
    Key? key,
    required this.temperature,
    required this.tempUnit,
    required this.windSpeed,
    required this.windDirection,
    required this.aqiLevel,
    required this.aqiColor,
    required this.pollenLevel,
    required this.pollenColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StatCard(
            label: 'Temp',
            value: '${temperature.toStringAsFixed(1)}$tempUnit',
            icon: Icons.thermostat,
            color: primary,
            bgColor: secondary.withOpacity(0.18),
            width: 90, // Increased from 60
            height: 100, // Increased from 70
            iconSize: 32, // Increased from 22
            valueFontSize: 18, // Increased from 13
            labelFontSize: 13, // Increased from 10
          ),
          const SizedBox(width: 16),
          StatCard(
            label: 'Wind',
            value: '${windSpeed.toStringAsFixed(1)} km/h $windDirection',
            icon: Icons.air,
            color: primary,
            bgColor: secondary.withOpacity(0.18),
            width: 90,
            height: 100,
            iconSize: 32,
            valueFontSize: 18,
            labelFontSize: 13,
          ),
          const SizedBox(width: 16),
          StatCard(
            label: 'AQI',
            value: aqiLevel,
            icon: Icons.cloud,
            color: primary,
            bgColor: secondary.withOpacity(0.18),
            width: 90,
            height: 100,
            iconSize: 32,
            valueFontSize: 18,
            labelFontSize: 13,
          ),
          const SizedBox(width: 16),
          StatCard(
            label: 'Pollen',
            value: pollenLevel,
            icon: Icons.grass,
            color: primary,
            bgColor: secondary.withOpacity(0.18),
            width: 90,
            height: 100,
            iconSize: 32,
            valueFontSize: 18,
            labelFontSize: 13,
          ),
        ],
      ),
    );
  }
}

// Quick stat card
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final double width;
  final double height;
  final double iconSize;
  final double valueFontSize;
  final double labelFontSize;
  const StatCard({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.width = 60,
    this.height = 70,
    this.iconSize = 22,
    this.valueFontSize = 13,
    this.labelFontSize = 10,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: iconSize),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                value,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: valueFontSize),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: color.withOpacity(0.7), fontSize: labelFontSize),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Compass direction indicator
class CompassIndicator extends StatelessWidget {
  final String direction;
  const CompassIndicator({Key? key, required this.direction}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.explore, color: Colors.white, size: 28),
        const SizedBox(width: 8),
        Text(direction, style: const TextStyle(color: Colors.white, fontSize: 18)),
      ],
    );
  }
}

// Simple logic for window alert message
String _getWindowAlertMessage({
  required double temperature,
  required double windSpeed,
  required String aqiLevel,
  required bool isCelsius,
}) {
  // Use correct thresholds for Celsius and Fahrenheit
  final minTemp = isCelsius ? 16 : 61; // 16°C ≈ 61°F
  final maxTemp = isCelsius ? 26 : 79; // 26°C ≈ 79°F
  if (aqiLevel == 'Good' && temperature > minTemp && temperature < maxTemp && windSpeed < 20) {
    return 'Now is a great time to open your windows!';
  } else if (aqiLevel != 'Good') {
    return 'Air quality is not ideal for open windows.';
  } else if (temperature <= minTemp) {
    return 'It may be too cold to open your windows.';
  } else if (temperature >= maxTemp) {
    return 'It may be too warm to open your windows.';
  } else if (windSpeed >= 20) {
    return 'It is too windy to open your windows.';
  }
  return '';
}

class _LiveTimestamp extends StatefulWidget {
  final Color textColor;
  const _LiveTimestamp({Key? key, this.textColor = Colors.black54}) : super(key: key);
  @override
  State<_LiveTimestamp> createState() => _LiveTimestampState();
}

class _LiveTimestampState extends State<_LiveTimestamp> {
  late String _timestamp;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timestamp = _getFormattedTimestamp();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timestamp = _getFormattedTimestamp();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _timestamp,
      style: TextStyle(
        color: widget.textColor,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        shadows: widget.textColor == Colors.white ? [
          const Shadow(
            offset: Offset(1.0, 1.0),
            blurRadius: 3.0,
            color: Colors.black54,
          ),
        ] : [],
      ),
    );
  }
}

String _getFormattedTimestamp() {
  final now = DateTime.now();
  final month = _monthShort(now.month);
  final day = now.day;
  final hour = now.hour;
  final minute = now.minute.toString().padLeft(2, '0');
  final ampm = hour < 12 ? 'am' : 'pm';
  final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$month $day $hour12:$minute $ampm';
}

String _monthShort(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return months[month - 1];
}

// Helper function to determine if house should show open windows
bool _shouldShowOpenWindows(String aqiLevel, double temperature, double windSpeed, bool isCelsius) {
  // Simple logic for determining when windows should be open
  final coldThreshold = isCelsius ? 16.0 : 61.0;
  final hotThreshold = isCelsius ? 26.0 : 79.0;
  
  // Convert wind speed to km/h for consistent comparison
  double windSpeedKmh;
  if (isCelsius) {
    // Metric units: wind speed is in m/s, convert to km/h
    windSpeedKmh = windSpeed * 3.6;
  } else {
    // Imperial units: wind speed is in mph, convert to km/h
    windSpeedKmh = windSpeed * 1.60934;
  }
  
  return aqiLevel == 'Good' && 
         temperature > coldThreshold && 
         temperature < hotThreshold && 
         windSpeedKmh < 25;
}
