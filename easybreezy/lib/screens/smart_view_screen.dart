import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/smart_energy_advisor_card.dart';
import '../widgets/predictive_window_recommendations_widget.dart';
import '../widgets/smart_thermostat_connection_widget.dart';
import '../widgets/carbon_footprint_widget.dart';
import '../widgets/thermostat_control_card.dart';
import '../screens/connect_smart_thermostat_page.dart';
import '../models/smart_thermostat_model.dart';
import '../models/predictive_recommendation_model.dart';
import '../models/carbon_footprint_model.dart';

/// Smart View Screen with configurable inactive widget overlays
/// 
/// TESTING TOGGLES:
/// - Set `_showInactiveOverlays` to false to remove all overlays for testing
/// - Set `_isThermostatConnected` to true to simulate connected thermostat
/// 
/// This creates semi-transparent overlays on widgets 2-5 when thermostat is not connected
class SmartViewScreen extends StatelessWidget {
  const SmartViewScreen({Key? key}) : super(key: key);

  // 🔧 TESTING TOGGLE: Set to false to remove inactive overlays for testing
  static const bool _showInactiveOverlays = true;
  
  // Mock thermostat connection status (in real app this would come from provider/state)
  static const bool _isThermostatConnected = false;

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

  /// Creates a widget with an inactive overlay if thermostat is not connected
  Widget _buildInactiveWidget({
    required Widget child,
    required BuildContext context,
  }) {
    if (!_showInactiveOverlays || _isThermostatConnected) {
      return child;
    }

    return Stack(
      children: [
        child,
        // Semi-transparent overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 32,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect Thermostat\nto Activate',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<WeatherProvider, HomeProvider>(
      builder: (context, weatherProvider, homeProvider, _) {
        final isLoading = weatherProvider.isLoading;
        final weatherData = weatherProvider.currentWeather;
        final error = weatherProvider.error;
        final homeConfig = homeProvider.homeConfig;
        final isCelsius = homeProvider.isCelsius;

        if (isLoading && weatherData == null) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_getBackgroundImage()),
                fit: BoxFit.cover,
              ),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (error != null && weatherData == null) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_getBackgroundImage()),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading weather data', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(error),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => weatherProvider.refreshWeatherData(context),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        if (weatherData == null) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_getBackgroundImage()),
                fit: BoxFit.cover,
              ),
            ),
            child: const Center(child: Text('No weather data available')),
          );
        }

        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(_getBackgroundImage()),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            children: [
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24), // Add top margin for spacing
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16), // Only horizontal padding
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  weatherProvider.city ?? 'Unknown',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary),
                              onPressed: () => weatherProvider.refreshWeatherData(context),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      // Smart Thermostat Connection Widget
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SmartThermostatConnectionWidget(
                          isPremiumUser: homeProvider.isPremiumUser,
                          onConnectTapped: () {
                            // Handle thermostat connection
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Connect Thermostat'),
                                content: const Text(
                                  'Choose your thermostat brand to begin the connection process.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Thermostat connection coming soon! 🌡️'),
                                          backgroundColor: Colors.blue.shade600,
                                        ),
                                      );
                                    },
                                    child: const Text('Continue'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onUpgradeTapped: () {
                            // Navigate to Connect Smart Thermostat page
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const ConnectSmartThermostatPage(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 24),
                      
                      // Thermostat Control Card (Widget 2 - with inactive overlay)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildInactiveWidget(
                          context: context,
                          child: ThermostatControlCard(
                            thermostatName: 'Living Room Thermostat',
                            currentTemperature: 72.0,
                            targetTemperature: 70.0,
                            currentMode: ThermostatMode.cooling,
                            onTargetTemperatureChanged: (temperature) {
                              // Handle target temperature change
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Target temperature set to ${temperature.toStringAsFixed(0)}°F'),
                                  backgroundColor: Colors.blue.shade600,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            onModeChanged: (mode) {
                              // Handle mode change
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Thermostat mode changed to ${mode.displayName}'),
                                  backgroundColor: Colors.green.shade600,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Smart Energy Advisor Card (Widget 3 - with inactive overlay)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildInactiveWidget(
                          context: context,
                          child: SmartEnergyAdvisorCard(
                            thermostatData: SmartThermostatModel.mock(),
                            onApplyNow: () {
                              // Show a snackbar for demo purposes
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Thermostat settings would be applied in a real app!'),
                                  backgroundColor: Colors.green.shade600,
                                  action: SnackBarAction(
                                    label: 'OK',
                                    textColor: Colors.white,
                                    onPressed: () {},
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24), // Add spacing after Energy Advisor Card

                      // Carbon Footprint Tracking Widget (Widget 4 - with inactive overlay)
                      if (weatherData != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildInactiveWidget(
                            context: context,
                            child: CarbonFootprintWidget(
                            carbonData: CarbonFootprintModel.fromWeatherData(
                              weatherData: weatherData,
                              isCelsius: isCelsius,
                              homeSquareFootage: 2000.0, // Default home size, could be configurable later
                              region: 'CA', // You could get this from location services
                              hasThermostatConnected: false, // This would come from user settings
                              currentThermostatTemp: 72.0, // This would come from connected thermostat
                            ),
                            onViewFullReport: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.assessment, color: Colors.white),
                                      const SizedBox(width: 8),
                                      const Expanded(
                                        child: Text('Monthly carbon report feature coming soon!'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green.shade600,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            },
                            onApplyRecommendation: (recommendation) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Text(recommendation.icon),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text('Applied: ${recommendation.title}'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green.shade600,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            },
                            onConnectThermostat: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ConnectSmartThermostatPage(),
                                ),
                              );
                            },
                            onAutoApplyThermostat: (action) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Text(action.icon),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text('Auto-applied: ${action.title}'),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: Colors.green.shade600,
                                  duration: const Duration(seconds: 3),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    textColor: Colors.white,
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Thermostat setting reverted'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      if (weatherData != null) const SizedBox(height: 24),

                      // Predictive Window Recommendations Widget (Widget 5 - with inactive overlay)
                      if (weatherData != null && weatherProvider.forecast != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildInactiveWidget(
                            context: context,
                            child: PredictiveWindowRecommendationsWidget(
                              predictions: PredictiveRecommendationModel.fromForecast(
                                forecastData: weatherProvider.forecast!.hourlyForecast,
                                homeOrientation: homeConfig?.orientation.toString().split('.').last ?? 'North',
                                isCelsius: isCelsius,
                              ),
                              onNotificationTapped: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Notification settings coming soon!'),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      if (weatherData != null && weatherProvider.forecast != null) const SizedBox(height: 24),
                      
                      // End of widgets
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
