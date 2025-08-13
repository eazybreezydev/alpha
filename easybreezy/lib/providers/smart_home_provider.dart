import 'package:flutter/material.dart';
import '../api/smart_home_api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SmartHomeProvider with ChangeNotifier {
  // Connection status
  Map<String, bool> _providerConnections = {
    'smartthings': false,
    'googlehome': false,
  };

  // Connected devices
  List<Map<String, dynamic>> _devices = [];
  
  // Selected device for AC control
  String? _selectedDeviceId;
  
  // AC state
  bool _acIsOn = false;
  double _acTemperature = 22.0;
  String _acFanMode = 'auto';
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Map<String, bool> get providerConnections => _providerConnections;
  List<Map<String, dynamic>> get devices => _devices;
  String? get selectedDeviceId => _selectedDeviceId;
  bool get acIsOn => _acIsOn;
  double get acTemperature => _acTemperature;
  String get acFanMode => _acFanMode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  bool get hasConnectedProviders => _providerConnections.values.any((connected) => connected);
  bool get hasAvailableDevices => _devices.isNotEmpty;

  // Initialize and check connection status
  Future<void> initialize() async {
    await _checkAllProviderStatus();
    if (hasConnectedProviders) {
      await _loadDevices();
    }
  }

  // Check connection status for all providers
  Future<void> _checkAllProviderStatus() async {
    for (String provider in _providerConnections.keys) {
      final status = await SmartHomeApiService.checkProviderStatus(provider);
      if (status != null) {
        _providerConnections[provider] = status['connected'] ?? false;
      }
    }
    notifyListeners();
  }

  // Start OAuth flow for a provider
  Future<void> connectProvider(BuildContext context, String provider) async {
    _setLoading(true);
    _clearError();

    try {
      final authData = await SmartHomeApiService.startOAuthFlow(provider);
      
      if (authData != null && authData['success'] == true) {
        final authUrl = authData['authUrl'];
        
        // Launch the OAuth URL in browser
        final uri = Uri.parse(authUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          
          // Show dialog to user about the OAuth process
          if (context.mounted) {
            _showOAuthInstructionsDialog(context, provider);
          }
        } else {
          _setError('Unable to open authentication page');
        }
      } else {
        _setError('Failed to start authentication process');
      }
    } catch (e) {
      _setError('Error connecting to $provider: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Show instructions dialog for OAuth process
  void _showOAuthInstructionsDialog(BuildContext context, String provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Connect ${_getProviderDisplayName(provider)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You will be redirected to ${_getProviderDisplayName(provider)} to sign in.'),
            const SizedBox(height: 12),
            const Text('Steps:'),
            Text('1. Sign in to your ${_getProviderDisplayName(provider)} account'),
            const Text('2. Grant permissions to Easy Breezy'),
            const Text('3. Return to this app when complete'),
            const SizedBox(height: 12),
            const Text('Once connected, you can control your AC through the app.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Check connection status after a delay
              Future.delayed(const Duration(seconds: 2), () {
                checkConnectionStatus(provider);
              });
            },
            child: const Text('Check Connection'),
          ),
        ],
      ),
    );
  }

  // Check connection status for a specific provider
  Future<void> checkConnectionStatus(String provider) async {
    final status = await SmartHomeApiService.checkProviderStatus(provider);
    if (status != null) {
      _providerConnections[provider] = status['connected'] ?? false;
      
      if (_providerConnections[provider] == true) {
        await _loadDevices();
        _setError(null);
      }
      
      notifyListeners();
    }
  }

  // Disconnect a provider
  Future<void> disconnectProvider(String provider) async {
    _setLoading(true);
    
    final success = await SmartHomeApiService.disconnectProvider(provider);
    if (success) {
      _providerConnections[provider] = false;
      _devices.clear();
      _selectedDeviceId = null;
    }
    
    _setLoading(false);
    notifyListeners();
  }

  // Load connected devices
  Future<void> _loadDevices() async {
    _devices.clear();
    
    for (String provider in _providerConnections.keys) {
      if (_providerConnections[provider] == true) {
        final devices = await SmartHomeApiService.getDevices(provider: provider);
        _devices.addAll(devices);
      }
    }
    
    // Auto-select first device if available
    if (_devices.isNotEmpty && _selectedDeviceId == null) {
      _selectedDeviceId = _devices.first['id'];
      await _updateDeviceStatus();
    }
    
    notifyListeners();
  }

  // Select a device for control
  void selectDevice(String deviceId) {
    _selectedDeviceId = deviceId;
    _updateDeviceStatus();
    notifyListeners();
  }

  // Update current device status
  Future<void> _updateDeviceStatus() async {
    if (_selectedDeviceId == null) return;
    
    final device = _devices.firstWhere(
      (d) => d['id'] == _selectedDeviceId,
      orElse: () => {},
    );
    
    if (device.isNotEmpty) {
      final status = await SmartHomeApiService.getDeviceStatus(
        _selectedDeviceId!,
        provider: device['provider'] ?? 'smartthings',
      );
      
      if (status != null) {
        _acIsOn = status['power'] == 'on';
        _acTemperature = (status['temperature'] ?? 22.0).toDouble();
        _acFanMode = status['fanMode'] ?? 'auto';
        notifyListeners();
      }
    }
  }

  // Turn AC on
  Future<bool> turnOnAC() async {
    if (_selectedDeviceId == null) {
      _setError('No device selected');
      return false;
    }
    
    _setLoading(true);
    _clearError();
    
    final device = _devices.firstWhere((d) => d['id'] == _selectedDeviceId);
    final success = await SmartHomeApiService.turnOnAC(
      _selectedDeviceId!,
      provider: device['provider'] ?? 'smartthings',
      temperature: _acTemperature,
      fanMode: _acFanMode,
    );
    
    if (success) {
      _acIsOn = true;
      await _updateDeviceStatus(); // Refresh status
    } else {
      _setError('Failed to turn on AC');
    }
    
    _setLoading(false);
    notifyListeners();
    return success;
  }

  // Turn AC off
  Future<bool> turnOffAC() async {
    if (_selectedDeviceId == null) {
      _setError('No device selected');
      return false;
    }
    
    _setLoading(true);
    _clearError();
    
    final device = _devices.firstWhere((d) => d['id'] == _selectedDeviceId);
    final success = await SmartHomeApiService.turnOffAC(
      _selectedDeviceId!,
      provider: device['provider'] ?? 'smartthings',
    );
    
    if (success) {
      _acIsOn = false;
      await _updateDeviceStatus(); // Refresh status
    } else {
      _setError('Failed to turn off AC');
    }
    
    _setLoading(false);
    notifyListeners();
    return success;
  }

  // Set AC temperature
  Future<void> setTemperature(double temperature) async {
    if (_selectedDeviceId == null) return;
    
    _acTemperature = temperature;
    notifyListeners();
    
    final device = _devices.firstWhere((d) => d['id'] == _selectedDeviceId);
    await SmartHomeApiService.setACTemperature(
      _selectedDeviceId!,
      temperature,
      provider: device['provider'] ?? 'smartthings',
    );
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  String _getProviderDisplayName(String provider) {
    switch (provider) {
      case 'smartthings':
        return 'SmartThings';
      case 'googlehome':
        return 'Google Home';
      default:
        return provider;
    }
  }

  // Refresh all data
  Future<void> refresh() async {
    await initialize();
  }
}
