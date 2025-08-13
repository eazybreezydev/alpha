import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../providers/weather_provider.dart';
import '../models/home_config.dart';
import '../widgets/wind_flow_animation.dart'; // Import new wind flow system
import '../services/auto_refresh_service.dart';
import 'notification_test_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' as math;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late HomeOrientation _selectedOrientation;
  late Map<WindowDirection, bool> _selectedWindows;
  late RangeValues _tempRange;
  late bool _notificationsEnabled;
  late bool _useCelsius; // Add state for temperature unit
  late String _address; // Add address state
  late TextEditingController _addressController;

  // Detailed notification settings
  late bool _disableAllNotifications;
  
  // Auto-refresh settings
  late bool _autoRefreshEnabled;
  
  // Ventilation Alerts
  late bool _openWindowsAlert;
  late bool _closeWindowsAlert;
  late bool _windAlignmentAlert;
  late int _ventilationFrequency; // 1, 3, or 6 hours
  
  // Weather Warnings
  late bool _rainAlert;
  late bool _stormWarning;
  late bool _highWindAdvisory;
  
  // Forecast-Based Notifications
  late bool _ventilationOpportunity;
  late bool _poorAirQuality;
  late bool _highPollenAlert;
  late bool _smokeAdvisory;
  
  // Daily Summary
  late bool _dailyMorningSummary;
  late bool _weeklyReport;
  late int _snoozeNotifications; // 30, 60, 180 minutes
  
  // Preferences
  late bool _customComfortZones;
  late bool _silentHours;
  late TimeOfDay _silentStart;
  late TimeOfDay _silentEnd;
  late bool _vacationMode;

  static const String kGoogleApiKey = 'AIzaSyBmZfcpnFKGRr2uzcL3ayXxUN-_fX6fy7s'; // TODO: Replace with your API key
  List<String> _addressSuggestions = [];
  bool _isLoadingSuggestions = false;
  Map<String, double>? _selectedCoords;

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
  void initState() {
    super.initState();
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final homeConfig = homeProvider.homeConfig;
    _selectedOrientation = homeConfig.orientation;
    _selectedWindows = Map.from(homeConfig.windows);
    _tempRange = RangeValues(
      homeConfig.comfortTempMin,
      homeConfig.comfortTempMax,
    );
    _notificationsEnabled = homeConfig.notificationsEnabled;
    _useCelsius = homeProvider.isCelsius;
    _address = homeConfig.address ?? '';
    _addressController = TextEditingController(text: _address);
    
    // Initialize detailed notification settings
    _initializeNotificationSettings();
    
    // Initialize auto-refresh settings
    _autoRefreshEnabled = AutoRefreshService().isEnabled;
    
    // Load saved coordinates if available
    if (homeConfig.latitude != null && homeConfig.longitude != null) {
      _selectedCoords = {
        'lat': homeConfig.latitude!,
        'lng': homeConfig.longitude!,
      };
    }
  }

  void _initializeNotificationSettings() {
    // Initialize with default values - in a real app, load from SharedPreferences
    _disableAllNotifications = false;
    
    // Ventilation Alerts
    _openWindowsAlert = true;
    _closeWindowsAlert = true;
    _windAlignmentAlert = false;
    _ventilationFrequency = 3; // 3 hours default
    
    // Weather Warnings
    _rainAlert = true;
    _stormWarning = true;
    _highWindAdvisory = false;
    
    // Forecast-Based Notifications
    _ventilationOpportunity = true;
    _poorAirQuality = true;
    _highPollenAlert = false;
    _smokeAdvisory = true;
    
    // Daily Summary
    _dailyMorningSummary = true;
    _weeklyReport = false;
    _snoozeNotifications = 60; // 1 hour default
    
    // Preferences
    _customComfortZones = false;
    _silentHours = false;
    _silentStart = const TimeOfDay(hour: 22, minute: 0); // 10 PM
    _silentEnd = const TimeOfDay(hour: 7, minute: 0); // 7 AM
    _vacationMode = false;
  }

  void _saveSettings() async {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
    final oldIsCelsius = homeProvider.isCelsius;
    
    // Update all settings
    homeProvider.updateHomeOrientation(_selectedOrientation);
    homeProvider.updateWindows(_selectedWindows);
    homeProvider.updateComfortTemperature(
      _tempRange.start,
      _tempRange.end,
    );
    homeProvider.toggleNotifications(_notificationsEnabled);
    
    // Save detailed notification settings
    await _saveNotificationSettings();
    
    // Save address and coordinates if available
    if (_selectedCoords != null) {
      homeProvider.updateAddressWithCoords(
        _address,
        _selectedCoords!['lat'],
        _selectedCoords!['lng'],
      );
    } else {
      homeProvider.updateAddress(_address);
    }
    // Save temperature unit
    if (homeProvider.isCelsius != _useCelsius) {
      homeProvider.toggleTemperatureUnit();
      // Refetch weather data if unit changed
      await weatherProvider.fetchWeatherData(context);
    }
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  Future<void> _saveNotificationSettings() async {
    // In a real app, save to SharedPreferences
    // For now, we'll just store in the state
    print('Saving notification settings...');
    // TODO: Implement SharedPreferences saving
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _silentStart : _silentEnd,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _silentStart = picked;
        } else {
          _silentEnd = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getFrequencyText(int hours) {
    switch (hours) {
      case 1: return 'Every hour';
      case 3: return 'Every 3 hours';
      case 6: return 'Every 6 hours';
      default: return 'Every 3 hours';
    }
  }

  String _getSnoozeText(int minutes) {
    switch (minutes) {
      case 30: return '30 minutes';
      case 60: return '1 hour';
      case 180: return '3 hours';
      default: return '1 hour';
    }
  }

  Future<void> _fetchAddressSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _addressSuggestions = [];
      });
      return;
    }
    setState(() {
      _isLoadingSuggestions = true;
    });
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&types=address&key=$kGoogleApiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _addressSuggestions = (data['predictions'] as List)
            .map((p) => p['description'] as String)
            .toList();
        _isLoadingSuggestions = false;
      });
    } else {
      setState(() {
        _addressSuggestions = [];
        _isLoadingSuggestions = false;
      });
    }
  }

  // Fetch place details and extract coordinates
  Future<Map<String, double>?> _fetchPlaceCoordinates(String address) async {
    // First, get the place_id for the selected address
    final autocompleteUrl = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(address)}&types=address&key=$kGoogleApiKey',
    );
    final autocompleteResponse = await http.get(autocompleteUrl);
    if (autocompleteResponse.statusCode == 200) {
      final data = json.decode(autocompleteResponse.body);
      if (data['predictions'] != null && data['predictions'].isNotEmpty) {
        final placeId = data['predictions'][0]['place_id'];
        // Now fetch details
        final detailsUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$kGoogleApiKey',
        );
        final detailsResponse = await http.get(detailsUrl);
        if (detailsResponse.statusCode == 200) {
          final detailsData = json.decode(detailsResponse.body);
          final location = detailsData['result']?['geometry']?['location'];
          if (location != null) {
            return {
              'lat': location['lat'] as double,
              'lng': location['lng'] as double,
            };
          }
        }
      }
    }
    return null;
  }

  // Suggest orientation based on coordinates (simple version: use longitude)
  void _suggestOrientationFromCoords(Map<String, double> coords) {
    // This is a placeholder: you can use more advanced logic if desired
    // For now, if longitude > 0, suggest east; < 0, suggest west; else north
    setState(() {
      if (coords['lng']! > 0) {
        _selectedOrientation = HomeOrientation.east;
      } else if (coords['lng']! < 0) {
        _selectedOrientation = HomeOrientation.west;
      } else {
        _selectedOrientation = HomeOrientation.north;
      }
    });
    // Optionally, show a SnackBar or indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Orientation suggested based on address. You can override it.')),
    );
  }

  Future<void> _fetchPlaceDetailsAndSuggestOrientation(String address) async {
    // Find the place_id for the selected address
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(address)}&types=address&key=$kGoogleApiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final predictions = data['predictions'] as List;
      if (predictions.isNotEmpty) {
        final placeId = predictions.first['place_id'];
        // Fetch place details
        final detailsUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$kGoogleApiKey',
        );
        final detailsResponse = await http.get(detailsUrl);
        if (detailsResponse.statusCode == 200) {
          final detailsData = json.decode(detailsResponse.body);
          final location = detailsData['result']?['geometry']?['location'];
          if (location != null) {
            final double lat = location['lat'];
            final double lng = location['lng'];
            // Suggest orientation based on longitude
            HomeOrientation suggestedOrientation;
            if (lng > 0) {
              suggestedOrientation = HomeOrientation.east;
            } else if (lng < 0) {
              suggestedOrientation = HomeOrientation.west;
            } else {
              suggestedOrientation = HomeOrientation.north;
            }
            setState(() {
              _selectedOrientation = suggestedOrientation;
            });
            // Show a visual indicator (SnackBar)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Orientation auto-suggested: '
                    '${suggestedOrientation.name[0].toUpperCase()}${suggestedOrientation.name.substring(1)} Facing'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, _) {
        final windSpeed = weatherProvider.currentWeather?.windSpeed ?? 0;
        final windDirection = weatherProvider.currentWeather?.windDirection ?? 'E';
        
        return Scaffold(
          backgroundColor: Colors.black, // Set a solid background for the scaffold
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 3.0,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(
              color: Colors.white,
              shadows: [
                Shadow(
                  offset: Offset(1.0, 1.0),
                  blurRadius: 3.0,
                  color: Colors.black54,
                ),
              ],
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_getBackgroundImage()),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // Realistic wind flow overlay background
                WindFlowOverlay(
                  windDirection: windDirection,
                  windSpeed: windSpeed.toDouble(),
                  subtleMode: windSpeed < 15, // Subtle mode for light winds
                ),
              ListView(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + kToolbarHeight,
                  bottom: 120, // Add bottom margin to access reset wizard button
                ),
                children: [
                  const SizedBox(height: 16),
                  
                  // Auto-Refresh Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Auto-Refresh',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            SwitchListTile(
                              title: const Text(
                                'Enable Auto-Refresh',
                                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                _autoRefreshEnabled 
                                  ? 'Weather data refreshes every 15 minutes'
                                  : 'Manual refresh only',
                                style: const TextStyle(color: Colors.black87),
                              ),
                              value: _autoRefreshEnabled,
                              activeColor: Theme.of(context).primaryColor,
                              onChanged: (bool value) {
                                setState(() {
                                  _autoRefreshEnabled = value;
                                  if (value) {
                                    AutoRefreshService().enable();
                                  } else {
                                    AutoRefreshService().disable();
                                  }
                                });
                              },
                            ),
                            
                            if (_autoRefreshEnabled) ...[
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.access_time, color: Colors.blue),
                                title: const Text(
                                  'Refresh Interval',
                                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '${AutoRefreshService().refreshIntervalMinutes} minutes',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                                trailing: const Icon(Icons.info_outline, color: Colors.grey),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Auto-Refresh Info'),
                                        content: const Text(
                                          'The app automatically refreshes weather data every 15 minutes to keep information current while minimizing device resource usage.\n\n'
                                          '• Works in background when app is active\n'
                                          '• Pauses when app is in background to save battery\n'
                                          '• Resumes and refreshes when app comes back to foreground\n'
                                          '• Does not show loading indicators during auto-refresh',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                              const Divider(),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Auto-refresh is active and running',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Notifications Section (comprehensive)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Master toggle
                            SwitchListTile(
                              title: const Text(
                                'Enable Notifications',
                                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                              ),
                              subtitle: const Text(
                                'Master control for all notifications',
                                style: TextStyle(color: Colors.black87),
                              ),
                              value: _notificationsEnabled && !_disableAllNotifications,
                              activeColor: Theme.of(context).primaryColor,
                              onChanged: (bool value) {
                                setState(() {
                                  _notificationsEnabled = value;
                                  _disableAllNotifications = !value;
                                });
                              },
                            ),
                            
                            // Notification Testing (for development)
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.bug_report, color: Colors.orange),
                              title: const Text(
                                'Test Notifications',
                                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                              ),
                              subtitle: const Text(
                                'Test different notification types and Firebase messaging',
                                style: TextStyle(color: Colors.black87),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const NotificationTestScreen(),
                                  ),
                                );
                              },
                            ),
                            
                            if (_notificationsEnabled && !_disableAllNotifications) ...[
                              const Divider(),
                              
                              // Ventilation Alerts
                              ExpansionTile(
                                title: const Text(
                                  'Ventilation Alerts',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                                children: [
                                  SwitchListTile(
                                    title: const Text('Open Windows Alert', style: TextStyle(color: Colors.black87)),
                                    subtitle: const Text('Get notified when it\'s ideal to open windows', style: TextStyle(color: Colors.black87)),
                                    value: _openWindowsAlert,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (value) => setState(() => _openWindowsAlert = value),
                                  ),
                                  SwitchListTile(
                                    title: const Text('Close Windows Alert', style: TextStyle(color: Colors.black87)),
                                    subtitle: const Text('Get notified when you should close windows', style: TextStyle(color: Colors.black87)),
                                    value: _closeWindowsAlert,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (value) => setState(() => _closeWindowsAlert = value),
                                  ),
                                  SwitchListTile(
                                    title: const Text('Wind Alignment Alert', style: TextStyle(color: Colors.black87)),
                                    subtitle: const Text('Notify when wind aligns with home orientation', style: TextStyle(color: Colors.black87)),
                                    value: _windAlignmentAlert,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (value) => setState(() => _windAlignmentAlert = value),
                                  ),
                                  ListTile(
                                    title: const Text('Alert Frequency', style: TextStyle(color: Colors.black87)),
                                    subtitle: Text(_getFrequencyText(_ventilationFrequency), style: const TextStyle(color: Colors.black87)),
                                    trailing: DropdownButton<int>(
                                      value: _ventilationFrequency,
                                      items: [1, 3, 6].map((int value) {
                                        return DropdownMenuItem<int>(
                                          value: value,
                                          child: Text(_getFrequencyText(value)),
                                        );
                                      }).toList(),
                                      onChanged: (value) => setState(() => _ventilationFrequency = value!),
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Weather Warnings
                              ExpansionTile(
                                title: const Text(
                                  'Weather Warnings',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                                children: [
                                  SwitchListTile(
                                    title: const Text('Rain Alert', style: TextStyle(color: Colors.black87)),
                                    subtitle: const Text('Get warned about incoming rain', style: TextStyle(color: Colors.black87)),
                                    value: _rainAlert,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (value) => setState(() => _rainAlert = value),
                                  ),
                                  SwitchListTile(
                                    title: const Text('Storm Warning', style: TextStyle(color: Colors.black87)),
                                    subtitle: const Text('Severe weather alerts', style: TextStyle(color: Colors.black87)),
                                    value: _stormWarning,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (value) => setState(() => _stormWarning = value),
                                  ),
                                  SwitchListTile(
                                    title: const Text('High Wind Advisory', style: TextStyle(color: Colors.black87)),
                                    subtitle: const Text('Alerts for dangerous wind speeds', style: TextStyle(color: Colors.black87)),
                                    value: _highWindAdvisory,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (value) => setState(() => _highWindAdvisory = value),
                                  ),
                                ],
                              ),
                              
                              // Forecast-Based Notifications
                              ExpansionTile(
                                title: const Text(
                                  'Forecast-Based',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                                children: [
                                  SwitchListTile(
                                    title: const Text('Upcoming Ventilation Opportunity', style: TextStyle(color: Colors.black87)),
                                    subtitle: const Text('Plan ahead for ideal window conditions', style: TextStyle(color: Colors.black87)),
                                    value: _ventilationOpportunity,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (value) => setState(() => _ventilationOpportunity = value),
                                  ),
                                  SwitchListTile(
                                    title: const Text('Poor Air Quality Warning', style: TextStyle(color: Colors.black87)),
                                    subtitle: const Text('Keep windows closed during poor air quality', style: TextStyle(color: Colors.black87)),
                                    value: _poorAirQuality,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (value) => setState(() => _poorAirQuality = value),
                                  ),
                                  SwitchListTile(
                                    title: const Text('High Pollen Alert', style: TextStyle(color: Colors.black87)),
                                    subtitle: const Text('Allergy-friendly ventilation timing', style: TextStyle(color: Colors.black87)),
                                    value: _highPollenAlert,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (value) => setState(() => _highPollenAlert = value),
                                  ),
                                  SwitchListTile(
                                    title: const Text('Smoke Advisory', style: TextStyle(color: Colors.black87)),
                                    subtitle: const Text('Wildfire smoke and air quality alerts', style: TextStyle(color: Colors.black87)),
                                    value: _smokeAdvisory,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (value) => setState(() => _smokeAdvisory = value),
                                  ),
                                ],
                              ),
                              
                              // Daily Summary
                              ExpansionTile(
                                title: const Text(
                                  'Daily Summary',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                                children: [
                                  SwitchListTile(
                                    title: const Text('Daily Morning Summary', style: TextStyle(color: Colors.black87)),
                                    subtitle: const Text('Start your day with ventilation insights', style: TextStyle(color: Colors.black87)),
                                    value: _dailyMorningSummary,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (value) => setState(() => _dailyMorningSummary = value),
                                  ),
                                  SwitchListTile(
                                    title: const Text('Weekly Report', style: TextStyle(color: Colors.black87)),
                                    subtitle: const Text('Weekly ventilation and energy summary', style: TextStyle(color: Colors.black87)),
                                    value: _weeklyReport,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (value) => setState(() => _weeklyReport = value),
                                  ),
                                  ListTile(
                                    title: const Text('Snooze Duration', style: TextStyle(color: Colors.black87)),
                                    subtitle: Text(_getSnoozeText(_snoozeNotifications), style: const TextStyle(color: Colors.black87)),
                                    trailing: DropdownButton<int>(
                                      value: _snoozeNotifications,
                                      items: [30, 60, 180].map((int value) {
                                        return DropdownMenuItem<int>(
                                          value: value,
                                          child: Text(_getSnoozeText(value)),
                                        );
                                      }).toList(),
                                      onChanged: (value) => setState(() => _snoozeNotifications = value!),
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Preferences
                              ExpansionTile(
                                title: const Text(
                                  'Preferences',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                                ),
                                children: [
                                  SwitchListTile(
                                    title: const Text('Custom Comfort Zones', style: TextStyle(color: Colors.black87)),
                                    subtitle: const Text('Use personalized temperature & humidity ranges', style: TextStyle(color: Colors.black87)),
                                    value: _customComfortZones,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (value) => setState(() => _customComfortZones = value),
                                  ),
                                  SwitchListTile(
                                    title: const Text('Silent Hours', style: TextStyle(color: Colors.black87)),
                                    subtitle: Text(
                                      _silentHours 
                                        ? 'Quiet from ${_formatTimeOfDay(_silentStart)} to ${_formatTimeOfDay(_silentEnd)}'
                                        : 'No quiet hours set',
                                      style: const TextStyle(color: Colors.black87),
                                    ),
                                    value: _silentHours,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (value) => setState(() => _silentHours = value),
                                  ),
                                  if (_silentHours) ...[
                                    ListTile(
                                      title: const Text('Silent Start Time', style: TextStyle(color: Colors.black87)),
                                      subtitle: Text(_formatTimeOfDay(_silentStart), style: const TextStyle(color: Colors.black87)),
                                      trailing: const Icon(Icons.access_time),
                                      onTap: () => _selectTime(true),
                                    ),
                                    ListTile(
                                      title: const Text('Silent End Time', style: TextStyle(color: Colors.black87)),
                                      subtitle: Text(_formatTimeOfDay(_silentEnd), style: const TextStyle(color: Colors.black87)),
                                      trailing: const Icon(Icons.access_time),
                                      onTap: () => _selectTime(false),
                                    ),
                                  ],
                                  SwitchListTile(
                                    title: const Text('Vacation Mode', style: TextStyle(color: Colors.black87)),
                                    subtitle: const Text('Disable all notifications temporarily', style: TextStyle(color: Colors.black87)),
                                    value: _vacationMode,
                                    activeColor: Theme.of(context).primaryColor,
                                    onChanged: (value) => setState(() => _vacationMode = value),
                                  ),
                                ],
                              ),
                            ],
                            
                            const Divider(),
                            SwitchListTile(
                              title: const Text(
                                'Use Celsius',
                                style: TextStyle(color: Colors.black87),
                              ),
                              subtitle: const Text(
                                'Toggle between Celsius and Fahrenheit',
                                style: TextStyle(color: Colors.black87),
                              ),
                              value: _useCelsius,
                              activeColor: Theme.of(context).primaryColor,
                              onChanged: (bool value) {
                                setState(() {
                                  _useCelsius = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Home Orientation Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Home Orientation',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<HomeOrientation>(
                              value: _selectedOrientation,
                              decoration: const InputDecoration(
                                labelText: 'Which direction does your home face?',
                                labelStyle: TextStyle(color: Colors.black87),
                              ),
                              onChanged: (HomeOrientation? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedOrientation = newValue;
                                  });
                                }
                              },
                              items: HomeOrientation.values.map((HomeOrientation orientation) {
                                return DropdownMenuItem<HomeOrientation>(
                                  value: orientation,
                                  child: Text(
                                    orientation.name + ' Facing',
                                    style: const TextStyle(color: Colors.black87),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          
          const SizedBox(height: 24),
          
          // Windows Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Windows',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...WindowDirection.values.map((direction) {
                      return CheckboxListTile(
                        title: Text(
                          '${direction.name} Windows',
                          style: const TextStyle(color: Colors.black87),
                        ),
                        subtitle: Text(
                          'Windows on the ${direction.name} side of your home',
                          style: const TextStyle(color: Colors.black87),
                        ),
                        value: _selectedWindows[direction] ?? false,
                        activeColor: Theme.of(context).primaryColor,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value != null) {
                              _selectedWindows[direction] = value;
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Comfort Temperature Range Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Comfort Temperature Range',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Set your preferred temperature range for open windows',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_tempRange.start.toInt()}°F',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        Text(
                          '${_tempRange.end.toInt()}°F',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: _tempRange,
                      min: 50,
                      max: 90,
                      divisions: 40,
                      labels: RangeLabels(
                        '${_tempRange.start.toInt()}°F',
                        '${_tempRange.end.toInt()}°F',
                      ),
                      onChanged: (RangeValues values) {
                        setState(() {
                          _tempRange = values;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),

          // Address Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Home Address',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                        labelText: 'Enter your home address',
                        labelStyle: TextStyle(color: Colors.black87),
                        hintText: '123 Main St, City, State',
                        hintStyle: TextStyle(color: Colors.grey),
                        suffixIcon: Icon(Icons.location_on),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _address = value;
                        });
                        _fetchAddressSuggestions(value);
                      },
                      onFieldSubmitted: (value) async {
                        // When user presses enter or submits, try to get coordinates for manually typed address
                        if (value.isNotEmpty && _selectedCoords == null) {
                          final coords = await _fetchPlaceCoordinates(value);
                          if (coords != null) {
                            setState(() {
                              _selectedCoords = coords;
                            });
                            _fetchPlaceDetailsAndSuggestOrientation(value);
                          }
                        }
                      },
                    ),
                    if (_isLoadingSuggestions)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: LinearProgressIndicator(),
                      ),
                    if (_addressSuggestions.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        margin: const EdgeInsets.only(top: 8.0),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _addressSuggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = _addressSuggestions[index];
                            return ListTile(
                              title: Text(
                                suggestion,
                                style: const TextStyle(color: Colors.black87),
                              ),
                              onTap: () async {
                                setState(() {
                                  _address = suggestion;
                                  _addressController.text = suggestion;
                                  _addressSuggestions = [];
                                });
                                final coords = await _fetchPlaceCoordinates(suggestion);
                                if (coords != null) {
                                  setState(() {
                                    _selectedCoords = coords;
                                  });
                                }
                                _fetchPlaceDetailsAndSuggestOrientation(suggestion);
                              },
                            );
                          },
                        ),
                      ),
                    // Show map if we have coordinates (either from saved address or newly selected)
                    if (_selectedCoords != null && _address.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      // Static Map Preview (fixed size, rounded corners, centered)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400, width: 1),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Builder(
                                  builder: (context) {
                                    final lat = _selectedCoords!['lat']?.toStringAsFixed(6);
                                    final lng = _selectedCoords!['lng']?.toStringAsFixed(6);
                                    final mapUrl =
                                        'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=15&size=320x180&scale=2&markers=color:red%7C$lat,$lng&key=$kGoogleApiKey';
                                    return Image.network(
                                      mapUrl,
                                      width: 320,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 320,
                                        height: 180,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Text(
                                            'Map preview unavailable',
                                            style: TextStyle(color: Colors.black87),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Compass overlay
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: _CompassPainter(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Manual Orientation Picker
                      _OrientationPicker(
                        selected: _selectedOrientation,
                        onChanged: (o) {
                          setState(() {
                            _selectedOrientation = o;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap a direction to set your home\'s front orientation',
                        style: TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      // Show current saved address info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _address.isNotEmpty ? _address : 'No address saved',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Save Settings'),
            ),
          ),

          // Reset to defaults option
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextButton(
              onPressed: () {
                _showResetDialog(context);
              },
              child: const Text('Reset to Defaults'),
            ),
          ),
          // Temporary Full reset button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextButton(
              onPressed: () async {
                // Reset onboarding flag and home config
                final homeProvider = Provider.of<HomeProvider>(context, listen: false);
                await homeProvider.resetOnboardingAndConfig();
                // Navigate to setup wizard (replace with your actual route)
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/setup', (route) => false);
                }
              },
              child: const Text('Full reset (Setup Wizard)'),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Settings'),
          content: const Text(
            'Are you sure you want to reset all settings to default values?'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedOrientation = HomeOrientation.north;
                  _selectedWindows = {
                    WindowDirection.north: false,
                    WindowDirection.east: false,
                    WindowDirection.south: false,
                    WindowDirection.west: false,
                  };
                  _tempRange = const RangeValues(65.0, 78.0);
                  _notificationsEnabled = true;
                  _useCelsius = false;
                  _address = '';
                });
                Navigator.of(context).pop();
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }
}

// Orientation Picker widget
class _OrientationPicker extends StatelessWidget {
  final HomeOrientation selected;
  final ValueChanged<HomeOrientation> onChanged;
  const _OrientationPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: HomeOrientation.values.map((o) {
        final isSelected = o == selected;
        return GestureDetector(
          onTap: () => onChanged(o),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.blue : Colors.grey[300],
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.grey,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  o == HomeOrientation.north
                      ? Icons.arrow_upward
                      : o == HomeOrientation.east
                          ? Icons.arrow_forward
                          : o == HomeOrientation.south
                              ? Icons.arrow_downward
                              : Icons.arrow_back,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                Text(
                  o.name[0].toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// Add this below _OrientationPicker
class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final double radius = size.shortestSide / 2 - 12;
    final Offset center = Offset(size.width / 2, size.height / 2);
    // Draw circle
    canvas.drawCircle(center, radius, paint);
    // Draw N, S, E, W
    final textStyle = TextStyle(
      color: Colors.black87.withOpacity(0.7),
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
    final directions = ['N', 'E', 'S', 'W'];
    for (int i = 0; i < 4; i++) {
      final angle = (-90 + i * 90) * 3.1415926535 / 180;
      final dx = center.dx + radius * 0.85 * math.cos(angle);
      final dy = center.dy + radius * 0.85 * math.sin(angle);
      final textSpan = TextSpan(text: directions[i], style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(dx - textPainter.width / 2, dy - textPainter.height / 2);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}