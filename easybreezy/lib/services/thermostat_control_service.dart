import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for controlling smart thermostats through their APIs
class ThermostatControlService {
  static const String _baseUrl = 'https://api.ecobee.com/1'; // Example with Ecobee
  static const String _nestUrl = 'https://smartdevicemanagement.googleapis.com/v1';
  
  /// Sets the target temperature on the connected thermostat
  Future<bool> setTemperature({
    required String deviceId,
    required String accessToken,
    required double targetTemp,
    required ThermostatBrand brand,
    required TemperatureMode mode,
    Duration? holdDuration,
  }) async {
    try {
      switch (brand) {
        case ThermostatBrand.ecobee:
          return await _setEcobeeTemperature(
            deviceId: deviceId,
            accessToken: accessToken,
            targetTemp: targetTemp,
            mode: mode,
            holdDuration: holdDuration,
          );
        case ThermostatBrand.nest:
          return await _setNestTemperature(
            deviceId: deviceId,
            accessToken: accessToken,
            targetTemp: targetTemp,
            mode: mode,
          );
        case ThermostatBrand.honeywell:
          return await _setHoneywellTemperature(
            deviceId: deviceId,
            accessToken: accessToken,
            targetTemp: targetTemp,
            mode: mode,
            holdDuration: holdDuration,
          );
        default:
          throw UnsupportedError('Brand $brand not supported');
      }
    } catch (e) {
      print('Error setting temperature: $e');
      return false;
    }
  }

  /// Ecobee API implementation
  Future<bool> _setEcobeeTemperature({
    required String deviceId,
    required String accessToken,
    required double targetTemp,
    required TemperatureMode mode,
    Duration? holdDuration,
  }) async {
    final tempF = targetTemp; // Ecobee uses Fahrenheit
    final holdType = holdDuration != null ? 'holdHours' : 'indefinite';
    final holdHours = holdDuration?.inHours ?? 0;

    final body = {
      'selection': {
        'selectionType': 'thermostats',
        'selectionMatch': deviceId,
      },
      'functions': [
        {
          'type': 'setHold',
          'params': {
            'holdType': holdType,
            'holdHours': holdHours,
            if (mode == TemperatureMode.cooling) 'coolHoldTemp': (tempF * 10).round(),
            if (mode == TemperatureMode.heating) 'heatHoldTemp': (tempF * 10).round(),
            if (mode == TemperatureMode.auto) ...{
              'coolHoldTemp': ((tempF + 2) * 10).round(),
              'heatHoldTemp': ((tempF - 2) * 10).round(),
            },
          },
        },
      ],
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/thermostat'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    return response.statusCode == 200;
  }

  /// Nest API implementation
  Future<bool> _setNestTemperature({
    required String deviceId,
    required String accessToken,
    required double targetTemp,
    required TemperatureMode mode,
  }) async {
    final tempC = (targetTemp - 32) * 5 / 9; // Nest uses Celsius

    Map<String, dynamic> body = {};
    
    switch (mode) {
      case TemperatureMode.heating:
        body = {
          'traits': {
            'sdm.devices.traits.ThermostatTemperatureSetpoint': {
              'heatCelsius': tempC,
            },
          },
        };
        break;
      case TemperatureMode.cooling:
        body = {
          'traits': {
            'sdm.devices.traits.ThermostatTemperatureSetpoint': {
              'coolCelsius': tempC,
            },
          },
        };
        break;
      case TemperatureMode.auto:
        body = {
          'traits': {
            'sdm.devices.traits.ThermostatTemperatureSetpoint': {
              'heatCelsius': tempC - 1,
              'coolCelsius': tempC + 1,
            },
          },
        };
        break;
    }

    final response = await http.post(
      Uri.parse('$_nestUrl/enterprises/project-id/devices/$deviceId:executeCommand'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'command': 'sdm.devices.commands.ThermostatTemperatureSetpoint.SetRange',
        'params': body['traits']['sdm.devices.traits.ThermostatTemperatureSetpoint'],
      }),
    );

    return response.statusCode == 200;
  }

  /// Honeywell API implementation
  Future<bool> _setHoneywellTemperature({
    required String deviceId,
    required String accessToken,
    required double targetTemp,
    required TemperatureMode mode,
    Duration? holdDuration,
  }) async {
    final tempF = targetTemp;
    final autoChangeoverActive = mode == TemperatureMode.auto;

    Map<String, dynamic> body = {
      'thermostatSetpointStatus': {
        if (mode == TemperatureMode.cooling || mode == TemperatureMode.auto)
          'coolSetpoint': tempF,
        if (mode == TemperatureMode.heating || mode == TemperatureMode.auto)
          'heatSetpoint': tempF,
      },
      'changeableValues': {
        'mode': mode.toString().split('.').last.toLowerCase(),
        'autoChangeoverActive': autoChangeoverActive,
        if (holdDuration != null) ...{
          'nextPeriodTime': DateTime.now().add(holdDuration).toIso8601String(),
        },
      },
    };

    final response = await http.post(
      Uri.parse('https://api.honeywell.com/v2/devices/thermostats/$deviceId'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    return response.statusCode == 200;
  }

  /// Gets current thermostat status
  Future<ThermostatStatus?> getThermostatStatus({
    required String deviceId,
    required String accessToken,
    required ThermostatBrand brand,
  }) async {
    try {
      switch (brand) {
        case ThermostatBrand.ecobee:
          return await _getEcobeeStatus(deviceId, accessToken);
        case ThermostatBrand.nest:
          return await _getNestStatus(deviceId, accessToken);
        case ThermostatBrand.honeywell:
          return await _getHoneywellStatus(deviceId, accessToken);
        default:
          return null;
      }
    } catch (e) {
      print('Error getting thermostat status: $e');
      return null;
    }
  }

  Future<ThermostatStatus?> _getEcobeeStatus(String deviceId, String accessToken) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/thermostat?format=json&body={"selection":{"selectionType":"thermostats","selectionMatch":"$deviceId","includeRuntime":true,"includeSettings":true}}'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final thermostat = data['thermostatList'][0];
      
      return ThermostatStatus(
        currentTemp: thermostat['runtime']['actualTemperature'] / 10.0,
        targetCoolTemp: thermostat['runtime']['desiredCool'] / 10.0,
        targetHeatTemp: thermostat['runtime']['desiredHeat'] / 10.0,
        mode: _parseEcobeeMode(thermostat['settings']['hvacMode']),
        isOnline: thermostat['runtime']['connected'],
        humidity: thermostat['runtime']['actualHumidity'].toDouble(),
      );
    }
    return null;
  }

  Future<ThermostatStatus?> _getNestStatus(String deviceId, String accessToken) async {
    final response = await http.get(
      Uri.parse('$_nestUrl/enterprises/project-id/devices/$deviceId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final traits = data['traits'];
      
      final tempC = traits['sdm.devices.traits.Temperature']['ambientTemperatureCelsius'];
      final currentTemp = tempC * 9 / 5 + 32; // Convert to Fahrenheit
      
      return ThermostatStatus(
        currentTemp: currentTemp,
        targetCoolTemp: (traits['sdm.devices.traits.ThermostatTemperatureSetpoint']['coolCelsius'] ?? 0) * 9 / 5 + 32,
        targetHeatTemp: (traits['sdm.devices.traits.ThermostatTemperatureSetpoint']['heatCelsius'] ?? 0) * 9 / 5 + 32,
        mode: _parseNestMode(traits['sdm.devices.traits.ThermostatMode']['mode']),
        isOnline: true,
        humidity: traits['sdm.devices.traits.Humidity']['ambientHumidityPercent']?.toDouble() ?? 0,
      );
    }
    return null;
  }

  Future<ThermostatStatus?> _getHoneywellStatus(String deviceId, String accessToken) async {
    final response = await http.get(
      Uri.parse('https://api.honeywell.com/v2/devices/thermostats/$deviceId'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      return ThermostatStatus(
        currentTemp: data['indoorTemperature'].toDouble(),
        targetCoolTemp: data['changeableValues']['coolSetpoint']?.toDouble() ?? 0,
        targetHeatTemp: data['changeableValues']['heatSetpoint']?.toDouble() ?? 0,
        mode: _parseHoneywellMode(data['changeableValues']['mode']),
        isOnline: data['isAlive'] ?? false,
        humidity: data['indoorHumidity']?.toDouble() ?? 0,
      );
    }
    return null;
  }

  TemperatureMode _parseEcobeeMode(String mode) {
    switch (mode) {
      case 'heat': return TemperatureMode.heating;
      case 'cool': return TemperatureMode.cooling;
      case 'auto': return TemperatureMode.auto;
      default: return TemperatureMode.off;
    }
  }

  TemperatureMode _parseNestMode(String mode) {
    switch (mode) {
      case 'HEAT': return TemperatureMode.heating;
      case 'COOL': return TemperatureMode.cooling;
      case 'HEATCOOL': return TemperatureMode.auto;
      default: return TemperatureMode.off;
    }
  }

  TemperatureMode _parseHoneywellMode(String mode) {
    switch (mode) {
      case 'heat': return TemperatureMode.heating;
      case 'cool': return TemperatureMode.cooling;
      case 'auto': return TemperatureMode.auto;
      default: return TemperatureMode.off;
    }
  }
}

/// Represents the current status of a thermostat
class ThermostatStatus {
  final double currentTemp;
  final double targetCoolTemp;
  final double targetHeatTemp;
  final TemperatureMode mode;
  final bool isOnline;
  final double humidity;

  const ThermostatStatus({
    required this.currentTemp,
    required this.targetCoolTemp,
    required this.targetHeatTemp,
    required this.mode,
    required this.isOnline,
    required this.humidity,
  });
}

enum ThermostatBrand { nest, ecobee, honeywell, smartthings }
enum TemperatureMode { heating, cooling, auto, off }
