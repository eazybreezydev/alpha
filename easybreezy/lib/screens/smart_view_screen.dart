import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/local_ads_banner.dart';
import '../widgets/smart_energy_advisor_card.dart';
import '../widgets/comfort_efficiency_tracker.dart';
import '../widgets/premium_upgrade_banner.dart';
import '../models/smart_thermostat_model.dart';
import '../models/comfort_efficiency_model.dart';

class SmartViewScreen extends StatelessWidget {
  const SmartViewScreen({Key? key}) : super(key: key);

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
              // Sticky Premium Upgrade Banner (only show for non-premium users)
              if (!homeProvider.isPremiumUser)
                SafeArea(
                  bottom: false,
                  child: PremiumUpgradeBanner(
                    onUpgradeTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Upgrade to Premium'),
                          content: const Text(
                            'Unlock advanced energy insights, detailed comfort analytics, and personalized recommendations to maximize your savings!',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Maybe Later'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                // Simulate premium upgrade for demo
                                homeProvider.upgradeToPremium();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Welcome to Premium! 🎉'),
                                    backgroundColor: Colors.green.shade600,
                                  ),
                                );
                              },
                              child: const Text('Upgrade Now'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
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

                      // Smart Energy Advisor Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      const SizedBox(height: 24), // Add spacing after Energy Advisor Card

                      // Comfort Efficiency Tracker
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ComfortEfficiencyTracker(
                          efficiencyData: ComfortEfficiencyModel.mockData(
                            isPremium: homeProvider.isPremiumUser, // Use provider's premium status
                          ),
                          onUpgradeTapped: () {
                            // Navigate to premium upgrade screen or show modal
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Upgrade to Premium'),
                                content: const Text(
                                  'Unlock advanced energy insights, detailed comfort analytics, and personalized recommendations to maximize your savings!',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Maybe Later'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      // Simulate premium upgrade for demo
                                      homeProvider.upgradeToPremium();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Welcome to Premium! 🎉'),
                                          backgroundColor: Colors.green.shade600,
                                        ),
                                      );
                                    },
                                    child: const Text('Upgrade Now'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24), // Add spacing after Comfort Efficiency Tracker
                      // ...other widgets from your old home screen...
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
