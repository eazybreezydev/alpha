import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../models/home_config.dart';

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

  @override
  void initState() {
    super.initState();
    
    // Initialize settings from provider
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final homeConfig = homeProvider.homeConfig;
    
    _selectedOrientation = homeConfig.orientation;
    _selectedWindows = Map.from(homeConfig.windows);
    _tempRange = RangeValues(
      homeConfig.comfortTempMin,
      homeConfig.comfortTempMax,
    );
    _notificationsEnabled = homeConfig.notificationsEnabled;
  }

  void _saveSettings() {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    
    // Update all settings
    homeProvider.updateHomeOrientation(_selectedOrientation);
    homeProvider.updateWindows(_selectedWindows);
    homeProvider.updateComfortTemperature(
      _tempRange.start,
      _tempRange.end,
    );
    homeProvider.toggleNotifications(_notificationsEnabled);
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Home Orientation Section
          _buildSectionHeader('Home Orientation'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonFormField<HomeOrientation>(
              value: _selectedOrientation,
              decoration: const InputDecoration(
                labelText: 'Which direction does your home face?',
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
                  child: Text(orientation.name + ' Facing'),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Windows Section
          _buildSectionHeader('Windows'),
          ...WindowDirection.values.map((direction) {
            return CheckboxListTile(
              title: Text('${direction.name} Windows'),
              subtitle: Text('Windows on the ${direction.name} side of your home'),
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
          
          const SizedBox(height: 24),
          
          // Comfort Temperature Range Section
          _buildSectionHeader('Comfort Temperature Range'),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set your preferred temperature range for open windows',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_tempRange.start.toInt()}°F',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_tempRange.end.toInt()}°F',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
          
          const SizedBox(height: 24),
          
          // Notifications Section
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Get alerts when it\'s ideal to open or close windows'),
            value: _notificationsEnabled,
            activeColor: Theme.of(context).primaryColor,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          
          const SizedBox(height: 32),
          
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
          
          const SizedBox(height: 24),
        ],
      ),
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
          color: Colors.blueGrey,
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
                // Reset to default values
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