import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../providers/weather_provider.dart';
import '../models/home_config.dart';
import '../models/weather_data.dart';
import '../widgets/weather_display.dart';
import '../widgets/recommendation_card.dart';
import '../utils/recommendation_engine.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecommendationEngine _recommendationEngine = RecommendationEngine();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Fetch weather data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchWeatherData();
    });
  }

  Future<void> _fetchWeatherData() async {
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    await weatherProvider.fetchWeatherData();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchWeatherData();
    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EasyBreezy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Consumer2<WeatherProvider, HomeProvider>(
          builder: (context, weatherProvider, homeProvider, _) {
            final isLoading = weatherProvider.isLoading || _isRefreshing;
            final weatherData = weatherProvider.currentWeather;
            final error = weatherProvider.error;
            final homeConfig = homeProvider.homeConfig;

            if (isLoading && weatherData == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (error != null && weatherData == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading weather data',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(error),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _fetchWeatherData,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }

            if (weatherData == null) {
              return const Center(child: Text('No weather data available'));
            }

            // Generate recommendation based on weather and home config
            final recommendation = _recommendationEngine.getRecommendation(
              weatherData,
              homeConfig,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weather display widget
                  WeatherDisplay(weatherData: weatherData),
                  
                  const SizedBox(height: 24),
                  
                  // Recommendation card
                  RecommendationCard(
                    recommendation: recommendation,
                    homeConfig: homeConfig,
                    weatherData: weatherData,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Forecast section
                  if (weatherProvider.forecast != null) ...[
                    Text(
                      'Hourly Forecast',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: weatherProvider.forecast!.hourlyForecast.length,
                        itemBuilder: (context, index) {
                          final hourData = weatherProvider.forecast!.hourlyForecast[index];
                          return _buildHourlyForecastItem(hourData);
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                                    
                  // Home orientation information
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.home, color: Colors.blueGrey),
                              const SizedBox(width: 8),
                              Text(
                                'Your Home',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('Orientation: ${homeConfig.orientation.name} facing'),
                          const SizedBox(height: 8),
                          Text(
                            'Windows: ${_getWindowsText(homeConfig.windows)}',
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsScreen()),
                              );
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Edit Configuration'),
                                SizedBox(width: 4),
                                Icon(Icons.edit, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHourlyForecastItem(WeatherData hourData) {
    final hour = hourData.dateTime.hour;
    final hourString = hour == 0 ? '12 AM' : hour == 12 ? '12 PM' : hour > 12 ? '${hour - 12} PM' : '$hour AM';
    
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            hourString,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _getWeatherIcon(hourData.weatherMain),
          const SizedBox(height: 8),
          Text(
            '${hourData.temperature.toStringAsFixed(0)}°F',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            hourData.windDirection,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _getWeatherIcon(String condition) {
    IconData iconData;
    Color color;
    
    condition = condition.toLowerCase();
    
    if (condition.contains('clear')) {
      iconData = Icons.wb_sunny;
      color = Colors.orange;
    } else if (condition.contains('cloud')) {
      iconData = Icons.cloud;
      color = Colors.grey;
    } else if (condition.contains('rain')) {
      iconData = Icons.grain;
      color = Colors.blueGrey;
    } else if (condition.contains('snow')) {
      iconData = Icons.ac_unit;
      color = Colors.lightBlue;
    } else if (condition.contains('thunder')) {
      iconData = Icons.flash_on;
      color = Colors.amber;
    } else if (condition.contains('mist') || condition.contains('fog')) {
      iconData = Icons.cloud_queue;
      color = Colors.blueGrey;
    } else {
      iconData = Icons.help_outline;
      color = Colors.grey;
    }
    
    return Icon(iconData, size: 28, color: color);
  }

  String _getWindowsText(Map<WindowDirection, bool> windows) {
    final presentWindows = windows.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key.name)
        .toList();
    
    if (presentWindows.isEmpty) {
      return 'No windows configured';
    } else if (presentWindows.length == 4) {
      return 'All sides';
    } else {
      return presentWindows.join(', ');
    }
  }
}