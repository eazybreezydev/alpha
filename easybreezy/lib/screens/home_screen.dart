import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';
import '../providers/smart_home_provider.dart';
import '../providers/location_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/home_dashboard.dart';
import '../services/auto_refresh_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AutoRefreshService _autoRefreshService = AutoRefreshService();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    // Fetch weather data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchWeatherData();
      await _initializeSmartHome();
      await _initializeLocationProvider(); // Call after weather data is loaded
      // Initialize auto-refresh service
      _autoRefreshService.initialize(context);
    });
  }

  @override
  void dispose() {
    // Clean up auto-refresh service when screen is disposed
    _autoRefreshService.dispose();
    super.dispose();
  }

  Future<void> _fetchWeatherData() async {
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    await weatherProvider.fetchWeatherData(context);
  }

  Future<void> _initializeSmartHome() async {
    final smartHomeProvider = Provider.of<SmartHomeProvider>(context, listen: false);
    await smartHomeProvider.initialize();
  }

  Future<void> _initializeLocationProvider() async {
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    
    await locationProvider.initialize();
    
    // Ensure home location exists after weather data is available
    if (weatherProvider.city != null && weatherProvider.province != null) {
      // Use street address if available, otherwise use "Home"
      final locationName = weatherProvider.streetAddress?.isNotEmpty == true 
          ? weatherProvider.streetAddress! 
          : "Home";
      
      await locationProvider.ensureHomeLocationExists(
        name: locationName,
        city: weatherProvider.city!,
        province: weatherProvider.province!,
        latitude: homeProvider.homeConfig.latitude ?? 44.3975666,
        longitude: homeProvider.homeConfig.longitude ?? -79.6767054,
      );
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      // Use the auto-refresh service for manual refresh to maintain consistency
      await _autoRefreshService.manualRefresh();
    } catch (e) {
      // Fallback to direct weather provider call if auto-refresh fails
      await _fetchWeatherData();
    }
    
    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HomeDashboard();
  }
}